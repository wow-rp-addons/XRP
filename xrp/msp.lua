--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this program.  If not, see
	<http://www.gnu.org/licenses/>.
]]

-- Needs an OnUpdate script to itself. Also handles CHAT_MSG_ADDON events.
xrp.msp = CreateFrame("Frame", nil, xrp)

-- Start out hidden to not pointlessly fire OnUpdate.
xrp.msp:Hide()

-- xrp uses some new fields, but the protocol is v1.
xrp.msp.protocol = 1

-- Claim MSP rights ASAP to try heading off other addons. Since we start with
-- "x", this probably won't help much if WoW loads in alphabetical order.
local disabled = false
if not msp_RPAddOn then
	msp_RPAddOn = GetAddOnMetadata("xrp", "Title")
else
	disabled = true
end

-- Needs to be global to use in profiles.lua (for TT version on logout).
-- TODO: Consider moving this into msp.lua by comparing xrp.profile with
-- xrp.profiles[xrp_selectedprofile].
xrp.msp.ttfields = { VP = true, VA = true, NA = true, NH = true, NI = true, NT = true, RA = true, FR = true, FC = true, CU = true }

-- These fields are (or should) be generated from UnitSomething() functions.
-- GF is an xrp-original, storing non-localized faction (since we cache
-- between sessions and can have data on both factions at once).
local unitfields = { GC, GF, GR, GS, GU }

local cache = {}
local buffers = {}
local old = false
local tt = false

local requestqueue = {}

local queue = {}
local queuepos = 1
local queueend = 0
local nextsend = GetTime() + 0.50
local lastburst = GetTime()

local function queuemessage(prefix, message, character)
	queueend = queueend + 1
	queue[queueend] = { prefix, message, character }
	xrp.msp:Show() -- Will fire on next frame draw (i.e., instantly).
end

local function xrp_msp_OnUpdate(self, elapsed)
	if next(requestqueue) then
		local reqtt = false
		for character, fields in pairs(requestqueue) do
			for key, field in ipairs(fields) do
				if field == "TT" then
					fields[key] = nil
					reqtt = true
				elseif xrp.msp.ttfields[field] then
					fields[key] = nil
					reqtt = true
				end
			end
			if reqtt then
				fields[#fields+1] = "TT"
			end
			xrp.msp:Request(character, fields)
			requestqueue[character] = nil
		end
	end
	local now = GetTime()
	if nextsend < now and queue[queuepos] then
		local out = 0
		if lastburst + 3 > now then
			out = out - 300
		elseif lastburst + 13 > now then
			out = out - 300
			lastburst = now
		end
		while (out < 300 and queuepos <= queueend) do
			SendAddonMessage(queue[queuepos][1], queue[queuepos][2], "WHISPER", queue[queuepos][3])
			--print("SendAddonMessage(\""..queue[queuepos][1]:gsub("\1", "\\1"):gsub("\2", "\\2"):gsub("\3", "\\3").."\", \""..queue[queuepos][2]:gsub("\1", "\\1").."\", \"WHISPER\", \""..queue[queuepos][3].."\")")
			--print("Sending to: "..queue[queuepos][3])
			out = out + #queue[queuepos][2] + 32
			queue[queuepos] = nil
			queuepos = queuepos + 1
		end
		nextsend = now + 0.25
--[[		if queuepos > queueend then
			xrp.msp:Hide()
		end]]
	end
	if queuepos > queueend then
		xrp.msp:Hide()
	end
end

-- Caches a tooltip response, but *does not* modify the tooltip version.
-- That needs to be done, if appropriate, whenever this is called. (For
-- example, it is *not* done on the first run, as versions for the next
-- session are updated on PLAYER_LOGOUT rather than always incrementing by
-- one.)
local function cachett()
	local tooltip = {}
	for field, _ in pairs(xrp.msp.ttfields) do
		if not xrp.profile[field] then
			tooltip[#tooltip+1] = format("%s%u", field, xrp_versions[field])
		else
			tooltip[#tooltip+1] = format("%s%u=%s", field, xrp_versions[field], xrp.profile[field])
		end
	end
	tooltip[#tooltip+1] = format("TT%u", xrp_versions.TT)
	tt = table.concat(tooltip, "\1")
	--print((tt:gsub("\1", "\\1")))
	return true
end

-- This returns TWO values. First is a string, if the MSP command requires
-- sending a response (i.e., is a query); second is a boolean, if the MSP
-- command provides an updated field (i.e., is a non-empty response).
local function process(character, cmd)
	-- Original LibMSP match string uses %a%a rather than %u%u. According to
	-- protcol documentation, %u%u would be more correct.
	local action, field, version, contents = cmd:match("(%p?)(%u%u)(%d*)=?(.*)")
	local updated = false
	version = tonumber(version) or 0
	if not field then
		return nil, updated
	elseif action == "?" then
		-- Queried our fields. This should end in returning a string with our
		-- info for that field. (If it doesn't, it means we're ignoring their
		-- polite request for some reason.)
		if version ~= 0 and xrp_versions[field] and version ~= xrp_versions[field] then
			return format("!%s%u", field, xrp_versions[field] or 0), updated
		elseif field == "TT" then
			if not tt then
				cachett()
			end
			return tt, updated
		else
			if not xrp.profile[field] then
				return format("%s%u", field, xrp_versions[field] or 0), updated
			else
				return format("%s%u=%s", field, xrp_versions[field], xrp.profile[field]), updated
			end
		end
	elseif action == "!" then
		-- Told us we have latest of their field.
		if xrp_cache[character].fields[field] then
			xrp_cache[character].time[field] = time()
		end
	elseif action == "" then
		-- Gave an actual response.
		if not xrp_cache[character] and version ~= 0 then
			xrp_cache[character] = {
				fields = {},
				time = {},
				versions = {},
			}
			-- What this does is pull the G-fields from the unitcache,
			-- accessed through xrp.characters, into the actual cache, but
			-- only if the character has MSP. This keeps the saved cache a
			-- bit more lightweight.
			--
			-- The G-fields are also put into the saved cache when they're
			-- initially generated, if the cache table for that character
			-- exists (indicating MSP support is/was present -- this function
			-- is the *only* place a character cache table is created).
			for _, gfield in pairs(unitfields) do
				xrp_cache[character].fields[gfield] = xrp.characters[character][gfield]
				xrp_cache[character].time[gfield] = character == xrp.toon.withrealm and 2147483647 or 0
				xrp_cache[character].versions[gfield] = 0
			end
		end
		if xrp_cache[character].fields[field] and (not contents or contents == "") then
			-- If it's newly blank, empty it in the cache.
			xrp_cache[character].fields[field] = nil
			updated = true
		elseif contents and contents ~= "" then
			xrp_cache[character].fields[field] = contents
			updated = true
		end
		-- Save version and time regardless of contents (even if empty). This
		-- should be done even if version == 0 (meaning the other side
		-- considers the field non-existant) so we don't query it again too
		-- soon.
		xrp_cache[character].time[field] = time()
		xrp_cache[character].versions[field] = version
	end
	return nil, updated -- No response needed.
end

local function send(character, data)
	if disabled then
		return false
	end
	if type(data) == "table" then
		data = table.concat(data, "\1")
	end
	if data and type(data) == "string" and data ~= "" then
		if #data <= 255 then
			queuemessage("MSP", data, character)
		else
			-- XC is most likely to add five or six extra characters, will not
			-- add less than five, and only adds seven or more if the profile
			-- is over 25000 characters or so. So let's say six.
			data = format("XC=%u\1%s", math.ceil((#data + 6) / 255), data)
			local position = 1
			queuemessage("MSP\1", data:sub(position, position + 254), character)
			position = position + 255
			while position + 255 <= #data do
				queuemessage("MSP\2", data:sub(position, position + 254), character)
				position = position + 255
			end
			queuemessage("MSP\3", data:sub(position), character)
		end
		return true
	end
	return false
end

xrp.msp.handlers = {
	["MSP"] = function (character, msg)
		if not cache[character] then
			cache[character] = {}
		else
			cache[character].nomsp = nil
			cache[character].lastcheck = nil
		end
		local out = {}
		local updated = false
		local fieldupdated = false
		if msg ~= "" then
			if msg:find("\1", 1, true) then
				for cmd in msg:gmatch("([^\1]+)\1*") do
					out[#out+1], fieldupdated = process(character, cmd)
					updated = updated or fieldupdated
				end
			else
				out[#out+1], fieldupdated = process(character, msg)
				updated = updated or fieldupdated
			end
		end
		if updated then
			-- This only fires if there's actually been any changes to field
			-- contents.
			xrp:FireEvent("MSP_RECEIVE", character)
		end
		if #out > 0 then
			send(character, out)
		end
	end,
	["MSP\1"] = function(character, msg)
		if not cache[character] then
			cache[character] = {}
		end
		local incchunks = (msg:match("XC=%d+\1"))
		if type(incchunks) == "string" then
			cache[character].totalchunks = tonumber(incchunks:gsub("XC=(%d+)\1", "%1"))
			-- Drop XC if present.
			msg = msg:gsub(incchunks, "")
		end
		cache[character].chunks = 1
		-- First message = fresh buffer.
		buffers[character] = { msg }
--		print(msg:gsub("\1", "\\1"))
		xrp:FireEvent("MSP_RECEIVE_CHUNK", character, cache[character].chunks, cache[character].totalchunks or nil)
	end,
	["MSP\2"] = function(character, msg)
		if buffers[character] then
			buffers[character][#buffers[character]+1] = msg
			cache[character].chunks = cache[character].chunks + 1
			xrp:FireEvent("MSP_RECEIVE_CHUNK", character, cache[character].chunks, cache[character].totalchunks or nil)
		else
			--TODO: Raise a warning about no first message.
		end
	end,
	["MSP\3"] = function(character, msg)
		if buffers[character] then
			buffers[character][#buffers[character]+1] = msg
			xrp.msp.handlers["MSP"](character, table.concat(buffers[character]))

			-- Fire MSP_RECIEVE_CHUNK even after MSP_UPDATE may be fired by
			-- the processing -- the processing does not necessarily fire
			-- MSP_UPDATE if there's no, well, updates. This allows anything
			-- doing something interesting with the chunk numbers to know that
			-- it's finished, even if they didn't get an update.
			xrp:FireEvent("MSP_RECEIVE_CHUNK", character, cache[character].chunks + 1, cache[character].chunks + 1)

			cache[character].chunks = nil
			cache[character].totalchunks = nil
			buffers[character] = nil
		else
			--TODO: Raise a warning about no first message.
		end
	end,
}

function xrp.msp:QueueRequest(character, field)
	if character == xrp.toon.withrealm then
		return
	end
	if not requestqueue then
		requestqueue = {
			[character] = {}
		}
	elseif not requestqueue[character] then
		requestqueue[character] = {}
	end
	requestqueue[character][#requestqueue[character]+1] = field
	xrp.msp:Show()
end

function xrp.msp:Request(character, fields)
	if disabled or xrp:NameWithoutRealm(character) == UNKNOWN or character == xrp.toon.withrealm then
		return false
	end

	local now = time()
	if cache[character] and cache[character].nomsp and now < (cache[character].lastcheck + 300) then
		return false
	elseif cache[character] and cache[character].nomsp then
		cache[character].lastcheck = now
	elseif not cache[character] then
		cache[character] = {
			nomsp = true,
			lastcheck = now,
		}
	end
	-- TODO: Strip time out of xrp_cache
	if not cache[character].time then
		cache[character].time = {}
	end
	-- TODO: Filter tooltip fields, replace with TT?
	if not fields then
		fields = { "TT" }
	elseif type(fields) == "string" then
		fields = { fields }
	end
	if type(fields) ~= "table" then
		return false
	end

	local out = {}
	for _, field in ipairs(fields) do
		if not xrp_cache[character] or (not xrp_cache[character].time[field] or not cache[character].time[field]) or ((now > xrp_cache[character].time[field] + 30) and (now > cache[character].time[field] + 30)) then
			out[#out+1] = format("?%s%u", field, (xrp_cache[character] and xrp_cache[character].versions[field]) or 0)
			cache[character].time[field] = now
		end
	end
	if #out > 0 then
		send(character, out)
		return true
	end
	return false
end

function xrp.msp:Update()
	if disabled then
		return false
	end

	local changes = false
	local ttchanges = false
	local new = xrp.profile()
	-- If not old, then its first run and versions can be kept as they stand.
	-- Version updates for overridden fields are handled in PLAYER_LOGOUT so
	-- we can save a bunch of bandwidth on rarely-changing fields.
	if old then
		for field, contents in pairs(new) do
			if old[field] ~= contents then
				changes = true
				xrp_versions[field] = (xrp_versions[field] or 0) + 1
				xrp_cache[xrp.toon.withrealm].fields[field] = contents
				xrp_cache[xrp.toon.withrealm].versions[field] = xrp_versions[field]
				xrp_cache[xrp.toon.withrealm].time[field] = 2147483647
				if not ttchanges and self.ttfields[field] then
					ttchanges = true
				end
			end
		end
		for field, _ in pairs(old) do
			if not new[field] then
				changes = true
				xrp_versions[field] = xrp_versions[field] + 1
				xrp_cache[xrp.toon.withrealm].fields[field] = nil
				xrp_cache[xrp.toon.withrealm].versions[field] = xrp_versions[field]
				xrp_cache[xrp.toon.withrealm].time[field] = 2147483647
				if not ttchanges and self.ttfields[field] then
					ttchanges = true
				end
			end
		end
	else
		for field, contents in pairs(new) do
			xrp_cache[xrp.toon.withrealm].fields[field] = contents
			xrp_cache[xrp.toon.withrealm].versions[field] = xrp_versions[field]
			xrp_cache[xrp.toon.withrealm].time[field] = 2147483647
		end
		xrp_cache[xrp.toon.withrealm].versions.TT = xrp_versions.TT
		xrp_cache[xrp.toon.withrealm].time.TT = 2147483647
		-- First run, build the tooltip (but don't change its version!).
		cachett()
		changes = true
	end
	old = new
	if ttchanges then
		xrp_versions.TT = (xrp_versions.TT or 0) + 1
		xrp_cache[xrp.toon.withrealm].versions.TT = xrp_versions.TT
		xrp_cache[xrp.toon.withrealm].time.TT = 2147483647
		cachett()
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
	if old then
		if not old[field] or old[field] ~= xrp.profile[field] then
			xrp_versions[field] = (xrp_versions[field] or 0) + 1
			old[field] = xrp.profile[field]
			xrp_cache[xrp.toon.withrealm].fields[field] = old[field]
			xrp_cache[xrp.toon.withrealm].versions[field] = xrp_versions[field]
			xrp_cache[xrp.toon.withrealm].time[field] = 2147483647
			if self.ttfields[field] then
				xrp_versions.TT = (xrp_versions.TT or 0) + 1
				xrp_cache[xrp.toon.withrealm].versions.TT = xrp_versions.TT
				xrp_cache[xrp.toon.withrealm].time.TT = 2147483647
				cachett()
			end
			xrp:FireEvent("MSP_UPDATE", field)
		end
	else -- First run is a single field update? Shouldn't happen.
		-- TODO: Add warning output.
		-- First run, cache the tooltip.
		cachett()
		old = xrp.profile()
		xrp:FireEvent("MSP_UPDATE")
	end
	return true
end

xrp.msp:SetScript("OnUpdate", xrp_msp_OnUpdate)

xrp.msp:SetScript("OnEvent", function(self, event, prefix, message, channel, character)
	if event == "CHAT_MSG_ADDON" and xrp.msp.handlers[prefix] then
		--print(character..": "..message:gsub("\1", "\\1"))
		--print("Receiving from: "..character)
		xrp.msp.handlers[prefix](character, message)
	elseif event == "ADDON_LOADED" and prefix == "xrp" then
		for prefix, _ in pairs(xrp.msp.handlers) do
			RegisterAddonMessagePrefix(prefix)
		end
		self:RegisterEvent("CHAT_MSG_ADDON")
		self:RegisterEvent("PLAYER_LOGOUT")
	elseif event == "PLAYER_LOGOUT" then
		xrp:Logout() -- Defined in profiles.lua.
	end
end)
xrp.msp:RegisterEvent("ADDON_LOADED")
