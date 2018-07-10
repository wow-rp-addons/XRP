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
	local needsSetting = setting and (not _xrp.settings[settingName .. "Limit"] or AltNames[categoryName][(select(2, UnitRace("player")))])
	for raceName in pairs(AltNames[categoryName]) do
		local raceUpperValue = "VALUE_GR_" .. raceName:upper()
		local raceUpperAltValue = raceUpperValue .. "_ALT"
		if needsSetting then
			xrp.L.VALUES.GR[raceName] = _xrp.L[raceUpperAltValue]
			_xrp.settingsToggles[forceSetting](_xrp.settings[forceSetting], forceSetting)
		else
			xrp.L.VALUES.GR[raceName] = _xrp.L[raceUpperValue]
			_xrp.settingsToggles[forceSetting](false, forceSetting)
		end
	end
	if needsSetting then
		_xrp.settingsToggles[forceSetting](_xrp.settings[forceSetting], forceSetting)
	else
		_xrp.settingsToggles[forceSetting](false, forceSetting)
	end
end

local function AltToggleForce(setting, settingName)
	local categoryName = settingName:match("^alt(.+)Force$")
	local raceName = select(2, UnitRace("player"))
	local raceAlt = _xrp.L[("VALUE_GR_%s_ALT"):format(raceName:upper())]
	if setting and AltNames[categoryName][raceName] and xrpSaved.meta.fields.RA ~= raceAlt then
		xrpSaved.meta.fields.RA = raceAlt
		_xrp.FireEvent("UPDATE", "RA")
	elseif (not setting or not AltNames[categoryName][raceName]) and xrpSaved.meta.fields.RA == raceAlt then
		xrpSaved.meta.fields.RA = nil
		_xrp.FireEvent("UPDATE", "RA")
	end
end

local function AltToggleLimit(setting, settingName)
	local raceSettingName = settingName:match("^(.+)Limit$")
	if _xrp.settings[raceSettingName] then
		_xrp.settingsToggles[raceSettingName](true, raceSettingName)
	end
end

_xrp.settingsToggles.altScourge = AltToggle
_xrp.settingsToggles.altScourgeForce = AltToggleForce
_xrp.settingsToggles.altScourgeLimit = AltToggleLimit
_xrp.settingsToggles.altElven = AltToggle
_xrp.settingsToggles.altElvenForce = AltToggleForce
_xrp.settingsToggles.altElvenLimit = AltToggleLimit
_xrp.settingsToggles.altTauren = AltToggle
_xrp.settingsToggles.altTaurenForce = AltToggleForce
_xrp.settingsToggles.altTaurenLimit = AltToggleLimit
