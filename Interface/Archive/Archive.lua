--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER, _xrp = ...

XRP_BOOKMARKS = _xrp.L.BOOKMARKS
XRP_OWN = _xrp.L.OWN
XRP_RECENT = _xrp.L.RECENT
XRP_SEARCH_ENTER = _xrp.L.PRESS_ENTER_SEARCH
XRP_PROFILES_NOTFOUND = _xrp.L.NO_PROFILES_FOUND

local request, results

-- Long races names, plus Undead, use alternate atlas names.
local atlasGR = {
	["HighmountainTauren"] = "Highmountain",
	["LightforgedDraenei"] = "Lightforged",
	["Scourge"] = "Undead",
	["ZandalariTroll"] = "Zandalari", -- This is a guess.
}

local function GetRaceAtlas(GR, GS)
	if (atlasGR[GR]) then
		GR = atlasGR[GR]
	end
	return ("raceicon-%s-%s"):format(GR:lower(), GS == "2" and "male" or "female")
end

function XRPArchiveList_update(self, force)
	if not self.buttons then return end
	local offset = HybridScrollFrame_GetOffset(self)
	local matches = #results

	if matches == 0 then
		self.NoResults:Show()
	else
		self.NoResults:Hide()
	end

	for i, button in ipairs(self.buttons) do
		local index = i + offset
		local character = xrp.characters.noRequest.byName[results[index]]
		if index <= matches then
			if force or not button.character or tostring(character) ~= tostring(button.character) then
				button.character = character
				local name, realm = tostring(character):match("^([^%-]+)%-([^%-]+)$")
				button.NA:SetText(xrp.Strip(character.fields.NA) or name)
				button.Name:SetText(name)
				button.Realm:SetText(xrp.RealmDisplayName(realm))
				local GR = character.fields.GR
				local RA = xrp.Strip(character.fields.RA) or xrp.L.VALUES.GR[GR]
				if RA then
					button.RA:SetText(RA)
					button.RA:Show()
					if GR then
						local GS = character.fields.GS
						if not GS then
							GS = tostring(fastrandom(2, 3))
						end
						button.RaceIcon:SetAtlas(GetRaceAtlas(GR, GS))
						button.RaceIcon:Show()
					else
						button.RaceIcon:Hide()
					end
				else
					button.RA:Hide()
					button.RaceIcon:Hide()
				end
				local GC = character.fields.GC
				local RC = xrp.Strip(character.fields.RC) or xrp.L.VALUES.GC[character.fields.GS or "1"][GC]
				if RC then
					button.RC:SetText(RC)
					button.RC:Show()
					if GC then
						local color = RAID_CLASS_COLORS[GC]
						button.RC:SetTextColor(color.r, color.g, color.b)
						button.ClassIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[GC]))
						button.ClassIcon:Show()
					else
						button.RC:SetTextColor(button.RC:GetFontObject():GetTextColor())
						button.ClassIcon:Hide()
					end
				else
					button.RC:Hide()
					button.ClassIcon:Hide()
				end
				button.Date:SetText(date("%Y-%m-%d %H:%M", character.date))
				local GF = character.fields.GF
				if GF == "Alliance" or GF == "Horde" then
					button.GF:SetAtlas("MountJournalIcons-" .. GF, true)
					button.GF:Show()
					local color = PLAYER_FACTION_COLORS[GF == "Alliance" and 1 or 0]
					button.Name:SetTextColor(color.r, color.g, color.b)
				elseif GF == "Neutral" then
					button.GF:Hide()
					local color = FACTION_BAR_COLORS[4]
					button.Name:SetTextColor(color.r, color.g, color.b)
				else
					button.GF:Hide()
					button.Name:SetTextColor(button.Name:GetFontObject():GetTextColor())
				end
				if character.notes then
					button.Notes:Show()
				else
					button.Notes:Hide()
				end
			end
			button:Show()
		else
			button:Hide()
		end
	end

	XRPArchive.Count:SetFormattedText(_xrp.L.TOTAL_LIST, matches, results.totalCount)

	HybridScrollFrame_Update(self, 72 * matches, 72)
end

local function Refresh()
	results = xrp.characters:List(request)
	XRPArchive.List.range = #results * 72
	XRPArchive.List:update()
	XRPArchive.List.scrollBar:SetValue(request.offset)
	if request.fullText then
		XRPArchive.FilterText.Instructions:SetText(SEARCH)
		XRPArchive.FilterText.FullTextWarning:Show()
	else
		XRPArchive.FilterText.Instructions:SetText(NAME)
		XRPArchive.FilterText.FullTextWarning:Hide()
	end
	XRPArchive.FilterText:SetText(request.text or "")
end

local function DROP(event, name)
	if name == "ALL" then
		request.offset = 0
		Refresh()
		return
	end
	for i, button in ipairs(XRPArchive.List.buttons) do
		if tostring(button.character) == name then
			request.offset = XRPArchive.List.scrollBar:GetValue()
			Refresh()
			return
		end
	end
end
xrp.HookEvent("DROP", DROP)

local function Menu_Checked(self)
	if self.disabled or not UIDROPDOWNMENU_INIT_MENU.character then
		return false
	elseif self.arg1 == "XRP_BOOKMARK" then
		return UIDROPDOWNMENU_INIT_MENU.character.bookmark ~= nil
	elseif self.arg1 == "XRP_HIDE" then
		return UIDROPDOWNMENU_INIT_MENU.character.hide ~= nil
	end
end
local function Menu_Click(self, arg1, arg2, checked)
	if arg1 == "XRP_VIEW_CACHED" then
		XRPViewer:View(UIDROPDOWNMENU_INIT_MENU.character)
	elseif arg1 == "XRP_VIEW_LIVE" then
		XRPViewer:View(tostring(UIDROPDOWNMENU_INIT_MENU.character))
	elseif arg1 == "XRP_NOTES" then
		XRPArchive.Notes:SetAttribute("character", UIDROPDOWNMENU_INIT_MENU.character)
		XRPArchive.Notes:Show()
	elseif arg1 == "XRP_FRIEND" then
		local character = UIDROPDOWNMENU_INIT_MENU.character
		local name = tostring(character)
		AddOrRemoveFriend(Ambiguate(name, "none"), xrp.Strip(character.fields.NA) or xrp.ShortName(name))
	elseif arg1 == "XRP_BOOKMARK" then
		UIDROPDOWNMENU_INIT_MENU.character.bookmark = not checked
		if request.bookmark then
			request.offset = XRPArchive.List.scrollBar:GetValue()
			Refresh()
		end
	elseif arg1 == "XRP_HIDE" then
		UIDROPDOWNMENU_INIT_MENU.character.hide = not checked
		if not request.showHidden then
			request.offset = XRPArchive.List.scrollBar:GetValue()
			Refresh()
		end
	elseif arg1 == "XRP_EXPORT" then
		local character = UIDROPDOWNMENU_INIT_MENU.character
		XRPExport:Export(xrp.ShortName(tostring(character)), tostring(character.fields))
	elseif arg1 == "XRP_CACHE_DROP" then
		local name, realm = tostring(UIDROPDOWNMENU_INIT_MENU.character):match("^([^%-]+)%-([^%-]+)")
		StaticPopup_Show("XRP_CACHE_SINGLE", _xrp.L.NAME_REALM:format(name, xrp.RealmDisplayName(realm)), nil, UIDROPDOWNMENU_INIT_MENU.character)
	end
	if UIDROPDOWNMENU_MENU_LEVEL > 1 then
		CloseDropDownMenus()
	end
end
local Advanced_menuList = {
	{ text = _xrp.L.EXPORT, arg1 = "XRP_EXPORT", notCheckable = true, func = Menu_Click, },
	{ text = _xrp.L.DROP_CACHE .. CONTINUED, arg1 = "XRP_CACHE_DROP", notCheckable = true, func = Menu_Click, },
}
XRPArchiveEntry_Mixin = {
	baseMenuList = {
		{ text = _xrp.L.VIEW_CACHED, arg1 = "XRP_VIEW_CACHED", notCheckable = true, func = Menu_Click, },
		{ text = _xrp.L.VIEW_LIVE, arg1 = "XRP_VIEW_LIVE", notCheckable = true, func = Menu_Click, },
		{ text = _xrp.L.NOTES, arg1 = "XRP_NOTES", notCheckable = true, func = Menu_Click, },
		{ text = ADD_FRIEND, arg1 = "XRP_FRIEND", notCheckable = true, func = Menu_Click, },
		{ text = _xrp.L.BOOKMARK, arg1 = "XRP_BOOKMARK", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = _xrp.L.HIDE_PROFILE, arg1 = "XRP_HIDE", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = ADVANCED_LABEL, notCheckable = true, hasArrow = true, menuList = Advanced_menuList, },
		{ text = CANCEL, notCheckable = true, func = _xrp.DoNothing, },
	},
	onHide = function(level)
		if level < 3 then
			UIDROPDOWNMENU_INIT_MENU.Selected:Hide()
		end
	end,
}

function XRPArchiveEntry_OnClick(self, button, down)
	if not self.character then return end
	if button == "RightButton" then
		self.Selected:Show()
		if self.character.own then
			if tostring(self.character) == _xrp.playerWithRealm then
				self.baseMenuList[1].disabled = true
				self.baseMenuList[7].menuList[2].disabled = true
			else
				self.baseMenuList[1].disabled = nil
				self.baseMenuList[7].menuList[2].disabled = nil
			end
			self.baseMenuList[4].disabled = true
			self.baseMenuList[5].disabled = true
			self.baseMenuList[6].disabled = true
		else
			self.baseMenuList[1].disabled = nil
			local GF = self.character.fields.GF
			if GF and GF ~= UnitFactionGroup("player") then
				self.baseMenuList[4].disabled = true
			else
				local name = Ambiguate(tostring(self.character), "none")
				local isFriend
				for i = 1, GetNumFriends() do
					if GetFriendInfo(i) == name then
						isFriend = true
						break
					end
				end
				self.baseMenuList[4].disabled = isFriend
			end
			self.baseMenuList[5].disabled = nil
			self.baseMenuList[6].disabled = nil
			self.baseMenuList[7].menuList[2].disabled = nil
		end
		ToggleDropDownMenu(nil, nil, self, "cursor", nil, nil, self.baseMenuList)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end

local lists = {}
local function Filter_Checked(self)
	return not request[self.arg1][self.arg2]
end
local function Filter_Click(self, arg1, arg2, checked)
	if arg2 == "ALL" then
		for i, value in pairs(lists[arg1]) do
			request[arg1][value] = nil
		end
		request[arg1].UNKNOWN = nil
		UIDropDownMenu_Refresh(XRPArchive.FilterButton.Menu, nil, UIDROPDOWNMENU_MENU_LEVEL)
	elseif arg2 == "NONE" then
		for i, value in pairs(lists[arg1]) do
			request[arg1][value] = true
		end
		request[arg1].UNKNOWN = true
		UIDropDownMenu_Refresh(XRPArchive.FilterButton.Menu, nil, UIDROPDOWNMENU_MENU_LEVEL)
	else
		request[arg1][arg2] = not checked
	end
	request.offset = 0
	Refresh()
end
if UnitFactionGroup("player") == "Horde" then
	lists.faction = { "Horde", "Alliance", "Neutral" }
	lists.race = { "Orc", "Scourge", "Tauren", "Troll", "BloodElf", "Goblin", "Nightborne", "HighmountainTauren", "MagharOrc", "ZandalariTroll", "Pandaren", "Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Worgen", "VoidElf", "LightforgedDraenei", "DarkIronDwarf", "KulTiran", }
else
	lists.faction = { "Alliance", "Horde", "Neutral" }
	lists.race = { "Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Worgen", "VoidElf", "LightforgedDraenei", "DarkIronDwarf", "KulTiran", "Pandaren", "Orc", "Scourge", "Tauren", "Troll", "BloodElf", "Goblin", "Nightborne", "HighmountainTauren", "MagharOrc", "ZandalariTroll", }
end
local factionMenu = {
	{ text = CHECK_ALL, notCheckable = true, keepShownOnClick = true, arg1 = "faction", arg2 = "ALL", func = Filter_Click, },
	{ text = UNCHECK_ALL, notCheckable = true, keepShownOnClick = true, arg1 = "faction", arg2 = "NONE", func = Filter_Click, },
}
for i, faction in ipairs(lists.faction) do
	factionMenu[#factionMenu + 1] = { text = xrp.L.VALUES.GF[faction], isNotRadio = true, keepShownOnClick = true, arg1 = "faction", arg2 = faction, checked = Filter_Checked, func = Filter_Click, }
end
factionMenu[#factionMenu + 1] = { text = UNKNOWN, isNotRadio = true, keepShownOnClick = true, arg1 = "faction", arg2 = "UNKNOWN", checked = Filter_Checked, func = Filter_Click, }

local raceMenu = {
	{ text = CHECK_ALL, notCheckable = true, keepShownOnClick = true, arg1 = "race", arg2 = "ALL", func = Filter_Click, },
	{ text = UNCHECK_ALL, notCheckable = true, keepShownOnClick = true, arg1 = "race", arg2 = "NONE", func = Filter_Click, },
}
for i, race in ipairs(lists.race) do
	raceMenu[#raceMenu + 1] = { text = xrp.L.VALUES.GR[race], isNotRadio = true, keepShownOnClick = true, arg1 = "race", arg2 = race, checked = Filter_Checked, func = Filter_Click, }
end
raceMenu[#raceMenu + 1] = { text = UNKNOWN, isNotRadio = true, keepShownOnClick = true, arg1 = "race", arg2 = "UNKNOWN", checked = Filter_Checked, func = Filter_Click, }

lists.class = {}
for class, localized in pairs(xrp.L.VALUES.GC["1"]) do
	lists.class[#lists.class + 1] = class
end
table.sort(lists.class)
local classMenu = {
	{ text = CHECK_ALL, notCheckable = true, keepShownOnClick = true, arg1 = "class", arg2 = "ALL", func = Filter_Click, },
	{ text = UNCHECK_ALL, notCheckable = true, keepShownOnClick = true, arg1 = "class", arg2 = "NONE", func = Filter_Click, },
}
for i, class in ipairs(lists.class) do
	classMenu[#classMenu + 1] = { text = xrp.L.VALUES.GC["1"][class], isNotRadio = true, keepShownOnClick = true, arg1 = "class", arg2 = class, checked = Filter_Checked, func = Filter_Click, }
end
classMenu[#classMenu + 1] = { text = UNKNOWN, isNotRadio = true, keepShownOnClick = true, arg1 = "class", arg2 = "UNKNOWN", checked = Filter_Checked, func = Filter_Click, }

local function Filter_Radio_Checked(self)
	return request[self.arg1] == self.arg2
end
local function Filter_Radio_Click(self, arg1, arg2, checked)
	request[arg1] = arg2
	request.offset = 0
	Refresh()
	UIDropDownMenu_Refresh(XRPArchive.FilterButton.Menu, nil, UIDROPDOWNMENU_MENU_LEVEL)
end
local sortMenu = {
	{ text = NAME, keepShownOnClick = true, arg1 = "sortType", arg2 = nil, checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
	{ text = _xrp.L.ROLEPLAY_NAME, keepShownOnClick = true, arg1 = "sortType", arg2 = "NA", checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
	{ text = _xrp.L.REALM, keepShownOnClick = true, arg1 = "sortType", arg2 = "realm", checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
	{ text = _xrp.L.DATE, keepShownOnClick = true, arg1 = "sortType", arg2 = "date", checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
}

local function Filter_Toggle_Checked(self)
	return request[self.arg1] == true
end
local function Filter_Toggle_Click(self, arg1, arg2, checked)
	request[arg1] = checked or nil
	request.offset = 0
	Refresh()
end
local function Filter_Reset(self, arg1, arg2, checked)
	request.text = nil
	for faction, filtered in pairs(request.faction) do
		request.faction[faction] = nil
	end
	for race, filtered in pairs(request.race) do
		request.race[race] = nil
	end
	for class, filtered in pairs(request.class) do
		request.class[class] = nil
	end
	request.sortType = request.defaultSortType
	request.fullText = nil
	request.sortReverse = nil
	request.notes = nil
	request.showHidden = nil
	request.offset = 0
	Refresh()
end
XRPArchiveFilterButton_baseMenuList = {
	{ text = FACTION, notCheckable = true, hasArrow = true, menuList = factionMenu, },
	{ text = RACE, notCheckable = true, hasArrow = true, menuList = raceMenu, },
	{ text = CLASS, notCheckable = true, hasArrow = true, menuList = classMenu, },
	{ text = _xrp.L.SORT_BY, notCheckable = true, hasArrow = true, menuList = sortMenu, },
	{ text = _xrp.L.FULL_SEARCH, isNotRadio = true, keepShownOnClick = true, arg1 = "fullText", checked = Filter_Toggle_Checked, func = Filter_Toggle_Click, },
	{ text = _xrp.L.REVERSE_SORT, isNotRadio = true, keepShownOnClick = true, arg1 = "sortReverse", checked = Filter_Toggle_Checked, func = Filter_Toggle_Click, },
	{ text = _xrp.L.HAS_NOTES, isNotRadio = true, keepShownOnClick = true, arg1 = "notes", checked = Filter_Toggle_Checked, func = Filter_Toggle_Click, },
	{ text = _xrp.L.INCLUDE_HIDDEN, isNotRadio = true, keepShownOnClick = true, arg1 = "showHidden", checked = Filter_Toggle_Checked, func = Filter_Toggle_Click, },
	{ text = _xrp.L.RESET_FILTERS, notCheckable = true, func = Filter_Reset, },
}

function XRPArchiveFilterText_OnTextChanged(self, userInput)
	if userInput and request.fullText or userInput == nil and not request.fullText then return end
	local text = self:GetText()
	if text == "" then
		text = nil
	end
	request.text = text
	Refresh()
end

function XRPArchiveHelpButton_PreClick(self, button, down)
	if not results or #results == 0 then
		XRPArchive.Tab4:Click()
	end
end

function XRPArchiveRefreshButton_OnClick(self, button, down)
	request.offset = 0
	Refresh()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

local ARCHIVE_TAB = {
	[1] = _xrp.L.BOOKMARKS,
	[2] = _xrp.L.OWN_CHARACTERS,
	[3] = _xrp.L.RECENT_3HOURS,
	[4] = _xrp.L.ALL_PROFILES,
}
local requests = {
	{ bookmark = true, sortType = "NA", defaultSortType = "NA", offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }, -- Bookmarks
	{ own = true, sortType = "NA", defaultSortType = "NA", offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }, -- Own
	{ maxAge = 10800, sortType = "date", defaultSortType = "date", offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }, -- Recent
	{ offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }, -- All
}
request = requests[1]

function XRPArchiveTab_OnClick(self, button, down)
	CloseDropDownMenus()
	request.offset = XRPArchive.List.scrollBar:GetValue()
	local now = GetTime()
	request.lastRefresh = now
	local tabID = self:GetID()
	request = requests[tabID]
	if self.resetOffset and now - 30 > request.lastRefresh then
		request.offset = 0
	end
	Refresh()
	PanelTemplates_SetTab(XRPArchive, tabID)
	XRPArchive.TitleText:SetText(ARCHIVE_TAB[tabID])
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
end

function XRPArchiveNotes_OnHide(self)
	XRPArchive.List:update(true)
end

function XRPArchiveNotes_OnAttributeChanged(self, name, value)
	if name == "character" then
		self.Title:SetText(xrp.ShortName(tostring(value)))
	end
end

function XRPArchive_OnUpdate(self, elapsed)
	self:SetScript("OnUpdate", nil)
	HybridScrollFrame_CreateButtons(self.List, "XRPArchiveEntryTemplate")
	Refresh()
end

XRPArchive_Mixin = {
	Toggle = function(self, tabID)
		if tabID and tabID ~= self.selectedTab then
			local tab = self[("Tab%d"):format(tabID)]
			if tab then
				tab:Click()
				ShowUIPanel(self)
				return
			end
		elseif self:IsShown() then
			HideUIPanel(self)
			return
		end
		ShowUIPanel(self)
	end,
	helpPlates = _xrp.help.archive,
}
