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
local L = AddOn.GetText

BINDING_HEADER_XRP = C_AddOns.GetAddOnMetadata(FOLDER_NAME, "Title")
BINDING_NAME_XRP_ARCHIVE = L"Toggle RP Profile Archive"
BINDING_NAME_XRP_CARD_TARGET = L"Show Target Card"
BINDING_NAME_XRP_EDITOR = L"Toggle RP Profile Editor"
BINDING_NAME_XRP_STATUS = L"Toggle IC/OOC Status"
BINDING_NAME_XRP_VIEWER = L"View RP Profile of Mouseover"
BINDING_NAME_XRP_VIEWER_TARGET = L"View RP Profile of Target"
BINDING_NAME_XRP_VIEWER_MOUSEOVER = L"View RP Profile of Target/Mouseover"
XRP_APPEARANCE = L.APPEARANCE
XRP_ARCHIVE_BOOKMARKS = L.BOOKMARKS
XRP_ARCHIVE_OWN = L.OWN
XRP_ARCHIVE_PROFILES_NOTFOUND = L"No profiles found."
XRP_ARCHIVE_RECENT = L.RECENT
XRP_ARCHIVE_SEARCH_ENTER = L"Press enter to search."
XRP_AUTOMATION = L.AUTOMATION
XRP_BIOGRAPHY = L.BIOGRAPHY
XRP_CACHE_CLEAR = L"Clear Cache" .. CONTINUED
XRP_CACHE_TIDY = L"Tidy Cache"
XRP_EXPORT_INSTRUCTIONS = L"Press %s to copy or Escape to close.":format(not IsMacClient() and "Ctrl+C" or "Cmd+C")
XRP_EXPORT_PROFILE = L.EXPORT_PROFILE
XRP_GLANCES = L.GLANCES
XRP_ICONS = L.ICONS
XRP_LICENSE = L.LICENSE
XRP_LICENSE_TEXT = L"XRP is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nXRP is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>."
XRP_NOTES = L.NOTES
XRP_NOTES_INSTRUCTIONS = L"You can store private notes here. They will never be visible to other players.\n\nNotes are accessible on all your characters and are automatically saved when you close this panel."
XRP_TITLE = C_AddOns.GetAddOnMetadata(FOLDER_NAME, "Title")
XRP_VERSION = (STAT_FORMAT .. " %s"):format(GAME_VERSION_LABEL, C_AddOns.GetAddOnMetadata(FOLDER_NAME, "Version") or UNKNOWN)
