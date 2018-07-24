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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

-- This file defines all the help plate tables for XRP.

AddOn.help = {}

local FRAME_POS = { x = 0, y = -22 }

AddOn.help.archive = {
	FramePos = FRAME_POS,
	FrameSize = { width = 338, height = 499 },
	{
		ButtonPos = { x = 291, y = 1 },
		HighLightBox = { x = 58, y = -7, width = 238, height = 30 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"You can filter the list of profiles in a number of ways, including by class, race, and faction.\n\nThe results of your filter choices can be sorted by character name, roleplay name, realm then character name, or date.\n\nYou can also perform a full-profile search by enabling the full-text filter. This may be slow if you have many profiles cached, so you'll have to press enter to trigger the search after typing.",
	},
	{
		ButtonPos = { x = 141, y = -105 },
		HighLightBox = { x = 5, y = -40, width = 326, height = 400 },
		ToolTipDir = "DOWN",
		ToolTipText = L"Each of these entries displays a profile XRP has cached, matching your filter selections.\n\nTo interact with these entries, right-click on them and a menu with a number of options will appear.\n\nIn this menu, you can access the cached profile, export the profile, or even add the character directly to your friends list.",
	},
	{
		ButtonPos = { x = 170, y = -430 },
		HighLightBox = { x = 5, y = -443, width = 180, height = 20 },
		ToolTipDir = "UP",
		ToolTipText = L"The number of profiles matching your filter results is indicated here.\n\nHidden profiles are not shown by default, so even the \"All\" view may not list everything initially!",
	},
	{
		ButtonPos = { x = 265, y = -460 },
		HighLightBox = { x = 10, y = -466, width = 263, height = 35 },
		ToolTipDir = "UP",
		ToolTipText = L"Each of these tabs provides a predefined filter, \"Bookmarks\" and \"All\" being self-explanatory.\n\nThe \"Own\" tab lists your own characters from this WoW account, and the \"Recent\" tab lists profiles XRP has seen in the past three hours, sorted by most recent first.",
	},
}

local EDITOR_MAIN = {
	{
		ButtonPos = { x = 74, y = 0 },
		HighLightBox = { x = 112, y = -6, width = 261, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"These controls manage the profile you're editing.\n\nThe dropdown selects a profile to edit, and the buttons allow you to add, remove, rename, copy, or export profiles.\n\nYou can add, delete, copy, and rename profiles at will. The only exception is you cannot delete your currently-active profile!",
	},
	{
		ButtonPos = { x = 370, y = 0 },
		HighLightBox = { x = 406, y = 0, width = 28, height = 42 },
		ToolTipDir = "DOWN",
		ToolTipText = L"These buttons access XRP's profile swapping automation (top) and private notes (bottom) features.\n\nIf you open this help system with the profile automation panel open, more help will be available for it.",
	},
	{
		ButtonPos = { x = 174, y = -466 },
		HighLightBox = { x = 5, y = -477, width = 190, height = 24 },
		ToolTipDir = "UP",
		ToolTipText = L"This button allows you to select a parent profile for the profile you're editing.\n\nHaving a parent profile lets you select fields, using the checkboxes next to the field names, to inherit from the parent profile if they're empty on this profile. Any inherited fields will show in a light grey text color, rather than white.\n\nYou can even use a profile that has a parent as a different profile's parent, up to 50 levels deep.",
	},
	{
		ButtonPos = { x = 218, y = -466 },
		HighLightBox = { x = 240, y = -477, width = 190, height = 24 },
		ToolTipDir = "UP",
		ToolTipText = L"This pair of buttons is only available when you've made changes to the profile you're editing.\n\nIf you've made changes, pressing \"Revert\" will discard any changes you've made since the profile was last saved.\n\nPressing \"Save\" will save any changes you've made, including field text changes and parent/inheritance changes.",
	},
}

local EDITOR_AUTO = {
	{
		ButtonPos = { x = 610, y = -60 },
		HighLightBox = { x = 456, y = -63, width = 177, height = 38 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"Select a form, equipment set, or form/equipment set combination from this menu.\n\nNote that you can select a form by itself, even if there's a submenu with equipment sets.\n\nIf selected, Mercenary Mode takes prescedence over all other forms and sets while acting as an opposite-faction Mercenary.",
	},
	{
		ButtonPos = { x = 610, y = -100 },
		HighLightBox = { x = 456, y = -103, width = 177, height = 38 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"Select a profile to use with the form/set you've selected above.\n\nA profile can be used for any number of forms/sets, and XRP will try to pick the closest match to your current form/set when you switch.",
	},
	{
		ButtonPos = { x = 610, y = -135 },
		HighLightBox = { x = 456, y = -146, width = 177, height = 23 },
		ToolTipDir = "DOWN",
		ToolTipText = L"When available, these buttons control the saving of a selection. Reverting will reset the selection back to the last-saved choice.\n\nWhen saving, if the profile would be active due to your current form, it will immediately be activated.\n\nWhen activating automatically at other times, there is a brief delay after changing forms/sets or after leaving combat.",
	},
}

local EDITOR_APPEARANCE = {
	{
		ButtonPos = { x = 167, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 193, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The name field should generally be used for your character's full name, without titles.\n\nKeep in mind that some races/cultures may not often have family names or last names!",
	},
	{
		ButtonPos = { x = 313, y = -38 },
		HighLightBox = { x = 208, y = -45, width = 143, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The nickname field is used for nickname(s) your character is commonly known by.\n\nGenerally, limiting this to two or three items, at most, is sensible.",
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 354, y = -45, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The height field is for your character's physical height.\n\nYou may either enter a specific height or a few-word description of their size.\n\nIf you enter a number without units, the number is assumed to be in centimeters.",
	},
	{
		ButtonPos = { x = 167, y = -73 },
		HighLightBox = { x = 12, y = -80, width = 193, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The title field is for your character's titles, including both official and unofficial titles.\n\nGenerally, try to limit how many titles you enter here. Much more than two or three is often excessive.",
	},
	{
		ButtonPos = { x = 313, y = -73 },
		HighLightBox = { x = 208, y = -80, width = 143, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The house/clan/tribe field is for your character's ancestry, if they belong to a distinct group.\n\nMost races do not often have any of these, so leaving this empty is common.",
	},
	{
		ButtonPos = { x = 388, y = -73 },
		HighLightBox = { x = 354, y = -80, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The weight field is for your character's physical weight.\n\nAs with height, you may enter a specific weight or a brief description of their body shape.\n\nIf you enter a number without units, the number is assumed to be in kilograms.",
	},
	{
		ButtonPos = { x = 106, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 132, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The eyes field is for a brief description of your character's eyes.\n\nFor many characters this will be simple, often just indicating their eye color.\n\nA short, straightforward description is typically best -- while poetic language may be tempting, it can be difficult for others to understand.",
	},
	{
		ButtonPos = { x = 247, y = -108 },
		HighLightBox = { x = 147, y = -115, width = 138, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The race field is for your character's race, if it is different from their race in-game.\n\nThis can be used for sub-races, such as \"Dark Iron Dwarf\", or for entirely separate races.\n\nIn general, exercise caution when using this field, as exotic races can be difficult to roleplay.",
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 288, y = -115, width = 138, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The class field is for your character's class, if it is different from their in-game class\n\nThis can be used as a more accurate description of your character's skills, such as \"Sniper\", or to explicitly note that their in-game class is irrelevant in roleplay, such as by using \"Civilian\".",
	},
	{
		ButtonPos = { x = 388, y = -143 },
		HighLightBox = { x = 12, y = -150, width = 414, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The currently field is for what your character is currently doing, usually no more than a single sentence.\n\nIf this is set here, it will be the default setting when using this profile.\n\nSetting this from XRP's minimap icon will set a temporary state, which reverts fifteen minutes after logging out.",
	},
	{
		ButtonPos = { x = 388, y = -178 },
		HighLightBox = { x = 12, y = -185, width = 414, height = 287 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The description field is for a physical description of your character.\n\nGenerally it is most useful to restrict yourself to what would be visible to others about your character in a normal setting.\n\nAdditionally, try to keep this to a reasonable length. Much more than a few hundred words may be excessively long.",
	},
}

local EDITOR_BIOGRAPHY = {
	{
		ButtonPos = { x = 46, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The age field is, unsurprisingly, for your character's age.\n\nYou may either enter a specific value (generally assumed to be in years), or a brief description, such as \"Old\".\n\nSome races age at different rates, and some of those rates are poorly explained in lore. If in doubt, a brief description may be best.",
	},
	{
		ButtonPos = { x = 217, y = -38 },
		HighLightBox = { x = 87, y = -45, width = 168, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The home field is for your character's current residence.\n\nFairly self-explanatorily, this typically means where they spend most of their time, be it a city, town, or even something vague, such as \"Wherever they happen to be.\".",
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 258, y = -45, width = 168, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The birthplace field is for your character's place of birth.\n\nIt's particularly useful to fill this out if your character was born in an unusual place, such as a human raised among dwarves.",
	},
	{
		ButtonPos = { x = 388, y = -73 },
		HighLightBox = { x = 12, y = -80, width = 414, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The motto field is for a brief (typically single-sentence) description of your character's outlook on life.\n\nIf your character happens to explicitly have a motto, then that is also a good thing to use here.\n\nIf in doubt, this field is commonly left empty.",
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 414, height = 316 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The history field is for a brief outline of your character's history.\n\nTypically, it is most useful to fill out only the sort of information which would be readily available, if someone were to seek it out, or any aspects of their history which could be gleaned from observing them.\n\nAs with your description, keeping this short is often the best choice. Much more than a few hundred words may be excessive.",
	},
	{
		ButtonPos = { x = 179, y = -427 },
		HighLightBox = { x = 12, y = -434, width = 205, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The roleplaying style field is for a brief description of any important information about your writing or story methods that needs to be immediately known.\n\nSometimes this is used to indicate someone who is always, no matter what, in-character, or to indicate an interest in a specific type of roleplay.",
	},
	{
		ButtonPos = { x = 388, y = -427 },
		HighLightBox = { x = 220, y = -434, width = 206, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The character status field allows you to notify others as to whether you might be interested in roleplay at the moment or not.\n\nTypically, setting this to whatever state you're most commonly in, such as \"Out of character\", is sensible.\n\nXRP's minimap button can be used to temporarily toggle your status to the opposite of what is selected here.",
	},
}

local LARGE_SIZE = { width = 439, height = 500 }
local AUTO_SIZE = { width = 648, height = 500 }

local EDITOR_APPEARANCE_NOAUTO = {
	FramePos = FRAME_POS,
	FrameSize = LARGE_SIZE,
}
for i, helpPlate in ipairs(EDITOR_MAIN) do
	EDITOR_APPEARANCE_NOAUTO[#EDITOR_APPEARANCE_NOAUTO + 1] = helpPlate
end
for i, helpPlate in ipairs(EDITOR_APPEARANCE) do
	EDITOR_APPEARANCE_NOAUTO[#EDITOR_APPEARANCE_NOAUTO + 1] = helpPlate
end

local EDITOR_APPEARANCE_AUTO = {
	FramePos = FRAME_POS,
	FrameSize = AUTO_SIZE,
}
for i, helpPlate in ipairs(EDITOR_MAIN) do
	EDITOR_APPEARANCE_AUTO[#EDITOR_APPEARANCE_AUTO + 1] = helpPlate
end
for i, helpPlate in ipairs(EDITOR_AUTO) do
	EDITOR_APPEARANCE_AUTO[#EDITOR_APPEARANCE_AUTO + 1] = helpPlate
end
for i, helpPlate in ipairs(EDITOR_APPEARANCE) do
	EDITOR_APPEARANCE_AUTO[#EDITOR_APPEARANCE_AUTO + 1] = helpPlate
end

local EDITOR_BIOGRAPHY_NOAUTO = {
	FramePos = FRAME_POS,
	FrameSize = LARGE_SIZE,
}
for i, helpPlate in ipairs(EDITOR_MAIN) do
	EDITOR_BIOGRAPHY_NOAUTO[#EDITOR_BIOGRAPHY_NOAUTO + 1] = helpPlate
end
for i, helpPlate in ipairs(EDITOR_BIOGRAPHY) do
	EDITOR_BIOGRAPHY_NOAUTO[#EDITOR_BIOGRAPHY_NOAUTO + 1] = helpPlate
end

local EDITOR_BIOGRAPHY_AUTO = {
	FramePos = FRAME_POS,
	FrameSize = AUTO_SIZE,
}
for i, helpPlate in ipairs(EDITOR_MAIN) do
	EDITOR_BIOGRAPHY_AUTO[#EDITOR_BIOGRAPHY_AUTO + 1] = helpPlate
end
for i, helpPlate in ipairs(EDITOR_AUTO) do
	EDITOR_BIOGRAPHY_AUTO[#EDITOR_BIOGRAPHY_AUTO + 1] = helpPlate
end
for i, helpPlate in ipairs(EDITOR_BIOGRAPHY) do
	EDITOR_BIOGRAPHY_AUTO[#EDITOR_BIOGRAPHY_AUTO + 1] = helpPlate
end

function XRPEditorHelpButton_PreClick(self, button, down)
	if XRPEditor.panes[1]:IsVisible() then
		if XRPEditor.Automation:IsVisible() then
			XRPEditor.helpPlates = EDITOR_APPEARANCE_AUTO
		else
			XRPEditor.helpPlates = EDITOR_APPEARANCE_NOAUTO
		end
	else
		if XRPEditor.Automation:IsVisible() then
			XRPEditor.helpPlates = EDITOR_BIOGRAPHY_AUTO
		else
			XRPEditor.helpPlates = EDITOR_BIOGRAPHY_NOAUTO
		end
	end
end

AddOn.help.viewer = {
	FramePos = FRAME_POS,
	FrameSize = LARGE_SIZE,
	{
		ButtonPos = { x = 358, y = 34 },
		HighLightBox = { x = 394, y = 22, width = 22, height = 22 },
		ToolTipDir = "DOWN",
		ToolTipText = L"This button accesses the viewer's menu. In this menu you can refresh the profile (if there is anything to refresh), add the character to your bookmarks or friends list, or even export the profile to plain text.\n\nIn addition, there are some advanced troubleshooting tools to help when profiles refuse to properly load, but these are rarely necessary.",
	},
	{
		ButtonPos = { x = 355, y = 1 },
		HighLightBox = { x = 79, y = -1, width = 285, height = 42 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"These lines show, from top to bottom, nicknames, titles, and house/clan/tribe.\n\nIf there is more text than can be shown (an ellipses will be visible at the end), you can mouseover the line to see the full text in a tooltip.",
	},
	{
		ButtonPos = { x = 424, y = -8 },
		HighLightBox = { x = 406, y = -18, width = 28, height = 24 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"This button accesses XRP's private notes feature, from a pop-out panel.\n\nThese notes are never seen by anyone else and are available for viewing/editing on all characters on your license. They may also be accessed through the archive.",
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 414, height = 67 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The shorter fields displayed here may not always be able to show the full text of a field. If that happens, mousing over the field will display a tooltip with the full text.\n\nAdditionally, the height and weight fields are, whenever possible, automatically converted to match the units you've selected in XRP's interface options.",
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 414, height = 355 },
		ToolTipDir = "RIGHT",
		ToolTipText = L"The longer fields displayed here will have scroll bars appear if the text is too lengthy to fit in the field as-is.\n\nIn addition, most internet links will be displayed in |cffc845faepic purple|r. When clicked, a box will pop up, allowing you to copy the link.",
	},
	{
		ButtonPos = { x = 184, y = -466 },
		HighLightBox = { x = 3, y = -477, width = 200, height = 22 },
		ToolTipDir = "UP",
		ToolTipText = L"The names and versions of certain addons active for the profile's subject are displayed here.\n\nIf there is too much text to display in the short line available, mouseover will display the full list.",
	},
	{
		ButtonPos = { x = 218, y = -466 },
		HighLightBox = { x = 242, y = -477, width = 186, height = 22 },
		ToolTipDir = "UP",
		ToolTipText = L"The incoming status of the profile currently being viewed is displayed here. In general, it will show whether the profile is in the process of receiving or whether it has been received.",
	},
	{
		ButtonPos = { x = 429, y = -471 },
		HighLightBox = { x = 426, y = -486, width = 13, height = 13 },
		ToolTipDir = "DOWN",
		ToolTipText = L"The small handle here may be clicked and dragged to resize the viewer window.\n\nTo reset the size of the viewer, right-click on it instead.",
	},
}
function XRPViewerHelpButton_PreClick(self, button, down)
	if HelpPlate_IsShowing(XRPViewer.helpPlates) then return end
	local width, height = XRPViewer:GetWidth(), XRPViewer:GetHeight()
	-- 439, 525 default
	local plates = XRPViewer.helpPlates
	-- Menu
	plates[1].ButtonPos.x = width - 81
	plates[1].HighLightBox.x = width - 45
	-- Single lines
	plates[2].ButtonPos.x = width - 84
	plates[2].HighLightBox.width = width - 154
	-- Notes button
	plates[3].ButtonPos.x = width - 15
	plates[3].HighLightBox.x = width - 33
	-- Single boxes
	plates[4].ButtonPos.x = width - 51
	plates[4].HighLightBox.width = width - 25
	-- Multiline boxes
	plates[5].ButtonPos.x = width - 51
	plates[5].HighLightBox.width = width - 25
	plates[5].HighLightBox.height = height - 170
	-- Addon info
	plates[6].ButtonPos.x = width - 255
	plates[6].ButtonPos.y = 59 - height
	plates[6].HighLightBox.y = 48 - height
	plates[6].HighLightBox.width = width - 239
	-- Status info
	plates[7].ButtonPos.x = width - 221
	plates[7].ButtonPos.y = 59 - height
	plates[7].HighLightBox.x = width - 201
	plates[7].HighLightBox.y = 48 - height
	-- Resize handle
	plates[8].ButtonPos.x = width - 10
	plates[8].ButtonPos.y = 54 - height
	plates[8].HighLightBox.x = width - 13
	plates[8].HighLightBox.y = 39 - height
end
