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

local editor

local Save_OnClick, Load
do

	local function ClearAllFocus()
		local focused = GetCurrentKeyBoardFocus()
		if focused then
			focused:ClearFocus()
		end
	end

	function Save_OnClick(self)
		ClearAllFocus()

		local editor = self:GetParent()
		local name = editor.Profiles.contents
		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		for field, control in pairs(editor.fields) do
			profile[field] = control.inherited and "" or control.contents
			inherits[field] = control.Inherit:GetChecked()
		end
		local parent = editor.Parent.contents
		xrp.profiles[name].parent = parent
		if xrp.profiles[name].parent ~= parent then
			local value = xrp.profiles[name].parent
			editor.Parent.contents = value
			editor.Parent:SetFormattedText("Parent: %s",  value or "None")
		end

		editor:CheckFields()
	end

	function Load(self, name)
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
		self.Parent.contents = value
		self.Parent:SetFormattedText("Parent: %s", value or "None")

		self.TitleText:SetFormattedText("Profile Editor: %s", name)

		self:CheckFields()
	end
end

local CheckFields
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

	function CheckFields(self, field)
		local name, parent = self.Profiles.contents, self.Parent.contents
		if not xrp.profiles[name] then return end
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

local Profiles_PreClick, Parent_PreClick, FC_baseMenuList
do
	local function Checked(self)
		return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
	end

	do
		local function Profiles_Click(self, arg1, arg2, checked)
			if not checked then
				UIDROPDOWNMENU_OPEN_MENU:GetParent():Load(arg1)
			end
		end

		function Profiles_PreClick(self, button, down)
			local parent = self:GetParent()
			parent.baseMenuList = {}
			for index, profile in ipairs(xrp.profiles:List()) do
				parent.baseMenuList[index] = { text = profile, checked = Checked, arg1 = profile, func = Profiles_Click }
			end
		end
	end

	do
		local function Parent_Click(self, arg1, arg2, checked)
			if not checked then
				UIDROPDOWNMENU_OPEN_MENU.contents = arg1
				UIDROPDOWNMENU_OPEN_MENU:SetFormattedText("Parent: %s", arg1 or "None")
				UIDROPDOWNMENU_OPEN_MENU:GetParent():CheckFields()
			end
		end

		local none = { text = "None", checked = Checked, arg1 = nil, func = Parent_Click }

		function Parent_PreClick(self, button, down)
			self.baseMenuList = { none }
			local editingProfile = self:GetParent().Profiles.contents
			for index, profile in ipairs(xrp.profiles:List()) do
				if profile ~= editingProfile and not xrpPrivate:DoesParentLoop(editingProfile, profile) then
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
				UIDROPDOWNMENU_OPEN_MENU:GetParent():GetParent():CheckFields("FC")
			end
		end

		local FC = xrp.values.FC
		FC_baseMenuList = {}
		for i = 0, #FC, 1 do
			FC_baseMenuList[i + 1] = { text = FC[i], checked = Checked, arg1 = i == 0 and "" or tostring(i), func = FC_Click }
		end
	end
end

local function CreateEditor()
	local frame = CreateFrame("Frame", "XRPEditor", UIParent, "XRPEditorTemplate")
	frame.Load = Load
	frame.CheckFields = CheckFields
	frame.fields.FC.baseMenuList = FC_baseMenuList
	frame.Parent:SetScript("PreClick", Parent_PreClick)
	frame.Profiles.ArrowButton:SetScript("PreClick", Profiles_PreClick)
	frame.SaveButton:SetScript("OnClick", Save_OnClick)
	xrpPrivate:SetupAutomationFrame(frame.Automation)
	frame:Load(xrpSaved.selected)
	return frame
end

function xrp:Edit(profile)
	if not editor then
		editor = CreateEditor()
	end
	if not profile and editor:IsShown() then
		HideUIPanel(editor)
		return
	end
	ShowUIPanel(editor)
	if profile then
		editor:Load(profile)
	end
end
