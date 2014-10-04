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

local settings
do
	local channel_menu = {}
	xrp.options.chatnames.CHANNEL_BUTTON:SetScript("OnClick", function(self, button, down)
		EasyMenu(channel_menu, self:GetParent().CHANNEL_MENU, self, 2, 4, "MENU", nil)
	end)

	local chatnames_UpdateChannels
	do
		local function chatnames_UpdateChannelSetting(self, name, index, checked)
			channel_menu[index].checked = checked
		end

		local function chatnames_Channels(...)
			local list, p = {}, 1
			while select(p, ...) do
				list[(p + 1) * 0.5] = select(p + 1, ...)
				p = p + 2
			end
			return list
		end

		function chatnames_UpdateChannels()
			wipe(channel_menu)
			for _, name in ipairs(chatnames_Channels(GetChannelList())) do
				local channel = "CHAT_MSG_CHANNEL_"..name:upper()
				local index = #channel_menu + 1
				channel_menu[index] = { text = name, arg1 = channel, arg2 = index, isNotRadio = true, checked = settings[channel], func = chatnames_UpdateChannelSetting, keepShownOnClick = true, }
			end
			channel_menu[#channel_menu + 1] = { text = CLOSE, notCheckable = true }
		end
	end

	do
		local chatnames_types = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER", "CHAT_MSG_PARTY", "CHAT_MSG_RAID", "CHAT_MSG_INSTANCE_CHAT", "emotebraced" }
		function xrp.options.chatnames:okay()
			for _, chattype in ipairs(chatnames_types) do
				settings[chattype] = self[chattype]:GetChecked()
			end
			for _, menu in pairs(channel_menu) do
				if menu.text ~= CLOSE then
					settings[menu.arg1] = menu.checked
				end
			end
		end

		function xrp.options.chatnames:refresh()
			for _, chat in ipairs(chatnames_types) do
				self[chat]:SetChecked(settings[chat])
			end
			chatnames_UpdateChannels()
		end
	end
end

function xrp.options.chatnames:default()
	for chat, _ in pairs(settings) do
		settings[chat] = nil
	end
	self:refresh()
end

xrp.options.chatnames.parent = XRP
xrp.options.chatnames.name = xrp.L["Chat Names"]
InterfaceOptions_AddCategory(xrp.options.chatnames)

xrp:HookLoad(function()
	settings = xrp.settings.chatnames
	xrp.options.chatnames:refresh()
end)
