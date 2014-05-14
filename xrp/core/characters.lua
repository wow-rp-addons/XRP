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

local nk = {}

local weak = { __mode = "v", __metatable = false, }

local chars = setmetatable({}, weak)
local caches = setmetatable({}, weak)

local gcache = setmetatable({}, weak)

local charsmt = {
	__index = function(self, field)
		local name = self[nk]
		-- Any access to a field is treated as an implicit request to fetch
		-- it (but xrp.msp won't do it if it's fresh, and will compile quick,
		-- successive requests into one go). Also try avoiding requests when
		-- we absolutely know they will fail. Never request data we already
		-- have, and know is good.
		if gcache[name] and gcache[name][field] then
			return gcache[name][field]
		end
		if not gcache[name] or not gcache[name].GF or gcache[name].GF == xrp.toon.fields.GF then
			xrp.msp:QueueRequest(name, field)
		end
		if xrp_cache[name] and xrp_cache[name].fields[field] then
			return xrp_cache[name].fields[field]
		end
		return nil
	end,
	__newindex = function(self, field, value)
	end,
	__call = function(self, request)
		if not request then
			local profile = {}
			for field, contents in pairs(xrp_cache[self[nk]].fields) do
				profile[field] = contents
			end
			return profile
		elseif type(request) == "table" or type(request) == "string" then
			xrp.msp:Request(self[nk], request)
		end
	end,
	__metatable = false,
}

xrp.characters = setmetatable({}, {
	__index = function(self, name)
		if not chars[name] then
			chars[name] = setmetatable({ [nk] = name }, charsmt)
		end
		return chars[name]
	end,
	__newindex = function(self, character, fields)
	end,
	__metatable = false,
})

xrp.units = setmetatable({}, {
	__index = function (self, unit)
		if not UnitIsPlayer(unit) then
			return nil
		end
		local name = xrp:UnitNameWithRealm(unit)
		if type(name) == "string" then
			if not chars[name] then
				chars[name] = setmetatable({ [nk] = name }, charsmt)
			end
			-- These values will only update once per session. This could
			-- create minor confusion if someone changes faction, race, sex,
			-- or GUID while we're still logged in. Unlikely, but possible.
			if not gcache[name] then
				gcache[name] = {
					GC = (select(2, UnitClass(unit))),
					GF = (UnitFactionGroup(unit)),
					GR = (select(2, UnitRace(unit))),
					GS = tostring(UnitSex(unit)),
					GU = UnitGUID(unit),
				}
				if xrp_cache[name] then
					for field, contents in pairs(gcache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrp_cache[name].fields[field] = contents
					end
				end
			elseif not gcache[name].GF then -- GUID won't always get faction.
				gcache[name].GF = (UnitFactionGroup(unit))
				if xrp_cache[name] then
					xrp_cache[name].fields.GF = gcache[name].GF
				end
			end
			return chars[name]
		end
		return nil
	end,
	__newindex = function(self, unit, fields)
	end,
	__metatable = false,
})

local race_faction = {
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
	Pandaren = false, -- Can't tell faction.
}

xrp.guids = setmetatable({}, {
	__index = function (self, guid)
		local _, class, _, race, sex, name, realm = GetPlayerInfoByGUID(guid)
		if not name or name == "" then
			return nil
		end
		local faction = race_faction[race] or nil
		name = xrp:NameWithRealm(name, realm)
		if type(name) == "string" then
			if not chars[name] then
				chars[name] = setmetatable({ [nk] = name }, charsmt)
			end
			-- These values will only update once per session. This could
			-- create minor confusion if someone changes faction, race, sex,
			-- or GUID while we're still logged in. Unlikely, but possible.
			if not gcache[name] then
				gcache[name] = {
					GC = class,
					GF = faction or nil,
					GR = race,
					GS = sex,
					GU = guid,
				}
				if xrp_cache[name] then
					for field, contents in pairs(gcache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrp_cache[name].fields[field] = contents
					end
				end
			end
			return chars[name]
		end
		return nil
	end,
	__newindex = function(self, unit, fields)
	end,
	__metatable = false,
})

local cachesmt = {
	__index = function(self, field)
		local name = self[nk]
		if gcache[name] and gcache[name][field] then
			return gcache[name][field]
		elseif xrp_cache[name] and xrp_cache[name].fields[field] then
			return xrp_cache[name].fields[field]
		end
		return nil
	end,
	__newindex = function(self, field, value)
	end,
	__call = function(self)
		local profile = {}
		for field, contents in pairs(xrp_cache[self[nk]].fields) do
			profile[field] = contents
		end
		return profile
	end,
	__metatable = false,
}

xrp.cache = setmetatable({}, {
	__index = function(self, name)
		if not caches[name] then
			caches[name] = setmetatable({ [nk] = name }, cachesmt)
		end
		return caches[name]
	end,
	__newindex = function(self, character, fields)
	end,
	__call = function(self)
		local out = {}
		for name, _ in xrp_cache do
			out[#out + 1] = name
		end
		return out
	end,
	__metatable = false,
})
