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
xrp.msp:Hide() -- Prevent OnUpdate until needed.

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

-- Fields in tooltip.
xrp.msp.ttfields = { VP = true, VA = true, NA = true, NH = true, NI = true, NT = true, RA = true, FR = true, FC = true, CU = true }

-- These fields are (or should) be generated from UnitSomething() functions.
-- GF is an xrp-original, storing non-localized faction (since we cache
-- between sessions and can have data on both factions at once).
xrp.msp.unitfields = { GC = true, GF = true, GR = true, GS = true, GU = true }

-- Metadata fields, not to be user-set. XC is an xrp-original.
xrp.msp.metafields = { VA = true, VP = true, XC = true }

local tmp_cache = setmetatable({}, {
	__index = function(tmp_cache, character)
		tmp_cache[character] = {
			nogfields = true,
			nomsp = true,
			lastcheck = 0,
			time = {},
		}
		return tmp_cache[character]
	end,
})
	
local old = false
local tt = false
local tttable = { "TT" }

local queue = {}
local queuepos = 1
local queueend = 0

-- TODO: Merge into send()? Maybe not, if CTL is present...
local function queuemessage(prefix, message, character)
	queueend = queueend + 1
	queue[queueend] = { prefix, message, character }
	xrp.msp:Show() -- Will fire on next frame draw (i.e., essentially instantly).
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
			tooltip[#tooltip + 1] = format("%s%u", field, xrp_versions[field])
		else
			tooltip[#tooltip + 1] = format("%s%u=%s", field, xrp_versions[field], xrp.profile[field])
		end
	end
	tooltip[#tooltip + 1] = format("TT%u", xrp_versions.TT)
	tt = table.concat(tooltip, "\1")
	--print((tt:gsub("\1", "\\1")))
	return true
end

local function send(character, data)
	if type(data) == "table" then
		data = table.concat(data, "\1")
	end
	--print(character..": "..data:gsub("\1", "\\1"))
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
		if (xrp_versions[field] and version == xrp_versions[field]) or (not xrp_versions[field] and version == 0) then
			-- They already have the latest.
			return format("!%s%u", field, xrp_versions[field] or 0), updated
		elseif field == "TT" then
			if not tt then -- panic, something went wrong in init.
				-- TODO: Debug output.
				return nil, updated
			end
			return tt, updated
		else
			if not xrp.profile[field] then
				-- Field is empty.
				return format("%s%u", field, xrp_versions[field] or 0), updated
			else
				-- Field has content.
				return format("%s%u=%s", field, xrp_versions[field], xrp.profile[field]), updated
			end
		end
	elseif action == "!" then
		-- Told us we have latest of their field.
		if xrp_cache[character].fields[field] then
			tmp_cache[character].time[field] = GetTime()
		end
	elseif action == "" then
		-- Gave us a field.
		if not xrp_cache[character] and ((contents and contents ~= "") or (version ~= 0)) then
			xrp_cache[character] = {
				fields = {},
				versions = {},
			}
			-- What this does is pull the G-fields from the unitcache,
			-- accessed through xrp.characters, into the actual cache, but
			-- only if the character has MSP. This keeps the saved cache a
			-- bit more lightweight. These are queries automatically by our
			-- first request to them, so it should either copy the fields
			-- from the unitcache or just get what they're already set to.
			--
			-- The G-fields are also put into the saved cache when they're
			-- initially generated, if the cache table for that character
			-- exists (indicating MSP support is/was present -- this function
			-- is the *only* place a character cache table is created).
			for gfield, _ in pairs(xrp.msp.unitfields) do
				xrp_cache[character].fields[gfield] = xrp.characters[character][gfield]
			end
		end
		if xrp_cache[character].fields[field] and (not contents or contents == "") and not xrp.msp.unitfields[field] then
			-- If it's newly blank, empty it in the cache. Never empty G*.
			xrp_cache[character].fields[field] = nil
			updated = true
		elseif contents and contents ~= "" then
			xrp_cache[character].fields[field] = contents
			updated = true
		end
		if version ~= 0 then
			xrp_cache[character].versions[field] = version
		else
			xrp_cache[character].versions[field] = nil
		end
		-- Save time regardless of contents or version. This prevents querying
		-- again too soon.
		tmp_cache[character].time[field] = GetTime()
	end
	return nil, updated -- No response needed.
end

xrp.msp.handlers = {
	["MSP"] = function (character, msg)
		if disabled then
			return false
		end
--[[		if not tmp_cache[character] then
			tmp_cache[character] = {
				nogfields = true,
				time = {},
			}
		else]]
		-- They definitely have MSP, no need to question it next time.
		tmp_cache[character].nomsp = nil
		tmp_cache[character].lastcheck = nil
--		end
		local out = {}
		local updated = false
		local fieldupdated = false
		if msg ~= "" then
			if msg:find("\1", 1, true) then
				for cmd in msg:gmatch("([^\1]+)\1*") do
					out[#out + 1], fieldupdated = process(character, cmd)
					updated = updated or fieldupdated
				end
			else
				out[#out + 1], fieldupdated = process(character, msg)
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
		if disabled then
			return false
		end
--[[		if not tmp_cache[character] then
			tmp_cache[character] = {
				nogfields = true,
				time = {},
			}
		else]]
			-- They definitely have MSP, no need to question it next time.
		tmp_cache[character].nomsp = nil
		tmp_cache[character].lastcheck = nil
--		end
		local incchunks = (msg:match("XC=%d+\1"))
		if type(incchunks) == "string" then
			tmp_cache[character].totalchunks = tonumber((incchunks:gsub("XC=(%d+)\1", "%1")))
			-- Drop XC if present.
			msg = msg:gsub(incchunks, "")
		end
		tmp_cache[character].chunks = 1
		-- First message = fresh buffer.
		tmp_cache[character].buffer = { msg }
		--print(msg:gsub("\1", "\\1"))
		xrp:FireEvent("MSP_RECEIVE_CHUNK", character, tmp_cache[character].chunks, tmp_cache[character].totalchunks or nil)
	end,
	["MSP\2"] = function(character, msg)
		if disabled then
			return false
		end
		if tmp_cache[character].buffer then
			tmp_cache[character].buffer[#tmp_cache[character].buffer + 1] = msg
			tmp_cache[character].chunks = tmp_cache[character].chunks + 1
			xrp:FireEvent("MSP_RECEIVE_CHUNK", character, tmp_cache[character].chunks, tmp_cache[character].totalchunks or nil)
		else
			--TODO: Raise a warning about no first message.
		end
	end,
	["MSP\3"] = function(character, msg)
		if disabled then
			return false
		end
		if tmp_cache[character].buffer then
			tmp_cache[character].buffer[#tmp_cache[character].buffer + 1] = msg
			xrp.msp.handlers["MSP"](character, table.concat(tmp_cache[character].buffer))

			-- Fire MSP_RECIEVE_CHUNK even after MSP_UPDATE may be fired by
			-- the processing -- the processing does not necessarily fire
			-- MSP_UPDATE if there's no, well, updates. This allows anything
			-- doing something interesting with the chunk numbers to know that
			-- it's finished, even if they didn't get an update.
			xrp:FireEvent("MSP_RECEIVE_CHUNK", character, tmp_cache[character].chunks + 1, tmp_cache[character].chunks + 1)

			tmp_cache[character].chunks = nil
			tmp_cache[character].totalchunks = nil
			tmp_cache[character].buffer = nil
		else
			--TODO: Raise a warning about no first message.
		end
	end,
}

local requestqueue = {}
function xrp.msp:QueueRequest(character, field)
	if character == xrp.toon.withrealm then
		return
	end
	local append = true
	if not requestqueue[character] then
		requestqueue[character] = {}
	else
		for _, reqfield in pairs(requestqueue[character]) do
			if append and reqfield == field then
				append = false
			end
		end
	end
	if append then
		--print(character..": "..field)
		requestqueue[character][#requestqueue[character] + 1] = field
		xrp.msp:Show()
	end
end

local refreshtime = 30
function xrp.msp:Request(character, fields)
	if disabled or not character or xrp:NameWithoutRealm(character) == UNKNOWN or character == xrp.toon.withrealm then
		return false
	end

	local now = GetTime()
	if tmp_cache[character].nomsp and now < (tmp_cache[character].lastcheck + 300) then
		return false
	elseif tmp_cache[character].nomsp then
		tmp_cache[character].lastcheck = now
	end
--[[	elseif not tmp_cache[character] then
		tmp_cache[character] = {
			nogfields = true,
			nomsp = true,
			lastcheck = now,
			time = {},
		}
	end]]

	if not fields or fields == "TT" then
		fields = tttable
	elseif type(fields) == "string" then
		fields = { fields }
	elseif type(fields) == "table" then
		-- No need to strip repeated fields -- the logic below for not querying
		-- fields too quickly in succession will handle that for us.
		local reqtt = false
		for key = #fields, 1, -1 do -- Backwards... Or else it breaks. BADLY.
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

	-- nogfields = true if we've not sent a request to them yet. Doing this
	-- automatically prevents us from sometimes sending another request later
	-- when we receive a probe from them.
	if tmp_cache[character].nogfields then
		for field, _ in pairs(xrp.msp.unitfields) do
			fields[#fields + 1] = field
		end
		tmp_cache[character].nogfields = nil
	end

	local out = {}
	for _, field in ipairs(fields) do
		if not xrp_cache[character] or not tmp_cache[character].time[field] or now > tmp_cache[character].time[field] + refreshtime then
			out[#out + 1] = format("?%s%u", field, (xrp_cache[character] and xrp_cache[character].versions[field]) or 0)
			tmp_cache[character].time[field] = now
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
				ttchanges = self.ttfields[field] and true or ttchanges
			end
		end
		for field, _ in pairs(old) do
			if not new[field] then
				changes = true
				xrp_versions[field] = xrp_versions[field] + 1
				xrp_cache[xrp.toon.withrealm].fields[field] = nil
				xrp_cache[xrp.toon.withrealm].versions[field] = xrp_versions[field]
				ttchanges = self.ttfields[field] and true or ttchanges
			end
		end
	else
		-- First initialization. Check for updates to unitfields (race change,
		-- sex change, etc.) and metafields (protocol version, addon version,
		-- etc.). We need to get these right for other xrp users (and anyone
		-- else who starts caching.
		for field, _ in pairs(xrp.msp.unitfields) do
			xrp_versions[field] = new[field] ~= xrp_cache[xrp.toon.withrealm].fields[field] and ((xrp_versions[field] or 0) + 1) or (xrp_versions[field] or 1)
		end
		for field, _ in pairs(xrp.msp.metafields) do
			xrp_versions[field] = new[field] ~= xrp_cache[xrp.toon.withrealm].fields[field] and ((xrp_versions[field] or 0) + 1) or (xrp_versions[field] or 1)
		end
		wipe(xrp_cache[xrp.toon.withrealm].fields)
		wipe(xrp_cache[xrp.toon.withrealm].versions)
		for field, contents in pairs(new) do
			xrp_cache[xrp.toon.withrealm].fields[field] = contents
		end
		for field, version in pairs(xrp_versions) do
			xrp_cache[xrp.toon.withrealm].versions[field] = version
		end
		-- First run, build the tooltip (but don't change its version!).
		cachett()
		changes = true
	end
	old = new
	if ttchanges then
		xrp_versions.TT = (xrp_versions.TT or 0) + 1
		xrp_cache[xrp.toon.withrealm].versions.TT = xrp_versions.TT
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
			if self.ttfields[field] then
				xrp_versions.TT = (xrp_versions.TT or 0) + 1
				xrp_cache[xrp.toon.withrealm].versions.TT = xrp_versions.TT
				cachett()
			end
			xrp:FireEvent("MSP_UPDATE", field)
		end
	else -- First run is a single field update. Shouldn't happen, run full.
		self:Update()
	end
	return true
end

local lastburst = GetTime()
local nextsend = lastburst + 1.00
local function xrp_msp_OnUpdate(self, elapsed)
	if next(requestqueue) then
		for character, fields in pairs(requestqueue) do
			--print(character..": "..fields)
			self:Request(character, fields)
			requestqueue[character] = nil
		end
	end
	local now = GetTime()
	if nextsend < now and queue[queuepos] then
		local out = 0
		if lastburst + 3 < now then
			out = out - 300
		elseif lastburst + 13 < now then
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
	end
	if queuepos > queueend then
		self:Hide()
	end
end
xrp.msp:SetScript("OnUpdate", xrp_msp_OnUpdate)

local function xrp_msp_OnEvent(self, event, prefix, message, channel, character)
	if event == "CHAT_MSG_ADDON" and self.handlers[prefix] then
		--print(character..": "..message:gsub("\1", "\\1"))
		--print("Receiving from: "..character)
		self.handlers[prefix](character, message)
	elseif event == "ADDON_LOADED" and prefix == "xrp" then
		for prefix, _ in pairs(self.handlers) do
			RegisterAddonMessagePrefix(prefix)
		end
		self:UnregisterEvent("ADDON_LOADED")
		self:RegisterEvent("CHAT_MSG_ADDON")
		self:RegisterEvent("PLAYER_LOGOUT")
	elseif event == "PLAYER_LOGOUT" then
		xrp:Logout() -- Defined in profiles.lua.
	end
end
xrp.msp:SetScript("OnEvent", xrp_msp_OnEvent)
xrp.msp:RegisterEvent("ADDON_LOADED")