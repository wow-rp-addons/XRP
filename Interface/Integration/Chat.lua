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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local function XRPGetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	local character = arg12 and xrp.characters.byGUID[arg12]

	-- Emotes from ourselves don't have our name in them, and Blizzard's
	-- code can erroneously replace substrings of the emotes or of the
	-- target's name with our (colored/RP) name. Being sure to return a
	-- non-colored, non-RP name for our own text emotes fixes the issue.
	if event == "CHAT_MSG_TEXT_EMOTE" then
		if arg2 == AddOn.characterName then
			return arg2
		elseif character then
			-- TEXT_EMOTE doesn't have realm attached to arg2, because
			-- Blizzard's code is missing an escape for a gsub.
			arg2 = tostring(character)
		end
	end

	local chatType = event:sub(10)
	local chatCategory = Chat_GetChatCategory(ChatTypeGroupInverted[event] or chatType)
	if chatCategory == "CHANNEL" then
		chatType = ("CHANNEL%d"):format(arg8)
	end

	-- RP name in channels is from case-insensitive NAME, not the number.
	if (chatCategory == "CHANNEL" or chatCategory == "COMMUNITIES_CHANNEL") and type(arg9) == "string" then
		-- The match() strips trims names like "General - Stormwind City"
		-- down to just "General".
		chatCategory = "CHANNEL_" .. arg9:match("^([^%s]*)"):upper()
	end

	local name, nameFormat
	if chatCategory == "EMOTE" and arg9 == "|" then
		name = arg2:match("^[\032-\126\194-\244][\128-\191]*") or Ambiguate(arg2, "guild")
		nameFormat = "[%s]"
	else
		name = AddOn.Settings.chatType[chatCategory] and character and not character.hide and xrp.Strip(character.fields.NA) or Ambiguate(arg2, "guild")
		nameFormat = chatCategory == "EMOTE" and (AddOn.Settings.chatEmoteBraced and "[%s]" or "%s") .. (arg9 or "") or "%s"
	end

	if character and Chat_ShouldColorChatByClass(ChatTypeInfo[chatType]) then
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
	local char = arg1:match("^%s*([%z\001-\127\192-\255][\128-\191]*)")
	-- arg9 isn't normally used for CHAT_MSG_EMOTE.
	if char and (char == "'" or char == "," or char == "’") then
		-- Matches apostrophes, commas, and fancy apostrophes (addons use
		-- these).
		arg9, arg1 = arg1:match("^([^%s]*)%s*(.*)$")
	elseif char == "|" then
		-- Match any number of pipes, since it'll be an escaped pipe (||).
		arg9, arg1 = "|", arg1:match("^[%s%|]*(.*)$")
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
-- unavailable, unit name.
local replacements, newText, lastText, lastLine
local function ChatEdit_ParseText_Hook(line, send)
	if send == 1 and replacements then
		local oldText = line:GetText()
		local text = oldText
		if text:find("%xt", nil, true) then
			text = text:gsub("%%xt", xrp.characters.byUnit.target and xrp.Strip(xrp.characters.byUnit.target.fields.NA) or UnitName("target") or L.NOBODY)
		end
		if text:find("%xf", nil, true) then
			text = text:gsub("%%xf", xrp.characters.byUnit.focus and xrp.Strip(xrp.characters.byUnit.focus.fields.NA) or UnitName("focus") or L.NOBODY)
		end
		if text ~= oldText then
			newText = text
			lastLine = line
			lastText = oldText
			line:SetText(text)
		end
	end
end
-- This returns the text to its original form after being read for sending, but
-- before being saved to the chat history.
local function SubstituteChatMessageBeforeSend_Hook(text)
	if lastText and newText == text then
		lastLine:SetText(lastText)
	end
	lastText = nil
	newText = nil
	lastLine = nil
end

local pratModule
AddOn.RegisterGameEventCallback("PLAYER_LOGIN", function(event)
	-- This is done at login to account for any addon load order.
	if Prat then
		pratModule = Prat:NewModule("XRPNames")
		Prat:SetModuleDefaults(pratModule.name, {
			profile = {
				on = true,
			},
		})
		function pratModule:Prat_PreAddMessage(arg, message, frame, event)
			local character = message.GUID and xrp.characters.byGUID[message.ORG.GUID]
			if not character then
				return
			end
			local chatCategory = Chat_GetChatCategory(ChatTypeGroupInverted[event] or event:sub(10))
			if chatCategory == "CHANNEL" and type(message.ORG.CHANNEL) == "string" then
				chatCategory = "CHANNEL_" .. message.ORG.CHANNEL:upper()
			end
			local rpName = AddOn.Settings.chatType[chatCategory] and not character.hide and xrp.Strip(character.fields.NA)
			if not rpName then
				return
			end
			message.PLAYER = message.PLAYER:gsub(message.ORG.PLAYER, rpName)
			message.sS = nil
			message.SERVER = nil
			message.Ss = nil
		end
		if names then
			Prat.RegisterChatEvent(pratModule, "Prat_PreAddMessage")
		end
	end
end)

local OldGetColoredName
AddOn.SettingsToggles.chatNames = function(setting)
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
		if pratModule then
			Prat.RegisterChatEvent(pratModule, "Prat_PreAddMessage")
		end
		names = true
	elseif names ~= nil then
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", MessageEventFilter_EMOTE)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", MessageEventFilter_TEXT_EMOTE)
		GetColoredName = OldGetColoredName
		if pratModule then
			Prat.UnregisterAllChatEvents(pratModule)
		end
		names = false
	end
end

AddOn.SettingsToggles.chatReplacements = function(setting)
	if setting then
		if replacements == nil then
			hooksecurefunc("ChatEdit_ParseText", ChatEdit_ParseText_Hook)
			hooksecurefunc("SubstituteChatMessageBeforeSend", SubstituteChatMessageBeforeSend_Hook)
		end
		replacements = true
	elseif replacements ~= nil then
		replacements = false
	end
end
