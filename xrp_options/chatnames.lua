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

do
	local channel_menu = {}
	xrp.options.chatnames.CHANNEL_BUTTON:SetScript("OnClick", function(self, button, down)
		EasyMenu(channel_menu, self:GetParent().CHANNEL_MENU, self, 2, 4, "MENU", nil)
	end)

	-- TODO: Get rid of channel_list if possible (UpdateChannelSetting).
	local channel_list = {}
	local chatnames_UpdateChannels
	do
		local function chatnames_UpdateChannelSetting(self, arg1, arg2, checked)
			channel_list[arg1].checked = not checked
		end

		local function chatnames_Channels(...)
			local p = 1
			local list = {}
			while select(p, ...) do
				list[(p + 1) * 0.5] = select(p + 1, ...)
				p = p + 2
			end
			return list
		end

		function chatnames_UpdateChannels()
			wipe(channel_menu)
			wipe(channel_list)
			for _, name in ipairs(chatnames_Channels(GetChannelList())) do
				local channel = "CHAT_MSG_CHANNEL_"..name:upper()
				channel_menu[#channel_menu + 1] = { text = name, arg1 = channel, isNotRadio = true, checked = xrp_settings.chatnames[channel], func = chatnames_UpdateChannelSetting }
				channel_list[channel] = channel_menu[#channel_menu]
			end
			channel_menu[#channel_menu + 1] = { text = CLOSE, notCheckable = true }
		end
	end

	do
		local chatnames_types = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER", "CHAT_MSG_PARTY", "CHAT_MSG_RAID", "CHAT_MSG_INSTANCE" }
		function xrp.options.chatnames:okay()
			for _, chattype in ipairs(chatnames_types) do
				xrp_settings.chatnames[chattype] = xrp.options.chatnames[chattype]:GetChecked() and true or false
			end
			for chattype, menu in pairs(channel_list) do
				if menu.text ~= CLOSE then
					xrp_settings.chatnames[chattype] = menu.checked
				end
			end
		end

		function xrp.options.chatnames:refresh()
			for _, chat in ipairs(chatnames_types) do
				xrp.options.chatnames[chat]:SetChecked(xrp_settings.chatnames[chat])
			end
			chatnames_UpdateChannels()
		end
	end
end

function xrp.options.chatnames:default()
	for chat, _ in pairs(xrp_settings.chatnames) do
		xrp_settings.chatnames[chat] = nil
	end
	self:refresh()
end

xrp.options.chatnames.parent = XRP
xrp.options.chatnames.name = xrp.L["Chat Names"]
InterfaceOptions_AddCategory(xrp.options.chatnames)

xrp:HookLoad(function()
	xrp.options.chatnames:refresh()
end)
