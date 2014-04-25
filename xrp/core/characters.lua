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

local chars = setmetatable({}, { __mode = "v" })

local gcache = setmetatable({}, { __mode = "v" })

local charmt = {
	__index = function(character, field)
		-- Any access to a field is treated as an implicit request to fetch
		-- it (but xrp.msp won't do it if it's fresh, and will compile quick,
		-- successive requests into one go). If the unit table's been used and
		-- the target is not our faction, don't run a request.
		if not gcache[character[nk]] or (gcache[character[nk]] and gcache[character[nk]].GF == xrp.toon.fields.GF) then
			xrp.msp:QueueRequest(character[nk], field)
		end
		if xrp_cache[character[nk]] and xrp_cache[character[nk]].fields[field] then
			return xrp_cache[character[nk]].fields[field]
		elseif gcache[character[nk]] and gcache[character[nk]][field] then
			return gcache[character[nk]][field]
		end
		return nil
	end,
	__newindex = function(character, field, value)
	end,
	__call = function(character, fields)
		if not fields then
			local profile = {}
			for field, contents in pairs(xrp_cache[character[nk]].fields) do
				profile[field] = contents
			end
			return profile
		elseif type(fields) == "table" or type(fields) == "string" then
			xrp.msp:Request(character[nk], fields)
		end
	end,
	__metatable = false,
}

xrp.characters = setmetatable({}, {
	__index = function (characters, name)
		if not chars[name] then
			chars[name] = setmetatable({ [nk] = name }, charmt)
		end
		return chars[name]
	end,
	__newindex = function(characters, character, value)
	end,
	__call = function(characters)
		local out = {}
		for name, _ in xrp_cache do
			out[#out + 1] = name
		end
	end,
	__metatable = false,
})

xrp.units = setmetatable({}, {
	__index = function (units, unit)
		if not UnitIsPlayer(unit) then
			return nil
		end
		local name = xrp:UnitNameWithRealm(unit)
		if type(name) == "string" then
			if not chars[name] then
				chars[name] = setmetatable({ [nk] = name }, charmt)
			end
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
						if not xrp_cache[name].fields[field] then
							xrp_cache[name].fields[field] = contents
						end
					end
				end
			end
			return chars[name]
		end
		return nil
	end,
	__newindex = function (units, unit, value)
	end,
	__metatable = false,
})
