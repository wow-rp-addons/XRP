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

local ck, rk, sk = {}, {}, {}

local charsmt = {
	__index = function(self, field)
		if xrp.fields.dummy[field] or not field:find("^%u%u$") then
			return nil
		end
		local character = self[ck]
		if character == xrp.toon then
			return xrp.current.fields[field]
		end
		-- Any access to a field is treated as an implicit request to fetch
		-- it (but msp won't do it if it's fresh, and will compile quick,
		-- successive requests into one go). Also try avoiding requests when
		-- we absolutely know they will fail. Never request data we already
		-- have, and know is good.
		if gcache[character] and gcache[character][field] then
			return gcache[character][field]
		end
		local request = self[rk]
		if request and (not gcache[character] or not gcache[character].GF or gcache[character].GF == xrpSaved.meta.fields.GF) then
			xrp:QueueRequest(character, field, self[sk])
		elseif request and gcache[character] and gcache[character].GF ~= xrpSaved.meta.fields.GF and gcache[character].GF ~= "Neutral" then
			xrp:FireEvent("MSP_FAIL", character, "faction")
		end
		if xrpCache[character] and xrpCache[character].fields[field] then
			return xrpCache[character].fields[field]
		end
		return nil
	end,
	__newindex = nonewindex,
	__metatable = false,
}
do
	local chars = setmetatable({}, weak)
	xrp.characters = setmetatable({}, {
		__index = function(self, character)
			character = xrp:NameWithRealm(character)
			if not character then
				return nil
			end
			if not chars[character] then
				chars[character] = setmetatable({ [ck] = character, [rk] = true, [sk] = 2 }, charsmt)
			end
			return chars[character]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end

do
	local chars = setmetatable({}, weak)
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
			-- Don't bother with requests to disconnected units.
			local request = UnitIsConnected(unit) == 1
			if not request then
				xrp:FireEvent("MSP_FAIL", character, "offline")
			end
			-- Half-unsafe if we're not within 100 yards, or we are stealthed.
			-- We have their GUID, but they may not have ours.
			local safe = (IsItemInRange(44212, unit) ~= 1 or IsStealthed()) and 1 or 0
			if not chars[character] then
				chars[character] = setmetatable({ [ck] = character, [rk] = request, [sk] = safe }, charsmt)
			else
				chars[character][rk] = request
				chars[character][sk] = safe
			end
			return chars[character]
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
			if not chars[character] then
				chars[character] = setmetatable({ [ck] = character, [rk] = true, [sk] = 1 }, charsmt)
			end
			return chars[character]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end

do
	local chars = setmetatable({}, weak)
	xrp.cache = setmetatable({}, {
		__index = function(self, character)
			if not character or character == "" then
				return nil
			end
			character = xrp:NameWithRealm(character)
			if not chars[character] then
				chars[character] = setmetatable({ [ck] = character, [rk] = false }, charsmt)
			end
			return chars[character]
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

xrp.bookmarks = setmetatable({}, {
	__index = function (self, character)
		character = xrp:NameWithRealm(character)
		if not character or not xrpCache[character] then
			return nil
		end
		return xrpCache[character].own and 0 or xrpCache[character].bookmark
	end,
	__newindex = function(self, character, bookmark)
		character = xrp:NameWithRealm(character)
		if not character or not xrpCache[character] then
			return nil
		end
		if bookmark and not xrpCache[character].bookmark then
			xrpCache[character].bookmark = time()
		elseif not bookmark and xrpCache[character].bookmark then
			xrpCache[character].bookmark = nil
		end
	end,
	__metatable = false,
})
