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

local addonName, _xrp = ...

XRP_APPEARANCE = _xrp.L.APPEARANCE
XRP_BIOGRAPHY = _xrp.L.BIOGRAPHY
XRP_NOTES = _xrp.L.NOTES
XRP_NOTES_INSTRUCTIONS = _xrp.L.NOTES_INSTRUCTIONS

XRPTemplates_DoNothing = _xrp.noFunc

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
	if not (self.tooltipText or self.tooltipKey) then return end
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:SetText(self.tooltipText or _xrp.L[self.tooltipKey] or _G[self.tooltipKey])
	GameTooltip:Show()
end

function XRPTemplates_TooltipTruncated(self, ...)
	if self.Text:IsTruncated() then
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
			if not HelpPlate_IsShowing(parent.helpPlates) then
				HelpPlate_Show(parent.helpPlates, parent, self, true)
			end
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
	if self.FocusButton then
		self.ScrollBar:SetFrameLevel(self.FocusButton:GetFrameLevel() + 2)
		if self.EditBox then
			self.EditBox:SetFrameLevel(self.FocusButton:GetFrameLevel() + 1)
		end
	end
end

function XRPTemplatesScrollFrame_OnSizeChanged(self, width, height)
	if self.EditBox then
		self.EditBox:SetWidth(width - 18)
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
	self.TitleText:SetText(self.titleText or _xrp.L[self.titleKey] or _G[self.titleKey])
end

function XRPTemplatesPanel_OnShow(self)
	if self.portraitUnit then
		SetPortraitTexture(self.portrait, self.portraitUnit)
	end
	PlaySound("igCharacterInfoOpen")
end

function XRPTemplatesPanel_OnHide(self)
	if self.popouts then
		for i, popout in ipairs(self.popouts) do
			popout:Hide()
		end
	end
	PlaySound("igCharacterInfoClose")
end

function XRPTooltip_OnUpdate(self, elapsed)
	if not self.fading and not UnitExists("mouseover") then
		self.fading = true
		self:FadeOut()
	end
end

function XRPTooltip_OnHide(self)
	self.fading = nil
end

function XRPCursorBook_OnEvent(self, event)
	if InCombatLockdown() or _xrp.settings.interact.disableInstance and (IsInInstance() or IsInActiveWorldPVP()) or _xrp.settings.interact.disablePvP and (UnitIsPVP("player") or UnitIsPVPFreeForAll("player")) or GetMouseFocus() ~= WorldFrame then
		self:Hide()
		return
	end
	local character = xrp.characters.byUnit.mouseover
	if not character or character.hide then
		self:Hide()
		return
	end
	self.current = not UnitCanAttack("player", "mouseover") and tostring(character) or nil
	-- Following two must be separate for UIErrorsFrame:Clear().
	self.mountable = self.current and UnitVehicleSeatCount("mouseover") > 0
	self.mountInParty = self.mountable and (UnitInParty("mouseover") or UnitInRaid("mouseover"))
	if self.current and character.fields.VA and (not self.mountInParty or not IsItemInRange(88589, "mouseover")) then
		self:Show()
	else
		self:Hide()
	end
end

do
	local previousX, previousY
	-- Crazy optimization crap since it's run every frame.
	local UnitIsPlayer, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, IsItemInRange, UIParent, GetEffectiveScale = UnitIsPlayer, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, IsItemInRange, UIParent, UIParent.GetEffectiveScale
	function XRPCursorBook_OnUpdate(self, elapsed)
		if not UnitIsPlayer("mouseover") or InCombatLockdown() or GetMouseFocus() ~= WorldFrame then
			self:Hide()
			return
		end
		local x, y = GetCursorPosition()
		if x == previousX and y == previousY then return end
		if self.mountInParty and IsItemInRange(88589, "mouseover") then
			self:Hide()
			return
		end
		local scale = GetEffectiveScale(UIParent)
		self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale + 36, y/scale - 4)
		previousX, previousY = x, y
	end
end

function XRPTemplatesPopout_OnShow(self)
	for i, popout in ipairs(self:GetParent().popouts) do
		if popout ~= self and popout:IsVisible() then
			popout:Hide()
		end
	end
	local parent = self:GetParent()
	parent:SetAttribute("UIPanelLayout-extraWidth", self:GetWidth())
	if parent:GetAttribute("UIPanelLayout-defined") then
		UpdateUIPanelPositions(parent)
	end
	PlaySound("UChatScrollButton")
end

function XRPTemplatesPopout_OnHide(self)
	local parent = self:GetParent()
	parent:SetAttribute("UIPanelLayout-extraWidth", nil)
	if parent:GetAttribute("UIPanelLayout-defined") then
		UpdateUIPanelPositions(parent)
	end
	PlaySound("UChatScrollButton")
end

local function XRPTemplatesNotes_Hook_OnSizeChanged(self, width, height)
	self.Notes:SetHeight(height - 56)
end

local allNotes = {}
function XRPTemplatesNotes_OnLoad(self)
	allNotes[#allNotes + 1] = self
	self:GetParent():HookScript("OnSizeChanged", XRPTemplatesNotes_Hook_OnSizeChanged)
end

function XRPTemplatesNotes_OnShow(self)
	for i, notes in ipairs(allNotes) do
		if notes ~= self and notes:IsVisible() and tostring(notes.character) == tostring(self.character) then
			self.Text.EditBox:SetText(notes.Text.EditBox:GetText())
			notes.Text.EditBox:SetText(self.character.notes or "")
			notes:Hide()
		end
	end
end

function XRPTemplatesNotes_OnHide(self)
	local text = self.Text.EditBox:GetText()
	if text == "" then
		text = nil
	end
	self.character.notes = text
	self.Revert:SetEnabled(false)
end

function XRPTemplatesNotes_OnAttributeChanged(self, name, value)
	if name == "character" and value ~= self.character then
		if self.character then
			local text = self.Text.EditBox:GetText()
			if text == "" then
				text = nil
			end
			self.character.notes = text
		end
		self.character = value
		self.Text.EditBox:SetText(self.character.notes or "")
		if self:IsVisible() then
			XRPTemplatesNotes_OnShow(self)
		end
	end
end

function XRPTemplatesNotesEditBox_OnEditFocusGained(self)
	self.Instructions:Hide()
end

function XRPTemplatesNotesEditBox_OnEditFocusLost(self)
	if self:GetText() == "" then
		self.Instructions:Show()
	else
		self.Instructions:Hide()
	end
end

function XRPTemplatesNotesEditBox_OnTextChanged(self, userInput)
	local parent = self:GetParent()
	ScrollingEdit_OnTextChanged(self, parent)
	local text = self:GetText()
	if text == "" then
		text = nil
	end
	local notes = parent:GetParent()
	if text == notes.character.notes then
		notes.Revert:SetEnabled(false)
	else
		notes.Revert:SetEnabled(true)
	end
	if not userInput and not self:HasFocus() then
		XRPTemplatesNotesEditBox_OnEditFocusLost(self)
	end
end

function XRPTemplatesNotesRevert_OnClick(self, button, down)
	local parent = self:GetParent()
	parent.Text.EditBox:ClearFocus()
	parent.Text.EditBox:SetText(parent.character.notes or "")
end
