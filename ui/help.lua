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

local addonName, xrpPrivate = ...

-- This file defines all the help plate tables for XRP.

local FRAME_POS = { x = 0, y = -22 }

local BOOKMARKS_HELP = {
	FramePos = FRAME_POS,
	FrameSize = { width = 338, height = 499 },
	{
		ButtonPos = { x = 291, y = 1 },
		HighLightBox = { x = 58, y = -7, width = 238, height = 30 },
		ToolTipDir = "RIGHT",
		ToolTipText = "You can filter the list of profiles in a number of ways, including by class, race, and faction.\n\nThe results of your filter choices can be sorted by character name, roleplay name, realm then character name, or date.\n\nYou can also perform a full-profile search by enabling the full-text filter. This may be slow if you have many profiles cached, so you'll have to press enter to trigger the search after typing.",
	},
	{
		ButtonPos = { x = 141, y = -105 },
		HighLightBox = { x = 5, y = -40, width = 326, height = 400 },
		ToolTipDir = "DOWN",
		ToolTipText = "Each of these entries displays a profile XRP has cached, matching your filter selections.\n\nTo interact with these entries, right-click on them and a menu with a number of options will appear.\n\nIn this menu, you can access the cached profile, export the profile, or even add the character directly to your friends list.",
	},
	{
		ButtonPos = { x = 170, y = -430 },
		HighLightBox = { x = 5, y = -443, width = 180, height = 20 },
		ToolTipDir = "UP",
		ToolTipText = "The number of profiles matching your filter results is indicated here.\n\nHidden profiles are not shown by default, so even the \"All\" view may not list everything initially!",
	},
	{
		ButtonPos = { x = 265, y = -460 },
		HighLightBox = { x = 10, y = -466, width = 263, height = 35 },
		ToolTipDir = "UP",
		ToolTipText = "Each of these tabs provides a predefined filter, \"Bookmarks\" and \"All\" being self-explanatory.\n\nThe \"Own\" tab lists your own characters from this WoW account, and the \"Recent\" tab lists profiles XRP has seen in the past three hours, sorted by most recent first.",
	},
}

local EDITOR_MAIN_HELP = {
	{
		ButtonPos = { x = 74, y = 3 },
		HighLightBox = { x = 112, y = -3, width = 259, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "These controls manage the profile you're editing.\n\nThe dropdown selects a profile to edit, and the buttons, from left to right, are add profile, delete profile, rename profile, copy profile, and export profile.\n\nYou can add, delete, rename, and copy profiles at will. The only exception is that XRP won't let you delete your currently-active profile!",
	},
	{
		ButtonPos = { x = 360, y = -10 },
		HighLightBox = { x = 381, y = -3, width = 52, height = 32 },
		ToolTipDir = "LEFT",
		ToolTipText = "The \"Auto\" button shows the controls for XRP's automated profile switching.\n\nIf you open this help system with these controls visible, more information will be available.",
	},
	{
		ButtonPos = { x = 174, y = -466 },
		HighLightBox = { x = 5, y = -477, width = 190, height = 24 },
		ToolTipDir = "UP",
		ToolTipText = "This button allows you to select a parent profile for the profile you're editing.\n\nHaving a parent profile lets you select fields, using the checkboxes next to the field names, to inherit from the parent profile if they're empty on this profile. Any inherited fields will show in a light grey text color, rather than white.\n\nYou can even use a profile that has a parent as a different profile's parent, up to 16 levels deep.",
	},
	{
		ButtonPos = { x = 218, y = -466 },
		HighLightBox = { x = 240, y = -477, width = 190, height = 24 },
		ToolTipDir = "UP",
		ToolTipText = "This pair of buttons is only available when you've made changes to the profile you're editing.\n\nIf you've made changes, pressing \"Revert\" will discard any changes you've made since the profile was last saved.\n\nPressing \"Save\" will save any changes you've made, including field text changes and parent/inheritance changes.",
	},
}

local EDITOR_AUTO_HELP = {
	{
		ButtonPos = { x = 610, y = -60 },
		HighLightBox = { x = 456, y = -63, width = 177, height = 38 },
		ToolTipDir = "UP",
		ToolTipText = "Select a form, equipment set, or form/equipment set combination from this menu.\n\nNote that you can select a form itself, even if there's a submenu with equipment sets. Just click on the form name anyway!",
	},
	{
		ButtonPos = { x = 610, y = -100 },
		HighLightBox = { x = 456, y = -103, width = 177, height = 38 },
		ToolTipDir = "RIGHT",
		ToolTipText = "Select a profile to use with the form/set you've selected above.\n\nA profile can be used for any number of forms/sets, and XRP will try to pick the closest match to your current form/set when you switch.",
	},
	{
		ButtonPos = { x = 610, y = -135 },
		HighLightBox = { x = 456, y = -146, width = 177, height = 23 },
		ToolTipDir = "DOWN",
		ToolTipText = "When available, these buttons control the saving of a selection. Reverting will reset the selection back to the last-saved choice.\n\nWhen saving, if the profile would be active due to your current form, it will immediately be activated.\n\nWhen activating automatically at other times, there is a brief delay after changing forms/sets or after leaving combat.",
	},
}

local EDITOR_APPEARANCE_HELP = {
	{
		ButtonPos = { x = 167, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 193, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "The name field should generally be used for your character's full name, without titles.\n\nKeep in mind that some races/cultures may not often have family names or last names!",
	},
	{
		ButtonPos = { x = 313, y = -38 },
		HighLightBox = { x = 208, y = -45, width = 143, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "The nickname field is used for nickname(s) your character is commonly known by.\n\nGenerally, limiting this to two or three items, at most, is sensible.",
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 354, y = -45, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The height field is for your character's physical height.\n\nYou may either enter a specific height or a few-word description of their size.\n\nIf you enter a number without units, the number is assumed to be in centimeters.",
	},
	{
		ButtonPos = { x = 167, y = -73 },
		HighLightBox = { x = 12, y = -80, width = 193, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "The title field is for your character's titles, including both official and unofficial titles.\n\nGenerally, try to limit how many titles you enter here. Much more than two or three is often excessive.",
	},
	{
		ButtonPos = { x = 313, y = -73 },
		HighLightBox = { x = 208, y = -80, width = 143, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "The house/clan/tribe field is for your character's ancestry, if they belong to a distinct group.\n\nMost races do not often have any of these, so leaving this empty is common.",
	},
	{
		ButtonPos = { x = 388, y = -73 },
		HighLightBox = { x = 354, y = -80, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The weight field is for your character's physical weight.\n\nAs with height, you may enter a specific weight or a brief description of their body shape.\n\nIf you enter a number without units, the number is assumed to be in kilograms.",
	},
	{
		ButtonPos = { x = 106, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 132, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "The eyes field is for a brief description of your character's eyes.\n\nFor many characters this will be simple, often just indicating their eye color.\n\nTry to avoid overly-poetic language, a straightforward description is best here!",
	},
	{
		ButtonPos = { x = 247, y = -108 },
		HighLightBox = { x = 147, y = -115, width = 138, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "The race field is for your character's race, if it is different from their race in-game.\n\nThis can be used for sub-races, such as \"Dark Iron Dwarf\", or for entirely separate races.\n\nIn general, exercise caution when using this field, as exotic races can be difficult to roleplay.",
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 288, y = -115, width = 138, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The class field is for your character's class, if it is different from their in-game class\n\nThis can be used as a more accurate description of your character's skills, such as \"Sniper\", or to explicitly note that their in-game class is irrelevant in roleplay, such as by using \"Civilian\".",
	},
	{
		ButtonPos = { x = 388, y = -143 },
		HighLightBox = { x = 12, y = -150, width = 414, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The currently field is for what your character is currently doing, usually no more than a single sentence.\n\nIf this is set here, it will be the default setting when using this profile.\n\nSetting this from XRP's minimap icon will set a temporary state, which reverts ten minutes after logging out.",
	},
	{
		ButtonPos = { x = 388, y = -178 },
		HighLightBox = { x = 12, y = -185, width = 414, height = 287 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The description field is for a physical description of your character.\n\nGenerally it is most useful to restrict yourself to what would be visible to others about your character in a normal setting.\n\nAdditionally, try to keep this to a reasonable length. Much more than a few hundred words may be excessively long.",
	},
}

local EDITOR_BIOGRAPHY_HELP = {
	{
		ButtonPos = { x = 46, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The age field is, unsurprisingly, for your character's age.\n\nYou may either enter a specific value (generally assumed to be in years), or a brief description, such as \"Old\".\n\nSome races age at different rates, and some of those rates are poorly explained in lore. If in doubt, a brief description may be best.",
	},
	{
		ButtonPos = { x = 217, y = -38 },
		HighLightBox = { x = 87, y = -45, width = 168, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = "The home field is for your character's current residence.\n\nFairly self-explanatorily, this typically means where they spend most of their time, be it a city, town, or even something vague, such as \"Wherever they happen to be.\".",
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 258, y = -45, width = 168, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The birthplace field is for your character's place of birth.\n\nIt's particularly useful to fill this out if your character was born in an unusual place, such as a human raised among dwarves.",
	},
	{
		ButtonPos = { x = 388, y = -73 },
		HighLightBox = { x = 12, y = -80, width = 414, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The motto field is for a brief (typically single-sentence) description of your character's outlook on life.\n\nIf your character happens to explicitly have a motto, then that is also a good thing to use here.\n\nIf in doubt, this field is commonly left empty.",
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 414, height = 316 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The history field is for a brief outline of your character's history.\n\nTypically, it is most useful to fill out only the sort of information which would be readily available, if someone were to seek it out, or any aspects of their history which could be gleaned from observing them.\n\nAs with your description, keeping this short is often the best choice. Much more than a few hundred words may be excessive.",
	},
	{
		ButtonPos = { x = 179, y = -427 },
		HighLightBox = { x = 12, y = -434, width = 205, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The roleplaying style field is for a brief description of any important information about your writing or story methods that needs to be immediately known.\n\nSometimes this is used to indicate someone who is always, no matter what, in-character, or to indicate an interest in a specific type of roleplay.",
	},
	{
		ButtonPos = { x = 388, y = -427 },
		HighLightBox = { x = 220, y = -434, width = 206, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The character status field allows you to notify others as to whether you might be interested in roleplay at the moment or not.\n\nTypically, setting this to whatever state you're most commonly in, such as \"Out of character\", is sensible.\n\nXRP's minimap button can be used to temporarily toggle your status to the opposite of what is selected here.",
	},
}

local LARGE_SIZE = { width = 439, height = 500 }
local AUTO_SIZE = { width = 648, height = 500 }

local EDITOR_APPEARANCE_NOAUTO_HELP
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = LARGE_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN_HELP) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_APPEARANCE_HELP) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_APPEARANCE_NOAUTO_HELP = plates
end
local EDITOR_APPEARANCE_AUTO_HELP
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = AUTO_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN_HELP) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_AUTO_HELP) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_APPEARANCE_HELP) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_APPEARANCE_AUTO_HELP = plates
end

local EDITOR_BIOGRAPHY_NOAUTO_HELP
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = LARGE_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN_HELP) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_BIOGRAPHY_HELP) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_BIOGRAPHY_NOAUTO_HELP = plates
end
local EDITOR_BIOGRAPHY_AUTO_HELP
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = AUTO_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN_HELP) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_AUTO_HELP) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_BIOGRAPHY_HELP) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_BIOGRAPHY_AUTO_HELP = plates
end

local VIEWER_HELP = {
	FramePos = FRAME_POS,
	FrameSize = LARGE_SIZE,
	{
		ButtonPos = { x = 358, y = 34 },
		HighLightBox = { x = 394, y = 22, width = 22, height = 22 },
		ToolTipDir = "DOWN",
		ToolTipText = "This button accesses the viewer's menu. In this menu you can refresh the profile (once every 30 seconds), add the character to your bookmarks or friends list, or even export the profile to plain text.",
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 414, height = 67 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The shorter fields displayed here may not always be able to show the full text of a field. If that happens, mousing over the field will display a tooltip with the full text.\n\nAdditionally, the height and weight fields are, whenever possible, automatically converted to match the units you've selected in XRP's interface options.",
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 414, height = 355 },
		ToolTipDir = "RIGHT",
		ToolTipText = "The longer fields displayed here will have scroll bars appear if the text is too lengthy to fit in the field as-is.\n\nIn addition, most internet links will be displayed in |cffc845faepic purple|r. When clicked, a box will pop up, allowing you to copy the link.",
	},
	{
		ButtonPos = { x = 174, y = -466 },
		HighLightBox = { x = 3, y = -477, width = 190, height = 22 },
		ToolTipDir = "UP",
		ToolTipText = "The names and versions of certain addons active for the profile's subject are displayed here.",
	},
	{
		ButtonPos = { x = 218, y = -466 },
		HighLightBox = { x = 242, y = -477, width = 190, height = 22 },
		ToolTipDir = "UP",
		ToolTipText = "The incoming status of the profile currently being viewed is displayed here. In general, it will show whether the profile is in the process of receiving or whether it has been received.",
	},
}

xrpPrivate.Help = {
	Bookmarks = BOOKMARKS_HELP,
	EditorAppearanceNoAuto = EDITOR_APPEARANCE_NOAUTO_HELP,
	EditorAppearanceAuto = EDITOR_APPEARANCE_AUTO_HELP,
	EditorBiographyNoAuto = EDITOR_BIOGRAPHY_NOAUTO_HELP,
	EditorBiographyAuto = EDITOR_BIOGRAPHY_AUTO_HELP,
	Viewer = VIEWER_HELP,
}
