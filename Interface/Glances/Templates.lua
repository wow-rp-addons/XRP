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

XRPPeek_Mixin = {}

function XRPPeek_Mixin:SetPeek(peek)
	if not peek or not peek.IC or not peek.NA then
		self:Hide()
		return
	elseif self:IsShown() and peek.IC == self.IC and peek.NA == self.NA and peek.DE == self.DE then
		return
	end
	self.IC = peek.IC
	self:SetNormalTexture(self.IC)
	self.NA = peek.NA
	self.DE = peek.DE
	self:Show()
	if XRPPeekTooltip:GetOwner() == self then
		self:OnEnter()
	end
end

function XRPPeek_Mixin:OnEnter()
	local owner = XRPPeekTooltip:GetOwner()
	if owner and owner ~= self and owner:GetChecked() then
		self:SetChecked(true)
		owner:SetChecked(false)
	end
	XRPPeekTooltip:SetOwner(self, self.tooltipAnchor or "ANCHOR_RIGHT", self.tooltipX or 0, self.tooltipY or 0)
	XRPPeekTooltip:AddLine(self.NA)
	if self.DE then
		XRPPeekTooltip:AddLine(self.DE, 1, 1, 1, true)
	end
	XRPPeekTooltip:Show()
end

function XRPPeek_Mixin:OnLeave()
	if not self:GetChecked() then
		XRPPeekTooltip:Hide()
	end
end

function XRPPeek_Mixin:OnHide()
	self:SetChecked(false)
	if XRPPeekTooltip:GetOwner() == self then
		XRPPeekTooltip:Hide()
	end
end
