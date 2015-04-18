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

local addonName, _xrp = ...

-- This file defines all the help plate tables for XRP.

local FRAME_POS = { x = 0, y = -22 }

XRPBookmarks_helpPlates = {
	FramePos = FRAME_POS,
	FrameSize = { width = 338, height = 499 },
	{
		ButtonPos = { x = 291, y = 1 },
		HighLightBox = { x = 58, y = -7, width = 238, height = 30 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_BOOKMARKS_FILTER,
	},
	{
		ButtonPos = { x = 141, y = -105 },
		HighLightBox = { x = 5, y = -40, width = 326, height = 400 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_BOOKMARKS_ENTRIES,
	},
	{
		ButtonPos = { x = 170, y = -430 },
		HighLightBox = { x = 5, y = -443, width = 180, height = 20 },
		ToolTipDir = "UP",
		ToolTipText = _xrp.L.HELP_BOOKMARKS_NUMBER,
	},
	{
		ButtonPos = { x = 265, y = -460 },
		HighLightBox = { x = 10, y = -466, width = 263, height = 35 },
		ToolTipDir = "UP",
		ToolTipText = _xrp.L.HELP_BOOKMARKS_TABS,
	},
}

local EDITOR_MAIN = {
	{
		ButtonPos = { x = 74, y = 3 },
		HighLightBox = { x = 112, y = -3, width = 259, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_CONTROLS,
	},
	{
		ButtonPos = { x = 360, y = -10 },
		HighLightBox = { x = 381, y = -3, width = 52, height = 32 },
		ToolTipDir = "LEFT",
		ToolTipText = _xrp.L.HELP_EDITOR_AUTO,
	},
	{
		ButtonPos = { x = 174, y = -466 },
		HighLightBox = { x = 5, y = -477, width = 190, height = 24 },
		ToolTipDir = "UP",
		ToolTipText = _xrp.L.HELP_EDITOR_PARENT,
	},
	{
		ButtonPos = { x = 218, y = -466 },
		HighLightBox = { x = 240, y = -477, width = 190, height = 24 },
		ToolTipDir = "UP",
		ToolTipText = _xrp.L.HELP_EDITOR_BUTTONS,
	},
}

local EDITOR_AUTO = {
	{
		ButtonPos = { x = 610, y = -60 },
		HighLightBox = { x = 456, y = -63, width = 177, height = 38 },
		ToolTipDir = "UP",
		ToolTipText = _xrp.L.HELP_EDITOR_AUTO_FORM,
	},
	{
		ButtonPos = { x = 610, y = -100 },
		HighLightBox = { x = 456, y = -103, width = 177, height = 38 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_AUTO_PROFILE,
	},
	{
		ButtonPos = { x = 610, y = -135 },
		HighLightBox = { x = 456, y = -146, width = 177, height = 23 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_AUTO_BUTTONS,
	},
}

local EDITOR_APPEARANCE = {
	{
		ButtonPos = { x = 167, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 193, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_NA,
	},
	{
		ButtonPos = { x = 313, y = -38 },
		HighLightBox = { x = 208, y = -45, width = 143, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_NI,
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 354, y = -45, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_AH,
	},
	{
		ButtonPos = { x = 167, y = -73 },
		HighLightBox = { x = 12, y = -80, width = 193, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_NT,
	},
	{
		ButtonPos = { x = 313, y = -73 },
		HighLightBox = { x = 208, y = -80, width = 143, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_NH,
	},
	{
		ButtonPos = { x = 388, y = -73 },
		HighLightBox = { x = 354, y = -80, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_AW,
	},
	{
		ButtonPos = { x = 106, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 132, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_AE,
	},
	{
		ButtonPos = { x = 247, y = -108 },
		HighLightBox = { x = 147, y = -115, width = 138, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_RA,
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 288, y = -115, width = 138, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_RC,
	},
	{
		ButtonPos = { x = 388, y = -143 },
		HighLightBox = { x = 12, y = -150, width = 414, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_CU,
	},
	{
		ButtonPos = { x = 388, y = -178 },
		HighLightBox = { x = 12, y = -185, width = 414, height = 287 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_DE,
	},
}

local EDITOR_BIOGRAPHY = {
	{
		ButtonPos = { x = 46, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 72, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_AG,
	},
	{
		ButtonPos = { x = 217, y = -38 },
		HighLightBox = { x = 87, y = -45, width = 168, height = 32 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_EDITOR_HH,
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 258, y = -45, width = 168, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_HB,
	},
	{
		ButtonPos = { x = 388, y = -73 },
		HighLightBox = { x = 12, y = -80, width = 414, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_MO,
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 414, height = 316 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_HI,
	},
	{
		ButtonPos = { x = 179, y = -427 },
		HighLightBox = { x = 12, y = -434, width = 205, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_FR,
	},
	{
		ButtonPos = { x = 388, y = -427 },
		HighLightBox = { x = 220, y = -434, width = 206, height = 32 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_EDITOR_FC,
	},
}

local LARGE_SIZE = { width = 439, height = 500 }
local AUTO_SIZE = { width = 648, height = 500 }

local EDITOR_APPEARANCE_NOAUTO
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = LARGE_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_APPEARANCE) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_APPEARANCE_NOAUTO = plates
end
local EDITOR_APPEARANCE_AUTO
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = AUTO_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_AUTO) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_APPEARANCE) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_APPEARANCE_AUTO = plates
end

local EDITOR_BIOGRAPHY_NOAUTO
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = LARGE_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_BIOGRAPHY) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_BIOGRAPHY_NOAUTO = plates
end
local EDITOR_BIOGRAPHY_AUTO
do
	local plates = {
		FramePos = FRAME_POS,
		FrameSize = AUTO_SIZE,
	}
	for i, helpPlate in ipairs(EDITOR_MAIN) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_AUTO) do
		plates[#plates + 1] = helpPlate
	end
	for i, helpPlate in ipairs(EDITOR_BIOGRAPHY) do
		plates[#plates + 1] = helpPlate
	end
	EDITOR_BIOGRAPHY_AUTO = plates
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

XRPViewer_helpPlates = {
	FramePos = FRAME_POS,
	FrameSize = LARGE_SIZE,
	{
		ButtonPos = { x = 358, y = 34 },
		HighLightBox = { x = 394, y = 22, width = 22, height = 22 },
		ToolTipDir = "DOWN",
		ToolTipText = _xrp.L.HELP_VIEWER_MENU,
	},
	{
		ButtonPos = { x = 355, y = 1 },
		HighLightBox = { x = 79, y = -1, width = 285, height = 42 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_VIEWER_LINES
	},
	{
		ButtonPos = { x = 388, y = -38 },
		HighLightBox = { x = 12, y = -45, width = 414, height = 67 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_VIEWER_SHORT,
	},
	{
		ButtonPos = { x = 388, y = -108 },
		HighLightBox = { x = 12, y = -115, width = 414, height = 355 },
		ToolTipDir = "RIGHT",
		ToolTipText = _xrp.L.HELP_VIEWER_LONG,
	},
	{
		ButtonPos = { x = 184, y = -466 },
		HighLightBox = { x = 3, y = -477, width = 200, height = 22 },
		ToolTipDir = "UP",
		ToolTipText = _xrp.L.HELP_VIEWER_ADDONS,
	},
	{
		ButtonPos = { x = 218, y = -466 },
		HighLightBox = { x = 242, y = -477, width = 190, height = 22 },
		ToolTipDir = "UP",
		ToolTipText = _xrp.L.HELP_VIEWER_STATUS,
	},
}
