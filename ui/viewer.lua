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

local addonName, _xrp = ...

local current, status, failed

local Load, FIELD
do
	-- This will request fields in the order listed.
	local DISPLAY = {
		"VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", -- In TT.
		"AE", "AH", "AW", "AG", "HH", "HB", "MO", -- Not in TT.
		"DE", "HI", -- High-bandwidth.
	}

	local function SetField(field, contents)
		contents = xrp.Strip(contents, field == "CU" or field == "DE" or field == "MO" or field == "HI")
		if field == "VA" then
			contents = contents and contents:gsub(";", PLAYER_LIST_DELIMITER) or NONE
		elseif not contents then
			contents = ""
		elseif field == "NI" then
			contents = _xrp.L.NICKNAME:format(contents)
		elseif field == "AH" then
			contents = xrp.Height(contents)
		elseif field == "AW" then
			contents = xrp.Weight(contents)
		elseif field == "CU" or field == "DE" or field == "MO" or field == "HI" then
			-- Link URLs in scrolling fields.
			contents = xrp.Link(contents)
		end
		XRPViewer.fields[field]:SetText(contents)
	end

	function Load(character)
		local fields = character.fields
		for i, field in ipairs(DISPLAY) do
			SetField(field, fields[field] or field == "NA" and xrp.ShortName(tostring(character)) or field == "RA" and xrp.L.VALUES.GR[fields.GR] or field == "RC" and xrp.L.VALUES.GC[fields.GS or "1"][fields.GC])
		end
		XRPViewer.XC:SetText("")
		failed = nil
		status = nil
		if character == current then
			return false
		elseif current and tostring(character) == tostring(current) then
			current = character
			return false
		end
		current = character
		return true
	end

	local SUPPORTED = {}
	for i, field in ipairs(DISPLAY) do
		SUPPORTED[field] = true
	end
	local META_SUPPORTED = {
		GR = "RA",
		GC = "RC",
	}
	function FIELD(event, name, field)
		if tostring(current) ~= name or current.noRequest then return end
		if META_SUPPORTED[field] then
			field = META_SUPPORTED[field]
		end
		if SUPPORTED[field] then
			local fields = current.fields
			SetField(field, fields[field] or field == "RA" and xrp.L.VALUES.GR[fields.GR] or field == "RC" and xrp.L.VALUES.GC[fields.GS or "1"][fields.GC])
		end
	end
end

local function RECEIVE(event, name)
	if tostring(current) == name and not current.noRequest then
		if failed then
			Load(current)
		end
		if status ~= "received" then
			if event == "NOCHANGE" then
				XRPViewer.XC:SetText(_xrp.L.NO_CHANGES)
				status = "nochange"
			elseif status ~= "nochange" then
				XRPViewer.XC:SetText(_xrp.L.RECEIVED)
				status = "received"
			end
		end
	end
end

local function UPDATE(event, field)
	if tostring(current) == _xrp.playerWithRealm then
		if field then
			FIELD("FIELD", _xrp.playerWithRealm, field)
		else
			Load(current)
		end
	end
end

local function CHUNK(event, name, chunk, totalChunks)
	if tostring(current) == name then
		if chunk ~= totalChunks then
			XRPViewer.XC:SetFormattedText(totalChunks and _xrp.L.RECEIVING_PARTS or _xrp.L.RECEIVING_UNKNOWN, chunk, totalChunks)
			status = "receiving"
		elseif status ~= "nochange" then
			XRPViewer.XC:SetFormattedText(_xrp.L.RECEIVED_PARTS, chunk, totalChunks)
			status = "received"
		end
	end
end

local function FAIL(event, name, reason)
	if tostring(current) == name then
		failed = true
		if not status then
			if reason == "offline" then
				XRPViewer.XC:SetText(_xrp.L.ERR_OFFLINE)
			elseif reason == "faction" then
				XRPViewer.XC:SetText(_xrp.L.ERR_FACTION)
			elseif reason == "nomsp" then
				XRPViewer.XC:SetText(_xrp.L.ERR_ADDON)
			end
			status = "failed"
		end
	end
end

local function DROP(event, name)
	if name == "ALL" or tostring(current) == name then
		XRPViewer:View("player")
		HideUIPanel(XRPViewer)
	end
end

do
	local function Menu_Checked(self)
		if self.disabled then
			return false
		elseif self.arg1 == "XRP_BOOKMARK" then
			return current.bookmark ~= nil
		elseif self.arg1 == "XRP_HIDE" then
			return current.hide ~= nil
		end
	end
	local function Menu_Click(self, arg1, arg2, checked)
		if arg1 == "XRP_NOTES" then
			XRPViewer.Notes:Show()
		elseif arg1 == "XRP_REFRESH" then
			if current.noRequest then
				Load(xrp.characters.byName[tostring(current)])
			else
				Load(current)
			end
		elseif arg1 == "XRP_FRIEND" then
			local name = tostring(current)
			AddOrRemoveFriend(Ambiguate(name, "none"), xrp.Strip(current.fields.NA) or xrp.ShortName(name))
		elseif arg1 == "XRP_BOOKMARK" then
			current.bookmark = not checked
		elseif arg1 == "XRP_HIDE" then
			current.hide = not checked
		elseif arg1 == "XRP_EXPORT" then
			XRPExport:Export(xrp.ShortName(tostring(current)), tostring(current.fields))
		elseif arg1 == "XRP_REFRESH_FORCE" then
			local name, realm = tostring(current):match("^([^%-]+)%-([^%-]+)")
			StaticPopup_Show("XRP_FORCE_REFRESH", _xrp.L.NAME_REALM:format(name, xrp.RealmDisplayName(realm)), nil, current)
		elseif arg1 == "XRP_CACHE_DROP" then
			local name, realm = tostring(current):match("^([^%-]+)%-([^%-]+)")
			StaticPopup_Show("XRP_CACHE_SINGLE", _xrp.L.NAME_REALM:format(name, xrp.RealmDisplayName(realm)), nil, current)
		end
		if arg2 then -- Second-level menu.
			CloseDropDownMenus()
		end
	end
	local Advanced_menuList = {
		{ text = _xrp.L.EXPORT, arg1 = "XRP_EXPORT", arg2 = true, notCheckable = true, func = Menu_Click, },
		{ text = _xrp.L.FORCE_REFRESH .. CONTINUED, arg1 = "XRP_REFRESH_FORCE", arg2 = true, notCheckable = true, func = Menu_Click, },
		{ text = _xrp.L.DROP_CACHE .. CONTINUED, arg1 = "XRP_CACHE_DROP", arg2 = true, notCheckable = true, func = Menu_Click, },
	}
	XRPViewerMenu_baseMenuList = {
		{ text = _xrp.L.NOTES, arg1 = "XRP_NOTES", notCheckable = true, func = Menu_Click, },
		{ text = REFRESH, arg1 = "XRP_REFRESH", notCheckable = true, func = Menu_Click, },
		{ text = ADD_FRIEND, arg1 = "XRP_FRIEND", notCheckable = true, func = Menu_Click, },
		{ text = _xrp.L.BOOKMARK, arg1 = "XRP_BOOKMARK", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = _xrp.L.HIDE_PROFILE, arg1 = "XRP_HIDE", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = ADVANCED_LABEL, notCheckable = true, hasArrow = true, menuList = Advanced_menuList, },
		{ text = CLOSE, notCheckable = true, func = _xrp.DoNothing, },
	}
end

function XRPViewerControls_OnLoad(self)
	if self.Label then
		self.Label:SetText(xrp.L.FIELDS[self.field])
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

do
	local function Menu_Click(self, arg1, arg2, checked)
		if arg1 == "XRP_TWEET" then
			if not SocialPostFrame then
					SocialFrame_LoadUI()
			end
			SocialPostFrame:SetAttribute("action", "Show")
			SocialPostFrame:SetAttribute("settext", ("|cff00aced%s|r "):format(UIDROPDOWNMENU_OPEN_MENU.linkData))
		elseif arg1 == "XRP_URL" then
			StaticPopup_Show("XRP_URL", nil, nil, ("https://twitter.com/%s"):format(UIDROPDOWNMENU_OPEN_MENU.linkData:match("^@(.-)$")))
		end
	end
	XRPViewerMultiline_baseMenuList = {
		{ text = _xrp.L.SEND_TWEET .. CONTINUED, arg1 = "XRP_TWEET", notCheckable = true, func = Menu_Click, },
		{ text = _xrp.L.COPY_URL .. CONTINUED, arg1 = "XRP_URL", notCheckable = true, func = Menu_Click, },
		{ text = CLOSE, notCheckable = true, func = _xrp.DoNothing, },
	}
end

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
	local name, isOwn = tostring(current), current.own
	local GF = xrp.characters.noRequest.byName[name].fields.GF
	if GF and GF ~= xrp.current.GF then
		self.baseMenuList[3].disabled = true
	else
		local name = Ambiguate(name, "none")
		local isFriend = isOwn
		if not isFriend then
			for i = 1, GetNumFriends() do
				if GetFriendInfo(i) == name then
					isFriend = true
					break
				end
			end
		end
		self.baseMenuList[3].disabled = isFriend
	end
	if not current.canRefresh then
		self.baseMenuList[2].disabled = true
	else
		self.baseMenuList[2].disabled = nil
	end
	local noProfile = not xrp.characters.noRequest.byName[name].fields.VA
	if isOwn or noProfile then
		self.baseMenuList[4].disabled = true
		self.baseMenuList[5].disabled = true
		self.baseMenuList[6].menuList[2].disabled = true
		if name == _xrp.playerWithRealm or noProfile then
			self.baseMenuList[6].menuList[3].disabled = true
		else
			self.baseMenuList[6].menuList[3].disabled = nil
		end
	else
		self.baseMenuList[4].disabled = nil
		self.baseMenuList[5].disabled = nil
		self.baseMenuList[6].menuList[2].disabled = nil
		self.baseMenuList[6].menuList[3].disabled = nil
	end
	if noProfile then
		self.baseMenuList[1].disabled = true
		self.baseMenuList[6].menuList[1].disabled = true
	else
		self.baseMenuList[1].disabled = nil
		self.baseMenuList[6].menuList[1].disabled = nil
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

xrp.HookEvent("FIELD", FIELD)
xrp.HookEvent("RECEIVE", RECEIVE)
xrp.HookEvent("NOCHANGE", RECEIVE)
xrp.HookEvent("UPDATE", UPDATE)
xrp.HookEvent("CHUNK", CHUNK)
xrp.HookEvent("FAIL", FAIL)
xrp.HookEvent("DROP", DROP)

XRPViewer_Mixin = {
	View = function(self, player)
		local isUnit, character
		if type(player) == "table" and player.fields then
			character = player
			local unit = Ambiguate(tostring(character), "none")
			isUnit = UnitExists(unit)
			player = isUnit and unit or tostring(character)
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
				player = isUnit and unit or xrp.FullName(player):gsub("^%l", string.upper)
			end
			character = isUnit and xrp.characters.byUnit[player] or xrp.characters.byName[player]
		end
		local isNew = Load(character)
		if isUnit then
			SetPortraitTexture(self.portrait, player)
		elseif isNew then
			local GF = character.fields.GF
			SetPortraitToTexture(self.portrait, GF == "Alliance" and "Interface\\Icons\\INV_BannerPVP_02" or GF == "Horde" and "Interface\\Icons\\INV_BannerPVP_01" or "Interface\\Icons\\INV_Misc_Book_17")
		end
		self.Notes:SetAttribute("character", character)
		ShowUIPanel(self)
		if isNew and not self.panes[1]:IsVisible() then
			self.Tab1:Click()
		end
	end,
	helpPlates = _xrp.help.viewer,
}

_xrp.settingsToggles.display.movableViewer = function(setting)
	local wasShown = XRPViewer:IsShown()
	if wasShown then
		HideUIPanel(XRPViewer)
	end
	if setting then
		XRPViewer:SetAttribute("UIPanelLayout-defined", false)
		XRPViewer:SetAttribute("UIPanelLayout-enabled", false)
		XRPViewer:SetMovable(true)
		XRPViewer:SetFrameStrata("HIGH")
		if not XRPViewer:GetPoint() then
			XRPViewer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -125)
		end
		if not XRPViewer.TitleRegion then
			XRPViewer.TitleRegion = XRPViewer:CreateTitleRegion()
		end
		XRPViewer.TitleRegion:SetAllPoints("XRPViewerTitleBg")
		_xrp.settingsToggles.display.closeOnEscapeViewer(_xrp.settings.display.closeOnEscapeViewer)
	elseif XRPViewer.TitleRegion then
		XRPViewer:SetAttribute("UIPanelLayout-defined", true)
		XRPViewer:SetAttribute("UIPanelLayout-enabled", true)
		XRPViewer:SetMovable(false)
		XRPViewer:SetFrameStrata("MEDIUM")
		XRPViewer.TitleRegion:SetPoint("BOTTOMLEFT", XRPViewer, "TOPLEFT")
		_xrp.settingsToggles.display.closeOnEscapeViewer(false)
	end
	if wasShown then
		ShowUIPanel(XRPViewer)
	end
end
local closeOnEscape
_xrp.settingsToggles.display.closeOnEscapeViewer = function(setting)
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
