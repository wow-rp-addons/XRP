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

local addonName, _xrp = ...

-- The following chat types are linked together.
local LINKED_CHAT_MSG = {
	["CHAT_MSG_TEXT_EMOTE"] = "CHAT_MSG_EMOTE",
	["CHAT_MSG_OFFICER"] = "CHAT_MSG_GUILD",
	["CHAT_MSG_AFK"] = "CHAT_MSG_WHISPER",
	["CHAT_MSG_DND"] = "CHAT_MSG_WHISPER",
	["CHAT_MSG_PARTY_LEADER"] = "CHAT_MSG_PARTY",
	["CHAT_MSG_RAID_LEADER"] = "CHAT_MSG_RAID",
	["CHAT_MSG_RAID_WARNING"] = "CHAT_MSG_RAID",
	["CHAT_MSG_INSTANCE_CHAT_LEADER"] = "CHAT_MSG_INSTANCE_CHAT",
}

local function XRPGetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	local character = arg12 and xrp.characters.byGUID[arg12]

	-- Emotes from ourselves don't have our name in them, and Blizzard's
	-- code can erroneously replace substrings of the emotes or of the
	-- target's name with our (colored/RP) name. Being sure to return a
	-- non-colored, non-RP name for our own text emotes fixes the issue.
	if event == "CHAT_MSG_TEXT_EMOTE" then
		if arg2 == _xrp.player then
			return arg2
		elseif character then
			-- TEXT_EMOTE doesn't have realm attached to arg2, because
			-- Blizzard's code is missing an escape for a gsub.
			arg2 = tostring(character)
		end
	end

	local chatType = event:sub(10)
	do
		local shortType = chatType:sub(1, 7)
		if shortType == "WHISPER" then
			event = "CHAT_MSG_WHISPER"
			chatType = "WHISPER"
		elseif shortType == "CHANNEL" then
			event = "CHAT_MSG_CHANNEL"
			chatType = ("CHANNEL%d"):format(arg8)
		end
	end

	-- RP name in channels is from case-insensitive NAME, not the number.
	if event == "CHAT_MSG_CHANNEL" and type(arg9) == "string" and arg9 ~= "" then
		-- The match() strips trims names like "General - Stormwind City"
		-- down to just "General".
		event = "CHAT_MSG_CHANNEL_" .. arg9:match("^([^%s]+)"):upper()
	elseif LINKED_CHAT_MSG[event] then
		event = LINKED_CHAT_MSG[event]
	end

	local name = _xrp.settings.chat[event] and character and not character.hide and xrp.Strip(character.fields.NA) or Ambiguate(arg2, "guild")
	local nameFormat = event == "CHAT_MSG_EMOTE" and (_xrp.settings.chat.emoteBraced and "[%s]" or "%s") .. (arg9 or "") or "%s"

	if character and ChatTypeInfo[chatType] and ChatTypeInfo[chatType].colorNameByClass then
		local color = RAID_CLASS_COLORS[character.fields.GC]
		if color and color.colorStr then
			return nameFormat:format(("|c%s%s|r"):format(color.colorStr, name))
		end
	end
	return nameFormat:format(name)
end

local function MessageEventFilter_TEXT_EMOTE(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...)
	local character = arg12 and xrp.characters.byGUID[arg12]
	if not character then
		return false
	end

	arg1 = arg1:gsub((tostring(character):gsub("%-", "%%%-")), arg2, 1)

	return false, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...
end

-- This fixes spacing at the start of emotes when using apostrophes,
-- commas, and colons. This requires a modified GetColoredName, so it has
-- to go hand-in-hand with chat names.
local function MessageEventFilter_EMOTE(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...)
	-- Some addons, but not commonly real people, use a fancy unicode
	-- apostrophe. Since Lua's string library isn't Unicode-aware, use
	-- string.byte to check first three bytes.
	local b1, b2, b3 = arg1:byte(1, 3)
	-- 39 = ' | 44 = , | 58 = : | 226/128/153 = ’
	if b1 == 39 or b1 == 44 or b1 == 58 or b1 == 226 and b2 == 128 and b3 == 153 then
		-- arg9 isn't normally used for CHAT_MSG_EMOTE.
		arg9 = arg1:match("^([^%s]*)")
		arg1 = arg1:match("^[^%s]*%s*(.*)")
	end
	return false, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...
end

local names, adding
-- This is used to be sure that XRP's filters (which actually *MODIFY* the
-- parameters) are always run last, to avoid interfering with the use other
-- addons make of the original data.
local function ChatFrame_AddMessageEventFilter_Hook(event, filter)
	if not names or adding then return end
	if event == "CHAT_MSG_EMOTE" then
		adding = true
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", MessageEventFilter_EMOTE)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", MessageEventFilter_EMOTE)
		adding = nil
	elseif event == "CHAT_MSG_TEXT_EMOTE" then
		adding = true
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", MessageEventFilter_TEXT_EMOTE)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", MessageEventFilter_TEXT_EMOTE)
		adding = nil
	end
end

-- This replaces %xt and %xf with the target's/focus's RP name or, if that is
-- unavailable, unit name. Note that this has the minor oddity of saving the
-- replaced value in the chat history, rather than the %xt/%xf replacement
-- pattern.
local replacements
local function ParseText_Hook(line, send)
	if send == 1 and replacements then
		local oldText = line:GetText()
		local text = oldText
		if text:find("%xt", nil, true) then
			text = text:gsub("%%xt", xrp.characters.byUnit.target and xrp.Strip(xrp.characters.byUnit.target.fields.NA) or UnitName("target") or _xrp.L.NOBODY)
		end
		if text:find("%xf", nil, true) then
			text = text:gsub("%%xf", xrp.characters.byUnit.focus and xrp.Strip(xrp.characters.byUnit.focus.fields.NA) or UnitName("focus") or _xrp.L.NOBODY)
		end
		if text ~= oldText then
			line:SetText(text)
		end
	end
end

local OldGetColoredName = GetColoredName
_xrp.settingsToggles.chat = {
	names = function(setting)
		if setting then
			if names == nil then
				hooksecurefunc("ChatFrame_AddMessageEventFilter", ChatFrame_AddMessageEventFilter_Hook)
			end
			ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", MessageEventFilter_EMOTE)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", MessageEventFilter_TEXT_EMOTE)
			if GetColoredName ~= XRPGetColoredName then
				OldGetColoredName = GetColoredName
			end
			GetColoredName = XRPGetColoredName
			names = true
		elseif names ~= nil then
			ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", MessageEventFilter_EMOTE)
			ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", MessageEventFilter_TEXT_EMOTE)
			GetColoredName = OldGetColoredName
			names = false
		end
	end,
	replacements = function(setting)
		if setting then
			if replacements == nil then
				hooksecurefunc("ChatEdit_ParseText", ParseText_Hook)
			end
			replacements = true
		elseif replacements ~= nil then
			replacements = false
		end
	end,
}
