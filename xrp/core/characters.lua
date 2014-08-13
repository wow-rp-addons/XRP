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

-- This makes sure the client has the item data cached to allow range checking.
xrp:HookLogin(function()
	IsItemInRange(44212, "player")
end)

local nonewindex = function() end
local weak = { __mode = "v" }
local gcache = setmetatable({}, weak)

local nk, rk, sk = {}, {}, {}

local charsmt = {
	__index = function(self, field)
		if xrp.fields.dummy[field] or not field:find("^%u%u$") then
			return nil
		end
		local name = self[nk]
		-- Any access to a field is treated as an implicit request to fetch
		-- it (but msp won't do it if it's fresh, and will compile quick,
		-- successive requests into one go). Also try avoiding requests when
		-- we absolutely know they will fail. Never request data we already
		-- have, and know is good.
		if gcache[name] and gcache[name][field] then
			return gcache[name][field]
		end
		local request = self[rk]
		if request and (not gcache[name] or not gcache[name].GF or gcache[name].GF == xrp.toon.fields.GF) then
			xrp:QueueRequest(name, field, self[sk])
		elseif request and gcache[name] and gcache[name].GF ~= xrp.toon.fields.GF and gcache[name].GF ~= "Neutral" then
			xrp:FireEvent("MSP_FAIL", name, "faction")
		end
		if xrp_cache[name] and xrp_cache[name].fields[field] then
			return xrp_cache[name].fields[field]
		end
		return nil
	end,
	__newindex = nonewindex,
	__call = function(self)
		local profile = {}
		for field, contents in pairs(xrp_cache[self[nk]].fields) do
			profile[field] = contents
		end
		return profile
	end,
	__metatable = false,
}
do
	local chars = setmetatable({}, weak)
	xrp.characters = setmetatable({}, {
		__index = function(self, name)
			name = xrp:NameWithRealm(name)
			if not name then
				return nil
			end
			if not chars[name] then
				chars[name] = setmetatable({ [nk] = name, [rk] = true, [sk] = 2 }, charsmt)
			end
			return chars[name]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end

do
	local chars = setmetatable({}, weak)
	xrp.units = setmetatable({}, {
		__index = function (self, unit)
			local name = xrp:UnitNameWithRealm(unit)
			if not name then
				return nil
			end
			-- These values may only update once per session (varying with
			-- garbage collection). This could create minor confusion if
			-- someone changes faction, race, sex, or GUID while we're still
			-- logged in. Unlikely, but possible.
			if not gcache[name] then
				local GU = UnitGUID(unit)
				local class, GC, race, GR, GS = GetPlayerInfoByGUID(GU)
				gcache[name] = {
					GC = GC,
					GF = UnitFactionGroup(unit),
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrp_cache[name] and name ~= xrp.toon.withrealm then
					for field, contents in pairs(gcache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrp_cache[name].fields[field] = contents
					end
				end
			elseif not gcache[name].GF then -- GUID won't always get faction.
				gcache[name].GF = UnitFactionGroup(unit)
				if xrp_cache[name] and name ~= xrp.toon.withrealm then
					xrp_cache[name].fields.GF = gcache[name].GF
				end
			end
			-- Don't bother with requests to disconnected units.
			local request = UnitIsConnected(unit) == 1
			if not request then
				xrp:FireEvent("MSP_FAIL", name, "offline")
			end
			-- Half-unsafe if we're not within 100 yards, or we are stealthed.
			-- We have their GUID, but they may not have ours.
			local safe = (IsItemInRange(44212, unit) ~= 1 or IsStealthed()) and 1 or 0
			if not chars[name] then
				chars[name] = setmetatable({ [nk] = name, [rk] = request, [sk] = safe }, charsmt)
			else
				chars[name][rk] = request
				chars[name][sk] = safe
			end
			return chars[name]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end

do
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
		Pandaren = nil, -- Can't tell faction.
	}

	local chars = setmetatable({}, weak)
	xrp.guids = setmetatable({}, {
		__index = function (self, GU)
			-- This will return nil if the GUID hasn't been seen by the client
			-- yet in the session.
			local class, GC, race, GR, GS, name, realm = GetPlayerInfoByGUID(GU)
			name = xrp:NameWithRealm(name, realm)
			if not name or name == "" then
				return nil
			end
			-- These values may only update once per session (varying with
			-- garbage collection). This could create minor confusion if
			-- someone changes faction, race, sex, or GUID while we're still
			-- logged in. Unlikely, but possible.
			if not gcache[name] then
				gcache[name] = {
					GC = GC,
					GF = race_faction[GR],
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrp_cache[name] and name ~= xrp.toon.withrealm then
					for field, contents in pairs(gcache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrp_cache[name].fields[field] = contents
					end
				end
			end
			if not chars[name] then
				chars[name] = setmetatable({ [nk] = name, [rk] = true, [sk] = 1 }, charsmt)
			end
			return chars[name]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end

do
	local chars = setmetatable({}, weak)
	xrp.cache = setmetatable({}, {
		__index = function(self, name)
			if not name or name == "" then
				return nil
			end
			name = xrp:NameWithRealm(name)
			if not chars[name] then
				chars[name] = setmetatable({ [nk] = name, [rk] = false }, charsmt)
			end
			return chars[name]
		end,
		__newindex = nonewindex,
		__call = function(self)
			local out = {}
			for name, _ in pairs(xrp_cache) do
				out[#out + 1] = name
			end
			table.sort(out)
			return out
		end,
		__metatable = false,
	})
end
