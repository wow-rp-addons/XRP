--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

-- This file is used with all language translations to build special constants
-- from both XRP translations and Blizzard UI translations. These constants are
-- used repeatedly throughout XRP, but more specialized ones are also built
-- elsewhere.

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

AddOn_XRP.Strings = {}

local Names = {}
Names.NA = L.FIELD_NA
Names.NI = L.FIELD_NI
Names.NT = L.FIELD_NT
Names.NH = L.FIELD_NH
Names.AH = L.FIELD_AH
Names.AW = L.FIELD_AW
Names.AE = L.FIELD_AE
Names.RA = L.FIELD_RA
Names.RC = L.FIELD_RC
Names.CU = L.FIELD_CU
Names.PE = L.FIELD_PE
Names.DE = L.FIELD_DE
Names.AG = L.FIELD_AG
Names.HH = L.FIELD_HH
Names.HB = L.FIELD_HB
Names.MO = L.FIELD_MO
Names.HI = L.FIELD_HI
Names.FR = L.FIELD_FR
Names.FC = L.FIELD_FC
Names.VA = L.FIELD_VA
Names.PX = L.FIELD_PX
Names.CO = L.FIELD_CO
Names.IC = L.FIELD_IC
-- Metadata fields.
Names.VP = L.FIELD_VP
Names.GC = L.FIELD_GC
Names.GF = L.FIELD_GF
Names.GR = L.FIELD_GR
Names.GS = L.FIELD_GS
Names.GU = L.FIELD_GU
-- Internal fields.
Names.TT = L.FIELD_TT
Names.VW = L.FIELD_VW

local MenuNames = setmetatable({}, { __index = Names })
MenuNames.FR = L.FIELD_FR_MENU
MenuNames.FC = L.FIELD_FC_MENU
-- Metadata fields.
MenuNames.VP = L.FIELD_VP_MENU
MenuNames.GC = L.FIELD_GC_MENU
MenuNames.GF = L.FIELD_GF_MENU
MenuNames.GR = L.FIELD_GR_MENU
MenuNames.GS = L.FIELD_GS_MENU

local Values = {}

Values.FC = {}
Values.FC["1"] = L.VALUE_FC_1
Values.FC["2"] = L.VALUE_FC_2
Values.FC["3"] = L.VALUE_FC_3
Values.FC["4"] = L.VALUE_FC_4

Values.FR = {}
Values.FR["1"] = L.VALUE_FR_1
Values.FR["2"] = L.VALUE_FR_2
Values.FR["3"] = L.VALUE_FR_3
Values.FR["4"] = L.VALUE_FR_4

Values.GC = setmetatable({}, {
	__index = function(self, key)
		-- Randomly select male or female when unknown.
		return self[tostring(fastrandom(2, 3))]
	end,
})
Values.GC["2"] = FillLocalizedClassList({}, false) -- Male forms
Values.GC["3"] = FillLocalizedClassList({}, true) -- Female forms

Values.GF = {}
Values.GF.Alliance = FACTION_ALLIANCE
Values.GF.Horde = FACTION_HORDE
Values.GF.Neutral = L.VALUE_GF_NEUTRAL

Values.GR = {}
Values.GR.BloodElf = L.VALUE_GR_BLOODELF
Values.GR.Draenei = L.VALUE_GR_DRAENEI
Values.GR.DarkIronDwarf = L.VALUE_GR_DARKIRONDWARF
Values.GR.Dwarf = L.VALUE_GR_DWARF
Values.GR.Gnome = L.VALUE_GR_GNOME
Values.GR.Goblin = L.VALUE_GR_GOBLIN
Values.GR.HighmountainTauren = L.VALUE_GR_HIGHMOUNTAINTAUREN
Values.GR.Human = L.VALUE_GR_HUMAN
Values.GR.KulTiran = L.VALUE_GR_KULTIRAN
Values.GR.LightforgedDraenei = L.VALUE_GR_LIGHTFORGEDDRAENEI
Values.GR.MagharOrc = L.VALUE_GR_MAGHARORC
Values.GR.NightElf = L.VALUE_GR_NIGHTELF
Values.GR.Nightborne = L.VALUE_GR_NIGHTBORNE
Values.GR.Orc = L.VALUE_GR_ORC
Values.GR.Pandaren = L.VALUE_GR_PANDAREN
Values.GR.Scourge = L.VALUE_GR_SCOURGE
Values.GR.Tauren = L.VALUE_GR_TAUREN
Values.GR.Troll = L.VALUE_GR_TROLL
Values.GR.VoidElf = L.VALUE_GR_VOIDELF
Values.GR.Worgen = L.VALUE_GR_WORGEN
Values.GR.ZandalariTroll = L.VALUE_GR_ZANDALARITROLL

Values.GS = {}
Values.GS["1"] = UNKNOWN
Values.GS["2"] = MALE
Values.GS["3"] = FEMALE

local MenuValues = setmetatable({}, { __index = Values })

MenuValues.FC = setmetatable({}, { __index = Values.FC })
MenuValues.FC["0"] = PARENS_TEMPLATE:format(NONE)
MenuValues.FC["1"] = L.VALUE_FC_1_MENU
MenuValues.FC["2"] = L.VALUE_FC_2_MENU
MenuValues.FC["3"] = L.VALUE_FC_3_MENU
MenuValues.FC["4"] = L.VALUE_FC_4_MENU

MenuValues.FR = setmetatable({}, { __index = Values.FR })
MenuValues.FR["0"] = PARENS_TEMPLATE:format(NONE)
MenuValues.FR["1"] = L.VALUE_FR_1_MENU
MenuValues.FR["2"] = L.VALUE_FR_2_MENU
MenuValues.FR["3"] = L.VALUE_FR_3_MENU
MenuValues.FR["4"] = L.VALUE_FR_4_MENU

AddOn_XRP.Strings.Names = Names
AddOn_XRP.Strings.Values = Values
AddOn_XRP.Strings.MenuNames = MenuNames
AddOn_XRP.Strings.MenuValues = MenuValues
