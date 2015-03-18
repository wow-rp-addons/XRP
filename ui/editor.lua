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

local addonName, xrpLocal = ...

do
	local function ClearAllFocus()
		local focused = GetCurrentKeyBoardFocus()
		if focused then
			focused:ClearFocus()
		end
	end

	function XRPEditorSave_OnClick(self, button, down)
		ClearAllFocus()

		local name = XRPEditor.Profiles.contents
		local profile, inherits = xrpLocal.profiles[name].fields, xrpLocal.profiles[name].inherits
		for field, control in pairs(XRPEditor.fields) do
			profile[field] = not control.inherited and control.contents or nil
			inherits[field] = control.Inherit:GetChecked()
		end
		local parent = XRPEditor.Parent.contents
		xrpLocal.profiles[name].parent = parent
		if xrpLocal.profiles[name].parent ~= parent then
			local value = xrpLocal.profiles[name].parent
			XRPEditor.Parent.contents = value
			XRPEditor.Parent:SetFormattedText("Parent: %s",  value or "None")
		end

		XRPEditor:CheckFields()
	end

	function XRPEditor_Edit(self, name)
		if not self:IsShown() then
			ShowUIPanel(self)
		elseif not name then
			HideUIPanel(self)
			return
		end
		if not name and (not self.Profiles.contents or self.Revert:GetButtonState() == "DISABLED" and self.Profiles.contents ~= xrpSaved.selected) then
			name = xrpSaved.selected
		elseif not name then
			return
		end
		ClearAllFocus()

		local profile, inherits = xrpLocal.profiles[name].fields, xrpLocal.profiles[name].inherits
		for field, control in pairs(self.fields) do
			control:SetAttribute("inherited", false)
			control:SetAttribute("contents", profile[field])
			control.Inherit:SetChecked(inherits[field] ~= false)
		end

		if self.Profiles.contents ~= name and not self.panes[1]:IsVisible() then
			self.Tab1:Click()
		end

		self.Profiles.contents = name
		self.Profiles.Text:SetText(name)

		local value = xrpLocal.profiles[name].parent
		self.Parent.contents = value
		self.Parent:SetFormattedText("Parent: %s", value or "None")

		self.TitleText:SetFormattedText("Profile Editor: %s", name)

		self:CheckFields()
	end
end

do
	local function FallbackFieldContents(field)
		if field ~= "NA" and field ~= "RA" and field ~= "RC" then
			return nil
		end
		local metafield = field == "RA" and "GR" or field == "RC" and "GC" or nil
		return xrpSaved.meta.fields[field] or xrp.values[metafield][xrpSaved.meta.fields[metafield]] or nil
	end

	local function CheckField(control, name, parent, profile, inherits, field)
		if (not control.HasFocus or not control:HasFocus()) and (not control.contents or control.inherited) then
			if parent and control.Inherit:GetChecked() then
				control:SetAttribute("inherited", true)
				local parentcontent = xrpLocal.profiles[parent].fields[field]
				if parentcontent then
					control:SetAttribute("contents", parentcontent)
				else
					local parentinherit = xrpLocal.profiles[parent].inherits[field]
					if type(parentinherit) == "string" and parentinherit ~= name then
						control:SetAttribute("contents", xrpLocal.profiles[parentinherit].fields[field])
					else
						control:SetAttribute("contents", FallbackFieldContents(field))
					end
				end
			else
				local fallback = FallbackFieldContents(field)
				control:SetAttribute("inherited", fallback ~= nil)
				control:SetAttribute("contents", fallback)
			end
		end
		if parent then
			control.Inherit:Show()
		else
			control.Inherit:Hide()
		end
		return control.inherited and profile[field] ~= nil or not control.inherited and control.contents ~= profile[field] or control.Inherit:GetChecked() ~= (inherits[field] ~= false) or nil
	end

	local modified = {}
	function XRPEditor_CheckFields(self, field)
		local name, parent = self.Profiles.contents, self.Parent.contents
		if not xrpLocal.profiles[name] then return end
		local profile, inherits = xrpLocal.profiles[name].fields, xrpLocal.profiles[name].inherits
		if self.fields[field] then
			modified[field] = CheckField(self.fields[field], name, parent, profile, inherits, field)
		else
			for field, control in pairs(self.fields) do
				modified[field] = CheckField(control, name, parent, profile, inherits, field)
			end
		end
		if parent ~= xrpLocal.profiles[name].parent or next(modified) then
			self.Save:Enable()
			self.Revert:Enable()
		else
			self.Save:Disable()
			self.Revert:Disable()
		end
	end
end

function XRPEditorPopup_OnClick(self, button, down)
	StaticPopup_Show(self.popup, XRPEditor.Profiles.contents)
end

function XRPEditorRevert_OnClick(self, button, down)
	XRPEditor:Edit(XRPEditor.Profiles.contents)
end

do
	local function Checked(self)
		return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
	end

	do
		local function Profiles_Click(self, arg1, arg2, checked)
			if not checked then
				XRPEditor:Edit(arg1)
			end
		end

		function XRPEditorProfiles_PreClick(self, button, down)
			local parent = self:GetParent()
			parent.baseMenuList = {}
			for i, profile in ipairs(xrpLocal.profiles:List()) do
				parent.baseMenuList[i] = { text = profile, checked = Checked, arg1 = profile, func = Profiles_Click }
			end
		end
	end

	do
		local function Parent_Click(self, arg1, arg2, checked)
			if not checked then
				UIDROPDOWNMENU_OPEN_MENU.contents = arg1
				UIDROPDOWNMENU_OPEN_MENU:SetFormattedText("Parent: %s", arg1 or "None")
				XRPEditor:CheckFields()
			end
		end

		local NONE = { text = "None", checked = Checked, arg1 = nil, func = Parent_Click }
		function XRPEditorParent_PreClick(self, button, down)
			self.baseMenuList = { NONE }
			local editingProfile = XRPEditor.Profiles.contents
			for i, profile in ipairs(xrpLocal.profiles:List()) do
				if profile ~= editingProfile and not xrpLocal:DoesParentLoop(editingProfile, profile) then
					self.baseMenuList[#self.baseMenuList + 1] = { text = profile, checked = Checked, arg1 = profile, func = Parent_Click }
				end
			end
		end
	end

	do
		local function FC_Click(self, arg1, arg2, checked)
			if not checked or UIDROPDOWNMENU_OPEN_MENU.inherited then
				UIDROPDOWNMENU_OPEN_MENU:SetAttribute("contents", arg1)
				UIDROPDOWNMENU_OPEN_MENU:SetAttribute("inherited", false)
				XRPEditor:CheckFields("FC")
			end
		end

		local FC = xrp.values.FC
		local baseMenuList = {}
		for i = 0, 4, 1 do
			local s = tostring(i)
			baseMenuList[i + 1] = { text = FC[s], checked = Checked, arg1 = i ~= 0 and s or nil, func = FC_Click }
		end
		XRPEditorFC_baseMenuList = baseMenuList
	end
end

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
		if value == true and not self.inherited then
			self:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			self.inherited = true
		elseif value == false and self.inherited then
			self:SetTextColor(self:GetFontObject():GetTextColor())
			self.inherited = false
		end
	end
end

function XRPEditorDropDown_OnAttributeChanged(self, name, value)
	if name == "contents" then
		self.contents = value
		self.Text:SetText(xrp.values[self.field][value or "0"])
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
	self.Label:SetText(self.fieldName)
	if self.EditBox then
		self.EditBox.field = self.field
		self.EditBox.safeLength = self.safeLength
		self.EditBox.Inherit = self.Inherit
		self.EditBox.Warning = self.Warning
	end
	if self.safeLength then
		self.Warning.tooltipText = ("|cffcc0000Warning:|r %s is over %u characters."):format(self.fieldName, self.safeLength)
	end
	if self.field then
		if not XRPEditor.fields then
			XRPEditor.fields = {}
		end
		XRPEditor.fields[self.field] = self.EditBox or self
	end
end

function XRPEditorControls_CheckField(self)
	XRPEditor:CheckFields(self.field or self:GetParent().field)
end

function XRPEditorControls_OnTabPressed(self)
	XRPEditor.fields[self.nextField or self:GetParent().nextField]:SetFocus()
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

function XRPEditorExport_OnClick(self, button, down)
	local profile = XRPEditor.Profiles.contents
	xrp:ExportPopup(profile, xrpLocal.profiles[profile]:Export())
end

function xrp:Edit(...)
	XRPEditor:Edit(...)
end
