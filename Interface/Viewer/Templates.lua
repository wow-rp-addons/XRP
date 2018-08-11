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

XRPViewerPeek_Mixin = {}

function XRPViewerPeek_Mixin:OnEnter()
	local owner = XRPPeekTooltip:GetOwner()
	for i, testOwner in ipairs(self:GetParent().PE) do
		if self ~= testOwner and owner == testOwner then
			self:SetChecked(true)
			owner:SetChecked(false)
		end
	end
	XRPPeekTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 37)
	XRPPeekTooltip:AddLine(self.NA)
	if self.DE then
		XRPPeekTooltip:AddLine(self.DE, 1, 1, 1, true)
	end
	XRPPeekTooltip:Show()
end

function XRPViewerPeek_Mixin:OnLeave()
	if not self:GetChecked() then
	XRPPeekTooltip:Hide()
	end
end

function XRPViewerPeek_Mixin:OnHide()
	self:SetChecked(false)
	if XRPPeekTooltip:GetOwner() == self then
		XRPPeekTooltip:Hide()
	end
end

function XRPViewerPeek_Mixin:OnShowFirst()
	local parent = self:GetParent()
	parent.extraWidth = 32
	local extraWidth = parent:GetAttribute("UIPanelLayout-extraWidth") or 0
	if extraWidth < 32 then
		parent:SetAttribute("UIPanelLayout-extraWidth", 32)
		if parent:GetAttribute("UIPanelLayout-defined") then
			UpdateUIPanelPositions(parent)
		end
	end
end

function XRPViewerPeek_Mixin:OnHideFirst()
	local parent = self:GetParent()
	parent.extraWidth = 0
	local extraWidth = parent:GetAttribute("UIPanelLayout-extraWidth") or 0
	if extraWidth == 32 then
		parent:SetAttribute("UIPanelLayout-extraWidth", 0)
		if parent:GetAttribute("UIPanelLayout-defined") then
			UpdateUIPanelPositions(parent)
		end
	end
end
