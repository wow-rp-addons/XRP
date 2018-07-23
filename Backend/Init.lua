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

xrp = {}

_xrp.L = {}

local SUPPORTED_LANGUAGES = {
	enUS = "en",
	enGB = "en",
}
_xrp.language = SUPPORTED_LANGUAGES[GetLocale()] or "en"

_xrp.version = GetAddOnMetadata(FOLDER, "Version")
_xrp.DoNothing = function() end
_xrp.weakMeta = { __mode = "v" }
_xrp.weakKeyMeta = { __mode = "k" }

_xrp.own = {}

local events = {}
function _xrp.FireEvent(event, ...)
	if not events[event] then
		return false
	end
	for func, isFunc in pairs(events[event]) do
		xpcall(func, geterrorhandler(), event, ...)
	end
	return true
end
function xrp.HookEvent(event, func)
	if type(func) ~= "function" then
		return false
	elseif type(events[event]) ~= "table" then
		events[event] = {}
	elseif events[event][func] then
		return false
	end
	events[event][func] = true
	return true
end
function xrp.UnhookEvent(event, func)
	if not events[event] or not events[event][func] then
		return false
	end
	events[event][func] = nil
	return true
end

local frame = CreateFrame("Frame")
frame:Hide()

local gameEvents = {}
function _xrp.HookGameEvent(event, func, unit)
	if type(func) ~= "function" then
		return false
	elseif not gameEvents[event] then
		gameEvents[event] = {}
	elseif gameEvents[event][func] then
		return false
	end
	gameEvents[event][func] = true
	if not unit then
		frame:RegisterEvent(event)
	else
		frame:RegisterUnitEvent(event, unit)
	end
	return true
end
function _xrp.UnhookGameEvent(event, func)
	if not gameEvents[event] or not gameEvents[event][func] then
		return false
	end
	gameEvents[event][func] = nil
	if not next(gameEvents[event]) then
		gameEvents[event] = nil
		frame:UnregisterEvent(event)
	end
	return true
end
frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and ... ~= FOLDER then return end
	for func, isFunc in pairs(gameEvents[event]) do
		xpcall(func, geterrorhandler(), event, ...)
	end
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		gameEvents[event] = nil
		self:UnregisterEvent(event)
	end
end)

local VERSION_MATCH = "^(%d+)%.(%d+)%.(%d+)[%-]?(%l*)(%d*)"
local function CompareVersion(newVersion, oldVersion)
	if newVersion:find("dev", nil, true) then
		-- Never issue updates for git -dev versions.
		return -1
	end
	local newMajor, newMinor, newPatch, newType, newRevision = newVersion:match(VERSION_MATCH)
	local oldMajor, oldMinor, oldPatch, oldType, oldRevision = oldVersion:match(VERSION_MATCH)

	newType = newType == "alpha" and 1 or newType == "beta" and 2 or newType == "rc" and 3 or 4
	oldType = oldType == "alpha" and 1 or oldType == "beta" and 2 or oldType == "rc" and 3 or 4

	-- Account for pre-8.0 version scheme. Remove this sometime before hitting
	-- a 'real' 5.0 release.
	if tonumber(newMajor) > 4 then
		newPatch = newMinor
		newMinor = newMajor
		newMajor = "1"
	end

	local new = (tonumber(newMajor) * 1000000) + (tonumber(newMinor) * 10000) + (tonumber(newPatch) * 100) + (tonumber(newRevision) or 0)
	local old = (tonumber(oldMajor) * 1000000) + (tonumber(oldMinor) * 10000) + (tonumber(oldPatch) * 100) + (tonumber(oldRevision) or 0)

	if new <= old then
		return -1
	elseif newType < oldType then
		return 0
	end
	return 1
end

function _xrp.AddonUpdate(version)
	if not version or version == _xrp.version or version == _xrp.settings.newversion then return end
	if CompareVersion(version, _xrp.settings.newversion or _xrp.version) >= 0 then
		_xrp.settings.newversion = version
	end
end

_xrp.HookGameEvent("ADDON_LOADED", function(event, addon)
	_xrp.playerWithRealm = xrp.UnitFullName("player")
	_xrp.player, _xrp.realm = _xrp.playerWithRealm:match("^([^%-]+)%-([^%-]+)$")
	_xrp.SavedVariableSetup()

	local addonString = "%s/%s"
	local VA = { addonString:format(FOLDER, _xrp.version) }
	for i, addon in ipairs({ "GHI", "Tongues" }) do
		if IsAddOnLoaded(addon) then
			VA[#VA + 1] = addonString:format(addon, GetAddOnMetadata(addon, "Version"))
		end
	end
	local newFields = {
		NA = _xrp.player, -- Fallback NA field.
		VA = table.concat(VA, ";"),
	}
	local fields = xrpSaved.meta.fields
	for field, contents in pairs(newFields) do
		if contents ~= fields[field] then
			fields[field] = contents
			_xrp.FireEvent("UPDATE", field)
		end
	end

	if not xrpSaved.overrides.logout or xrpSaved.overrides.logout + 900 < time() then
		xrpSaved.overrides.fields = {}
	end
	xrpSaved.overrides.logout = nil

	if _xrp.settings.cacheAutoClean then
		_xrp.CacheTidy(nil, true)
	end

	_xrp.LoadSettings()

	if _xrp.settings.newversion then
		local update = CompareVersion(_xrp.settings.newversion, _xrp.version)
		local now = time()
		if update == 1 and (not _xrp.settings.versionwarning or _xrp.settings.versionwarning < now - 21600) then
			C_Timer.After(8, function()
				print(_xrp.L.NEW_VERSION:format(_xrp.settings.newversion))
				_xrp.settings.versionwarning = now
			end)
		elseif update == -1 then
			_xrp.settings.newversion = nil
			_xrp.settings.versionwarning = nil
		end
	end
end)
_xrp.HookGameEvent("PLAYER_LOGIN", function(event)
	_xrp.FireEvent("UPDATE")
	-- GetAutoCompleteResults() doesn't work before PLAYER_LOGIN.
	_xrp.own[_xrp.playerWithRealm] = true
	if xrpCache[_xrp.playerWithRealm] and not xrpCache[_xrp.playerWithRealm].own then
		xrpCache[_xrp.playerWithRealm].own = true
	end
	for i, character in ipairs(GetAutoCompleteResults("", 0, 1, AUTO_COMPLETE_ACCOUNT_CHARACTER, 0)) do
		local name = xrp.FullName(character.name)
		_xrp.own[name] = true
		if xrpCache[name] and not xrpCache[name].own then
			xrpCache[name].own = true
		end
	end
	for name, data in pairs(xrpCache) do
		if data.own and not _xrp.own[name] and name:match("%-([^%-]+)$") == _xrp.realm then
			data.own = nil
		end
	end
end)
_xrp.HookGameEvent("PLAYER_LOGOUT", function(event)
	-- Note: This code must be thoroughly tested if any changes are
	-- made. If there are any errors in here, they are not visible in
	-- any manner in-game.
	if next(xrpSaved.overrides.fields) then
		xrpSaved.overrides.logout = time()
	end
end)
