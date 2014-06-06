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

local clear = CreateFrame("Frame")
clear:Hide()

local safe = setmetatable({}, {
	__index = function(self, character)
		return 2
	end,
	__newindex = function(self, character, safelevel)
		rawset(self, character, safelevel)
		clear:Show() -- Resets every framedraw.
	end,
	__mode = "v",
	__metatable = false,
})

local request = setmetatable({}, {
	__index = function(self, character)
		return false
	end,
	__newindex = function(self, character, nocache)
		rawset(self, character, nocache and true or false)
		clear:Show() -- Resets every framedraw.
	end,
	__mode = "v",
	__metatable = false,
})

local function clear_OnUpdate(self, elapsed)
	wipe(safe)
	wipe(request)
	self:Hide()
end

local function clear_OnEvent(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN")
		IsItemInRange(44212, "player")
	end
end

clear:SetScript("OnUpdate", clear_OnUpdate)
clear:SetScript("OnEvent", clear_OnEvent)
clear:RegisterEvent("PLAYER_LOGIN")

local chars = setmetatable({}, weak)

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
		if request[name] and (not gcache[name] or not gcache[name].GF or gcache[name].GF == xrp.toon.fields.GF) then
			xrp.msp:QueueRequest(name, field, safe[name])
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
		if not name or name == "" then
			return nil
		end
		name = xrp:NameWithRealm(name)
		if not chars[name] then
			chars[name] = setmetatable({ [nk] = name }, charsmt)
		end
		request[name] = true
		return chars[name]
	end,
	__newindex = function(self, character, fields)
	end,
	__metatable = false,
})

-- TODO: Use UnitGUID()/GetPlayerInfoByGUID()?
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
				if xrp_cache[name] and name ~= xrp.toon.withrealm then
					for field, contents in pairs(gcache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrp_cache[name].fields[field] = contents
					end
				end
			elseif not gcache[name].GF then -- GUID won't always get faction.
				gcache[name].GF = (UnitFactionGroup(unit))
				if xrp_cache[name] and name ~= xrp.toon.withrealm then
					xrp_cache[name].fields.GF = gcache[name].GF
				end
			end
			-- Half-unsafe not within 100 yards, or are stealthed. We have their
			-- GUID, but they may not have ours.
			safe[name] = (IsItemInRange(44212, unit) ~= 1 or IsStealthed()) and 1 or 0
			-- Don't bother with requests to disconnected units.
			request[name] = UnitIsConnected(unit) and true or nil
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
		-- This will return nil if the GUID hasn't been seen by the client yet
		-- in the session.
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
				if xrp_cache[name] and name ~= xrp.toon.withrealm then
					for field, contents in pairs(gcache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrp_cache[name].fields[field] = contents
					end
				end
			end
			safe[name] = 1 -- We have their GUID, they may not have ours.
			request[name] = true
			return chars[name]
		end
		return nil
	end,
	__newindex = function(self, unit, fields)
	end,
	__metatable = false,
})

xrp.cache = setmetatable({}, {
	__index = function(self, name)
		if not name or name == "" then
			return nil
		end
		name = xrp:NameWithRealm(name)
		if not chars[name] then
			chars[name] = setmetatable({ [nk] = name }, charsmt)
		end
		return chars[name]
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
