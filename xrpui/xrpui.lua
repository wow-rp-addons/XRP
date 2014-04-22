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

-- This is all the localizable data for semi-generic UI fields and features.
-- Any XRP-based addons not also basing themselves on XRP-UI would need to
-- handle this on their own.
--
-- TODO: Implement some localizing.
xrpui.fields = {
	-- Biography fields.
	NA = "Name",
	NI = "Nickname",
	NT = "Title",
	NH = "House/Clan/Tribe",
	AE = "Eyes",
	RA = "Race",
	AH = "Height",
	AW = "Weight",
	CU = "Currently",
	DE = "Description",
	-- History fields.
	AG = "Age",
	HH = "Home",
	HB = "Birthplace",
	MO = "Motto",
	HI = "History",
	-- OOC fields.
	FR = "Roleplaying style",
	FC = "Character status",
	-- Addon fields.
	VA = "Addon version",
	VP = "Protocol version",
	-- Hidden fields.
	GC = "Toon class",
	GF = "Toon faction",
	GR = "Toon race",
	GS = "Toon gender",
	GU = "Toon GUID",
	-- Metadata fields.
	XC = "MSP chunks",
}

xrpui.values = {
	RA = {
		Dwarf = "Dwarf",
		Draenei = "Draenei",
		Gnome = "Gnome",
		Human = "Human",
		NightElf = "Night Elf",
		Worgen = "Worgen",
		BloodElf = "Blood Elf",
		Goblin = "Goblin",
		Orc = "Orc",
		Scourge = "Undead", -- Yes, Scourge.
		Tauren = "Tauren",
		Troll = "Troll",
		Pandaren = "Pandaren",
	},
	FR = {
		"Normal roleplayer",
		"Casual roleplayer",
		"Full-time roleplayer",
		"Beginner roleplayer",
		"Mature roleplayer", -- This isn't standard (?) but is used sometimes.
	},
	FR_EMPTY = "(Style not set)",
	FC = {
		"Out of character",
		"In character",
		"Looking for contact",
		"Storyteller",
	},
	FC_EMPTY = "(Status not set)",
}

-- Sigh, global variable pollution. FrameXML needs it, though -- and at least
-- we're prefixing with XRPUI_.
for field, name in pairs(xrpui.fields) do
	_G["XRPUI_"..field] = name
end

XRPUI_VERSION = GetAddOnMetadata("xrpui", "Title").."/"..GetAddOnMetadata("xrpui", "Version")
BINDING_HEADER_XRPUI = GetAddOnMetadata("xrpui", "Title")
BINDING_NAME_XRPUI_EDITOR = "Toggle RP profile editor"
BINDING_NAME_XRPUI_VIEWER = "View target's RP profile"
BINDING_NAME_XRPUI_VIEWER_TOGGLE = "Toggle RP profile viewer"

local function loadifneeded(addon)
	local isloaded = IsAddOnLoaded(addon)
	if not isloaded and IsAddOnLoadOnDemand(addon) then
		local loaded, reason = LoadAddOn(addon)
		if not loaded then
			return false
		else
			return true
		end
	end
	return isloaded
end

function xrpui:ToggleEditor()
	if not loadifneeded("xrpui_editor") then
		return
	end
	ToggleFrame(xrpui.editor)
end

function xrpui:ToggleViewer()
	if not loadifneeded("xrpui_viewer") then
		return
	end
	ToggleFrame(xrpui.viewer)
end

function xrpui:ShowViewerCharacter(character)
	if not loadifneeded("xrpui_viewer") then
		return
	end
	xrpui.viewer:ViewCharacter(character)
end

function xrpui:ShowViewerUnit(unit)
	if not loadifneeded("xrpui_viewer") then
		return
	end
	xrpui.viewer:ViewUnit(unit)
end

local function xrpui_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrpui" then
		if not xrpui_settings then
			xrpui_settings = {}
		end
		self:UnregisterEvent("ADDON_LOADED")
	end
end

xrpui:SetScript("OnEvent", xrpui_OnEvent)
xrpui:RegisterEvent("ADDON_LOADED")
