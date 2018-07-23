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

XRP_EXPORT_PROFILE = L.EXPORT_PROFILE
XRP_EXPORT_INSTRUCTIONS = L.EXPORT_INSTRUCTIONS:format(not IsMacClient() and "Ctrl+C" or "Cmd+C")

function XRPExportText_OnLoad(self)
	self.ScrollBar:ClearAllPoints()
	self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 7, -9)
	self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 7, 7)
	self.ScrollBar.ScrollDownButton:SetPoint("TOP", self.ScrollBar, "BOTTOM", 0, 4)
	self.ScrollBar.ScrollUpButton:SetPoint("BOTTOM", self.ScrollBar, "TOP", 0, -4)
	self.ScrollBar.ScrollUpButton:Disable()
	self.ScrollBar:Hide()
	self.EditBox:SetWidth(self:GetWidth())
end

function XRPExportTextEditBox_OnTextChanged(self, userInput)
	if userInput then
		self:SetText(XRPExport.currentText or "")
		EditBox_HighlightText(self)
	end
end

function XRPExport_Export(self, title, text)
	if not title or not text then return end
	self.currentText = text
	self.Text.EditBox:SetText(text)
	self.Text.EditBox:SetCursorPosition(0)
	self.Text:SetVerticalScroll(0)
	self.HeaderText:SetFormattedText(SUBTITLE_FORMAT, L.EXPORT, title)
	ShowUIPanel(self)
end
