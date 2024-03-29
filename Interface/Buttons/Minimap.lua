--[[
	Copyright / © 2014-2018 Justin Snelgrove
	Copyright / © 2008-2011 Rabbit <rabbit.magtheridon@gmail.com>

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
local MenuNames, MenuValues = AddOn_XRP.Strings.MenuNames, AddOn_XRP.Strings.MenuValues

local Button, LDBObject

local TEXTURES = {
	target = "Interface\\Icons\\INV_Misc_Book_03",
	ooc = "Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red",
	ic = "Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green",
}

local function XRPButton_UpdateIcon()
	if AddOn.Settings.mainButtonClickToView then
		local target = AddOn_XRP.Characters.byUnit.target
		if target and target.hasProfile then
			if Button then
				Button:SetNormalTexture(TEXTURES.target)
				Button:SetPushedTexture(TEXTURES.target)
			end
			if LDBObject then
				LDBObject.icon = "Interface\\MINIMAP\\TRACKING\\Class"
				LDBObject.text = L.VIEW_TARGET_LDB
			end
			return
		end
	end
	local FC = AddOn_XRP.Characters.byUnit.player.FC
	if not FC or FC == "0" or FC == "1" then
		if Button then
			Button:SetNormalTexture(TEXTURES.ooc)
			Button:SetPushedTexture(TEXTURES.ooc)
		end
		if LDBObject then
			LDBObject.icon = "Interface\\FriendsFrame\\StatusIcon-DnD"
			LDBObject.text = MenuValues.FC["1"]
		end
	else
		if Button then
			Button:SetNormalTexture(TEXTURES.ic)
			Button:SetPushedTexture(TEXTURES.ic)
		end
		if LDBObject then
			LDBObject.icon = "Interface\\FriendsFrame\\StatusIcon-Online"
			LDBObject.text = MenuValues.FC["2"]
		end
	end
end

local function RenderTooltip(Tooltip)
	Tooltip:AddLine(AddOn_XRP.Characters.byUnit.player.NA)
	Tooltip:AddLine(" ")
	Tooltip:AddLine(SUBTITLE_FORMAT:format(L.PROFILE, ("|cffffffff%s|r"):format(AddOn_XRP.Profiles.SELECTED.name)))
	local FC = AddOn_XRP.RemoveTextFormats(AddOn_XRP.Characters.byUnit.player.FC)
	if FC and FC ~= "0" then
		Tooltip:AddLine(SUBTITLE_FORMAT:format(L.STATUS, ("|cff%s%s|r"):format(FC == "1" and "99664d" or "66b380", Values.FC[FC] or FC)))
	end
	local CU = AddOn_XRP.RemoveTextFormats(AddOn_XRP.Characters.byUnit.player.CU)
	if CU then
		Tooltip:AddLine(" ")
		Tooltip:AddLine(STAT_FORMAT:format(Names.CU))
		Tooltip:AddLine(("%s"):format(AddOn.LinkURLs(CU)), 0.9, 0.7, 0.6, true)
	end
	Tooltip:AddLine(" ")
	local target = AddOn_XRP.Characters.byUnit.target
	if AddOn.Settings.mainButtonClickToView and target and target.hasProfile then
		Tooltip:AddLine(L"Click to view your target's profile.", 1, 0.93, 0.67)
	elseif not FC or FC == "0" or FC == "1" then
		Tooltip:AddLine(L"Click for in character.", 0.4, 0.7, 0.5)
	else
		Tooltip:AddLine(L"Click for out of character.", 0.6, 0.4, 0.3)
	end
	Tooltip:AddLine(L"Right click for the menu.", 0.6, 0.6, 0.6)
end

function XRPButton_OnEnter(self, motion)
	if motion then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, 32)
		RenderTooltip(GameTooltip)
		GameTooltip:Show()
	end
end

local Status_menuList = {}
local function Status_Click(self, status, arg2, checked)
	if not checked then
		AddOn_XRP.SetStatus(status or "0")
	end
	CloseDropDownMenus()
end
local function Status_Checked(self)
	return self.arg1 == AddOn_XRP.Characters.byUnit.player.FC
end
for i = 0, 4 do
	local s = tostring(i)
	Status_menuList[i + 1] = { text = MenuValues.FC[s], checked = Status_Checked, arg1 = i ~= 0 and s or nil, func = Status_Click, }
end

local Profiles_menuList = {}
XRPButton_baseMenuList = {
	{ text = L.PROFILES, notCheckable = true, hasArrow = true, menuList = Profiles_menuList, },
	{ text = MenuNames.FC, notCheckable = true, hasArrow = true, menuList = Status_menuList, },
	{ text = MenuNames.CU .. CONTINUED, notCheckable = true, func = function() StaticPopup_Show("XRP_CURRENTLY") end, },
	{ text = L.ARCHIVE, notCheckable = true, func = function() XRPArchive:Toggle(1) end, },
	{ text = L.VIEWER, notCheckable = true, func = function() XRPViewer:View() end, },
	{ text = L.EDITOR, notCheckable = true, func = function() XRPEditor:Edit() end, },
	{ text = L.OPTIONS, notCheckable = true, func = function() AddOn.Options() end, },
	{ text = CANCEL, notCheckable = true, func = AddOn.DoNothing, },
}

local function Profiles_Click(self, profileName, arg2, checked)
	if not checked and AddOn_XRP.Profiles[profileName] then
		AddOn_XRP.SetProfile(profileName)
	end
	CloseDropDownMenus()
end

local ldbMenu
function XRPButton_OnClick(self, button, down)
	if button == "LeftButton" then
		local target = AddOn_XRP.Characters.byUnit.target
		if AddOn.Settings.mainButtonClickToView and target and target.hasProfile then
			XRPViewer:View("target")
		else
			AddOn_XRP.ToggleStatus()
		end
		if self == Button then
			XRPButton_OnEnter(self, true)
		end
		CloseDropDownMenus()
	elseif button == "RightButton" then
		if self ~= Button and not ldbMenu then
			ldbMenu = CreateFrame("Frame")
			ldbMenu.baseMenuList = XRPButton_baseMenuList
			ldbMenu.initialize = XRPTemplatesMenu_Mixin.initialize
			ldbMenu.displayMode = "MENU"
			ldbMenu.anchor = "cursor"
		end
		table.wipe(Profiles_menuList)
		local selected = AddOn_XRP.Profiles.SELECTED.name
		for i, profileName in ipairs(AddOn_XRP.GetProfileList()) do
			Profiles_menuList[#Profiles_menuList + 1] = { text = profileName, checked = selected == profileName, arg1 = profileName, func = Profiles_Click, }
		end
		XRPTemplatesMenu_OnClick(self == Button and self or ldbMenu, button, down)
	end
end

local MINIMAP_SHAPES = {
	["ROUND"] = { true, true, true, true },
	["SQUARE"] = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
	["SIDE-LEFT"] = { false, true, false, true },
	["SIDE-RIGHT"] = { true, false, true, false },
	["SIDE-TOP"] = { false, false, true, true },
	["SIDE-BOTTOM"] = { true, true, false, false },
	["TRICORNER-TOPLEFT"] = { false, true, true, true },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}
local function UpdatePositionAttached(self)
	local angle = math.rad(AddOn.Settings.mainButtonMinimapAngle)
	local x, y, q = math.cos(angle), math.sin(angle), 1
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end
	if MINIMAP_SHAPES[GetMinimapShape and GetMinimapShape() or "ROUND"][q] then
		x, y = x * 105, y * 105
	else
		-- 103.13708498985 = math.sqrt(2*(80)^2)-10
		x = math.max(-105, math.min(x * 103.13708498985, 105))
		y = math.max(-105, math.min(y * 103.13708498985, 105))
	end
	self:ClearAllPoints()
	self:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
local function Minimap_OnUpdate(self, elapsed)
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	px, py = px / scale, py / scale
	AddOn.Settings.mainButtonMinimapAngle = math.deg(math.atan2(py - my, px - mx)) % 360
	UpdatePositionAttached(self)
end

function XRPButtonAttached_OnDragStart(self, button)
	self:LockHighlight()
	self:SetScript("OnUpdate", Minimap_OnUpdate)
end

function XRPButtonAttached_OnDragStop(self)
	self:SetScript("OnUpdate", nil)
	self:UnlockHighlight()
end

function XRPButtonDetached_OnDragStart(self, button)
	if IsShiftKeyDown() then
		self:LockHighlight()
		self:StartMoving()
	end
end

function XRPButtonDetached_OnDragStop(self)
	self:StopMovingOrSizing()
	AddOn.Settings.mainButtonDetachedPoint, AddOn.Settings.mainButtonDetachedX, AddOn.Settings.mainButtonDetachedY = select(3, self:GetPoint())
	self:UnlockHighlight()
end

local isRegistered = false
local function RegisterEvents()
	if isRegistered then return end
	AddOn_XRP.RegisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", XRPButton_UpdateIcon)
	AddOn.RegisterGameEventCallback("PLAYER_TARGET_CHANGED", XRPButton_UpdateIcon)
	AddOn.RegisterGameEventCallback("PLAYER_ENTERING_WORLD", XRPButton_UpdateIcon)
	isRegistered = true
end

local function UnregisterEvents()
	if not isRegistered then return end
	AddOn_XRP.UnregisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", XRPButton_UpdateIcon)
	AddOn.UnregisterGameEventCallback("PLAYER_TARGET_CHANGED", XRPButton_UpdateIcon)
	AddOn.UnregisterGameEventCallback("PLAYER_ENTERING_WORLD", XRPButton_UpdateIcon)
	isRegistered = false
end

AddOn.SettingsToggles.mainButtonEnabled = function(setting)
	if setting then
		if AddOn.Settings.mainButtonDetached then
			if Button and Button == LibDBIcon10_XRP then
				Button:UnregisterAllEvents()
				Button:Hide()
			end
			if not XRPButton then
				CreateFrame("Button", "XRPButton", UIParent, "XRPButtonTemplate")
				XRPButton:SetPoint(AddOn.Settings.mainButtonDetachedPoint, UIParent, AddOn.Settings.mainButtonDetachedPoint, AddOn.Settings.mainButtonDetachedX, AddOn.Settings.mainButtonDetachedY)
			end
			Button = XRPButton
		else
			if Button and Button == XRPButton then
				Button:UnregisterAllEvents()
				Button:Hide()
			end
			if not LibDBIcon10_XRP then
				CreateFrame("Button", "LibDBIcon10_XRP", Minimap, "XRPMinimapTemplate")
				UpdatePositionAttached(LibDBIcon10_XRP)
			end
			Button = LibDBIcon10_XRP
		end
		RegisterEvents()
		XRPButton_UpdateIcon()
		Button:Show()
	elseif Button ~= nil then
		if not LDBObject then
			UnregisterEvents()
		end
		Button:Hide()
		Button = nil
	end
end

AddOn.SettingsToggles.mainButtonDetached = function(setting)
	if not AddOn.Settings.mainButtonEnabled or not Button or setting and Button == XRPButton or not setting and Button == LibDBIcon10_XRP then return end
	AddOn.SettingsToggles.mainButtonEnabled(AddOn.Settings.mainButtonEnabled)
end

AddOn.SettingsToggles.ldbObject = function(setting)
	if setting then
		if LDBObject then return end
		local ldb = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
		if not ldb then return end
		LDBObject = {
			type = "data source",
			text = UNKNOWN,
			label = FOLDER_NAME,
			icon = "Interface\\Icons\\INV_Misc_QuestionMark",
			OnClick = XRPButton_OnClick,
			OnTooltipShow = RenderTooltip,
		}
		ldb:NewDataObject(LDBObject.label, LDBObject)
		RegisterEvents()
		XRPButton_UpdateIcon()
		if not LDBObject and not (LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)) then
			-- No LDB library, meaning no chance of a viewer.
			InterfaceOptionsFramePanelContainer.XRPGeneral.LDBObject:SetEnabled(false)
		end
	end
end
