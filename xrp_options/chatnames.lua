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

local chatnames_types = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER" }

local function chatnames_Okay()
	for _, chat in pairs(chatnames_types) do
		xrp_settings.chatnames[chat] = xrp.options.chatnames[chat]:GetChecked() and true or false
		if chat == "CHAT_MSG_WHISPER" then
			xrp_settings.chatnames["CHAT_MSG_WHISPER_INFORM"] = xrp.options.chatnames[chat]:GetChecked() and true or false
		elseif chat == "CHAT_MSG_EMOTE" then
			xrp_settings.chatnames["CHAT_MSG_TEXT_EMOTE"] = xrp.options.chatnames[chat]:GetChecked() and true or false
		end
	end
end

local function chatnames_Default()
	for _, chat in pairs(chatnames_types) do
		xrp.options.chatnames[chat]:SetChecked(true)
	end
end

local function chatnames_Refresh()
	for _, chat in pairs(chatnames_types) do
		xrp.options.chatnames[chat]:SetChecked(xrp_settings.chatnames[chat] == nil and true or xrp_settings.chatnames[chat])
	end
end

local function chatnames_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_options" then

		local name, title, notes, enabled, loadable, readon = GetAddOnInfo("xrp_chatnames")
		self.name = "Chat Names"
		self.refresh = chatnames_Refresh
		self.okay = chatnames_Okay
		self.default = chatnames_Default
		self.parent = XRP

		if enabled then
			InterfaceOptions_AddCategory(self)
			chatnames_Refresh()
		end

		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrp.options.chatnames:SetScript("OnEvent", chatnames_OnEvent)
xrp.options.chatnames:RegisterEvent("ADDON_LOADED")
