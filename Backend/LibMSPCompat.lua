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

local FOLDER, _xrp = ...

if msp_RPAddOn ~= GetAddOnMetadata(FOLDER, "Title") then return end

-- This file provides emulation of reference LibMSP for XRP. This is used by
-- some addons (such as GHI) to interact with a RP profile. For the most part,
-- this is read-only. msp.my (current profile) is writable, but only sets an
-- override value and cannot actually modify stored profiles.
--
-- Note that this is somewhat limited -- to keep the complexity low, it only
-- interacts with the cached values, rather than the standard xrp.characters
-- table which will run requests automatically. Doing so also makes it behave
-- more like reference LibMSP.

if msp then
	if msp.versionx then
		-- libmspx
		msp.dummyframex:UnregisterAllEvents()
	else
		-- LibMSP
		msp.dummyframe:UnregisterAllEvents()
	end
	table.wipe(msp)
else
	msp = {}
end

-- XRP is active and the in-control RP addon, so we really don't want other
-- versions of MSP overwriting this.
msp.version = 999
msp.versionx = 999
msp.protocolversion = _xrp.msp

-- Run MSP callbacks with appropriate arguments on XRP events.
msp.callback = {
	received = {},
}

local SafeCall = _xrp.SafeCall
xrp.HookEvent("RECEIVE", function(event, name)
	for i, func in ipairs(msp.callback.received) do
		SafeCall(func, name)
		local ambiguated = Ambiguate(name, "none")
		if ambiguated ~= name then
			-- Some unmaintained code expects names without realms for
			-- same-realm.
			SafeCall(func, ambiguated)
		end
	end
end)

local nameMap = setmetatable({}, _xrp.weakKeyMeta)

local mspChars = setmetatable({}, _xrp.weakMeta)

local fieldMeta = {
	__index = function(self, field)
		local name = nameMap[self]
		if name == _xrp.playerWithRealm then
			return xrp.current[field]
		end
		return xrpCache[name] and xrpCache[name].fields[field] or ""
	end,
	__newindex = _xrp.DoNothing,
	__metatable = false,
}

local verMeta = {
	__index = function(self, field)
		local name = nameMap[self]
		if name == _xrp.playerWithRealm then
			return _xrp.versions[field]
		end
		return xrpCache[name] and xrpCache[name].versions[field]
	end,
	__newindex = _xrp.DoNothing,
	__metatable = false,
}

local loadTime = GetTime()
local timeTable = setmetatable({}, {
	__index = function()
		return loadTime -- Worst-case scenario, they re-run msp:Request().
	end,
	__newindex = _xrp.DoNothing,
	__metatable = false,
})

local emptyMeta = { __newindex = _xrp.DoNothing, __metatable = false, }
local emptyTable = setmetatable({}, emptyMeta)

local emptyChar = setmetatable({
	field = setmetatable({}, { __index = function() return "" end, __newindex = _xrp.DoNothing, __metatable = false, }),
	ver = emptyTable,
	time = emptyTable,
}, emptyMeta)

-- Some addons try to mess with the frames we don't actually have.
msp.dummyframe = {
	RegisterEvent = _xrp.DoNothing,
	UnregisterEvent = _xrp.DoNothing,
}
msp.dummyframex = msp.dummyframe

msp.char = setmetatable({}, {
	__index = function(self, name)
		name = xrp.FullName(name) -- For pre-5.4.7 addons.
		if xrpCache[name] then
			local character = { field = setmetatable({}, fieldMeta), ver = setmetatable({}, verMeta), time = timeTable, }
			nameMap[character.field] = name
			nameMap[character.ver] = name
			mspChars[name] = character
			return mspChars[name]
		end
		return emptyChar -- LibMSP never returns nil.
	end,
	__newindex = _xrp.DoNothing,
	__metatable = false,
})

msp.my = setmetatable({}, {
	__index = function(self, field)
		-- Return currently active profile field (incl. overrides).
		return xrp.current[field]
	end,
	__newindex = function(self, field, contents)
		-- Sets a temporary override. Removes if empty string (unlike normal
		-- overrides allowing explicitly empty).
		xrp.current[field] = contents ~= "" and contents or nil
	end,
	__metatable = false,
})

-- Allows reading versions, but will not allow modifying them. XRP handles
-- that entirely automatically.
msp.myver = setmetatable({}, {
	__index = function(self, field)
		return _xrp.versions[field]
	end,
	__newindex = _xrp.DoNothing,
	__metatable = false,
})

function msp:Request(name, fields)
	if not fields then
		fields = { "TT" }
	elseif type(fields) == "string" then
		fields = { fields }
	elseif type(fields) ~= "table" then
		return false
	end
	return _xrp.Request(xrp.FullName(name), fields)
end

-- Used by GHI.
function msp:PlayerKnownAbout(name)
	name = xrp.FullName(name)
	return name == _xrp.playerWithRealm or xrpCache[name] ~= nil
end

-- Dummy function. Updates are processed as they're set in XRP.
function msp:Update()
	return false
end

-- Dummy function. Pushing to others isn't supported in XRP.
function msp:Send()
	return 0, 0
end

setmetatable(msp, {
	__newindex = _xrp.DoNothing,
	__metatable = false,
})
