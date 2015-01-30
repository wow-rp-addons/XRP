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
				return xrpCache[name].bookmark
			elseif component == "hide" then
				return xrpCache[name].hide
			elseif component == "own" then
				return xrpCache[name].own
			elseif component == "date" then
				return xrpCache[name].lastReceive
			end
		end,
		__newindex = function(self, component, value)
			local name = self[nk]
			if not xrpCache[name] then return end
			if component == "bookmark" then
				if value and not xrpCache[name].bookmark then
					xrpCache[name].bookmark = time()
				elseif not value and xrpCache[name].bookmark then
					xrpCache[name].bookmark = nil
				end
			elseif component == "hide" then
				if value and not xrpCache[name].hide then
					xrpCache[name].hide = true
				elseif not value and xrpCache[name].hide then
					xrpCache[name].hide = nil
				end
			end
		end,
		__metatable = false,
	}
end

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
	},
}
