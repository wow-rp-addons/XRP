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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

XRPOptionsControl_Mixin = {}

function XRPOptionsControl_Mixin:Get()
	local settingsTable = AddOn.settings
	if self.xrpTable then
		settingsTable = AddOn.settings[self.xrpTable]
	end
	return settingsTable[self.xrpSetting]
end

function XRPOptionsControl_Mixin:Set(value)
	local settingsTable = AddOn.settings
	if self.xrpTable then
		settingsTable = AddOn.settings[self.xrpTable]
	end
	settingsTable[self.xrpSetting] = value
	local settingsToggleTable = AddOn.settingsToggles
	if self.xrpTable then
		settingsToggleTable = AddOn.settingsToggles[self.xrpTable]
	end
	if settingsToggleTable and settingsToggleTable[self.xrpSetting] then
		xpcall(settingsToggleTable[self.xrpSetting], geterrorhandler(), value, self.xrpSetting)
	end
end

XRPOptions_Mixin = {}

function XRPOptions_Mixin:okay()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomOkay then
			xpcall(control.CustomOkay, geterrorhandler(), control)
		else
			control.oldValue = control.value
		end
	end
end

function XRPOptions_Mixin:refresh()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomRefresh then
			xpcall(control.CustomRefresh, geterrorhandler(), control)
		else
			local setting = control:Get()
			control.value = setting
			if control.oldValue == nil then
				control.oldValue = setting
			end
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(setting)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				for i, entry in ipairs(control.baseMenuList) do
					if entry.arg1 == control.value then
						control.Text:SetText(entry.text)
						break
					end
				end
			end
		end
		if control.dependsOn then
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self[control.dependsOn]:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				local setting = self[control.dependsOn]:GetChecked()
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

function XRPOptions_Mixin:cancel()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomCancel then
			xpcall(control.CustomCancel, geterrorhandler(), control)
		else
			control:Set(control.oldValue)
			control.value = control.oldValue
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(control.value)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				for i, entry in ipairs(control.baseMenuList) do
					if entry.arg1 == control.value then
						control.Text:SetText(entry.text)
						break
					end
				end
			end
		end
		if control.dependsOn then
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self[control.dependsOn]:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				local setting = self[control.dependsOn]:GetChecked()
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

function XRPOptions_Mixin:default()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomDefault then
			xpcall(control.CustomDefault, geterrorhandler(), control)
		else
			local defaultValue
			if control.xrpTable then
				defaultValue = AddOn.DEFAULT_SETTINGS[control.xrpTable][control.xrpSetting]
			else
				defaultValue = AddOn.DEFAULT_SETTINGS[control.xrpSetting]
			end
			control:Set(defaultValue)
			control.value = defaultValue
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(control.value)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				for i, entry in ipairs(control.baseMenuList) do
					if entry.arg1 == control.value then
						control.Text:SetText(entry.text)
						break
					end
				end
			end
		end
		if control.dependsOn then
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self[control.dependsOn]:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				local setting = self[control.dependsOn]:GetChecked()
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

local OPTIONS_NAME = {
	GENERAL = GENERAL,
	DISPLAY = DISPLAY,
	CHAT = CHAT,
	TOOLTIP = L.TOOLTIP,
	ADVANCED = ADVANCED_LABEL,
}
local OPTIONS_DESCRIPTION = {
	GENERAL = L.GENERAL_OPTIONS,
	DISPLAY = L.DISPLAY_OPTIONS,
	CHAT = L.CHAT_OPTIONS,
	TOOLTIP = L.TOOLTIP_OPTIONS,
	ADVANCED = L.ADVANCED_OPTIONS,
}
function XRPOptions_Mixin:OnLoad()
	self.name = OPTIONS_NAME[self.paneID]
	self.Title:SetFormattedText(SUBTITLE_FORMAT, "XRP", self.name)
	self.SubText:SetText(OPTIONS_DESCRIPTION[self.paneID])
	self:GetParent().XRP[self.paneID] = self
	InterfaceOptions_AddCategory(self)
end

function XRPOptions_Mixin:OnShow()
	if not self.wasShown then
		self.wasShown = true
		self:refresh()
	end
	self:GetParent().XRP.lastShown = self.paneID
end

local OPTIONS_TEXT = {
	chatType = {
		SAY = SAY,
		EMOTE = EMOTE,
		YELL = YELL,
		WHISPER = WHISPER,
		GUILD = GUILD,
		OFFICER = OFFICER,
		PARTY = PARTY,
		RAID = RAID,
		INSTANCE_CHAT = INSTANCE_CHAT,
	},
	cacheRetainTime = L.CACHE_EXPIRY_TIME,
	cacheAutoClean = L.CACHE_AUTOCLEAN,
	chatNames = L.ENABLE_ROLEPLAY_NAMES,
	chatEmoteBraced = L.EMOTE_SQUARE_BRACES,
	chatReplacements = L.XT_XF_REPLACE,
	altScourge = L.ALT_RACE_SINGLE:format(L.VALUE_GR_SCOURGE_ALT, L.VALUE_GR_SCOURGE),
	altScourgeLimit = L.ALT_RACE_SINGLE_LIMIT,
	altScourgeForce = L.ALT_RACE_FORCE,
	altElven = L.ALT_RACE_CATEGORY:format(L.ALT_RACE_ELVEN),
	altElvenLimit = L.ALT_RACE_CATEGORY_LIMIT,
	altElvenForce = L.ALT_RACE_FORCE,
	altTauren = L.ALT_RACE_CATEGORY:format(L.ALT_RACE_TAUREN),
	altTaurenLimit = L.ALT_RACE_CATEGORY_LIMIT,
	altTaurenForce = L.ALT_RACE_FORCE,
	viewerMovable = L.MOVABLE_VIEWER,
	viewerCloseOnEscape = L.CLOSE_ESCAPE_VIEWER,
	friendsOnly = L.SHOW_FRIENDS_ONLY,
	friendsIncludeGuild = L.GUILD_IS_FRIENDS,
	heightUnits = L.HEIGHT_DISPLAY,
	weightUnits = L.WEIGHT_DISPLAY,
	cursorEnabled = L.DISPLAY_BOOK_CURSOR,
	cursorRightClick = L.VIEW_PROFILE_RTCLICK,
	cursorDisableInstance = L.DISABLE_INSTANCES,
	cursorDisablePvP = L.DISABLE_PVPFLAG,
	viewOnInteract = L.VIEW_PROFILE_KEYBIND,
	menusChat = L.RTCLICK_MENU_STANDARD,
	menusUnits = L.RTCLICK_MENU_UNIT,
	mainButtonEnabled = L.MINIMAP_ENABLE,
	mainButtonDetached = L.DETACH_MINIMAP,
	ldbObject = L.LDB_OBJECT,
	tooltipEnabled = L.TOOLTIP_ENABLE,
	tooltipReplace = L.REPLACE_DEFAULT_TOOLTIP,
	tooltipShowWatchEye = L.EYE_ICON_TARGET,
	tooltipShowBookmarkFlag = L.BOOKMARK_INDICATOR,
	tooltipShowExtraSpace = L.EXTRA_SPACE_TOOLTIP,
	tooltipShowHouse = L.SHOW_HOUSE_TOOLTIP,
	tooltipShowGuildRank = L.DISPLAY_GUILD_RANK,
	tooltipShowGuildIndex = L.DISPLAY_GUILD_RANK_INDEX,
	tooltipHideHostile = L.NO_HOSTILE,
	tooltipHideOppositeFaction = L.NO_OP_FACTION,
	tooltipHideInstanceCombat = L.NO_INSTANCE_COMBAT,
	tooltipHideClass = L.NO_RP_CLASS,
	tooltipHideRace = L.NO_RP_RACE,
}

function XRPOptionsControl_Mixin:OnLoad()
	if self.type == CONTROLTYPE_CHECKBOX then
		self.dependentControls = {}
	end
	if self.dependsOn then
		local depends = self:GetParent()[self.dependsOn].dependentControls
		depends[#depends + 1] = self
	end
	local optionsText = self.xrpSetting and (self.xrpTable and OPTIONS_TEXT[self.xrpTable][self.xrpSetting] or OPTIONS_TEXT[self.xrpSetting])
	if self.type == CONTROLTYPE_CHECKBOX and self.xrpSetting then
		self.Text:SetText(optionsText)
	elseif self.type == CONTROLTYPE_DROPDOWN and self.xrpSetting then
		self.Label:SetText(optionsText)
	end
	if self.textString then
		self.Text:SetText(self.textString)
	end
end

XRPOptionsCheckButton_Mixin = {}

function XRPOptionsCheckButton_Mixin:OnClick(button, down)
	local setting = self:GetChecked()
	PlaySound(setting and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	self.value = setting
	if self.dependentControls then
		for i, control in ipairs(self.dependentControls) do
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(setting)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
	if setting and self.enableWarn then
		StaticPopup_Show("XRP_ERROR", L[self.enableWarn])
	elseif not setting and self.disableWarn then
		StaticPopup_Show("XRP_ERROR", L[self.disableWarn])
	end
	self:Set(setting)
end

function XRPOptionsCheckButton_Mixin:OnEnable()
	self.Text:SetTextColor(self.Text:GetFontObject():GetTextColor())
	if self.dependentControls then
		for i, control in ipairs(self.dependentControls) do
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				if self:GetChecked() then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

function XRPOptionsCheckButton_Mixin:OnDisable()
	self.Text:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
	if self.dependentControls then
		for i, control in ipairs(self.dependentControls) do
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(false)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				UIDropDownMenu_DisableDropDown(control)
			end
		end
	end
end

local function DropDown_OnClick(self, arg1, arg2, checked)
	if not checked then
		UIDROPDOWNMENU_INIT_MENU.Text:SetText(arg2)
		UIDROPDOWNMENU_INIT_MENU.value = arg1
		UIDROPDOWNMENU_INIT_MENU:Set(arg1)
	end
end

local function DropDown_Checked(self)
	return self.arg1 == UIDROPDOWNMENU_INIT_MENU.value
end

XRPOptionsGeneralHeight_baseMenuList = {
	{ text = L.CENTIMETERS, arg1 = "cm", arg2 = L.CENTIMETERS, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.FEET_INCHES, arg1 = "ft", arg2 = L.FEET_INCHES, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.METERS, arg1 = "m", arg2 = L.METERS, checked = DropDown_Checked, func = DropDown_OnClick },
}

XRPOptionsGeneralWeight_baseMenuList = {
	{ text = L.KILOGRAMS, arg1 = "kg", arg2 = L.KILOGRAMS, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.POUNDS, arg1 = "lb", arg2 = L.POUNDS, checked = DropDown_Checked, func = DropDown_OnClick },
}

XRPOptionsAdvancedTime_baseMenuList = {
	{ text = L.TIME_1DAY, arg1 = 86400, arg2 = L.TIME_1DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.TIME_3DAY, arg1 = 259200, arg2 = L.TIME_3DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.TIME_7DAY, arg1 = 604800, arg2 = L.TIME_7DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.TIME_10DAY, arg1 = 864000, arg2 = L.TIME_10DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.TIME_2WEEK, arg1 = 1209600, arg2 = L.TIME_2WEEK, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.TIME_1MONTH, arg1 = 2419200, arg2 = L.TIME_1MONTH, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.TIME_3MONTH, arg1 = 7257600, arg2 = L.TIME_3MONTH, checked = DropDown_Checked, func = DropDown_OnClick },
}
