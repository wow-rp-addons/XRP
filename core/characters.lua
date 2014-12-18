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

local noFunc = function() end
local weak = { __mode = "v" }
local gCache = setmetatable({}, weak)

local ck, rk = {}, {}
local characterMeta

do
	local fieldsMeta = {
		__index = function(self, field)
			if xrpPrivate.fields.dummy[field] or not field:find("^%u%u$") then
				return nil
			end
			local character = self[ck]
			if character == xrpPrivate.playerWithRealm then
				return xrp.current.fields[field]
			end
			-- Any access to a field is treated as an implicit request to fetch
			-- it (but msp won't do it if it's fresh, and will compile quick,
			-- successive requests into one go). Also try avoiding requests
			-- when we absolutely know they will fail. Never request data we
			-- already have, and know is good.
			if gCache[character] and gCache[character][field] then
				return gCache[character][field]
			end
			if self[rk] then
				xrpPrivate:QueueRequest(character, field)
			end
			if xrpCache[character] and xrpCache[character].fields[field] then
				return xrpCache[character].fields[field]
			end
			return nil
		end,
		__newindex = noFunc,
		__metatable = false,
	}

	characterMeta = {
		__index = function(self, component)
			local character = self[ck]
			if component == "fields" then
				rawset(self, "fields", setmetatable({ [ck] = character, [rk] = self[rk] }, fieldsMeta))
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
				characters[character] = setmetatable({ [ck] = character, [rk] = true }, characterMeta)
			end
			return characters[character]
		end,
		__newindex = noFunc,
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
			if not gCache[character] then
				local GU = UnitGUID(unit)
				local class, GC, race, GR, GS = GetPlayerInfoByGUID(GU)
				gCache[character] = {
					GC = GC,
					GF = UnitFactionGroup(unit),
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrpCache[character] and character ~= xrpPrivate.playerWithRealm then
					for field, contents in pairs(gCache[character]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrpCache[character].fields[field] = contents
					end
				end
			elseif not gCache[character].GF then -- GUID won't always get faction.
				gCache[character].GF = UnitFactionGroup(unit)
				if xrpCache[character] and character ~= xrpPrivate.playerWithRealm then
					xrpCache[character].fields.GF = gCache[character].GF
				end
			end
			if not characters[character] then
				characters[character] = setmetatable({ [ck] = character, [rk] = true }, characterMeta)
			end
			return characters[character]
		end,
		__newindex = noFunc,
		__metatable = false,
	})

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
			if not gCache[character] then
				gCache[character] = {
					GC = GC,
					GF = RACE_FACTION[GR],
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrpCache[character] and character ~= xrpPrivate.playerWithRealm then
					for field, contents in pairs(gCache[character]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrpCache[character].fields[field] = contents
					end
				end
			end
			if not characters[character] then
				characters[character] = setmetatable({ [ck] = character, [rk] = true }, characterMeta)
			end
			return characters[character]
		end,
		__newindex = noFunc,
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
				characters[character] = setmetatable({ [ck] = character, [rk] = false }, characterMeta)
			end
			return characters[character]
		end,
		__newindex = noFunc,
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
