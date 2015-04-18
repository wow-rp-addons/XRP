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

XRP_LICENSE_HEADER = _xrp.L.LICENSE_COPYRIGHT
XRP_LICENSE = _xrp.L.GPL_HEADER
XRP_CLEAR_CACHE = _xrp.L.CLEAR_CACHE
XRP_TIDY_CACHE = _xrp.L.TIDY_CACHE

function XRPOptions_Get(self)
	return _xrp.settings[self.xrpTable][self.xrpSetting]
end

function XRPOptions_Set(self, value)
	_xrp.settings[self.xrpTable][self.xrpSetting] = value
	if _xrp.settingsToggles[self.xrpTable] and _xrp.settingsToggles[self.xrpTable][self.xrpSetting] then
		_xrp.settingsToggles[self.xrpTable][self.xrpSetting](value)
	end
end

function XRPOptions_okay(self)
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomOkay then
			control:CustomOkay()
		else
			control.oldValue = control.value
		end
	end
end

function XRPOptions_refresh(self)
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomRefresh then
			control:CustomRefresh()
		else
			local setting = control:Get()
			control.value = setting
			if control.oldValue == nil then
				control.oldValue = setting
			end
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(setting)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				UIDropDownMenu_Initialize(control, control.initialize, nil, nil, control.baseMenuList)
				UIDropDownMenu_SetSelectedValue(control, setting)
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

function XRPOptions_cancel(self)
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomCancel then
			control:CustomCancel()
		else
			control:Set(control.oldValue)
			control.value = control.oldValue
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(control.value)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				UIDropDownMenu_Initialize(control, control.initialize, nil, nil, control.baseMenuList)
				UIDropDownMenu_SetSelectedValue(control, control.value)
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

function XRPOptions_default(self)
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomDefault then
			control:CustomDefault()
		else
			local defaultValue = _xrp.DEFAULT_SETTINGS[control.xrpTable][control.xrpSetting]
			control:Set(defaultValue)
			control.value = defaultValue
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(control.value)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				UIDropDownMenu_Initialize(control, control.initialize, nil, nil, control.baseMenuList)
				UIDropDownMenu_SetSelectedValue(control, control.value)
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

function XRPOptionsAbout_OnShow(self)
	if not self.wasShown then
		self.wasShown = true
		InterfaceOptionsFrame_OpenToCategory(self.GENERAL)
	elseif self.ADVANCED.AutoClean:Get() then
		self.CacheTidy:Hide()
	else
		self.CacheTidy:Show()
	end
end

local OPTIONS_NAME = {
	GENERAL = GENERAL,
	CHAT = CHAT,
	TOOLTIP = _xrp.L.TOOLTIP,
	ADVANCED = ADVANCED_LABEL,
}
local OPTIONS_DESCRIPTION = {
	GENERAL = _xrp.L.GENERAL_OPTIONS,
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
	cache = {
		time = _xrp.L.CACHE_EXPIRY_TIME,
		autoClean = _xrp.L.CACHE_AUTOCLEAN,
	},
	chat = {
		names = _xrp.L.ENABLE_ROLEPLAY_NAMES,
		emoteBraced = _xrp.L.EMOTE_SQUARE_BRACES,
		replacements = _xrp.L.XT_XF_REPLACE,
		CHAT_MSG_SAY = SAY,
		CHAT_MSG_EMOTE = EMOTE,
		CHAT_MSG_YELL = YELL,
		CHAT_MSG_WHISPER = WHISPER,
		CHAT_MSG_GUILD = GUILD,
		CHAT_MSG_PARTY = PARTY,
		CHAT_MSG_RAID = RAID,
		CHAT_MSG_INSTANCE_CHAT = INSTANCE_CHAT,
	},
	display = {
		movableViewer = _xrp.L.MOVABLE_VIEWER,
		closeOnEscapeViewer = _xrp.L.CLOSE_ESCAPE_VIEWER,
		height = _xrp.L.HEIGHT_DISPLAY,
		weight = _xrp.L.WEIGHT_DISPLAY,
	},
	interact = {
		cursor = _xrp.L.DISPLAY_BOOK_CURSOR,
		rightClick = _xrp.L.VIEW_PROFILE_RTCLICK,
		disableInstance = _xrp.L.DISABLE_INSTANCES,
		disablePvP = _xrp.L.DISABLE_PVPFLAG,
		keybind = _xrp.L.VIEW_PROFILE_KEYBIND,
	},
	menus = {
		standard = _xrp.L.RTCLICK_MENU_STANDARD,
		units = _xrp.L.RTCLICK_MENU_UNIT,
	},
	minimap = {
		enabled = _xrp.L.MINIMAP_ENABLE,
		detached = _xrp.L.DETACH_MINIMAP,
	},
	tooltip = {
		enabled = _xrp.L.TOOLTIP_ENABLE,
		replace = _xrp.L.REPLACE_DEFAULT_TOOLTIP,
		watching = _xrp.L.EYE_ICON_TARGET,
		extraSpace = _xrp.L.EXTRA_SPACE_TOOLTIP,
		guildRank = _xrp.L.DISPLAY_GUILD_RANK,
		guildIndex = _xrp.L.DISPLAY_GUILD_RANK_INDEX,
		noHostile = _xrp.L.NO_HOSTILE,
		noOpFaction = _xrp.L.NO_OP_FACTION,
		noClass = _xrp.L.NO_RP_CLASS,
		noRace = _xrp.L.NO_RP_RACE,
	},
}

function XRPOptionsControls_OnLoad(self)
	if self.type == CONTROLTYPE_CHECKBOX then
		self.dependentControls = {}
	end
	if self.dependsOn then
		local depends = self:GetParent()[self.dependsOn].dependentControls
		depends[#depends + 1] = self
	end
	if self.type == CONTROLTYPE_CHECKBOX and self.xrpSetting then
		self.Text:SetText(OPTIONS_TEXT[self.xrpTable][self.xrpSetting])
	elseif self.type == CONTROLTYPE_DROPDOWN and self.xrpSetting then
		self.Label:SetText(OPTIONS_TEXT[self.xrpTable][self.xrpSetting])
	end
	if self.textString then
		UIDropDownMenu_SetText(self, self.textString)
	end
end

function XRPOptionsCheckButton_OnClick(self, button, down)
	local setting = self:GetChecked()
	PlaySound(setting and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
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

do
	local settingsList = {}

	local function Channels_Checked(self)
		return settingsList[self.arg1].value
	end
	local function Channels_OnClick(self, channel, arg2, checked)
		settingsList[channel].value = checked
		_xrp.settings.chat[channel] = checked
	end

	local function ChannelsTable(...)
		local list, i = {}, 2
		while select(i, ...) do
			list[i * 0.5] = select(i, ...)
			i = i + 2
		end
		return list
	end

	local function AddChannel(channel, menuList)
		local setting = _xrp.settings.chat[channel]
		local oldSetting = setting
		if setting == nil then
			setting = false
		end
		if not settingsList[channel] then
			settingsList[channel] = { value = setting, oldValue = oldSetting }
		end
		menuList[#menuList + 1] = { text = channel:match("^CHAT_MSG_CHANNEL_(.+)"):lower():gsub("^%l", string.upper), arg1 = channel, isNotRadio = true, checked = Channels_Checked, func = Channels_OnClick, keepShownOnClick = true, }
	end

	function XRPOptionsChatChannels_CustomRefresh(self)
		table.wipe(self.baseMenuList)
		local seenChannels = {}
		for i, name in ipairs(ChannelsTable(GetChannelList())) do
			local channel = "CHAT_MSG_CHANNEL_" .. name:upper()
			AddChannel(channel, self.baseMenuList, settingsList)
			seenChannels[channel] = true
		end
		for channel, setting in pairs(_xrp.settings.chat) do
			if not seenChannels[channel] and channel:find("CHAT_MSG_CHANNEL_", nil, true) then
				AddChannel(channel, self.baseMenuList, settingsList)
				seenChannels[channel] = true
			end
		end
	end
	function XRPOptionsChatChannels_CustomOkay(self)
		for channel, control in pairs(settingsList) do
			control.oldValue = control.value
		end
	end
	function XRPOptionsChatChannels_CustomDefault(self)
		for channel, control in pairs(settingsList) do
			_xrp.settings.chat[channel] = nil
			control.value = nil
		end
	end
	function XRPOptionsChatChannels_CustomCancel(self)
		for channel, control in pairs(settingsList) do
			_xrp.settings.chat[channel] = control.oldValue
			control.value = control.oldValue
		end
	end
end
XRPOptionsChatChannels_baseMenuList = {}

do
	local function DropDown_OnClick(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.baseMenuList[UIDropDownMenu_GetSelectedID(UIDROPDOWNMENU_OPEN_MENU)].checked = nil
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			UIDROPDOWNMENU_OPEN_MENU.value = self.value
			UIDROPDOWNMENU_OPEN_MENU:Set(self.value)
		end
	end

	XRPOptionsGeneralHeight_baseMenuList = {
		{ text = _xrp.L.CENTIMETERS, value = "cm", func = DropDown_OnClick },
		{ text = _xrp.L.FEET_INCHES, value = "ft", func = DropDown_OnClick },
		{ text = _xrp.L.METERS, value = "m", func = DropDown_OnClick },
	}

	XRPOptionsGeneralWeight_baseMenuList = {
		{ text = _xrp.L.KILOGRAMS, value = "kg", func = DropDown_OnClick },
		{ text = _xrp.L.POUNDS, value = "lb", func = DropDown_OnClick },
	}

	XRPOptionsAdvancedTime_baseMenuList = {
		{ text = _xrp.L.TIME_1DAY, value = 86400, func = DropDown_OnClick },
		{ text = _xrp.L.TIME_3DAY, value = 259200, func = DropDown_OnClick },
		{ text = _xrp.L.TIME_7DAY, value = 604800, func = DropDown_OnClick },
		{ text = _xrp.L.TIME_10DAY, value = 864000, func = DropDown_OnClick },
		{ text = _xrp.L.TIME_2WEEK, value = 1209600, func = DropDown_OnClick },
		{ text = _xrp.L.TIME_1MONTH, value = 2419200, func = DropDown_OnClick },
		{ text = _xrp.L.TIME_3MONTH, value = 7257600, func = DropDown_OnClick },
	}
end

function _xrp.Options(pane)
	local XRPOptions = InterfaceOptionsFramePanelContainer.XRP
	if not XRPOptions.wasShown then
		XRPOptions.wasShown = true
		InterfaceOptionsFrame_OpenToCategory(XRPOptions)
	end
	InterfaceOptionsFrame_OpenToCategory(XRPOptions[pane] or XRPOptions[XRPOptions.lastShown] or XRPOptions.GENERAL)
end
