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

xrp.msp = {
	-- xrp uses some new fields, but the protocol is v1.
	protocol = 1,
	-- Fields in tooltip.
	ttfields = { VP = true, VA = true, NA = true, NH = true, NI = true, NT = true, RA = true, FR = true, FC = true, CU = true },
	-- These fields are (or should) be generated from UnitSomething()
	-- functions. GF is an xrp-original, storing non-localized faction (since
	-- we cache between sessions and can have data on both factions at once).
	unitfields = { GC = true, GF = true, GR = true, GS = true, GU = true },
	-- Metadata fields, not to be user-set.
	metafields = { VA = true, VP = true },
	-- Dummy fields are used for extra XRP communication, not to be
	-- user-exposed.
	dummyfields = { XC = true, XD = true },
	-- 45 seconds for non-TT fields.
	fieldtimes = setmetatable(
		{ TT = 15, },
		{
			__index = function(self, field)
				return 45
			end,
		}
	),
}

-- Claim MSP rights ASAP to try heading off other addons. Since we start with
-- "x", this probably won't help much.
local disabled = false
if not msp_RPAddOn then
	msp_RPAddOn = GetAddOnMetadata("xrp", "Title")
else
	StaticPopupDialogs["XRP_MSP_DISABLE"] = {
		text = xrp.L["You are running another RP profile addon (%s). XRP's support for sending and receiving profiles is disabled; to enable it, disable %s and reload your UI."]:format(msp_RPAddOn, msp_RPAddOn),
		button1 = OKAY,
		showAlert = true,
		enterClicksFirstButton = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	disabled = true
	StaticPopup_Show("XRP_MSP_DISABLE")
end

-- Session cache.
local tmp_cache = setmetatable({}, {
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

local msp_Send
do
	local msp_AddFilter
	do
		-- Filtered "No such..." errors.
		local filter = setmetatable({}, { __mode = "v" })

		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, message)
			local character = message:match(ERR_CHAT_PLAYER_NOT_FOUND_S:format("(.+)"))
			if character == nil or character == "" then
				return false
			end
			local now = GetTime()
			-- Filter if within 750ms of current time plus home latency.
			-- GetNetStats() provides value in milliseconds.
			local dofilter = filter[character] and filter[character] > (now - 0.750 - ((select(3, GetNetStats())) * 0.001)) or false
			if not dofilter then
				filter[character] = nil
			else
				-- 30 second timer between checks for offline characters. Try
				-- to not query offline characters higher up the chain as well,
				-- remember.
				if tmp_cache[character].nextcheck then
					tmp_cache[character].nextcheck = now + 30
				end
				xrp:FireEvent("MSP_FAIL", character, xrp.cache[character].GF ~= xrp.toon.fields.GF and "faction" or "offline")
			end
			return dofilter
		end)
		function msp_AddFilter(character)
			filter[character] = GetTime()
		end
	end

	function msp_Send(character, data)
		data = table.concat(data, "\1")
		--print("Sending to: "..character)
		--print("Out: "..character..": "..data:gsub("\1", "\\1"))
		if #data <= 255 then
			ChatThrottleLib:SendAddonMessage("BULK", "MSP", data, "WHISPER", character, "MSP-"..character, msp_AddFilter, character)
			--print(character..": Outgoing MSP")
		else
			-- XC is most likely to add five or six extra characters, will not
			-- add less than five, and only adds seven or more if the profile
			-- is over 25000 characters or so. So let's say six.
			data = ("XC=%u\1%s"):format(math.ceil((#data + 6) / 255), data)
			local position = 1
			ChatThrottleLib:SendAddonMessage("BULK", "MSP\1", data:sub(position, position + 254), "WHISPER", character, "MSP-"..character, msp_AddFilter, character)
			--print(character..": Outgoing MSP\\1")
			position = position + 255
			while position + 255 <= #data do
				ChatThrottleLib:SendAddonMessage("BULK", "MSP\2", data:sub(position, position + 254), "WHISPER", character, "MSP-"..character, msp_AddFilter, character)
				--print(character..": Outgoing MSP\\2")
				position = position + 255
			end
			ChatThrottleLib:SendAddonMessage("BULK", "MSP\3", data:sub(position), "WHISPER", character, "MSP-"..character, msp_AddFilter, character)
			--print(character..": Outgoing MSP\\3")
		end
		tmp_cache[character].lastsend = GetTime()
	end
end

-- OnUpdate/OnEvent frame.
local msprun = CreateFrame("Frame")
-- OnUpdate timer.
msprun.timer = 0
-- Sending message queue; send queue safety; requested field queue
msprun.send, msprun.safe, msprun.request = {}, {}, {}

-- Dummy workaround request.
msprun.dummy = { "?XD" }

local function msp_QueueSend(character, data, count)
	if msprun.send[character] then
		for _, request in ipairs(data) do
			msprun.send[character].data[#msprun.send[character].data + 1] = request
		end
		return
	end
	local now = GetTime()
	local unit = Ambiguate(character, "none")
	if count == 0 or (tmp_cache[character].received and now < tmp_cache[character].lastsend + 45) or UnitInParty(unit) or UnitInRaid(unit) then
		msp_Send(character, data)
		return
	elseif count == 1 or tmp_cache[character].received or now < tmp_cache[character].lastsend + 45 then
		count = 0
		now = now + 1.000 + ((select(3, GetNetStats())) * 0.001) -- One-way safe needs more delay.
	else
		count = 1
		now = now + 0.500 + ((select(3, GetNetStats())) * 0.001)
	end
	msp_Send(character, msprun.dummy)
	msprun.send[character] = { data = data, count = count, sendtime = now }
	msprun:Show()
end

function xrp.msp:QueueRequest(character, field, safe)
	if disabled or character == xrp.toon.withrealm or xrp:NameWithoutRealm(character) == UNKNOWN then
		return false
	end
	local append = true
	if not msprun.request[character] then
		msprun.request[character] = {}
	else
		for _, reqfield in pairs(msprun.request[character]) do
			if append and reqfield == field then
				append = false
			end
		end
	end
	-- Always want the lowest (i.e., safest) value to skip dummies if possible.
	msprun.safe[character] = (not msprun.safe[character] or safe < msprun.safe[character]) and safe or msprun.safe[character]
	if append then
		--print(character..": "..field)
		msprun.request[character][#msprun.request[character] + 1] = field
		msprun:Show()
	end
	return true
end

function xrp.msp:Request(character, fields, safe)
	if disabled or character == xrp.toon.withrealm or xrp:NameWithoutRealm(character) == UNKNOWN then
		return false
	end

	local now = GetTime()
	if not tmp_cache[character].received and now < tmp_cache[character].nextcheck then
		xrp:FireEvent("MSP_FAIL", character, "nomsp")
		return false
	elseif not tmp_cache[character].received then
		tmp_cache[character].nextcheck = now + (safe == 0 and 300 or 30)
	end

	if not fields then
		fields = { "TT" }
	elseif type(fields) == "string" then
		fields = { fields }
	elseif type(fields) == "table" then
		-- No need to strip repeated fields -- the logic below for not querying
		-- fields repeatedly over a short time will handle that for us.
		local reqtt = false
		-- This entire for block is FRAGILE. Modifications not recommended.
		for key = #fields, 1, -1 do
			if fields[key] == "TT" or xrp.msp.ttfields[fields[key]] then
				table.remove(fields, key)
				reqtt = true
			end
		end
		if reqtt then
			fields[#fields + 1] = "TT"
		end
	else
		return false
	end

	local out = {}
	for _, field in ipairs(fields) do
		if not tmp_cache[character].time[field] or now > tmp_cache[character].time[field] + xrp.msp.fieldtimes[field] then
			out[#out + 1] = ((not xrp_cache[character] or not xrp_cache[character].versions[field]) and "?%s" or "?%s%u"):format(field, xrp_cache[character] and xrp_cache[character].versions[field] or 0)
			tmp_cache[character].time[field] = now
		end
	end
	if #out > 0 then
		--print(character..": "..table.concat(out, " "))
		if safe == 0 then
			msp_Send(character, out)
		else
			msp_QueueSend(character, out, safe or 2)
		end
		return true
	end
	xrp:FireEvent("MSP_FAIL", character, "time")
	return false
end

msprun:Hide()
msprun:SetScript("OnUpdate", function(self, elapsed)
	if next(self.request) then
		for character, fields in pairs(self.request) do
			--print(character..": "..fields)
			xrp.msp:Request(character, fields, self.safe[character])
			self.request[character] = nil
			self.safe[character] = nil
		end
	elseif next(self.send) then
		self.timer = self.timer + elapsed
		if self.timer > 0.250 then
			self.timer = 0
			local now = GetTime()
			for character, message in pairs(self.send) do
				if message.sendtime <= now and message.count > 0 then
					msp_Send(character, self.dummy)
					message.count = message.count - 1
					message.sendtime = now + 0.500 + ((select(3, GetNetStats())) * 0.001)
				elseif message.sendtime <= now and message.count == 0 then
					msp_Send(character, message.data)
					self.send[character] = nil
				end
			end
		end
	else
		self:Hide()
	end
end)

do
	-- Cached tooltip response.
	local tt
	do
		-- This returns two values. First is a string, if the MSP command
		-- requires sending a response (i.e., is a query); second is a boolean,
		-- if the MSP command provides an updated field (i.e., is a non-empty
		-- response).
		local function msp_Process(character, cmd)
			-- Original LibMSP match string uses %a%a rather than %u%u.
			-- According to protcol documentation, %u%u would be more correct.
			local action, field, version, contents = cmd:match("(%p?)(%u%u)(%d*)=?(.*)")
			local updated = false
			version = tonumber(version) or 0
			if not field then
				return nil, updated
			elseif action == "?" then
				-- Queried our fields. This should end in returning a string
				-- with our info for that field. (If it doesn't, it means we're
				-- ignoring their polite request for some reason.)
				if (xrp_versions[field] and version == xrp_versions[field]) or (not xrp_versions[field] and version == 0) then
					-- They already have the latest.
					return (not xrp_versions[field] and "%s" or "!%s%u"):format(field, xrp_versions[field]), updated
				elseif field == "TT" then
					if not tt then -- panic, something went wrong in init.
						xrp.msp:Update()
					end
					return tt, updated
				else
					if not xrp.current[field] then
						-- Field is empty.
						return (not xrp_versions[field] and "%s" or "%s%u"):format(field, xrp_versions[field]), updated
					else
						-- Field has content.
						return ("%s%u=%s"):format(field, xrp_versions[field], xrp.current[field]), updated
					end
				end
			elseif action == "!" then
				-- Told us we have latest of their field.
				tmp_cache[character].time[field] = GetTime()
			elseif action == "" then
				-- Gave us a field.
				if not xrp_cache[character] and (contents ~= "" or version ~= 0) then
					xrp_cache[character] = {
						fields = {},
						versions = {},
					}
					-- What this does is pull the G-fields from the unitcache,
					-- accessed through xrp.cache, into the actual cache, but
					-- only if the character has MSP. This keeps the saved
					-- cache a bit more lightweight.
					--
					-- The G-fields are also put into the saved cache when
					-- they're initially generated, if the cache table for that
					-- character exists (indicating MSP support is/was present
					-- -- this function is the *only* place a character cache
					-- table is created).
					for gfield, _ in pairs(xrp.msp.unitfields) do
						xrp_cache[character].fields[gfield] = xrp.cache[character][gfield]
					end
				end
				if xrp_cache[character] and xrp_cache[character].fields[field] and (not contents or contents == "") and not xrp.msp.unitfields[field] then
					-- If it's newly blank, empty it in the cache. Never empty G*.
					xrp_cache[character].fields[field] = nil
					updated = true
				elseif contents and contents ~= "" then
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
				-- querying again too soon. Query time is also set prior to
				-- initial send -- so timer will count from send OR receive as
				-- appropriate.
				tmp_cache[character].time[field] = GetTime()
			end
			return nil, updated -- No response needed.
		end

		msprun.handlers = {
			["MSP"] = function (character, msg)
				if disabled then
					return false
				end
				-- They definitely have MSP, no need to question it next time.
				tmp_cache[character].received = true
				tmp_cache[character].nextcheck = nil
				local out = {}
				local updated = false
				local fieldupdated = false
				if msg ~= "" then
					if msg:find("\1", 1, true) then
						for cmd in msg:gmatch("([^\1]+)\1*") do
							out[#out + 1], fieldupdated = msp_Process(character, cmd)
							updated = updated or fieldupdated
						end
					else
						out[#out + 1], fieldupdated = msp_Process(character, msg)
						updated = updated or fieldupdated
					end
				end
				if updated then
					-- This only fires if there's actually been any changes to
					-- field contents.
					xrp:FireEvent("MSP_RECEIVE", character)
				elseif #out == 0 then
					-- If they sent a request, out will have content.
					xrp:FireEvent("MSP_NOCHANGE", character)
				end
				if #out > 0 then
					msp_QueueSend(character, out)
				end
				-- Cache timer. Last receive marked for clearing old entries.
				if xrp_cache[character] then
					xrp_cache[character].lastreceive = time()
				end
			end,
			["MSP\1"] = function(character, msg)
				if disabled then
					return false
				end
				-- They definitely have MSP, no need to question it next time.
				tmp_cache[character].received = true
				tmp_cache[character].nextcheck = nil
				local incchunks = msg:match("XC=%d+\1")
				if incchunks then
					tmp_cache[character].totalchunks = tonumber(incchunks:match("XC=(%d+)\1"))
					-- Drop XC if present.
					msg = msg:gsub(incchunks, "")
				end
				--print(msg:gsub("\1", "\\1"))
				tmp_cache[character].chunks = 1
				-- First message = fresh buffer.
				tmp_cache[character].buffer = { msg }
				xrp:FireEvent("MSP_CHUNK", character, tmp_cache[character].chunks, tmp_cache[character].totalchunks or nil)
			end,
			["MSP\2"] = function(character, msg)
				if disabled then
					return false
				end
				if tmp_cache[character].buffer then
					tmp_cache[character].buffer[#tmp_cache[character].buffer + 1] = msg
					tmp_cache[character].chunks = tmp_cache[character].chunks + 1
					xrp:FireEvent("MSP_CHUNK", character, tmp_cache[character].chunks, tmp_cache[character].totalchunks or nil)
				end
			end,
			["MSP\3"] = function(character, msg)
				if disabled then
					return false
				end
				if tmp_cache[character].buffer then
					tmp_cache[character].buffer[#tmp_cache[character].buffer + 1] = msg
					msprun.handlers["MSP"](character, table.concat(tmp_cache[character].buffer))
					-- MSP_CHUNK after MSP_RECEIVE would fire. Makes it easier
					-- to something useful when chunks == totalchunks.
					xrp:FireEvent("MSP_CHUNK", character, tmp_cache[character].chunks + 1, tmp_cache[character].chunks + 1)

					tmp_cache[character].chunks = nil
					tmp_cache[character].totalchunks = nil
					tmp_cache[character].buffer = nil
				end
			end,
		}
	end
	do
		-- Caches a tooltip response, but *does not* modify the tooltip
		-- version.  That needs to be done, if appropriate, whenever this is
		-- called.
		local function msp_CacheTT()
			local tooltip = {}
			for field, _ in pairs(xrp.msp.ttfields) do
				if not xrp.current[field] then
					tooltip[#tooltip + 1] = (not xrp_versions[field] and "%s" or "%s%u"):format(field, xrp_versions[field])
				else
					tooltip[#tooltip + 1] = ("%s%u=%s"):format(field, xrp_versions[field], xrp.current[field])
				end
			end
			tooltip[#tooltip + 1] = ("TT%u"):format(xrp_versions.TT)
			tt = table.concat(tooltip, "\1")
			--print((tt:gsub("\1", "\\1")))
			return true
		end

		function xrp.msp:Update()
			if disabled then
				return false
			end

			local changes = false
			local ttchanges = false
			local character = xrp.toon.withrealm
			local new = xrp.current()
			local old = xrp_cache[character].fields

			for field, contents in pairs(new) do
				if old[field] ~= contents then
					changes = true
					xrp_versions[field] = (xrp_versions[field] or 0) + 1
					xrp_cache[character].fields[field] = contents
					xrp_cache[character].versions[field] = xrp_versions[field]
					ttchanges = self.ttfields[field] and true or ttchanges
				end
			end
			for field, _ in pairs(old) do
				if not new[field] then
					changes = true
					xrp_versions[field] = (xrp_versions[field] or 0) + 1
					xrp_cache[character].fields[field] = nil
					xrp_cache[character].versions[field] = xrp_versions[field]
					ttchanges = self.ttfields[field] and true or ttchanges
				end
			end
			if ttchanges then
				xrp_versions.TT = (xrp_versions.TT or 0) + 1
				xrp_cache[character].versions.TT = xrp_versions.TT
				msp_CacheTT()
			elseif not tt then
				-- If it's our character we never want the cache tidy to wipe
				-- it out.  Do this by setting the wipe timer for 2038. This
				-- should get run on the first update every session
				xrp_cache[character].lastreceive = 2147483647
				msp_CacheTT()
			end
			if changes then
				xrp:FireEvent("MSP_UPDATE")
			end
			return true
		end

		function xrp.msp:UpdateField(field)
			if disabled then
				return false
			end
			local character = xrp.toon.withrealm
			local old = xrp_cache[character].fields
			if not old[field] or old[field] ~= xrp.current[field] then
				xrp_versions[field] = (xrp_versions[field] or 0) + 1
				xrp_cache[character].fields[field] = xrp.current[field]
				xrp_cache[character].versions[field] = xrp_versions[field]
				if self.ttfields[field] then
					xrp_versions.TT = (xrp_versions.TT or 0) + 1
					xrp_cache[character].versions.TT = xrp_versions.TT
					msp_CacheTT()
				elseif not tt then
					xrp_cache[character].lastreceive = 2147483647
					msp_CacheTT()
				end
				xrp:FireEvent("MSP_UPDATE", field)
			end
			return true
		end
	end
end

if not disabled then
	for prefix, _ in pairs(msprun.handlers) do
		RegisterAddonMessagePrefix(prefix)
	end
	msprun:SetScript("OnEvent", function(self, event, prefix, message, channel, character)
		--if event == "CHAT_MSG_ADDON" then print(character..": Incoming "..(prefix:gsub("\1", "\\1"):gsub("\2", "\\2"):gsub("\3", "\\3"))) end
		-- message ~= "XD" filters dummy responses early.
		if self.handlers[prefix] and message ~= "XD" then
			--print("In: "..character..": "..message:gsub("\1", "\\1"))
			--print("Receiving from: "..character)
			self.handlers[prefix](character, message)
		end
	end)
	msprun:RegisterEvent("CHAT_MSG_ADDON")
	ChatThrottleLib.MAX_CPS = 1200 -- up from 800
	ChatThrottleLib.MIN_FPS = 15 -- down from 20
end
