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

local XRPOptions = InterfaceOptionsFramePanelContainer.XRP

function XRPOptions:Get(xrpTable, xrpSetting)
	return xrpPrivate.settings[xrpTable][xrpSetting]
end

function XRPOptions:Set(xrpTable, xrpSetting, value)
	xrpPrivate.settings[xrpTable][xrpSetting] = value
	if xrpPrivate.settingsToggles[xrpTable] and xrpPrivate.settingsToggles[xrpTable][xrpSetting] then
		xrpPrivate.settingsToggles[xrpTable][xrpSetting](value)
	end
end

XRPOptions.Author:SetText("|cff99b3e6Author:|r " .. GetAddOnMetadata(addonName, "Author"))
XRPOptions.Version:SetText("|cff99b3e6Version:|r " .. xrpPrivate.version)
XRPOptions.License:SetText(
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

	function XRPOptions.Chat.Channels:CustomRefresh()
		table.wipe(self.baseMenuList)
		local seenChannels = {}
		for i, name in ipairs(ChannelsTable(GetChannelList())) do
			local channel = "CHAT_MSG_CHANNEL_" .. name:upper()
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
function XRPOptions.Chat.Channels:CustomOkay()
	for channel, control in pairs(self.settingsList) do
		control.oldValue = control.value
	end
end
function XRPOptions.Chat.Channels:CustomDefault()
	for channel, control in pairs(self.settingsList) do
		xrpPrivate.settings.chat[channel] = nil
		control.value = nil
	end
end
function XRPOptions.Chat.Channels:CustomCancel()
	for channel, control in pairs(self.settingsList) do
		xrpPrivate.settings.chat[channel] = control.oldValue
		control.value = control.oldValue
	end
end
XRPOptions.Chat.Channels.baseMenuList = {}
XRPOptions.Chat.Channels.settingsList = {}

do
	local function DropDown_OnClick(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.baseMenuList[UIDropDownMenu_GetSelectedID(UIDROPDOWNMENU_OPEN_MENU)].checked = nil
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			UIDROPDOWNMENU_OPEN_MENU.value = self.value
			UIDROPDOWNMENU_OPEN_MENU:GetParent():Set(UIDROPDOWNMENU_OPEN_MENU.xrpTable, UIDROPDOWNMENU_OPEN_MENU.xrpSetting, self.value)
		end
	end

	XRPOptions.General.Height.baseMenuList = {
		{ text = "Centimeters", value = "cm", func = DropDown_OnClick },
		{ text = "Feet/Inches", value = "ft", func = DropDown_OnClick },
		{ text = "Meters", value = "m", func = DropDown_OnClick },
	}

	XRPOptions.General.Weight.baseMenuList = {
		{ text = "Kilograms", value = "kg", func = DropDown_OnClick },
		{ text = "Pounds", value = "lb", func = DropDown_OnClick },
	}

	XRPOptions.Advanced.Time.baseMenuList = {
		{ text = "1 day", value = 86400, func = DropDown_OnClick },
		{ text = "3 days", value = 259200, func = DropDown_OnClick },
		{ text = "7 days", value = 604800, func = DropDown_OnClick },
		{ text = "10 days", value = 864000, func = DropDown_OnClick },
		{ text = "2 weeks", value = 1209600, func = DropDown_OnClick },
		{ text = "1 month", value = 2419200, func = DropDown_OnClick },
		{ text = "3 months", value = 7257600, func = DropDown_OnClick },
	}
end

local loadedOnce
function xrpPrivate:Options(pane)
	if not loadedOnce then
		loadedOnce = true
		XRPOptions.wasShown = true
		InterfaceOptionsFrame_OpenToCategory("XRP")
	end
	InterfaceOptionsFrame_OpenToCategory(XRPOptions[pane] or XRPOptions[XRPOptions.lastShown] or XRPOptions.General)
end
