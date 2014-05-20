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

local chatnames = CreateFrame("Frame")

-- And so it begins...
local old_GetColoredName = _G.GetColoredName

local default_settings = {
	["CHAT_MSG_SAY"] = true,
	["CHAT_MSG_YELL"] = true,
	["CHAT_MSG_EMOTE"] = true,
	["CHAT_MSG_TEXT_EMOTE"] = true,
	["CHAT_MSG_GUILD"] = true,
	["CHAT_MSG_WHISPER"] = true,
	["CHAT_MSG_WHISPER_INFORM"] = true,
}

-- /cry - I don't want to overwrite your functions, Blizzard, but you don't
-- leave me any choice.
local function new_GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	local rpname = false
	if xrp_settings.chatnames[event] then
		rpname = true
	end
	if event == "CHAT_MSG_TEXT_EMOTE" and arg12 then
		-- No realm for arg2 in TEXT_EMOTEs. For whatever fucking reason.
		-- Attach it here, falling back to our own realm.
		arg2 = xrp:NameWithRealm(arg2, (select(7, GetPlayerInfoByGUID(arg12))))
	end

	local name = rpname and arg12 and xrp.guids[arg12].NA or Ambiguate(arg2, "guild")
	local chattype = event:sub(10)
	if chattype:sub(1, 7) == "WHISPER" then
		chattype = "WHISPER"
	elseif chattype:sub(1, 7) == "CHANNEL" then
		chattype = "CHANNEL"..arg8
	end

	local info = ChatTypeInfo[chattype]
	if info and info.colorNameByClass and arg12 then
		local color = RAID_CLASS_COLORS[xrp.guids[arg12].GC]
		if not color or not color.colorStr then
			return name
		end
		return format("|c%s%s|r", color.colorStr, name)
	end
	return name
end

local stripname = "^"..CHAT_EMOTE_GET:format(FULL_PLAYER_NAME:format(".-", ".-")).."(.*)$"
local function emotename(self, event, message, sender, ...)
	-- TODO: Check for GUID availability?
	-- The other half of attaching the realm name in GetColoredName is to,
	-- uh, remove it here first. Why? Fuck knows, it's Blizzard and we get
	-- things like Player-RealmName-RealmName if we don't drop it here from
	-- the message. ...Which is where the name is, because fuck knows.
	local nameless = message:match(stripname)
	if nameless then
		message = CHAT_EMOTE_GET:format(sender)..nameless
	end
	return false, message, sender, ...
end

local function chatnames_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_chatnames" then
		if type(xrp_settings.chatnames) ~= "table" then
			xrp_settings.chatnames = {}
		end
		setmetatable(xrp_settings.chatnames, { __index = default_settings })
		ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", emotename)
		self:UnregisterEvent("ADDON_LOADED")
		self:RegisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_LOGIN" then
		-- I hate this. Hate hate hate hate hate.
		_G.GetColoredName = new_GetColoredName
	end
end

chatnames:SetScript("OnEvent", chatnames_OnEvent)
chatnames:RegisterEvent("ADDON_LOADED")
