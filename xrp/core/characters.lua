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

local safe, request
do
	local clear = CreateFrame("Frame")

	safe = setmetatable({}, {
		__index = function(self, character)
			return 2
		end,
		__newindex = function(self, character, safelevel)
			rawset(self, character, safelevel)
			clear:Show() -- Resets every framedraw.
		end,
		__mode = "v",
	})

	request = setmetatable({}, {
		__index = function(self, character)
			return false
		end,
		__newindex = function(self, character, nocache)
			rawset(self, character, nocache and true or false)
			clear:Show() -- Resets every framedraw.
		end,
		__mode = "v",
	})

	clear:Hide()
	clear:SetScript("OnUpdate", function(self, elapsed)
		wipe(safe)
		wipe(request)
		self:Hide()
	end)

	clear:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			IsItemInRange(44212, "player")
			self:UnregisterAllEvents()
			self:SetScript("OnEvent", nil)
		end
	end)
	clear:RegisterEvent("PLAYER_LOGIN")
end

local chars, gcache
do
	local weak = { __mode = "v" }

	chars = setmetatable({}, weak)
	gcache = setmetatable({}, weak)
end

local nonewindex = function() end

local nk = {}

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
		elseif request[name] and gcache[name] and gcache[name].GF ~= xrp.toon.fields.GF then
			xrp:FireEvent("MSP_FAIL", name, "faction")
		end
		if xrp_cache[name] and xrp_cache[name].fields[field] then
			return xrp_cache[name].fields[field]
		end
		return nil
	end,
	__newindex = nonewindex,
	__call = function(self, request)
		local profile = {}
		for field, contents in pairs(xrp_cache[self[nk]].fields) do
			profile[field] = contents
		end
		return profile
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
	__newindex = nonewindex,
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
				local GU = UnitGUID(unit)
				local class, GC, race, GR, GS = GetPlayerInfoByGUID(GU)
				gcache[name] = {
					GC = GC,
					GF = UnitFactionGroup(unit),
					GR = GR,
					GS = GS,
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
			-- Half-unsafe if we're not within 100 yards, or we are stealthed.
			-- We have their GUID, but they may not have ours.
			safe[name] = (IsItemInRange(44212, unit) ~= 1 or IsStealthed()) and 1 or 0
			-- Don't bother with requests to disconnected units.
			if not UnitIsConnected(unit) then
				request[name] = nil
				xrp:FireEvent("MSP_FAIL", name, "offline")
			else
				request[name] = true
			end
			return chars[name]
		end
		return nil
	end,
	__newindex = nonewindex,
	__metatable = false,
})

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
		Pandaren = false, -- Can't tell faction.
	}

	xrp.guids = setmetatable({}, {
		__index = function (self, GU)
			-- This will return nil if the GUID hasn't been seen by the client yet
			-- in the session.
			local class, GC, race, GR, GS, name, realm = GetPlayerInfoByGUID(GU)
			if not name or name == "" then
				return nil
			end
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
						GC = GC,
						GF = race_faction[GR],
						GR = GR,
						GS = GS,
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
				safe[name] = 1 -- We have their GUID, they may not have ours.
				request[name] = true
				return chars[name]
			end
			return nil
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end

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
	__newindex = nonewindex,
	__call = function(self)
		local out = {}
		for name, _ in xrp_cache do
			out[#out + 1] = name
		end
		return out
	end,
	__metatable = false,
})
