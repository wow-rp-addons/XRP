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

local LANGUAGE = "en"

local addonName, _xrp = ...
if _xrp.language ~= LANGUAGE then return end
setfenv(1, _xrp.L)

local UNTRANSLATED = " (Needs translation.)"

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
FIELD_DE = "Description"
FIELD_AG = "Age"
FIELD_HH = "Home"
FIELD_HB = "Birthplace"
FIELD_MO = "Motto"
FIELD_HI = "History"
FIELD_FR = "Roleplaying style"
FIELD_FC = "Character status"
FIELD_VA = "Version"
-- Below are metadata, not usually user-exposed.
FIELD_VP = "Protocol version"
FIELD_GC = "Toon class"
FIELD_GF = "Toon faction"
FIELD_GR = "Toon race"
FIELD_GS = "Toon gender"
FIELD_GU = "Toon GUID"
-- Below are not implemented by XRP.
FIELD_IC = "Icon"
FIELD_CO = "Currently (OOC)"

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
VALUE_FR_5 = "Mature roleplayer"
VALUE_GR_BLOODELF = "Blood Elf"
VALUE_GR_DRAENEI = "Draenei"
VALUE_GR_DWARF = "Dwarf"
VALUE_GR_GNOME = "Gnome"
VALUE_GR_GOBLIN = "Goblin"
VALUE_GR_HUMAN = "Human"
VALUE_GR_NIGHTELF = "Night Elf"
VALUE_GR_ORC = "Orc"
VALUE_GR_PANDAREN = "Pandaren"
VALUE_GR_SCOURGE = "Undead"
VALUE_GR_TAUREN = "Tauren"
VALUE_GR_TROLL = "Troll"
VALUE_GR_WORGEN = "Worgen"
VALUE_GF_NEUTRAL = "Neutral"

-- These are alternate values suited for use in menus.
VALUE_FC_1_MENU = "Out of Character"
VALUE_FC_2_MENU = "In Character"
VALUE_FC_3_MENU = "Looking for Contact"
VALUE_FR_1_MENU = "Normal Roleplayer"
VALUE_FR_2_MENU = "Casual Roleplayer"
VALUE_FR_3_MENU = "Full-Time Roleplayer"
VALUE_FR_4_MENU = "Beginner Roleplayer"
VALUE_FR_5_MENU = "Mature Roleplayer"

-- These are alternate values for certain races.
VALUE_GR_BLOODELF_ALT = "Sin'dorei"
VALUE_GR_NIGHTELF_ALT = "Kaldorei"
VALUE_GR_SCOURGE_ALT = "Forsaken"
VALUE_GR_TAUREN_ALT = "Shu'halo"

NICKNAME = "\"%s\""
NAME_REALM = "%s (%s)"
ASIDE = "%s [%s]"

-- xrp.lua
NEW_VERSION = "There is a new version of |cffabd473XRP|r available. You should update to %s as soon as possible."

-- settings.lua
RENAMED_FORMAT = "%s Renamed"

-- core/automation.lua
TREANT_BUFF = "Treant Form" -- Must match in-game name of Treant buff.

-- core/msp.lua
MSP_DISABLED = "You are currently running two roleplay profile addons. XRP's support for sending and receiving profiles is disabled; to fully use XRP, disable \"%s\" and reload your UI."

-- core/utils.lua
-- Pattern matches for weight/height.
KG1 = "([%d%.]+)%s*kgs?%.?"
KG2 = "([%d%.]+)%s*kilo[grams]+"
LBS1 = "([%d%.]+)%s*lbs?%.?"
LBS2 = "([%d%.]+)%s*pounds?"
CM1 = "([%d%.]+)%s*cm%.?"
CM2 = "([%d%.]+)%s*centimet[ers]+"
M1 = "([%d%.]+)%s*m%.?"
M2 = "([%d%.]+)%s*met[ers]+"
FT1 = "(%d+)%s*'%s*(%d*)%s*\"?"
FT2 = "([%d%.]+)%s*ft%.?%s*([%d%.]*)[in%.]*"
FT3 = "([%d%.]+)%s*feet%s*([%d%.]*)[inches]*"
-- Format strings for weight/height display.
KG = "%.1f kg"
LBS = "%.0f lbs"
CM = "%.0f cm"
M = "%.2f m"
FT = "%.0f'%.0f\""

-- extra/fixes.lua
CUF_WARNING = "The raid profile configuration panel has been accessed, which may cause UI problems due to Blizzard bugs (inaccurately blaming \"%s\" or others). You should reload your UI now to avoid this."

-- extra/import.lua
IMPORT_RELOAD = "Available profiles have been imported and may be found in the editor's profile list. You should reload your UI now."
HEIGHT_VSHORT = "Very short"
HEIGHT_SHORT = "Short"
HEIGHT_AVERAGE = "Average"
HEIGHT_TALL = "Tall"
HEIGHT_VTALL = "Very tall"
WEIGHT_HEAVY = "Overweight"
WEIGHT_REGULAR = "Regular"
WEIGHT_MUSCULAR = "Muscular"
WEIGHT_SKINNY = "Skinny"
IMPORT_FACE = "Face: %s"
IMPORT_MODS = "Piercings/Tattoos: %s"
TRP3_NICKNAME = "Nickname"
TRP3_HOUSE_NAME = "House name"
TRP3_MOTTO = "Motto"

-- Bindings.xml
TOGGLE_STATUS = "Toggle IC/OOC Status"
TOGGLE_BOOKMARKS = "Toggle RP Profile Bookmarks"
VIEW_TARGET_MOUSEOVER = "View RP Profile of Target/Mouseover"
VIEW_TARGET = "View RP Profile of Target"
VIEW_MOUSEOVER = "View RP Profile of Mouseover"
TOGGLE_EDITOR = "Toggle RP Profile Editor"

-- Shared UI strings
APPEARANCE = "Appearance"
BIOGRAPHY = "Biography"
NOTES = "Notes"
AUTHOR = "Author"
VIEW_CACHED = "View (Cached)"
VIEW_LIVE = "View (Live)"
BOOKMARK = "Bookmark"
HIDE_PROFILE = "Hide Profile"
DROP_CACHE = "Drop Cache"
FORCE_REFRESH = "Force Refresh"
NOTES_INSTRUCTIONS = "You can store private notes here. They will never be visible to other players.\n\nNotes are accessible on all your characters and are automatically saved when you close this panel."

-- ui/automation.lua
STANDARD = "Standard"
HUMANOID = "Humanoid"
NOEQUIP = "No Equipment Set"
CAT = "Cat Form"
BEAR = "Bear Form"
MOONKIN = "Moonkin Form"
ASTRAL = "Astral Form"
AQUATIC = "Travel Form (Aquatic)"
TRAVEL = "Travel Form (Land)"
FLIGHT = "Travel Form (Flight)"
TREANT = "Treant Form"
SHADOWFORM = "Shadowform"
GHOST_WOLF = "Ghost Wolf"
WORGEN_SHADOW = "Shadowform (Worgen)"
HUMAN_SHADOW = "Shadowform (Human)"
WARN_FALLBACK = "You should set a fallback profile for \"%s\"."
NO_SETS = "No Equipment Sets"

-- ui/bookmarks.lua
TOTAL_LIST = "Listing %d of %d profiles."
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
NO_PROFILES_FOUND = "No profiles found."
PRESS_ENTER_SEARCH = "Press enter to search."
BOOKMARKS = "Bookmarks"
OWN = "Own"
RECENT = "Recent"

-- ui/chat.lua
-- This is used mid-sentence, like "You look at nobody.", in place of a full
-- character name when one is not available.
NOBODY = "nobody"

-- ui/commands.lua
USAGE = "Usage"
-- This can add (not replace) an alternative to /xrp if appropriate for your
-- language, such as something easier to type on a common input device.
--SLASH_XRP = "/xrp"
-- These actually change the commands that can be run under /xrp. English
-- alternatives are always also allowed.
CMD_ABOUT = "about"
CMD_BOOKMARKS = "bookmarks"
CMD_EDIT = "edit"
CMD_EXPORT = "export"
CMD_HELP = "help"
CMD_PROFILE = "profile"
CMD_STATUS = "status"
CMD_TOGGLE = "toggle"
CMD_VIEW = "view"
ARG_PROFILE_LIST = "list"
ARG_STATUS_NIL = "nil"
ARG_STATUS_IC = "ic"
ARG_STATUS_OOC = "ooc"
ARG_STATUS_LFC = "lfc"
ARG_STATUS_ST = "st"
-- These are just standard texts again.
COMMANDS_HELP = "Use /xrp help [command] for more usage information."
ABOUT_HELP = "Show basic information about XRP."
BOOKMARKS_HELP = "Toggle the bookmarks frame open/closed."
EDIT_HELP = "Access the editor."
EXPORT_HELP = "Export a character's profile to plain text."
HELP_HELP = "Display /xrp command help."
PROFILE_HELP = "Set your current profile."
STATUS_HELP = "Set your character status."
TOGGLE_HELP = "Toggle IC/OOC status."
VIEW_HELP = "View a character's profile."
COMMANDS = "<command>"
ARGUMENTS = "[argument]"
EDIT_ARGS = "[<Profile>]"
EDIT_ARG1 = "<none>"
EDIT_ARG1_HELP = "Toggle the editor open/closed."
EDIT_ARG2 = "<Profile>"
EDIT_ARG2_HELP = "Open a profile for editing."
EXPORT_ARG1 = "<Character>"
EXPORT_ARG1_HELP = "Export the cached profile of the named character."
PROFILE_ARGS = "[list|<Profile>]"
PROFILE_ARG1_HELP = "List all profiles."
PROFILE_ARG2 = "<Profile>"
PROFILE_ARG2_HELP = "Set current profile to the named profile."
STATUS_ARGS = "[nil|ooc|ic|lfc|st]"
STATUS_ARG1_HELP = "Reset to profile default."
STATUS_ARG2_HELP = "Set to out of character."
STATUS_ARG3_HELP = "Set to in character."
STATUS_ARG4_HELP = "Set to looking for contact."
STATUS_ARG5_HELP = "Set to storyteller."
VIEW_ARGS = "[<Unit>|<Character>]"
VIEW_ARG1 = "<none>"
VIEW_ARG1_HELP = "View your target or mouseover's profile, as available."
VIEW_ARG2 = "<Unit>"
VIEW_ARG2_HELP = "View a unit's profile, such as \"target\" or \"mouseover\"."
VIEW_ARG3 = "<Character>"
VIEW_ARG3_HELP = "View the profile of the named character."
GPL_SHORT = "License: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>\nThis is free software: you are free to change and redistribute it.\nThere is NO WARRANTY, to the extent permitted by law."
SET_PROFILE = "Set profile to \"%s\"."
SET_PROFILE_FAIL = "Failed to set profile to \"%s\"."

-- ui/editor.lua
PARENT = "Parent"
PROFILE_EDITOR = "Profile Editor"
RENAME = "Rename"
COPY = "Copy"
WARNING = "Warning"
WARNING_LENGTH = "%s is over %d characters."
FORM_SET = "Form/set"
PROFILE_FOR_FORM = "Profile for selected form/set"

-- ui/editor.xml
AUTOMATION = "Automation"
USE_PARENT = "Use parent profile if blank."
EXPORT = "Export"

-- ui/export.xml
EXPORT_PROFILE = "Export Profile"
EXPORT_INSTRUCTIONS = "Press %s to copy or Escape to close."

-- ui/help.lua
HELP_BOOKMARKS_FILTER = "You can filter the list of profiles in a number of ways, including by class, race, and faction.\n\nThe results of your filter choices can be sorted by character name, roleplay name, realm then character name, or date.\n\nYou can also perform a full-profile search by enabling the full-text filter. This may be slow if you have many profiles cached, so you'll have to press enter to trigger the search after typing."
HELP_BOOKMARKS_ENTRIES = "Each of these entries displays a profile XRP has cached, matching your filter selections.\n\nTo interact with these entries, right-click on them and a menu with a number of options will appear.\n\nIn this menu, you can access the cached profile, export the profile, or even add the character directly to your friends list."
HELP_BOOKMARKS_NUMBER = "The number of profiles matching your filter results is indicated here.\n\nHidden profiles are not shown by default, so even the \"All\" view may not list everything initially!"
HELP_BOOKMARKS_TABS = "Each of these tabs provides a predefined filter, \"Bookmarks\" and \"All\" being self-explanatory.\n\nThe \"Own\" tab lists your own characters from this WoW account, and the \"Recent\" tab lists profiles XRP has seen in the past three hours, sorted by most recent first."
HELP_EDITOR_CONTROLS = "These controls manage the profile you're editing.\n\nThe dropdown selects a profile to edit, and the buttons allow you to add or remove profiles.\n\nYou can add and delete profiles at will. The only exception is that XRP won't let you delete your currently-active profile!"
HELP_EDITOR_MENU = "This button accesses the editor's menu. In this menu you can access your private notes, export your profile, rename or copy your profile, or access the automated profile controls.\n\nIf you open this help system with the automated profile controls visible, more help on that feature is available."
HELP_EDITOR_PARENT = "This button allows you to select a parent profile for the profile you're editing.\n\nHaving a parent profile lets you select fields, using the checkboxes next to the field names, to inherit from the parent profile if they're empty on this profile. Any inherited fields will show in a light grey text color, rather than white.\n\nYou can even use a profile that has a parent as a different profile's parent, up to 50 levels deep."
HELP_EDITOR_BUTTONS = "This pair of buttons is only available when you've made changes to the profile you're editing.\n\nIf you've made changes, pressing \"Revert\" will discard any changes you've made since the profile was last saved.\n\nPressing \"Save\" will save any changes you've made, including field text changes and parent/inheritance changes."
HELP_EDITOR_AUTO_FORM = "Select a form, equipment set, or form/equipment set combination from this menu.\n\nNote that you can select a form itself, even if there's a submenu with equipment sets. Just click on the form name anyway!"
HELP_EDITOR_AUTO_PROFILE = "Select a profile to use with the form/set you've selected above.\n\nA profile can be used for any number of forms/sets, and XRP will try to pick the closest match to your current form/set when you switch."
HELP_EDITOR_AUTO_BUTTONS = "When available, these buttons control the saving of a selection. Reverting will reset the selection back to the last-saved choice.\n\nWhen saving, if the profile would be active due to your current form, it will immediately be activated.\n\nWhen activating automatically at other times, there is a brief delay after changing forms/sets or after leaving combat."
HELP_EDITOR_NA = "The name field should generally be used for your character's full name, without titles.\n\nKeep in mind that some races/cultures may not often have family names or last names!"
HELP_EDITOR_NI = "The nickname field is used for nickname(s) your character is commonly known by.\n\nGenerally, limiting this to two or three items, at most, is sensible."
HELP_EDITOR_AH = "The height field is for your character's physical height.\n\nYou may either enter a specific height or a few-word description of their size.\n\nIf you enter a number without units, the number is assumed to be in centimeters."
HELP_EDITOR_NT = "The title field is for your character's titles, including both official and unofficial titles.\n\nGenerally, try to limit how many titles you enter here. Much more than two or three is often excessive."
HELP_EDITOR_NH = "The house/clan/tribe field is for your character's ancestry, if they belong to a distinct group.\n\nMost races do not often have any of these, so leaving this empty is common."
HELP_EDITOR_AW = "The weight field is for your character's physical weight.\n\nAs with height, you may enter a specific weight or a brief description of their body shape.\n\nIf you enter a number without units, the number is assumed to be in kilograms."
HELP_EDITOR_AE = "The eyes field is for a brief description of your character's eyes.\n\nFor many characters this will be simple, often just indicating their eye color.\n\nA short, straightforward description is typically best -- while poetic language may be tempting, it can be difficult for others to understand."
HELP_EDITOR_RA = "The race field is for your character's race, if it is different from their race in-game.\n\nThis can be used for sub-races, such as \"Dark Iron Dwarf\", or for entirely separate races.\n\nIn general, exercise caution when using this field, as exotic races can be difficult to roleplay."
HELP_EDITOR_RC = "The class field is for your character's class, if it is different from their in-game class\n\nThis can be used as a more accurate description of your character's skills, such as \"Sniper\", or to explicitly note that their in-game class is irrelevant in roleplay, such as by using \"Civilian\"."
HELP_EDITOR_CU = "The currently field is for what your character is currently doing, usually no more than a single sentence.\n\nIf this is set here, it will be the default setting when using this profile.\n\nSetting this from XRP's minimap icon will set a temporary state, which reverts ten minutes after logging out."
HELP_EDITOR_DE = "The description field is for a physical description of your character.\n\nGenerally it is most useful to restrict yourself to what would be visible to others about your character in a normal setting.\n\nAdditionally, try to keep this to a reasonable length. Much more than a few hundred words may be excessively long."
HELP_EDITOR_AG = "The age field is, unsurprisingly, for your character's age.\n\nYou may either enter a specific value (generally assumed to be in years), or a brief description, such as \"Old\".\n\nSome races age at different rates, and some of those rates are poorly explained in lore. If in doubt, a brief description may be best."
HELP_EDITOR_HH = "The home field is for your character's current residence.\n\nFairly self-explanatorily, this typically means where they spend most of their time, be it a city, town, or even something vague, such as \"Wherever they happen to be.\"."
HELP_EDITOR_HB = "The birthplace field is for your character's place of birth.\n\nIt's particularly useful to fill this out if your character was born in an unusual place, such as a human raised among dwarves."
HELP_EDITOR_MO = "The motto field is for a brief (typically single-sentence) description of your character's outlook on life.\n\nIf your character happens to explicitly have a motto, then that is also a good thing to use here.\n\nIf in doubt, this field is commonly left empty."
HELP_EDITOR_HI = "The history field is for a brief outline of your character's history.\n\nTypically, it is most useful to fill out only the sort of information which would be readily available, if someone were to seek it out, or any aspects of their history which could be gleaned from observing them.\n\nAs with your description, keeping this short is often the best choice. Much more than a few hundred words may be excessive."
HELP_EDITOR_FR = "The roleplaying style field is for a brief description of any important information about your writing or story methods that needs to be immediately known.\n\nSometimes this is used to indicate someone who is always, no matter what, in-character, or to indicate an interest in a specific type of roleplay."
HELP_EDITOR_FC = "The character status field allows you to notify others as to whether you might be interested in roleplay at the moment or not.\n\nTypically, setting this to whatever state you're most commonly in, such as \"Out of character\", is sensible.\n\nXRP's minimap button can be used to temporarily toggle your status to the opposite of what is selected here."
HELP_VIEWER_MENU = "This button accesses the viewer's menu. In this menu you can refresh the profile (once every 30 seconds), add the character to your bookmarks or friends list, or even export the profile to plain text."
HELP_VIEWER_LINES = "These lines show, from top to bottom, nicknames, titles, and house/clan/tribe.\n\nIf there is more text than can be shown (an ellipses will be visible at the end), you can mouseover the line to see the full text in a tooltip."
HELP_VIEWER_SHORT = "The shorter fields displayed here may not always be able to show the full text of a field. If that happens, mousing over the field will display a tooltip with the full text.\n\nAdditionally, the height and weight fields are, whenever possible, automatically converted to match the units you've selected in XRP's interface options."
HELP_VIEWER_LONG = "The longer fields displayed here will have scroll bars appear if the text is too lengthy to fit in the field as-is.\n\nIn addition, most internet links will be displayed in |cffc845faepic purple|r. When clicked, a box will pop up, allowing you to copy the link."
HELP_VIEWER_ADDONS = "The names and versions of certain addons active for the profile's subject are displayed here.\n\nIf there is too much text to display in the short line available, mouseover will display the full list."
HELP_VIEWER_STATUS = "The incoming status of the profile currently being viewed is displayed here. In general, it will show whether the profile is in the process of receiving or whether it has been received."
HELP_VIEWER_RESIZE = "The small handle here may be clicked and dragged to resize the viewer window.\n\nTo reset the size of the viewer, right-click on it instead."

-- ui/menus.lua
ROLEPLAY_PROFILE = "Roleplay Profile"

-- ui/minimap.lua
PROFILE = "Profile"
STATUS = "Status"
CLICK_VIEW_TARGET = "Click to view your target's profile."
CLICK_IC = "Click for in character."
CLICK_OOC = "Click for out of character."
RTCLICK_MENU = "Right click for the menu."
PROFILES = "Profiles"
VIEWER = "Viewer"
EDITOR = "Editor"
OPTIONS = "Options"

-- ui/options.lua
CENTIMETERS = "Centimeters"
FEET_INCHES = "Feet/Inches"
METERS = "Meters"
KILOGRAMS = "Kilograms"
POUNDS = "Pounds"
TIME_1DAY = "1 Day"
TIME_3DAY = "3 Days"
TIME_7DAY = "7 Days"
TIME_10DAY = "10 Days"
TIME_2WEEK = "2 Weeks"
TIME_1MONTH = "1 Month"
TIME_3MONTH = "3 Months"
TOOLTIP = "Tooltip"
GENERAL_OPTIONS = "Configure the core XRP options, dealing with the user interface. Note that some of these options may require a UI reload (/reload) to fully enable/disable in some cases."
DISPLAY_OPTIONS = "Configure the display options for XRP, changing how some roleplay information is displayed in-game."
CHAT_OPTIONS = "Configure the chat-related options for XRP, primarily roleplay names in chat."
TOOLTIP_OPTIONS = "Configure the options available for XRP's tooltip display. By default, this overwrites the default tooltip and may conflict with other tooltip-modifying addons."
ADVANCED_OPTIONS = "Configure advanced XRP options. Please exercise caution when changing these."
CACHE_EXPIRY_TIME = "Cache expiry time"
CACHE_AUTOCLEAN = "Automatically clean old cache entries"
ENABLE_ROLEPLAY_NAMES = "Enable roleplay names in chat for:"
EMOTE_SQUARE_BRACES = "Show square brackets around names in emotes"
XT_XF_REPLACE = "Replace %xt and %xf with roleplay names of target and focus in chat"
ALT_RACE = "Display \"%s\" in place of \"%s\" for character race"
ALT_RACE_FORCE = "Force others to see \"%s\" for your character's race, if appropriate"
MOVABLE_VIEWER = "Enable profile viewer movement via click/drag on title bar"
CLOSE_ESCAPE_VIEWER = "Close profile viewer by pressing escape"
HEIGHT_DISPLAY = "Height display units"
WEIGHT_DISPLAY = "Weight display units"
DISPLAY_BOOK_CURSOR = "Display book icon next to cursor if character has a roleplay profile"
VIEW_PROFILE_RTCLICK = "View profile on right click"
DISABLE_INSTANCES = "Disable in instances (PvE and PvP)"
DISABLE_PVPFLAG = "Disable while PvP flagged"
VIEW_PROFILE_KEYBIND = "Enable profile viewing via Blizzard interact with target/mouseover keybinds"
RTCLICK_MENU_STANDARD = "Enable right-click menu entry in chat, friends list, and guild list (disables \"Target\")"
RTCLICK_MENU_UNIT = "Enable right-click menu entry on unit frames (disables \"Set Focus\")"
MINIMAP_ENABLE = "Enable minimap button (if disabled, use /xrp commands to access XRP features)"
DETACH_MINIMAP = "Detach button from minimap (shift + right click and drag to move)"
TOOLTIP_ENABLE = "Enable tooltip"
REPLACE_DEFAULT_TOOLTIP = "Replace default tooltip for players and pets"
EYE_ICON_TARGET = "Show eye icon if player is targeting you"
EXTRA_SPACE_TOOLTIP = "Add extra spacing lines to the tooltip"
DISPLAY_GUILD_RANK = "Display guild rank in tooltip"
DISPLAY_GUILD_RANK_INDEX = "Also display guild rank index (numerical ranking) in tooltip"
NO_HOSTILE = "Disable roleplay information display on hostile characters"
NO_OP_FACTION = "Disable roleplay information display on all opposite faction characters"
NO_RP_CLASS = "Hide roleplay class information on tooltip"
NO_RP_RACE = "Hide roleplay race information on tooltip"

-- ui/options.xml
LICENSE_COPYRIGHT = "License/Copyright"
-- This text should be taken from GNU translations directly.
GPL_HEADER = "This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>."
CLEAR_CACHE = "Clear Cache"
TIDY_CACHE = "Tidy Cache"

-- ui/popups.lua
POPUP_URL = "Copy the URL (%s) and paste into your web browser."
POPUP_CURRENTLY = "What are you currently doing?\n(This will reset ten minutes after logout; use the editor to set this more permanently.)"
POPUP_ASK_CACHE = "Are you sure you wish to fully clear the cache?"
POPUP_ASK_CACHE_SINGLE = "It is typically unnecessary to indiviudally drop cached profiles.\n\nAre you sure you wish to drop %s from the cache anyway?"
POPUP_ASK_FORCE_REFRESH = "Force refreshing is rarely necessary and should be done sparingly.\n\nDo you wish to forcibly refresh all fields for %s as soon as possible anyway?"
POPUP_CLEAR_CACHE = "The cache has been cleared."
POPUP_TIDY_CACHE = "Old entries have been pruned from the cache."
POPUP_EDITOR_ADD = "Enter a name for the new profile:"
POPUP_EDITOR_DELETE = "Are you sure you want to remove \"%s\"?"
POPUP_EDITOR_RENAME = "Enter a new name for \"%s\":"
POPUP_EDITOR_COPY = "Enter a name for the copy of \"%s\":"
POPUP_EDITOR_UNAVAILABLE = "The name \"%s\" is unavailable or already in use."
POPUP_EDITOR_INUSE = "The profile \"%s\" is currently in-use directly or as a parent profile. In-use profiles cannot be removed."

-- ui/tooltip.lua
HIDDEN = "Hidden"
LETHAL_LEVEL = "??"
GUILD = "<%s>"
GUILD_RANK = "%s of <%s>"
GUILD_RANK_INDEX = "%s (%d) of <%s>"
-- These must match in-game returns from UnitCreatureFamily() and
-- UnitCreatureType().
PET_GHOUL = "Ghoul"
PET_WATER_ELEMENTAL = "Water Elemental"
PET_MT_WATER_ELEMENTAL = "MT - Water Elemental"
PET_ELEMENTAL = "Elemental"
PET_UNDEAD = "Undead"

-- ui/viewer.lua
RECEIVED = "Received!"
RECEIVED_PARTS = "Received! (%d/%d)"
RECEIVING_PARTS = "Receiving... (%d/%d)"
RECEIVING_UNKNOWN = "Receiving... (%d/??)"
NO_CHANGES = "No changes."
ERR_OFFLINE = "Character is not online."
ERR_FACTION = "Character is opposite faction."
ERR_ADDON = "No RP addon appears to be active."

-- ui/viewer.xml
PROFILE_VIEWER = "Profile Viewer"
