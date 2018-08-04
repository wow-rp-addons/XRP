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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

xrp.L = {
	FIELDS = {
		NA = L.FIELD_NA,
		NI = L.FIELD_NI,
		NT = L.FIELD_NT,
		NH = L.FIELD_NH,
		AH = L.FIELD_AH,
		AW = L.FIELD_AW,
		AE = L.FIELD_AE,
		RA = L.FIELD_RA,
		RC = L.FIELD_RC,
		CU = L.FIELD_CU,
		DE = L.FIELD_DE,
		AG = L.FIELD_AG,
		HH = L.FIELD_HH,
		HB = L.FIELD_HB,
		MO = L.FIELD_MO,
		HI = L.FIELD_HI,
		FR = L.FIELD_FR,
		FC = L.FIELD_FC,
		VA = L.FIELD_VA,
		-- Read-only.
		CO = L.FIELD_CO,
		-- Metadata fields.
		VP = L.FIELD_VP,
		GC = L.FIELD_GC,
		GF = L.FIELD_GF,
		GR = L.FIELD_GR,
		GS = L.FIELD_GS,
		GU = L.FIELD_GU,
		-- Unimplemented.
		IC = L.FIELD_IC,
	},
	VALUES = {
		FC = {
			["1"] = L.VALUE_FC_1,
			["2"] = L.VALUE_FC_2,
			["3"] = L.VALUE_FC_3,
			["4"] = L.VALUE_FC_4,
		},
		FR = {
			["1"] = L.VALUE_FR_1,
			["2"] = L.VALUE_FR_2,
			["3"] = L.VALUE_FR_3,
			["4"] = L.VALUE_FR_4,
			["5"] = L.VALUE_FR_5,
		},
		GC = setmetatable({
			["2"] = FillLocalizedClassList({}, false), -- Male forms
			["3"] = FillLocalizedClassList({}, true), -- Female forms
		}, { __index = function(self, key) return rawget(self, "1") end }),
		GF = {
			Alliance = FACTION_ALLIANCE,
			Horde = FACTION_HORDE,
			Neutral = L.VALUE_GF_NEUTRAL,
		},
		GR = {
			BloodElf = L.VALUE_GR_BLOODELF,
			Draenei = L.VALUE_GR_DRAENEI,
			DarkIronDwarf = L.VALUE_GR_DARKIRONDWARF,
			Dwarf = L.VALUE_GR_DWARF,
			Gnome = L.VALUE_GR_GNOME,
			Goblin = L.VALUE_GR_GOBLIN,
			HighmountainTauren = L.VALUE_GR_HIGHMOUNTAINTAUREN,
			Human = L.VALUE_GR_HUMAN,
			KulTiran = L.VALUE_GR_KULTIRAN,
			LightforgedDraenei = L.VALUE_GR_LIGHTFORGEDDRAENEI,
			MagharOrc = L.VALUE_GR_MAGHARORC,
			NightElf = L.VALUE_GR_NIGHTELF,
			Nightborne = L.VALUE_GR_NIGHTBORNE,
			Orc = L.VALUE_GR_ORC,
			Pandaren = L.VALUE_GR_PANDAREN,
			Scourge = L.VALUE_GR_SCOURGE,
			Tauren = L.VALUE_GR_TAUREN,
			Troll = L.VALUE_GR_TROLL,
			VoidElf = L.VALUE_GR_VOIDELF,
			Worgen = L.VALUE_GR_WORGEN,
			ZandalariTroll = L.VALUE_GR_ZANDALARITROLL,
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
	FR = L.FIELD_FR_MENU,
	FC = L.FIELD_FC_MENU,
	-- Metadata fields.
	VP = L.FIELD_VP_MENU,
	GC = L.FIELD_GC_MENU,
	GF = L.FIELD_GF_MENU,
	GR = L.FIELD_GR_MENU,
	GS = L.FIELD_GS_MENU,
}, { __index = xrp.L.FIELDS })

xrp.L.MENU_VALUES = setmetatable({
	FC = {
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = L.VALUE_FC_1_MENU,
		["2"] = L.VALUE_FC_2_MENU,
		["3"] = L.VALUE_FC_3_MENU,
		["4"] = L.VALUE_FC_4_MENU,
	},
	FR = {
		["0"] = PARENS_TEMPLATE:format(NONE),
		["1"] = L.VALUE_FR_1_MENU,
		["2"] = L.VALUE_FR_2_MENU,
		["3"] = L.VALUE_FR_3_MENU,
		["4"] = L.VALUE_FR_4_MENU,
		["5"] = L.VALUE_FR_5_MENU,
	},
}, { __index = xrp.L.VALUES })

BINDING_HEADER_XRP = GetAddOnMetadata(FOLDER_NAME, "Title")
BINDING_NAME_XRP_ARCHIVE = L"Toggle RP Profile Archive"
BINDING_NAME_XRP_EDITOR = L"Toggle RP Profile Editor"
BINDING_NAME_XRP_STATUS = L"Toggle IC/OOC Status"
BINDING_NAME_XRP_VIEWER = L"View RP Profile of Mouseover"
BINDING_NAME_XRP_VIEWER_TARGET = L"View RP Profile of Target"
BINDING_NAME_XRP_VIEWER_MOUSEOVER = L"View RP Profile of Target/Mouseover"
