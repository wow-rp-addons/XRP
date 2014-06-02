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

local chatnames_types = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER", "CHAT_MSG_PARTY", "CHAT_MSG_RAID", "CHAT_MSG_INSTANCE", "CHAT_MSG_CHANNEL" }

local channel_menu = {}
local channel_list = {}

local function chatnames_Channels(...)
	local p = 1
	local list = {}
	while select(p, ...) do
		list[select(p, ...)] = select(p + 1, ...)
		p = p + 2
	end
	return list
end

local function chatnames_UpdateChannelSetting(self, arg1, arg2, checked)
	channel_list[arg1].checked = not checked
end

local function chatnames_UpdateChannels()
	local chanlist = chatnames_Channels(GetChannelList())
	wipe(channel_menu)
	wipe(channel_list)
	for _, name in ipairs(chanlist) do
		channel = "CHAT_MSG_CHANNEL_"..name:upper()
		channel_menu[#channel_menu + 1] = { text = name, arg1 = channel, isNotRadio = true, checked = xrp_settings.chatnames[channel], func = chatnames_UpdateChannelSetting }
		channel_list[channel] = channel_menu[#channel_menu]
	end
	channel_menu[#channel_menu + 1] = { text = CLOSE, notCheckable = true }
end

local function chatnames_Okay()
	for _, chattype in ipairs(chatnames_types) do
		xrp_settings.chatnames[chattype] = xrp.options.chatnames[chattype]:GetChecked() and true or false
	end
	for chattype, menu in pairs(channel_list) do
		if menu.text ~= CLOSE then
			xrp_settings.chatnames[chattype] = menu.checked
		end
	end
end

local function chatnames_Refresh()
	for _, chat in ipairs(chatnames_types) do
		xrp.options.chatnames[chat]:SetChecked(xrp_settings.chatnames[chat])
	end
	chatnames_UpdateChannels()
end

local function chatnames_Default()
	for chat, _ in pairs(xrp_settings.chatnames) do
		xrp_settings.chatnames[chat] = nil
	end
	chatnames_Refresh()
end

local function chatnames_ChannelButton_OnClick(self, button, down)
	EasyMenu(channel_menu, self:GetParent().CHANNEL_MENU, self, 3, 10, "MENU", nil)
end

local function chatnames_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_options" then

		if (select(4, GetAddOnInfo("xrp_chatnames"))) then
			self.name = xrp.L["Chat Names"]
			self.refresh = chatnames_Refresh
			self.okay = chatnames_Okay
			self.default = chatnames_Default
			self.parent = XRP
			self.CHANNEL_BUTTON:SetScript("OnClick", chatnames_ChannelButton_OnClick)
			InterfaceOptions_AddCategory(self)
			chatnames_Refresh()
		end

		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrp.options.chatnames:SetScript("OnEvent", chatnames_OnEvent)
xrp.options.chatnames:RegisterEvent("ADDON_LOADED")
