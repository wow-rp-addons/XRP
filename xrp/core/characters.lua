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

local addonName, private = ...

local nonewindex = function() end
local weak = { __mode = "v" }
local gcache = setmetatable({}, weak)

local ck, rk = {}, {}
local character_mt

do
	local fields_mt = {
		__index = function(self, field)
			if private.fields.dummy[field] or not field:find("^%u%u$") then
				return nil
			end
			local character = self[ck]
			if character == xrp.toon then
				return xrp.current.fields[field]
			end
			-- Any access to a field is treated as an implicit request to fetch
			-- it (but msp won't do it if it's fresh, and will compile quick,
			-- successive requests into one go). Also try avoiding requests
			-- when we absolutely know they will fail. Never request data we
			-- already have, and know is good.
			if gcache[character] and gcache[character][field] then
				return gcache[character][field]
			end
			if self[rk] then
				private:QueueRequest(character, field)
			end
			if xrpCache[character] and xrpCache[character].fields[field] then
				return xrpCache[character].fields[field]
			end
			return nil
		end,
		__newindex = nonewindex,
		__metatable = false,
	}

	character_mt = {
		__index = function(self, component)
			local character = self[ck]
			if component == "fields" then
				rawset(self, "fields", setmetatable({ [ck] = character, [rk] = self[rk] }, fields_mt))
				return self.fields
			elseif component == "bookmark" then
				if not xrpCache[character] then
					return nil
				end
				return xrpCache[character].bookmark
			elseif component == "hide" then
				if not xrpCache[character] then
					return nil
				end
				return xrpCache[character].hide
			elseif component == "own" then
				if not xrpCache[character] then
					return nil
				end
				return xrpCache[character].own
			end
		end,
		__newindex = function(self, component, value)
			local character = self[ck]
			if not xrpCache[character] then return end
			if component == "bookmark" then
				if value and not xrpCache[character].bookmark then
					xrpCache[character].bookmark = time()
				elseif not value and xrpCache[character].bookmark then
					xrpCache[character].bookmark = nil
				end
			elseif component == "hide" then
				if value and not xrpCache[character].hide then
					xrpCache[character].hide = true
				elseif not value and xrpCache[character].hide then
					xrpCache[character].hide = nil
				end
			end
		end,
		__metatable = false,
	}
end

do
	local characters = setmetatable({}, weak)
	xrp.characters = setmetatable({}, {
		__index = function(self, character)
			character = xrp:NameWithRealm(character)
			if not character then
				return nil
			end
			if not characters[character] then
				characters[character] = setmetatable({ [ck] = character, [rk] = true }, character_mt)
			end
			return characters[character]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})

	xrp.units = setmetatable({}, {
		__index = function (self, unit)
			local character = xrp:UnitNameWithRealm(unit)
			if not character then
				return nil
			end
			-- These values may only update once per session (varying with
			-- garbage collection). This could create minor confusion if
			-- someone changes faction, race, sex, or GUID while we're still
			-- logged in. Unlikely, but possible.
			if not gcache[character] then
				local GU = UnitGUID(unit)
				local class, GC, race, GR, GS = GetPlayerInfoByGUID(GU)
				gcache[character] = {
					GC = GC,
					GF = UnitFactionGroup(unit),
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrpCache[character] and character ~= xrp.toon then
					for field, contents in pairs(gcache[character]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrpCache[character].fields[field] = contents
					end
				end
			elseif not gcache[character].GF then -- GUID won't always get faction.
				gcache[character].GF = UnitFactionGroup(unit)
				if xrpCache[character] and character ~= xrp.toon then
					xrpCache[character].fields.GF = gcache[character].GF
				end
			end
			if not characters[character] then
				characters[character] = setmetatable({ [ck] = character, [rk] = true }, character_mt)
			end
			return characters[character]
		end,
		__newindex = nonewindex,
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
		Pandaren = nil, -- Can't tell faction.
	}

	xrp.guids = setmetatable({}, {
		__index = function (self, GU)
			-- This will return nil if the GUID hasn't been seen by the client
			-- yet in the session.
			local class, GC, race, GR, GS, character, realm = GetPlayerInfoByGUID(GU)
			character = xrp:NameWithRealm(character, realm)
			if not character or character == "" then
				return nil
			end
			-- These values may only update once per session (varying with
			-- garbage collection). This could create minor confusion if
			-- someone changes faction, race, sex, or GUID while we're still
			-- logged in. Unlikely, but possible.
			if not gcache[character] then
				gcache[character] = {
					GC = GC,
					GF = race_faction[GR],
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrpCache[character] and character ~= xrp.toon then
					for field, contents in pairs(gcache[character]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrpCache[character].fields[field] = contents
					end
				end
			end
			if not characters[character] then
				characters[character] = setmetatable({ [ck] = character, [rk] = true }, character_mt)
			end
			return characters[character]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end

do
	local characters = setmetatable({}, weak)
	xrp.cache = setmetatable({}, {
		__index = function(self, character)
			if not character or character == "" then
				return nil
			end
			character = xrp:NameWithRealm(character)
			if not characters[character] then
				characters[character] = setmetatable({ [ck] = character, [rk] = false }, character_mt)
			end
			return characters[character]
		end,
		__newindex = nonewindex,
		__call = function(self)
			local out = {}
			for character, _ in pairs(xrpCache) do
				out[#out + 1] = character
			end
			table.sort(out)
			return out
		end,
		__metatable = false,
	})
end
