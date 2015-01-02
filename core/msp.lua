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

local addonName, xrpPrivate = ...

-- Claim MSP rights ASAP to try heading off other addons. Since we start with
-- "x", this probably won't help much.
local disabled = false
if not msp_RPAddOn then
	msp_RPAddOn = GetAddOnMetadata(addonName, "Title")
else
	StaticPopupDialogs["XRP_MSP_DISABLE"] = {
		text = "You are running another RP profile addon (\"%s\"). XRP's support for sending and receiving profiles is disabled; to enable it, disable \"%s\" and reload your UI.",
		button1 = OKAY,
		showAlert = true,
		enterClicksFirstButton = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	disabled = true
	StaticPopup_Show("XRP_MSP_DISABLE", msp_RPAddOn, msp_RPAddOn)
end

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

-- This is the core of the MSP send/recieve implementation. The API is nothing
-- like LibMSP and is not accessible outside this file.
local msp = CreateFrame("Frame")
-- Battle.net friends mapping.
msp.bnet = {}
-- Requested field queue
msp.request = {}
-- Session cache. Do NOT make weak.
msp.cache = setmetatable({}, {
	__index = function(self, name)
		self[name] = {
			nextCheck = 0,
			received = false,
			time = {},
		}
		return self[name]
	end,
})

function msp:UpdateBNList()
	for i = 1, select(2, BNGetNumFriends()) do
		for j = 1, BNGetNumFriendToons(i) do
			local active, toonName, client, realmName, realmID, faction, race, class, blank, zoneName, level, gameText, broadcastText, broadcastTime, isConnected, toonID = BNGetFriendToonInfo(i, j)
			if client == "WoW" then
				self.bnet[xrp:Name(toonName, realmName)] = toonID
			end
		end
	end
end

do
	local AddFilter
	do
		-- Filter visible "No such..." errors from addon messages.
		local filter = {}

		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, message)
			local name = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
			if not name or name == "" or not filter[name] then
				return false
			end
			local doFilter = filter[name] > (GetTime() - 2.500)
			if not doFilter then
				filter[name] = nil
			else
				-- Same error message for offline and opposite faction.
				xrpPrivate:FireEvent("FAIL", name, (not xrpCache[name] or not xrpCache[name].fields.GF or xrpCache[name].fields.GF == xrp.current.fields.GF) and "offline" or "faction")
			end
			return doFilter
		end)

		-- Most complex function ever.
		function AddFilter(name)
			filter[name] = GetTime()
		end
	end

	function msp:Send(name, data, channel, isRequest)
		data = table.concat(data, "\1")
		--print("Sending to: "..name)
		--print(GetTime()..": Out: "..name..": "..data:gsub("\1", ";"))

		-- Check whether sending by BN is available and preferred.
		if (not channel or channel == "BN") and self.bnet[name] then
			if not select(15, BNGetToonInfo(self.bnet[name])) then
				-- presenceID is no longer valid. Probably offline.
				self.bnet[name] = nil
			elseif not channel then
				if self.cache[name].bnet == false then
					channel = "GAME"
				elseif self.cache[name].bnet == true then
					channel = "BN"
				end
			end
		end

		if (not channel or channel == "BN") and self.bnet[name] then
			local presenceID = self.bnet[name]
			local queue = ("XRP-%u"):format(presenceID)
			if #data <= 4078 then
				libbw:BNSendGameData(presenceID, "MSP", data, "NORMAL", queue)
			else
				-- XC is most likely to add five extra characters, will not add
				-- less than five, and only adds six or more if the profile is
				-- over 40000 characters or so. So let's say five.
				data = ("XC=%u\1%s"):format(((#data + 5) / 4078) + 1, data)
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

		local isGroup = channel ~= "WHISPER" and UnitRealmRelationship(Ambiguate(name, "none")) == LE_REALM_RELATION_COALESCED
		channel = channel ~= "GAME" and channel or isGroup and (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID") or "WHISPER"
		local prepend = isGroup and isRequest and name .. "\30" or ""
		local queue = isGroup and "XRP-GROUP" or "XRP-" .. name
		local callback = not isGroup and AddFilter or nil
		local chunkSize = 255 - #prepend

		if #data <= chunkSize then
			libbw:SendAddonMessage(not isGroup and "MSP" or "GMSP", prepend .. data, channel, name, "NORMAL", queue, callback, name)
		else
			chunkSize = isGroup and chunkSize - 1 or chunkSize
			-- XC is most likely to add five or six extra characters, will
			-- not add less than five, and only adds seven or more if the
			-- profile is over 25000 characters or so. So let's say six.
			data = ("XC=%u\1%s"):format(((#data + 6) / chunkSize) + 1, data)
			libbw:SendAddonMessage(not isGroup and "MSP\1" or "GMSP", (isGroup and "%s\1%s" or "%s%s"):format(prepend, data:sub(1, chunkSize)), channel, name, "BULK", queue, callback, name)
			local position = chunkSize + 1
			while position + chunkSize <= #data do
				libbw:SendAddonMessage(not isGroup and "MSP\2" or "GMSP", (isGroup and "%s\2%s" or "%s%s"):format(prepend, data:sub(position, position + chunkSize - 1)), channel, name, "BULK", queue, callback, name)
				position = position + chunkSize
			end
			libbw:SendAddonMessage(not isGroup and "MSP\3" or "GMSP", (isGroup and "%s\3%s" or "%s%s"):format(prepend, data:sub(position)), channel, name, "BULK", queue, callback, name)
		end
	end
end

do
	-- Tooltip order for ideal XRP viewer usage.
	local TT_LIST = { "VP", "VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "FR", "FC" }
	local tt
	function msp:GetTT()
		if not tt then
			local current, tooltip = xrp.current, {}
			for i, field in ipairs(TT_LIST) do
				tooltip[#tooltip + 1] = not current.fields[field] and field or ("%s%u=%s"):format(field, current.versions[field], current.fields[field])
			end
			local newtt = table.concat(tooltip, "\1")
			tt = ("%s\1TT%u"):format(newtt, newtt ~= xrpSaved.oldtt and xrpPrivate:NewVersion("TT") or xrpSaved.versions.TT)
			xrpSaved.oldtt = newtt
		end
		return tt
	end
	xrp:HookEvent("UPDATE", function(event, field)
		if tt and (not field or TT_FIELDS[field]) then
			tt = nil
		end
	end)
end

do
	local requestTime = setmetatable({}, {
		__index = function(self, name)
			self[name] = {}
			return self[name]
		end,
		__mode = "v", -- Worst case, we rarely send too soon again.
	})
	-- This returns requested field output, or nil if no requests were
	-- made. msp.cache[name].fieldUpdated is set to true if a
	-- field has changed, false if a field has not been changed.
	function msp:Process(name, command)
		local action, field, version, contents = command:match("(%p?)(%u%u)(%d*)=?(.*)")
		version = tonumber(version) or 0
		if not field then
			return nil
		elseif action == "?" then
			local now = GetTime()
			-- Queried our fields. This should end in returning a
			-- string with our info for that field. (If it doesn't, it
			-- means we're ignoring their request, probably because
			-- they're spamming it at us.)
			if requestTime[name][field] and requestTime[name][field] > now - 5 then
				requestTime[name][field] = now
				return nil
			end
			requestTime[name][field] = now
			if field == "TT" then
				-- Rebuild the TT to catch any version changes before checking
				-- the version.
				local tt = self:GetTT()
				if version == xrpSaved.versions.TT then
					return ("!TT%u"):format(version)
				end
				return tt
			end
			local currentVersion = xrp.current.versions[field]
			if not currentVersion then
				-- Field is empty. Empty fields are always version 0 in XRP.
				return field
			elseif version == currentVersion then
				-- They already have the latest.
				return ("!%s%u"):format(field, version)
			end
			-- Field has new content.
			return ("%s%u=%s"):format(field, currentVersion, xrp.current.fields[field])
		elseif action == "!" and version == (xrpCache[name] and xrpCache[name].versions[field] or 0) then
			-- Told us we have latest of their field.
			self.cache[name].time[field] = GetTime()
			self.cache[name].fieldUpdated = self.cache[name].fieldUpdated or false
			if field == "TT" and xrpCache[name] and self.cache[name].bnet == nil then
				local VP = tonumber(xrpCache[name].fields.VP)
				if VP then
					self.cache[name].bnet = VP >= 2
				end
			end
			return nil
		elseif action == "" then
			-- If we're stumbling through a partial (garbled) request, don't
			-- update TT version or time. Full TT may not have been received.
			if field == "TT" and self.cache[name].partialRequest then
				return nil
			end
			-- Gave us a field.
			if not xrpCache[name] and (contents ~= "" or version ~= 0) then
				xrpCache[name] = {
					fields = {},
					versions = {},
				}
				-- This is the only place a cache table is created by XRP. If
				-- we already have any data about them in the gCache (unit
				-- cache), pull that into the real cache.
				if xrpPrivate.gCache[name] then
					for gField, isUnitField in pairs(UNIT_FIELDS) do
						xrpCache[name].fields[gField] = xrpPrivate.gCache[name][gField]
					end
				end
			end
			local updated = false
			if contents == "" and xrpCache[name] and xrpCache[name].fields[field] and not UNIT_FIELDS[field] then
				-- If it's newly blank, empty it in the cache. Never
				-- empty G*, but do update them (following elseif).
				xrpCache[name].fields[field] = nil
				updated = true
			elseif contents ~= "" and contents ~= xrpCache[name].fields[field] then
				xrpCache[name].fields[field] = contents
				updated = true
				if field == "VA" then
					xrpPrivate:AddonUpdate(contents:match("^XRP/([^;]+)"))
				end
			end
			if version ~= 0 then
				xrpCache[name].versions[field] = version
			elseif xrpCache[name] then
				xrpCache[name].versions[field] = nil
			end
			-- Save time regardless of contents or version. This prevents
			-- querying again too soon. Query time is also set prior to initial
			-- send -- so timer will count from send OR receive as appropriate.
			self.cache[name].time[field] = GetTime()

			if updated then
				xrpPrivate:FireEvent("FIELD", name, field)
				self.cache[name].fieldUpdated = true
			else
				self.cache[name].fieldUpdated = self.cache[name].fieldUpdated or false
			end
			if field == "VP" and (updated or self.cache[name].bnet == nil) then
				local VP = tonumber(contents)
				if VP then
					self.cache[name].bnet = VP >= 2
				end
			end
			return nil
		end
	end
end

local TT_REQ = { "?TT" }
msp.handlers = {
	["MSP"] = function(self, name, message, channel)
		local out
		for command in message:gmatch("([^\1]+)\1*") do
			local response = self:Process(name, command)
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
		if self.cache[name].fieldUpdated == true then
			xrpPrivate:FireEvent("RECEIVE", name)
			self.cache[name].fieldUpdated = nil
		elseif self.cache[name].fieldUpdated == false then
			xrpPrivate:FireEvent("NOCHANGE", name)
			self.cache[name].fieldUpdated = nil
		end
		if out then
			self:Send(name, out, channel)
		end
		if xrpCache[name] ~= nil then
			-- Cache timer. Last receive marked for clearing old entries.
			xrpCache[name].lastReceive = time()
		elseif not self.cache[name].time.TT then
			-- If we don't have any info for them and haven't requested the
			-- tooltip in this session, also send a tooltip request
			self:Send(name, TT_REQ, channel, true)
		end
	end,
	["MSP\1"] = function(self, name, message, channel)
		local totalChunks = tonumber(message:match("^XC=(%d+)\1"))
		if totalChunks then
			self.cache[name].totalChunks = totalChunks
			-- Drop XC if present.
			message = message:gsub("^XC=%d+\1", "")
		end
		-- This only does partial processing -- queries (i.e., ?TT) are
		-- processed only after full reception. Mixed queries/responses are not
		-- common, but also not forbidden by the spec.
		for command in message:gmatch("([^\1]+)\1") do
			if command:find("^[^%?]") then
				self:Process(name, command)
				message = message:gsub(command:gsub("(%W)","%%%1") .. "\1", "")
			end
		end
		self.cache[name].chunks = 1
		self.cache[name][channel] = message
		xrpPrivate:FireEvent("CHUNK", name, 1, totalChunks)
	end,
	["MSP\2"] = function(self, name, message, channel)
		local buffer = self.cache[name][channel]
		-- If we don't have a buffer (i.e., no prior received message),
		-- still try to process as many full commands as we can.
		if not buffer then
			message = message:match("^.-\1(.+)$")
			if not message then return end
			buffer = ""
			self.cache[name].partialRequest = true
		end
		-- Only merge the contents if there's an end-of-command to process.
		if message:find("\1", nil, true) then
			message = (type(buffer) == "string" and buffer or table.concat(buffer)) .. message
			for command in message:gmatch("([^\1]+)\1") do
				if command:find("^[^%?]") then
					self:Process(name, command)
					message = message:gsub(command:gsub("(%W)","%%%1") .. "\1", "")
				end
			end
			self.cache[name][channel] = message
		else
			if type(buffer) == "string" then
				self.cache[name][channel] = { buffer, message }
			else
				buffer[#buffer + 1] = message
			end
		end
		local chunks = (self.cache[name].chunks or 0) + 1
		self.cache[name].chunks = chunks
		xrpPrivate:FireEvent("CHUNK", name, chunks, self.cache[name].totalChunks)
	end,
	["MSP\3"] = function(self, name, message, channel)
		local buffer = self.cache[name][channel]
		-- If we don't have a buffer (i.e., no prior received message),
		-- still try to process as many full commands as we can.
		if not buffer then
			message = message:match("^.-\1(.+)$")
			if not message then return end
			buffer = ""
			self.cache[name].partialRequest = true
		end
		self.handlers["MSP"](self, name, (type(buffer) == "string" and buffer or table.concat(buffer)) .. message, channel)
		-- CHUNK after RECEIVE would fire. Makes it easier to do something
		-- useful when chunks == totalChunks.
		xrpPrivate:FireEvent("CHUNK", name, (self.cache[name].chunks or 0) + 1, (self.cache[name].chunks or 0) + 1)

		self.cache[name].chunks = nil
		self.cache[name].totalChunks = nil
		self.cache[name][channel] = nil
		self.cache[name].partialRequest = nil
	end,
	["GMSP"] = function(self, name, message, channel)
		local target, prefix, message = message:match(message:find("\30", nil, true) and "^(.+)\30([\1\2\3]?)(.+)$" or "^(.-)([\1\2\3]?)(.+)$")
		if target ~= "" and target ~= xrpPrivate.playerWithRealm then return end
		self.handlers[prefix ~= "" and ("MSP%s"):format(prefix) or "MSP"](self, name, message, channel)
	end,
}

msp:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if event == "CHAT_MSG_ADDON" and self.handlers[prefix] then
		-- Sometimes won't have the realm attached because I dunno. Always
		-- works correctly for different-realm messages.
		local name = xrp:Name(sender)
		--print(GetTime()..": In: "..name..": "..message:gsub("\1", ";"))
		--print("Receiving from: "..name)

		-- Ignore messages from ourselves (GMSP).
		if name ~= xrpPrivate.playerWithRealm then
			self.cache[name].received = true
			self.cache[name].nextCheck = nil

			self.handlers[prefix](self, name, message, channel)
		end
	elseif event == "BN_CHAT_MSG_ADDON" and self.handlers[prefix] then
		local active, toonName, client, realmName = BNGetToonInfo(sender)
		local name = xrp:Name(toonName, realmName)
		self.bnet[name] = sender

		self.cache[name].bnet = true
		self.cache[name].received = true
		self.cache[name].nextCheck = nil

		self.handlers[prefix](self, name, message, "BN")
	elseif event == "BN_TOON_NAME_UPDATED" or event == "BN_FRIEND_TOON_ONLINE" then
		local active, toonName, client, realmName = BNGetToonInfo(prefix)
		if client == "WoW" then
			local name = xrp:Name(toonName, realmName)
			if not self.bnet[name] and not self.cache[name].received then
				self.cache[name].nextCheck = 0
			end
			self.bnet[name] = prefix
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		local units = IsInRaid() and self.raidUnits or self.partyUnits
		local inGroup, newInGroup = self.inGroup, {}
		for i, unit in ipairs(units) do
			local name = xrp:UnitName(unit)
			if not name then break end
			if name ~= xrpPrivate.playerWithRealm then
				if not inGroup[name] and not self.cache[name].received then
					self.cache[name].nextCheck = 0
				end
				newInGroup[name] = true
			end
		end
		self.inGroup = newInGroup
	elseif event == "BN_CONNECTED" then
		self:UpdateBNList()
		self:RegisterEvent("BN_TOON_NAME_UPDATED")
		self:RegisterEvent("BN_FRIEND_TOON_ONLINE")
	elseif event == "BN_DISCONNECTED" then
		self:UnregisterEvent("BN_TOON_NAME_UPDATED")
		self:UnregisterEvent("BN_FRIEND_TOON_ONLINE")
		self.bnet = {}
	end
end)

if not disabled then
	for prefix, handler in pairs(msp.handlers) do
		RegisterAddonMessagePrefix(prefix)
	end
	msp:RegisterEvent("CHAT_MSG_ADDON")
	msp:RegisterEvent("BN_CHAT_MSG_ADDON")
	msp:RegisterEvent("GROUP_ROSTER_UPDATE")
	if BNConnected() then
		msp:UpdateBNList()
		msp:RegisterEvent("BN_TOON_NAME_UPDATED")
		msp:RegisterEvent("BN_FRIEND_TOON_ONLINE")
	end
	msp:RegisterEvent("BN_CONNECTED")
	msp:RegisterEvent("BN_DISCONNECTED")
end

do
	local raidUnits, partyUnits = {}, {}
	local raid, party = "raid%u", "party%u"
	for i = 1, MAX_RAID_MEMBERS do
		raidUnits[i] = raid:format(i)
	end
	for i = 1, MAX_PARTY_MEMBERS do
		partyUnits[i] = party:format(i)
	end
	msp.raidUnits = raidUnits
	msp.partyUnits = partyUnits
	msp.inGroup = {}
end

function msp:OnUpdate(elapsed)
	if next(self.request) then
		for name, fields in pairs(self.request) do
			xrpPrivate:Request(name, fields)
			self.request[name] = nil
		end
	end
	self:Hide()
end
msp:Hide()
msp:SetScript("OnUpdate", msp.OnUpdate)

xrpPrivate.msp = 2

function xrpPrivate:QueueRequest(name, field)
	if disabled or name == xrpPrivate.playerWithRealm or xrp:Ambiguate(name) == UNKNOWN or msp.cache[name].time[field] and GetTime() < msp.cache[name].time[field] + FIELD_TIMES[field] then
		return false
	end

	if not msp.request[name] then
		msp.request[name] = {}
	end

	msp.request[name][#msp.request[name] + 1] = field
	msp:Show()

	return true
end

function xrpPrivate:Request(name, fields)
	if disabled or name == xrpPrivate.playerWithRealm or xrp:Ambiguate(name) == UNKNOWN then
		return false
	end

	local now = GetTime()
	if not msp.cache[name].received and now < msp.cache[name].nextCheck then
		self:FireEvent("FAIL", name, "nomsp")
		return false
	elseif not msp.cache[name].received then
		msp.cache[name].nextCheck = now + 120
	end

	-- No need to strip repeated fields -- the logic below for not querying
	-- fields repeatedly over a short time will handle that for us.
	local reqTT = false
	-- This entire for block is FRAGILE. Modifications not recommended.
	for key = #fields, 1, -1 do
		if fields[key] == "TT" or TT_FIELDS[fields[key]] then
			table.remove(fields, key)
			reqTT = true
		end
	end
	if reqTT then
		-- Want TT at start of request.
		table.insert(fields, 1, "TT")
	end

	local out = {}
	for i, field in ipairs(fields) do
		if not msp.cache[name].time[field] or now > msp.cache[name].time[field] + FIELD_TIMES[field] then
			if not xrpCache[name] or not xrpCache[name].versions[field] then
				out[#out + 1] = "?" .. field
			else
				out[#out + 1] = ("?%s%u"):format(field, xrpCache[name].versions[field])
			end
			msp.cache[name].time[field] = now
		end
	end
	if #out > 0 then
		msp:Send(name, out, nil, true)
		return true
	end
	return false
end

-- The following is a workaround for the fact that OnUpdate scripts won't fire
-- when the user is tabbed out in fullscreen (non-windowed) mode. It uses some
-- common events to fake running OnUpdates if there hasn't been any recent
-- framedraws to keep sending/receiving properly while tabbed out (albeit with
-- the possibility of some delay).
local function CreateFSFrame()
	local frame = CreateFrame("Frame")
	frame:Hide()
	frame:SetScript("OnShow", function(self)
		local now = GetTime()
		self.lastDraw = now
		self.lastMSP = now
		self.lastBWBN = now
		self.lastBWGame = now
	end)
	frame:SetScript("OnUpdate", function(self, elapsed)
		self.lastDraw = self.lastDraw + elapsed
	end)
	frame:SetScript("OnEvent", function(self, event)
		local now = GetTime()
		if self.lastDraw < now - 5 then
			-- No framedraw for 5+ seconds.
			if msp:IsVisible() then
				msp:OnUpdate(now - self.lastMSP)
				self.lastMSP = now
			end
			if libbw.BN:IsVisible() then
				libbw.BN:OnUpdate(now - self.lastBWBN)
				self.lastBWBN = now
			end
			if libbw.GAME:IsVisible() then
				libbw.GAME:OnUpdate(now - self.lastBWGame)
				self.lastBWGame = now
			end
		end
	end)
	return frame
end

local fsFrame
local function FullscreenCheck()
	if GetCVar("gxWindow") == "0" then
		-- Is true fullscreen.
		fsFrame = fsFrame or CreateFSFrame()
		fsFrame:Show()
		-- These events are relatively common while idling, so are used to
		-- fake OnUpdate when tabbed out.
		fsFrame:RegisterEvent("CHAT_MSG_ADDON")
		fsFrame:RegisterEvent("CHAT_MSG_CHANNEL")
		fsFrame:RegisterEvent("CHAT_MSG_GUILD")
		fsFrame:RegisterEvent("CHAT_MSG_SAY")
		fsFrame:RegisterEvent("CHAT_MSG_EMOTE")
		fsFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
		fsFrame:RegisterEvent("GUILD_TRADESKILL_UPDATE")
		fsFrame:RegisterEvent("GUILD_RANKS_UPDATE")
		fsFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
		fsFrame:RegisterEvent("COMPANION_UPDATE")
		-- This would be nice to use, but actually having it happening
		-- in-combat would be huge overhead.
		--fsFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	elseif fsFrame then
		-- Is not true fullscreen, but the frame exists. Hide it, and
		-- disable events.
		fsFrame:Hide()
		fsFrame:UnregisterAllEvents()
	end
end

hooksecurefunc("RestartGx", FullscreenCheck)
FullscreenCheck()
