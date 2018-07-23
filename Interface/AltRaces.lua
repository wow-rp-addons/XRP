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
	local needsSetting = setting and (not AddOn.settings[settingName .. "Limit"] or AltNames[categoryName][(select(2, UnitRace("player")))])
	for raceName in pairs(AltNames[categoryName]) do
		local raceUpperValue = "VALUE_GR_" .. raceName:upper()
		local raceUpperAltValue = raceUpperValue .. "_ALT"
		if needsSetting then
			xrp.L.VALUES.GR[raceName] = L[raceUpperAltValue]
			AddOn.settingsToggles[forceSetting](AddOn.settings[forceSetting], forceSetting)
		else
			xrp.L.VALUES.GR[raceName] = L[raceUpperValue]
			AddOn.settingsToggles[forceSetting](false, forceSetting)
		end
	end
	if needsSetting then
		AddOn.settingsToggles[forceSetting](AddOn.settings[forceSetting], forceSetting)
	else
		AddOn.settingsToggles[forceSetting](false, forceSetting)
	end
end

local function AltToggleForce(setting, settingName)
	local categoryName = settingName:match("^alt(.+)Force$")
	local raceName = select(2, UnitRace("player"))
	local raceAlt = L[("VALUE_GR_%s_ALT"):format(raceName:upper())]
	if setting and AltNames[categoryName][raceName] and xrpSaved.meta.fields.RA ~= raceAlt then
		xrpSaved.meta.fields.RA = raceAlt
		AddOn.FireEvent("UPDATE", "RA")
	elseif (not setting or not AltNames[categoryName][raceName]) and xrpSaved.meta.fields.RA == raceAlt then
		xrpSaved.meta.fields.RA = nil
		AddOn.FireEvent("UPDATE", "RA")
	end
end

local function AltToggleLimit(setting, settingName)
	local raceSettingName = settingName:match("^(.+)Limit$")
	if AddOn.settings[raceSettingName] then
		AddOn.settingsToggles[raceSettingName](true, raceSettingName)
	end
end

AddOn.settingsToggles.altScourge = AltToggle
AddOn.settingsToggles.altScourgeForce = AltToggleForce
AddOn.settingsToggles.altScourgeLimit = AltToggleLimit
AddOn.settingsToggles.altElven = AltToggle
AddOn.settingsToggles.altElvenForce = AltToggleForce
AddOn.settingsToggles.altElvenLimit = AltToggleLimit
AddOn.settingsToggles.altTauren = AltToggle
AddOn.settingsToggles.altTaurenForce = AltToggleForce
AddOn.settingsToggles.altTaurenLimit = AltToggleLimit
