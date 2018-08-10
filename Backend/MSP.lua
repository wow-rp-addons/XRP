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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local disabled = false
if not msp_RPAddOn then
	msp_RPAddOn = FOLDER_NAME
else
	StaticPopupDialogs["XRP_MSP_DISABLE"] = {
		text = L"You are currently running two roleplay profile addons. XRP's support for sending and receiving profiles is disabled; to fully use XRP, disable \"%s\" and reload your UI.",
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

local OwnCharacters = {}

AddOn.RegisterGameEventCallback("PLAYER_LOGIN", function(event)
	-- GetAutoCompleteResults() doesn't work before PLAYER_LOGIN.
	OwnCharacters[AddOn.characterID] = true
	if xrpCache[AddOn.characterID] and not xrpCache[AddOn.characterID].own then
		xrpCache[AddOn.characterID].own = true
	end
	for i, character in ipairs(GetAutoCompleteResults("", 0, 1, AUTO_COMPLETE_ACCOUNT_CHARACTER, 0)) do
		local name = AddOn.BuildCharacterID(character.name)
		OwnCharacters[name] = true
		if xrpCache[name] and not xrpCache[name].own then
			xrpCache[name].own = true
		end
	end
	for name, data in pairs(xrpCache) do
		if data.own and not OwnCharacters[name] and name:match("%-([^%-]+)$") == AddOn.characterRealm then
			data.own = nil
		end
	end
end)

local function ProfileUpdate(event, field)
	if field then
		if msp.INTERNAL_FIELDS[field] then return end
		local contents = xrpSaved.overrides[field] or xrp.profiles.SELECTED.fullFields[field] or AddOn.FallbackFields[field]
		if not contents or contents == "" then
			contents = nil
		elseif field == "AH" then
			contents = AddOn.ConvertHeight(contents, "msp")
		elseif field == "AW" then
			contents = AddOn.ConvertWeight(contents, "msp")
		end
		msp.my[field] = contents
	else
		local fields = AddOn.GetFullCurrentProfile()
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
	local name = AddOn.BuildCharacterID(statusName)
	if not name or reason == "MESSAGE" and (type(msgID) ~= "number" or type(msgTotal) ~= "number") then
		error("XRP: LibMSP status callback receieved invalid arguments.")
	elseif reason == "ERROR" then
		-- Same error message from offline and from opposite faction.
		local GF = AddOn.unitCache[name] and AddOn.unitCache[name].GF or xrpCache[name] and xrpCache[name].fields.GF
		AddOn.RunEvent("FAIL", name, (not GF or GF == UnitFactionGroup("player")) and "offline" or "faction")
	elseif reason == "MESSAGE" and msgTotal ~= 1 then
		AddOn.RunEvent("CHUNK", name, msgID, msgTotal)
	end
end

local function UpdatedHandler(updatedName, field, contents, version)
	local name = AddOn.BuildCharacterID(updatedName)
	if not name or type(field) ~= "string" or not field:find("^%u%u$") or contents and type(contents) ~= "string" or version and type(version) ~= "number" then
		error("XRP: LibMSP updated callback receieved invalid arguments.")
	elseif field == "VW" then
		if contents then
			AddOn.UpdateWoWVersion((";"):split(contents))
		end
		return
	elseif not xrpCache[name] then
		-- This is the only place a cache table is created by XRP.
		xrpCache[name] = {
			fields = {},
			versions = {},
			lastReceive = time(),
			own = OwnCharacters[name],
		}
		if AddOn.unitCache[name] then
			for i, unitField in pairs(UNIT_FIELDS) do
				xrpCache[name].fields[unitField] = AddOn.unitCache[name][unitField]
			end
		end
	end
	xrpCache[name].fields[field] = contents
	xrpCache[name].versions[field] = version
	AddOn.RunEvent("FIELD", name, field)
	if field == "VA" and contents then
		AddOn.CheckVersionUpdate(name, contents:match("^XRP/([^;]+)"))
	end
end

local function ReceivedHandler(receivedName)
	local name = AddOn.BuildCharacterID(receivedName)
	if not name then
		error("XRP: LibMSP received callback receieved invalid arguments.")
	end
	AddOn.RunEvent("RECEIVE", name)
	if xrpCache[name] then
		-- Cache timer. Last receive marked for clearing old entries.
		xrpCache[name].lastReceive = time()
	end
end

local function DataLoadHandler(dataLoadName, char)
	local name = AddOn.BuildCharacterID(dataLoadName)
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
	AddOn_XRP.RegisterEventCallback("UPDATE", ProfileUpdate)
end

local gameFriends
local function FRIENDLIST_UPDATE(event)
	if not gameFriends then return end
	table.wipe(gameFriends)
	for i = 1, select(2, GetNumFriends()) do
		gameFriends[AddOn.BuildCharacterID((GetFriendInfo(i)))] = true
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
				bnetFriends[AddOn.BuildCharacterID(characterName, realm)] = true
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
				guildies[AddOn.BuildCharacterID(name)] = true
			end
		end
	else
		for i = 1, select(2, GetNumGuildMembers()) do
			guildies[AddOn.BuildCharacterID((GetGuildRosterInfo(i)))] = true
		end
	end
end

local function GUILD_ROSTER_UPDATE(event)
	if not guildies then return end
	-- Workaround for ugly issue with the show offline tickbox on the guild
	-- roster UI.
	C_Timer.After(0, UpdateGuildRoster)
end

function AddOn.QueueRequest(name, field)
	if disabled or gameFriends and not (gameFriends[name] or bnetFriends[name] or guildies and guildies[name]) then
		return
	elseif AddOn.unitCache[name] and AddOn.unitCache[name][field] then
		return
	end
	return msp:QueueRequest(name, field)
end

function AddOn.CanRefresh(name)
	if name == AddOn.characterID then
		return false
	end
	return (msp.char[name].time.DE or 0) < GetTime() - 30
end

function AddOn.ResetCacheTimers(name)
	msp.char[name].time = nil
	msp.char[name].scantime = nil
	msp.char[name].supported = nil
end

function AddOn.DropCache(name)
	if xrpAccountSaved.bookmarks[name] or xrpAccountSaved.notes[name] then return end
	msp.char[name] = nil
	xrpCache[name] = nil
	AddOn.RunEvent("DROP", name)
end

function AddOn.ForceRefresh(name)
	AddOn.ResetCacheTimers(name)
	msp.char[name].ver = nil

	for field, contents in pairs(msp.char[name].field) do
		AddOn.QueueRequest(name, field)
	end
end

AddOn.SettingsToggles.friendsOnly = function(setting)
	if setting then
		gameFriends = {}
		FRIENDLIST_UPDATE()
		AddOn.RegisterGameEventCallback("FRIENDLIST_UPDATE", FRIENDLIST_UPDATE)
		bnetFriends = {}
		BN_FRIEND_INFO_CHANGED()
		AddOn.RegisterGameEventCallback("BN_FRIEND_INFO_CHANGED", BN_FRIEND_INFO_CHANGED)
		AddOn.SettingsToggles.friendsIncludeGuild(AddOn.Settings.friendsIncludeGuild)
	elseif gameFriends then
		AddOn.SettingsToggles.friendsIncludeGuild(false)
		AddOn.UnregisterGameEventCallback("FRIENDLIST_UPDATE", FRIENDLIST_UPDATE)
		gameFriends = nil
		AddOn.UnregisterGameEventCallback("BN_FRIEND_INFO_CHANGED", BN_FRIEND_INFO_CHANGED)
		bnetFriends = nil
	end
end
AddOn.SettingsToggles.friendsIncludeGuild = function(setting)
	if setting and gameFriends then
		guildies = {}
		GUILD_ROSTER_UPDATE()
		AddOn.RegisterGameEventCallback("GUILD_ROSTER_UPDATE", GUILD_ROSTER_UPDATE)
	elseif guildies and gameFriends then
		AddOn.UnregisterGameEventCallback("GUILD_ROSTER_UPDATE", GUILD_ROSTER_UPDATE)
		guildies = nil
	end
end
