--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this program.  If not, see
	<http://www.gnu.org/licenses/>.
]]

local namekey = {}

local metacharacters = {}

local unitcache = {}

local charactermt = {
	__index = function(character, field)
		-- Any access to a field is treated as an implicit request to fetch
		-- it (but xrp.msp won't do it if it's fresh).
		xrp.msp:QueueRequest(character[namekey], field)
		if xrp_cache[character[namekey]] and xrp_cache[character[namekey]].fields[field] then
			return xrp_cache[character[namekey]].fields[field]
		elseif unitcache[character[namekey]] and unitcache[character[namekey]][field] then
			return unitcache[character[namekey]][field]
		elseif field == "NA" then
			return xrp:NameWithoutRealm(character[namekey])
		end
		return nil
	end,
	__newindex = function(character, field, value)
	end,
	__call = function(character, fields)
		if not fields then
			local profile = {}
			for field, contents in pairs(xrp_cache[character[namekey]].fields) do
				profile[field] = contents
			end
			return profile
		elseif type(fields) == "table" or type(fields) == "string" then
			xrp.msp:Request(character[namekey], fields)
		end
	end,
	__metatable = false,
}

xrp.characters = setmetatable({}, {
	__index = function (characters, name)
		if not metacharacters[name] then
			metacharacters[name] = setmetatable({ [namekey] = name }, charactermt)
		end
		return metacharacters[name]
	end,
	__newindex = function(characters, character, value)
	end,
	__call = function(characters)
		local out = {}
		for name, _ in xrp_cache do
			out[#out+1] = name
		end
	end,
	__metatable = false,
})

xrp.units = setmetatable({}, {
	__index = function (units, unit)
		name = xrp:UnitNameWithRealm(unit)
		if name then
			if not metacharacters[name] then
				metacharacters[name] = setmetatable({ [namekey] = name}, charactermt)
			end
			if not unitcache[name] then
				unitcache[name] = {
					GC = (select(2, UnitClass(unit))),
					GF = (UnitFactionGroup(unit)),
					GR = (select(2, UnitRace(unit))),
					GS = tostring(UnitSex(unit)),
					GU = UnitGUID(unit),
				}
				if xrp_cache[name] then
					for field, contents in pairs(unitcache[name]) do
						if not xrp_cache[name].fields[field] then
							xrp_cache[name].fields[field] = contents
							xrp_cache[name].time[field] = name == xrp.toon.withrealm and 2147483647 or 0
							xrp_cache[name].versions[field] = 0
						end
					end
				end
			end
			return metacharacters[name]
		end
		return nil
	end,
	__newindex = function (units, unit, value)
	end,
	__metatable = false,
})
