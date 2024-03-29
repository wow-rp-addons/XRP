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

local Names, Values = AddOn_XRP.Strings.Names, AddOn_XRP.Strings.Values
local MenuNames, MenuValues = AddOn_XRP.Strings.MenuNames, AddOn_XRP.Strings.MenuValues

local function FallbackFieldContents(field)
	if AddOn.FallbackFields[field] then
		return AddOn.FallbackFields[field]
	elseif field == "RA" then
		return Values.GR[select(2, UnitRace("player"))]
	elseif field == "RC" then
		return Values.GC["1"][select(2, UnitClass("player"))]
	end
	return nil
end

local function CheckField(self, profile, parent)
	if (not self.HasFocus or not self:HasFocus()) and (not self.contents or self.inherited) then
		if parent and self.Inherit:GetChecked() then
			self:SetAttribute("inherited", true)
			self:SetAttribute("contents", parent.Full[self.field] or FallbackFieldContents(self.field))
		else
			local fallback = FallbackFieldContents(self.field)
			self:SetAttribute("inherited", fallback ~= nil)
			self:SetAttribute("contents", fallback)
		end
	end
	if parent then
		self.Inherit:Show()
	else
		self.Inherit:Hide()
	end
	return self.inherited and profile.Field[self.field] ~= nil or not self.inherited and self.contents ~= profile.Field[self.field] or self.Inherit:GetChecked() ~= profile.Inherit[self.field] or nil
end

local modified = {}
local function CheckFields(field)
	local profile = AddOn_XRP.Profiles[XRPEditor.Profiles.contents]
	local parent = AddOn_XRP.Profiles[XRPEditor.Parent.contents]
	if XRPEditor.fields[field] then
		modified[field] = CheckField(XRPEditor.fields[field], profile, parent)
	else
		for field, control in pairs(XRPEditor.fields) do
			modified[field] = CheckField(XRPEditor.fields[field], profile, parent)
		end
	end
	if next(modified) or (parent and parent.name) ~= profile.parent then
		XRPEditor.Save:Enable()
		XRPEditor.Revert:Enable()
	else
		XRPEditor.Save:Disable()
		XRPEditor.Revert:Disable()
	end
end

local function ClearAllFocus()
	local focused = GetCurrentKeyBoardFocus()
	if focused then
		focused:ClearFocus()
	end
end

function XRPEditorSave_OnClick(self, button, down)
	ClearAllFocus()

	local name = XRPEditor.Profiles.contents
	local profile = AddOn_XRP.Profiles[name]
	-- TOOD: inform user if the profile was deleted.
	for field, control in pairs(XRPEditor.fields) do
		profile.Field[field] = not control.inherited and control.contents or nil
		profile.Inherit[field] = control.Inherit:GetChecked()
	end
	profile.parent = XRPEditor.Parent.contents

	CheckFields()
end

function XRPEditor_Edit(self, name)
	if not self:IsShown() then
		ShowUIPanel(self)
	elseif not name then
		HideUIPanel(self)
		return
	end
	if not name and (not self.Profiles.contents or self.Revert:GetButtonState() == "DISABLED" and self.Profiles.contents ~= AddOn_XRP.Profiles.SELECTED.name) then
		name = AddOn_XRP.Profiles.SELECTED.name
	elseif not name then
		return
	end
	ClearAllFocus()

	local profile = AddOn_XRP.Profiles[name]
	-- TOOD: inform user if the profile was deleted.

	local fields, inherit = profile.Field, profile.Inherit
	for field, control in pairs(self.fields) do
		control:SetAttribute("inherited", false)
		control:SetAttribute("contents", fields[field])
		control.Inherit:SetChecked(inherit[field])
	end

	if self.Profiles.contents ~= name and not self.panes[1]:IsVisible() then
		self.Tab1:Click()
	end

	self.Profiles.contents = name
	self.Profiles.Text:SetText(name)

	local value = profile.parent
	self.Parent.contents = value
	self.Parent:SetFormattedText(SUBTITLE_FORMAT, L.PARENT, value or NONE)

	self.TitleContainer.TitleText:SetFormattedText(SUBTITLE_FORMAT, L.PROFILE_EDITOR, name)

	CheckFields()
end

function XRPEditorPopup_OnClick(self, button, down)
	StaticPopup_Show(self.popup, XRPEditor.Profiles.contents)
end

function XRPEditorEButton_OnClick(self, button, down)
	XRPExport:Export(XRPEditor.Profiles.contents, AddOn_XRP.Profiles[XRPEditor.Profiles.contents].exportPlainText)
end

function XRPEditorRevert_OnClick(self, button, down)
	XRPEditor:Edit(XRPEditor.Profiles.contents)
end

local function Checked(self)
	return self.arg1 == MSA_DROPDOWNMENU_INIT_MENU.contents
end

local function Profiles_Click(self, arg1, arg2, checked)
	if not checked then
		if XRPEditor.Revert:GetButtonState() == "DISABLED" then
			XRPEditor:Edit(arg1)
		else
			StaticPopup_Show("XRP_EDITOR_UNSAVED", XRPEditor.Profiles.contents, nil, arg1)
		end
	end
end

function XRPEditorProfiles_PreClick(self, button, down)
	local parent = self:GetParent()
	parent.baseMenuList = {}
	for i, profile in ipairs(AddOn_XRP.GetProfileList()) do
		parent.baseMenuList[i] = { text = profile, checked = Checked, arg1 = profile, func = Profiles_Click }
	end
end

local function Parent_Click(self, arg1, arg2, checked)
	if not checked then
		MSA_DROPDOWNMENU_INIT_MENU.contents = arg1
		MSA_DROPDOWNMENU_INIT_MENU:SetFormattedText(SUBTITLE_FORMAT, L.PARENT, arg1 or NONE)
		CheckFields()
	end
end

local NONE_MENU = { text = NONE, checked = Checked, arg1 = nil, func = Parent_Click }
function XRPEditorParent_PreClick(self, button, down)
	self.baseMenuList = { NONE_MENU }
	local editingProfile = XRPEditor.Profiles.contents
	for i, profile in ipairs(AddOn_XRP.GetProfileList()) do
		if profile ~= editingProfile and AddOn_XRP.Profiles[editingProfile]:IsParentValid(profile) then
			self.baseMenuList[#self.baseMenuList + 1] = { text = profile, checked = Checked, arg1 = profile, func = Parent_Click }
		end
	end
end

local function FC_Click(self, arg1, arg2, checked)
	if not checked or MSA_DROPDOWNMENU_INIT_MENU.inherited then
		MSA_DROPDOWNMENU_INIT_MENU:SetAttribute("contents", arg1)
		MSA_DROPDOWNMENU_INIT_MENU:SetAttribute("inherited", false)
		CheckFields("FC")
	end
end

local baseMenuList = {
	{ text = PARENS_TEMPLATE:format(DEFAULT), checked = Checked, func = FC_Click }
}
for i = 1, 4 do
	local s = tostring(i)
	baseMenuList[i + 1] = { text = MenuValues.FC[s], checked = Checked, arg1 = s, func = FC_Click }
end
XRPEditorFC_baseMenuList = baseMenuList

function XRPEditorControls_OnAttributeChanged(self, name, value)
	if name == "contents" then
		self.contents = value
		self:SetText(value or "")
		self:SetCursorPosition(0)
		if value and #value > self.safeLength then
			self.Warning:Show()
		else
			self.Warning:Hide()
		end
	elseif name == "inherited" then
		if value and not self.inherited then
			self:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			self.inherited = true
		elseif not value and self.inherited then
			self:SetTextColor(1, 1, 1)
			self.inherited = false
		end
	end
end

function XRPEditorDropDown_OnAttributeChanged(self, name, value)
	if name == "contents" then
		self.contents = value
		self.Text:SetText(MenuValues[self.field][value or "0"])
	elseif name == "inherited" then
		if value == true and not self.inherited then
			self.Text:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			self.inherited = true
		elseif value == false and self.inherited then
			self.Text:SetTextColor(self.Text:GetFontObject():GetTextColor())
			self.inherited = false
		end
	end
end

function XRPEditorControls_OnLoad(self)
	local fieldName = Names[self.field] or L[self.labelKey]
	self.Label:SetText(fieldName)
	if self.EditBox then
		self.EditBox.field = self.field
		self.EditBox.safeLength = self.safeLength
		self.EditBox.Inherit = self.Inherit
		self.EditBox.Warning = self.Warning
	end
	if self.safeLength then
		self.Warning.tooltipText = ("|cffcc0000%s|r %s"):format(STAT_FORMAT:format(L.WARNING), L"%s is over %d characters.":format(fieldName, self.safeLength))
	end
	if self.field then
		if not XRPEditor.fields then
			XRPEditor.fields = {}
		end
		XRPEditor.fields[self.field] = self.EditBox or self
	end
end

function XRPEditorControls_CheckField(self)
	CheckFields(self.field or self:GetParent().field)
end

function XRPEditorControls_OnTabPressed(self)
	if IsShiftKeyDown() and self:IsMultiLine() then
		self:Insert("        ")
	else
		XRPEditor.fields[self.nextField or self:GetParent().nextField]:SetFocus()
	end
end

function XRPEditorControls_OnTextChanged(self, userInput)
	if self:IsMultiLine() then
		ScrollingEdit_OnTextChanged(self, self:GetParent())
	end
	if userInput then
		local text = self:GetText()
		self.contents = text ~= "" and text or nil
		if #text > self.safeLength then
			self.Warning:Show()
		else
			self.Warning:Hide()
		end
		XRPEditorControls_CheckField(self)
	end
end

function XRPEditorControls_OnEditFocusGained(self)
	if self.inherited then
		self:SetAttribute("inherited", false)
		self:SetAttribute("contents", nil)
	end
end

function XRPEditorControls_OnEditFocusLost(self)
	self:HighlightText(0, 0)
	self:ClearFocus()
	XRPEditorControls_CheckField(self)
end

function XRPEditorNotes_OnShow(self)
	if not self.character then
		self.character = AddOn_XRP.Characters.byUnit.player
	end
end
