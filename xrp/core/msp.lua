--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

-- Claim MSP rights ASAP to try heading off other addons. Since we start with
-- "x", this probably won't help much.
local disabled = false
if not msp_RPAddOn then
	msp_RPAddOn = GetAddOnMetadata("xrp", "Title")
else
	StaticPopupDialogs["XRP_MSP_DISABLE"] = {
		text = xrp.L["You are running another RP profile addon (%s). XRP's support for sending and receiving profiles is disabled; to enable it, disable %s and reload your UI."],
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
-- like LibMSP and is not public, despite using the same table name. The
-- (minimal) public API is contained in xrp. In general even that shouldn't
-- be interacted with.
local msp = CreateFrame("Frame")
-- OnUpdate timer.
msp.timer = 0.08
-- Sending message queue; send queue safety; requested field queue
msp.send, msp.safe, msp.request = {}, {}, {}
-- Session cache. Do NOT make weak.
msp.cache = setmetatable({}, {
	__index = function(self, character)
		self[character] = {
			nextcheck = 0,
			lastsend = 0,
			received = false,
			time = {},
		}
		return self[character]
	end,
})

do
	local msp_AddFilter
	do
		-- Filter "No such..." errors.
		local filter = setmetatable({}, { __mode = "v" })

		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, message)
			local character = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
			if not character or character == "" or not filter[character] then
				return false
			end
			local now = GetTime()
			-- Filter if within 1000ms of current time plus home latency.
			-- GetNetStats() provides value in milliseconds.
			local dofilter = filter[character] > (now - 1.000 - ((select(3, GetNetStats())) * 0.001))
			if not dofilter then
				filter[character] = nil
			else
				-- If they're not offline, they're opposite faction. Same error
				-- for both.
				local offline = not (xrp.cache[character].GF and xrp.cache[character].GF ~= xrp.toon.fields.GF)
				-- 30 second timer between checks for offline characters. Try
				-- to not query offline characters higher up the chain as well,
				-- remember.
				if msp.cache[character].nextcheck and offline then
					msp.cache[character].nextcheck = now + 30
				end
				msp.send[character] = nil
				xrp:FireEvent("MSP_FAIL", character, offline and "offline" or "faction")
			end
			return dofilter
		end)

		-- Most complex function ever.
		function msp_AddFilter(character)
			filter[character] = GetTime()
		end
	end

	function msp:Send(character, data)
		data = table.concat(data, "\1")
		--print("Sending to: "..character)
		--print(GetTime()..": Out: "..character..": "..data:gsub("\1", "\\1"))
		if #data <= 255 then
			ChatThrottleLib:SendAddonMessage("NORMAL", "MSP", data, "WHISPER", character, "XRP-"..character, msp_AddFilter, character)
			--print(character..": Outgoing MSP")
		else
			-- XC is most likely to add five or six extra characters, will not
			-- add less than five, and only adds seven or more if the profile
			-- is over 25000 characters or so. So let's say six.
			data = ("XC=%u\1%s"):format(math.ceil((#data + 6) / 255), data)
			local position = 1
			ChatThrottleLib:SendAddonMessage("BULK", "MSP\1", data:sub(position, position + 254), "WHISPER", character, "XRP-"..character, msp_AddFilter, character)
			--print(character..": Outgoing MSP\\1")
			position = position + 255
			while position + 255 <= #data do
				ChatThrottleLib:SendAddonMessage("BULK", "MSP\2", data:sub(position, position + 254), "WHISPER", character, "XRP-"..character, msp_AddFilter, character)
				--print(character..": Outgoing MSP\\2")
				position = position + 255
			end
			ChatThrottleLib:SendAddonMessage("BULK", "MSP\3", data:sub(position), "WHISPER", character, "XRP-"..character, msp_AddFilter, character)
			--print(character..": Outgoing MSP\\3")
		end
		self.cache[character].lastsend = GetTime()
	end

	local function msp_DummyFilter(character)
		--print("dummy sent")
		msp_AddFilter(character)
		if msp.send[character] then
			--print("queuing next message")
			msp.send[character].sendtime = GetTime() + msp.send[character].delay
		end
	end

	function msp:Dummy(character, response)
		--print(GetTime()..": Out: "..character..": "..(response and "XD" or "?XD"))
		ChatThrottleLib:SendAddonMessage("ALERT", "MSP", response and "XD" or "?XD", "WHISPER", character, "XRP-"..character, response and msp_AddFilter or msp_DummyFilter, character)
		self.cache[character].lastsend = GetTime()
	end
end

-- TODO 6.0: RIP THIS OUT. HOORAY!!
function msp:QueueSend(character, data, count)
	if self.send[character] then
		for _, request in ipairs(data) do
			self.send[character].data[#self.send[character].data + 1] = request
		end
		if count and count - 1 < self.send[character].count then
			self.send[character].count = count - 1
		end
		return
	end
	local now = GetTime()
	-- Names as units are odd -- same realm MUST NOT have realm attached.
	local unit = Ambiguate(character, "none")
	if count == 0 or (self.cache[character].received and now < self.cache[character].lastsend + 60) or UnitInParty(unit) or UnitInRaid(unit) then
		self:Send(character, data)
		return
	end
	local delay = (count == 1 or self.cache[character].received or now < self.cache[character].lastsend + 60) and (1.000 + ((select(3, GetNetStats())) * 0.001)) or (0.500 + ((select(3, GetNetStats())) * 0.001))
	self.send[character] = { data = data, count = (count or 2) - 1, delay = delay, sendtime = now + delay }
	self:Dummy(character)
	self:Show()
end

function msp:OnUpdate(elapsed)
	self.timer = self.timer + elapsed
	if self.timer < 0.08 then return end
	self.timer = 0
	-- This exhausts itself every time it's run. One and done.
	if next(self.request) then
		for character, fields in pairs(self.request) do
			--print(character..": "..fields)
			xrp:Request(character, fields, self.safe[character])
			self.request[character] = nil
			self.safe[character] = nil
		end
	end
	-- This might need to keep running repeatedly.
	if next(self.send) then
		for character, message in pairs(self.send) do
			local now = GetTime()
			if message.sendtime and message.sendtime <= now and message.count > 0 then
				message.count = message.count - 1
				message.sendtime = nil
				self:Dummy(character)
			elseif message.sendtime and message.sendtime <= now then
				self:Send(character, message.data)
				self.send[character] = nil
			end
		end
	else
		-- Only if there's nothing left in the send queue.
		self:Hide()
		-- Run first framedraw on next show.
		self.timer = 0.08
	end
end
msp:Hide()
msp:SetScript("OnUpdate", msp.OnUpdate)

-- Caches a tooltip response, but *does not* modify the tooltip version. That
-- needs to be done, if appropriate, whenever this is called.
do
	-- This sets the field order to a xrp_viewer-ideal incoming order.
	local tt = { "VP", "VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "FR", "FC" }
	function msp:CacheTT()
		local tooltip = {}
		for _, field in ipairs(tt) do
			tooltip[#tooltip + 1] = (not xrp.current[field] and (not xrp_versions[field] and "%s" or "%s%u") or "%s%u=%s"):format(field, xrp_versions[field], xrp.current[field])
		end
		tooltip[#tooltip + 1] = ("TT%u"):format(xrp_versions.TT)
		self.tt = table.concat(tooltip, "\1")
		--print((self.tt:gsub("\1", "\\1")))
	end
end

do
	local req_timer = setmetatable({}, {
		__index = function(self, character)
			self[character] = {}
			return self[character]
		end,
		__mode = "v", -- Worst case, we rarely send too soon again.
	})
	-- This returns requested field output, or nil if no requests were
	-- made. msp.cache[character].fieldupdated is set to true if a
	-- field has changed, false if a field has not been changed.
	function msp:Process(character, command)
		-- Original LibMSP match string uses %a%a rather than %u%u.
		-- According to protcol documentation, %u%u would be more
		-- correct.
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
			if req_timer[character][field] and req_timer[character][field] > now - 10 then
				req_timer[character][field] = now
				return nil
			end
			req_timer[character][field] = now
			if (xrp_versions[field] and version == xrp_versions[field]) or (not xrp_versions[field] and version == 0) then
				-- They already have the latest.
				return (not xrp_versions[field] and "%s" or "!%s%u"):format(field, xrp_versions[field])
			elseif field == "TT" then
				if not self.tt then -- Panic, something went wrong in init.
					xrp:Update() -- ...but try to fix it.
				end
				return self.tt
			elseif not xrp.current[field] then
				-- Field is empty.
				return (not xrp_versions[field] and "%s" or "%s%u"):format(field, xrp_versions[field])
			end
			-- Field has content.
			return ("%s%u=%s"):format(field, xrp_versions[field], xrp.current[field])
		elseif action == "!" then
			-- Told us we have latest of their field.
			self.cache[character].time[field] = GetTime()
			self.cache[character].fieldupdated = self.cache[character].fieldupdated or false
			return nil
		elseif action == "" then
			-- Gave us a field.
			if not xrp_cache[character] and (contents ~= "" or version ~= 0) then
				xrp_cache[character] = {
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
				for gfield, _ in pairs(xrp.fields.unit) do
					xrp_cache[character].fields[gfield] = xrp.cache[character][gfield]
				end
			end
			local updated = false
			if xrp_cache[character] and xrp_cache[character].fields[field] and contents == "" and not xrp.fields.unit[field] then
				-- If it's newly blank, empty it in the cache. Never
				-- empty G*, but do update them (following elseif).
				xrp_cache[character].fields[field] = nil
				updated = true
			elseif contents ~= "" and xrp_cache[character].fields[field] ~= contents then
				xrp_cache[character].fields[field] = contents
				updated = true
				if field == "VA" then
					xrp:UpdateVersion(contents:match("^XRP/([^;]+)"))
				end
			end
			if version ~= 0 then
				xrp_cache[character].versions[field] = version
			elseif xrp_cache[character] then
				xrp_cache[character].versions[field] = nil
			end
			-- Save time regardless of contents or version. This prevents
			-- querying again too soon. Query time is also set prior to initial
			-- send -- so timer will count from send OR receive as appropriate.
			self.cache[character].time[field] = GetTime()

			if updated then
				xrp:FireEvent("MSP_FIELD", character, field)
				self.cache[character].fieldupdated = true
			else
				self.cache[character].fieldupdated = self.cache[character].fieldupdated or false
			end
			return nil
		end
	end
end

msp.handlers = {
	["MSP"] = function(self, character, message)
		local out = {}
		for command in message:gmatch("([^\1]+)\1*") do
			out[#out + 1] = self:Process(character, command)
		end
		-- If a field has been updated (i.e., changed content), fieldupdated
		-- will be set to true; if a field was received, but the content has
		-- not changed, fieldupdated will be set to false; if no fields were
		-- received (i.e., only requests), fieldupdated is nil.
		if self.cache[character].fieldupdated == true then
			xrp:FireEvent("MSP_RECEIVE", character)
			self.cache[character].fieldupdated = nil
		elseif self.cache[character].fieldupdated == false then
			xrp:FireEvent("MSP_NOCHANGE", character)
			self.cache[character].fieldupdated = nil
		end
		if #out > 0 then
			self:QueueSend(character, out)
		end
		-- Cache timer. Last receive marked for clearing old entries.
		if xrp_cache[character] then
			xrp_cache[character].lastreceive = time()
		end
	end,
	["MSP\1"] = function(self, character, message)
		local totalchunks = tonumber(message:match("^XC=(%d+)\1"))
		if totalchunks then
			self.cache[character].totalchunks = totalchunks
			-- Drop XC if present.
			message = message:gsub(("XC=%d\1"):format(totalchunks), "")
		end
		-- This only does partial processing -- queries (i.e., ?NA) are
		-- processed only after full reception. Most times that sort of mixed
		-- message won't even exist, but XRP can produce it sometimes.
		for command in message:gmatch("([^\1]+)\1") do
			if command:find("^[^%?]") then
				self:Process(character, command)
				message = message:gsub(command:gsub("(%W)","%%%1").."\1", "")
			end
		end
		--print(message:gsub("\1", "\\1"))
		self.cache[character].chunks = 1
		-- First message = fresh buffer.
		self.cache[character].buffer = message
		xrp:FireEvent("MSP_CHUNK", character, self.cache[character].chunks, self.cache[character].totalchunks or nil)
	end,
	["MSP\2"] = function(self, character, message)
		-- If we don't have a buffer (i.e., no prior received message),
		-- still try to process as many full commands as we can.
		if not self.cache[character].buffer then
			message = message:match("^.-\1(.+)$")
			if not message then return end
			self.cache[character].buffer = ""
		end
		if message:find("\1", 1, true) then
			message = type(self.cache[character].buffer) == "string" and (self.cache[character].buffer..message) or (table.concat(self.cache[character].buffer)..message)
			for command in message:gmatch("([^\1]+)\1") do
				if command:find("^[^%?]") then
					self:Process(character, command)
					message = message:gsub(command:gsub("(%W)","%%%1").."\1", "")
				end
			end
			self.cache[character].buffer = message
		else
			if type(self.cache[character].buffer) == "string" then
				self.cache[character].buffer = { self.cache[character].buffer, message }
			else
				self.cache[character].buffer[#self.cache[character].buffer + 1] = message
			end
		end
		self.cache[character].chunks = (self.cache[character].chunks or 0) + 1
		xrp:FireEvent("MSP_CHUNK", character, self.cache[character].chunks, self.cache[character].totalchunks or nil)
	end,
	["MSP\3"] = function(self, character, message)
		-- If we don't have a buffer (i.e., no prior received message),
		-- still try to process as many full commands as we can.
		if not self.cache[character].buffer then
			message = message:match("^.-\1(.+)$")
			if not message then return end
			self.cache[character].buffer = ""
		end
		self.handlers["MSP"](self, character, type(self.cache[character].buffer) == "string" and (self.cache[character].buffer..message) or (table.concat(self.cache[character].buffer)..message))
		-- MSP_CHUNK after MSP_RECEIVE would fire. Makes it easier to
		-- do something useful when chunks == totalchunks.
		xrp:FireEvent("MSP_CHUNK", character, (self.cache[character].chunks or 0) + 1, (self.cache[character].chunks or 0) + 1)

		self.cache[character].chunks = nil
		self.cache[character].totalchunks = nil
		self.cache[character].buffer = nil
	end,
}

if not disabled then
	for prefix, _ in pairs(msp.handlers) do
		RegisterAddonMessagePrefix(prefix)
	end

	msp:SetScript("OnEvent", function(self, event, prefix, message, channel, character)
		if event == "CHAT_MSG_ADDON" and self.handlers[prefix] then
			--print(GetTime()..": In: "..character..": "..message:gsub("\1", "\\1"))
			--print("Receiving from: "..character)

			local received = self.cache[character].received
			self.cache[character].received = true
			self.cache[character].nextcheck = nil

			-- Dummy messages, requests and responses, are handled quickly,
			-- rather than running full processing on them. This also cuts out
			-- the attempts to send dummy requests when receiving a dummy
			-- request (to be absolutely certain that the *vital* dummy
			-- response reaches the other side...).
			if message == "?XD" then
				if self.send[character] and not received then
					self.send[character].count = self.send[character].count - 1
				end
				self:Dummy(character, true)
			elseif message == "XD" then
				if self.send[character] then
					self.send[character].sendtime = GetTime()
					self.send[character].count = 0
				end
			else
				if self.send[character] and not received then
					self.send[character].count = self.send[character].count - 1
				end
				self.handlers[prefix](self, character, message)
			end
		elseif event == "PLAYER_REGEN_DISABLED" then
			ChatThrottleLib.MAX_CPS = 800
		elseif event == "PLAYER_REGEN_ENABLED" then
			ChatThrottleLib.MAX_CPS = 1200
		end
	end)
	msp:RegisterEvent("CHAT_MSG_ADDON")
	msp:RegisterEvent("PLAYER_REGEN_DISABLED")
	msp:RegisterEvent("PLAYER_REGEN_ENABLED")
	ChatThrottleLib.MAX_CPS = 1200 -- up from 800
	ChatThrottleLib.MIN_FPS = 15 -- down from 20
end

xrp.msp = 1

xrp.fields = {
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
	dummy = { XC = true, XD = true },
	-- 45 seconds for non-TT fields.
	times = setmetatable({ TT = 15, }, {
		__index = function(self, field)
			if xrp.fields.tt[field] then
				return self.TT
			end
			return 45
		end,
	}),
}

function xrp:QueueRequest(character, field, safe)
	if disabled or character == self.toon.withrealm or self:NameWithoutRealm(character) == UNKNOWN then return false end

	if not msp.request[character] then
		msp.request[character] = {}
	end

	msp.request[character][#msp.request[character] + 1] = field
	msp.safe[character] = (not msp.safe[character] or safe < msp.safe[character]) and safe or msp.safe[character]
	msp:Show()

	return true
end

function xrp:Request(character, fields, safe)
	if disabled or character == self.toon.withrealm or self:NameWithoutRealm(character) == UNKNOWN then return false end

	local now = GetTime()
	if not msp.cache[character].received and now < msp.cache[character].nextcheck then
		self:FireEvent("MSP_FAIL", character, "nomsp")
		return false
	elseif not msp.cache[character].received then
		msp.cache[character].nextcheck = now + (safe == 0 and 300 or 30)
	end

	-- No need to strip repeated fields -- the logic below for not querying
	-- fields repeatedly over a short time will handle that for us.
	local reqtt = false
	-- This entire for block is FRAGILE. Modifications not recommended.
	for key = #fields, 1, -1 do
		if fields[key] == "TT" or self.fields.tt[fields[key]] then
			table.remove(fields, key)
			reqtt = true
		end
	end
	if reqtt then
		-- Want TT at start of request.
		table.insert(fields, 1, "TT")
	end

	local out = {}
	for _, field in ipairs(fields) do
		if not msp.cache[character].time[field] or now > msp.cache[character].time[field] + self.fields.times[field] then
			out[#out + 1] = ((not xrp_cache[character] or not xrp_cache[character].versions[field]) and "?%s" or "?%s%u"):format(field, xrp_cache[character] and xrp_cache[character].versions[field] or 0)
			msp.cache[character].time[field] = now
		end
	end
	if #out > 0 then
		--print(character..": "..table.concat(out, " "))
		if safe == 0 then
			msp:Send(character, out)
		else
			msp:QueueSend(character, out, safe or 2)
		end
		return true
	end
	return false
end

function xrp:Update()
	if disabled then return false end
	local changes, ttchanges, character = false, false, self.toon.withrealm
	local new, old = self.current(), xrp_cache[character].fields
	for field, contents in pairs(new) do
		if old[field] ~= contents then
			changes = true
			xrp_versions[field] = (xrp_versions[field] or 0) + 1
			xrp_cache[character].fields[field] = contents
			xrp_cache[character].versions[field] = xrp_versions[field]
			ttchanges = self.fields.tt[field] or ttchanges
		end
	end
	for field, _ in pairs(old) do
		if not new[field] then
			changes = true
			xrp_versions[field] = (xrp_versions[field] or 0) + 1
			xrp_cache[character].fields[field] = nil
			xrp_cache[character].versions[field] = xrp_versions[field]
			ttchanges = self.fields.tt[field] or ttchanges
		end
	end
	if ttchanges then
		xrp_versions.TT = (xrp_versions.TT or 0) + 1
		xrp_cache[character].versions.TT = xrp_versions.TT
		msp:CacheTT()
	elseif not msp.tt then
		-- If it's our character we never want the cache tidy to wipe it out.
		-- Do this by setting the wipe timer for 2038. This should get run on
		-- the first update every session (i.e., around PLAYER_LOGIN).
		xrp_cache[character].lastreceive = time()
		xrp_cache[character].own = true
		msp:CacheTT()
	end
	if changes then
		self:FireEvent("MSP_UPDATE")
		return true
	end
	return false
end

function xrp:UpdateField(field)
	if disabled then return false end
	local character = self.toon.withrealm
	local new, old = self.current[field], xrp_cache[character].fields[field]
	if old ~= new then
		xrp_versions[field] = (xrp_versions[field] or 0) + 1
		xrp_cache[character].fields[field] = new
		xrp_cache[character].versions[field] = xrp_versions[field]
		if self.fields.tt[field] then
			xrp_versions.TT = (xrp_versions.TT or 0) + 1
			xrp_cache[character].versions.TT = xrp_versions.TT
			msp:CacheTT()
		elseif not msp.tt then
			xrp_cache[character].lastreceive = time()
			xrp_cache[character].own = true
			msp:CacheTT()
		end
		self:FireEvent("MSP_UPDATE", field)
		return true
	end
	return false
end

-- The following is a workaround for the fact that OnUpdate scripts won't fire
-- when the user is tabbed out in fullscreen (non-windowed) mode. It uses some
-- common events to fake running OnUpdates if there hasn't been any recent
-- framedraws to keep sending/receiving properly while tabbed out (albeit with
-- the possibility of some delay).
local function fs_Create()
	local frame = CreateFrame("Frame")
	frame:Hide()
	frame:SetScript("OnShow", function(self)
		local now = GetTime()
		self.lastdraw = now
		self.lastmsp = now
		self.lastctl = now
	end)
	frame:SetScript("OnUpdate", function(self, elapsed)
		self.lastdraw = self.lastdraw + elapsed
	end)
	frame:SetScript("OnEvent", function(self, event)
		local now = GetTime()
		--print(now..": "..event)
		if self.lastdraw < now - 5 then
			--print("No framedraw for 5+ seconds.")
			-- No framedraw for 5+ seconds.
			if msp:IsVisible() then
				--print(now..": Running MSP OnUpdate!")
				msp:OnUpdate(now - self.lastmsp)
				self.lastmsp = now
			end
			if ChatThrottleLib.Frame:IsVisible() then
				--print(now..": Running CTL OnUpdate!")
				-- Temporarily setting MIN_FPS to zero since... Well, no
				-- framedraws are happening, but it's not because the system is
				-- bogged down.
				local minfps = ChatThrottleLib.MIN_FPS
				ChatThrottleLib.MIN_FPS = 0
				ChatThrottleLib.OnUpdate(ChatThrottleLib.Frame, now - self.lastctl)
				ChatThrottleLib.MIN_FPS = minfps
				self.lastctl = now
			end
		end
	end)
	return frame
end

local fsframe
local function fs_Check()
	if GetCVar("gxWindow") == "0" then
		--print("Fullscreen enabled.")
		-- Is true fullscreen.
		fsframe = fsframe or fs_Create()
		fsframe:Show()
		-- These events are relatively common while idling, so are used to
		-- fake OnUpdate when tabbed out.
		fsframe:RegisterEvent("CHAT_MSG_ADDON")
		fsframe:RegisterEvent("CHAT_MSG_CHANNEL")
		fsframe:RegisterEvent("CHAT_MSG_GUILD")
		fsframe:RegisterEvent("CHAT_MSG_SAY")
		fsframe:RegisterEvent("CHAT_MSG_EMOTE")
		fsframe:RegisterEvent("GUILD_ROSTER_UPDATE")
		fsframe:RegisterEvent("GUILD_TRADESKILL_UPDATE")
		fsframe:RegisterEvent("GUILD_RANKS_UPDATE")
		fsframe:RegisterEvent("PLAYER_GUILD_UPDATE")
		fsframe:RegisterEvent("COMPANION_UPDATE")
		-- This would be nice to use, but actually having it happening
		-- in-combat would be huge overhead.
		--fsframe:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	elseif fsframe then
		-- Is not true fullscreen, but the frame exists. Hide it, and
		-- disable events.
		fsframe:Hide()
		fsframe:UnregisterAllEvents()
	end
end

hooksecurefunc("RestartGx", fs_Check)
fs_Check()
