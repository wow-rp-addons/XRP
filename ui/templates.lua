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

local addonName, xrpPrivate = ...

XRPTemplates_DoNothing = xrpPrivate.noFunc

function XRPTemplates_CloseDropDownMenus(self, ...)
	CloseDropDownMenus()
end

function XRPTemplates_HideParentParent(self, ...)
	self:GetParent():GetParent():Hide()
end

function XRPTemplates_ShowPopup(self, ...)
	if not self.popup then return end
	StaticPopup_Show(self.popup)
end

function XRPTemplates_RegisterMouse(self, ...)
	if self.registerClicks then
		self:RegisterForClicks(string.split(",", self.registerClicks))
	end
	if self.registerDrags then
		self:RegisterForDrag(string.split(",", self.registerDrags))
	end
end

function XRPTemplates_TooltipText(self, ...)
	if not self.tooltipText then return end
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:SetText(self.tooltipText)
	GameTooltip:Show()
end

function XRPTemplates_TooltipTruncated(self, ...)
	if self.Text.fullText then
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetText(self.Text.fullText)
	elseif self.Text:IsTruncated() then
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetText(self.Text:GetText())
	end
end

function XRPTemplatesTabButton_OnClick(self, button, down)
	local parent, id = self:GetParent(), self:GetID()
	PanelTemplates_SetTab(parent, id)
	for paneID, pane in ipairs(parent.panes) do
		if paneID == id then
			pane:Show()
		else
			pane:Hide()
		end
	end
	if parent.helpPlates and HelpPlate_IsShowing(parent.helpPlates) then
		local PreClick = parent.HelpButton:GetScript("PreClick")
		if PreClick then
			PreClick(parent.HelpButton, "LeftButton", false)
			HelpPlate_Show(parent.helpPlates, parent, self, true)
		end
	end
	PlaySound("igCharacterInfoTab")
end

local function XRPTemplatesDropDown_OnClick(self, button, down)
	local parent = self:GetParent()
	-- This uses baseMenuList instead of the default menuList, as menuList is
	-- overwritten when a second-level menu pops out.
	ToggleDropDownMenu(nil, nil, parent, nil, nil, nil, parent.baseMenuList)
	PlaySound("igMainMenuOptionCheckBoxOn")
end

function XRPTemplatesDropDown_OnLoad(self)
	local button = _G[self:GetName() .. "Button"]
	button:SetScript("OnClick", XRPTemplatesDropDown_OnClick)
	self.Text = _G[self:GetName() .. "Text"]
	if self.width then
		UIDropDownMenu_SetWidth(self, self.width, 0)
	end
	if self.preClick then
		button:SetScript("PreClick", self.preClick)
	end
end

function XRPTemplatesMenu_OnClick(self, button, down)
	-- This uses baseMenuList instead of the default menuList, as menuList is
	-- overwritten when a second-level menu pops out.
	ToggleDropDownMenu(nil, nil, self.Menu or self, self, nil, nil, self.baseMenuList)
	PlaySound("igMainMenuOptionCheckBoxOn")
end

function XRPTemplatesScrollFrame_OnLoad(self)
	self.ScrollBar:ClearAllPoints()
	self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", -13, -11)
	self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -13, 9)
	self.ScrollBar.ScrollDownButton:SetPoint("TOP", self.ScrollBar, "BOTTOM", 0, 4)
	self.ScrollBar.ScrollUpButton:SetPoint("BOTTOM", self.ScrollBar, "TOP", 0, -4)
	self.ScrollBar.ScrollUpButton:Disable()
	self.ScrollBar:Hide()
	if self.EditBox then
		self.EditBox:SetWidth(self:GetWidth() - 18)
	end
	if self.FocusButton then
		self.ScrollBar:SetFrameLevel(self.FocusButton:GetFrameLevel() + 2)
		if self.EditBox then
			self.EditBox:SetFrameLevel(self.FocusButton:GetFrameLevel() + 1)
		end
	end
end

function XRPTemplatesScrollFrameFocusButton_OnClick(self, button, down)
	local editBox = self:GetParent().EditBox
	editBox:SetFocus()
	editBox:SetCursorPosition(#editBox:GetText())
end

function XRPTemplatesRefresh_OnMouseDown(self)
	self.Icon:SetPoint("CENTER", self, "CENTER", -2, -1)
end

function XRPTemplatesRefresh_OnMouseUp(self)
	self.Icon:SetPoint("CENTER", self, "CENTER", -1, 0)
end

function XRPTemplatesScrollFrameEditBox_ResetToStart(self, ...)
	self:SetCursorPosition(0)
	self:GetParent():SetVerticalScroll(0)
end

function XRPTemplatesHelpButton_OnClick(self, button, down)
	local parent = self:GetParent()
	if not HelpPlate_IsShowing(parent.helpPlates) then
		CloseDropDownMenus()
		HelpPlate_Show(parent.helpPlates, parent, self, true)
	else
		HelpPlate_Hide(true)
	end
end

function XRPTemplatesHelpButton_OnHide(self)
	if HelpPlate_IsShowing(self:GetParent().helpPlates) then
		HelpPlate_Hide()
	end
end

function XRPTemplatesPanel_OnLoad(self)
	if self.portraitTexture then
		SetPortraitToTexture(self.portrait, self.portraitTexture)
	end
	if self.panes then
		PanelTemplates_SetNumTabs(self, #self.panes)
	end
	if self.numTabs then
		PanelTemplates_SetTab(self, 1)
	end
	self.TitleText:SetText(self.titleText)
end

function XRPTemplatesPanel_OnShow(self)
	if self.portraitUnit then
		SetPortraitTexture(self.portrait, self.portraitUnit)
	end
	PlaySound("igCharacterInfoOpen")
end

function XRPTemplatesPanel_OnHide(self)
	if self.subframe then
		self[self.subframe]:Hide()
	end
	PlaySound("igCharacterInfoClose")
end

function XRPTemplatesPanelSubframeToggle_OnClick(self, button, down)
	local parent = self:GetParent()
	local subframe = parent[parent.subframe]
	if subframe and subframe:IsVisible() then
		subframe:Hide()
	elseif subframe then
		subframe:Show()
	end
end

function XRPTemplatesPane_OnHide(self)
	PlaySound("UChatScrollButton")
end

XRP_EXPORT_INSTRUCTIONS = not IsMacClient() and "Press Ctrl+C to copy or Escape to close." or "Press Cmd+C to copy or Escape to close."

-- Analogue to XRPTemplatesScrollFrame_OnLoad for XRPExport.
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
		self:SetText(self:GetParent():GetParent().currentText or "")
		EditBox_HighlightText(self)
	end
end
