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

XRPEditorPeek_Mixin = {}

function XRPEditorPeek_Mixin:SetPeek(peek)
	local noPeek = not peek or (not peek.IC and not peek.NA and not peek.DE)
	if noPeek then
		self.IC:SetNormalTexture("Interface\\Icons\\inv_misc_questionmark")
		self.NA:SetText("")
		self.DE.EditBox:SetText("")
		self.Clear:SetEnabled(false)
	else
		self.NA:ClearFocus()
		self.DE.EditBox:ClearFocus()
		self.IC:SetNormalTexture(peek.IC or "Interface\\Icons\\inv_misc_questionmark")
		self.NA:SetText(peek.NA or "")
		self.NA:SetCursorPosition(0)
		self.DE.EditBox:SetText(peek.DE or "")
		self.DE.EditBox:SetCursorPosition(0)
		if self:GetParent().inherited then
			self.Clear:SetEnabled(false)
		else
			self.Clear:SetEnabled(true)
		end
	end
	self.peek = peek or {}
end

function XRPEditorPeek_Mixin:OnAttributeChanged(name, value)
	if name == "contents" then
		self:SetPeek(value)
	elseif name == "inherited" then
		if value and not self.inherited then
			self.IC:GetNormalTexture():SetDesaturated(true)
			self.NA:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			self.DE.EditBox:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			self.inherited = true
		elseif not value and self.inherited then
			self.IC:GetNormalTexture():SetDesaturated(false)
			self.NA:SetTextColor(self.NA:GetFontObject():GetTextColor())
			self.DE.EditBox:SetTextColor(self.DE.EditBox:GetFontObject():GetTextColor())
			self.inherited = false
		end
	end
end

XRPEditorPeekText_Mixin = {}

function XRPEditorPeekText_Mixin:OnLoad()
	if self.Label and self.labelKey then
		self.Label:SetText(L[self.labelKey])
	end
end

function XRPEditorPeekText_Mixin:OnTextChanged(userInput)
	local parent = self:GetParent()
	if self:IsMultiLine() then
		ScrollingEdit_OnTextChanged(self, parent)
		parent = parent:GetParent()
	end
	if userInput then
		local text = self:GetText()
		parent.peek[self.peekField] = text ~= "" and text or nil
		--[[if #text > self.safeLength then
			self.Warning:Show()
		else
			self.Warning:Hide()
		end]]
		parent:GetParent():UpdatePeeks()
	end
end

function XRPEditorPeekText_Mixin:OnEditFocusGained()
	local PE
	if self:IsMultiLine() then
		PE = self:GetParent():GetParent():GetParent()
	else
		PE = self:GetParent():GetParent()
	end
	if PE.inherited then
		PE:SetAttribute("inherited", false)
		PE:SetAttribute("contents", nil)
	end
end

function XRPEditorPeekText_Mixin:OnEditFocusLost()
	self:HighlightText(0, 0)
	self:ClearFocus()
	XRPEditorControls_CheckField(self:IsMultiLine() and self:GetParent():GetParent():GetParent() or self:GetParent():GetParent())
end

function XRPEditorPeekText_Mixin:OnTabPressed()
	if self:IsMultiLine() then
		local parent = self:GetParent():GetParent()
		parent:GetParent().peeks[(parent:GetID() % 5) + 1].IC:Click()
	else
		local editBox = self:GetParent().DE.EditBox
		editBox:SetFocus()
		editBox:HighlightText()
	end
end

XRPEditorGlances_Mixin = {}

function XRPEditorGlances_Mixin:OnLoad()
	if not XRPEditor.fields then
		XRPEditor.fields = {}
	end
	self:GetParent().fields.PE = self
end

function XRPEditorGlances_Mixin:OnAttributeChanged(name, value)
	if name == "contents" then
		self.contents = value
		for i, peek in ipairs(self.peeks) do
			peek:SetAttribute("contents", value and value[i] or {})
		end
	elseif name == "inherited" then
		if value and not self.inherited then
			for i, peek in ipairs(self.peeks) do
				peek:SetAttribute("inherited", true)
			end
			self.inherited = true
		elseif not value and self.inherited then
			for i, peek in ipairs(self.peeks) do
				peek:SetAttribute("inherited", false)
			end
			self.inherited = false
		end
	end
end

function XRPEditorGlances_Mixin:UpdatePeeks()
	if self.contents then
		wipe(self.contents)
	end
	for i, peek in ipairs(self.peeks) do
		if peek.peek.IC or peek.peek.NA or peek.peek.DE then
			if not self.contents then
				self.contents = AddOn.GetEmptyPE()
			end
			self.contents[#self.contents + 1] = peek.peek
			peek.Clear:SetEnabled(true)
		else
			peek.Clear:SetEnabled(false)
		end
	end
	if self.contents and not next(self.contents) then
		self.contents = nil
	end
	XRPEditorControls_CheckField(self)
end

XRPEditorIconsFilter_Mixin = {}

local iconList = {}
function XRPEditorIconsFilter_Mixin:OnTextChanged(userInput)
	local search = self:GetText():lower()
	if search == "" then
		search = nil
	end
	wipe(iconList)
	iconList[1] = "Interface\\Icons\\inv_misc_questionmark"
	for i, icon in ipairs(AddOn.ICON_LIST) do
		if not search or icon:find(search, nil, true) then
			local texturePath = "Interface\\Icons\\" .. icon
			if GetFileIDFromPath(texturePath) then
				iconList[#iconList + 1] = texturePath
			end
		end
	end
	self:GetParent().ScrollFrame:Update()
end

function XRPEditorIconsFilter_Mixin:OnEditFocusGained()
	local PE = self:GetParent().selectedFrame:GetParent()
	if PE.inherited then
		PE:SetAttribute("inherited", false)
		PE:SetAttribute("contents", nil)
	end
end

function XRPEditorIconsFilter_Mixin:OnEditFocusLost()
	if GetMouseFocus() ~= self.clearButton then
		HideParentPanel(self)
	else
		self:SetFocus()
	end
end

function XRPEditorIconsFilter_Mixin:OnTabPressed()
	local parent = self:GetParent()
	local peek = parent.selectedFrame
	parent:Hide()
	peek.NA:SetFocus()
	peek.NA:HighlightText()
end

function XRPEditorIconsFilter_Mixin:OnLoad()
	if self.instructionsText then
		self.Instructions:SetText(L(self.instructionsText))
	end
end

XRPEditorIcons_Mixin = {}

function XRPEditorIcons_Mixin:OnShow()
	if not self.iconsArrayBuilt then
		self.iconsArrayBuilt = true
		BuildIconArray(self, "XRPEditorIconsButton", "XRPEditorPopupIconTemplate", 8, 8)
		self.buttons[1]:SetPoint("TOPLEFT", self.HeaderTop, "BOTTOMLEFT", 5, -2)
	end
	local IC = self.selectedFrame.peek.IC
	local icon = IC and IC:match("^Interface\\Icons\\(.+)")
	self.FilterIcons:SetText(icon ~= "TEMP" and icon or "")
	self.FilterIcons:SetFocus()
	self.ScrollFrame:Update()
end

function XRPEditorIcons_Mixin:OnHide()
	local peek = self.selectedFrame
	self.selectedFrame = nil
	peek.IC:SetChecked(false)
	peek:GetParent():UpdatePeeks()
end

XRPEditorIconsScrollFrame_Mixin = {}

function XRPEditorIconsScrollFrame_Mixin:Update()
	local numIcons = #iconList
	local offset = FauxScrollFrame_GetOffset(self)
	local parent = self:GetParent()

	for i=1, 8 * 8 do
		local button = parent.buttons[i]
		local index = (offset * 8) + i
		local texture = iconList[index]
		local texturePath = index ~= 1 and texture or nil

		if ( index <= numIcons and texture ) then
			button:SetNormalTexture(texture)
			button.texturePath = texturePath
			button:Show()
		else
			button:SetNormalTexture("")
			button.texturePath = nil
			button:Hide()
		end
		if parent.selectedFrame.peek.IC == texturePath then
			button:SetChecked(true)
		else
			button:SetChecked(false)
		end
	end

	FauxScrollFrame_Update(self, ceil(numIcons / 8) + 1, 8, 36)
end

function XRPEditorIconsScrollFrame_Mixin:OnVerticalScroll(offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 36, self.Update)
end

function XRPEditorIconsScrollFrame_Mixin:OnLoad()
	self.ScrollBar.scrollStep = 72
end

-- This has scripts for a few different frames.
XRPEditorGlancesTemplates_Mixin = {}

function XRPEditorGlancesTemplates_Mixin:PeekICOnClick(button, down)
	local peek = self:GetParent()
	local PE = peek:GetParent()
	local Icons = PE:GetParent().Icons
	if self:GetChecked() then
		if Icons:IsShown() then
			Icons:Hide()
		end
		Icons.selectedFrame = peek
		Icons:Show()
	else
		Icons:Hide()
	end
end

function XRPEditorGlancesTemplates_Mixin:PeekClearOnClick(button, down)
	local peek = self:GetParent()
	peek:SetPeek(nil)
	peek:GetParent():UpdatePeeks()
end

function XRPEditorGlancesTemplates_Mixin:PopupIconOnClick(button, down)
	local Icons = self:GetParent()
	local peek = Icons.selectedFrame
	peek.peek.IC = self.texturePath
	peek.IC:SetNormalTexture(self.texturePath or "Interface\\Icons\\inv_misc_questionmark")
	--peek:GetParent():UpdatePeeks()
	Icons.ScrollFrame:Update()
end
