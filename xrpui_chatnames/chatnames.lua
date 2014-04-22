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

-- And so it begins...
local old_GetColoredName = GetColoredName

-- Keys are names with realms. -1 means never use an RP name, 0 means try
-- using an RP name (and filter errors), 1 means always use an RP name.
local chatnames_filter = {}

local chatnames_languages = {
	["Common"] = "Alliance",
	["Dwarvish"] = "Alliance",
	["Gnomish"] = "Alliance",
	["Draenei"] = "Alliance",
	["Darnassian"] = "Alliance",
	["Orcish"] = "Horde",
	["Troll"] = "Horde",
	["Taurahe"] = "Horde",
	["Gutterspeak"] = "Horde",
	["Thalassian"] = "Horde",
	["Goblin"] = "Horde",
	["Pandaren"] = "Neutral",
}

local chatnames_races = {
	["Human"] = "Alliance",
	["Dwarf"] = "Alliance",
	["Gnome"] = "Alliance",
	["Draenei"] = "Alliance",
	["NightElf"] = "Alliance",
	["Worgen"] = "Alliance",
	["Orc"] = "Horde",
	["Troll"] = "Horde",
	["Tauren"] = "Horde",
	["Scourge"] = "Horde",
	["BloodElf"] = "Horde",
	["Goblin"] = "Horde",
	["Pandaren"] = "Neutral",
}

local chatnames_events = {
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
function new_GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	local rpname = false
	local GC, GR, _
	if arg12 then
		_, GC, _, GR, _, _, _ = GetPlayerInfoByGUID(arg12)
	end
	if chatnames_filter[arg2] == -1 or not chatnames_events[event] then
		rpname = false
	elseif chatnames_filter[arg2] == 1 then
		rpname = true
	elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" then
		-- Filter faction by language. Except pandas.
		if chatnames_languages[arg3] == xrp.toon.fields.GF then
			rpname = true
			chatnames_filter[arg2] = 1
		elseif chatname_languages[arg3] == "Neutral" then
			rpname = true
			chatnames_filter[arg2] = chatnames_filter[arg2] or 0
		end
	elseif event == "CHAT_MSG_EMOTE" then
		-- Filter faction by "makes some strange gestures.", race.
		if GR and chatnames_races[GR] == xrp.toon.fields.GF then
			rpname = true
			chatnames_filter[arg2] = 1
		elseif arg1 == CHAT_EMOTE_UNKNOWN then
			chatnames_filter[arg2] = -1
		else -- Might be a friendly panda, can't guarantee GR.
			rpname = true
			chatnames_filter[arg2] = 0
		end
	elseif event == "CHAT_MSG_TEXT_EMOTE" then
		-- Try filtering by race.
		if GR and chatnames_races[GR] == xrp.toon.fields.GF then
			rpname = true
			chatnames_filter[arg2] = 1
		else -- Might be a friendly panda, can't guarantee GR.
			rpname = true
			chatnames_filter[arg2] = 0
		end
	elseif event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		rpname = true
		chatnames_filter[arg2] = 1
	end

	local arg2orig = arg2
	if rpname then
		arg2 = xrp.characters[arg2].NA
	else
		arg2 = Ambiguate(arg2, "guild")
	end
	if GC or (rpname and xrp.characters[arg2orig].GC) then
		GC = GC or xrp.characters[arg2orig].GC
		if GC then
			local color = RAID_CLASS_COLORS[GC]
			if not color then
				return arg2
			end
			return string.format("\124c%s%s\124r", color.colorStr, arg2)
		end
	end
	return arg2
end

local function chatnames_msp_receive(character)
	chatnames_filter[character] = 1
end

-- I was working so, so hard to avoid having to do this... /sob
local function chatnames_filter_error(self, event, message)
	local character = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
	if character == nil or character == "" then
		return false
	end
	local filter = chatnames_filter[character] == 0
	chatnames_filter[character] = -1
	return filter
end

local function chatnames_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrpui_chatnames" then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", chatnames_filter_error)
		xrp:HookEvent("MSP_RECEIVE", chatnames_msp_receive)
		self:UnregisterEvent("ADDON_LOADED")
		self:RegisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_LOGIN" then
		GetColoredName = new_GetColoredName
	end
end

xrpui.chatnames:SetScript("OnEvent", chatnames_OnEvent)
xrpui.chatnames:RegisterEvent("ADDON_LOADED")
