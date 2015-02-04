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

local addonName, xrpPrivate = ...

-- These fields are not searched in a full-text search.
local FILTER_IGNORE = { CO = true, FC = true, FR = true, GC = true, GF = true, GR = true, GS = true, GU = true, IC = true, VA = true, VP = true }

local RACE_FACTION = {
	Human = "Alliance",
	Dwarf = "Alliance",
	Gnome = "Alliance",
	NightElf = "Alliance",
	Draenei = "Alliance",
	Worgen = "Alliance",
	Orc = "Horde",
	Tauren = "Horde",
	Troll = "Horde",
	Scourge = "Horde",
	BloodElf = "Horde",
	Goblin = "Horde",
	Pandaren = nil, -- Can't tell faction.
}

local gCache = {}
xrpPrivate.gCache = gCache

local nk, rq = {}, {}

local characterMeta
do
	local fieldsMeta = {
		__index = function(self, field)
			if not field:find("^%u%u$") then
				return nil
			end
			local name = self[nk]
			if name == xrpPrivate.playerWithRealm then
				return xrp.current.fields[field]
			end
			-- Any access to a field is treated as an implicit request to fetch
			-- it (but msp won't do it if it's fresh, and will compile quick,
			-- successive requests into one go). Never request data we already
			-- have, and know is good.
			if gCache[name] and gCache[name][field] then
				return gCache[name][field]
			end
			if self[rq] then
				xrpPrivate:QueueRequest(name, field)
			end
			if xrpCache[name] and xrpCache[name].fields[field] then
				return xrpCache[name].fields[field]
			end
			return nil
		end,
		__newindex = xrpPrivate.noFunc,
		__metatable = false,
	}

	characterMeta = {
		__index = function(self, component)
			local name = self[nk]
			if component == "fields" then
				rawset(self, "fields", setmetatable({ [nk] = name, [rq] = self[rq] }, fieldsMeta))
				return self.fields
			elseif component == "name" then
				return name
			elseif component == "own" and name == xrpPrivate.playerWithRealm then
				return true
			elseif not xrpCache[name] then
				return nil
			elseif component == "bookmark" then
				return xrpAccountSaved.bookmarks[name]
			elseif component == "hide" then
				return xrpAccountSaved.hidden[name]
			elseif component == "own" then
				return xrpCache[name].own
			elseif component == "date" then
				return xrpCache[name].lastReceive
			elseif component == "noRequest" then
				return not self[rq]
			elseif component == "exportText" then
				local EXPORT_FIELDS, EXPORT_FORMATS = xrpPrivate.EXPORT_FIELDS, xrpPrivate.EXPORT_FORMATS
				local fields
				if name == xrpPrivate.playerWithRealm then
					fields = xrpPrivate.current.fields
				else
					fields = xrpCache[name].fields
				end
				local shortName, realm = name:match(FULL_PLAYER_NAME:format("(.+)", "(.+)"))
				realm = xrp:RealmDisplayName(realm)
				local export = { shortName, " (", realm, ")\n" }
				for i = 1, #shortName + #realm + 3 do
					export[#export + 1] = "="
				end
				export[#export + 1] = "\n"
				for i, field in ipairs(EXPORT_FIELDS) do
					if fields[field] then
						local fieldText = fields[field]
						if field == "AH" then
							fieldText = xrp:Height(fieldText)
						elseif field == "AW" then
							fieldText = xrp:Weight(fieldText)
						end
						export[#export + 1] = EXPORT_FORMATS[field]:format(fieldText)
					end
				end
				return table.concat(export)
			end
		end,
		__newindex = function(self, component, value)
			local name = self[nk]
			if not xrpCache[name] then return end
			if component == "bookmark" then
				if value and not xrpAccountSaved.bookmarks[name] then
					xrpAccountSaved.bookmarks[name] = time()
				elseif not value and xrpAccountSaved.bookmarks[name] then
					xrpAccountSaved.bookmarks[name] = nil
				end
			elseif component == "hide" then
				if value and not xrpAccountSaved.hidden[name] then
					xrpAccountSaved.hidden[name] = true
				elseif not value and xrpAccountSaved.hidden[name] then
					xrpAccountSaved.hidden[name] = nil
				end
			end
		end,
		__metatable = false,
	}
end

local Filter
do
	local function SortString(sortType, name, cache)
		if sortType == "date" then
			return ("%u\30%s"):format(cache.lastReceive, name)
		elseif sortType == "NA" then
			return ("%s\30%s"):format((xrp:Strip(cache.fields.NA) or name):lower(), name)
		elseif sortType == "realm" then
			return ("%s\30%s"):format(name:match(FULL_PLAYER_NAME:format(".+", "(.+)")), name)
		end
		return "\30" .. name
	end

	local function SortAsc(a, b)
		return a > b
	end

	function Filter(self, request)
		local results = {}
		if type(request) ~= "table" then
			return results
		end
		local totalCount = 0
		local before = request.maxAge and (time() - request.maxAge)
		local bookmarks = xrpAccountSaved.bookmarks
		local hidden = xrpAccountSaved.hidden
		for name, cache in pairs(xrpCache) do
			totalCount = totalCount + 1
			local toAdd = true
			if request.bookmark and not bookmarks[name] then
				toAdd = false
			elseif not request.showHidden and hidden[name] then
				toAdd = false
			elseif request.own and not cache.own then
				toAdd = false
			elseif request.faction and request.faction[cache.fields.GF or "UNKNOWN"] then
				toAdd = false
			elseif request.class and request.class[cache.fields.GC or "UNKNOWN"] then
				toAdd = false
			elseif request.race and request.race[cache.fields.GR or "UNKNOWN"] then
				toAdd = false
			elseif before and cache.lastReceive < before then
				toAdd = false
			end
			if toAdd and not request.fullText and request.text then
				local searchText = request.text:lower()
				local nameText = name:match(FULL_PLAYER_NAME:format("(.+)", ".+")):lower()
				if not nameText:find(searchText, nil, true) then
					toAdd = false
				end
			elseif toAdd and request.text then
				local found = false
				local searchText = request.text:lower()
				for field, contents in pairs(cache.fields) do
					if not FILTER_IGNORE[field] and contents:lower():find(searchText, nil, true) then
						found = true
						break
					end
				end
				if not found then
					toAdd = false
				end
			end
			if toAdd then
				results[#results + 1] = SortString(request.sortType, name, cache)
			end
		end
		local sortAscending = request.sortReverse
		if request.sortType == "date" then -- Default to newest first for date.
			sortAscending = not sortAscending
		end
		if sortAscending then
			table.sort(results, SortAsc)
		else
			table.sort(results)
		end
		for i, result in ipairs(results) do
			results[i] = self.byName[result:match("^.-\30(.+)$")]
		end
		results.totalCount = totalCount
		return results
	end
end

local requestTables = setmetatable({}, xrpPrivate.weakMeta)
local noRequestTables = setmetatable({}, xrpPrivate.weakMeta)

xrp.characters = {
	byName = setmetatable({}, {
		__index = function(self, name)
			name = xrp:Name(name)
			if not name then
				return nil
			end
			if not requestTables[name] then
				requestTables[name] = setmetatable({ [nk] = name, [rq] = true }, characterMeta)
			end
			return requestTables[name]
		end,
		__newindex = xrpPrivate.noFunc,
		__metatable = false,
	}),
	byUnit = setmetatable({}, {
		__index = function (self, unit)
			local name = xrp:UnitName(unit)
			if not name then
				return nil
			end
			-- These values may only update once per session. This could create
			-- minor confusion if someone changes faction, race, sex, or GUID
			-- while we're still logged in. Unlikely, but possible.
			if not gCache[name] then
				local GU = UnitGUID(unit)
				local class, GC, race, GR, GS = GetPlayerInfoByGUID(GU)
				gCache[name] = {
					GC = GC,
					GF = UnitFactionGroup(unit),
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrpCache[name] and name ~= xrpPrivate.playerWithRealm then
					for field, contents in pairs(gCache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrpCache[name].fields[field] = contents
					end
				end
			elseif not gCache[name].GF then -- GUID won't always get faction.
				gCache[name].GF = UnitFactionGroup(unit)
				if xrpCache[name] and name ~= xrpPrivate.playerWithRealm then
					xrpCache[name].fields.GF = gCache[name].GF
				end
			end
			if not requestTables[name] then
				requestTables[name] = setmetatable({ [nk] = name, [rq] = true }, characterMeta)
			end
			return requestTables[name]
		end,
		__newindex = xrpPrivate.noFunc,
		__metatable = false,
	}),
	byGUID = setmetatable({}, {
		__index = function (self, GU)
			-- This will return nil if the GUID hasn't been seen by the client
			-- yet in the session.
			local class, GC, race, GR, GS, name, realm = GetPlayerInfoByGUID(GU)
			name = xrp:Name(name, realm)
			if not name or name == "" then
				return nil
			end
			-- These values may only update once per session. This could create
			-- minor confusion if someone changes faction, race, sex, or GUID
			-- while we're still logged in. Unlikely, but possible.
			if not gCache[name] then
				gCache[name] = {
					GC = GC,
					GF = RACE_FACTION[GR],
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrpCache[name] and name ~= xrpPrivate.playerWithRealm then
					for field, contents in pairs(gCache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrpCache[name].fields[field] = contents
					end
				end
			end
			if not requestTables[name] then
				requestTables[name] = setmetatable({ [nk] = name, [rq] = true }, characterMeta)
			end
			return requestTables[name]
		end,
		__newindex = xrpPrivate.noFunc,
		__metatable = false,
	}),
	Filter = Filter,
	noRequest = {
		byName = setmetatable({}, {
			__index = function(self, name)
				name = xrp:Name(name)
				if not name then
					return nil
				end
				if not noRequestTables[name] then
					noRequestTables[name] = setmetatable({ [nk] = name, [rq] = false }, characterMeta)
				end
				return noRequestTables[name]
			end,
			__newindex = xrpPrivate.noFunc,
			__metatable = false,
		}),
		Filter = Filter,
	},
}
