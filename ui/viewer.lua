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

local current, failed

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
		if field == "VA" then
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
		XRPViewer.fields[field]:SetText(contents)
		if field == "DE" or field == "HI" then
			XRPViewer.nextRefresh = GetTime() + 30
		end
	end

	function Load(character)
		local fields = character.fields
		for i, field in ipairs(DISPLAY) do
			SetField(field, fields[field] or field == "NA" and xrp:Ambiguate(character.name) or field == "RA" and xrp.values.GR[fields.GR] or field == "RC" and xrp.values.GC[fields.GC] or nil)
		end
		XRPViewer.XC:SetText("")
		failed = nil
		if character == current then
			return false
		elseif current and character.name == current.name then
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
		if current.name ~= name then return end
		if META_SUPPORTED[field] then
			field = META_SUPPORTED[field]
		end
		if SUPPORTED[field] then
			local fields = current.fields
			SetField(field, fields[field] or field == "RA" and xrp.values.GR[fields.GR] or field == "RC" and xrp.values.GC[fields.GC] or nil)
		end
	end
end

local function RECEIVE(event, name)
	if current.name == name then
		if failed then
			Load(current)
		end
		local XC = XRPViewer.XC:GetText()
		if not XC or not XC:find("^Received") then
			XRPViewer.XC:SetText(event == "NOCHANGE" and "No changes." or "Received!")
		end
	end
end

local function UPDATE(event, field)
	if current.name == xrpPrivate.playerWithRealm then
		if field then
			FIELD("FIELD", xrpPrivate.playerWithRealm, field)
		else
			Load(current)
		end
	end
end

local function CHUNK(event, name, chunk, totalchunks)
	if current.name == name then
		local XC = XRPViewer.XC:GetText()
		if chunk ~= totalchunks or not XC or XC:find("^Receiv") then
			XRPViewer.XC:SetFormattedText(totalchunks and (chunk == totalchunks and "Received! (%u/%u)" or "Receiving... (%u/%u)") or "Receiving... (%u/??)", chunk, totalchunks)
		end
	end
end

local function FAIL(event, name, reason)
	if current.name == name then
		failed = true
		if not XRPViewer.XC:GetText() then
			if reason == "offline" then
				XRPViewer.XC:SetText("Character is not online.")
			elseif reason == "faction" then
				XRPViewer.XC:SetText("Character is opposite faction.")
			elseif reason == "nomsp" then
				XRPViewer.XC:SetText("No RP addon appears to be active.")
			end
		end
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
		if arg1 == "XRP_EXPORT" then
			xrp:ExportPopup(xrp:Ambiguate(current.name), current.exportText)
		elseif arg1 == "XRP_REFRESH" then
			if current.noRequest then
				Load(xrp.characters.byName[current.name])
			else
				Load(current)
			end
		elseif arg1 == "XRP_FRIEND" then
			AddOrRemoveFriend(Ambiguate(current.name, "none"), xrp:Strip(current.fields.NA))
		elseif arg1 == "XRP_BOOKMARK" then
			current.bookmark = not checked
		elseif arg1 == "XRP_HIDE" then
			current.hide = not checked
		end
	end
	XRPViewerMenu_baseMenuList = {
		{ text = "Export...", arg1 = "XRP_EXPORT", notCheckable = true, func = Menu_Click, },
		{ text = "Refresh", arg1 = "XRP_REFRESH", notCheckable = true, func = Menu_Click, },
		{ text = "Add friend", arg1 = "XRP_FRIEND", notCheckable = true, func = Menu_Click, },
		{ text = "Bookmark", arg1 = "XRP_BOOKMARK", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Hide profile", arg1 = "XRP_HIDE", isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Close", notCheckable = true, func = xrpPrivate.noFunc, },
	}
end

function XRPViewerControls_OnLoad(self)
	if self.Label then
		self.Label:SetText(self.fieldName)
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

function XRPViewerScrollFrameEditBox_OnHyperlinkClicked(self, linkData, link, button)
	if button == "LeftButton" then
		StaticPopup_Show("XRP_URL", nil, nil, linkData)
	end
end

function XRPViewerMenu_PreClick(self, button, down)
	local GF = current.fields.GF
	local isOwn = current.own
	if GF and GF ~= xrp.current.fields.GF then
		self.baseMenuList[3].disabled = true
	else
		local name = Ambiguate(current.name, "none")
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
	if isOwn or not current.noRequest and XRPViewer.nextRefresh > GetTime() then
		self.baseMenuList[2].disabled = true
	else
		self.baseMenuList[2].disabled = nil
	end
	if isOwn or not current.fields.VA then
		self.baseMenuList[4].disabled = true
		self.baseMenuList[5].disabled = true
	else
		self.baseMenuList[4].disabled = nil
		self.baseMenuList[5].disabled = nil
	end
end

function XRPViewer_OnLoad(self)
	self.fields.NA = self.TitleText
	self.fields.VA = self.VA
end

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
		local unit = Ambiguate(character.name, "none")
		isUnit = UnitExists(unit)
		player = isUnit and unit or character.name
	else
		if not player then
			if XRPViewer:IsShown() then
				HideUIPanel(XRPViewer)
				return
			elseif not current then
				player = "player"
			else
				ShowUIPanel(XRPViewer)
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
		SetPortraitTexture(XRPViewer.portrait, player)
	elseif isNew then
		local GF = character.fields.GF
		SetPortraitToTexture(XRPViewer.portrait, GF == "Alliance" and "Interface\\Icons\\INV_BannerPVP_02" or GF == "Horde" and "Interface\\Icons\\INV_BannerPVP_01" or "Interface\\Icons\\INV_Misc_Book_17")
	end
	ShowUIPanel(XRPViewer)
	if isNew and not XRPViewer.panes[1]:IsVisible() then
		XRPViewer.Tab1:Click()
	end
end

xrpPrivate.settingsToggles.display.movableViewer = function(setting)
	local wasVisible = XRPViewer:IsVisible()
	if wasVisible then
		HideUIPanel(XRPViewer)
	end
	if setting then
		XRPViewer:SetAttribute("UIPanelLayout-defined", false)
		XRPViewer:SetAttribute("UIPanelLayout-enabled", false)
		XRPViewer:SetMovable(true)
		XRPViewer:SetClampedToScreen(true)
		XRPViewer:SetFrameStrata("HIGH")
		if not XRPViewer:GetPoint() then
			XRPViewer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -125)
		end
		if not XRPViewer.TitleRegion then
			XRPViewer.TitleRegion = XRPViewer:CreateTitleRegion()
		end
		XRPViewer.TitleRegion:SetAllPoints("XRPViewerTitleBg")
		xrpPrivate.settingsToggles.display.closeOnEscapeViewer(xrpPrivate.settings.display.closeOnEscapeViewer)
	elseif XRPViewer.TitleRegion then
		XRPViewer:SetAttribute("UIPanelLayout-defined", true)
		XRPViewer:SetAttribute("UIPanelLayout-enabled", true)
		XRPViewer:SetMovable(false)
		XRPViewer:SetClampedToScreen(false)
		XRPViewer:SetFrameStrata("MEDIUM")
		XRPViewer.TitleRegion:SetPoint("BOTTOMLEFT", XRPViewer, "TOPLEFT")
		xrpPrivate.settingsToggles.display.closeOnEscapeViewer(false)
	end
	if wasVisible then
		ShowUIPanel(XRPViewer)
	end
end
local closeOnEscape
xrpPrivate.settingsToggles.display.closeOnEscapeViewer = function(setting)
	if setting and XRPViewer.TitleRegion then
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
