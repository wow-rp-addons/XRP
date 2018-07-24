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

XRP_TITLE = GetAddOnMetadata(FOLDER_NAME, "Title")
XRP_LICENSE_HEADER = L.LICENSE
-- This text should be taken from GNU translations directly.
XRP_LICENSE = L"This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>."

function XRPOptionsAbout_OnShow(self)
	if not self.wasShown then
		self.wasShown = true
		InterfaceOptionsFrame_OpenToCategory(self.GENERAL)
	end
end

function AddOn.Options(pane)
	local XRPOptions = InterfaceOptionsFramePanelContainer.XRP
	if not XRPOptions.wasShown then
		XRPOptions.wasShown = true
		InterfaceOptionsFrame_OpenToCategory(XRPOptions)
	end
	InterfaceOptionsFrame_OpenToCategory(XRPOptions[pane] or XRPOptions[XRPOptions.lastShown] or XRPOptions.GENERAL)
end
