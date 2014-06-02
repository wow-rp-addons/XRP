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

local L = xrp.L

-- Some of these are defined in the global WoW strings (i.e., "Home" or
-- "History"), but the contexts are such that the localization might not
-- always match. "Name" and "Race" are used in their in-game contexts.

XRP_APPEARANCE = L["Appearance"]
-- Appearance fields.
XRP_NA = NAME -- "Name"
XRP_NI = L["Nickname"]
XRP_NT = L["Title"]
XRP_NH = L["House/Clan/Tribe"]
XRP_AE = L["Eyes"]
XRP_RA = RACE -- "Race"
XRP_AH = L["Height"]
XRP_AW = L["Weight"]
XRP_CU = L["Currently"]
XRP_DE = L["Description"]

XRP_BIOGRAPHY = L["Biography"]
-- Biography fields.
XRP_AG = L["Age"]
XRP_HH = L["Home"]
XRP_HB = L["Birthplace"]
XRP_MO = L["Motto"]
XRP_HI = L["History"]

-- OOC fields.
XRP_FR = L["Roleplaying style"]
XRP_FC = L["Character status"]

-- Metadata fields.
XRP_VA = L["Addon version"]
XRP_VP = L["Protocol version"]

-- Toon fields.
XRP_GC = L["Toon class"]
XRP_GF = L["Toon faction"]
XRP_GR = L["Toon race"]
XRP_GS = L["Toon gender"]
XRP_GU = L["Toon GUID"]

-- Dummy fields.
XRP_XC = L["MSP chunks"]
XRP_XD = L["Dummy field"]

xrp.values = {
	GR = {
		Dwarf = L["Dwarf"],
		Draenei = L["Draenei"],
		Gnome = L["Gnome"],
		Human = L["Human"],
		NightElf = L["Night Elf"],
		Worgen = L["Worgen"],
		BloodElf = L["Blood Elf"],
		Goblin = L["Goblin"],
		Orc = L["Orc"],
		Scourge = L["Undead"], -- Yes, Scourge.
		Tauren = L["Tauren"],
		Troll = L["Troll"],
		Pandaren = L["Pandaren"],
	},
	-- TODO: ["0"], ["1"], etc. formatting.
	FR = {
		L["Normal roleplayer"],
		L["Casual roleplayer"],
		L["Full-time roleplayer"],
		L["Beginner roleplayer"],
		L["Mature roleplayer"], -- This isn't standard (?) but is used sometimes.
	},
	FR_EMPTY = L["(Style not set)"],
	FC = {
		L["Out of character"],
		L["In character"],
		L["Looking for contact"],
		L["Storyteller"],
	},
	FC_EMPTY = L["(Status not set)"],
}

XRP = GetAddOnMetadata("xrp", "Title") -- In other words, XRP = "XRP"... Huh.

BINDING_HEADER_XRP = XRP
BINDING_NAME_XRP_EDITOR = L["Open/close RP profile editor"]
BINDING_NAME_XRP_VIEWER = L["View target's or mouseover's RP profile"]
BINDING_NAME_XRP_VIEWER_TARGET = L["View target's RP profile"]
BINDING_NAME_XRP_VIEWER_MOUSEOVER = L["View mouseover's RP profile"]

local info = "|cff99b3e6%s:|r %s"
XRP_AUTHOR = info:format(L["Author"], GetAddOnMetadata("xrp", "Author"))
XRP_VERSION = info:format(GAME_VERSION_LABEL, GetAddOnMetadata("xrp", "Version"))
XRP_COPYHEADER = L["License/Copyright"]

-- Copyright line should not be localized.
XRP_COPYRIGHT = "(C) 2014 Bor Blasthammer <bor@blasthammer.net>"

-- These two should, ideally, be taken from FSF translations.
XRP_LICENSE = L[ [[This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.]] ]
XRP_LICENSE_SHORT = L[ [[License: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.]] ]

XRP_CLEAR_CACHE = L["Clear Cache"]
XRP_TIDY_CACHE = L["Tidy Cache"]
