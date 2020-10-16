--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local Names, Values = AddOn_XRP.Strings.Names, AddOn_XRP.Strings.Values

local current, status, lastUpdate

-- This will request fields in the order listed.
local DISPLAY = {
	"VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "CO", -- In TT.
	"AE", "AH", "AW", "AG", "HH", "HB", "MO", -- Not in TT.
	"PE", "DE", "HI", -- High-bandwidth.
}

local function SetField(field, contents, secondary, tertiary)
	if field == "PE" then
		for i, display in ipairs(XRPViewer.PE) do
			display:SetPeek(contents and contents[i])
		end
		return
	end
	contents = AddOn_XRP.RemoveTextFormats(contents, field == "CU" or field == "CO" or field == "DE" or field == "HI")
	if field == "VA" then
		contents = contents and contents:gsub(";", PLAYER_LIST_DELIMITER) or NONE
	elseif secondary then
		if field == "NA" then
			contents = secondary
		elseif field =="RA" then
			contents = Values.GR[secondary]
		elseif field =="RC" then
			contents = Values.GC[tertiary or "1"][secondary]
		end
	end
	if not contents then
		contents = ""
	elseif field == "NA" and tertiary then
		contents = ("%s %s"):format(tertiary, contents)
	elseif field == "NI" and not contents:find(L.QUOTE_MATCH) then
		contents = L.NICKNAME:format(contents)
	elseif field =="CU" or field == "CO" or field == "DE" or field == "HI" then
		-- Link URLs in scrolling fields.
		contents = AddOn.LinkURLs(contents)
		if field == "DE" or field == "HI" then
			contents = contents .. "\n"
		end
	end
	XRPViewer.fields[field]:SetText(contents)
end

local function Load(character)
	for i, field in ipairs(DISPLAY) do
		local contents = character[field]
		SetField(field, contents, not contents and (field == "NA" and character.name or field == "RA" and character.GR or field == "RC" and character.GC), field == "NA" and character.PX or not contents and field == "RC" and character.GS)
	end
	if character == current then
		if character.offline ~= current.offline then
			current = character
		end
		return false
	else
		XRPViewer.XC:SetText("")
		status = nil
	end
	current = character
	lastUpdate = 0
	return true
end

local SUPPORTED = {}
for i, field in ipairs(DISPLAY) do
	SUPPORTED[field] = true
end
local META_SUPPORTED = {
	GR = "RA",
	GC = "RC",
	PX = "NA",
}
local function FIELD(event, name, field)
	if not current or current.id ~= name or current.offline or name == AddOn.characterID then return end
	if META_SUPPORTED[field] then
		field = META_SUPPORTED[field]
	end
	if SUPPORTED[field] then
		local contents = current[field]
		SetField(field, contents, not contents and (field == "NA" and character.name or field == "RA" and current.GR or field == "RC" and current.GC), field == "NA" and current.PX or not contents and field == "RC" and current.GS)
		lastUpdate = GetTime()
	end
end

local function RECEIVE(event, name)
	if current and current.id == name and not current.offline then
		Load(current)
		if name == AddOn.characterID then
			return
		end
		if status ~= "received" then
			if lastUpdate < GetTime() - 10 then
				XRPViewer.XC:SetText(L"No changes.")
				status = "nochange"
			elseif status ~= "nochange" then
				XRPViewer.XC:SetText(L"Received!")
				status = "received"
			end
		end
	end
end

local function CHUNK(event, name, chunk, totalChunks)
	if current and current.id == name then
		if chunk ~= totalChunks then
			XRPViewer.XC:SetFormattedText(totalChunks and L"Receiving... (%d/%d)" or L"Receiving... (%d/??)", chunk, totalChunks)
			status = "receiving"
		elseif status ~= "nochange" then
			XRPViewer.XC:SetFormattedText(L"Received! (%d/%d)", chunk, totalChunks)
			status = "received"
		end
	end
end

local function FAIL(event, name, reason)
	if current and current.id == name then
		if not status then
			if reason == "offline" then
				XRPViewer.XC:SetText(L"Character is not online.")
			elseif reason == "faction" then
				XRPViewer.XC:SetText(L"Character is opposite faction.")
			elseif reason == "nomsp" then
				XRPViewer.XC:SetText(L"No RP addon appears to be active.")
			end
			status = "failed"
		end
	end
end

XRPViewerPeek_Mixin = {}

function XRPViewerPeek_Mixin:OnShowFirst()
	local parent = self:GetParent()
	parent.extraWidth = 32
	local extraWidth = parent:GetAttribute("UIPanelLayout-extraWidth") or 0
	if extraWidth < 32 then
		parent:SetAttribute("UIPanelLayout-extraWidth", 32)
		if parent:GetAttribute("UIPanelLayout-defined") then
			UpdateUIPanelPositions(parent)
		end
	end
end

function XRPViewerPeek_Mixin:OnHideFirst()
	local parent = self:GetParent()
	parent.extraWidth = 0
	local extraWidth = parent:GetAttribute("UIPanelLayout-extraWidth") or 0
	if extraWidth == 32 then
		parent:SetAttribute("UIPanelLayout-extraWidth", 0)
		if parent:GetAttribute("UIPanelLayout-defined") then
			UpdateUIPanelPositions(parent)
		end
	end
end

local function DROP(event, name)
	if not name or current and current.id == name then
		XRPViewer:View("player")
		HideUIPanel(XRPViewer)
	end
end

local function Menu_Checked(self)
	if self.disabled then
		return false
	elseif self.arg1 == "XRP_BOOKMARK" then
		return current.bookmark and true or false
	elseif self.arg1 == "XRP_HIDE" then
		return current.hidden and true or false
	end
end
local function Menu_Click(self, arg1, arg2, checked)
	if arg1 == "XRP_REFRESH" then
		if current.offline then
			Load(AddOn_XRP.Characters.byName[current.id])
		else
			Load(current)
		end
	elseif arg1 == "XRP_FRIEND" then
		local name = current.id
		AddOrRemoveFriend(Ambiguate(name, "none"), AddOn_XRP.RemoveTextFormats(current.NA) or current.name)
	elseif arg1 == "XRP_BOOKMARK" then
		current.bookmark = not checked
	elseif arg1 == "XRP_HIDE" then
		current.hidden = not checked
	elseif arg1 == "XRP_EXPORT" then
		XRPExport:Export(current.name, current.exportPlainText)
	elseif arg1 == "XRP_REPORT" then
		local approxTime = ("%02d:%02d"):format(GetGameTime())
		StaticPopup_Show("XRP_REPORT", nil, nil, L"Logged addon message prefix: MSP; Player name: %s; Realm name: %s; Approximate game time: %s":format(current.name, current.realm, approxTime))
	elseif arg1 == "XRP_REFRESH_FORCE" then
		StaticPopup_Show("XRP_FORCE_REFRESH", current.idDisplay, nil, current)
	elseif arg1 == "XRP_CACHE_DROP" then
		StaticPopup_Show("XRP_CACHE_SINGLE", current.idDisplay, nil, current)
	end
	if arg2 then -- Second-level menu.
		CloseDropDownMenus()
	end
end

local MENU_ADV_FORCE_REFRESH = { text = L.FORCE_REFRESH .. CONTINUED, arg1 = "XRP_REFRESH_FORCE", arg2 = true, notCheckable = true, func = Menu_Click, }
local MENU_ADV_DROP_CACHE = { text = L.DROP_CACHE .. CONTINUED, arg1 = "XRP_CACHE_DROP", arg2 = true, notCheckable = true, func = Menu_Click, }

local Advanced_menuList = {
	MENU_ADV_FORCE_REFRESH,
	MENU_ADV_DROP_CACHE,
}

local MENU_REFRESH = { text = REFRESH, arg1 = "XRP_REFRESH", notCheckable = true, func = Menu_Click, }
local MENU_FRIEND = { text = ADD_FRIEND, arg1 = "XRP_FRIEND", notCheckable = true, func = Menu_Click, }
local MENU_BOOKMARK = { text = L.BOOKMARK, arg1 = "XRP_BOOKMARK", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, }
local MENU_HIDE = { text = L.HIDE_PROFILE, arg1 = "XRP_HIDE", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, }
local MENU_EXPORT = { text = L.EXPORT, arg1 = "XRP_EXPORT", notCheckable = true, func = Menu_Click, }
local MENU_REPORT = { text=  L.REPORT_PROFILE .. CONTINUED, arg1 = "XRP_REPORT", notCheckable = true, func = Menu_Click, }

XRPViewerMenu_baseMenuList = {
	MENU_REFRESH,
	MENU_FRIEND,
	MENU_BOOKMARK,
	MENU_HIDE,
	MENU_EXPORT,
	--MENU_REPORT,
	{ text = ADVANCED_LABEL, notCheckable = true, hasArrow = true, menuList = Advanced_menuList, },
	{ text = CANCEL, notCheckable = true, func = AddOn.DoNothing, },
}

function XRPViewerControls_OnLoad(self)
	if self.Label then
		self.Label:SetText(Names[self.field])
	end
	if self.field then
		if not XRPViewer.fields then
			XRPViewer.fields = {}
		end
		XRPViewer.fields[self.field] = self.EditBox or self.Text
	end
end

function XRPViewerScrollFrameEditBox_OnLoad(self)
	self:Disable()
	self:SetHyperlinksEnabled(true)
end

local function FixLevel(targetLevel, ...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		if frame:GetFrameLevel() < targetLevel then
			frame:SetFrameLevel(targetLevel)
		end
	end
end

local function XRPViewerScrollFrameEditBox_OnUpdate(self, elapsed)
	FixLevel(self:GetFrameLevel() + 1, self:GetChildren())
	self:SetScript("OnUpdate", nil)
end

function XRPViewerScrollFrameEditBox_OnTextChanged(self, userInput)
	self:SetScript("OnUpdate", XRPViewerScrollFrameEditBox_OnUpdate)
	XRPTemplatesScrollFrameEditBox_ResetToStart(self, userInput)
end

local function Menu_Click(self, arg1, arg2, checked)
	if arg1 == "XRP_TWEET" then
		if not SocialPostFrame then
				SocialFrame_LoadUI()
		end
		SocialPostFrame:SetAttribute("action", "Show")
		SocialPostFrame:SetAttribute("settext", ("|cff00aced%s|r "):format(UIDROPDOWNMENU_INIT_MENU.linkData))
	elseif arg1 == "XRP_URL" then
		StaticPopup_Show("XRP_URL", nil, nil, ("https://twitter.com/%s"):format(UIDROPDOWNMENU_INIT_MENU.linkData:match("^@(.-)$")))
	end
end
XRPViewerMultiline_baseMenuList = {
	{ text = L.SEND_TWEET .. CONTINUED, arg1 = "XRP_TWEET", notCheckable = true, func = Menu_Click, },
	{ text = L.COPY_URL .. CONTINUED, arg1 = "XRP_URL", notCheckable = true, func = Menu_Click, },
	{ text = CANCEL, notCheckable = true, func = AddOn.DoNothing, },
}

function XRPViewerScrollFrameEditBox_OnHyperlinkClicked(self, linkData, link, button)
	if linkData:find("^https?://") then
		if button == "LeftButton" then
			StaticPopup_Show("XRP_URL", nil, nil, linkData)
		end
	elseif linkData:find("^@") then
		if button == "LeftButton" then
			if C_Social.IsSocialEnabled() then
				if not SocialPostFrame then
					SocialFrame_LoadUI()
				end
				SocialPostFrame:SetAttribute("action", "Show")
				SocialPostFrame:SetAttribute("settext", ("|cff00aced%s|r "):format(linkData))
			else
				StaticPopup_Show("XRP_URL", nil, nil, ("https://twitter.com/%s"):format(linkData:match("^@(.-)$")))
			end
		elseif button == "RightButton" then
			local parent = self:GetParent()
			if not C_Social.IsSocialEnabled() then
				parent.Menu.baseMenuList[1].disabled = true
			else
				parent.Menu.baseMenuList[1].disabled = nil
			end
			parent.Menu.linkData = linkData
			ToggleDropDownMenu(nil, nil, parent.Menu, "cursor", nil, nil, parent.Menu.baseMenuList)
		end
	end
end

function XRPViewerMenu_PreClick(self, button, down)
	local name, isOwn = current.id, current.own
	local GF = AddOn_XRP.Characters.byNameOffline[name].GF
	if GF and GF ~= UnitFactionGroup("player") then
		MENU_FRIEND.disabled = true
	else
		local name = Ambiguate(name, "none")
		local isFriend = isOwn
		if not isFriend then
			for i = 1, C_FriendList.GetNumFriends() do
				if C_FriendList.GetFriendInfoByIndex(i) == name then
					isFriend = true
					break
				end
			end
		end
		MENU_FRIEND.disabled = isFriend
	end
	if not current.canRefresh then
		MENU_REFRESH.disabled = true
	else
		MENU_REFRESH.disabled = nil
	end
	local noProfile = not AddOn_XRP.Characters.byNameOffline[name].hasProfile
	if isOwn or noProfile then
		MENU_BOOKMARK.disabled = true
		MENU_HIDE.disabled = true
		if name == AddOn.characterID or noProfile then
			MENU_ADV_FORCE_REFRESH.disabled = true
			MENU_ADV_DROP_CACHE.disabled = true
		else
			MENU_ADV_FORCE_REFRESH.disabled = nil
			MENU_ADV_DROP_CACHE.disabled = nil
		end
		MENU_REPORT.disabled = true
	else
		MENU_BOOKMARK.disabled = nil
		MENU_HIDE.disabled = nil
		if current.GU and AddOn_Chomp.CheckReportGUID("MSP", current.GU) then
			MENU_REPORT.disabled = nil
		else
			MENU_REPORT.disabled = true
		end
		MENU_ADV_FORCE_REFRESH.disabled = nil
		MENU_ADV_DROP_CACHE.disabled = nil
	end
	if noProfile then
		MENU_EXPORT.disabled = true
	else
		MENU_EXPORT.disabled = nil
	end
end

function XRPViewerResize_OnClick(self, button, down)
	XRPViewer:SetWidth(439)
	XRPViewer:SetHeight(525)
	if XRPViewer:GetAttribute("UIPanelLayout-defined") then
		UpdateUIPanelPositions(XRPViewer)
	end
end

function XRPViewerResize_OnMouseDown(self, button)
	if button == "LeftButton" then
		self:SetButtonState("PUSHED", true)
		self:GetHighlightTexture():Hide()
		XRPViewer:StartSizing()
	end
end

function XRPViewerResize_OnMouseUp(self, button)
	if button == "LeftButton" then
		self:SetButtonState("NORMAL", false)
		self:GetHighlightTexture():Show()
		XRPViewer:StopMovingOrSizing()
		if XRPViewer:GetAttribute("UIPanelLayout-defined") then
			UpdateUIPanelPositions(XRPViewer)
		end
	end
end

function XRPViewer_OnLoad(self)
	self.fields.NA = self.TitleText
end

AddOn_XRP.RegisterEventCallback("ADDON_XRP_FIELD_RECEIVED", FIELD)
AddOn_XRP.RegisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", RECEIVE)
AddOn_XRP.RegisterEventCallback("ADDON_XRP_PROGRESS_UPDATED", CHUNK)
AddOn_XRP.RegisterEventCallback("ADDON_XRP_QUERY_FAILED", FAIL)
AddOn_XRP.RegisterEventCallback("ADDON_XRP_CACHE_DROPPED", DROP)

XRPViewer_Mixin = {
	View = function(self, player)
		local isUnit, character
		if type(player) == "table" and player.id then
			character = player
			local unit = Ambiguate(character.id, "none")
			isUnit = UnitExists(unit)
			player = isUnit and unit or character.id
		else
			if not player then
				if self:IsShown() then
					HideUIPanel(self)
					return
				elseif not current then
					player = "player"
				else
					ShowUIPanel(self)
					return
				end
			end
			isUnit = UnitExists(player)
			if isUnit and not UnitIsPlayer(player) then return end
			if not isUnit then
				local unit = Ambiguate(player, "none")
				isUnit = UnitExists(unit)
				player = isUnit and unit or player:gsub("^%l", string.upper)
			end
			character = isUnit and AddOn_XRP.Characters.byUnit[player] or AddOn_XRP.Characters.byName[player]
		end
		local isNew = Load(character)
		if isUnit then
			SetPortraitTexture(self.portrait, player)
		elseif isNew then
			local GF = character.GF
			SetPortraitToTexture(self.portrait, GF == "Alliance" and "Interface\\Icons\\INV_BannerPVP_02" or GF == "Horde" and "Interface\\Icons\\INV_BannerPVP_01" or "Interface\\Icons\\INV_Misc_Book_17")
		end
		self.Notes:SetAttribute("character", character)
		ShowUIPanel(self)
		if isNew and not self.panes[1]:IsVisible() then
			self.Tab1:Click()
		end
	end,
	helpPlates = AddOn.help.viewer,
}

AddOn.SettingsToggles.viewerMovable = function(setting)
	local wasShown = XRPViewer:IsShown()
	if wasShown then
		HideUIPanel(XRPViewer)
	end
	if setting then
		if not XRPViewer.TitleRegion then
			XRPViewer.TitleRegion = CreateFrame("Frame", nil, XRPViewer)
			XRPViewer.TitleRegion:SetScript("OnDragStart", function(self, button)
				self:GetParent():StartMoving()
			end)
			XRPViewer.TitleRegion:SetScript("OnDragStop", function(self)
				self:GetParent():StopMovingOrSizing()
			end)
			XRPViewer.TitleRegion:EnableMouse(true)
			XRPViewer.TitleRegion:RegisterForDrag("LeftButton")
			XRPViewer.TitleRegion:SetAllPoints("XRPViewerTitleBg")
		end
		XRPViewer:SetAttribute("UIPanelLayout-defined", false)
		XRPViewer:SetAttribute("UIPanelLayout-enabled", false)
		XRPViewer:SetMovable(true)
		XRPViewer:SetFrameStrata("HIGH")
		if not XRPViewer:GetPoint() then
			XRPViewer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -125)
		end
		XRPViewer.TitleRegion:Show()
		AddOn.SettingsToggles.viewerCloseOnEscape(AddOn.Settings.viewerCloseOnEscape)
	elseif XRPViewer.TitleRegion then
		XRPViewer:SetAttribute("UIPanelLayout-defined", true)
		XRPViewer:SetAttribute("UIPanelLayout-enabled", true)
		XRPViewer:SetMovable(false)
		XRPViewer:SetFrameStrata("MEDIUM")
		XRPViewer.TitleRegion:Hide()
		AddOn.SettingsToggles.viewerCloseOnEscape(false)
	end
	if wasShown then
		ShowUIPanel(XRPViewer)
	end
end
local closeOnEscape
AddOn.SettingsToggles.viewerCloseOnEscape = function(setting)
	if setting and XRPViewer.TitleRegion then
		if not closeOnEscape then
			UISpecialFrames[#UISpecialFrames + 1] = "XRPViewer"
		end
		closeOnEscape = true
	elseif closeOnEscape then
		for i, frame in ipairs(UISpecialFrames) do
			if frame == "XRPViewer" then
				table.remove(UISpecialFrames, i)
				break
			end
		end
		closeOnEscape = false
	end
end
