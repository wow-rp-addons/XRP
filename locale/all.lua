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

-- This file is used with all language translations to build special constants
-- from both XRP translations and Blizzard UI translations. These constants are
-- used repeatedly throughout XRP, but more specialized ones are also built
-- elsewhere.

local addonName, _xrp = ...

xrp.fields = {
	NA = _xrp.L.FIELD_NA,
	NI = _xrp.L.FIELD_NI,
	NT = _xrp.L.FIELD_NT,
	NH = _xrp.L.FIELD_NH,
	AH = _xrp.L.FIELD_AH,
	AW = _xrp.L.FIELD_AW,
	AE = _xrp.L.FIELD_AE,
	RA = _xrp.L.FIELD_RA,
	RC = _xrp.L.FIELD_RC,
	CU = _xrp.L.FIELD_CU,
	DE = _xrp.L.FIELD_DE,
	AG = _xrp.L.FIELD_AG,
	HH = _xrp.L.FIELD_HH,
	HB = _xrp.L.FIELD_HB,
	MO = _xrp.L.FIELD_MO,
	HI = _xrp.L.FIELD_HI,
	FR = _xrp.L.FIELD_FR,
	FC = _xrp.L.FIELD_FC,
	VA = _xrp.L.FIELD_VA,
}

xrp.values = {
	FC = {
		["1"] = _xrp.L.VALUE_FC_1,
		["2"] = _xrp.L.VALUE_FC_2,
		["3"] = _xrp.L.VALUE_FC_3,
		["4"] = _xrp.L.VALUE_FC_4,
	},
	FR = {
		["1"] = _xrp.L.VALUE_FR_1,
		["2"] = _xrp.L.VALUE_FR_2,
		["3"] = _xrp.L.VALUE_FR_3,
		["4"] = _xrp.L.VALUE_FR_4,
		["5"] = _xrp.L.VALUE_FR_5,
	},
	GC = {
		["2"] = FillLocalizedClassList({}, false), -- Male forms
		["3"] = FillLocalizedClassList({}, true), -- Female forms
	},
	GF = {
		Alliance = FACTION_ALLIANCE,
		Horde = FACTION_HORDE,
		Neutral = _xrp.L.VALUE_GF_NEUTRAL,
	},
	GR = {
		BloodElf = _xrp.L.VALUE_GR_BLOODELF,
		Draenei = _xrp.L.VALUE_GR_DRAENEI,
		Dwarf = _xrp.L.VALUE_GR_DWARF,
		Gnome = _xrp.L.VALUE_GR_GNOME,
		Goblin = _xrp.L.VALUE_GR_GOBLIN,
		Human = _xrp.L.VALUE_GR_HUMAN,
		NightElf = _xrp.L.VALUE_GR_NIGHTELF,
		Orc = _xrp.L.VALUE_GR_ORC,
		Pandaren = _xrp.L.VALUE_GR_PANDAREN,
		Scourge = _xrp.L.VALUE_GR_SCOURGE,
		Tauren = _xrp.L.VALUE_GR_TAUREN,
		Troll = _xrp.L.VALUE_GR_TROLL,
		Worgen = _xrp.L.VALUE_GR_WORGEN,
	},
	GS = {
		["1"] = UNKNOWN,
		["2"] = MALE,
		["3"] = FEMALE,
	},
}

-- Match unknown class genders to player gender (non-English).
xrp.values.GC["1"] = UnitSex("player") == 2 and xrp.values.GC["2"] or xrp.values.GC["3"]

xrp.menuValues = setmetatable({
	FC = {
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = _xrp.L.VALUE_FC_1_MENU,
		["2"] = _xrp.L.VALUE_FC_2_MENU,
		["3"] = _xrp.L.VALUE_FC_3_MENU,
		["4"] = _xrp.L.VALUE_FC_4_MENU,
	},
	FR = {
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = _xrp.L.VALUE_FR_1_MENU,
		["2"] = _xrp.L.VALUE_FR_2_MENU,
		["3"] = _xrp.L.VALUE_FR_3_MENU,
		["4"] = _xrp.L.VALUE_FR_4_MENU,
		["5"] = _xrp.L.VALUE_FR_5_MENU,
	},
}, { __index = xrp.values })

BINDING_HEADER_XRP = GetAddOnMetadata(addonName, "Title")
BINDING_NAME_XRP_BOOKMARKS = _xrp.L.TOGGLE_BOOKMARKS
BINDING_NAME_XRP_EDITOR = _xrp.L.TOGGLE_EDITOR
BINDING_NAME_XRP_STATUS = _xrp.L.TOGGLE_STATUS
BINDING_NAME_XRP_VIEWER = _xrp.L.VIEW_TARGET_MOUSEOVER
BINDING_NAME_XRP_VIEWER_TARGET = _xrp.L.VIEW_TARGET
BINDING_NAME_XRP_VIEWER_MOUSEOVER = _xrp.L.VIEW_MOUSEOVER

_xrp.settingsToggles.display.altBloodElf = function(setting)
	if setting and xrp.values.GR.BloodElf == _xrp.L.VALUE_GR_BLOODELF then
		xrp.values.GR.BloodElf = _xrp.L.VALUE_GR_BLOODELF_ALT
		_xrp.settingsToggles.display.altBloodElfForce(_xrp.settings.display.altBloodElfForce)
	elseif not setting then
		if xrp.values.GR.BloodElf == _xrp.L.VALUE_GR_BLOODELF_ALT then
			xrp.values.GR.BloodElf = _xrp.L.VALUE_GR_BLOODELF
		end
		_xrp.settingsToggles.display.altBloodElfForce(false)
	end
end
_xrp.settingsToggles.display.altBloodElfForce = function(setting)
	if setting and xrpSaved.meta.fields.GR == "BloodElf" and xrpSaved.meta.fields.RA ~= _xrp.L.VALUE_GR_BLOODELF_ALT then
		xrpSaved.meta.fields.RA = _xrp.L.VALUE_GR_BLOODELF_ALT
		xrpSaved.meta.versions.RA = _xrp.NewVersion("RA", _xrp.L.VALUE_GR_BLOODELF_ALT)
		_xrp.FireEvent("UPDATE", "RA")
	elseif (not setting or xrpSaved.meta.fields.GR ~= "BloodElf") and xrpSaved.meta.fields.RA == _xrp.L.VALUE_GR_BLOODELF_ALT then
		xrpSaved.meta.fields.RA = nil
		xrpSaved.meta.versions.RA = nil
		_xrp.FireEvent("UPDATE", "RA")
	end
end
_xrp.settingsToggles.display.altNightElf = function(setting)
	if setting and xrp.values.GR.NightElf == _xrp.L.VALUE_GR_NIGHTELF then
		xrp.values.GR.NightElf = _xrp.L.VALUE_GR_NIGHTELF_ALT
		_xrp.settingsToggles.display.altNightElfForce(_xrp.settings.display.altNightElfForce)
	elseif not setting then
		if xrp.values.GR.NightElf == _xrp.L.VALUE_GR_NIGHTELF_ALT then
			xrp.values.GR.NightElf = _xrp.L.VALUE_GR_NIGHTELF
		end
		_xrp.settingsToggles.display.altNightElfForce(false)
	end
end
_xrp.settingsToggles.display.altNightElfForce = function(setting)
	if setting and xrpSaved.meta.fields.GR == "NightElf" and xrpSaved.meta.fields.RA ~= _xrp.L.VALUE_GR_NIGHTELF_ALT then
		xrpSaved.meta.fields.RA = _xrp.L.VALUE_GR_NIGHTELF_ALT
		xrpSaved.meta.versions.RA = _xrp.NewVersion("RA", _xrp.L.VALUE_GR_NIGHTELF_ALT)
		_xrp.FireEvent("UPDATE", "RA")
	elseif (not setting or xrpSaved.meta.fields.GR ~= "NightElf") and xrpSaved.meta.fields.RA == _xrp.L.VALUE_GR_NIGHTELF_ALT then
		xrpSaved.meta.fields.RA = nil
		xrpSaved.meta.versions.RA = nil
		_xrp.FireEvent("UPDATE", "RA")
	end
end
_xrp.settingsToggles.display.altScourge = function(setting)
	if setting and xrp.values.GR.Scourge == _xrp.L.VALUE_GR_SCOURGE then
		xrp.values.GR.Scourge = _xrp.L.VALUE_GR_SCOURGE_ALT
		_xrp.settingsToggles.display.altScourgeForce(_xrp.settings.display.altScourgeForce)
	elseif not setting then
		if xrp.values.GR.Scourge == _xrp.L.VALUE_GR_SCOURGE_ALT then
			xrp.values.GR.Scourge = _xrp.L.VALUE_GR_SCOURGE
		end
		_xrp.settingsToggles.display.altScourgeForce(false)
	end
end
_xrp.settingsToggles.display.altScourgeForce = function(setting)
	if setting and xrpSaved.meta.fields.GR == "Scourge" and xrpSaved.meta.fields.RA ~= _xrp.L.VALUE_GR_SCOURGE_ALT then
		xrpSaved.meta.fields.RA = _xrp.L.VALUE_GR_SCOURGE_ALT
		xrpSaved.meta.versions.RA = _xrp.NewVersion("RA", _xrp.L.VALUE_GR_SCOURGE_ALT)
		_xrp.FireEvent("UPDATE", "RA")
	elseif (not setting or xrpSaved.meta.fields.GR ~= "Scourge") and xrpSaved.meta.fields.RA == _xrp.L.VALUE_GR_SCOURGE_ALT then
		xrpSaved.meta.fields.RA = nil
		xrpSaved.meta.versions.RA = nil
		_xrp.FireEvent("UPDATE", "RA")
	end
end
_xrp.settingsToggles.display.altTauren = function(setting)
	if setting and xrp.values.GR.Tauren == _xrp.L.VALUE_GR_TAUREN then
		xrp.values.GR.Tauren = _xrp.L.VALUE_GR_TAUREN_ALT
		_xrp.settingsToggles.display.altTaurenForce(_xrp.settings.display.altTaurenForce)
	elseif not setting then
		if xrp.values.GR.Tauren == _xrp.L.VALUE_GR_TAUREN_ALT then
			xrp.values.GR.Tauren = _xrp.L.VALUE_GR_TAUREN
		end
		_xrp.settingsToggles.display.altTaurenForce(false)
	end
end
_xrp.settingsToggles.display.altTaurenForce = function(setting)
	if setting and xrpSaved.meta.fields.GR == "Tauren" and xrpSaved.meta.fields.RA ~= _xrp.L.VALUE_GR_TAUREN_ALT then
		xrpSaved.meta.fields.RA = _xrp.L.VALUE_GR_TAUREN_ALT
		xrpSaved.meta.versions.RA = _xrp.NewVersion("RA", _xrp.L.VALUE_GR_TAUREN_ALT)
		_xrp.FireEvent("UPDATE", "RA")
	elseif (not setting or xrpSaved.meta.fields.GR ~= "Tauren") and xrpSaved.meta.fields.RA == _xrp.L.VALUE_GR_TAUREN_ALT then
		xrpSaved.meta.fields.RA = nil
		xrpSaved.meta.versions.RA = nil
		_xrp.FireEvent("UPDATE", "RA")
	end
end
