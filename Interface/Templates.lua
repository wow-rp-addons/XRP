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
	GameTooltip:SetText(self.tooltipText or L[self.tooltipKey] or _G[self.tooltipKey])
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
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
end

function XRPTemplatesDropDown_OnLoad(self)
	if self.width then
		UIDropDownMenu_SetWidth(self, self.width, 0)
	end
	if self.preClick then
		_G[self:GetName() .. "Button"]:SetScript("PreClick", self.preClick)
	end
end

local function Menu_Initialize(self, level, menuList)
	if level == 1 then
		menuList = self.baseMenuList or self:GetParent().baseMenuList
	end
	for i, entry in ipairs(menuList) do
		if (entry.text) then
			UIDropDownMenu_AddButton(entry, level)
		end
	end
end

XRPTemplatesDropDown_Mixin = {
	initialize = Menu_Initialize,
	relativePoint = "BOTTOMRIGHT",
	xOffset = -11,
	yOffset = 22,
}

XRPTemplatesMenu_Mixin = {
	initialize = Menu_Initialize,
	SetHeight = AddOn.DoNothing,
}

function XRPTemplatesMenu_OnClick(self, button, down)
	ToggleDropDownMenu(nil, nil, self.Menu or self, self.anchor or self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function XRPTemplatesScrollFrame_OnLoad(self)
	self.ScrollBar:ClearAllPoints()
	self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", -13, -11)
	self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -13, 9)
	self.ScrollBar.ScrollDownButton:SetPoint("TOP", self.ScrollBar, "BOTTOM", 0, 4)
	self.ScrollBar.ScrollUpButton:SetPoint("BOTTOM", self.ScrollBar, "TOP", 0, -4)
	self.ScrollBar.ScrollUpButton:Disable()
	self.ScrollBar:Hide()
end

function XRPTemplatesScrollFrame_OnSizeChanged(self, width, height)
	if self.EditBox then
		self.EditBox:SetWidth(width - 18)
	end
end

function XRPTemplatesScrollFrame_OnMouseDown(self, button)
	if self.EditBox then
		self.EditBox:SetFocus()
		self.EditBox:SetCursorPosition(#self.EditBox:GetText())
	end
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
	self.TitleText:SetText(self.titleText or L[self.titleKey] or _G[self.titleKey])
end

function XRPTemplatesPanel_OnShow(self)
	if self.portraitUnit then
		SetPortraitTexture(self.portrait, self.portraitUnit)
	end
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
end

function XRPTemplatesPanel_OnHide(self)
	if self.popouts then
		for i, popout in ipairs(self.popouts) do
			popout:Hide()
		end
	end
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
end

function XRPTemplatesPanel_OnSizeChanged(self, width, height)
	local uiWidth = UIParent:GetWidth()
	if width > uiWidth then
		self:SetWidth(uiWidth * 0.95)
		return
	end
	local uiHeight = UIParent:GetHeight()
	if height > uiHeight then
		self:SetHeight(uiHeight * 0.95)
		return
	end
end

function XRPCursorBook_OnEvent(self, event)
	if InCombatLockdown() or AddOn.Settings.cursorDisableInstance and (IsInInstance() or IsInActiveWorldPVP()) or AddOn.Settings.cursorDisablePvP and (UnitIsPVP("player") or UnitIsPVPFreeForAll("player")) or UnitIsUnit("player", "mouseover") or GetMouseFocus() ~= WorldFrame then
		self:Hide()
		return
	end
	local character = AddOn_XRP.Characters.byUnit.mouseover
	if not character or character.hidden then
		self:Hide()
		return
	end
	self.characterID = not UnitCanAttack("player", "mouseover") and character.id
	self.characterName = self.characterID and character.name
	-- Following two must be separate for UIErrorsFrame:Clear().
	self.mountable = self.characterID and UnitVehicleSeatCount("mouseover") > 0
	self.mountInParty = self.mountable and (UnitInParty("mouseover") or UnitInRaid("mouseover"))
	if self.characterID and character.VA and (not self.mountInParty or not IsItemInRange(88589, "mouseover")) then
		XRPCursorBook_OnUpdate(self, 0)
		self:Show()
	else
		self:Hide()
	end
end

local previousX, previousY
-- Crazy optimization crap since it's run every frame.
do
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

function XRPTemplatesPopoutButton_OnLoad(self)
	self:SetFrameLevel(self:GetFrameLevel() + 1)
	local popout = self:GetParent()[self.popout]
	popout:HookScript("OnShow", function(...)
		self.Icon:SetTexCoord(1, 0, 0, 1)
	end)
	popout:HookScript("OnHide", function(...)
		self.Icon:SetTexCoord(0, 1, 0, 1)
	end)
end

function XRPTemplatesPopoutButton_OnMouseDown(self)
	if self:IsEnabled() and self.MainIcon then
		local point, relativeTo, relativePoint, x, y = self.MainIcon:GetPoint(1)
		self.MainIcon:SetPoint(point, x + 1, y - 1)
	end
end

function XRPTemplatesPopoutButton_OnMouseUp(self)
	if self:IsEnabled() and self.MainIcon then
		local point, relativeTo, relativePoint, x, y = self.MainIcon:GetPoint(1)
		self.MainIcon:SetPoint(point, x - 1, y + 1)
	end
end

function XRPTemplatesPopoutButton_OnClick(self, button, down)
	local popout = self:GetParent()[self.popout]
	if not popout:IsShown() then
		popout:Show()
	else
		popout:Hide()
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
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function XRPTemplatesPopout_OnHide(self)
	local parent = self:GetParent()
	parent:SetAttribute("UIPanelLayout-extraWidth", parent.extraWidth or nil)
	if parent:GetAttribute("UIPanelLayout-defined") then
		UpdateUIPanelPositions(parent)
	end
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
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
	self.Text.EditBox:SetText(self.character.notes or "")
	for i, notes in ipairs(allNotes) do
		if notes ~= self and notes:IsVisible() and notes.character == self.character then
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
		local visible = self:IsVisible()
		if visible then
			XRPTemplatesNotes_OnHide(self)
		end
		self.character = value
		if visible then
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
