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

local disabled = false
if not msp_RPAddOn then
	msp_RPAddOn = GetAddOnMetadata(addonName, "Title")
else
	StaticPopupDialogs["XRP_MSP_DISABLE"] = {
		text = _xrp.L.MSP_DISABLED,
		button1 = OKAY,
		showAlert = true,
		enterClicksFirstButton = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	disabled = true
	StaticPopup_Show("XRP_MSP_DISABLE", msp_RPAddOn)
end

-- Protocol version two indicates Battle.net support.
_xrp.msp = 2

-- Fields in tooltip.
local TT_FIELDS = { VP = true, VA = true, NA = true, NH = true, NI = true, NT = true, RA = true, RC = true, FR = true, FC = true, CU = true }

-- These fields are (or should) be generated from UnitSomething() functions.
local UNIT_FIELDS = { GC = true, GF = true, GR = true, GS = true, GU = true }

-- 15 seconds for tooltip, 30 seconds for other fields.
local FIELD_TIMES = setmetatable({ TT = 15 }, {
	__index = function(self, field)
		if TT_FIELDS[field] then
			return self.TT
		end
		return 30
	end,
})

-- Session cache. Do NOT make weak.
local cache = setmetatable({}, {
	__index = function(self, name)
		self[name] = {
			nextCheck = 0,
			time = {},
		}
		return self[name]
	end,
})

local bnet
local function RebuildBNList()
	local newBnet = {}
	for i = 1, select(2, BNGetNumFriends()) do
		for j = 1, BNGetNumFriendToons(i) do
			local active, toonName, client, realmName, realmID, faction, race, class, blank, zoneName, level, gameText, broadcastText, broadcastTime, isConnected, toonID = BNGetFriendToonInfo(i, j)
			if isConnected and client == "WoW" and realmName ~= "" then
				local name = xrp.FullName(toonName, realmName)
				if cache[name].nextCheck then
					cache[name].nextCheck = 0
				end
				newBnet[name] = toonID
			end
		end
	end
	if not next(newBnet) then
		return false
	end
	bnet = newBnet
	return true
end

local function GetPresenceID(name)
	if not BNConnected() or not bnet and not RebuildBNList() or not bnet[name] or not select(15, BNGetToonInfo(bnet[name])) then
		return nil
	end
	return bnet[name]
end

local Send, handlers
do
	local AddFilter
	do
		-- Filter visible "No such..." errors from addon messages.
		local filter = {}

		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, message)
			local name = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
			if not name then
				return false
			elseif not filter[name] or filter[name] < GetTime() then
				filter[name] = nil
				return false
			end
			-- Same error message from offline and from opposite faction.
			local GF = _xrp.unitCache[name] and _xrp.unitCache[name].GF or xrpCache[name] and xrpCache[name].fields.GF
			_xrp.FireEvent("FAIL", name, (not GF or GF == xrp.current.GF) and "offline" or "faction")
			return true
		end)

		function AddFilter(name)
			filter[name] = GetTime() + 2.500
		end
	end

	-- Group outgoing field tracking.
	local groupOut = {}
	local function GroupSent(fields)
		for i, field in ipairs(fields) do
			groupOut[field] = nil
		end
	end

	function Send(name, dataTable, channel, isRequest)
		local data = table.concat(dataTable, "\1")

		local presenceID
		if not channel or channel == "BN" then
			presenceID = GetPresenceID(name)
			if not channel and presenceID then
				if cache[name].bnet == false then
					channel = "GAME"
				elseif cache[name].bnet == true then
					channel = "BN"
				end
			end
		end

		if (not channel or channel == "BN") and presenceID then
			local queue = ("XRP-%d"):format(presenceID)
			if #data <= 4078 then
				libbw:BNSendGameData(presenceID, "MSP", data, isRequest and "ALERT" or "NORMAL", queue)
			else
				-- Guess five added characters from metadata.
				data = ("XC=%d\1%s"):format(((#data + 5) / 4078) + 1, data)
				libbw:BNSendGameData(presenceID, "MSP\1", data:sub(1, 4078), "BULK", queue)
				local position = 4079
				while position + 4078 <= #data do
					libbw:BNSendGameData(presenceID, "MSP\2", data:sub(position, position + 4077), "BULK", queue)
					position = position + 4078
				end
				libbw:BNSendGameData(presenceID, "MSP\3", data:sub(position), "BULK", queue)
			end
		end
		if channel == "BN" then return end

		-- Second condition is always true for non-group targets.
		if channel == "WHISPER" or UnitRealmRelationship(Ambiguate(name, "none")) ~= LE_REALM_RELATION_COALESCED then
			local queue = "XRP-" .. name
			if #data <= 255 then
				libbw:SendAddonMessage("MSP", data, "WHISPER", name, isRequest and "ALERT" or "NORMAL", queue, AddFilter, name)
			else
				-- Guess six added characters from metadata.
				data = ("XC=%d\1%s"):format(((#data + 6) / 255) + 1, data)

				libbw:SendAddonMessage("MSP\1", data:sub(1, 255), "WHISPER", name, "BULK", queue, AddFilter, name)

				local position = 256
				while position + 255 <= #data do

					libbw:SendAddonMessage("MSP\2", data:sub(position, position + 254), "WHISPER", name, "BULK", queue, AddFilter, name)
					position = position + 255
				end

				libbw:SendAddonMessage("MSP\3", data:sub(position), "WHISPER", name, "BULK", queue, AddFilter, name)
			end
		else -- GMSP
			channel = channel ~= "GAME" and channel or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
			local prepend = isRequest and name .. "\30" or ""
			local chunkSize = 255 - #prepend

			if #data <= chunkSize then
				libbw:SendAddonMessage("GMSP", prepend .. data, channel, name, isRequest and "ALERT" or "NORMAL", "XRP-GROUP")
			else
				chunkSize = chunkSize - 1

				-- Guess six added characters from metadata.
				local chunkString = ("XC=%d\1"):format(((#data + 6) / chunkSize) + 1)
				data = chunkString .. data

				-- Which fields are in which messages is tracked so that they
				-- won't get re-queued (to the XRP-GROUP single queue) while
				-- they're still being transmitted.
				local fields
				if not isRequest then
					fields = {}
					local total, totalFields = #chunkString, #dataTable
					for i, chunk in ipairs(dataTable) do
						total = total + #chunk
						if i ~= totalFields then
							total = total + 1 -- +1 for the \1 separator byte.
						end
						local field = chunk:match("^(%u%u)")
						if field then
							local messageNum = math.ceil(total / chunkSize)
							local messageFields = fields[messageNum]
							if not messageFields then
								fields[messageNum] = { field }
							else
								messageFields[#messageFields + 1] = field
							end
							groupOut[field] = true
						end
					end
				end

				local messageFields = fields and fields[1]
				libbw:SendAddonMessage("GMSP", ("%s\1%s"):format(prepend, data:sub(1, chunkSize)), channel, name, "BULK", "XRP-GROUP", messageFields and GroupSent, messageFields)

				local position, messageNum = chunkSize + 1, 2
				while position + chunkSize <= #data do
					messageFields = fields and fields[messageNum]
					libbw:SendAddonMessage("GMSP", ("%s\2%s"):format(prepend, data:sub(position, position + chunkSize - 1)), channel, name, "BULK", "XRP-GROUP", messageFields and GroupSent, messageFields)
					position = position + chunkSize
					messageNum = messageNum + 1
				end

				messageFields = fields and fields[messageNum]
				libbw:SendAddonMessage("GMSP", ("%s\3%s"):format(prepend, data:sub(position)), channel, name, "BULK", "XRP-GROUP", messageFields and GroupSent, messageFields)
			end
		end
	end

	local tt
	xrp.HookEvent("UPDATE", function(event, field)
		if tt and (not field or TT_FIELDS[field]) then
			tt = nil
		end
	end)

	local requestTime = setmetatable({}, {
		__index = function(self, name)
			self[name] = {}
			return self[name]
		end,
		__mode = "v", -- Worst case, we rarely send too soon again.
	})
	local TT_LIST = { "VP", "VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "FR", "FC" }
	local function Process(name, command, isGroup)
		local action, field, version, contents = command:match("(%p?)(%u%u)(%d*)=?(.*)")
		version = tonumber(version) or 0
		if not field then
			return nil
		elseif action == "?" then
			local now = GetTime()
			-- Queried our fields. This should end in returning a string,
			-- unless they're spamming requests.
			if isGroup then
				-- In group, ignore every 2.5s to try and catch simultaneous
				-- requests (such as from names-in-chat).
				if groupOut[field] or requestTime.GROUP[field] and requestTime.GROUP[field] > now then
					return nil
				end
				requestTime.GROUP[field] = now + 2.5
			end
			if requestTime[name][field] and requestTime[name][field] > now then
				requestTime[name][field] = now + 5
				return nil
			end
			requestTime[name][field] = now + 5
			if field == "TT" then
				-- Rebuild the TT to catch any version changes before checking
				-- the version.
				if not tt then
					local tooltip = {}
					for i, field in ipairs(TT_LIST) do
						local contents = xrp.current[field]
						tooltip[#tooltip + 1] = not contents and field or ("%s%.0f=%s"):format(field, _xrp.versions[field], contents)
					end
					local newtt = table.concat(tooltip, "\1")
					tt = ("%s\1TT%.0f"):format(newtt, newtt ~= xrpSaved.oldtt and _xrp.NewVersion("TT", newtt) or xrpSaved.versions.TT)
					xrpSaved.oldtt = newtt
				end
				if version == xrpSaved.versions.TT then
					return ("!TT%.0f"):format(version)
				end
				return tt
			end
			local currentVersion = _xrp.versions[field]
			if not currentVersion then
				-- Empty fields are versionless.
				return field
			elseif version == currentVersion then
				return ("!%s%.0f"):format(field, version)
			end
			return ("%s%.0f=%s"):format(field, currentVersion, xrp.current[field])
		elseif action == "!" and version == (xrpCache[name] and xrpCache[name].versions[field] or 0) then
			cache[name].time[field] = GetTime() + FIELD_TIMES[field]
			cache[name].fieldUpdated = cache[name].fieldUpdated or false
			if field == "TT" and xrpCache[name] and cache[name].bnet == nil then
				local VP = tonumber(xrpCache[name].fields.VP)
				if VP then
					cache[name].bnet = VP >= 2
				end
			end
			return nil
		elseif action == "" then
			-- If working with a partial message, don't update TT version or
			-- time. Full TT may not have been received.
			if field == "TT" and cache[name].partialMessage then
				return nil
			elseif not xrpCache[name] and (contents ~= "" or version ~= 0) then
				-- This is the only place a cache table is created by XRP.
				xrpCache[name] = {
					fields = {},
					versions = {},
					lastReceive = time(),
				}
				if _xrp.unitCache[name] then
					for gField, isUnitField in pairs(UNIT_FIELDS) do
						xrpCache[name].fields[gField] = _xrp.unitCache[name][gField]
					end
				end
			elseif field == "TT" and xrpCache[name] and version < (xrpCache[name].versions.TT or 0) then
				-- Their TT version is lower than we have. They probably wiped
				-- and reinstalled, force-refresh non-TT fields.
				_xrp.ForceRefresh(name, true)
			end
			local updated = false
			if contents == "" and xrpCache[name] and xrpCache[name].fields[field] and not UNIT_FIELDS[field] then
				-- Unit fields are never cleared from the cache.
				xrpCache[name].fields[field] = nil
				updated = true
			elseif contents ~= "" and contents ~= xrpCache[name].fields[field] then
				xrpCache[name].fields[field] = contents
				updated = true
				if field == "VA" then
					_xrp.AddonUpdate(contents:match("^XRP/([^;]+)"))
				end
			end
			if version ~= 0 then
				xrpCache[name].versions[field] = version
			elseif xrpCache[name] then
				xrpCache[name].versions[field] = nil
			end
			-- Save session time regardless of contents or version.
			cache[name].time[field] = GetTime() + FIELD_TIMES[field]

			if updated then
				_xrp.FireEvent("FIELD", name, field)
				cache[name].fieldUpdated = true
			else
				cache[name].fieldUpdated = cache[name].fieldUpdated or false
			end
			if field == "VP" and (updated or cache[name].bnet == nil) then
				local VP = tonumber(contents)
				if VP then
					cache[name].bnet = VP >= 2
				end
			end
			return nil
		end
	end

	-- Using GU is more efficient outgoing (~8 bytes less), but some addons don't
	-- properly expose it always, and it's about as efficient for the other side if
	-- we just ask for all the fields.
	local TT_REQ = { "?TT", "?GC", "?GF", "?GR", "?GS" }
	handlers = {
		["MSP"] = function(name, message, channel)
			local out
			for command in message:gmatch("([^\1]+)\1*") do
				local response = Process(name, command, channel ~= "WHISPER" and channel ~= "BN")
				if response then
					if not out then
						out = {}
					end
					out[#out + 1] = response
				end
			end
			-- If a field has been updated (i.e., changed content), fieldUpdated
			-- will be set to true; if a field was received, but the content has
			-- not changed, fieldUpdated will be set to false; if no fields were
			-- received (i.e., only requests), fieldUpdated is nil.
			if cache[name].fieldUpdated == true then
				_xrp.FireEvent("RECEIVE", name)
				cache[name].fieldUpdated = nil
			elseif cache[name].fieldUpdated == false then
				_xrp.FireEvent("NOCHANGE", name)
				cache[name].fieldUpdated = nil
			end
			if out then
				Send(name, out, channel)
			end
			if xrpCache[name] ~= nil then
				-- Cache timer. Last receive marked for clearing old entries.
				xrpCache[name].lastReceive = time()
			elseif not cache[name].time.TT then
				-- If we don't have any info for them and haven't requested the
				-- tooltip in this session, also send a tooltip request.
				local now = GetTime()
				local timer = FIELD_TIMES.TT
				cache[name].time.TT = now + timer
				for field, isTT in pairs(TT_FIELDS) do
					cache[name].time[field] = now + timer
				end
				Send(name, TT_REQ, channel, true)
			end
		end,
		["MSP\1"] = function(name, message, channel)
			local totalChunks = tonumber(message:match("^XC=(%d+)\1"))
			if totalChunks then
				if totalChunks < 512 then
					cache[name].totalChunks = totalChunks
				end
				message = message:gsub("^XC=%d+\1", "")
			end
			-- Queries (i.e., "?TT") are processed only after receive finishes.
			for command in message:gmatch("([^\1]+)\1") do
				if command:find("^[^%?]") then
					Process(name, command)
					message = message:gsub(command:gsub("(%W)","%%%1") .. "\1", "")
				end
			end
			cache[name].chunks = 1
			cache[name][channel] = message
			_xrp.FireEvent("CHUNK", name, 1, totalChunks)
		end,
		["MSP\2"] = function(name, message, channel)
			local buffer = cache[name][channel]
			-- If we don't have a buffer (i.e., no prior received message), still
			-- try to process as many full commands as we can.
			if not buffer then
				message = message:match("^.-\1(.+)$")
				if not message then return end
				buffer = { "", partial = true }
				cache[name][channel] = buffer
			end
			-- Only merge the contents if there's an end-of-command to process.
			if message:find("\1", nil, true) then
				if type(buffer) == "string" then
					message = buffer .. message
				else
					if buffer.partial then
						cache[name].partialMessage = true
					end
					buffer[#buffer + 1] = message
					message = table.concat(buffer)
				end
				for command in message:gmatch("([^\1]+)\1") do
					if command:find("^[^%?]") then
						Process(name, command)
						message = message:gsub(command:gsub("(%W)","%%%1") .. "\1", "")
					end
				end
				if cache[name].partialMessage then
					cache[name].partialMessage = nil
					cache[name][channel] = { message, partial = true }
				else
					cache[name][channel] = message
				end
			else
				if type(buffer) == "string" then
					cache[name][channel] = { buffer, message }
				else
					buffer[#buffer + 1] = message
				end
			end
			cache[name].chunks = (cache[name].chunks or 0) + 1
			_xrp.FireEvent("CHUNK", name, cache[name].chunks, cache[name].totalChunks)
		end,
		["MSP\3"] = function(name, message, channel)
			local buffer = cache[name][channel]
			-- If we don't have a buffer (i.e., no prior received message), still
			-- try to process as many full commands as we can.
			if not buffer then
				message = message:match("^.-\1(.+)$")
				if not message then return end
				buffer = ""
				cache[name].partialMessage = true
			end
			if type(buffer) == "string" then
				handlers["MSP"](name, buffer .. message, channel)
			else
				if buffer.partial then
					cache[name].partialMessage = true
				end
				buffer[#buffer + 1] = message
				handlers["MSP"](name, table.concat(buffer), channel)
			end
			-- CHUNK after RECEIVE would fire. Makes it easier to do something
			-- useful when chunks == totalChunks.
			local chunks = (cache[name].chunks or 0) + 1
			_xrp.FireEvent("CHUNK", name, chunks, chunks)

			cache[name].chunks = nil
			cache[name].totalChunks = nil
			cache[name][channel] = nil
			cache[name].partialMessage = nil
		end,
		["GMSP"] = function(name, message, channel)
			local target, prefix
			if message:find("\30", nil, true) then
				target, prefix, message = message:match("^(.-)\30([\1\2\3]?)(.+)$")
			else
				prefix, message = message:match("^([\1\2\3]?)(.+)$")
			end
			if target and target ~= _xrp.playerWithRealm then return end
			handlers["MSP" .. prefix](name, message, channel)
		end,
	}
end

local gameEvents = {}
function gameEvents.CHAT_MSG_ADDON(event, prefix, message, channel, sender)
	if not handlers[prefix] then return end
	-- Sometimes won't have the realm attached because I dunno. Always
	-- works correctly for different-realm messages.
	local name = xrp.FullName(sender)

	-- Ignore messages from ourselves (GMSP).
	if name ~= _xrp.playerWithRealm then
		cache[name].nextCheck = nil

		handlers[prefix](name, message, channel)
	end
end
function gameEvents.BN_CHAT_MSG_ADDON(event, prefix, message, channel, presenceID)
	if not handlers[prefix] then return end
	local active, toonName, client, realmName = BNGetToonInfo(presenceID)
	local name = xrp.FullName(toonName, realmName)
	if bnet then
		bnet[name] = presenceID
	end

	cache[name].bnet = true
	cache[name].nextCheck = nil

	handlers[prefix](name, message, "BN")
end
function gameEvents.BN_TOON_NAME_UPDATE(event, presenceID)
	if not bnet then return end
	local active, toonName, client, realmName = BNGetToonInfo(presenceID)
	if client == "WoW" and realmName ~= "" then
		local name = xrp.FullName(toonName, realmName)
		if cache[name].nextCheck then
			cache[name].nextCheck = 0
		end
		bnet[name] = presenceID
	end
end
function gameEvents.BN_CONNECTED(event)
	RebuildBNList()
	_xrp.HookGameEvent("BN_TOON_NAME_UPDATED", gameEvents.BN_TOON_NAME_UPDATED)
	_xrp.HookGameEvent("BN_FRIEND_TOON_ONLINE", gameEvents.BN_TOON_NAME_UPDATED)
end
function gameEvents.BN_DISCONNECTED(event)
	_xrp.UnhookGameEvent("BN_TOON_NAME_UPDATED", gameEvents.BN_TOON_NAME_UPDATED)
	_xrp.UnhookGameEvent("BN_FRIEND_TOON_ONLINE", gameEvents.BN_TOON_NAME_UPDATED)
	bnet = nil
end
do
	local inGroup = {}
	local raidUnits, partyUnits = {}, {}
	do
		local raid, party = "raid%d", "party%d"
		for i = 1, MAX_RAID_MEMBERS do
			raidUnits[i] = raid:format(i)
		end
		for i = 1, MAX_PARTY_MEMBERS do
			partyUnits[i] = party:format(i)
		end
	end
	function gameEvents.GROUP_ROSTER_UPDATE(event)
		local units = IsInRaid() and raidUnits or partyUnits
		local newInGroup = {}
		for i, unit in ipairs(units) do
			local name = xrp.UnitFullName(unit)
			if not name then break end
			if name ~= _xrp.playerWithRealm then
				if not inGroup[name] and cache[name].nextCheck then
					cache[name].nextCheck = 0
				end
				newInGroup[name] = true
			end
		end
		inGroup = newInGroup
	end
end

if not disabled then
	for prefix, handler in pairs(handlers) do
		RegisterAddonMessagePrefix(prefix)
	end
	_xrp.HookGameEvent("CHAT_MSG_ADDON", gameEvents.CHAT_MSG_ADDON)
	_xrp.HookGameEvent("BN_CHAT_MSG_ADDON", gameEvents.BN_CHAT_MSG_ADDON)
end
_xrp.HookGameEvent("GROUP_ROSTER_UPDATE", gameEvents.GROUP_ROSTER_UPDATE)
if BNConnected() then
	_xrp.HookGameEvent("BN_TOON_NAME_UPDATED", gameEvents.BN_TOON_NAME_UPDATED)
	_xrp.HookGameEvent("BN_FRIEND_TOON_ONLINE", gameEvents.BN_TOON_NAME_UPDATED)
end
_xrp.HookGameEvent("BN_CONNECTED", gameEvents.BN_CONNECTED)
_xrp.HookGameEvent("BN_DISCONNECTED", gameEvents.BN_DISCONNECTED)

local request, requestQueued = {}
local function RunRequestQueue()
	for name, fields in pairs(request) do
		_xrp.Request(name, fields)
		request[name] = nil
	end
	requestQueued = nil
end

function _xrp.QueueRequest(name, field)
	if disabled or name == _xrp.playerWithRealm or xrp.ShortName(name) == UNKNOWN or cache[name].time[field] and GetTime() < cache[name].time[field] then
		return
	elseif not request[name] then
		request[name] = {}
	end
	request[name][#request[name] + 1] = field
	if not requestQueued then
		C_Timer.After(0, RunRequestQueue)
		requestQueued = true
	end
end

-- As also in TT_REQ, these are only slightly less efficient than using GF+GU,
-- but are much more reliable.
local UNIT_REQUEST = { "GC", "GF", "GR", "GS" }
function _xrp.Request(name, fields)
	if disabled or name == _xrp.playerWithRealm or xrp.ShortName(name) == UNKNOWN then
		return false
	end

	local now = GetTime()
	if cache[name].nextCheck and now < cache[name].nextCheck then
		local GF = _xrp.unitCache[name] and _xrp.unitCache[name].GF or xrpCache[name] and xrpCache[name].fields.GF
		_xrp.FireEvent("FAIL", name, (not GF or GF == xrp.current.GF) and "nomsp" or "faction")
		return false
	elseif cache[name].nextCheck then
		cache[name].nextCheck = now + 120
	end

	-- No need to strip repeated fields -- the logic below for not querying
	-- fields repeatedly over a short time will handle that for us.
	local reqTT = false
	-- This entire for block is FRAGILE. Modifications not recommended.
	for i = #fields, 1, -1 do
		if fields[i] == "TT" or TT_FIELDS[fields[i]] then
			table.remove(fields, i)
			reqTT = true
		end
	end
	if reqTT then
		-- Want TT at start of request.
		table.insert(fields, 1, "TT")
	end

	if not _xrp.unitCache[name] then
		if not xrpCache[name] then
			for i, field in ipairs(UNIT_REQUEST) do
				fields[#fields + 1] = field
			end
		else
			local cached = xrpCache[name].fields
			for i, field in ipairs(UNIT_REQUEST) do
				if not cached[field] then
					fields[#fields + 1] = field
				end
			end
		end
	elseif not _xrp.unitCache[name].GF and (not xrpCache[name] or not xrpCache[name].fields.GF) then
		fields[#fields + 1] = "GF"
	end

	local out = {}
	for i, field in ipairs(fields) do
		if not cache[name].time[field] or now > cache[name].time[field] then
			if not xrpCache[name] or not xrpCache[name].versions[field] then
				out[#out + 1] = "?" .. field
			else
				out[#out + 1] = ("?%s%.0f"):format(field, xrpCache[name].versions[field])
			end
			cache[name].time[field] = now + FIELD_TIMES[field]
			if field == "TT" then
				local timer = FIELD_TIMES[field]
				for ttField, isTT in pairs(TT_FIELDS) do
					cache[name].time[ttField] = now + timer
				end
			end
		end
	end
	if #out > 0 then
		Send(name, out, nil, true)
		return true
	end
	return false
end

function _xrp.CanRefresh(name)
	local now = GetTime()
	if cache[name].nextCheck and now < cache[name].nextCheck then
		return false
	elseif (cache[name].time.TT or 0) < now or (cache[name].time.DE or 0) < now then
		return true
	end
	return false
end

function _xrp.ResetCacheTimers(name)
	if rawget(cache, name) then
		local now = GetTime()
		if cache[name].nextCheck and now < cache[name].nextCheck then
			cache[name].nextCheck = now + 5
		end
		for field, nextReq in pairs(cache[name].time) do
			if nextReq > now + 5 then
				cache[name].time[field] = now + 5
			end
		end
	end
end

function _xrp.DropCache(name)
	if xrpAccountSaved.bookmarks[name] or xrpAccountSaved.notes[name] then return end
	_xrp.ResetCacheTimers(name)
	xrpCache[name] = nil
	_xrp.FireEvent("DROP", name)
end

function _xrp.ForceRefresh(name, skipTT)
	local fields = {}
	for field, lastReq in pairs(cache[name].time) do
		fields[field] = true
	end
	for field, contents in pairs(xrpCache[name].fields) do
		fields[field] = true
	end
	for field, version in pairs(xrpCache[name].versions) do
		fields[field] = true
	end

	local now = GetTime()
	local requestNow, requestLater = {}, {}
	for field, isKnown in pairs(fields) do
		if not skipTT or not TT_FIELDS[field] then
			if (cache[name].time[field] or 0) < now then
				requestNow[#requestNow + 1] = field
			else
				cache[name].time[field] = now + 5
				requestLater[#requestLater + 1] = field
			end
			xrpCache[name].versions[field] = nil
		end
	end

	if #requestNow > 0 then
		_xrp.Request(name, requestNow)
	end
	if #requestLater > 0 then
		-- Not a fan of using a closure like this, but this won't be run often
		-- enough to matter.
		C_Timer.After(5.5, function() _xrp.Request(name, requestLater) end)
	end
end
