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

local settings
do
	local default_settings = {
		emotebraced = false,
		["CHAT_MSG_SAY"] = true,
		["CHAT_MSG_YELL"] = true,
		["CHAT_MSG_EMOTE"] = true, -- CHAT_MSG_TEXT_EMOTE.
		["CHAT_MSG_GUILD"] = false, -- CHAT_MSG_OFFICER.
		["CHAT_MSG_WHISPER"] = false, -- CHAT_MSG_WHISPER_INFORM, CHAT_MSG_AFK, CHAT_MSG_DND
		["CHAT_MSG_PARTY"] = false, -- CHAT_MSG_PARTY_LEADER
		["CHAT_MSG_RAID"] = false, -- CHAT_MSG_RAID_LEADER
		["CHAT_MSG_INSTANCE_CHAT"] = false, -- CHAT_MSG_INSTANCE_CHAT_LEADER
	}

	local linked = {
		["CHAT_MSG_TEXT_EMOTE"] = "CHAT_MSG_EMOTE",
		["CHAT_MSG_OFFICER"] = "CHAT_MSG_GUILD",
		["CHAT_MSG_WHISPER_INFORM"] = "CHAT_MSG_WHISPER",
		["CHAT_MSG_AFK"] = "CHAT_MSG_WHISPER",
		["CHAT_MSG_DND"] = "CHAT_MSG_WHISPER",
		["CHAT_MSG_PARTY_LEADER"] = "CHAT_MSG_PARTY",
		["CHAT_MSG_RAID_LEADER"] = "CHAT_MSG_RAID",
		["CHAT_MSG_INSTANCE_CHAT_LEADER"] = "CHAT_MSG_INSTANCE_CHAT",
	}

	local settingsmt = {
		__index = function(self, chattype)
			-- This won't get triggered if the user's set a custom setting.
			if default_settings[chattype] ~= nil then
				return default_settings[chattype]
			elseif linked[chattype] then
				return self[linked[chattype]]
			else
				return false
			end
		end,
	}

	xrp:HookLoad(function()
		if type(xrp.settings.chatnames) ~= "table" then
			xrp.settings.chatnames = {}
		else
			-- Pre-5.4.8.0_beta2 conversion.
			if xrp.settings.chatnames["CHAT_MSG_TEXT_EMOTE"] ~= nil then
				xrp.settings.chatnames["CHAT_MSG_TEXT_EMOTE"] = nil
				xrp.settings.chatnames["CHAT_MSG_WHISPER_INFORM"] = nil
			end
			-- Pre-5.4.8.0_rc6 conversion.
			if xrp.settings.chatnames["CHAT_MSG_INSTANCE"] ~= nil then
				xrp.settings.chatnames["CHAT_MSG_INSTANCE_CHAT"] = xrp.settings.chatnames["CHAT_MSG_INSTANCE"]
				xrp.settings.chatnames["CHAT_MSG_INSTANCE"] = nil
			end
		end
		settings = setmetatable(xrp.settings.chatnames, settingsmt)
	end)
end

-- This hooks and runs at login to try and be the very last filter run as often
-- as possible. We don't want to be mucking with things in this kinda way
-- before other addons if at all possible.
xrp:HookLogin(function()
	-- /cry - I don't want to overwrite your functions, Blizzard, but you don't
	-- leave me any choice.
	function GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
		-- Emotes from ourselves don't have our name in them, and Blizzard's
		-- code can erroneously replace substrings of the emotes or of the
		-- target's name with our (colored/RP) name. Being sure to return a
		-- non-colored, non-RP name for our own text emotes fixes the issue.
		if event == "CHAT_MSG_TEXT_EMOTE" then
			if arg2 == xrp.toon.name then
				return arg2
			elseif arg12 then
				-- TEXT_EMOTE doesn't have realm attached to arg2, because
				-- Blizzard's code is missing an escape for a gsub.
				arg2 = xrp:NameWithRealm(arg2, select(7, GetPlayerInfoByGUID(arg12)))
			end
		end

		local chattype = event:sub(10)
		if chattype:sub(1, 7) == "WHISPER" then
			chattype = "WHISPER"
		elseif chattype:sub(1, 7) == "CHANNEL" then
			chattype = ("CHANNEL%u"):format(arg8)
		end

		-- RP name in channels is from case-insensitive NAME, not the number.
		if event == "CHAT_MSG_CHANNEL" and type(arg9) == "string" and arg9:find("^[^%s]+.*") then
			-- The match() strips trims names like "General - Stormwind City"
			-- down to just "General".
			event = event.."_"..arg9:match("^([^%s]+).*"):upper()
		end

		local name = settings[event] and arg12 and xrp:StripPunctuation(xrp:StripEscapes(xrp.guids[arg12].NA)) or Ambiguate(arg2, "guild")
		local nameformat = ((event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE") and settings.emotebraced and "[%s]" or "%s")..(event == "CHAT_MSG_EMOTE" and arg9 or "")

		local info = ChatTypeInfo[chattype]
		if info and info.colorNameByClass and arg12 then
			local color = RAID_CLASS_COLORS[xrp.guids[arg12].GC]
			if color and color.colorStr then
				return nameformat:format(("|c%s%s|r"):format(color.colorStr, name))
			end
		end
		return nameformat:format(name)
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", function(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...)
		if not arg12 then return false end

		-- Blizzard doesn't include the realm name in TEXT_EMOTE events because
		-- of bad string escaping practices.
		local realm = select(7, GetPlayerInfoByGUID(arg12))

		if realm and realm ~= "" then
			arg1 = arg1:gsub((xrp:NameWithRealm(arg2, realm):gsub("%-", "%%%-")), arg2, 1)
		end

		return false, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...
	end)

	-- This fixes spacing at the start of emotes when using apostrophes,
	-- commas, and colons. This requires a modified GetColoredName, so it has
	-- to go hand-in-hand with chat names.
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", function(self, event, message, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...)
		-- Some addons, but not commonly real people, use a fancy unicode
		-- apostrophe. Since Lua's string library isn't Unicode-aware, use
		-- string.byte to check first three bytes.
		local b1, b2, b3 = message:byte(1, 3)
		-- 39 = ' | 44 = , | 58 = : | 226/128/153 = ’
		if b1 == 39 or b1 == 44 or b1 == 58 or (b1 == 226 and b2 == 128 and b3 == 153) then
			-- arg9 isn't normally used for CHAT_MSG_EMOTE.
			arg9 = message:match("([^%s]*).*")
			message = message:match("[^%s]*%s*(.*)")
		end
		return false, message, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...
	end)
end)
