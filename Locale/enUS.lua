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

local FOLDER_NAME, AddOn = ...

local LOCALE = "enUS"

local AddLocale, _G = AddOn.AddLocale, _G
local ConstantTable = {}
--local LookupTable = {}

_G.setfenv(1, ConstantTable)

-- Standard field names suited for most display.
FIELD_NA = "Name"
FIELD_NI = "Nickname"
FIELD_NT = "Title"
FIELD_NH = "House/Clan/Tribe"
FIELD_AH = "Height"
FIELD_AW = "Weight"
FIELD_AE = "Eyes"
FIELD_RA = "Race"
FIELD_RC = "Class"
FIELD_CU = "Currently"
FIELD_PE = "Glances"
FIELD_DE = "Description"
FIELD_AG = "Age"
FIELD_HH = "Home"
FIELD_HB = "Birthplace"
FIELD_MO = "Motto"
FIELD_HI = "History"
FIELD_FR = "Roleplaying style"
FIELD_FC = "Character status"
FIELD_VA = "Version"
FIELD_PX = "Prefix"
-- Below are implemented read-only.
FIELD_CO = "Currently (OOC)"
-- Below are metadata, not usually user-exposed.
FIELD_VP = "Protocol version"
FIELD_GC = "Toon class"
FIELD_GF = "Toon faction"
FIELD_GR = "Toon race"
FIELD_GS = "Toon gender"
FIELD_GU = "Toon GUID"
-- Below are not implemented by XRP.
FIELD_IC = "Icon"
-- Below are internal-only fields.
FIELD_TT = "Tooltip metafield"
FIELD_VW = "Detailed addon build info"

-- These are alternate field names suited for use in menus.
FIELD_FR_MENU = "Roleplaying Style"
FIELD_FC_MENU = "Character Status"
FIELD_VP_MENU = "Protocol Version"
FIELD_GC_MENU = "Toon Class"
FIELD_GF_MENU = "Toon Faction"
FIELD_GR_MENU = "Toon Race"
FIELD_GS_MENU = "Toon Gender"

-- Values not listed here have a context-appropriate translation available
-- in Blizzard's localization.
VALUE_FC_1 = "Out of character"
VALUE_FC_2 = "In character"
VALUE_FC_3 = "Looking for contact"
VALUE_FC_4 = "Storyteller"
VALUE_FR_1 = "Normal roleplayer"
VALUE_FR_2 = "Casual roleplayer"
VALUE_FR_3 = "Full-time roleplayer"
VALUE_FR_4 = "Beginner roleplayer"
VALUE_GR_BLOODELF = "Blood Elf"
VALUE_GR_DRAENEI = "Draenei"
VALUE_GR_DARKIRONDWARF = "Dark Iron Dwarf"
VALUE_GR_DWARF = "Dwarf"
VALUE_GR_GNOME = "Gnome"
VALUE_GR_GOBLIN = "Goblin"
VALUE_GR_HIGHMOUNTAINTAUREN = "Highmountain Tauren"
VALUE_GR_HUMAN = "Human"
VALUE_GR_KULTIRAN = "Kul Tiran"
VALUE_GR_LIGHTFORGEDDRAENEI = "Lightforged Draenei"
VALUE_GR_MAGHARORC = "Mag'har Orc"
VALUE_GR_NIGHTELF = "Night Elf"
VALUE_GR_NIGHTBORNE = "Nightborne"
VALUE_GR_ORC = "Orc"
VALUE_GR_PANDAREN = "Pandaren"
VALUE_GR_SCOURGE = "Undead"
VALUE_GR_TAUREN = "Tauren"
VALUE_GR_TROLL = "Troll"
VALUE_GR_VOIDELF = "Void Elf"
VALUE_GR_WORGEN = "Worgen"
VALUE_GR_ZANDALARITROLL = "Zandalari Troll"
VALUE_GF_NEUTRAL = "Neutral"

-- These are alternate values suited for use in menus.
VALUE_FC_1_MENU = "Out of Character"
VALUE_FC_2_MENU = "In Character"
VALUE_FC_3_MENU = "Looking for Contact"
VALUE_FR_1_MENU = "Normal Roleplayer"
VALUE_FR_2_MENU = "Casual Roleplayer"
VALUE_FR_3_MENU = "Full-Time Roleplayer"
VALUE_FR_4_MENU = "Beginner Roleplayer"

-- These are alternate values for certain races.
VALUE_GR_BLOODELF_ALT = "Sin'dorei"
VALUE_GR_NIGHTELF_ALT = "Kaldorei"
VALUE_GR_NIGHTBORNE_ALT = "Shal'dorei"
VALUE_GR_VOIDELF_ALT = "Ren'dorei"
VALUE_GR_SCOURGE_ALT = "Forsaken"
VALUE_GR_TAUREN_ALT = "Shu'halo"
VALUE_GR_HIGHMOUNTAINTAUREN_ALT = "Highmountain Shu'halo"

NICKNAME = "\"%s\""
NAME_REALM = "%s (%s)"
ASIDE = "%s [%s]"

OOC_TEXT = "((%s))"
OOC_STRIP = "^%(%((.-)%)%)$"

-- Backend/Utility.lua
-- Pattern matches for weight/height.
KG1 = "([%d%.]+)%s*kgs?%.?"
KG2 = "([%d%.]+)%s*kilo[grams]+"
LBS1 = "([%d%.]+)%s*lbs?%.?"
LBS2 = "([%d%.]+)%s*pounds?"
CM1 = "([%d%.]+)%s*cm%.?"
CM2 = "([%d%.]+)%s*centimet[ers]+"
M1 = "([%d%.]+)%s*m%.?"
M2 = "([%d%.]+)%s*met[ers]+"
FT1 = "(%d+)%s*'%s*(%d*)%s*[\"']*"
FT2 = "([%d%.]+)%s*ft%.?%s*([%d%.]*)[in%.]*"
FT3 = "([%d%.]+)%s*feet%s*([%d%.]*)[inches]*"
-- Format strings for weight/height display.
KG = "%.1f kg"
LBS = "%.0f lbs"
CM = "%.0f cm"
M = "%.2f m"
FT = "%.0f'%.0f\""

-- Backend/Import.lua
TRP3_NICKNAME = "Nickname"
TRP3_HOUSE_NAME = "House name"
TRP3_MOTTO = "Motto"

-- Shared UI strings
APPEARANCE = "Appearance"
BIOGRAPHY = "Biography"
GLANCES = "Glances"
ICONS = "Icons"
NAME_DESCRIPTION = "Name/Description"
NOTES = "Notes"
AUTHOR = "Author"
VIEW_CACHED = "View (Cached)"
VIEW_LIVE = "View (Live)"
BOOKMARK = "Bookmark"
HIDE_PROFILE = "Hide Profile"
DROP_CACHE = "Drop Cache"
FORCE_REFRESH = "Force Refresh"

-- ui/bookmarks.lua
ROLEPLAY_NAME = "Roleplay Name"
REALM = "Realm"
DATE = "Date"
SORT_BY = "Sort By"
FULL_SEARCH = "Full-Text Search"
REVERSE_SORT = "Reverse Sorting"
HAS_NOTES = "Has Notes"
INCLUDE_HIDDEN = "Include Hidden"
RESET_FILTERS = "Reset Filters"
OWN_CHARACTERS = "Own Characters"
RECENT_3HOURS = "Recently Seen (3 hours)"
ALL_PROFILES = "All Profiles"

-- ui/bookmarks.xml
ARCHIVE = "Archive"
BOOKMARKS = "Bookmarks"
OWN = "Own"
RECENT = "Recent"

-- Interface/Integration/Chat.lua
-- This is used mid-sentence, like "You look at nobody.", in place of a full
-- character name when one is not available.
NOBODY = "nobody"

-- Interface/Integration/Commands.lua
USAGE = "Usage"
-- These actually change the commands that can be run under /xrp. English
-- alternatives are always also allowed.
CMD_ABOUT = "about"
CMD_ARCHIVE = "archive"
CMD_CURRENTLY = "currently"
CMD_EDIT = "edit"
CMD_EXPORT = "export"
CMD_HELP = "help"
CMD_PROFILE = "profile"
CMD_STATUS = "status"
CMD_TOGGLE = "toggle"
CMD_VIEW = "view"
ARG_CURRENTLY_NIL = "nil"
ARG_PROFILE_LIST = "list"
ARG_STATUS_NIL = "nil"
ARG_STATUS_IC = "ic"
ARG_STATUS_OOC = "ooc"
ARG_STATUS_LFC = "lfc"
ARG_STATUS_ST = "st"

-- ui/editor.lua
PARENT = "Parent"
PROFILE_EDITOR = "Profile Editor"
RENAME = "Rename"
COPY = "Copy"
WARNING = "Warning"
FORM_SET = "Form/set"
PROFILE_FOR_FORM = "Profile for selected form/set"
CLEAR = "Clear"

-- ui/editor.xml
AUTOMATION = "Automation"
USE_PARENT = "Use parent profile if blank."
EXPORT = "Export"

-- ui/export.xml
EXPORT_PROFILE = "Export Profile"

-- ui/menus.lua
ROLEPLAY_PROFILE = "Roleplay Profile"

-- ui/minimap.lua
VIEW_TARGET_LDB = "View Target"
PROFILE = "Profile"
STATUS = "Status"
PROFILES = "Profiles"
VIEWER = "Viewer"
EDITOR = "Editor"
OPTIONS = "Options"

-- Interface/Options/Templates.lua
CENTIMETERS = "Centimeters"
FEET_INCHES = "Feet/Inches"
METERS = "Meters"
KILOGRAMS = "Kilograms"
POUNDS = "Pounds"
TOOLTIP = "Tooltip"
ALT_RACE_ELVEN = "Elven"
ALT_RACE_TAUREN = "Tauren"

-- Interface/Options/*xml
DISABLE_REQUIRES_RELOAD = "This option requires a UI reload (via /reload) to fully-disable.\n\nIt's recommended that you reload your UI at your earliest convenience."
FRIENDS_ONLY_ENABLE_WARNING = "This option is STRONGLY DISCOURAGED for normal use. Enabling this option will prevent you from seeing most roleplay profiles, and should only be used if you understand what this does and why you want it.\n\nAfter enabling this option, it is recommended to clear your cache for the option to fully take effect. You may need to wait a couple minutes before doing so, or clear it a second time after a couple minutes."
GUILD_IS_FRIENDS_DISABLE_WARNING = "After disabling this option, it is recommended to clear your cache for the option to fully take effect. You may need to wait a couple minutes before doing so, or clear it a second time after a couple minutes."

-- Interface/Options/Options.lua
LICENSE = "License"

-- Interface/Tooltip/Tooltip.lua
QUOTE_MATCH = "^['\"].-['\"]$"
HIDDEN = "Hidden"
LETHAL_LEVEL = "??"
GUILD = "<%s>"
GUILD_RANK = "%s of <%s>"
GUILD_RANK_INDEX = "%s (%d) of <%s>"
-- These must match in-game returns from UnitCreatureType().
PET_BEAST = "Beast"
PET_MECHANICAL = "Mechanical"
PET_UNDEAD = "Undead"
PET_ELEMENTAL = "Elemental"
PET_DEMON = "Demon"
-- These must match UnitCreatureFamily() returns.
PET_GHOUL = "Ghoul"
PET_WATER_ELEMENTAL = "Water Elemental"
-- These must match UnitName() returns.
PET_NAME_RISEN_SKULKER = "Risen Skulker"
PET_NAME_HATI = "Hati"

-- Interface/Viewer/Viewer.lua
SEND_TWEET = "Send Tweet"
COPY_URL = "Copy URL"
REPORT_PROFILE = "Reporting Info"

-- Interface/Viewer/Viewer.xml
PROFILE_VIEWER = "Profile Viewer"

AddLocale(LOCALE, ConstantTable, LookupTable)
