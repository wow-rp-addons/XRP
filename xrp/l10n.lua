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

local L = setmetatable({}, {
	__index = function(L, key)
		return key
	end,
	__newindex = function(L, key, value)
	end,
	__call = function(L, arg1)
	end,
	__metatable = false,
})

xrp.L = L

xrp.fields = {
	-- Biography fields.
	NA = NAME, -- "Name"
	NI = L["Nickname"],
	NT = L["Title"],
	NH = L["House/Clan/Tribe"],
	AE = L["Eyes"],
	RA = RACE, -- "Race"
	AH = L["Height"],
	AW = L["Weight"],
	CU = L["Currently"],
	DE = L["Description"],
	-- History fields.
	AG = L["Age"],
	HH = HOME, -- "Home"
	HB = L["Birthplace"],
	MO = L["Motto"],
	HI = HISTORY, -- "History"
	-- OOC fields.
	FR = L["Roleplaying style"],
	FC = L["Character status"],
	-- Addon fields.
	VA = L["Addon version"],
	VP = L["Protocol version"],
	-- Hidden fields.
	GC = L["Toon class"],
	GF = L["Toon faction"],
	GR = L["Toon race"],
	GS = L["Toon gender"],
	GU = L["Toon GUID"],
	-- Metadata fields.
	XC = L["MSP chunks"],
}

xrp.values = {
	RA = {
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

-- Sigh, global variable pollution. FrameXML needs it, though -- and at least
-- we're prefixing with XRP_.
for field, name in pairs(xrp.fields) do
	_G["XRP_"..field] = name
end

XRP = GetAddOnMetadata("xrp", "Title") -- In other words, XRP = "XRP"... Huh.

BINDING_HEADER_XRP = XRP
BINDING_NAME_XRP_EDITOR = L["Toggle RP profile editor"]
BINDING_NAME_XRP_VIEWER = L["View target's RP profile"]
BINDING_NAME_XRP_VIEWER_TOGGLE = L["Toggle RP profile viewer"]

XRP_AUTHOR = format("%s%s:|r %s", "|cff99b3e6", L["Author"], GetAddOnMetadata("xrp", "Author"))
XRP_VERSION = format("%s%s:|r %s", "|cff99b3e6", GAME_VERSION_LABEL, GetAddOnMetadata("xrp", "Version"))
XRP_COPYHEADER = L["License/Copyright"]
XRP_COPYRIGHT = "(C) 2014 Bor Blasthammer <bor@blasthammer.net>"
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
