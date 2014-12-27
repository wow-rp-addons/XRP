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

-- This is the core of the MSP send/recieve implementation. The API is nothing
-- like LibMSP and is not accessible outside this file.
local msp = CreateFrame("Frame")
-- Battle.net friends mapping.
msp.bnet = {}
-- Requested field queue
msp.request = {}
-- Session cache. Do NOT make weak.
msp.cache = setmetatable({}, {
	__index = function(self, character)
		self[character] = {
			nextCheck = 0,
			received = false,
			time = {},
		}
		return self[character]
	end,
})

function msp:UpdateBNList()
	for i = 1, select(2, BNGetNumFriends()) do
		for j = 1, BNGetNumFriendToons(i) do
			local active, toonName, client, realmName, realmID, faction, race, class, blank, zoneName, level, gameText, broadcastText, broadcastTime, isConnected, toonID = BNGetFriendToonInfo(i, j)
			if client == "WoW" then
				local character = xrp:Name(toonName, realmName)
				self.bnet[character] = toonID
			end
		end
	end
end

do
	local msp_AddFilter
	do
		-- Filter visible "No such..." errors from addon messages.
		local filter = setmetatable({}, xrpPrivate.weakMeta)

		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, message)
			local character = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
			if not character or character == "" or not filter[character] then
				return false
			end
			local doFilter = filter[character] > (GetTime() - 2.500)
			if not doFilter then
				filter[character] = nil
			else
				-- Same error message for offline and opposite faction.
				xrpPrivate:FireEvent("FAIL", character, (not xrpCache[character] or not xrpCache[character].fields.GF or xrpCache[character].fields.GF == xrp.current.fields.GF) and "offline" or "faction")
			end
			return doFilter
		end)

		-- Most complex function ever.
		function msp_AddFilter(character)
			filter[character] = GetTime()
		end
	end

	function msp:Send(character, data, channel, isRequest)
		data = table.concat(data, "\1")
		--print("Sending to: "..character)
		--print(GetTime()..": Out: "..character..": "..data:gsub("\1", ";"))

		-- Check whether sending by BN is available and preferred.
		if (not channel or channel == "BN") and self.bnet[character] then
			if not select(15, BNGetToonInfo(self.bnet[character])) then
				self.bnet[character] = nil
			elseif not channel then
				if self.cache[character].bnet == false then
					channel = "GAME"
				elseif self.cache[character].bnet == true then
					channel = "BN"
				end
			end
		end

		if (not channel or channel == "BN") and self.bnet[character] then
			local presenceID = self.bnet[character]
			local queue = ("XRP-%u"):format(presenceID)
			if #data <= 4078 then
				libbw:BNSendGameData(presenceID, "MSP", data, "NORMAL", queue)
			else
				-- XC is most likely to add five extra characters, will not add
				-- less than five, and only adds six or more if the profile is
				-- over 40000 characters or so. So let's say five.
				data = ("XC=%u\1%s"):format(((#data + 5) / 4078) + 1, data)
				local position = 1
				libbw:BNSendGameData(presenceID, "MSP\1", data:sub(position, position + 4077), "BULK", queue)
				position = position + 4078
				while position + 4078 <= #data do
					libbw:BNSendGameData(presenceID, "MSP\2", data:sub(position, position + 4077), "BULK", queue)
					position = position + 4078
				end
				libbw:BNSendGameData(presenceID, "MSP\3", data:sub(position), "BULK", queue)
			end
		end
		if channel == "BN" then return end

		local isGroup = channel ~= "WHISPER" and UnitRealmRelationship(Ambiguate(character, "none")) == LE_REALM_RELATION_COALESCED
		local isInstance = isGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
		channel = channel ~= "GAME" and channel or isGroup and (isInstance and "INSTANCE_CHAT" or "RAID") or "WHISPER"
		local prepend = isGroup and isRequest and ("%s\30"):format(character) or ""
		local queue = isGroup and "XRP-GROUP" or ("XRP-%s"):format(character)
		local callback = not isGroup and msp_AddFilter or nil
		local chunkSize = 255 - #prepend

		if #data <= chunkSize then
			libbw:SendAddonMessage(not isGroup and "MSP" or "GMSP", prepend .. data, channel, character, "NORMAL", queue, callback, character)
		else
			chunkSize = isGroup and chunkSize - 1 or chunkSize
			-- XC is most likely to add five or six extra characters, will
			-- not add less than five, and only adds seven or more if the
			-- profile is over 25000 characters or so. So let's say six.
			data = ("XC=%u\1%s"):format(((#data + 6) / chunkSize) + 1, data)
			local position = 1
			libbw:SendAddonMessage(not isGroup and "MSP\1" or "GMSP", (isGroup and "%s\1%s" or "%s%s"):format(prepend, data:sub(position, position + chunkSize - 1)), channel, character, "BULK", queue, callback, character)
			position = position + chunkSize
			while position + chunkSize <= #data do
				libbw:SendAddonMessage(not isGroup and "MSP\2" or "GMSP", (isGroup and "%s\2%s" or "%s%s"):format(prepend, data:sub(position, position + chunkSize - 1)), channel, character, "BULK", queue, callback, character)
				position = position + chunkSize
			end
			libbw:SendAddonMessage(not isGroup and "MSP\3" or "GMSP", (isGroup and "%s\3%s" or "%s%s"):format(prepend, data:sub(position)), channel, character, "BULK", queue, callback, character)
		end
	end
end

do
	-- Tooltip order for ideal XRP viewer usage.
	local TT_FIELDS = { "VP", "VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "FR", "FC" }
	local tt
	function msp:GetTT()
		if not tt then
			local current, tooltip = xrp.current, {}
			for i, field in ipairs(TT_FIELDS) do
				tooltip[#tooltip + 1] = not current.fields[field] and field or ("%s%u=%s"):format(field, current.versions[field], current.fields[field])
			end
			local newtt = table.concat(tooltip, "\1")
			tt = ("%s\1TT%u"):format(newtt, newtt ~= xrpSaved.oldtt and xrpPrivate:NewVersion("TT") or xrpSaved.versions.TT)
			xrpSaved.oldtt = newtt
		end
		return tt
	end
	xrp:HookEvent("UPDATE", function(event, field)
		if tt and (not field or xrpPrivate.fields.tt[field]) then
			tt = nil
		end
	end)
end

do
	local requestTime = setmetatable({}, {
		__index = function(self, character)
			self[character] = {}
			return self[character]
		end,
		__mode = "v", -- Worst case, we rarely send too soon again.
	})
	-- This returns requested field output, or nil if no requests were
	-- made. msp.cache[character].fieldUpdated is set to true if a
	-- field has changed, false if a field has not been changed.
	function msp:Process(character, command)
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
			if requestTime[character][field] and requestTime[character][field] > now - 10 then
				requestTime[character][field] = now
				return nil
			end
			requestTime[character][field] = now
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
		elseif action == "!" and version == (xrpCache[character] and xrpCache[character].versions[field] or 0) then
			-- Told us we have latest of their field.
			self.cache[character].time[field] = GetTime()
			self.cache[character].fieldUpdated = self.cache[character].fieldUpdated or false
			if field == "TT" and xrpCache[character] and self.cache[character].bnet == nil then
				local numVP = tonumber(xrpCache[character].fields.VP)
				if numVP then
					self.cache[character].bnet = numVP >= 2
				end
			end
			return nil
		elseif action == "" then
			-- Gave us a field.
			if not xrpCache[character] and (contents ~= "" or version ~= 0) then
				xrpCache[character] = {
					fields = {},
					versions = {},
				}
				-- What this does is pull the G-fields from the unitcache,
				-- accessed through xrp.cache, into the actual cache, but only
				-- if the character has MSP. This keeps the saved cache a bit
				-- more lightweight.
				--
				-- The G-fields are also put into the saved cache when they're
				-- initially generated, if the cache table for that character
				-- exists (indicating MSP support is/was present -- this
				-- function is the *only* place a character cache table is
				-- created).
				if xrpPrivate.gCache[character] then
					for gField, isUnitField in pairs(xrpPrivate.fields.unit) do
						xrpCache[character].fields[gField] = xrpPrivate.gCache[character][gField]
					end
				end
			end
			local updated = false
			if contents == "" and xrpCache[character] and xrpCache[character].fields[field] and not xrpPrivate.fields.unit[field] then
				-- If it's newly blank, empty it in the cache. Never
				-- empty G*, but do update them (following elseif).
				xrpCache[character].fields[field] = nil
				updated = true
			elseif contents ~= "" and contents ~= xrpCache[character].fields[field] then
				xrpCache[character].fields[field] = contents
				updated = true
				if field == "VA" then
					xrpPrivate:AddonUpdate(contents:match("^XRP/([^;]+)"))
				end
			end
			if version ~= 0 then
				xrpCache[character].versions[field] = version
			elseif xrpCache[character] then
				xrpCache[character].versions[field] = nil
			end
			-- Save time regardless of contents or version. This prevents
			-- querying again too soon. Query time is also set prior to initial
			-- send -- so timer will count from send OR receive as appropriate.
			self.cache[character].time[field] = GetTime()

			if updated then
				xrpPrivate:FireEvent("FIELD", character, field)
				self.cache[character].fieldUpdated = true
				if field == "VP" then
					local numVP = tonumber(contents)
					if numVP then
						self.cache[character].bnet = numVP >= 2
					end
				end
			else
				self.cache[character].fieldUpdated = self.cache[character].fieldUpdated or false
			end
			return nil
		end
	end
end

local TT_REQ = { "?TT" }
msp.handlers = {
	["MSP"] = function(self, character, message, channel)
		local out
		for command in message:gmatch("([^\1]+)\1*") do
			local response = self:Process(character, command)
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
		if self.cache[character].fieldUpdated == true then
			xrpPrivate:FireEvent("RECEIVE", character)
			self.cache[character].fieldUpdated = nil
		elseif self.cache[character].fieldUpdated == false then
			xrpPrivate:FireEvent("NOCHANGE", character)
			self.cache[character].fieldUpdated = nil
		end
		if out then
			self:Send(character, out, channel)
		end
		if xrpCache[character] ~= nil then
			-- Cache timer. Last receive marked for clearing old entries.
			xrpCache[character].lastReceive = time()
		elseif not self.cache[character].time.TT then
			-- If we don't have any info for them and haven't requested the
			-- tooltip in this session, also send a tooltip request
			self:Send(character, TT_REQ, channel, true)
		end
	end,
	["MSP\1"] = function(self, character, message, channel)
		local totalChunks = tonumber(message:match("^XC=(%d+)\1"))
		if totalChunks then
			self.cache[character].totalChunks = totalChunks
			-- Drop XC if present.
			message = message:gsub("^XC=%d+\1", "")
		end
		-- This only does partial processing -- queries (i.e., ?TT) are
		-- processed only after full reception. Mixed queries/responses are not
		-- common, but also not forbidden by the spec.
		for command in message:gmatch("([^\1]+)\1") do
			if command:find("^[^%?]") then
				self:Process(character, command)
				message = message:gsub(command:gsub("(%W)","%%%1") .. "\1", "")
			end
		end
		self.cache[character].chunks = 1
		self.cache[character][channel] = message
		xrpPrivate:FireEvent("CHUNK", character, 1, totalChunks)
	end,
	["MSP\2"] = function(self, character, message, channel)
		-- If we don't have a buffer (i.e., no prior received message),
		-- still try to process as many full commands as we can.
		if not self.cache[character][channel] then
			message = message:match("^.-\1(.+)$")
			if not message then return end
			self.cache[character][channel] = ""
		end
		-- Only merge the contents if there's an end-of-command to process.
		if message:find("\1", nil, true) then
			message = (type(self.cache[character][channel]) == "string" and self.cache[character][channel] or table.concat(self.cache[character][channel])) .. message
			for command in message:gmatch("([^\1]+)\1") do
				if command:find("^[^%?]") then
					self:Process(character, command)
					message = message:gsub(command:gsub("(%W)","%%%1") .. "\1", "")
				end
			end
			self.cache[character][channel] = message
		else
			if type(self.cache[character][channel]) == "string" then
				self.cache[character][channel] = { self.cache[character][channel], message }
			else
				self.cache[character][channel][#self.cache[character][channel] + 1] = message
			end
		end
		local chunks = (self.cache[character].chunks or 0) + 1
		self.cache[character].chunks = chunks
		xrpPrivate:FireEvent("CHUNK", character, chunks, self.cache[character].totalChunks)
	end,
	["MSP\3"] = function(self, character, message, channel)
		-- If we don't have a buffer (i.e., no prior received message),
		-- still try to process as many full commands as we can.
		if not self.cache[character][channel] then
			message = message:match("^.-\1(.+)$")
			if not message then return end
			self.cache[character][channel] = ""
		end
		self.handlers["MSP"](self, character, (type(self.cache[character][channel]) == "string" and self.cache[character][channel] or table.concat(self.cache[character][channel])) .. message, channel)
		-- CHUNK after RECEIVE would fire. Makes it easier to do something
		-- useful when chunks == totalChunks.
		xrpPrivate:FireEvent("CHUNK", character, (self.cache[character].chunks or 0) + 1, (self.cache[character].chunks or 0) + 1)

		self.cache[character].chunks = nil
		self.cache[character].totalChunks = nil
		self.cache[character][channel] = nil
	end,
	["GMSP"] = function(self, character, message, channel)
		local target, prefix, message = message:match(message:find("\30", nil, true) and "^(.+)\30([\1\2\3]?)(.+)$" or "^(.-)([\1\2\3]?)(.+)$")
		if not (target == "" or target == xrpPrivate.playerWithRealm) then return end
		self.handlers[prefix ~= "" and ("MSP%s"):format(prefix) or "MSP"](self, character, message, channel)
	end,
}

msp:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if event == "CHAT_MSG_ADDON" and self.handlers[prefix] then
		-- Sometimes won't have the realm attached because I dunno. Always
		-- works correctly for different-realm messages.
		local character = xrp:Name(sender)
		--print(GetTime()..": In: "..character..": "..message:gsub("\1", ";"))
		--print("Receiving from: "..character)

		-- Ignore messages from ourselves (GMSP).
		if character ~= xrpPrivate.playerWithRealm then
			self.cache[character].received = true
			self.cache[character].nextCheck = nil

			self.handlers[prefix](self, character, message, channel)
		end
	elseif event == "BN_CHAT_MSG_ADDON" and self.handlers[prefix] then
		local active, toonName, client, realmName = BNGetToonInfo(sender)
		local character = xrp:Name(toonName, realmName)
		self.bnet[character] = sender

		self.cache[character].bnet = true
		self.cache[character].received = true
		self.cache[character].nextCheck = nil

		self.handlers[prefix](self, character, message, "BN")
	elseif event == "BN_TOON_NAME_UPDATED" or event == "BN_FRIEND_TOON_ONLINE" then
		local active, toonName, client, realmName = BNGetToonInfo(prefix)
		if client == "WoW" then
			local character = xrp:Name(toonName, realmName)
			if not self.bnet[character] and not self.cache[character].received then
				self.cache[character].nextCheck = 0
			end
			self.bnet[character] = prefix
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
	for prefix, func in pairs(msp.handlers) do
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
		for character, fields in pairs(self.request) do
			xrpPrivate:Request(character, fields)
			self.request[character] = nil
		end
	end
	self:Hide()
end
msp:Hide()
msp:SetScript("OnUpdate", msp.OnUpdate)

xrpPrivate.msp = 2

xrpPrivate.fields = {
	-- Fields in tooltip.
	tt = { VP = true, VA = true, NA = true, NH = true, NI = true, NT = true, RA = true, RC = true, FR = true, FC = true, CU = true },
	-- These fields are (or should) be generated from UnitSomething()
	-- functions. GF is an XRP-original, storing non-localized faction (since
	-- we cache between sessions and can have data on both factions at once).
	unit = { GC = true, GF = true, GR = true, GS = true, GU = true },
	-- Metadata fields, not to be user-set.
	meta = { VA = true, VP = true },
	-- Dummy fields are used for extra XRP communication, not to be
	-- user-exposed.
	dummy = { XC = true },
	-- 30 seconds for non-TT fields.
	times = setmetatable({ TT = 15, }, {
		__index = function(self, field)
			if xrpPrivate.fields.tt[field] then
				return self.TT
			end
			return 30
		end,
	}),
}

function xrpPrivate:QueueRequest(character, field)
	if disabled or character == xrpPrivate.playerWithRealm or xrp:Ambiguate(character) == UNKNOWN or msp.cache[character].time[field] and GetTime() < msp.cache[character].time[field] + self.fields.times[field] then
		return false
	end

	if not msp.request[character] then
		msp.request[character] = {}
	end

	msp.request[character][#msp.request[character] + 1] = field
	msp:Show()

	return true
end

function xrpPrivate:Request(character, fields)
	if disabled or character == xrpPrivate.playerWithRealm or xrp:Ambiguate(character) == UNKNOWN then
		return false
	end

	local now = GetTime()
	if not msp.cache[character].received and now < msp.cache[character].nextCheck then
		self:FireEvent("FAIL", character, "nomsp")
		return false
	elseif not msp.cache[character].received then
		msp.cache[character].nextCheck = now + 120
	end

	-- No need to strip repeated fields -- the logic below for not querying
	-- fields repeatedly over a short time will handle that for us.
	local reqTT = false
	-- This entire for block is FRAGILE. Modifications not recommended.
	for key = #fields, 1, -1 do
		if fields[key] == "TT" or self.fields.tt[fields[key]] then
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
		if not msp.cache[character].time[field] or now > msp.cache[character].time[field] + self.fields.times[field] then
			local noVersion = not xrpCache[character] or not xrpCache[character].versions[field]
			out[#out + 1] = (noVersion and "?%s" or "?%s%u"):format(field, noVersion or xrpCache[character].versions[field])
			msp.cache[character].time[field] = now
		end
	end
	if #out > 0 then
		msp:Send(character, out, nil, true)
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
