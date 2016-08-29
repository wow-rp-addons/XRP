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

XRP_LICENSE_HEADER = _xrp.L.LICENSE_COPYRIGHT
XRP_LICENSE = _xrp.L.GPL_HEADER
XRP_CLEAR_CACHE = _xrp.L.CLEAR_CACHE .. CONTINUED
XRP_TIDY_CACHE = _xrp.L.TIDY_CACHE

XRPOptionsControl_Mixin = {
	Get = function(self)
		return _xrp.settings[self.xrpTable][self.xrpSetting]
	end,
	Set = function(self, value)
		_xrp.settings[self.xrpTable][self.xrpSetting] = value
		if _xrp.settingsToggles[self.xrpTable] and _xrp.settingsToggles[self.xrpTable][self.xrpSetting] then
			_xrp.settingsToggles[self.xrpTable][self.xrpSetting](value, self.xrpSetting)
		end
	end,
}

XRPOptions_Mixin = {
	okay = function(self)
		if not self.controls then return end
		for i, control in ipairs(self.controls) do
			if control.CustomOkay then
				control:CustomOkay()
			else
				control.oldValue = control.value
			end
		end
	end,
	refresh = function(self)
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
				control:CustomCancel()
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
				control:CustomDefault()
			else
				local defaultValue = _xrp.DEFAULT_SETTINGS[control.xrpTable][control.xrpSetting]
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

function XRPOptionsAbout_OnShow(self)
	if not self.wasShown then
		self.wasShown = true
		InterfaceOptionsFrame_OpenToCategory(self.GENERAL)
	end
end

function XRPOptionsAdvancedAutoClean_OnClick(self, button, down)
	if self:Get() then
		self:GetParent().CacheTidy:Hide()
	else
		self:GetParent().CacheTidy:Show()
	end
end

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
	cache = {
		time = _xrp.L.CACHE_EXPIRY_TIME,
		autoClean = _xrp.L.CACHE_AUTOCLEAN,
	},
	chat = {
		names = _xrp.L.ENABLE_ROLEPLAY_NAMES,
		emoteBraced = _xrp.L.EMOTE_SQUARE_BRACES,
		replacements = _xrp.L.XT_XF_REPLACE,
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
	display = {
		altScourge = _xrp.L.ALT_RACE:format(_xrp.L.VALUE_GR_SCOURGE_ALT, _xrp.L.VALUE_GR_SCOURGE),
		altScourgeLimit = _xrp.L.ALT_RACE_LIMIT,
		altScourgeForce = _xrp.L.ALT_RACE_FORCE,
		altBloodElf = _xrp.L.ALT_RACE:format(_xrp.L.VALUE_GR_BLOODELF_ALT, _xrp.L.VALUE_GR_BLOODELF),
		altBloodElfLimit = _xrp.L.ALT_RACE_LIMIT,
		altBloodElfForce = _xrp.L.ALT_RACE_FORCE,
		altNightElf = _xrp.L.ALT_RACE:format(_xrp.L.VALUE_GR_NIGHTELF_ALT, _xrp.L.VALUE_GR_NIGHTELF),
		altNightElfLimit = _xrp.L.ALT_RACE_LIMIT,
		altNightElfForce = _xrp.L.ALT_RACE_FORCE,
		altTauren = _xrp.L.ALT_RACE:format(_xrp.L.VALUE_GR_TAUREN_ALT, _xrp.L.VALUE_GR_TAUREN),
		altTaurenLimit = _xrp.L.ALT_RACE_LIMIT,
		altTaurenForce = _xrp.L.ALT_RACE_FORCE,
		movableViewer = _xrp.L.MOVABLE_VIEWER,
		closeOnEscapeViewer = _xrp.L.CLOSE_ESCAPE_VIEWER,
		friendsOnly = _xrp.L.SHOW_FRIENDS_ONLY,
		guildIsFriends = _xrp.L.GUILD_IS_FRIENDS,
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
		ldbObject = _xrp.L.LDB_OBJECT,
	},
	tooltip = {
		enabled = _xrp.L.TOOLTIP_ENABLE,
		replace = _xrp.L.REPLACE_DEFAULT_TOOLTIP,
		watching = _xrp.L.EYE_ICON_TARGET,
		bookmark = _xrp.L.BOOKMARK_INDICATOR,
		extraSpace = _xrp.L.EXTRA_SPACE_TOOLTIP,
		showHouse = _xrp.L.SHOW_HOUSE_TOOLTIP,
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
		self.Text:SetText(self.textString)
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

local settingsList = {}

local function Channels_Checked(self)
	return settingsList[self.arg1].value
end
local function Channels_OnClick(self, channel, arg2, checked)
	settingsList[channel].value = checked
	_xrp.settings.chat[channel] = checked or nil
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
	local setting = _xrp.settings.chat[channel] or false
	local oldSetting = setting
	if not settingsList[channel] then
		settingsList[channel] = { value = setting, oldValue = oldSetting }
	end
	menuList[#menuList + 1] = { text = channel:match("^CHANNEL_(.+)"):lower():gsub("^%l", string.upper), arg1 = channel, isNotRadio = true, checked = Channels_Checked, func = Channels_OnClick, keepShownOnClick = true, }
end

XRPOptionsChatChannels_Mixin = {
	CustomRefresh = function(self)
		table.wipe(self.baseMenuList)
		local seenChannels = {}
		for i, name in ipairs(ChannelsTable(GetChannelList())) do
			local channel = "CHANNEL_" .. name:upper()
			AddChannel(channel, self.baseMenuList, settingsList)
			seenChannels[channel] = true
		end
		for channel, setting in pairs(_xrp.settings.chat) do
			if not seenChannels[channel] and channel:find("^CHANNEL_") then
				AddChannel(channel, self.baseMenuList, settingsList)
				seenChannels[channel] = true
			end
		end
	end,
	CustomOkay = function(self)
		for channel, control in pairs(settingsList) do
			control.oldValue = control.value
		end
	end,
	CustomDefault = function(self)
		for channel, control in pairs(settingsList) do
			_xrp.settings.chat[channel] = nil
			control.value = nil
		end
	end,
	CustomCancel = function(self)
		for channel, control in pairs(settingsList) do
			_xrp.settings.chat[channel] = control.oldValue
			control.value = control.oldValue
		end
	end,
	baseMenuList = {},
}

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

function _xrp.Options(pane)
	local XRPOptions = InterfaceOptionsFramePanelContainer.XRP
	if not XRPOptions.wasShown then
		XRPOptions.wasShown = true
		InterfaceOptionsFrame_OpenToCategory(XRPOptions)
	end
	InterfaceOptionsFrame_OpenToCategory(XRPOptions[pane] or XRPOptions[XRPOptions.lastShown] or XRPOptions.GENERAL)
end
