--[[
	© Justin Snelgrove

	Permission to use, copy, modify, and/or distribute this software for any
	purpose with or without fee is hereby granted, provided that the above
	copyright notice and this permission notice appear in all copies.

	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
	WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
	SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
	WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
	ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
	IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

	libmspx is based upon the reference LibMSP (public domain).
	Reference LibMSP written by Etarna Moonshyne <etarna@moonshyne.org>.

	libmspx should be able to be used as a drop-in replacement for reference
	LibMSP (v8). Some of the behaviours are subtly different from LibMSP (and
	the internals have been substantially restructured), but the API should be
	completely compatible unless you were making use of internal MSP functions.

	This library is, compared to LibMSP, higher in terms of CPU and memory
	consumption. The amount used, however, should be negligible compared to the
	increased client system requirements since the last major changes to
	LibMSP.
]]

local LIBMSPX_VERSION = 1
local LIBMSP_VERSION = 9

assert(libbw and libbw.version >= 1, "libmspx requires libbw v1 or later.")

if msp and msp.versionx and msp.versionx >= LIBMSPX_VERSION then
	return
elseif not msp then
	msp = {}
end

msp.version = LIBMSP_VERSION
msp.versionx = LIBMSPX_VERSION

-- Protocol version >= 2 indicates support for MSP-over-Battle.net. It also
-- includes MSP-over-group, but that requires a new prefix registered, so the
-- protocol version isn't the real indicator there (meaning, yes, you can do
-- version <= 1 with no Battle.net or version >= 2 with no group).
msp.protocolversion = 2

msp.callback = {
	received = {},
}

do
	local emptyMeta = {
		__index = function(self, field)
			return ""
		end,
	}

	local charMeta = {
		__index = function(self, key)
			if key == "field" then
				self[key] = setmetatable({}, emptyMeta)
				return self[key]
			elseif key == "ver" or key == "time" or key == "buffer" then
				self[key] = {}
				return self[key]
			else
				return nil
			end
		end,
	}

	msp.char = setmetatable({}, {
		__index = function(self, name)
			-- Account for unmaintained code using names without realms.
			name = msp:Name(name)
			if not rawget(self, name) then
				self[name] = setmetatable({}, charMeta)
			end
			return rawget(self, name)
		end,
	})
end

msp.my = {}
msp.myver = {}
msp.my.VP = tostring(msp.protocolversion)

local TT_LIST = { "VP", "VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "FR", "FC" }

local handlers, ttCache
do
	local Process
	do
		local requestTime = setmetatable({}, {
			__index = function(self, name)
				self[name] = {}
				return self[name]
			end,
			__mode = "v",
		})
		function Process(self, name, command, isGroup)
			local action, field, version, contents = command:match("(%p?)(%u%u)(%d*)=?(.*)")
			version = tonumber(version) or 0
			if not field then return end
			if action == "?" then
				local now = GetTime()
				-- This mitigates some potential 'denial of service' attacks
				-- against MSP.
				if isGroup then
					if requestTime.GROUP[field] and requestTime.GROUP[field] > now then
						return
					end
					requestTime.GROUP[field] = now + 2
				end
				if requestTime[name][field] and requestTime[name][field] > now then
					requestTime[name][field] = now + 5
					return
				end
				requestTime[name][field] = now + 5
				if not self.reply then
					self.reply = {}
				end
				local reply = self.reply
				if version == 0 or version ~= (self.myver[field] or 0) then
					if field == "TT" then
						if not ttCache then
							self:Update()
						end
						reply[#reply + 1] = ttCache
					elseif not self.my[field] or self.my[field] == "" then
						reply[#reply + 1] = field
					else
						reply[#reply + 1] = ("%s%u=%s"):format(field, self.myver[field], self.my[field])
					end
				else
					reply[#reply + 1] = ("!%s%u"):format(field, self.myver[field])
				end
			elseif action == "!" and version == (self.char[name].ver[field] or 0) then
				self.char[name].time[field] = GetTime()
			elseif action == "" then
				self.char[name].ver[field] = version
				self.char[name].time[field] = GetTime()
				self.char[name].field[field] = contents
				if field == "VP" then
					local VP = tonumber(contents)
					if VP then
						self.char[name].bnet = VP >= 2
					end
				end
			end
		end
	end

	handlers = {
		["MSP"] = function(self, name, message, channel)
			if message:find("\1", nil, true) then
				for command in message:gmatch("([^\1]+)\1*") do
					Process(self, name, command, channel ~= "WHISPER" and channel ~= "BN")
				end
			else
				Process(self, name, message)
			end
			for i, func in ipairs(self.callback.received) do
				pcall(func, name)
				local ambiguated = Ambiguate(name, "none")
				if ambiguated ~= name then
					-- Same thing, but for name without realm, supports
					-- unmaintained code.
					pcall(func, ambiguated)
				end
			end
			if self.reply then
				self:Send(name, self.reply, channel, true)
				self.reply = nil
			end
		end,
		["MSP\1"] = function(self, name, message, channel)
			-- This drops chunk metadata.
			self.char[name].buffer[channel] = message:gsub("^XC=%d+\1", "")
		end,
		["MSP\2"] = function(self, name, message, channel)
			local buffer = self.char[name].buffer[channel]
			if buffer then
				if type(buffer) == "table" then
					buffer[#buffer + 1] = message
				else
					self.char[name].buffer[channel] = { buffer, message }
				end
			end
		end,
		["MSP\3"] = function(self, name, message, channel)
			local buffer = self.char[name].buffer[channel]
			if buffer then
				if type(buffer) == "table" then
					buffer[#buffer + 1] = message
					handlers["MSP"](self, name, table.concat(buffer))
				else
					handlers["MSP"](self, name, buffer .. message)
				end
			end
			self.char[name].buffer[channel] = nil
		end,
		["GMSP"] = function(self, name, message, channel)
			local target, prefix, message = message:match(message:find("\30", nil, true) and "^(.-)\30([\1\2\3]?)(.+)$" or "^(.-)([\1\2\3]?)(.+)$")
			if target ~= "" and target ~= self.player then return end
			handlers[prefix ~= "" and ("MSP%s"):format(prefix) or "MSP"](self, name, message, channel)
		end,
	}
end

do
	local function BNRebuildList()
		for i = 1, select(2, BNGetNumFriends()) do
			for j = 1, BNGetNumFriendToons(i) do
				local active, toonName, client, realmName, realmID, faction, race, class, blank, zoneName, level, gameText, broadcastText, broadcastTime, isConnected, toonID = BNGetFriendToonInfo(i, j)
				if client == "WoW" then
					msp.bnet[msp:Name(toonName, realmName)] = toonID
				end
			end
		end
	end

	local raidUnits, partyUnits = {}, {}
	local inGroup = {}
	do
		local raid, party = "raid%u", "party%u"
		for i = 1, MAX_RAID_MEMBERS do
			raidUnits[#raidUnits + 1] = raid:format(i)
		end
		for i = 1, MAX_PARTY_MEMBERS do
			partyUnits[#partyUnits + 1] = party:format(i)
		end
	end

	local mspFrame = msp.dummyframex or msp.dummyframe or CreateFrame("Frame")

	-- Some addons try to mess with the old dummy frame. If they want to keep
	-- doing that, they need to update the code to handle all the new events
	-- (at minimum, BN_CHAT_MSG_ADDON).
	do
		local noFunc = function() end
		msp.dummyframe = {
			RegisterEvent = noFunc,
			UnregisterEvent = noFunc,
		}
	end

	mspFrame:SetScript("OnEvent", function(self, event, prefix, body, channel, sender)
		if event == "CHAT_MSG_ADDON" and handlers[prefix] then
			local name = msp:Name(sender)
			if name ~= msp.player then
				msp.char[name].supported = true
				msp.char[name].scantime = nil
				handlers[prefix](msp, name, body, channel)
			end
		elseif event == "BN_CHAT_MSG_ADDON" and handlers[prefix] then
			local active, toonName, client, realmName = BNGetToonInfo(sender)
			local name = msp:Name(toonName, realmName)
			msp.bnet[name] = sender

			msp.char[name].supported = true
			msp.char[name].scantime = nil
			msp.char[name].bnet = true
			handlers[prefix](msp, name, body, "BN")
		elseif event == "BN_TOON_NAME_UPDATED" or event == "BN_FRIEND_TOON_ONLINE" then
			local active, toonName, client, realmName = BNGetToonInfo(prefix)
			if client == "WoW" then
				local name = msp:Name(toonName, realmName)
				if not msp.bnet[name] and not msp.char[name].supported then
					msp.char[name].scantime = 0
				end
				msp.bnet[name] = prefix
			end
		elseif event == "GROUP_ROSTER_UPDATE" then
			local units = IsInRaid() and raidUnits or partyUnits
			local newInGroup = {}
			for i, unit in ipairs(units) do
				local name = UnitIsPlayer(unit) and msp:Name(UnitName(unit)) or nil
				if not name then break end
				if name ~= msp.player then
					if not inGroup[name] and not msp.char[name].supported then
						msp.char[name].scantime = 0
					end
					newInGroup[name] = true
				end
			end
			inGroup = newInGroup
		elseif event == "BN_CONNECTED" then
			BNRebuildList()
			self:RegisterEvent("BN_TOON_NAME_UPDATED")
			self:RegisterEvent("BN_FRIEND_TOON_ONLINE")
		elseif event == "BN_DISCONNECTED" then
			self:UnregisterEvent("BN_TOON_NAME_UPDATED")
			self:UnregisterEvent("BN_FRIEND_TOON_ONLINE")
			wipe(msp.bnet)
		end
	end)
	mspFrame:RegisterEvent("CHAT_MSG_ADDON")
	mspFrame:RegisterEvent("BN_CHAT_MSG_ADDON")
	mspFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	mspFrame:RegisterEvent("BN_CONNECTED")
	mspFrame:RegisterEvent("BN_DISCONNECTED")
	msp.bnet = {}
	if BNConnected() then
		BNRebuildList()
		mspFrame:RegisterEvent("BN_TOON_NAME_UPDATED")
		mspFrame:RegisterEvent("BN_FRIEND_TOON_ONLINE")
	end
	msp.dummyframex = mspFrame
end

for prefix, handler in pairs(handlers) do
	RegisterAddonMessagePrefix(prefix)
end

function msp:Name(name, realm)
	if not name or name == "" then
		return nil
	elseif name:find(FULL_PLAYER_NAME:format(".+", ".+")) then
		return name
	elseif realm and realm ~= "" then
		-- If a realm was provided, use it.
		return FULL_PLAYER_NAME:format(name, (realm:gsub("%s*%-*", "")))
	end
	return FULL_PLAYER_NAME:format(name, (GetRealmName():gsub("%s*%-*", "")))
end

msp.player = msp:Name(UnitName("player"))

do
	-- These fields can be positively enormous. Don't update the version on
	-- first run -- assume the addon is smart enough to load what they last
	-- left us with.
	local LONG_FIELD = { DE = true, HI = true }
	local myPrevious = {}
	function msp:Update()
		local updated, firstUpdate = false, next(myPrevious) == nil
		local tt = {}
		for field, contents in pairs(myPrevious) do
			if not self.my[field] then
				updated = true
				myPrevious[field] = ""
				self.myver[field] = (self.myver[field] or 0) + 1
			end
		end
		for field, contents in pairs(self.my) do
			if (myPrevious[field] or "") ~= contents then
				updated = true
				myPrevious[field] = contents or ""
				if field == "VP" then
					-- Since VP is always a number, just use the protocol
					-- version as the field version. Simple!
					self.myver[field] = self.protocolversion
				elseif self.myver[field] and (not firstUpdate or not LONG_FIELD[field]) then
					self.myver[field] = (self.myver[field] or 0) + 1
				elseif contents ~= "" and not self.myver[field] then
					self.myver[field] = 1
				end
			end
		end
		for i, field in ipairs(TT_LIST) do
			local contents = self.my[field]
			if not contents or contents == "" then
				tt[#tt + 1] = field
			else
				tt[#tt + 1] = ("%s%u=%s"):format(field, self.myver[field], contents)
			end
		end
		local newtt = table.concat(tt, "\1") or ""
		if ttCache ~= ("%s\1TT%u"):format(newtt, (self.myver.TT or 0)) then
			self.myver.TT = (self.myver.TT or 0) + 1
			ttCache = ("%s\1TT%u"):format(newtt, self.myver.TT)
		end
		return updated
	end
end

do
	local TT_ALONE = { "TT" }
	local PROBE_FREQUENCY = 120
	local FIELD_FREQUENCY = 15
	function msp:Request(name, fields)
		if name:match("^([^%-]+)") == UNKNOWN then
			return false
		end
		name = self:Name(name)
		local now = GetTime()
		if self.char[name].supported == false and (now < self.char[name].scantime + PROBE_FREQUENCY) then
			return false
		elseif not self.char[name].supported then
			self.char[name].supported = false
			self.char[name].scantime = now
		end
		if type(fields) == "string" and fields ~= "TT" then
			fields = { fields }
		elseif type(fields) ~= "table" then
			fields = TT_ALONE
		end
		local toSend = {}
		for i, field in ipairs(fields) do
			if not self.char[name].supported or not self.char[name].time[field] or (now > self.char[name].time[field] + FIELD_FREQUENCY) then
				if not self.char[name].supported or not self.char[name].ver[field] or self.char[name].ver[field] == 0 then
					toSend[#toSend + 1] = "?" .. field
				else
					toSend[#toSend + 1] = ("?%s%u"):format(field, self.char[name].ver[field])
				end
				-- Marking time here prevents rapid re-requesting. Also done in
				-- receive.
				self.char[name].time[field] = now
			end
		end
		if #toSend > 0 then
			self:Send(name, toSend)
			return true
		end
		return false
	end
end

do
	local AddFilter
	do
		-- This does more nuanced error filtering. It only filters errors if
		-- within 2.5s of the last addon message send time. This generally
		-- preserves the offline notices for standard whispers (except with bad
		-- timing).
		local filter = setmetatable({}, { __mode = "v" })
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, message)
			local name = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
			if not name or name == "" or not filter[name] then
				return false
			end
			local doFilter = filter[name] > (GetTime() - 2.500)
			if not doFilter then
				filter[name] = nil
			end
			return doFilter
		end)

		function AddFilter(name)
			filter[name] = GetTime()
		end
	end

	function msp:Send(name, chunks, channel, isResponse)
		local payload
		if type(chunks) == "string" then
			payload = chunks
		elseif type(chunks) == "table" then
			payload = table.concat(chunks, "\1")
		end
		if not payload then
			return 0, 0
		end

		if (not channel or channel == "BN") and self.bnet[name] then
			if not select(15, BNGetToonInfo(self.bnet[name])) then
				self.bnet[name] = nil
			elseif not channel then
				if self.char[name].bnet == false then
					channel = "GAME"
				elseif self.char[name].bnet == true then
					channel = "BN"
				end
			end
		end

		local bnParts = 0
		if (not channel or channel == "BN") and self.bnet[name] then
			local presenceID = self.bnet[name]
			local queue = ("MSP-%u"):format(presenceID)
			if #payload <= 4078 then
				libbw:BNSendGameData(presenceID, "MSP", payload, isResponse and "NORMAL" or "ALERT", queue)
				bnParts = 1
			else
				-- This line adds chunk metadata for addons which use it.
				payload = ("XC=%u\1%s"):format(((#payload + 5) / 4078) + 1, payload)
				libbw:BNSendGameData(presenceID, "MSP\1", payload:sub(1, 4078), "BULK", queue)
				local position = 4079
				bnParts = 2
				while position + 4078 <= #payload do
					libbw:BNSendGameData(presenceID, "MSP\2", payload:sub(position, position + 4077), "BULK", queue)
					position = position + 4078
					bnParts = bnParts + 1
				end
				libbw:BNSendGameData(presenceID, "MSP\3", payload:sub(position), "BULK", queue)
			end
		end

		if channel == "BN" then
			return 0, bnParts
		end

		local mspParts
		local isGroup = channel ~= "WHISPER" and UnitRealmRelationship(Ambiguate(name, "none")) == LE_REALM_RELATION_COALESCED
		channel = channel ~= "GAME" and channel or isGroup and (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID") or "WHISPER"
		local prepend = isGroup and not isResponse and character .. "\30" or ""
		local queue = isGroup and "MSP-GROUP" or ("MSP-%s"):format(name)
		local callback = not isGroup and AddFilter or nil
		local chunkSize = 255 - #prepend
		if #payload <= chunkSize then
			libbw:SendAddonMessage(not isGroup and "MSP" or "GMSP", prepend .. payload, channel, name, isResponse and "NORMAL" or "ALERT", queue, callback, name)
			mspParts = 1
		else
			chunkSize = isGroup and (chunkSize - 1) or chunkSize
			-- This line adds chunk metadata for addons which use it.
			payload = ("XC=%u\1%s"):format(((#payload + 6) / chunkSize) + 1, payload)
			libbw:SendAddonMessage(not isGroup and "MSP\1" or "GMSP", (isGroup and "%s\1%s" or "%s%s"):format(prepend, payload:sub(1, chunkSize)), channel, name, "BULK", queue, callback, name)
			local position = chunkSize + 1
			mspParts = 2
			while position + chunkSize <= #payload do
				libbw:SendAddonMessage(not isGroup and "MSP\2" or "GMSP", (isGroup and "%s\2%s" or "%s%s"):format(prepend, payload:sub(position, position + 254)), channel, name, "BULK", queue, callback, name)
				position = position + chunkSize
				mspParts = mspParts + 1
			end
			libbw:SendAddonMessage(not isGroup and "MSP\3" or "GMSP", (isGroup and "%s\3%s" or "%s%s"):format(prepend, payload:sub(position)), channel, name, "BULK", queue, callback, name)
		end

		return mspParts, bnParts
	end
end

-- GHI makes use of this. Even if not used for filtering, keep it.
function msp:PlayerKnownAbout(name)
	if not name or name == "" then
		return false
	end
	-- msp:Name() is called on this in the msp.char metatable.
	return self.char[name].supported ~= nil
end
