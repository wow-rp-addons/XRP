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
