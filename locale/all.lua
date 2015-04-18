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
--	VP = _xrp.L.FIELD_VP,
--	GC = _xrp.L.FIELD_GC,
--	GF = _xrp.L.FIELD_GF,
--	GR = _xrp.L.FIELD_GR,
--	GS = _xrp.L.FIELD_GS,
--	GU = _xrp.L.FIELD_GU,
}

xrp.values = {
	FC = {
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = _xrp.L.VALUE_FC_1,
		["2"] = _xrp.L.VALUE_FC_2,
		["3"] = _xrp.L.VALUE_FC_3,
		["4"] = _xrp.L.VALUE_FC_4,
	},
	FR = {
		["0"] = PARENS_TEMPLATE:format(NONE),
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
		["1"] = _xrp.L.VALUE_GS_1,
		["2"] = MALE,
		["3"] = FEMALE,
	},
}

-- Match unknown class genders to player gender (non-English).
xrp.values.GC["1"] = UnitSex("player") == 2 and xrp.values.GC["2"] or xrp.values.GC["3"]

BINDING_HEADER_XRP = GetAddOnMetadata(addonName, "Title")
BINDING_NAME_XRP_BOOKMARKS = _xrp.L.TOGGLE_BOOKMARKS
BINDING_NAME_XRP_EDITOR = _xrp.L.TOGGLE_EDITOR
BINDING_NAME_XRP_STATUS = _xrp.L.TOGGLE_STATUS
BINDING_NAME_XRP_VIEWER = _xrp.L.VIEW_TARGET_MOUSEOVER
BINDING_NAME_XRP_VIEWER_TARGET = _xrp.L.VIEW_TARGET
BINDING_NAME_XRP_VIEWER_MOUSEOVER = _xrp.L.VIEW_MOUSEOVER
