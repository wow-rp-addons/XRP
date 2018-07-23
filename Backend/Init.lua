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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

xrp = {}

local SUPPORTED_LANGUAGES = {
	enUS = "en",
	enGB = "en",
}
AddOn.language = SUPPORTED_LANGUAGES[GetLocale()] or "en"

AddOn.version = GetAddOnMetadata(FOLDER_NAME, "Version")
AddOn.DoNothing = function() end
AddOn.weakMeta = { __mode = "v" }
AddOn.weakKeyMeta = { __mode = "k" }

AddOn.own = {}

local events = {}
function AddOn.FireEvent(event, ...)
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
function AddOn.HookGameEvent(event, func, unit)
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
function AddOn.UnhookGameEvent(event, func)
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
	if event == "ADDON_LOADED" and ... ~= FOLDER_NAME then return end
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

function AddOn.AddonUpdate(version)
	if not version or version == AddOn.version or version == AddOn.settings.newversion then return end
	if CompareVersion(version, AddOn.settings.newversion or AddOn.version) >= 0 then
		AddOn.settings.newversion = version
	end
end

AddOn.HookGameEvent("ADDON_LOADED", function(event, addon)
	AddOn.playerWithRealm = xrp.UnitFullName("player")
	AddOn.player, AddOn.realm = AddOn.playerWithRealm:match("^([^%-]+)%-([^%-]+)$")
	AddOn.SavedVariableSetup()

	local addonString = "%s/%s"
	local VA = { addonString:format(FOLDER_NAME, AddOn.version) }
	for i, addon in ipairs({ "GHI", "Tongues" }) do
		if IsAddOnLoaded(addon) then
			VA[#VA + 1] = addonString:format(addon, GetAddOnMetadata(addon, "Version"))
		end
	end
	local newFields = {
		NA = AddOn.player, -- Fallback NA field.
		VA = table.concat(VA, ";"),
	}
	local fields = xrpSaved.meta.fields
	for field, contents in pairs(newFields) do
		if contents ~= fields[field] then
			fields[field] = contents
			AddOn.FireEvent("UPDATE", field)
		end
	end

	if not xrpSaved.overrides.logout or xrpSaved.overrides.logout + 900 < time() then
		xrpSaved.overrides.fields = {}
	end
	xrpSaved.overrides.logout = nil

	if AddOn.settings.cacheAutoClean then
		AddOn.CacheTidy(nil, true)
	end

	AddOn.LoadSettings()

	if AddOn.settings.newversion then
		local update = CompareVersion(AddOn.settings.newversion, AddOn.version)
		local now = time()
		if update == 1 and (not AddOn.settings.versionwarning or AddOn.settings.versionwarning < now - 21600) then
			C_Timer.After(8, function()
				print(L.NEW_VERSION:format(AddOn.settings.newversion))
				AddOn.settings.versionwarning = now
			end)
		elseif update == -1 then
			AddOn.settings.newversion = nil
			AddOn.settings.versionwarning = nil
		end
	end
end)
AddOn.HookGameEvent("PLAYER_LOGIN", function(event)
	AddOn.FireEvent("UPDATE")
	-- GetAutoCompleteResults() doesn't work before PLAYER_LOGIN.
	AddOn.own[AddOn.playerWithRealm] = true
	if xrpCache[AddOn.playerWithRealm] and not xrpCache[AddOn.playerWithRealm].own then
		xrpCache[AddOn.playerWithRealm].own = true
	end
	for i, character in ipairs(GetAutoCompleteResults("", 0, 1, AUTO_COMPLETE_ACCOUNT_CHARACTER, 0)) do
		local name = xrp.FullName(character.name)
		AddOn.own[name] = true
		if xrpCache[name] and not xrpCache[name].own then
			xrpCache[name].own = true
		end
	end
	for name, data in pairs(xrpCache) do
		if data.own and not AddOn.own[name] and name:match("%-([^%-]+)$") == AddOn.realm then
			data.own = nil
		end
	end
end)
AddOn.HookGameEvent("PLAYER_LOGOUT", function(event)
	-- Note: This code must be thoroughly tested if any changes are
	-- made. If there are any errors in here, they are not visible in
	-- any manner in-game.
	if next(xrpSaved.overrides.fields) then
		xrpSaved.overrides.logout = time()
	end
end)
