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

local FOLDER, _xrp = ...

local disabled = false
if not msp_RPAddOn then
	msp_RPAddOn = FOLDER
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

-- These fields are (or should) be generated from UnitSomething() functions.
local UNIT_FIELDS = { "GC", "GF", "GR", "GS", "GU" }

xrp.HookEvent("UPDATE", function(event, field)
	if field then
		msp.my[field] = xrp.current[field]
	else
		local fields = {}
		local profiles, inherit = { xrpSaved.profiles[xrpSaved.selected] }, xrpSaved.profiles[xrpSaved.selected].parent
		for i = 1, _xrp.PROFILE_MAX_DEPTH do
			if not xrpSaved.profiles[inherit] then
				break
			end
			profiles[#profiles + 1] = xrpSaved.profiles[inherit]
			inherit = xrpSaved.profiles[inherit].parent
		end
		for i = #profiles, 1, -1 do
			local profile = profiles[i]
			for field, doInherit in pairs(profile.inherits) do
				if doInherit == false then
					fields[field] = nil
				end
			end
			for field, contents in pairs(profile.fields) do
				if not fields[field] then
					fields[field] = contents
				end
			end
		end
		for field, contents in pairs(xrpSaved.meta.fields) do
			if not fields[field] then
				fields[field] = contents
			end
		end
		for field, contents in pairs(xrpSaved.overrides.fields) do
			if contents == "" then
				fields[field] = nil
			else
				fields[field] = contents
			end
		end
		if fields.AW then
			fields.AW = xrp.Weight(fields.AW, "msp")
		end
		if fields.AH then
			fields.AH = xrp.Height(fields.AH, "msp")
		end
		for field, contents in pairs(fields) do
			msp.my[field] = contents
		end
	end
	msp:Update()
end)

local function StatusHandler(name, reason, msgID, msgTotal)
	if reason == "ERROR" then
		-- Same error message from offline and from opposite faction.
		local GF = _xrp.unitCache[name] and _xrp.unitCache[name].GF or xrpCache[name] and xrpCache[name].fields.GF
		_xrp.FireEvent("FAIL", name, (not GF or GF == xrp.current.GF) and "offline" or "faction")
	elseif reason == "MESSAGE" then
		_xrp.FireEvent("CHUNK", name, msgID, msgTotal)
	end
end

msp.callback.status[#msp.callback.status + 1] = StatusHandler

msp:AddFieldsToTooltip("RC")

local function UpdatedHandler(name, field, contents)
	if not xrpCache[name] and (contents ~= "" or version ~= 0) then
		-- This is the only place a cache table is created by XRP.
		xrpCache[name] = {
			fields = {},
			lastReceive = time(),
			own = _xrp.own[name],
		}
		if _xrp.unitCache[name] then
			for i, unitField in pairs(UNIT_FIELDS) do
				xrpCache[name].fields[unitField] = _xrp.unitCache[name][unitField]
			end
		end
	end
	if field == "VA" then
		_xrp.AddonUpdate(contents:match("^XRP/([^;]+)"))
	end
	xrpCache[name].fields[field] = contents
	_xrp.FireEvent("FIELD", name, field)
end

msp.callback.updated[#msp.callback.updated + 1] = UpdatedHandler

local TT_REQ = { "?TT" }
local function ReceivedHandler(name)
	_xrp.FireEvent("RECEIVE", name)
	--_xrp.FireEvent("NOCHANGE", name)
	if xrpCache[name] then
		-- Cache timer. Last receive marked for clearing old entries.
		xrpCache[name].lastReceive = time()
	end
end

local gameEvents = {}

--TODO: Add Battlenet friends updating.
function gameEvents.FRIENDLIST_UPDATE(event)
	if not friends then return end
	table.wipe(friends)
	for i = 1, select(2, GetNumFriends()) do
		friends[xrp.FullName((GetFriendInfo(i)))] = true
	end
end

local function UpdateGuildRoster()
	local showOffline = GetGuildRosterShowOffline()
	table.wipe(guildies)
	if showOffline then
		for i = 1, GetNumGuildMembers() do
			local name, rank, rankIndex, level, class, zone, note, officerNote, online = GetGuildRosterInfo(i)
			if online then
				guildies[xrp.FullName(name)] = true
			end
		end
	else
		for i = 1, select(2, GetNumGuildMembers()) do
			guildies[xrp.FullName((GetGuildRosterInfo(i)))] = true
		end
	end
end

function gameEvents.GUILD_ROSTER_UPDATE(event)
	if not guildies then return end
	-- Workaround for ugly issue with the show offline tickbox on the guild
	-- roster UI.
	C_Timer.After(0, UpdateGuildRoster)
end

local request, requestQueued = {}
local function RunRequestQueue()
	for name, fields in pairs(request) do
		_xrp.Request(name, fields)
		request[name] = nil
	end
	requestQueued = nil
end

function _xrp.QueueRequest(name, field)
	if disabled or name == _xrp.playerWithRealm or friends and not (friends[name] or guildies and guildies[name]) or xrp.ShortName(name) == UNKNOWN then
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

-- Using GU+GF alone would be great, but it's not reliable.
local UNIT_REQUEST = { "GC", "GF", "GR", "GS", "GU" }
function _xrp.Request(name, fields)
	if disabled or name == _xrp.playerWithRealm or friends and not (friends[name] or guildies and guildies[name]) or xrp.ShortName(name) == UNKNOWN then
		return false
	end
	-- TODO: Only one autorequest per session.
	if not _xrp.unitCache[name] then
		for i, field in ipairs(UNIT_REQUEST) do
			fields[#fields + 1] = field
		end
	elseif not _xrp.unitCache[name].GF then
		fields[#fields + 1] = "GF"
	end
	return msp:Request(name, fields)
				end

function _xrp.CanRefresh(name)
	return true
--[[	local now = GetTime()
	if cache[name].nextCheck and now < cache[name].nextCheck then
		return false
	elseif (cache[name].time.TT or 0) < now or (cache[name].time.DE or 0) < now then
		return true
	end
	return false]]
end

function _xrp.ResetCacheTimers(name)
--[[	if rawget(cache, name) then
		local now = GetTime()
		if cache[name].nextCheck and now < cache[name].nextCheck then
			cache[name].nextCheck = now + 5
		end
		for field, nextReq in pairs(cache[name].time) do
			if nextReq > now + 5 then
				cache[name].time[field] = now + 5
			end
		end
	end]]
end

function _xrp.DropCache(name)
--[[	if xrpAccountSaved.bookmarks[name] or xrpAccountSaved.notes[name] then return end
	_xrp.ResetCacheTimers(name)
	xrpCache[name] = nil
	_xrp.FireEvent("DROP", name)]]
end

function _xrp.ForceRefresh(name, skipTT)
--[[	local fields = {}
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
	end]]
end

_xrp.settingsToggles.display.friendsOnly = function(setting)
	if setting then
		friends = {}
		gameEvents.FRIENDLIST_UPDATE()
		_xrp.HookGameEvent("FRIENDLIST_UPDATE", gameEvents.FRIENDLIST_UPDATE)
		_xrp.settingsToggles.display.guildIsFriends(_xrp.settings.display.guildIsFriends)
	elseif friends then
		_xrp.settingsToggles.display.guildIsFriends(false)
		_xrp.UnhookGameEvent("FRIENDLIST_UPDATE", gameEvents.FRIENDLIST_UPDATE)
		friends = nil
	end
end
_xrp.settingsToggles.display.guildIsFriends = function(setting)
	if setting and friends then
		guildies = {}
		gameEvents.GUILD_ROSTER_UPDATE()
		_xrp.HookGameEvent("GUILD_ROSTER_UPDATE", gameEvents.GUILD_ROSTER_UPDATE)
	elseif guildies and friends then
		_xrp.UnhookGameEvent("GUILD_ROSTER_UPDATE", gameEvents.GUILD_ROSTER_UPDATE)
		guildies = nil
	end
end
