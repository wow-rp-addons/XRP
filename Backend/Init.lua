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

AddOn.DoNothing = function() end
AddOn.weakMeta = { __mode = "v" }
AddOn.weakKeyMeta = { __mode = "k" }

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

AddOn.HookGameEvent("ADDON_LOADED", function(event, addon)
	AddOn.characterID = xrp.UnitFullName("player")
	AddOn.characterName, AddOn.characterRealm = AddOn.characterID:match("^([^%-]+)%-([^%-]+)$")

	AddOn.SavedVariableSetup()

	local addonString = "%s/%s"
	local VA = { addonString:format(FOLDER_NAME, GetAddOnMetadata(FOLDER_NAME, "Version")) }
	for i, addon in ipairs({ "GHI", "Tongues" }) do
		if IsAddOnLoaded(addon) then
			VA[#VA + 1] = addonString:format(addon, GetAddOnMetadata(addon, "Version"))
		end
	end
	local newFields = {
		NA = AddOn.characterName, -- Fallback NA field.
		VA = table.concat(VA, ";"),
		FC = "1",
	}
	local fields = xrpSaved.meta.fields
	for field, contents in pairs(newFields) do
		if contents ~= fields[field] then
			fields[field] = contents
		end
	end

	if not xrpSaved.overrides.logout or xrpSaved.overrides.logout + 900 < time() then
		xrpSaved.overrides.fields = {}
	end
	xrpSaved.overrides.logout = nil

	AddOn.FireEvent("UPDATE")

	if AddOn.Settings.cacheAutoClean then
		AddOn.CacheTidy(nil, true)
	end

	AddOn.LoadSettings()
end)
AddOn.HookGameEvent("PLAYER_LOGOUT", function(event)
	-- Note: This code must be thoroughly tested if any changes are
	-- made. If there are any errors in here, they are not visible in
	-- any manner in-game.
	if next(xrpSaved.overrides.fields) then
		xrpSaved.overrides.logout = time()
	end
end)
