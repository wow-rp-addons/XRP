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

-- This maps the number of peeks to the slot each peek is set in. This is set
-- to keep symmetry, regardless of number of peeks, and have them in their
-- proper order, as the actual peek frames are out-of-order for anchoring.
--
-- Frame order:
--    4, 2, 1, 3, 5
local PEEK_MAP = {
	{ 1, 2, 3, 4, 5 },
	{ 3, 1, 2, 4, 5 },
	{ 2, 1, 3, 4, 5 },
	{ 5, 2, 3, 1, 4 },
	{ 3, 2, 4, 1, 5 },
}

-- A little more flair than "Unknown, Unknown, Unknown, Unknown" for lazy
-- people.
local FALLBACK = {
	AG = L"Indeterminate",
	AH = L"Average",
	AW = L"Typical",
	NI = L"None on file",
	HH = L"Not available",
	HB = UNKNOWN,
}

XRPCard_Mixin = {}

function XRPCard_Mixin:SetUnit(unit)
	if InCombatLockdown() or self.BounceOut:IsPlaying() then
		return
	end
	local character = AddOn_XRP.Characters.byUnit[unit]
	if character then
		self.unit = unit
		if self:IsVisible() then
			self.BounceOut:Play()
			return
		end
		self.character = character
		if UnitIsVisible(unit) then
			self.Model:SetModelScale(1)
			self.Model:SetPosition(0, 0, 0)
			self.Model:SetUnit(unit)
		else
			-- Unit needs to be cleared or else it will overwrite.
			self.Model:SetUnit("none")
			self.Model:SetModel("Interface\\Buttons\\talktomequestionmark")
			self.Model:SetModelScale(3)
			self.Model:SetPosition(0, 0, -0.15)
		end
		local GF = UnitFactionGroup(unit)
		if GF == "Alliance" then
			self.Model.Portrait:SetAtlas("TalkingHeads-Alliance-PortraitFrame")
		elseif GF == "Horde" then
			self.Model.Portrait:SetAtlas("TalkingHeads-Horde-PortraitFrame")
		else
			self.Model.Portrait:SetAtlas("TalkingHeads-Neutral-PortraitFrame")
		end
		local class, GC = UnitClass(unit)
		local r, g, b = RAID_CLASS_COLORS[GC]:GetRGB()
		self.NA:SetTextColor(r, g, b, 1)
		self.PX:SetTextColor(r, g, b, 1)
	else
		self.character = nil
		self.unit = nil
	end
	self:Reload()
end

function XRPCard_Mixin:Reload()
	if not self.character or not self.character.hasProfile then
		if not self:IsInvisibleOrFading() then
			self.FadeOut:Play()
		end
	else
		self.NA:SetText(AddOn_XRP.RemoveTextFormats(self.character.NA) or self.character.name)
		self.PX:SetText(AddOn_XRP.RemoveTextFormats(self.character.PX) or "")
		for field, fallback in pairs(FALLBACK) do
			self[field]:SetText(AddOn_XRP.RemoveTextFormats(self.character[field]) or fallback)
		end
		self:SetPE(self.character.PE)
		if self:IsInvisibleOrFading() then
			if self.bounceIn then
				self.BounceIn:Play()
			else
				self.FadeIn:Play()
			end
		end
	end
end

function XRPCard_Mixin:SetPE(PE)
	local map = PE and PEEK_MAP[#PE]
	for i, frame in ipairs(self.PE) do
		frame:SetPeek(PE and PE[map[i]])
	end
	if not PE then
		self:SetHeight(120)
	else
		self:SetHeight(176)
	end
end

function XRPCard_Mixin:IsInvisibleOrFading()
	return not self:IsVisible() or self.FadeOut:IsPlaying() or self.BounceOut:IsPlaying()
end

function XRPCard_Mixin:OnLoad()
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:RegisterForDrag("LeftButton")
	for i, field in ipairs{"AG", "AH", "AW", "NI", "HH", "HB"} do
		self[field .. "Label"]:SetText(AddOn_XRP.Strings.Names[field])
	end
	local function XRPEventCallback(event, characterID, field)
		if self.character and self.character.id == characterID then
			if event == "ADDON_XRP_PROFILE_RECEIVED" then
				self:Reload()
			elseif event == "ADDON_XRP_FIELD_RECEIVED" then
				if field == "NA" then
					self.NA:SetText(AddOn_XRP.RemoveTextFormats(self.character.NA) or self.character.name)
					local r, g, b = RAID_CLASS_COLORS[self.character.GC]:GetRGB()
					self.NA:SetTextColor(r, g, b, 1)
				elseif field == "PE" then
					self:SetPE(self.character.PE)
				elseif FALLBACK[field] then
					self[field]:SetText(AddOn_XRP.RemoveTextFormats(self.character[field]) or FALLBACK[field])
				end
			end
		end
	end
	AddOn_XRP.RegisterEventCallback("ADDON_XRP_FIELD_RECEIVED", XRPEventCallback)
	AddOn_XRP.RegisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", XRPEventCallback)
end

function XRPCard_Mixin:OnClick(button)
	if button == "LeftButton" then
		if not self.character then
			return
		end
		local now = GetTime()
		if self.lastClick > now - 0.75 then
			if self.unit and AddOn_XRP.Characters.byUnit[self.unit] == self.character then
				XRPViewer:View(self.unit)
			else
				XRPViewer:View(self.character.id)
			end
		else
			self.lastClick = now
		end
	elseif button == "RightButton" then
		self.FadeOut:Play()
	end
end

function XRPCard_Mixin:OnEnter()
	if self.unit and AddOn_XRP.Characters.byUnit[self.unit] == self.character then
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:SetUnit(self.unit)
		GameTooltip:Show()
		self.tooltip = true
	end
end

function XRPCard_Mixin:OnLeave()
	if self.tooltip then
		GameTooltip:FadeOut()
	end
	self.tooltip = nil
end

function XRPCard_Mixin:OnDragStart(button)
	self:StartMoving()
end

function XRPCard_Mixin:OnDragStop()
	self:StopMovingOrSizing()
end

XRPCardModel_Mixin = {}

function XRPCardModel_Mixin:OnLoad()
	self:RegisterEvent("UI_SCALE_CHANGED")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")
end

function XRPCardModel_Mixin:OnModelLoaded()
	self:SetPortraitZoom(0.85)
end

XRPCardAnimation_Mixin = {}

function XRPCardAnimation_Mixin:OnLoad()
	local parent = self:GetParent()
	if not parent.anims then
		parent.anims = {}
	end
	parent.anims[#parent.anims + 1] = self
end

function XRPCardAnimation_Mixin:OnPlay()
	local parent = self:GetParent()
	for i, anim in ipairs(parent.anims) do
		if anim ~= self then
			anim:Stop()
		end
	end
end

function XRPCardAnimation_Mixin:ShowParentOnPlay()
	self:GetParent():Show()
end

function XRPCardAnimation_Mixin:BounceOutOnFinished()
	local parent = self:GetParent()
	parent:Hide()
	if parent.unit then
		parent.bounceIn = true
		parent:SetUnit(parent.unit)
		parent.bounceIn = false
	end
end
