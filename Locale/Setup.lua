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

local FOLDER, _xrp = ...

xrp.L = {
	FIELDS = {
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
		-- Read-only.
		CO = _xrp.L.FIELD_CO,
		-- Metadata fields.
		VP = _xrp.L.FIELD_VP,
		GC = _xrp.L.FIELD_GC,
		GF = _xrp.L.FIELD_GF,
		GR = _xrp.L.FIELD_GR,
		GS = _xrp.L.FIELD_GS,
		GU = _xrp.L.FIELD_GU,
		-- Unimplemented.
		IC = _xrp.L.FIELD_IC,
	},
	VALUES = {
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
		GC = setmetatable({
			["2"] = FillLocalizedClassList({}, false), -- Male forms
			["3"] = FillLocalizedClassList({}, true), -- Female forms
		}, { __index = function(self, key) return rawget(self, "1") end }),
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
			HighmountainTauren = _xrp.L.VALUE_GR_HIGHMOUNTAINTAUREN,
			Human = _xrp.L.VALUE_GR_HUMAN,
			LightforgedDraenei = _xrp.L.VALUE_GR_LIGHTFORGEDDRAENEI,
			NightElf = _xrp.L.VALUE_GR_NIGHTELF,
			Nightborne = _xrp.L.VALUE_GR_NIGHTBORNE,
			Orc = _xrp.L.VALUE_GR_ORC,
			Pandaren = _xrp.L.VALUE_GR_PANDAREN,
			Scourge = _xrp.L.VALUE_GR_SCOURGE,
			Tauren = _xrp.L.VALUE_GR_TAUREN,
			Troll = _xrp.L.VALUE_GR_TROLL,
			VoidElf = _xrp.L.VALUE_GR_VOIDELF,
			Worgen = _xrp.L.VALUE_GR_WORGEN,
		},
		GS = {
			["1"] = UNKNOWN,
			["2"] = MALE,
			["3"] = FEMALE,
		},
	},
}
-- Match unknown class genders to player gender.
xrp.L.VALUES.GC["1"] = UnitSex("player") == 2 and xrp.L.VALUES.GC["2"] or xrp.L.VALUES.GC["3"]

xrp.L.MENU_FIELDS = setmetatable({
	FR = _xrp.L.FIELD_FR_MENU,
	FC = _xrp.L.FIELD_FC_MENU,
	-- Metadata fields.
	VP = _xrp.L.FIELD_VP_MENU,
	GC = _xrp.L.FIELD_GC_MENU,
	GF = _xrp.L.FIELD_GF_MENU,
	GR = _xrp.L.FIELD_GR_MENU,
	GS = _xrp.L.FIELD_GS_MENU,
}, { __index = xrp.L.FIELDS })

xrp.L.MENU_VALUES = setmetatable({
	FC = setmetatable({
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = _xrp.L.VALUE_FC_1_MENU,
		["2"] = _xrp.L.VALUE_FC_2_MENU,
		["3"] = _xrp.L.VALUE_FC_3_MENU,
		["4"] = _xrp.L.VALUE_FC_4_MENU,
	}, { __index = xrp.L.VALUES.FC }),
	FR = setmetatable({
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = _xrp.L.VALUE_FR_1_MENU,
		["2"] = _xrp.L.VALUE_FR_2_MENU,
		["3"] = _xrp.L.VALUE_FR_3_MENU,
		["4"] = _xrp.L.VALUE_FR_4_MENU,
		["5"] = _xrp.L.VALUE_FR_5_MENU,
	}, { __index = xrp.L.VALUES.FR }),
}, { __index = xrp.L.VALUES })

BINDING_HEADER_XRP = GetAddOnMetadata(FOLDER, "Title")
BINDING_NAME_XRP_BOOKMARKS = _xrp.L.TOGGLE_BOOKMARKS
BINDING_NAME_XRP_EDITOR = _xrp.L.TOGGLE_EDITOR
BINDING_NAME_XRP_STATUS = _xrp.L.TOGGLE_STATUS
BINDING_NAME_XRP_VIEWER = _xrp.L.VIEW_TARGET_MOUSEOVER
BINDING_NAME_XRP_VIEWER_TARGET = _xrp.L.VIEW_TARGET
BINDING_NAME_XRP_VIEWER_MOUSEOVER = _xrp.L.VIEW_MOUSEOVER

local function AltToggle(setting, settingName)
	local raceName = settingName:match("^alt(.+)$")
	local forceSetting = settingName .. "Force"
	local raceUpperValue = "VALUE_GR_" .. raceName:upper()
	local raceUpperAltValue = raceUpperValue .. "_ALT"
	if setting and xrp.L.VALUES.GR[raceName] == _xrp.L[raceUpperValue] and (not _xrp.settings.display[settingName .. "Limit"] or xrpSaved.meta.fields.GR == raceName) then
		xrp.L.VALUES.GR[raceName] = _xrp.L[raceUpperAltValue]
		_xrp.settingsToggles.display[forceSetting](_xrp.settings.display[forceSetting], forceSetting)
	elseif xrp.L.VALUES.GR[raceName] ~= _xrp.L[raceUpperAltValue] then
		xrp.L.VALUES.GR[raceName] = _xrp.L[raceUpperValue]
		_xrp.settingsToggles.display[forceSetting](false, forceSetting)
	end
end

local function AltToggleForce(setting, settingName)
	local raceName = settingName:match("^alt(.+)Force$")
	local raceAlt = _xrp.L[("VALUE_GR_%s_ALT"):format(raceName:upper())]
	if setting and xrpSaved.meta.fields.GR == raceName and xrpSaved.meta.fields.RA ~= raceAlt then
		xrpSaved.meta.fields.RA = raceAlt
		_xrp.FireEvent("UPDATE", "RA")
	elseif (not setting or xrpSaved.meta.fields.GR ~= raceName) and xrpSaved.meta.fields.RA == raceAlt then
		xrpSaved.meta.fields.RA = nil
		_xrp.FireEvent("UPDATE", "RA")
	end
end

local function AltToggleLimit(setting, settingName)
	local raceSettingName = settingName:match("^(.+)Limit$")
	if _xrp.settings.display[raceSettingName] then
		_xrp.settingsToggles.display[raceSettingName](true, raceSettingName)
	end
end

_xrp.settingsToggles.display.altScourge = AltToggle
_xrp.settingsToggles.display.altScourgeForce = AltToggleForce
_xrp.settingsToggles.display.altScourgeLimit = AltToggleLimit
_xrp.settingsToggles.display.altBloodElf = AltToggle
_xrp.settingsToggles.display.altBloodElfForce = AltToggleForce
_xrp.settingsToggles.display.altBloodElfLimit = AltToggleLimit
_xrp.settingsToggles.display.altNightElf = AltToggle
_xrp.settingsToggles.display.altNightElfForce = AltToggleForce
_xrp.settingsToggles.display.altNightElfLimit = AltToggleLimit
_xrp.settingsToggles.display.altTauren = AltToggle
_xrp.settingsToggles.display.altTaurenForce = AltToggleForce
_xrp.settingsToggles.display.altTaurenLimit = AltToggleLimit
