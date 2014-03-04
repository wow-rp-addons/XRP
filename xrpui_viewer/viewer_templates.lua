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

function OutputScrollFrame_OnLoad(self)
	local scrollBar = self.ScrollBar
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", -13, -11)
	scrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -13, 9)
	_G[self:GetName().."ScrollBarScrollDownButton"]:SetPoint("TOP", scrollBar, "BOTTOM", 0, 4)
	_G[self:GetName().."ScrollBarScrollUpButton"]:SetPoint("BOTTOM", scrollBar, "TOP", 0, -4)
	self.scrollBarHideable = 1
	scrollBar:Hide()
	self.EditBox:SetWidth(self:GetWidth() - 18)
end
