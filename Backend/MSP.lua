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

local function ProfileUpdate(event, field)
	if field then
		if msp.INTERNAL_FIELDS[field] then return end
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
		for field, contents in pairs(msp.my) do
			if not msp.INTERNAL_FIELDS[field] and not fields[field] then
				msp.my[field] = nil
			end
		end
		for field, contents in pairs(fields) do
			msp.my[field] = contents
		end
	end
	msp:Update()
end

local function StatusHandler(statusName, reason, msgID, msgTotal)
	local name = xrp.FullName(statusName)
	if not name or reason == "MESSAGE" and (type(msgID) ~= "number" or type(msgTotal) ~= "number") then
		error("XRP: LibMSP status callback receieved invalid arguments.")
	elseif reason == "ERROR" then
		-- Same error message from offline and from opposite faction.
		local GF = _xrp.unitCache[name] and _xrp.unitCache[name].GF or xrpCache[name] and xrpCache[name].fields.GF
		_xrp.FireEvent("FAIL", name, (not GF or GF == UnitFactionGroup("player")) and "offline" or "faction")
	elseif reason == "MESSAGE" and msgTotal ~= 1 then
		_xrp.FireEvent("CHUNK", name, msgID, msgTotal)
	end
end

local function UpdatedHandler(updatedName, field, contents, version)
	local name = xrp.FullName(updatedName)
	if not name or type(field) ~= "string" or not field:find("^%u%u$") or contents and type(contents) ~= "string" or version and type(version) ~= "number" then
		error("XRP: LibMSP updated callback receieved invalid arguments.")
	elseif not xrpCache[name] and (contents ~= "" or version ~= 0) then
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
	xrpCache[name].fields[field] = contents
	xrpCache[name].versions[field] = version
	_xrp.FireEvent("FIELD", name, field)
	if field == "VA" and contents then
		_xrp.AddonUpdate(contents:match("^XRP/([^;]+)"))
	end
end

local function ReceivedHandler(receivedName)
	local name = xrp.FullName(receivedName)
	if not name then
		error("XRP: LibMSP received callback receieved invalid arguments.")
	end
	_xrp.FireEvent("RECEIVE", name)
	if xrpCache[name] then
		-- Cache timer. Last receive marked for clearing old entries.
		xrpCache[name].lastReceive = time()
	end
end

local function DataLoadHandler(dataLoadName, char)
	local name = xrp.FullName(dataLoadName)
	if not name or type(char) ~= "table" then
		error("XRP: LibMSP dataload callback receieved invalid arguments.")
	end
	if xrpCache[name] then
		for field, contents in pairs(xrpCache[name].fields) do
			char.field[field] = contents
			char.ver[field] = xrpCache[name].versions[field]
		end
		char.ver.TT = xrpCache[name].versions.TT
	end
end

if not disabled then
	msp:AddFieldsToTooltip("RC")
	msp.callback.status[#msp.callback.status + 1] = StatusHandler
	msp.callback.updated[#msp.callback.updated + 1] = UpdatedHandler
	msp.callback.received[#msp.callback.received + 1] = ReceivedHandler
	msp.callback.dataload[#msp.callback.dataload + 1] = DataLoadHandler
	xrp.HookEvent("UPDATE", ProfileUpdate)
end

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

function _xrp.QueueRequest(name, field)
	if disabled or gameFriends and not (gameFriends[name] or bnetFriends[name] or guildies and guildies[name]) then
		return
	elseif _xrp.unitCache[name] and _xrp.unitCache[name][field] then
		return
	end
	return msp:QueueRequest(name, field)
end

function _xrp.CanRefresh(name)
	return (msp.char[name].time.DE or 0) < GetTime() - 30
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

	for field, contents in pairs(msp.char[name].field) do
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
