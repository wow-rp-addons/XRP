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

xrp.chatnames = CreateFrame("Frame", nil, xrp)

-- And so it begins...
local old_GetColoredName = GetColoredName

-- Keys are names with realms. -1 means never use an RP name, 0 means try
-- using an RP name (and filter errors), 1 means always use an RP name. This
-- tries as hard as it can to keep the amount set to 0 as low as possible. XRP
-- does not appreciate filtering error messages (particularly since they often
-- reveal something wrong happening in the code).
local filter = {}

local languages = {
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
	["Pandaren"] = "Neutral", -- Yet pandas still can't talk cross-faction...
}

local races = {
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
	["Pandaren"] = "Neutral", -- They're separate races under-the-hood...
}

local events = {
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
	local rp = false
	local GC, GR, realm, _
	if arg12 then
		_, GC, _, GR, _, _, realm = GetPlayerInfoByGUID(arg12)
	end
	if event == "CHAT_MSG_TEXT_EMOTE" and realm then
		-- No realm for arg2 in TEXT_EMOTEs. For whatever fucking reason.
		-- Attach it here... except there isn't a realm for same-realm from
		-- GetPlayerInfoByGUID. So run it through xrp:NameWithRealm()... After
		-- removing the possibly-dangling dash, so xrp:NameWithRealm doesn't
		-- get confused. Got all that? There will be a test.
		arg2 = xrp:NameWithRealm((format("%s-%s", arg2, realm):gsub("-$", "")))
	end
	if filter[arg2] == -1 or not events[event] or not xrp_settings.chatnames[event] then
		rp = false
	elseif filter[arg2] == 1 then
		rp = true
	elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" then
		-- Filter faction by language. Only pandas speaking in nommish won't
		-- get caught by this.
		if languages[arg3] == xrp.toon.fields.GF then
			rp = true
			filter[arg2] = 1
		elseif languages[arg3] == "Neutral" then
			rp = true
			filter[arg2] = filter[arg2] or 0
		else -- Not friendly, not neutral, must be enemy.
			filter[arg2] = -1
		end
	elseif event == "CHAT_MSG_EMOTE" then
		-- Filter faction by "makes some strange gestures.", race.
		if GR and races[GR] == xrp.toon.fields.GF then
			rp = true
			filter[arg2] = 1
		elseif arg1 == CHAT_EMOTE_UNKNOWN then
			filter[arg2] = -1
		else -- Probably a friendly panda, but can't be positive.
			rp = true
			filter[arg2] = 0
		end
	elseif event == "CHAT_MSG_TEXT_EMOTE" then
		-- Try filtering by race.
		if GR and races[GR] == xrp.toon.fields.GF then
			rp = true
			filter[arg2] = 1
		elseif GR and races[GR] == "Neutral" then -- Panda, might be friendly.
			rp = true
			filter[arg2] = 0
		end
	elseif event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		rp = true
		filter[arg2] = 1
	end

	local rpname
	if rp then
		rpname = xrp.characters[arg2].NA
		if not rpname then
			rpname = Ambiguate(arg2, "guild")
		end
	else
		rpname = Ambiguate(arg2, "guild")
	end
	if GC or (rp and xrp.characters[arg2].GC) then
		GC = GC or xrp.characters[arg2].GC
		if GC then
			local color = RAID_CLASS_COLORS[GC]
			if not color then
				return rpname
			end
			return format("\124c%s%s\124r", color.colorStr, rpname)
		end
	end
	return rpname
end

local function msp_receive(character)
	filter[character] = 1
end

-- I was working so, so hard to avoid having to do this... /sob
local function filter_error(self, event, message)
	local character = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
	if character == nil or character == "" then
		return false
	end
	local dofilter = filter[character] == 0
	filter[character] = -1
	return dofilter
end

local function emotename(self, event, message, sender, ...)
	-- The other half of attaching the realm name in GetColoredName is to,
	-- uh, remove it here first. Why? Fuck knows, it's Blizzard and we get
	-- things like Player-RealmName-RealmName if we don't drop it here from
	-- the message. ...Which is where the name is, because fuck knows.
	message = format("%s %s", sender, message:match("^[^%s]*%s+(.*)"))
	return false, message, sender, ...
end

local function chatnames_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_chatnames" then
		if type(xrp_settings.chatnames) ~= "table" then
			xrp_settings.chatnames = {}
		end
		setmetatable(xrp_settings.chatnames, { __index = events})
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filter_error)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", emotename)
		xrp:HookEvent("MSP_RECEIVE", msp_receive)
		self:UnregisterEvent("ADDON_LOADED")
		self:RegisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_LOGIN" then
		-- I hate this. Hate hate hate hate hate.
		GetColoredName = new_GetColoredName
	end
end

xrp.chatnames:SetScript("OnEvent", chatnames_OnEvent)
xrp.chatnames:RegisterEvent("ADDON_LOADED")
