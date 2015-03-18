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

function XRPOptions_Get(self)
	return xrpPrivate.settings[self.xrpTable][self.xrpSetting]
end

function XRPOptions_Set(self, value)
	xrpPrivate.settings[self.xrpTable][self.xrpSetting] = value
	if xrpPrivate.settingsToggles[self.xrpTable] and xrpPrivate.settingsToggles[self.xrpTable][self.xrpSetting] then
		xrpPrivate.settingsToggles[self.xrpTable][self.xrpSetting](value)
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
			control:Set(control.defaultValue)
			control.value = control.defaultValue
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
		InterfaceOptionsFrame_OpenToCategory(self.General)
	elseif self.Advanced.AutoClean:Get() then
		self.CacheTidy:Hide()
	else
		self.CacheTidy:Show()
	end
end

function XRPOptions_OnLoad(self)
	if self.titleText then
		self.Title:SetText(self.titleText)
	end
	if self.subText then
		self.SubText:SetText(self.subText)
	end
	self:GetParent().XRP[self.name] = self
	InterfaceOptions_AddCategory(self)
end

function XRPOptions_OnShow(self)
	if not self.wasShown then
		self.wasShown = true
		self:refresh()
	end
	self:GetParent().XRP.lastShown = self.name
end

function XRPOptionsControls_OnLoad(self)
	if self.type == CONTROLTYPE_CHECKBOX then
		self.dependentControls = {}
	end
	if self.dependsOn then
		local depends = self:GetParent()[self.dependsOn].dependentControls
		depends[#depends + 1] = self
	end
	if self.textString then
		if self.type == CONTROLTYPE_CHECKBOX then
			self.Text:SetText(self.textString)
		elseif self.type == CONTROLTYPE_DROPDOWN then
			UIDropDownMenu_SetText(self, self.textString)
		end
	end
	if self.labelString then
		self.Label:SetText(self.labelString)
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

XRP_OPTIONS_AUTHOR = "|cff99b3e6Author:|r " .. GetAddOnMetadata(addonName, "Author")
XRP_OPTIONS_VERSION = "|cff99b3e6Version:|r " .. xrpPrivate.version
XRP_OPTIONS_LICENSE =
[[This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.]]

do
	local settingsList = {}

	local function Channels_Checked(self)
		return settingsList[self.arg1].value
	end
	local function Channels_OnClick(self, channel, arg2, checked)
		settingsList[channel].value = checked
		xrpPrivate.settings.chat[channel] = checked
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
		local setting = xrpPrivate.settings.chat[channel]
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
		for channel, setting in pairs(xrpPrivate.settings.chat) do
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
			xrpPrivate.settings.chat[channel] = nil
			control.value = nil
		end
	end
	function XRPOptionsChatChannels_CustomCancel(self)
		for channel, control in pairs(settingsList) do
			xrpPrivate.settings.chat[channel] = control.oldValue
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
		{ text = "Centimeters", value = "cm", func = DropDown_OnClick },
		{ text = "Feet/Inches", value = "ft", func = DropDown_OnClick },
		{ text = "Meters", value = "m", func = DropDown_OnClick },
	}

	XRPOptionsGeneralWeight_baseMenuList = {
		{ text = "Kilograms", value = "kg", func = DropDown_OnClick },
		{ text = "Pounds", value = "lb", func = DropDown_OnClick },
	}

	XRPOptionsAdvancedTime_baseMenuList = {
		{ text = "1 day", value = 86400, func = DropDown_OnClick },
		{ text = "3 days", value = 259200, func = DropDown_OnClick },
		{ text = "7 days", value = 604800, func = DropDown_OnClick },
		{ text = "10 days", value = 864000, func = DropDown_OnClick },
		{ text = "2 weeks", value = 1209600, func = DropDown_OnClick },
		{ text = "1 month", value = 2419200, func = DropDown_OnClick },
		{ text = "3 months", value = 7257600, func = DropDown_OnClick },
	}
end

function xrpPrivate:Options(pane)
	local XRPOptions = InterfaceOptionsFramePanelContainer.XRP
	if not XRPOptions.wasShown then
		XRPOptions.wasShown = true
		InterfaceOptionsFrame_OpenToCategory("XRP")
	end
	InterfaceOptionsFrame_OpenToCategory(XRPOptions[pane] or XRPOptions[XRPOptions.lastShown] or XRPOptions.General)
end
