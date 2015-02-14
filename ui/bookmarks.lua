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

local addonName, xrpPrivate = ...

local bookmarks

-- Unlike CLASS_ICON_TCOORDS these aren't in a global.
local RACE_ICON_TCOORDS = {
	["HUMAN_MALE"] = { 0, 0.125, 0, 0.25 },
	["HUMAN_FEMALE"] = { 0, 0.125, 0.5, 0.75 },
	["DWARF_MALE"] = { 0.125, 0.25, 0, 0.25 },
	["DWARF_FEMALE"] = { 0.125, 0.25, 0.5, 0.75 },
	["NIGHTELF_MALE"] = { 0.375, 0.5, 0, 0.25 },
	["NIGHTELF_FEMALE"] = { 0.375, 0.5, 0.5, 0.75 },
	["GNOME_MALE"] = { 0.25, 0.375, 0, 0.25 },
	["GNOME_FEMALE"] = { 0.25, 0.375, 0.5, 0.75 },
	["DRAENEI_MALE"] = { 0.5, 0.625, 0, 0.25 },
	["DRAENEI_FEMALE"] = { 0.5, 0.625, 0.5, 0.75 },
	["WORGEN_MALE"] = { 0.625, 0.750, 0, 0.25 },
	["WORGEN_FEMALE"] = { 0.625, 0.750, 0.5, 0.75 },
	["ORC_MALE"] = { 0.375, 0.5, 0.25, 0.5 },
	["ORC_FEMALE"] = { 0.375, 0.5, 0.75, 1.0 },
	["SCOURGE_MALE"] = { 0.125, 0.25, 0.25, 0.5 },
	["SCOURGE_FEMALE"] = { 0.125, 0.25, 0.75, 1.0 },
	["TAUREN_MALE"] = { 0, 0.125, 0.25, 0.5 },
	["TAUREN_FEMALE"] = { 0, 0.125, 0.75, 1.0 },
	["TROLL_MALE"] = { 0.25, 0.375, 0.25, 0.5 },
	["TROLL_FEMALE"] = { 0.25, 0.375, 0.75, 1.0 },
	["BLOODELF_MALE"] = { 0.5, 0.625, 0.25, 0.5 },
	["BLOODELF_FEMALE"] = { 0.5, 0.625, 0.75, 1.0 },
	["GOBLIN_MALE"] = { 0.625, 0.750, 0.25, 0.5 },
	["GOBLIN_FEMALE"] = { 0.625, 0.750, 0.75, 1.0 },
	["PANDAREN_MALE"] = { 0.750, 0.875, 0, 0.25 },
	["PANDAREN_FEMALE"] = { 0.750, 0.875, 0.5, 0.75 },
}

local function Bookmarks_Scroll_update(self)
	local offset = HybridScrollFrame_GetOffset(self)
	local buttons = self.buttons
	local results = self:GetParent().results
	local matches = #results

	if matches == 0 then
		self.NoResults:Show()
	else
		self.NoResults:Hide()
	end

	for i=1, #buttons do
		local index = i + offset
		local button = buttons[i]
		local character = results[index]
		if index <= matches then
			if not button.character or character.name ~= button.character.name then
				button.character = character
				local name, realm = character.name:match(FULL_PLAYER_NAME:format("(.+)", "(.+)"))
				button.NA:SetText(xrp:Strip(character.fields.NA) or name)
				button.Name:SetText(name)
				button.Realm:SetText(xrp:RealmDisplayName(realm))
				local GR = character.fields.GR
				local RA = xrp:Strip(character.fields.RA) or xrp.values.GR[GR]
				if RA then
					button.RA:SetText(RA)
					button.RA:Show()
					if GR then
						local GS = character.fields.GS
						if not GS then
							GS = tostring(fastrandom(2, 3))
						end
						local gender = GS == "2" and "_MALE" or "_FEMALE"
						button.RaceIcon:SetTexCoord(unpack(RACE_ICON_TCOORDS[GR:upper() .. gender]))
						button.RaceIcon:Show()
					else
						button.RaceIcon:Hide()
					end
				else
					button.RA:Hide()
					button.RaceIcon:Hide()
				end
				local GC = character.fields.GC
				local RC = xrp:Strip(character.fields.RC) or xrp.values.GC[GC]
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
			end
			button:Show()
		else
			button:Hide()
		end
	end

	bookmarks.Count:SetFormattedText("Listing %u of %u profiles.", matches, results.totalCount)

	HybridScrollFrame_Update(self, 72 * matches, 72)
end

local function Bookmarks_OnUpdate(self, elapsed)
	self:SetScript("OnUpdate", nil)
	HybridScrollFrame_CreateButtons(self.List, "XRPBookmarksEntryTemplate")
	self:Refresh()
end

local function Bookmarks_Refresh(self)
	self.results = xrp.characters.noRequest:Filter(self.request)
	self.List.range = #self.results * 72
	self.List:update()
	self.List.scrollBar:SetValue(self.request.offset)
	if self.request.fullText then
		self.FilterText.Instructions:SetText("Search")
		self.FilterText.FullTextWarning:Show()
	else
		self.FilterText.Instructions:SetText("Name")
		self.FilterText.FullTextWarning:Hide()
	end
	self.FilterText:SetText(self.request.text or "")
end

local Bookmarks_baseMenuList
do
	local function Menu_Checked(self)
		if self.disabled then
			return false
		elseif self.arg1 == 5 then
			return UIDROPDOWNMENU_INIT_MENU.character and UIDROPDOWNMENU_INIT_MENU.character.bookmark ~= nil
		elseif self.arg1 == 6 then
			return UIDROPDOWNMENU_INIT_MENU.character and UIDROPDOWNMENU_INIT_MENU.character.hide ~= nil
		end
	end
	local function Menu_Click(self, arg1, arg2, checked)
		if arg1 == 1 then
			xrp:View(UIDROPDOWNMENU_OPEN_MENU.character)
		elseif arg1 == 2 then
			xrp:View(UIDROPDOWNMENU_OPEN_MENU.character.name)
		elseif arg1 == 3 then
			local character = UIDROPDOWNMENU_OPEN_MENU.character
			xrp:ExportPopup(xrp:Ambiguate(character.name), character.exportText)
		elseif arg1 == 4 then
			local character = UIDROPDOWNMENU_OPEN_MENU.character
			AddOrRemoveFriend(Ambiguate(character.name, "none"), xrp:Strip(character.fields.NA))
		elseif arg1 == 5 then
			UIDROPDOWNMENU_OPEN_MENU.character.bookmark = not checked
			if bookmarks.request.bookmark then
				bookmarks.request.offset = bookmarks.List.scrollBar:GetValue()
				bookmarks:Refresh()
			end
		elseif arg1 == 6 then
			UIDROPDOWNMENU_OPEN_MENU.character.hide = not checked
			if not bookmarks.request.showHidden then
				bookmarks.request.offset = bookmarks.List.scrollBar:GetValue()
				bookmarks:Refresh()
			end
		end
	end
	Bookmarks_baseMenuList = {
		{ text = "View (cached)...", arg1 = 1, notCheckable = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "View (live)...", arg1 = 2, notCheckable = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Export...", arg1 = 3, notCheckable = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Add friend", arg1 = 4, notCheckable = true, func = Menu_Click, },
		{ text = "Bookmark", arg1 = 5, isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Hide profile", arg1 = 6, isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Cancel", notCheckable = true, func = xrpPrivate.noFunc, },
	}
end

local Filter_baseMenuList
do
	local lists = {}
	local function Filter_Checked(self)
		return not bookmarks.request[self.arg1][self.arg2]
	end
	local function Filter_Click(self, arg1, arg2, checked)
		if arg2 == "ALL" then
			for i, value in pairs(lists[arg1]) do
				bookmarks.request[arg1][value] = nil
			end
			bookmarks.request[arg1].UNKNOWN = nil
			UIDropDownMenu_Refresh(bookmarks.FilterButton.Menu, nil, UIDROPDOWNMENU_MENU_LEVEL)
		elseif arg2 == "NONE" then
			for i, value in pairs(lists[arg1]) do
				bookmarks.request[arg1][value] = true
			end
			bookmarks.request[arg1].UNKNOWN = true
			UIDropDownMenu_Refresh(bookmarks.FilterButton.Menu, nil, UIDROPDOWNMENU_MENU_LEVEL)
		else
			bookmarks.request[arg1][arg2] = not checked
		end
		bookmarks.request.offset = 0
		bookmarks:Refresh()
	end
	local faction = UnitFactionGroup("player")
	if faction == "Horde" then
		lists.faction = { "Horde", "Alliance", "Neutral" }
		lists.race = { "Orc", "Scourge", "Tauren", "Troll", "BloodElf", "Goblin", "Pandaren", "Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Worgen" }
	else
		lists.faction = { "Alliance", "Horde", "Neutral" }
		lists.race = { "Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Worgen", "Pandaren", "Orc", "Scourge", "Tauren", "Troll", "BloodElf", "Goblin" }
	end
	local factionMenu = {
		{ text = "Check all", notCheckable = true, keepShownOnClick = true, arg1 = "faction", arg2 = "ALL", func = Filter_Click, },
		{ text = "Uncheck all", notCheckable = true, keepShownOnClick = true, arg1 = "faction", arg2 = "NONE", func = Filter_Click, },
	}
	for i, faction in ipairs(lists.faction) do
		factionMenu[#factionMenu + 1] = { text = xrp.values.GF[faction], isNotRadio = true, keepShownOnClick = true, arg1 = "faction", arg2 = faction, checked = Filter_Checked, func = Filter_Click, }
	end
	factionMenu[#factionMenu + 1] = { text = "Unknown", isNotRadio = true, keepShownOnClick = true, arg1 = "faction", arg2 = "UNKNOWN", checked = Filter_Checked, func = Filter_Click, }

	local raceMenu = {
		{ text = "Check all", notCheckable = true, keepShownOnClick = true, arg1 = "race", arg2 = "ALL", func = Filter_Click, },
		{ text = "Uncheck all", notCheckable = true, keepShownOnClick = true, arg1 = "race", arg2 = "NONE", func = Filter_Click, },
	}
	for i, race in ipairs(lists.race) do
		raceMenu[#raceMenu + 1] = { text = xrp.values.GR[race], isNotRadio = true, keepShownOnClick = true, arg1 = "race", arg2 = race, checked = Filter_Checked, func = Filter_Click, }
	end
	raceMenu[#raceMenu + 1] = { text = "Unknown", isNotRadio = true, keepShownOnClick = true, arg1 = "race", arg2 = "UNKNOWN", checked = Filter_Checked, func = Filter_Click, }

	lists.class = { "DEATHKNIGHT", "DRUID", "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }
	local classMenu = {
		{ text = "Check all", notCheckable = true, keepShownOnClick = true, arg1 = "class", arg2 = "ALL", func = Filter_Click, },
		{ text = "Uncheck all", notCheckable = true, keepShownOnClick = true, arg1 = "class", arg2 = "NONE", func = Filter_Click, },
	}
	for i, class in ipairs(lists.class) do
		classMenu[#classMenu + 1] = { text = xrp.values.GC[class], isNotRadio = true, keepShownOnClick = true, arg1 = "class", arg2 = class, checked = Filter_Checked, func = Filter_Click, }
	end
	classMenu[#classMenu + 1] = { text = "Unknown", isNotRadio = true, keepShownOnClick = true, arg1 = "class", arg2 = "UNKNOWN", checked = Filter_Checked, func = Filter_Click, }

	local function Filter_Radio_Checked(self)
		return bookmarks.request[self.arg1] == self.arg2
	end
	local function Filter_Radio_Click(self, arg1, arg2, checked)
		bookmarks.request[arg1] = arg2
		bookmarks.request.offset = 0
		bookmarks:Refresh()
		UIDropDownMenu_Refresh(bookmarks.FilterButton.Menu, nil, UIDROPDOWNMENU_MENU_LEVEL)
	end
	local sortMenu = {
		{ text = "Name", keepShownOnClick = true, arg1 = "sortType", arg2 = nil, checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
		{ text = "Roleplay name", keepShownOnClick = true, arg1 = "sortType", arg2 = "NA", checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
		{ text = "Realm", keepShownOnClick = true, arg1 = "sortType", arg2 = "realm", checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
		{ text = "Date", keepShownOnClick = true, arg1 = "sortType", arg2 = "date", checked = Filter_Radio_Checked, func = Filter_Radio_Click, },
	}

	local function Filter_Toggle_Checked(self)
		return bookmarks.request[self.arg1] == true
	end
	local function Filter_Toggle_Click(self, arg1, arg2, checked)
		bookmarks.request[arg1] = checked or nil
		bookmarks.request.offset = 0
		bookmarks:Refresh()
	end
	local function Filter_Reset(self, arg1, arg2, checked)
		local request = bookmarks.request
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
		bookmarks.request.offset = 0
		bookmarks:Refresh()
	end
	Filter_baseMenuList = {
		{ text = "Faction", notCheckable = true, hasArrow = true, menuList = factionMenu, },
		{ text = "Race", notCheckable = true, hasArrow = true, menuList = raceMenu, },
		{ text = "Class", notCheckable = true, hasArrow = true, menuList = classMenu, },
		{ text = "Sort by", notCheckable = true, hasArrow = true, menuList = sortMenu, },
		{ text = "Full-text search", isNotRadio = true, keepShownOnClick = true, arg1 = "fullText", checked = Filter_Toggle_Checked, func = Filter_Toggle_Click, },
		{ text = "Reverse sorting", isNotRadio = true, keepShownOnClick = true, arg1 = "sortReverse", checked = Filter_Toggle_Checked, func = Filter_Toggle_Click, },
		{ text = "Include hidden", isNotRadio = true, keepShownOnClick = true, arg1 = "showHidden", checked = Filter_Toggle_Checked, func = Filter_Toggle_Click, },
		{ text = "Reset filters", notCheckable = true, func = Filter_Reset, },
	}
end

local function HelpButton_PreClick(self, button, down)
	if not bookmarks.results or #bookmarks.results == 0 then
		bookmarks.Tab4:Click()
	end
end

local function CreateBookmarks()
	local frame = CreateFrame("Frame", "XRPBookmarks", UIParent, "XRPBookmarksTemplate")
	frame.Refresh = Bookmarks_Refresh
	frame.helpPlates = xrpPrivate.Help.Bookmarks
	frame.HelpButton:SetScript("PreClick", HelpButton_PreClick)
	frame.List.update = Bookmarks_Scroll_update
	frame.Tab1.request = { bookmark = true, sortType = "NA", defaultSortType = "NA", offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }
	frame.Tab2.request = { own = true, sortType = "NA", defaultSortType = "NA", offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }
	frame.Tab3.request = { maxAge = 10800, sortType = "date", defaultSortType = "date", offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }
	frame.Tab4.request = { offset = 0, lastRefresh = 0, faction = {}, race = {}, class = {} }
	frame.request = frame.Tab1.request
	frame.baseMenuList = Bookmarks_baseMenuList
	frame.FilterButton.baseMenuList = Filter_baseMenuList
	frame:SetScript("OnUpdate", Bookmarks_OnUpdate)
	return frame
end

function xrp:Bookmarks(showBookmarks)
	if not bookmarks then
		bookmarks = CreateBookmarks()
	elseif bookmarks:IsShown() then
		HideUIPanel(bookmarks)
		return
	elseif showBookmarks then
		bookmarks.Tab1:Click()
	end
	ShowUIPanel(bookmarks)
end

xrpPrivate.settingsToggles.display.preloadBookmarks = function(setting)
	if setting and not bookmarks then
		bookmarks = CreateBookmarks()
	end
end
