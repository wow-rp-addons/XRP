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

local XRPEditor_Save, XRPEditor_Load
do

	local function ClearAllFocus()
		local focused = GetCurrentKeyBoardFocus()
		if focused then
			focused:ClearFocus()
		end
	end

	function XRPEditor_Save(self)
		ClearAllFocus()

		local name = self.Profiles.contents
		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		for field, control in pairs(self.fields) do
			profile[field] = control.inherited and "" or control.contents
			inherits[field] = control.Inherit:GetChecked()
		end
		local parent = self.Parent.contents
		if parent == "" then
			parent = nil
		end
		xrp.profiles[name].parent = parent
		if xrp.profiles[name].parent ~= parent then
			local value = xrp.profiles[name].parent
			self.Parent.contents = value or ""
			self.Parent:SetFormattedText("Parent: %s", value and value ~= "" and value or "None")
		end

		self:CheckFields()
	end

	function XRPEditor_Load(self, name)
		ClearAllFocus()

		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		for field, control in pairs(self.fields) do
			control:SetAttribute("contents", profile[field] or "")
			control:SetAttribute("inherited", false)
			control.Inherit:SetChecked(inherits[field] ~= false)
		end

		if self.Profiles.contents ~= name and not self.panes[1]:IsVisible() then
			self.Tab1:Click()
		end

		self.Profiles.contents = name
		UIDropDownMenu_SetText(self.Profiles, name)

		local value = xrp.profiles[name].parent
		self.Parent.contents = value or ""
		self.Parent:SetFormattedText("Parent: %s", value and value ~= "" and value or "None")

		self.TitleText:SetFormattedText("Profile Editor: %s", name)

		self:CheckFields()
	end
end

local XRPEditor_CheckFields
do
	local function FallbackFieldContents(field)
		if field ~= "NA" and field ~= "RA" and field ~= "RC" then
			return ""
		end
		local metafield = field == "RA" and "GR" or field == "RC" and "GC" or nil
		return xrpSaved.meta.fields[field] or xrp.values[metafield][xrpSaved.meta.fields[metafield]] or ""
	end

	local function CheckField(control, name, parent, profile, inherits, field)
		if (not control.HasFocus or not control:HasFocus()) and (control.contents == "" or control.inherited) then
			if parent and control.Inherit:GetChecked() then
				control:SetAttribute("inherited", true)
				local parentcontent = xrp.profiles[parent].fields[field]
				if parentcontent then
					control:SetAttribute("contents", parentcontent)
				else
					local parentinherit = xrp.profiles[parent].inherits[field]
					if type(parentinherit) == "string" and parentinherit ~= name then
						control:SetAttribute("contents", xrp.profiles[parentinherit].fields[field])
					else
						control:SetAttribute("contents", FallbackFieldContents(field))
					end
				end
			else
				local fallback = FallbackFieldContents(field)
				control:SetAttribute("inherited", fallback ~= "")
				control:SetAttribute("contents", fallback)
			end
		end
		if parent then
			control.Inherit:Show()
		else
			control.Inherit:Hide()
		end
		return (control.inherited and profile[field] ~= nil) or (not control.inherited and control.contents ~= (profile[field] or "")) or (control.Inherit:GetChecked()) ~= (inherits[field] ~= false) or nil
	end

	function XRPEditor_CheckFields(self, field)
		local name, parent = self.Profiles.contents, self.Parent.contents
		if not xrp.profiles[name] then return end
		if parent == "" then
			parent = nil
		end
		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		if self.fields[field] then
			self.modified[field] = CheckField(self.fields[field], name, parent, profile, inherits, field)
		else
			for field, control in pairs(self.fields) do
				self.modified[field] = CheckField(control, name, parent, profile, inherits, field)
			end
		end
		if parent ~= xrp.profiles[name].parent or next(self.modified) then
			self.SaveButton:Enable()
			self.RevertButton:Enable()
		else
			self.SaveButton:Disable()
			self.RevertButton:Disable()
		end
	end
end

local XRPEditorProfiles_PreClick, XRPEditorParent_PreClick, XRPEditorFC_baseMenuList
do
	local function XRPEditor_Checked(self)
		return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
	end

	do
		local function XRPEditorProfiles_Click(self, arg1, arg2, checked)
			if not checked then
				UIDROPDOWNMENU_OPEN_MENU:GetParent():Load(arg1)
			end
		end

		function XRPEditorProfiles_PreClick(self, button, down)
			local parent = self:GetParent()
			parent.baseMenuList = {}
			for _, profile in ipairs(xrp.profiles:List()) do
				parent.baseMenuList[#parent.baseMenuList + 1] = { text = profile, checked = XRPEditor_Checked, arg1 = profile, func = XRPEditorProfiles_Click }
			end
		end
	end

	do
		local function XRPEditorParent_Click(self, arg1, arg2, checked)
			if not checked then
				UIDROPDOWNMENU_OPEN_MENU.contents = arg1 or ""
				UIDROPDOWNMENU_OPEN_MENU:SetFormattedText("Parent: %s", arg1 and arg1 ~= "" and arg1 or "None")
				UIDROPDOWNMENU_OPEN_MENU:GetParent():CheckFields()
			end
		end

		local none = { text = "None", checked = XRPEditor_Checked, arg1 = "", func = XRPEditorParent_Click }

		function XRPEditorParent_PreClick(self, button, down)
			self.baseMenuList = { none }
			for _, profile in ipairs(xrp.profiles:List()) do
				if profile ~= self:GetParent().Profiles.contents then
					self.baseMenuList[#self.baseMenuList + 1] = { text = profile, checked = XRPEditor_Checked, arg1 = profile, func = XRPEditorParent_Click }
				end
			end
		end
	end

	do
		local function XRPEditorFC_Click(self, arg1, arg2, checked)
			if not checked or UIDROPDOWNMENU_OPEN_MENU.inherited then
				UIDROPDOWNMENU_OPEN_MENU:SetAttribute("contents", arg1)
				UIDROPDOWNMENU_OPEN_MENU:SetAttribute("inherited", false)
				UIDROPDOWNMENU_OPEN_MENU:GetParent():GetParent():CheckFields("FC")
			end
		end

		local FC = xrp.values.FC
		XRPEditorFC_baseMenuList = {}
		for i = 0, #FC, 1 do
			XRPEditorFC_baseMenuList[#XRPEditorFC_baseMenuList + 1] = { text = FC[i], checked = XRPEditor_Checked, arg1 = i == 0 and "" or tostring(i), func = XRPEditorFC_Click }
		end
	end
end

function xrpPrivate:GetEditor()
	if xrpPrivate.editor then
		return xrpPrivate.editor
	end
	local frame = CreateFrame("Frame", "XRPEditor", UIParent, "XRPEditorTemplate")
	frame.Save = XRPEditor_Save
	frame.Load = XRPEditor_Load
	frame.CheckFields = XRPEditor_CheckFields
	frame.fields.FC.baseMenuList = XRPEditorFC_baseMenuList
	frame.Parent:SetScript("PreClick", XRPEditorParent_PreClick)
	frame.Profiles.ArrowButton:SetScript("PreClick", XRPEditorProfiles_PreClick)
	xrpPrivate:SetupAutomationFrame(frame.Automation)
	frame:Load(xrpSaved.selected)
	xrpPrivate.editor = frame
	return frame
end
