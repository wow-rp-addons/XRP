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

local viewer = XRPViewer

local Load, FIELD
do
	-- This will request fields in the order listed.
	local DISPLAY = {
		"VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", -- In TT.
		"AE", "AH", "AW", "AG", "HH", "HB", "MO", -- Not in TT.
		"DE", "HI", -- High-bandwidth.
	}

	local function SetField(field, contents)
		contents = contents and xrp:Strip(contents) or nil
		if field == "NA" then
			contents = contents or UNKNOWN
		elseif field == "VA" then
			contents = contents and contents:gsub(";", ", ") or "Unknown/None"
		elseif not contents then
			contents = ""
		elseif field == "NI" then
			contents = ("\"%s\""):format(contents)
		elseif field == "AH" then
			contents = xrp:Height(contents)
		elseif field == "AW" then
			contents = xrp:Weight(contents)
		elseif field == "CU" or field == "DE" or field == "MO" or field == "HI" then
			-- Link URLs in scrolling fields.
			contents = contents:gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.com[^%w])", "http://%1"):gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.net[^%w])", "http://%1"):gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.org[^%w])", "http://%1"):gsub("(bit%.ly%/)", "http://%1"):gsub("(https?://)http://", "%1"):gsub("(https?://[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%%%-%.%_%~%:%/%?#%[%]%@%!%$%&%'%(%)%*%+%,%;%=]+)", "|H%1|h|cffc845fa[%1]|r|h")
		end
		viewer.fields[field]:SetText(contents)
		if field == "DE" or field == "HI" then
			viewer.lastFieldSet = GetTime()
		end
	end

	function Load(character)
		local fields = character.fields
		for i, field in ipairs(DISPLAY) do
			SetField(field, fields[field] or field == "NA" and xrp:Ambiguate(character.name) or field == "RA" and xrp.values.GR[fields.GR] or field == "RC" and xrp.values.GC[fields.GC] or nil)
		end
		if character.own then
			viewer.Menu:Hide()
		else
			viewer.Menu:Show()
		end
		viewer.XC:SetText("")
		viewer.failed = nil
		if character == viewer.current then
			return false
		end
		viewer.current = character
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
		if META_SUPPORTED[field] then
			field = META_SUPPORTED[field]
		end
		if viewer.current.name == name and SUPPORTED[field] then
			local fields = viewer.current.fields
			SetField(field, fields[field] or field == "RA" and xrp.values.GR[fields.GR] or field == "RC" and xrp.values.GC[fields.GC] or nil)
		end
	end
end

local function RECEIVE(event, name)
	if viewer.current.name == name then
		if viewer.failed then
			Load(viewer.current)
		end
		local XC = viewer.XC:GetText()
		if not XC or not XC:find("^Received") then
			viewer.XC:SetText(event == "NOCHANGE" and "No changes." or "Received!")
		end
	end
end

local function UPDATE(event, field)
	if viewer.current.name == xrpPrivate.playerWithRealm then
		if field then
			FIELD("FIELD", xrpPrivate.playerWithRealm, field)
		else
			Load(viewer.current)
		end
	end
end

local function CHUNK(event, name, chunk, totalchunks)
	if viewer.current.name == name then
		local XC = viewer.XC:GetText()
		if chunk ~= totalchunks or not XC or XC:find("^Receiv") then
			viewer.XC:SetFormattedText(totalchunks and (chunk == totalchunks and "Received! (%u/%u)" or "Receiving... (%u/%u)") or "Receiving... (%u/??)", chunk, totalchunks)
		end
	end
end

local function FAIL(event, name, reason)
	if viewer.current.name == name then
		viewer.failed = true
		if not viewer.XC:GetText() then
			if reason == "offline" then
				viewer.XC:SetText("Character is not online.")
			elseif reason == "faction" then
				viewer.XC:SetText("Character is opposite faction.")
			elseif reason == "nomsp" then
				viewer.XC:SetText("No RP addon appears to be active.")
			end
		end
	end
end

local Menu_baseMenuList
do
	local function Menu_Checked(self)
		if self.disabled then
			return false
		end
		if self.arg1 == 1 then
			return UIDROPDOWNMENU_INIT_MENU:GetParent().current.bookmark ~= nil
		elseif self.arg1 == 2 then
			return UIDROPDOWNMENU_INIT_MENU:GetParent().current.hide ~= nil
		end
	end
	local function Menu_Click(self, arg1, arg2, checked)
		if arg1 == 1 then
			UIDROPDOWNMENU_OPEN_MENU:GetParent().current.bookmark = not checked
		elseif arg1 == 2 then
			UIDROPDOWNMENU_OPEN_MENU:GetParent().current.hide = not checked
		elseif arg1 == 3 then
			local character = UIDROPDOWNMENU_OPEN_MENU:GetParent().current
			AddOrRemoveFriend(Ambiguate(character.name, "none"), xrp:Strip(character.fields.NA))
		elseif arg1 == 4 then
			Load(UIDROPDOWNMENU_OPEN_MENU:GetParent().current)
		end
	end
	Menu_baseMenuList = {
		{ text = "Bookmark", arg1 = 1, isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Hide profile", arg1 = 2, isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Add friend", arg1 = 3, notCheckable = true, func = Menu_Click, },
		{ text = "Refresh", arg1 = 4, notCheckable = true, func = Menu_Click, },
	}
end

local function Menu_PreClick(self, button, down)
	local viewer = self:GetParent()
	local GF = viewer.current.fields.GF
	if GF and GF ~= xrp.current.fields.GF then
		self.baseMenuList[3].disabled = true
	else
		local name = Ambiguate(viewer.current.name, "none")
		local isFriend
		for i = 1, GetNumFriends() do
			if GetFriendInfo(i) == name then
				isFriend = true
			end
		end
		self.baseMenuList[3].disabled = isFriend
	end
	if viewer.lastFieldSet + 30 > GetTime() then
		self.baseMenuList[4].disabled = true
	else
		self.baseMenuList[4].disabled = nil
	end
end

viewer.Menu.baseMenuList = Menu_baseMenuList
viewer.Menu:SetScript("PreClick", Menu_PreClick)
xrp:HookEvent("FIELD", FIELD)
xrp:HookEvent("RECEIVE", RECEIVE)
xrp:HookEvent("NOCHANGE", RECEIVE)
xrp:HookEvent("UPDATE", UPDATE)
xrp:HookEvent("CHUNK", CHUNK)
xrp:HookEvent("FAIL", FAIL)

function xrp:View(player)
	local isUnit, character
	if type(player) == "table" and player.name and player.fields then
		character = player
	else
		if not player then
			if viewer:IsShown() then
				HideUIPanel(viewer)
				return
			end
			if not viewer.current then
				player = "player"
			else
				ShowUIPanel(viewer)
				return
			end
		end
		isUnit = UnitExists(player)
		if isUnit and not UnitIsPlayer(player) then return end
		if not isUnit then
			local unit = Ambiguate(player, "none")
			isUnit = UnitExists(unit)
			player = isUnit and unit or self:Name(player):gsub("^%l", string.upper)
		end
		character = isUnit and self.characters.byUnit[player] or self.characters.byName[player]
	end
	local isNew = Load(character)
	if isUnit then
		SetPortraitTexture(viewer.portrait, player)
	elseif isNew then
		local GF = character.fields.GF
		SetPortraitToTexture(viewer.portrait, GF == "Alliance" and "Interface\\Icons\\INV_BannerPVP_02" or GF == "Horde" and "Interface\\Icons\\INV_BannerPVP_01" or "Interface\\Icons\\INV_Misc_Book_17")
	end
	ShowUIPanel(viewer)
	if not viewer.panes[1]:IsVisible() then
		viewer.Tab1:Click()
	end
end

if not xrpPrivate.settingsToggles.display then
	xrpPrivate.settingsToggles.display = {}
end
xrpPrivate.settingsToggles.display.movableViewer = function(setting)
	local wasVisible = viewer:IsVisible()
	if wasVisible then
		HideUIPanel(viewer)
	end
	if setting then
		viewer:SetAttribute("UIPanelLayout-defined", false)
		viewer:SetAttribute("UIPanelLayout-enabled", false)
		viewer:SetMovable(true)
		viewer:SetClampedToScreen(true)
		viewer:SetFrameStrata("HIGH")
		if not viewer:GetPoint() then
			viewer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -125)
		end
		if not viewer.TitleRegion then
			viewer.TitleRegion = viewer:CreateTitleRegion()
		end
		viewer.TitleRegion:SetAllPoints(viewer:GetName() .. "TitleBg")
		xrpPrivate.settingsToggles.display.closeOnEscapeViewer(xrpPrivate.settings.display.closeOnEscapeViewer)
	elseif viewer.TitleRegion then
		viewer:SetAttribute("UIPanelLayout-defined", true)
		viewer:SetAttribute("UIPanelLayout-enabled", true)
		viewer:SetMovable(false)
		viewer:SetClampedToScreen(false)
		viewer:SetFrameStrata("MEDIUM")
		viewer.TitleRegion:SetPoint("BOTTOMLEFT", viewer, "TOPLEFT")
		xrpPrivate.settingsToggles.display.closeOnEscapeViewer(false)
	end
	if wasVisible then
		ShowUIPanel(viewer)
	end
end
local closeOnEscape
xrpPrivate.settingsToggles.display.closeOnEscapeViewer = function(setting)
	if setting and viewer.TitleRegion then
		if not closeOnEscape then
			UISpecialFrames[#UISpecialFrames + 1] = "XRPViewer"
			closeOnEscape = true
		end
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
