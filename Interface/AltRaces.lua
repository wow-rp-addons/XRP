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

local AltNames = {
	Scourge = {
		Scourge = true,
	},
	Elven = {
		BloodElf = true,
		NightElf = true,
		Nightborne = true,
		VoidElf = true,
	},
	Tauren = {
		HighmountainTauren = true,
		Tauren = true,
	},
}

local function AltToggle(setting, settingName)
	local categoryName = settingName:match("^alt(.+)$")
	local forceSetting = settingName .. "Force"
	local needsSetting = setting and (not AddOn.Settings[settingName .. "Limit"] or AltNames[categoryName][(select(2, UnitRace("player")))])
	for raceName in pairs(AltNames[categoryName]) do
		local raceUpperValue = "VALUE_GR_" .. raceName:upper()
		local raceUpperAltValue = raceUpperValue .. "_ALT"
		if needsSetting then
			xrp.L.VALUES.GR[raceName] = L[raceUpperAltValue]
			AddOn.SettingsToggles[forceSetting](AddOn.Settings[forceSetting], forceSetting)
		else
			xrp.L.VALUES.GR[raceName] = L[raceUpperValue]
			AddOn.SettingsToggles[forceSetting](false, forceSetting)
		end
	end
	if needsSetting then
		AddOn.SettingsToggles[forceSetting](AddOn.Settings[forceSetting], forceSetting)
	else
		AddOn.SettingsToggles[forceSetting](false, forceSetting)
	end
end

local function AltToggleForce(setting, settingName)
	local categoryName = settingName:match("^alt(.+)Force$")
	local raceName = select(2, UnitRace("player"))
	local raceAlt = L[("VALUE_GR_%s_ALT"):format(raceName:upper())]
	if setting and AltNames[categoryName][raceName] and AddOn.FallbackFields.RA ~= raceAlt then
		AddOn.FallbackFields.RA = raceAlt
		AddOn.RunEvent("UPDATE", "RA")
	elseif (not setting or not AltNames[categoryName][raceName]) and AddOn.FallbackFields.RA == raceAlt then
		AddOn.FallbackFields.RA = nil
		AddOn.RunEvent("UPDATE", "RA")
	end
end

local function AltToggleLimit(setting, settingName)
	local raceSettingName = settingName:match("^(.+)Limit$")
	if AddOn.Settings[raceSettingName] then
		AddOn.SettingsToggles[raceSettingName](true, raceSettingName)
	end
end

AddOn.SettingsToggles.altScourge = AltToggle
AddOn.SettingsToggles.altScourgeForce = AltToggleForce
AddOn.SettingsToggles.altScourgeLimit = AltToggleLimit
AddOn.SettingsToggles.altElven = AltToggle
AddOn.SettingsToggles.altElvenForce = AltToggleForce
AddOn.SettingsToggles.altElvenLimit = AltToggleLimit
AddOn.SettingsToggles.altTauren = AltToggle
AddOn.SettingsToggles.altTaurenForce = AltToggleForce
AddOn.SettingsToggles.altTaurenLimit = AltToggleLimit
