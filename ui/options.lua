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

local about = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer, "XRPAboutTemplate")

function about:okay()
	if not self.controls then return end
	for _, control in ipairs(self.controls) do
		if control.CustomOkay then
			control:CustomOkay()
		else
			control.oldValue = control.value
		end
	end
end

function about:refresh()
	if not self.controls then return end
	for _, control in ipairs(self.controls) do
		if control.CustomRefresh then
			control:CustomRefresh()
		else
			local setting = self:Get(control.xrpTable, control.xrpSetting)
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

function about:cancel()
	if not self.controls then return end
	for _, control in ipairs(self.controls) do
		if control.CustomCancel then
			control:CustomCancel()
		else
			self:Set(control.xrpTable, control.xrpSetting, control.oldValue)
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

function about:default()
	if not self.controls then return end
	for _, control in ipairs(self.controls) do
		if control.CustomDefault then
			control:CustomDefault()
		else
			self:Set(control.xrpTable, control.xrpSetting, control.defaultValue)
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

function about:Get(xrpTable, xrpSetting)
	return xrpPrivate.settings[xrpTable][xrpSetting]
end

function about:Set(xrpTable, xrpSetting, value)
	xrpPrivate.settings[xrpTable][xrpSetting] = value
	if xrpPrivate.settingsToggles[xrpTable] and xrpPrivate.settingsToggles[xrpTable][xrpSetting] then
		xrpPrivate.settingsToggles[xrpTable][xrpSetting](value)
	end
end

about.Author:SetText("|cff99b3e6Author:|r "..GetAddOnMetadata(addonName, "Author"))
about.Version:SetText("|cff99b3e6Version:|r "..xrpPrivate.version)
about.License:SetText(
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
)

about:SetScript("OnShow", function(self)
	if not self.core then
		xrpPrivate:Options()
	end
	if self:Get("cache", "autoClean") then
		self.CacheTidy:Hide()
	else
		self.CacheTidy:Show()
	end
end)

InterfaceOptions_AddCategory(about)

local ChatChannels_CustomRefresh
do
	local function Channels_Checked(self)
		return self.arg2[self.arg1].value
	end

	local function Channels_OnClick(self, channel, settingsList, checked)
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

	local function AddChannel(channel, menuList, settingsList)
		local setting = xrpPrivate.settings.chat[channel]
		local oldSetting = setting
		if setting == nil then
			setting = false
		end
		if not settingsList[channel] then
			settingsList[channel] = { value = setting, oldValue = oldSetting }
		end
		menuList[#menuList + 1] = { text = channel:match("^CHAT_MSG_CHANNEL_(.+)"):lower():gsub("^%l", string.upper), arg1 = channel, arg2 = settingsList, isNotRadio = true, checked = Channels_Checked, func = Channels_OnClick, keepShownOnClick = true, }
	end

	function ChatChannels_CustomRefresh(self)
		wipe(self.baseMenuList)
		local channelList, seenChannels = ChannelsTable(GetChannelList()), {}
		for _, name in ipairs(channelList) do
			local channel = "CHAT_MSG_CHANNEL_"..name:upper()
			AddChannel(channel, self.baseMenuList, self.settingsList)
			seenChannels[channel] = true
		end
		for channel, setting in pairs(xrpPrivate.settings.chat) do
			if not seenChannels[channel] and channel:find("CHAT_MSG_CHANNEL_", nil, true) then
				AddChannel(channel, self.baseMenuList, self.settingsList)
				seenChannels[channel] = true
			end
		end
	end
end
local function ChatChannels_CustomOkay(self)
	for channel, control in pairs(self.settingsList) do
		control.oldValue = control.value
	end
end
local function ChatChannels_CustomDefault(self)
	for channel, control in pairs(self.settingsList) do
		xrpPrivate.settings.chat[channel] = nil
		control.value = nil
	end
end
local function ChatChannels_CustomCancel(self)
	for channel, control in pairs(self.settingsList) do
		xrpPrivate.settings.chat[channel] = control.oldValue
		control.value = control.oldValue
	end
end

local Height_baseMenuList, Weight_baseMenuList, Time_baseMenuList
do
	local function DropDown_OnClick(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.baseMenuList[UIDropDownMenu_GetSelectedID(UIDROPDOWNMENU_OPEN_MENU)].checked = nil
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			UIDROPDOWNMENU_OPEN_MENU.value = self.value
			UIDROPDOWNMENU_OPEN_MENU:GetParent():Set(UIDROPDOWNMENU_OPEN_MENU.xrpTable, UIDROPDOWNMENU_OPEN_MENU.xrpSetting, self.value)
		end
	end

	Height_baseMenuList = {
		{ text = "Centimeters", value = "cm", func = DropDown_OnClick },
		{ text = "Feet/Inches", value = "ft", func = DropDown_OnClick },
		{ text = "Meters", value = "m", func = DropDown_OnClick },
	}

	Weight_baseMenuList = {
		{ text = "Kilograms", value = "kg", func = DropDown_OnClick },
		{ text = "Pounds", value = "lb", func = DropDown_OnClick },
	}

	Time_baseMenuList = {
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
	if not about.core then
		about.core = CreateFrame("Frame", nil, about, "XRPOptionsCoreTemplate")
		about.core.Height.baseMenuList = Height_baseMenuList
		about.core.Weight.baseMenuList = Weight_baseMenuList
		about.chat = CreateFrame("Frame", nil, about, "XRPOptionsChatTemplate")
		about.chat.Channels.CustomOkay = ChatChannels_CustomOkay
		about.chat.Channels.CustomRefresh = ChatChannels_CustomRefresh
		about.chat.Channels.CustomCancel = ChatChannels_CustomCancel
		about.chat.Channels.CustomDefault = ChatChannels_CustomDefault
		about.chat.Channels.baseMenuList = {}
		about.chat.Channels.settingsList = {}
		about.tooltip = CreateFrame("Frame", nil, about, "XRPOptionsTooltipTemplate")
		about.advanced = CreateFrame("Frame", nil, about, "XRPOptionsAdvancedTemplate")
		about.advanced.Time.baseMenuList = Time_baseMenuList
		for _, frame in ipairs(about.panes) do
			frame:refresh()
		end
		InterfaceOptionsFrame_OpenToCategory("XRP")
	end
	InterfaceOptionsFrame_OpenToCategory(about[pane] or about.core)
end
