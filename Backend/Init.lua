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

AddOn.HookGameEvent("ADDON_LOADED", function(event, addon)
	AddOn.characterID = xrp.UnitCharacterID("player")
	AddOn.characterName, AddOn.characterRealm = AddOn.characterID:match("^([^%-]+)%-([^%-]+)$")

	AddOn.SavedVariableSetup()

	local addonString = "%s/%s"
	local VA = { addonString:format(FOLDER_NAME, GetAddOnMetadata(FOLDER_NAME, "Version")) }
	for i, addon in ipairs({ "GHI", "Tongues" }) do
		if IsAddOnLoaded(addon) then
			VA[#VA + 1] = addonString:format(addon, GetAddOnMetadata(addon, "Version"))
		end
	end
	AddOn.FallbackFields = {
		NA = AddOn.characterName,
		VA = table.concat(VA, ";"),
		FC = "1",
	}

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
