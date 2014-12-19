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

if msp ~= nil then return end

local addonName, xrpPrivate = ...

-- This file provides emulation of reference LibMSP for XRP. This is used by
-- some addons (such as GHI) to interact with a RP profile. For the most part,
-- this is read-only. msp.my (current profile) is writable, but only sets an
-- override value and cannot actually modify stored profiles.
--
-- Note that this is somewhat limited -- to keep the complexity low, it only
-- interacts with the cached values, rather than the standard xrp.characters
-- table which will run requests automatically. Doing so also makes it behave
-- more like reference LibMSP.

local msp = {}
msp.version = 9 -- Let's just say we're 9.
msp.versionx = 1 -- ...and version 1 LibMSPX.
msp.protocolversion = xrpPrivate.msp

-- Run MSP callbacks with appropriate arguments on XRP events.
msp.callback = {
	received = {},
}

xrp:HookEvent("RECEIVE", function(event, character)
	for _, func in ipairs(msp.callback.received) do
		pcall(func, character)
		local ambiguated = Ambiguate(character, "none")
		if ambiguated ~= character then
			-- Some unmaintained code expects names without realms for
			-- same-realm.
			pcall(func, ambiguated)
		end
	end
end)

local nk = {} -- Used to hide character names inside table.

local noFunc = function() end

local mspChars = setmetatable({}, { __mode = "v" })

local fieldMeta = {
	__index = function(self, field)
		return xrpCache[self[nk]].fields[field] or ""
	end,
	__newindex = noFunc,
	__metatable = false,
}

local verMeta = {
	__index = function(self, field)
		return xrpCache[self[nk]].versions[field]
	end,
	__newindex = noFunc,
	__metatable = false,
}

local loadTime = GetTime()
local timeTable = setmetatable({}, {
	__index = function()
		return loadTime -- Worst-case scenario, they re-run msp:Request().
	end,
	__newindex = noFunc,
	__metatable = false,
})

local emptyMeta = { __newindex = noFunc, __metatable = false, }
local emptyTable = setmetatable({}, emptyMeta)

local emptychar = setmetatable({
	field = setmetatable({}, { __index = function() return "" end, __newindex = noFunc, __metatable = false, }),
	ver = emptyTable,
	time = emptyTable,
}, emptyMeta)

-- Some addons try to mess with the frames we don't actually have.
msp.dummyframe = {
	RegisterEvent = noFunc,
	UnregisterEvent = noFunc,
}
msp.dummyframex = msp.dummyframe

msp.char = setmetatable({}, {
	__index = function (self, character)
		local name = xrp:NameWithRealm(character) -- For pre-5.4.7 addons.
		if xrpCache[name] then
			mspChars[name] = { field = setmetatable({ [nk] = name }, fieldMeta), ver = setmetatable({ [nk] = name }, verMeta), time = timeTable, }
			return mspChars[name]
		end
		return emptychar -- LibMSP never returns nil.
	end,
	__newindex = noFunc,
	__metatable = false,
})

msp.my = setmetatable({}, {
	__index = function(self, field)
		-- Return currently active profile field (incl. overrides).
		return xrp.current.fields[field]
	end,
	__newindex = function(self, field, contents)
		-- Sets a temporary override. Removes if empty string (unlike normal
		-- overrides allowing explicitly empty).
		xrp.current.fields[field] = contents ~= "" and contents or nil
	end,
	__metatable = false,
})

-- Allows reading versions, but will not allow modifying them. XRP handles
-- that entirely automatically.
msp.myver = setmetatable({}, {
	__index = function(self, field)
		return xrp.current.versions[field]
	end,
	__newindex = noFunc,
	__metatable = false,
})

function msp:Request(character, fields)
	if not fields then
		fields = { "TT" }
	elseif type(fields) == "string" then
		fields = { fields }
	elseif type(fields) ~= "table" then
		return false
	end
	return xrpPrivate:Request(xrp:NameWithRealm(character), fields)
end

function msp:NameWithRealm(...)
	return xrp:NameWithRealm(...)
end

-- Used by GHI... Working with the cache since GHI expects values to be
-- present if we know about someone. Real weird, since this is all-but-
-- explicitly noted as an internal LibMSP function in the library...
function msp:PlayerKnownAbout(character)
	return xrpCache[character] ~= nil
end

-- Dummy function. Updates are processed as they're set in XRP. Benefits of
-- a more tightly-integrated MSP implementation.
function msp:Update()
	return false
end

-- Dummy function. Pushing to others isn't supported in XRP.
function msp:Send()
	return 0
end

_G.msp = msp
