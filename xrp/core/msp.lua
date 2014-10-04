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
		text = xrp.L["You are running another RP profile addon (\"%s\"). XRP's support for sending and receiving profiles is disabled; to enable it, disable \"%s\" and reload your UI."],
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
-- Requested field queue
msp.request = {}
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
				local offline = not (xrp.cache[character].GF and xrp.cache[character].GF ~= xrpSaved.meta.fields.GF)
				-- 30 second timer between checks for offline characters. Try
				-- to not query offline characters higher up the chain as well,
				-- remember.
				if msp.cache[character].nextcheck and offline then
					msp.cache[character].nextcheck = now + 30
				end
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
end

function msp:OnUpdate(elapsed)
	-- This exhausts itself every time it's run. One and done.
	if next(self.request) then
		for character, fields in pairs(self.request) do
			--print(character..": "..fields)
			xrp:Request(character, fields)
			self.request[character] = nil
		end
	end
	self:Hide()
end
msp:Hide()
msp:SetScript("OnUpdate", msp.OnUpdate)

do
	-- This sets the field order to a xrp_viewer-ideal incoming order.
	local ttfields = { "VP", "VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", "FR", "FC" }
	local tt, oldtt
	function msp:GetTT()
		if not tt then
			if not oldtt and xrpSaved.oldtt then
				oldtt = xrpSaved.oldtt
				xrpSaved.oldtt = nil
			end
			local current = xrp.current
			local tooltip = {}
			for _, field in ipairs(ttfields) do
				tooltip[#tooltip + 1] = (not current.fields[field] and "%s" or "%s%u=%s"):format(field, current.versions[field], current.fields[field])
			end
			local newtt = table.concat(tooltip, "\1")
			tt = ("%s\1TT%u"):format(newtt, newtt ~= oldtt and xrp:NewVersion("TT") or xrpSaved.versions.TT)
			oldtt = newtt
		end
		--print((tt:gsub("\1", "\\1")))
		return tt
	end
	xrp:HookEvent("FIELD_UPDATE", function(field)
		if tt and (not field or xrp.fields.tt[field]) then
			tt = nil
		end
	end)
	xrp:HookLogout(function()
		xrpSaved.oldtt = oldtt
	end)
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
			if version == xrp.current.versions[field] or (not xrp.current.versions[field] and version == 0) then
				-- They already have the latest.
				return (not xrp.current.versions[field] and "%s" or "!%s%u"):format(field, xrp.current.versions[field])
			elseif field == "TT" then
				return self:GetTT()
			elseif not xrp.current.fields[field] then
				-- Field is empty.
				return field
			end
			-- Field has content.
			return ("%s%u=%s"):format(field, xrp.current.versions[field], xrp.current.fields[field])
		elseif action == "!" then
			-- Told us we have latest of their field.
			self.cache[character].time[field] = GetTime()
			self.cache[character].fieldupdated = self.cache[character].fieldupdated or false
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
				for gfield, _ in pairs(xrp.fields.unit) do
					xrpCache[character].fields[gfield] = xrp.cache[character][gfield]
				end
			end
			local updated = false
			if xrpCache[character] and xrpCache[character].fields[field] and contents == "" and not xrp.fields.unit[field] then
				-- If it's newly blank, empty it in the cache. Never
				-- empty G*, but do update them (following elseif).
				xrpCache[character].fields[field] = nil
				updated = true
			elseif contents ~= "" and xrpCache[character].fields[field] ~= contents then
				xrpCache[character].fields[field] = contents
				updated = true
				if field == "VA" then
					xrp:AddonUpdate(contents:match("^XRP/([^;]+)"))
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
			self:Send(character, out)
		end
		-- Cache timer. Last receive marked for clearing old entries.
		if xrpCache[character] then
			xrpCache[character].lastreceive = time()
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

			self.cache[character].received = true
			self.cache[character].nextcheck = nil

			self.handlers[prefix](self, character, message)
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
	dummy = { XC = true },
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

function xrp:QueueRequest(character, field)
	if disabled or character == self.toon or self:NameWithoutRealm(character) == UNKNOWN then return false end

	if not msp.request[character] then
		msp.request[character] = {}
	end

	msp.request[character][#msp.request[character] + 1] = field
	msp:Show()

	return true
end

function xrp:Request(character, fields)
	if disabled or character == self.toon or self:NameWithoutRealm(character) == UNKNOWN then return false end

	local now = GetTime()
	if not msp.cache[character].received and now < msp.cache[character].nextcheck then
		self:FireEvent("MSP_FAIL", character, "nomsp")
		return false
	elseif not msp.cache[character].received then
		msp.cache[character].nextcheck = now + 300
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
			out[#out + 1] = ((not xrpCache[character] or not xrpCache[character].versions[field]) and "?%s" or "?%s%u"):format(field, xrpCache[character] and xrpCache[character].versions[field] or 0)
			msp.cache[character].time[field] = now
		end
	end
	if #out > 0 then
		--print(character..": "..table.concat(out, " "))
		msp:Send(character, out)
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
