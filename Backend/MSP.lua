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

local SUPPORTED_FIELDS = {
	"NA", "NI", "NT", "NH", "AH", "AW", "AE", "RA", "RC", "CU", "DE",
	"AG", "HH", "HB", "MO", "HI", "FR", "FC", "CO", "IC", "VA",
}

-- These fields are (or should) be generated from UnitSomething() functions.
local UNIT_FIELDS = { "GC", "GF", "GR", "GS", "GU" }

xrp.HookEvent("UPDATE", function(event, field)
	if field then
		msp.my[field] = xrp.current[field]
	else
		for i, field in ipairs(SUPPORTED_FIELDS) do
			msp.my[field] = xrp.current[field]
		end
	end
	msp:Update()
end)

local function StatusHandler(name, reason, msgID, msgTotal)
	if reason == "ERROR" then
		-- Same error message from offline and from opposite faction.
		local GF = _xrp.unitCache[name] and _xrp.unitCache[name].GF or xrpCache[name] and xrpCache[name].fields.GF
		_xrp.FireEvent("FAIL", name, (not GF or GF == UnitFactionGroup("player")) and "offline" or "faction")
	elseif reason == "MESSAGE" then
		if msgID ~= msgTotal then
			_xrp.FireEvent("CHUNK", name, msgID, msgTotal)
		end
	end
end
msp.callback.status[#msp.callback.status + 1] = StatusHandler

msp:AddFieldsToTooltip("RC")

local function UpdatedHandler(name, field, contents, version)
	if not xrpCache[name] and (contents ~= "" or version ~= 0) then
		-- This is the only place a cache table is created by XRP.
		xrpCache[name] = {
			fields = {},
			versions = {},
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
	xrpCache[name].versions[field] = version
	_xrp.FireEvent("FIELD", name, field)
end
msp.callback.updated[#msp.callback.updated + 1] = UpdatedHandler

local function ReceivedHandler(name)
	_xrp.FireEvent("RECEIVE", name)
	--_xrp.FireEvent("NOCHANGE", name)
	if xrpCache[name] then
		-- Cache timer. Last receive marked for clearing old entries.
		xrpCache[name].lastReceive = time()
	end
end
msp.callback.received[#msp.callback.received + 1] = ReceivedHandler

local function DataLoadHandler(name, char)
	if xrpCache[name] then
		for field, contents in pairs(xrpCache[name].fields) do
			char.field[field] = contents
			char.ver[field] = xrpCache[name].versions[field]
		end
		char.ver.TT = xrpCache[name].versions.TT
	end
end
msp.callback.dataload[#msp.callback.dataload + 1] = DataLoadHandler

local gameFriends
local function FRIENDLIST_UPDATE(event)
	if not gameFriends then return end
	table.wipe(gameFriends)
	for i = 1, select(2, GetNumFriends()) do
		gameFriends[xrp.FullName((GetFriendInfo(i)))] = true
	end
end

local bnetFriends
local function BN_FRIEND_INFO_CHANGED(event)
	if not bnetFriends then return end
	table.wipe(bnetFriends)
	for i = 1, select(2, BNGetNumFriends()) do
		for j = 1, BNGetNumFriendGameAccounts(i) do
			local active, characterName, client, realmName, realmID, faction, race, class, blank, zoneName, level, gameText, broadcastText, broadcastTime, isConnected, bnetIDGameAccount = BNGetFriendGameAccountInfo(i, j)
			if isConnected and client == BNET_CLIENT_WOW and realmName and realmName ~= "" then
				bnetFriends[xrp.FullName(characterName, realm)] = true
			end
		end
	end
end

local guildies
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

local function GUILD_ROSTER_UPDATE(event)
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
	if disabled or name == _xrp.playerWithRealm or gameFriends and not (gameFriends[name] or bnetFriends[name] or guildies and guildies[name]) or xrp.ShortName(name) == UNKNOWN then
		return
	elseif _xrp.unitCache[name] and _xrp.unitCache[name][field] then
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
	if disabled or name == _xrp.playerWithRealm or gameFriends and not (gameFriends[name] or bnetFriends[name] or guildies and guildies[name]) or xrp.ShortName(name) == UNKNOWN then
		return false
	end
	if not _xrp.unitCache[name] then
		for i, field in ipairs(UNIT_REQUEST) do
			if not msp.char[name].time[field] then
				fields[#fields + 1] = field
			end
		end
	elseif not _xrp.unitCache[name].GF and not msp.char[name].time.GF then
		fields[#fields + 1] = "GF"
	end
	return msp:Request(name, fields)
end

-- TODO: Remove, replace with status line in Viewer if cannot refresh after
-- trying to do so.
function _xrp.CanRefresh(name)
	return true
end

function _xrp.ResetCacheTimers(name)
	msp.char[name].time = nil
	msp.char[name].scantime = nil
	msp.char[name].supported = nil
end

function _xrp.DropCache(name)
	if xrpAccountSaved.bookmarks[name] or xrpAccountSaved.notes[name] then return end
	msp.char[name] = nil
	xrpCache[name] = nil
	_xrp.FireEvent("DROP", name)
end

function _xrp.ForceRefresh(name)
	_xrp.ResetCacheTimers(name)
	msp.char[name].ver = nil

	for field, contents in pairs(msp.char[name]) do
		_xrp.QueueRequest(name, field)
	end
end

_xrp.settingsToggles.friendsOnly = function(setting)
	if setting then
		gameFriends = {}
		FRIENDLIST_UPDATE()
		_xrp.HookGameEvent("FRIENDLIST_UPDATE", FRIENDLIST_UPDATE)
		bnetFriends = {}
		BN_FRIEND_INFO_CHANGED()
		_xrp.HookGameEvent("BN_FRIEND_INFO_CHANGED", BN_FRIEND_INFO_CHANGED)
		_xrp.settingsToggles.friendsIncludeGuild(_xrp.settings.friendsIncludeGuild)
	elseif gameFriends then
		_xrp.settingsToggles.friendsIncludeGuild(false)
		_xrp.UnhookGameEvent("FRIENDLIST_UPDATE", FRIENDLIST_UPDATE)
		gameFriends = nil
		_xrp.UnhookGameEvent("BN_FRIEND_INFO_CHANGED", BN_FRIEND_INFO_CHANGED)
		bnetFriends = nil
	end
end
_xrp.settingsToggles.friendsIncludeGuild = function(setting)
	if setting and gameFriends then
		guildies = {}
		GUILD_ROSTER_UPDATE()
		_xrp.HookGameEvent("GUILD_ROSTER_UPDATE", GUILD_ROSTER_UPDATE)
	elseif guildies and gameFriends then
		_xrp.UnhookGameEvent("GUILD_ROSTER_UPDATE", GUILD_ROSTER_UPDATE)
		guildies = nil
	end
end
