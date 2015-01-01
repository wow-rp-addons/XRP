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
	local function emptyindex(self, key)
		return ""
	end

	local function charindex(self, key)
		if key == "field" then
			self[key] = setmetatable({}, { __index = emptyindex })
			return self[key]
		elseif key == "ver" or key == "time" or key == "buffer" then
			self[key] = {}
			return self[key]
		else 
			return nil
		end
	end

	msp.char = setmetatable({}, {
		__index = function(self, key)
			-- Account for unmaintained code using names without realms.
			local char = msp:NameWithRealm(key)
			if not rawget(self, char) then
				self[char] = setmetatable({}, { __index = charindex })
			end
			return rawget(self, char)
		end,
	})
end

msp.my = {}
msp.myver = {}
msp.my.VP = tostring(msp.protocolversion)

local MSP_FIELDS_IN_TT = { "VP", "VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "FR", "FC" }
local MSP_TT_FIELD = { VP = true, VA = true, NA = true, NH = true, NI = true, NT = true, RA = true, RC = true, CU = true, FR = true, FC = true }

local msp_tt_cache
do
	local msp_incomingchunk
	do
		local req_time = setmetatable({}, {
			__index = function(self, name)
				self[name] = {}
				return self[name]
			end,
			__mode = "v",
		})
		function msp_incomingchunk(sender, chunk)
			local head, field, ver, body = chunk:match("(%p?)(%u%u)(%d*)=?(.*)")
			ver = tonumber(ver) or 0
			if not field then return end
			if head == "?" then
				local now = GetTime()
				-- This mitigates some potential 'denial of service' attacks
				-- against MSP.
				if req_time[sender][field] and req_time[sender][field] > now - 10 then
					req_time[sender][field] = now
					return
				end
				req_time[sender][field] = now
				if not msp.reply then
					msp.reply = {}
				end
				local reply = msp.reply
				if ver == 0 or ver ~= (msp.myver[field] or 0) then
					if field == "TT" then
						if not msp_tt_cache then
							msp:Update()
						end
						reply[#reply + 1] = msp_tt_cache
					elseif not msp.my[field] or msp.my[field] == "" then
						reply[#reply + 1] = field
					else
						reply[#reply + 1] = ("%s%u=%s"):format(field, msp.myver[field], msp.my[field])
					end
				else
					reply[#reply + 1] = ("!%s%u"):format(field, msp.myver[field])
				end
			elseif head == "!" and ver == (msp.char[sender].ver[field] or 0) then
				msp.char[sender].time[field] = GetTime()
			elseif head == "" then
				msp.char[sender].ver[field] = ver
				msp.char[sender].time[field] = GetTime()
				msp.char[sender].field[field] = body
				if field == "VP" then
					local VP = tonumber(contents)
					if VP then
						msp.char[sender].bnet = VP >= 2
					end
				end
			end
		end
	end

	msp.handlers = {
		["MSP"] = function(self, sender, body, channel)
			if body ~= "" then
				if body:find("\1", nil, true) then
					for chunk in body:gmatch("([^\1]+)\1*") do
						msp_incomingchunk(sender, chunk)
					end
				else
					msp_incomingchunk(sender, body)
				end
			end
			for _, func in ipairs(self.callback.received) do
				pcall(func, sender)
				local ambiguated = Ambiguate(sender, "none")
				if ambiguated ~= sender then
					-- Same thing, but for name without realm, supports
					-- unmaintained code.
					pcall(func, ambiguated)
				end
			end
			if self.reply then
				self:Send(sender, self.reply, channel, true)
				self.reply = nil
			end
		end,
		["MSP\1"] = function(self, sender, body, channel)
			-- This drops chunk metadata.
			self.char[sender].buffer[channel] = body:gsub("^XC=%d+\1", "")
		end,
		["MSP\2"] = function(self, sender, body, channel)
			local buf = self.char[sender].buffer[channel]
			if buf then
				if type(buf) == "table" then
					buf[#buf + 1] = body
				else
					self.char[sender].buffer[channel] = { buf, body }
				end
			end
		end,
		["MSP\3"] = function(self, sender, body, channel)
			local buf = self.char[sender].buffer[channel]
			if buf then
				if type(buf) == "table" then
					buf[#buf + 1] = body
					self.handlers["MSP"](self, sender, table.concat(buf))
				else
					self.handlers["MSP"](self, sender, buf..body)
				end
			end
		end,
		["GMSP"] = function(self, sender, body, channel)
			local target, prefix, body = body:match(body:find("\30", nil, true) and "^(.+)\30([\1\2\3]?)(.+)$" or "^(.-)([\1\2\3]?)(.+)$")
			if target ~= "" and target ~= self.player then return end
			self.handlers[prefix ~= "" and ("MSP%s"):format(prefix) or "MSP"](self, sender, body, channel)
		end,
	}
end

do
	local function BNRebuildList()
		for i = 1, select(2, BNGetNumFriends()) do
			for j = 1, BNGetNumFriendToons(i) do
				local active, toonName, client, realmName, realmID, faction, race, class, blank, zoneName, level, gameText, broadcastText, broadcastTime, isConnected, toonID = BNGetFriendToonInfo(i, j)
				if client == "WoW" then
					msp.bnet[msp:NameWithRealm(toonName, realmName)] = toonID
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
		if event == "CHAT_MSG_ADDON" and msp.handlers[prefix] then
			local name = msp:NameWithRealm(sender)
			if name ~= msp.player then
				msp.char[name].supported = true
				msp.char[name].scantime = nil
				msp.handlers[prefix](msp, name, body, channel)
			end
		elseif event == "BN_CHAT_MSG_ADDON" and msp.handlers[prefix] then
			local active, toonName, client, realmName = BNGetToonInfo(sender)
			local name = msp:NameWithRealm(toonName, realmName)
			msp.bnet[name] = sender

			msp.char[name].supported = true
			msp.char[name].scantime = nil
			msp.char[name].bnet = true
			msp.handlers[prefix](msp, name, body, "BN")
		elseif event == "BN_TOON_NAME_UPDATED" or event == "BN_FRIEND_TOON_ONLINE" then
			local active, toonName, client, realmName = BNGetToonInfo(prefix)
			if client == "WoW" then
				local name = msp:NameWithRealm(toonName, realmName)
				if not msp.bnet[name] and not msp.char[name].supported then
					msp.char[name].scantime = 0
				end
				msp.bnet[name] = prefix
			end
		elseif event == "GROUP_ROSTER_UPDATE" then
			local units = IsInRaid() and raidUnits or partyUnits
			local newinGroup = {}
			for _, unit in ipairs(units) do
				local name = UnitIsPlayer(unit) and msp:NameWithRealm(UnitName(unit)) or nil
				if not name then break end
				if name ~= msp.player then
					if not inGroup[name] and not msp.char[name].supported then
						msp.char[name].nextcheck = 0
					end
					newinGroup[name] = true
				end
			end
			inGroup = newinGroup
		elseif event == "BN_CONNECTED" then
			BNRebuildList()
			self:RegisterEvent("BN_TOON_NAME_UPDATED")
			self:RegisterEvent("BN_FRIEND_TOON_ONLINE")
		elseif event == "BN_DISCONNECTED" then
			self:UnregisterEvent("BN_TOON_NAME_UPDATED")
			self:UnregisterEvent("BN_FRIEND_TOON_ONLINE")
			msp.bnet = {}
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

for prefix, handler in pairs(msp.handlers) do
	RegisterAddonMessagePrefix(prefix)
end

function msp:NameWithRealm(name, realm)
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

msp.player = msp:NameWithRealm(UnitName("player"))

do
	-- These fields are generated at runtime, meaning they always need version
	-- updates. Other fields should be loaded as they were left last session,
	-- prior to being changed in a new session.
	local MSP_RUNTIME_FIELD = { VA = true, GU = true, GS = true, GC = true, GR = true, GF = true }
	local msp_my_previous = {}
	function msp:Update()
		local updated, firstupdate = false, next(msp_my_previous) == nil
		local tt = {}
		for field, value in pairs(msp_my_previous) do
			if not self.my[field] then
				updated = true
				msp_my_previous[field] = ""
				self.myver[field] = (self.myver[field] or 0) + 1
			end
		end
		for field, value in pairs(self.my) do
			if (msp_my_previous[field] or "") ~= value then
				updated = true
				msp_my_previous[field] = value or ""
				if field == "VP" then
					-- Since VP is always a number, just use the protocol
					-- version as the field version. Simple!
					self.myver[field] = self.protocolversion
				elseif self.myver[field] and (not firstupdate or MSP_RUNTIME_FIELD[field]) then
					self.myver[field] = (self.myver[field] or 0) + 1
				elseif value ~= "" and not self.myver[field] then
					self.myver[field] = 1
				end
			end
		end
		for _, field in ipairs(MSP_FIELDS_IN_TT) do
			local value = self.my[field]
			if not value or value == "" then
				tt[#tt + 1] = field..(self.myver[field] or "")
			else
				tt[#tt + 1] = field..(self.myver[field] or "").."="..value
			end
		end
		local newtt = table.concat(tt, "\1") or ""
		if msp_tt_cache ~= newtt.."\1TT"..(self.myver.TT or 0) then
			self.myver.TT = (self.myver.TT or 0) + 1
			msp_tt_cache = newtt.."\1TT"..self.myver.TT
		end
		return updated
	end
end

do
	local MSP_TT_ALONE = { "TT" }
	local MSP_PROBE_FREQUENCY = 120
	local MSP_FIELD_UPDATE_FREQUENCY = 15
	function msp:Request(player, fields)
		if player:match("^([^%-]+)") == UNKNOWN then
			return false
		end
		player = self:NameWithRealm(player)
		local now = GetTime()
		if self.char[player].supported == false and (now < self.char[player].scantime + MSP_PROBE_FREQUENCY) then
			return false
		elseif not self.char[player].supported then
			self.char[player].supported = false
			self.char[player].scantime = now
		end
		if type(fields) == "string" and fields ~= "TT" then
			fields = { fields }
		elseif type(fields) ~= "table" then
			fields = MSP_TT_ALONE
		end
		local tosend = {}
		for _, field in ipairs(fields) do
			if not self.char[player].supported or not self.char[player].time[field] or (now > self.char[player].time[field] + MSP_FIELD_UPDATE_FREQUENCY) then
				if not self.char[player].supported or not self.char[player].ver[field] or self.char[player].ver[field] == 0 then
					tosend[#tosend + 1] = "?"..field
				else
					tosend[#tosend + 1] = "?"..field..tostring(self.char[player].ver[field])
				end
				-- Marking time here prevents rapid re-requesting. Also done in
				-- receive.
				self.char[player].time[field] = now
			end
		end
		if #tosend > 0 then
			self:Send(player, tosend)
			return true
		end
		return false
	end
end

do
	local msp_AddFilter
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
			local dofilter = filter[name] > (GetTime() - 2.500)
			if not dofilter then
				filter[name] = nil
			end
			return dofilter
		end)

		function msp_AddFilter(name)
			filter[name] = GetTime()
		end
	end

	function msp:Send(player, chunks, channel, isResponse)
		local payload
		if type(chunks) == "string" then
			payload = chunks
		elseif type(chunks) == "table" then
			payload = table.concat(chunks, "\1")
		end
		if not payload then
			return 0, 0
		end

		if (not channel or channel == "BN") and self.bnet[player] then
			if not select(15, BNGetToonInfo(self.bnet[player])) then
				self.bnet[player] = nil
			elseif not channel then
				if self.char[player].bnet == false then
					channel = "GAME"
				elseif self.char[player].bnet == true then
					channel = "BN"
				end
			end
		end

		local bnParts = 0
		if (not channel or channel == "BN") and self.bnet[player] then
			local presenceID = self.bnet[player]
			local queue = ("MSP-%u"):format(presenceID)
			if #payload <= 4078 then
				libbw:BNSendGameData(presenceID, "MSP", payload, "NORMAL", queue)
				bnParts = 1
			else
				-- This line adds chunk metadata for addons which use it.
				payload = ("XC=%u\1%s"):format(((#payload + 5) / 4078) + 1, payload)
				libbw:BNSendGameData(presenceID, "MSP\1", payload:sub(1, 4078), "BULK", queue)
				local pos = 4079
				bnParts = 2
				while pos + 4078 <= #payload do
					libbw:BNSendGameData(presenceID, "MSP\2", payload:sub(pos, pos + 4077), "BULK", queue)
					pos = pos + 4078
					bnParts = bnParts + 1
				end
				libbw:BNSendGameData(presenceID, "MSP\3", payload:sub(pos), "BULK", queue)
			end
		end
		if channel == "BN" then
			return 0, bnParts
		end

		local mspParts
		local isGroup = channel ~= "WHISPER" and UnitRealmRelationship(Ambiguate(player, "none")) == LE_REALM_RELATION_COALESCED
		channel = channel ~= "GAME" and channel or isGroup and (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID") or "WHISPER"
		local prepend = isGroup and not isResponse and character.."\30" or ""
		local queue = isGroup and "MSP-GROUP" or ("MSP-%s"):format(player)
		local callback = not isGroup and msp_AddFilter or nil
		local chunksize = 255 - #prepend
		if #payload <= chunksize then
			libbw:SendAddonMessage(not isGroup and "MSP" or "GMSP", prepend..payload, channel, player, "NORMAL", queue, callback, player)
			mspParts = 1
		else
			chunksize = isGroup and (chunksize - 1) or chunksize
			-- This line adds chunk metadata for addons which use it.
			payload = ("XC=%u\1%s"):format(((#payload + 6) / chunksize) + 1, payload)
			libbw:SendAddonMessage(not isGroup and "MSP\1" or "GMSP", prepend..(isGroup and "\1" or "")..payload:sub(1, 255), channel, player, "BULK", queue, callback, player)
			local pos = 256
			mspParts = 2
			while pos + 255 <= #payload do
				libbw:SendAddonMessage(not isGroup and "MSP\2" or "GMSP", prepend..(isGroup and "\2" or "")..payload:sub(pos, pos + 254), channel, player, "BULK", queue, callback, player)
				pos = pos + 255
				mspParts = mspParts + 1
			end
			libbw:SendAddonMessage(not isGroup and "MSP\3" or "GMSP", prepend..(isGroup and "\3" or "")..payload:sub(pos), channel, player, "BULK", queue, callback, player)
		end

		return mspParts, bnParts
	end
end

-- GHI makes use of this. Even if not used for filtering, keep it.
function msp:PlayerKnownAbout(name)
	if not name or name == "" then
		return false
	end
	return self.char[self:NameWithRealm(name)].supported ~= nil
end
