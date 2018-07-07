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

local function SafeCall(func, ...)
	local success, message = pcall(func, ...)
	if not success then
		geterrorhandler()(message)
	end
end
_xrp.SafeCall = SafeCall

local events = {}
function _xrp.FireEvent(event, ...)
	if not events[event] then
		return false
	end
	for func, isFunc in pairs(events[event]) do
		SafeCall(func, event, ...)
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
		SafeCall(func, event, ...)
	end
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		gameEvents[event] = nil
		self:UnregisterEvent(event)
	end
end)

local function CompareVersion(newVersion, oldVersion)
	local newMajor, newMinor, newPatch, newAddOn, newRelType, newRelRev = newVersion:match("(%d+)%.(%d+)%.(%d+)%.?(%d*)[%_%-]?(%l*)(%d*)")
	local oldMajor, oldMinor, oldPatch, oldAddOn, oldRelType, oldRelRev = oldVersion:match("(%d+)%.(%d+)%.(%d+)%.?(%d*)[%_%-]?(%l*)(%d*)")

	newRelType = (newRelType == "alpha" or newRelType == "a") and 1 or (newRelType == "beta" or oldRelType == "b") and 2 or newRelType == "rc" and 3 or 4
	oldRelType = (oldRelType == "alpha" or oldRelType == "a") and 1 or (oldRelType == "beta" or oldRelType == "b") and 2 or oldRelType == "rc" and 3 or 4

	local newWoW = (tonumber(newMajor) * 1000000) + (tonumber(newMinor) * 10000) + (tonumber(newPatch) * 100)
	local oldWoW = (tonumber(oldMajor) * 1000000) + (tonumber(oldMinor) * 10000) + (tonumber(oldPatch) * 100)

	if newWoW < oldWoW then
		return -1
	elseif newRelType < oldRelType and newWoW > oldWoW then
		return 0
	elseif newWoW > oldWoW then
		return 1
	end

	local newXRP = (tonumber(newAddOn) * 10000) + (newRelType * 100) + (tonumber(newRelRev) or 0)
	local oldXRP = (tonumber(oldAddOn) * 10000) + (oldRelType * 100) + (tonumber(oldRelRev) or 0)

	if newXRP <= oldXRP then
		return -1
	elseif newRelType < oldRelType and newXRP > oldXRP then
		return 0
	else
		return 1
	end
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
		GC = select(2, UnitClass("player")),
		GF = UnitFactionGroup("player"),
		GR = select(2, UnitRace("player")),
		GS = tostring(UnitSex("player")),
		NA = _xrp.player, -- Fallback NA field.
		VA = table.concat(VA, ";"),
	}
	local fields, versions = xrpSaved.meta.fields, xrpSaved.meta.versions
	for field, contents in pairs(newFields) do
		if contents ~= fields[field] then
			fields[field] = contents
			versions[field] = _xrp.NewVersion(field, contents)
			_xrp.FireEvent("UPDATE", field)
		end
	end
	fields.VP = tostring(msp.protocolversion)
	versions.VP = _xrp.msp

	if not xrpSaved.overrides.logout or xrpSaved.overrides.logout + 900 < time() then
		xrpSaved.overrides.fields = {}
		xrpSaved.overrides.versions = {}
	end
	xrpSaved.overrides.logout = nil

	if _xrp.settings.cache.autoClean then
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

	if fields.GF == "Neutral" then
		_xrp.HookGameEvent("NEUTRAL_FACTION_SELECT_RESULT", function(event)
			xrpSaved.meta.fields.GF = UnitFactionGroup("player")
			xrpSaved.meta.versions.GF = _xrp.NewVersion("GF", xrpSaved.meta.fields.GF)
			_xrp.FireEvent("UPDATE", "GF")
		end)
	end
end)
_xrp.HookGameEvent("PLAYER_LOGIN", function(event)
	-- UnitGUID() does not work prior to first PLAYER_LOGIN.
	local GU = UnitGUID("player")
	if xrpSaved.meta.fields.GU ~= GU then
		xrpSaved.meta.fields.GU = GU
		xrpSaved.meta.versions.GU = _xrp.NewVersion("GU", GU)
		_xrp.FireEvent("UPDATE", "GU")
	end
	-- GetAutoCompleteResults() also doesn't work.
	_xrp.own[_xrp.playerWithRealm] = true
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
	_xrp.FireEvent("UPDATE")
end)
_xrp.HookGameEvent("PLAYER_LOGOUT", function(event)
	-- Note: This code must be thoroughly tested if any changes are
	-- made. If there are any errors in here, they are not visible in
	-- any manner in-game.
	local now = time()
	local fields, versions = {}, {}
	for field, contents in pairs(msp.my) do
		if field ~= "TT" then
			fields[field] = contents
		end
		versions[field] = msp.myver[field]
	end
	xrpCache[_xrp.playerWithRealm] = {
		fields = fields,
		versions = versions,
		own = true,
		lastReceive = now,
	}
	if next(xrpSaved.overrides.fields) then
		xrpSaved.overrides.logout = now
	end
end)
