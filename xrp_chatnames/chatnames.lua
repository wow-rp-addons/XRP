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
		["CHAT_MSG_INSTANCE"] = false, -- CHAT_MSG_INSTANCE_LEADER
	}

	local linked = {
		["CHAT_MSG_TEXT_EMOTE"] = "CHAT_MSG_EMOTE",
		["CHAT_MSG_OFFICER"] = "CHAT_MSG_GUILD",
		["CHAT_MSG_WHISPER_INFORM"] = "CHAT_MSG_WHISPER",
		["CHAT_MSG_AFK"] = "CHAT_MSG_WHISPER",
		["CHAT_MSG_DND"] = "CHAT_MSG_WHISPER",
		["CHAT_MSG_PARTY_LEADER"] = "CHAT_MSG_PARTY",
		["CHAT_MSG_RAID_LEADER"] = "CHAT_MSG_RAID",
		["CHAT_MSG_INSTANCE_LEADER"] = "CHAT_MSG_INSTANCE",
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
			for _, chattype in ipairs({ "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_WHISPER_INFORM" }) do
				if xrp.settings.chatnames[chattype] ~= nil then
					xrp.settings.chatnames[chattype] = nil
				end
			end
		end
		settings = setmetatable(xrp.settings.chatnames, settingsmt)
	end)
end

-- /cry - I don't want to overwrite your functions, Blizzard, but you don't
-- leave me any choice.
function GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	if event == "CHAT_MSG_TEXT_EMOTE" and arg12 then
		-- No realm for arg2 in TEXT_EMOTEs. For whatever fucking reason.
		-- Attach it here, falling back to our own realm.
		arg2 = xrp:NameWithRealm(arg2, (select(7, GetPlayerInfoByGUID(arg12))))
	end

	local chattype = event:sub(10)
	if chattype:sub(1, 7) == "WHISPER" then
		chattype = "WHISPER"
	elseif chattype:sub(1, 7) == "CHANNEL" then
		chattype = ("CHANNEL%u"):format(arg8)
	end

	-- RP name in channels is from case-insensitive NAME, not the number.
	if event == "CHAT_MSG_CHANNEL" and type(arg9) == "string" and arg9:find("^[^%s]+.*") then
		-- The match() strips trims names like "General - Stormwind City" down
		-- to just "General".
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

ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", function(self, event, message, sender, ...)
	-- Availability of GUID for restoring the realm. Bail out if we won't be
	-- able to recover the realm name later.
	if not (select(10, ...)) then
		return false
	end

	-- The other half of attaching the realm name in GetColoredName is to, uh,
	-- remove it here first. Why? Fuck knows, it's Blizzard and we get things
	-- like Player-RealmName-RealmName if we don't drop it here from the
	-- message. ...Which is where the realm name is, because fuck knows.
	local nameless = message:match(("^"..CHAT_EMOTE_GET:format(FULL_PLAYER_NAME:format("%s", ".-")).."(.*)"):format(sender))
	if nameless then
		message = CHAT_EMOTE_GET:format(sender)..nameless
	end
	return false, message, sender, ...
end)

-- This hooks and runs at login to try and be the very last filter run as often
-- as possible. We don't want to be mucking with things in this kinda way
-- before other addons if at all possible.
xrp:HookLogin(function()
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", function(self, event, message, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...)
		if message:sub(0, 1) == "'" then
			-- arg9 isn't used for CHAT_MSG_EMOTE.
			arg9 = message:match("('[^%s]*).*")
			message = message:match("'[^%s]*%s*(.*)")
		end
		return false, message, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, ...
	end)
end)

UnitPopupButtons["XRP_VIEWPROFILE"] = { text = xrp.L["RP Profile"], dist = 0 }
table.insert(UnitPopupMenus["FRIEND"], 4, "XRP_VIEWPROFILE")
hooksecurefunc("UnitPopup_OnClick", function(self)
	if self.value == "XRP_VIEWPROFILE" then
		xrp:ShowViewerCharacter(xrp:NameWithRealm(UIDROPDOWNMENU_INIT_MENU.name))
	end
end)

hooksecurefunc("ChatEdit_ParseText", function(line, send)
	if send == 1 then
		local text = line:GetText()
		if text:find("%%xt") then
			text = text:gsub("%%xt", UnitExists("target") and (xrp.units.target and xrp.units.target.NA or "%%t") or xrp.L["nobody"])
		end
		if text:find("%%xf") then
			text = text:gsub("%%xf", UnitExists("focus") and (xrp.units.focus and xrp.units.focus.NA or "%%f") or xrp.L["nobody"])
		end
		if text ~= line:GetText() then
			line:SetText(text)
		end
	end
end)
