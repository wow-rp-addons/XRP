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

XRPOptionsControl_Mixin = {
	Get = function(self)
		local settingsTable = _xrp.settings
		if self.xrpTable then
			settingsTable = _xrp.settings[self.xrpTable]
		end
		return settingsTable[self.xrpSetting]
	end,
	Set = function(self, value)
		local settingsTable = _xrp.settings
		if self.xrpTable then
			settingsTable = _xrp.settings[self.xrpTable]
		end
		settingsTable[self.xrpSetting] = value
		local settingsToggleTable = _xrp.settingsToggles
		if self.xrpTable then
			settingsToggleTable = _xrp.settingsToggles[self.xrpTable]
		end
		if settingsToggleTable[self.xrpSetting] then
			xpcall(settingsToggleTable[self.xrpSetting], geterrorhandler(), value, self.xrpSetting)
		end
	end,
}

XRPOptions_Mixin = {
	okay = function(self)
		if not self.controls then return end
		for i, control in ipairs(self.controls) do
			if control.CustomOkay then
				xpcall(control.CustomOkay, geterrorhandler(), control)
			else
				control.oldValue = control.value
			end
		end
	end,
	refresh = function(self)
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
	end,
	cancel = function(self)
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
	end,
	default = function(self)
		if not self.controls then return end
		for i, control in ipairs(self.controls) do
			if control.CustomDefault then
				xpcall(control.CustomDefault, geterrorhandler(), control)
			else
				local defaultValue
				if control.xrpTable then
					defaultValue = _xrp.DEFAULT_SETTINGS[control.xrpTable][control.xrpSetting]
				else
					defaultValue = _xrp.DEFAULT_SETTINGS[control.xrpSetting]
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
	end,
}

local OPTIONS_NAME = {
	GENERAL = GENERAL,
	DISPLAY = DISPLAY,
	CHAT = CHAT,
	TOOLTIP = _xrp.L.TOOLTIP,
	ADVANCED = ADVANCED_LABEL,
}
local OPTIONS_DESCRIPTION = {
	GENERAL = _xrp.L.GENERAL_OPTIONS,
	DISPLAY = _xrp.L.DISPLAY_OPTIONS,
	CHAT = _xrp.L.CHAT_OPTIONS,
	TOOLTIP = _xrp.L.TOOLTIP_OPTIONS,
	ADVANCED = _xrp.L.ADVANCED_OPTIONS,
}
function XRPOptions_OnLoad(self)
	self.name = OPTIONS_NAME[self.paneID]
	self.Title:SetFormattedText(SUBTITLE_FORMAT, "XRP", self.name)
	self.SubText:SetText(OPTIONS_DESCRIPTION[self.paneID])
	self:GetParent().XRP[self.paneID] = self
	InterfaceOptions_AddCategory(self)
end

function XRPOptions_OnShow(self)
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
	cacheRetainTime = _xrp.L.CACHE_EXPIRY_TIME,
	cacheAutoClean = _xrp.L.CACHE_AUTOCLEAN,
	chatNames = _xrp.L.ENABLE_ROLEPLAY_NAMES,
	chatEmoteBraced = _xrp.L.EMOTE_SQUARE_BRACES,
	chatReplacements = _xrp.L.XT_XF_REPLACE,
	altScourge = _xrp.L.ALT_RACE_SINGLE:format(_xrp.L.VALUE_GR_SCOURGE_ALT, _xrp.L.VALUE_GR_SCOURGE),
	altScourgeLimit = _xrp.L.ALT_RACE_SINGLE_LIMIT,
	altScourgeForce = _xrp.L.ALT_RACE_FORCE,
	altElven = _xrp.L.ALT_RACE_CATEGORY:format(_xrp.L.ALT_RACE_ELVEN),
	altElvenLimit = _xrp.L.ALT_RACE_CATEGORY_LIMIT,
	altElvenForce = _xrp.L.ALT_RACE_FORCE,
	altTauren = _xrp.L.ALT_RACE_CATEGORY:format(_xrp.L.ALT_RACE_TAUREN),
	altTaurenLimit = _xrp.L.ALT_RACE_CATEGORY_LIMIT,
	altTaurenForce = _xrp.L.ALT_RACE_FORCE,
	viewerMovable = _xrp.L.MOVABLE_VIEWER,
	viewerCloseOnEscape = _xrp.L.CLOSE_ESCAPE_VIEWER,
	friendsOnly = _xrp.L.SHOW_FRIENDS_ONLY,
	friendsIncludeGuild = _xrp.L.GUILD_IS_FRIENDS,
	heightUnits = _xrp.L.HEIGHT_DISPLAY,
	weightUnits = _xrp.L.WEIGHT_DISPLAY,
	cursorEnabled = _xrp.L.DISPLAY_BOOK_CURSOR,
	cursorRightClick = _xrp.L.VIEW_PROFILE_RTCLICK,
	cursorDisableInstance = _xrp.L.DISABLE_INSTANCES,
	cursorDisablePvP = _xrp.L.DISABLE_PVPFLAG,
	viewOnInteract = _xrp.L.VIEW_PROFILE_KEYBIND,
	menusChat = _xrp.L.RTCLICK_MENU_STANDARD,
	menusUnits = _xrp.L.RTCLICK_MENU_UNIT,
	mainButtonEnabled = _xrp.L.MINIMAP_ENABLE,
	mainButtonDetached = _xrp.L.DETACH_MINIMAP,
	ldbObject = _xrp.L.LDB_OBJECT,
	tooltipEnabled = _xrp.L.TOOLTIP_ENABLE,
	tooltipReplace = _xrp.L.REPLACE_DEFAULT_TOOLTIP,
	tooltipShowWatchEye = _xrp.L.EYE_ICON_TARGET,
	tooltipShowBookmarkFlag = _xrp.L.BOOKMARK_INDICATOR,
	tooltipShowExtraSpace = _xrp.L.EXTRA_SPACE_TOOLTIP,
	tooltipShowHouse = _xrp.L.SHOW_HOUSE_TOOLTIP,
	tooltipShowGuildRank = _xrp.L.DISPLAY_GUILD_RANK,
	tooltipShowGuildIndex = _xrp.L.DISPLAY_GUILD_RANK_INDEX,
	tooltipHideHostile = _xrp.L.NO_HOSTILE,
	tooltipHideOppositeFaction = _xrp.L.NO_OP_FACTION,
	tooltipHideInstanceCombat = _xrp.L.NO_INSTANCE_COMBAT,
	tooltipHideClass = _xrp.L.NO_RP_CLASS,
	tooltipHideRace = _xrp.L.NO_RP_RACE,
}

function XRPOptionsControls_OnLoad(self)
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

function XRPOptionsCheckButton_OnClick(self, button, down)
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
		StaticPopup_Show("XRP_ERROR", _xrp.L[self.enableWarn])
	elseif not setting and self.disableWarn then
		StaticPopup_Show("XRP_ERROR", _xrp.L[self.disableWarn])
	end
	self:Set(setting)
end

function XRPOptionsCheckButton_OnEnable(self)
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

function XRPOptionsCheckButton_OnDisable(self)
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
	{ text = _xrp.L.CENTIMETERS, arg1 = "cm", arg2 = _xrp.L.CENTIMETERS, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.FEET_INCHES, arg1 = "ft", arg2 = _xrp.L.FEET_INCHES, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.METERS, arg1 = "m", arg2 = _xrp.L.METERS, checked = DropDown_Checked, func = DropDown_OnClick },
}

XRPOptionsGeneralWeight_baseMenuList = {
	{ text = _xrp.L.KILOGRAMS, arg1 = "kg", arg2 = _xrp.L.KILOGRAMS, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.POUNDS, arg1 = "lb", arg2 = _xrp.L.POUNDS, checked = DropDown_Checked, func = DropDown_OnClick },
}

XRPOptionsAdvancedTime_baseMenuList = {
	{ text = _xrp.L.TIME_1DAY, arg1 = 86400, arg2 = _xrp.L.TIME_1DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.TIME_3DAY, arg1 = 259200, arg2 = _xrp.L.TIME_3DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.TIME_7DAY, arg1 = 604800, arg2 = _xrp.L.TIME_7DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.TIME_10DAY, arg1 = 864000, arg2 = _xrp.L.TIME_10DAY, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.TIME_2WEEK, arg1 = 1209600, arg2 = _xrp.L.TIME_2WEEK, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.TIME_1MONTH, arg1 = 2419200, arg2 = _xrp.L.TIME_1MONTH, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = _xrp.L.TIME_3MONTH, arg1 = 7257600, arg2 = _xrp.L.TIME_3MONTH, checked = DropDown_Checked, func = DropDown_OnClick },
}
