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

local addonName, _L = ...
local _S = _L.strings

xrp.fields = {
	NA = _S.FIELD_NA,
	NI = _S.FIELD_NI,
	NT = _S.FIELD_NT,
	NH = _S.FIELD_NH,
	AH = _S.FIELD_AH,
	AW = _S.FIELD_AW,
	AE = _S.FIELD_AE,
	RA = _S.FIELD_RA,
	RC = _S.FIELD_RC,
	CU = _S.FIELD_CU,
	DE = _S.FIELD_DE,
	AG = _S.FIELD_AG,
	HH = _S.FIELD_HH,
	HB = _S.FIELD_HB,
	MO = _S.FIELD_MO,
	HI = _S.FIELD_HI,
	FR = _S.FIELD_FR,
	FC = _S.FIELD_FC,
	VA = _S.FIELD_VA,
--	VP = _S.FIELD_VP,
--	GC = _S.FIELD_GC,
--	GF = _S.FIELD_GF,
--	GR = _S.FIELD_GR,
--	GS = _S.FIELD_GS,
--	GU = _S.FIELD_GU,
}

xrp.values = {
	FC = {
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = _S.VALUE_FC_1,
		["2"] = _S.VALUE_FC_2,
		["3"] = _S.VALUE_FC_3,
		["4"] = _S.VALUE_FC_4,
	},
	FR = {
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = _S.VALUE_FR_1,
		["2"] = _S.VALUE_FR_2,
		["3"] = _S.VALUE_FR_3,
		["4"] = _S.VALUE_FR_4,
		["5"] = _S.VALUE_FR_5,
	},
	GC = {
		["2"] = FillLocalizedClassList({}, false), -- Male forms
		["3"] = FillLocalizedClassList({}, true), -- Female forms
	},
	GF = {
		Alliance = FACTION_ALLIANCE,
		Horde = FACTION_HORDE,
		Neutral = _S.VALUE_GF_NEUTRAL,
	},
	GR = {
		BloodElf = _S.VALUE_GR_BLOODELF,
		Draenei = _S.VALUE_GR_DRAENEI,
		Dwarf = _S.VALUE_GR_DWARF,
		Gnome = _S.VALUE_GR_GNOME,
		Goblin = _S.VALUE_GR_GOBLIN,
		Human = _S.VALUE_GR_HUMAN,
		NightElf = _S.VALUE_GR_NIGHTELF,
		Orc = _S.VALUE_GR_ORC,
		Pandaren = _S.VALUE_GR_PANDAREN,
		Scourge = _S.VALUE_GR_SCOURGE,
		Tauren = _S.VALUE_GR_TAUREN,
		Troll = _S.VALUE_GR_TROLL,
		Worgen = _S.VALUE_GR_WORGEN,
	},
	GS = {
		["1"] = _S.VALUE_GS_1,
		["2"] = MALE,
		["3"] = FEMALE,
	},
}

-- Match unknown class genders to player gender (non-English).
xrp.values.GC["1"] = UnitSex("player") == 2 and xrp.values.GC["2"] or xrp.values.GC["3"]

BINDING_HEADER_XRP = GetAddOnMetadata(addonName, "Title")
BINDING_NAME_XRP_BOOKMARKS = _S.TOGGLE_BOOKMARKS
BINDING_NAME_XRP_EDITOR = _S.TOGGLE_EDITOR
BINDING_NAME_XRP_STATUS = _S.TOGGLE_STATUS
BINDING_NAME_XRP_VIEWER = _S.VIEW_TARGET_MOUSEOVER
BINDING_NAME_XRP_VIEWER_TARGET = _S.VIEW_TARGET
BINDING_NAME_XRP_VIEWER_MOUSEOVER = _S.VIEW_MOUSEOVER
