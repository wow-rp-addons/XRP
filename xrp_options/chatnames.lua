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
if not (select(4, GetAddOnInfo("xrp_chatnames"))) then
	return
end

local addonName, private = ...

private.chatnames = XRPOptionsChatnames
XRPOptionsChatnames = nil

local settings
do
	local channels = {}
	local chatnames_UpdateChannels
	do
		local function chatnames_UpdateChannelSetting(self, name, index, checked)
			channels[index].checked = checked
		end

		local function chatnames_Channels(...)
			local list, i = {}, 1
			while select(i, ...) do
				list[(i + 1) * 0.5] = select(i + 1, ...)
				i = i + 2
			end
			return list
		end

		function chatnames_UpdateChannels()
			wipe(channels)
			for _, name in ipairs(chatnames_Channels(GetChannelList())) do
				local channel = "CHAT_MSG_CHANNEL_"..name:upper()
				local index = #channels + 1
				channels[index] = { text = name, arg1 = channel, arg2 = index, isNotRadio = true, checked = settings[channel], func = chatnames_UpdateChannelSetting, keepShownOnClick = true, }
			end
			channels[#channels + 1] = { text = CLOSE, notCheckable = true }
		end
	end
	private.chatnames.Channels.Menu.initialize = EasyMenu_Initialize
	private.chatnames.Channels.Menu.displayMode = "MENU"
	private.chatnames.Channels.Menu.menuList = channels

	do
		local CHATNAMES_BOOLEAN = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER", "CHAT_MSG_PARTY", "CHAT_MSG_RAID", "CHAT_MSG_INSTANCE_CHAT", "emotebraced" }
		function private.chatnames:okay()
			for _, setting in ipairs(CHATNAMES_BOOLEAN) do
				settings[setting] = self[setting]:GetChecked()
			end
			for _, menu in pairs(channels) do
				if menu.text ~= CLOSE then
					settings[menu.arg1] = menu.checked
				end
			end
		end

		function private.chatnames:refresh()
			for _, setting in ipairs(CHATNAMES_BOOLEAN) do
				self[setting]:SetChecked(settings[setting])
			end
			chatnames_UpdateChannels()
		end
	end
end

function private.chatnames:default()
	for setting, _ in pairs(settings) do
		settings[setting] = nil
	end
	self:refresh()
end

private.chatnames.parent = XRP
private.chatnames.name = xrp.L["Chat Names"]
InterfaceOptions_AddCategory(private.chatnames)

xrp:HookLoad(function()
	settings = xrp.settings.chatnames
	private.chatnames:refresh()
end)
