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
about.License:SetText([[This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.]])

about:SetScript("OnShow", function(self)
	xrp:Options("interact")
end)

local function XRPOptionsDropDown_OnClick(self, arg1, arg2, checked)
	if checked then return end
	UIDROPDOWNMENU_OPEN_MENU.menuList[UIDropDownMenu_GetSelectedID(UIDROPDOWNMENU_OPEN_MENU)].checked = nil
	UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
	UIDROPDOWNMENU_OPEN_MENU.value = self.value
	UIDROPDOWNMENU_OPEN_MENU:GetParent():Set(UIDROPDOWNMENU_OPEN_MENU.xrpTable, UIDROPDOWNMENU_OPEN_MENU.xrpSetting, self.value)
end

local XRPOptionsChatChannels_CustomRefresh
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

	local function AddChannel(channel, menuList, settingsList, seenChannels)
		local setting = xrpPrivate.settings.chat[channel]
		local oldSetting = setting
		if setting == nil then
			setting = false
		end
		if not settingsList[channel] then
			settingsList[channel] = { value = setting, oldValue = oldSetting }
		end
		menuList[#menuList + 1] = { text = channel:match("^CHAT_MSG_CHANNEL_(.+)"):lower():gsub("^%l", string.upper), arg1 = channel, arg2 = settingsList, isNotRadio = true, checked = Channels_Checked, func = Channels_OnClick, keepShownOnClick = true, }
		seenChannels[channel] = true
	end

	function XRPOptionsChatChannels_CustomRefresh(self)
		wipe(self.menuList)
		local channelList, seenChannels = ChannelsTable(GetChannelList()), {}
		for _, name in ipairs(channelList) do
			local channel = "CHAT_MSG_CHANNEL_"..name:upper()
			AddChannel(channel, self.menuList, self.settingsList, seenChannels)
		end
		for channel, setting in pairs(xrpPrivate.settings.chat) do
			if not seenChannels[channel] and channel:find("CHAT_MSG_CHANNEL_", nil, true) then
				AddChannel(channel, self.menuList, self.settingsList, seenChannels)
			end
		end
	end
end
local function XRPOptionsChatChannels_CustomOkay(self)
	for channel, control in pairs(self.settingsList) do
		control.oldValue = control.value
	end
end
local function XRPOptionsChatChannels_CustomDefault(self)
	for channel, control in pairs(self.settingsList) do
		xrpPrivate.settings.chat[channel] = nil
		control.value = nil
	end
end
local function XRPOptionsChatChannels_CustomCancel(self)
	for channel, control in pairs(self.settingsList) do
		xrpPrivate.settings.chat[channel] = control.oldValue
		control.value = control.oldValue
	end
end

function xrp:Options(pane)
	if not about.core then
		about:SetScript("OnShow", nil)
		about.core = CreateFrame("Frame", nil, about, "XRPCoreOptionsTemplate")
		about.core.Height.menuList = {
			{ text = "Centimeters", value = "cm", func = XRPOptionsDropDown_OnClick },
			{ text = "Feet/Inches", value = "ft", func = XRPOptionsDropDown_OnClick },
			{ text = "Meters", value = "m", func = XRPOptionsDropDown_OnClick },
		}
		about.core.Weight.menuList = {
			{ text = "Kilograms", value = "kg", func = XRPOptionsDropDown_OnClick },
			{ text = "Pounds", value = "lb", func = XRPOptionsDropDown_OnClick },
		}
		about.core.Time.menuList = {
			{ text = "1 day", value = 86400, func = XRPOptionsDropDown_OnClick },
			{ text = "3 days", value = 259200, func = XRPOptionsDropDown_OnClick },
			{ text = "7 days", value = 604800, func = XRPOptionsDropDown_OnClick },
			{ text = "10 days", value = 864000, func = XRPOptionsDropDown_OnClick },
			{ text = "2 weeks", value = 1209600, func = XRPOptionsDropDown_OnClick },
			{ text = "1 month", value = 2419200, func = XRPOptionsDropDown_OnClick },
			{ text = "3 months", value = 7257600, func = XRPOptionsDropDown_OnClick },
		}
		about.chat = CreateFrame("Frame", nil, about, "XRPChatOptionsTemplate")
		about.chat.Channels.CustomOkay = XRPOptionsChatChannels_CustomOkay
		about.chat.Channels.CustomRefresh = XRPOptionsChatChannels_CustomRefresh
		about.chat.Channels.CustomCancel = XRPOptionsChatChannels_CustomCancel
		about.chat.Channels.CustomDefault = XRPOptionsChatChannels_CustomDefault
		about.chat.Channels.menuList = {}
		about.chat.Channels.settingsList = {}
		about.tooltip = CreateFrame("Frame", nil, about, "XRPTooltipOptionsTemplate")
		for _, frame in ipairs(about.panes) do
			frame:refresh()
		end
		InterfaceOptionsFrame_OpenToCategory("XRP")
	end
	InterfaceOptionsFrame_OpenToCategory(about[pane] or about.core)
end
