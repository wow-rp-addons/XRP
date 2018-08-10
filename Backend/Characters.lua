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

AddOn_XRP.Characters = {}

local FILTER_SEARCH = {
	NA = true, NI = true, NT = true, NH = true, AH = true, AW = true,
	AE = true, RA = true, RC = true, CU = true, DE = true, AG = true,
	HH = true, HB = true, MO = true, HI = true, CO = true,
}

local RACE_FACTION = {
	Human = "Alliance",
	Dwarf = "Alliance",
	Gnome = "Alliance",
	NightElf = "Alliance",
	Draenei = "Alliance",
	Worgen = "Alliance",
	VoidElf = "Alliance",
	LightforgedDraenei = "Alliance",
	DarkIronDwarf = "Alliance",
	KulTiran = "Alliance",
	Orc = "Horde",
	Tauren = "Horde",
	Troll = "Horde",
	Scourge = "Horde",
	BloodElf = "Horde",
	Goblin = "Horde",
	Nightborne = "Horde",
	HighmountainTauren = "Horde",
	MagharOrc = "Horde",
	ZandalariTroll = "Horde",
	Pandaren = false, -- Can't tell faction.
}

local MERCENARY = {
	Alliance = "Horde",
	Horde = "Alliance",
}

local unitCache = {}
AddOn.unitCache = unitCache

local CharacterIDMap = setmetatable({}, AddOn.WeakKeyMetatable)
local OfflineMap = setmetatable({}, AddOn.WeakKeyMetatable)

local CharacterMethods = {}

function CharacterMethods:DropCache()
	AddOn.DropCache(CharacterIDMap[self])
end

function CharacterMethods:ForceRefresh()
	AddOn.ForceRefresh(CharacterIDMap[self])
end

local CharacterMetatable = {}

function CharacterMetatable:__index(index)
	if type(index) ~= "string" then
		error("AddOn_XRP.Characters: CharacterTable: expected string index, got " .. type(index), 2)
	end
	local characterID = CharacterIDMap[self]
	if index == "id" then
		return characterID
	elseif index:find("^%u%u$") then
		local field = index
		if unitCache[characterID] and unitCache[characterID][field] then
			return unitCache[characterID][field]
		elseif not OfflineMap[self] then
			AddOn.QueueRequest(characterID, field)
		end
		if xrpCache[characterID] and xrpCache[characterID].fields[field] then
			local contents = xrpCache[characterID].fields[field]
			if field == "AH" then
				contents = AddOn.ConvertHeight(contents)
			elseif field == "AW" then
				contents = AddOn.ConvertWeight(contents)
			end
			return contents
		end
		return nil
	elseif index == "name" then
		local name, realm = AddOn.SplitCharacterID(characterID)
		return name
	elseif index == "realm" then
		local name, realm = AddOn.SplitCharacterID(characterID)
		return realm
	elseif index == "fullDisplayName" then
		local name, realm = AddOn.SplitCharacterID(characterID)
		return L.NAME_REALM:format(name, realm)
	elseif CharacterMethods[index] then
		return CharacterMethods[index]
	elseif index == "offline" then
		return OfflineMap[self] or false
	elseif index == "canRefresh" then
		return OfflineMap[self] or AddOn.CanRefresh(characterID)
	elseif index == "notes" then
		return xrpAccountSaved.notes[characterID] or nil
	elseif index == "bookmark" then
		return xrpAccountSaved.bookmarks[characterID] or false
	elseif index == "hide" then
		return xrpAccountSaved.hidden[characterID] or false
	elseif index == "own" then
		return characterID == AddOn.characterID or xrpCache[characterID] and xrpCache[characterID].own or false
	elseif index == "date" then
		return xrpCache[characterID] and xrpCache[characterID].lastReceive or -1
	elseif index == "exportPlainText" then
		if not xrpCache[characterID] then
			return ""
		end
		return AddOn.ExportText(self.fullDisplayName, xrpCache[characterID].fields)
	end
	error("AddOn_XRP.Characters: CharacterTable: invalid index " .. index, 2)
end

function CharacterMetatable:__newindex(index, value)
	if type(index) ~= "string" then
		error("AddOn_XRP.Characters: CharacterTable: expected to set string index, got " .. type(index), 2)
	end
	local characterID = CharacterIDMap[self]
	if index == "notes" then
		if value ~= nil and type(value) ~= "string" then
			error("AddOn_XRP.Characters: CharacterTable.notes: expected string or nil value, got " .. type(value), 2)
		elseif value == "" then
			value = nil
		end
		xrpAccountSaved.notes[characterID] = value
	elseif index == "bookmark" then
		if type(value) ~= "boolean" then
			error("AddOn_XRP.Characters: CharacterTable.bookmark: expected boolean value, got " .. type(value), 2)
		elseif value and not xrpAccountSaved.bookmarks[characterID] then
			xrpAccountSaved.bookmarks[characterID] = time()
		elseif not value and xrpAccountSaved.bookmarks[characterID] then
			xrpAccountSaved.bookmarks[characterID] = nil
		end
	elseif index == "hide" then
		if type(value) ~= "boolean" then
			error("AddOn_XRP.Characters: CharacterTable.hide: expected boolean value, got " .. type(value), 2)
		elseif value and not xrpAccountSaved.hidden[characterID] then
			xrpAccountSaved.hidden[characterID] = true
		elseif not value and xrpAccountSaved.hidden[characterID] then
			xrpAccountSaved.hidden[characterID] = nil
		end
	else
		error("AddOn_XRP.Characters: CharacterTable: could not set invalid or read-only index: " .. index, 2)
	end
end

function CharacterMetatable:__eq(toCompare)
	return CharacterIDMap[self] == CharacterIDMap[toCompare]
end

CharacterMetatable.__metatable = false

local Online = setmetatable({}, AddOn.WeakValueMetatable)
local Offline = setmetatable({}, AddOn.WeakValueMetatable)

local byNameMetatable = {}
function byNameMetatable:__index(name)
	if name ~= nil and type(name) ~= "string" then
		error("AddOn_XRP.Characters.byName: expected string or nil index, got " .. type(name), 2)
	end
	local characterID = AddOn.BuildCharacterID(name)
	if not characterID then
		return nil
	elseif not Online[characterID] then
		local character = setmetatable({}, CharacterMetatable)
		CharacterIDMap[character] = characterID
		Online[characterID] = character
	end
	return Online[characterID]
end
byNameMetatable.__newindex = AddOn.DoNothing
byNameMetatable.__metatable = false

local byNameOfflineMetatable = {}
function byNameOfflineMetatable:__index(name)
	if name ~= nil and type(name) ~= "string" then
		error("AddOn_XRP.Characters.byNameOffline: expected string or nil index, got " .. type(name), 2)
	end
	local characterID = AddOn.BuildCharacterID(name)
	if not characterID then
		return nil
	elseif not Offline[characterID] then
		local character = setmetatable({}, CharacterMetatable)
		CharacterIDMap[character] = characterID
		Offline[characterID] = character
		OfflineMap[character] = true
	end
	return Offline[characterID]
end
byNameOfflineMetatable.__newindex = AddOn.DoNothing
byNameOfflineMetatable.__metatable = false

local byGUIDMetatable = {}
function byGUIDMetatable:__index(GU)
	if GU ~= nil and type(GU) ~= "string" then
		error("AddOn_XRP.Characters.byGUID: expected string or nil index, got " .. type(GU), 2)
	end
	-- GetPlayerInfoByGUID() has been known to varyingly error or return
	-- garbage values if the GUID is invalid or maybe just not seen by the
	-- client yet.
	local success, class, GC, race, GR, GS, name, realm = pcall(GetPlayerInfoByGUID, GU)
	if not success or not name or name == UNKNOWN then
		return nil
	end
	local characterID = AddOn.BuildCharacterID(name, realm)
	if not unitCache[characterID] then
		if not AddOn_XRP.Strings.Values.GR[GR] then
			AddOn_XRP.Strings.Values.GR[GR] = race
		end
		unitCache[characterID] = {
			GC = GC,
			GF = RACE_FACTION[GR] or nil,
			GR = GR,
			GS = tostring(GS),
			GU = GU,
		}
		if xrpCache[characterID] and characterID ~= AddOn.characterID then
			for field, contents in pairs(unitCache[characterID]) do
				-- We DO want to overwrite these, to account for race,
				-- faction, or sex changes.
				xrpCache[characterID].fields[field] = contents
			end
		end
	end
	if not Online[characterID] then
		local character = setmetatable({}, CharacterMetatable)
		CharacterIDMap[character] = characterID
		Online[characterID] = character
	end
	return Online[characterID]
end
byGUIDMetatable.__newindex = AddOn.DoNothing
byGUIDMetatable.__metatable = false

local byUnitMetatable = {}
function byUnitMetatable:__index(unit)
	if unit ~= nil and type(unit) ~= "string" then
		error("AddOn_XRP.Characters.byUnit: expected string or nil index, got " .. type(unit), 2)
	end
	local character = AddOn_XRP.Characters.byGUID[UnitGUID(unit)]
	if not character then
		return nil
	end
	local characterID = character.id
	if not unitCache[characterID].GF then
		-- GUID won't always get faction.
		local GF = UnitIsMercenary(unit) and MERCENARY[UnitFactionGroup(unit)] or UnitFactionGroup(unit)
		if unitCache.GR and RACE_FACTION[unitCache.GR] == nil then
			RACE_FACTION[unitCache.GR] = GF
		end
		unitCache[characterID].GF = GF
		if xrpCache[characterID] and characterID ~= AddOn.characterID then
			xrpCache[characterID].fields.GF = GF
		end
	end
	return character
end
byUnitMetatable.__newindex = AddOn.DoNothing
byUnitMetatable.__metatable = false

AddOn_XRP.Characters.byName = setmetatable({}, byNameMetatable)
AddOn_XRP.Characters.byNameOffline = setmetatable({}, byNameOfflineMetatable)
AddOn_XRP.Characters.byGUID = setmetatable({}, byGUIDMetatable)
AddOn_XRP.Characters.byUnit = setmetatable({}, byUnitMetatable)

local function SortString(sortType, name, cache)
	if sortType == "date" then
		return ("%d\000%s"):format(cache.lastReceive, name)
	elseif sortType == "NA" then
		return ("%s\000%s"):format((xrp.Strip(cache.fields.NA) or name):lower(), name)
	elseif sortType == "realm" then
		return ("%s\000%s"):format(name:match("%-([^%-]+)$"), name)
	end
	return ("%s\000%s"):format(name:lower(), name)
end

local function SortAsc(a, b)
	return a > b
end

function AddOn_XRP.SearchCharacters(query)
	if not query then
		query = {}
	end
	local results, totalCount = {}, 0
	local before = query.maxAge and (time() - query.maxAge)
	local bookmarks, notes, hidden = xrpAccountSaved.bookmarks, xrpAccountSaved.notes, xrpAccountSaved.hidden
	for name, cache in pairs(xrpCache) do
		totalCount = totalCount + 1
		local toAdd = true
		if query.bookmark and not bookmarks[name] then
			toAdd = false
		elseif query.notes and not notes[name] then
			toAdd = false
		elseif not query.showHidden and hidden[name] then
			toAdd = false
		elseif query.own and not cache.own then
			toAdd = false
		elseif query.faction and query.faction[cache.fields.GF or "UNKNOWN"] then
			toAdd = false
		elseif query.class and query.class[cache.fields.GC or "UNKNOWN"] then
			toAdd = false
		elseif query.race and query.race[cache.fields.GR or "UNKNOWN"] then
			toAdd = false
		elseif before and cache.lastReceive < before then
			toAdd = false
		elseif not query.fullText and query.text then
			local searchText = query.text:lower()
			local nameText = name:match(FULL_PLAYER_NAME:format("(.+)", ".+")):lower()
			if not nameText:find(searchText, nil, true) then
				toAdd = false
			end
		elseif query.text then
			local found = false
			local searchText = query.text:lower()
			for field, contents in pairs(cache.fields) do
				if FILTER_SEARCH[field] and contents:lower():find(searchText, nil, true) then
					found = true
					break
				end
			end
			if not found then
				toAdd = false
			end
		end
		if toAdd then
			results[#results + 1] = SortString(query.sortType, name, cache)
		end
	end
	local sortAscending = query.sortReverse
	if query.sortType == "date" then -- Default to newest first for date.
		sortAscending = not sortAscending
	end
	if sortAscending then
		table.sort(results, SortAsc)
	else
		table.sort(results)
	end
	for i, result in ipairs(results) do
		results[i] = result:match("^.-%z(.+)$")
	end
	results.totalCount = totalCount
	return results
end
