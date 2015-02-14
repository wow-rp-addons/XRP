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

do
	local function ClearAllFocus()
		local focused = GetCurrentKeyBoardFocus()
		if focused then
			focused:ClearFocus()
		end
	end

	XRPEditor.SaveButton:SetScript("OnClick", function(self, button, down)
		ClearAllFocus()

		local name = XRPEditor.Profiles.contents
		local profile, inherits = xrpPrivate.profiles[name].fields, xrpPrivate.profiles[name].inherits
		for field, control in pairs(XRPEditor.fields) do
			profile[field] = not control.inherited and control.contents or nil
			inherits[field] = control.Inherit:GetChecked()
		end
		local parent = XRPEditor.Parent.contents
		xrpPrivate.profiles[name].parent = parent
		if xrpPrivate.profiles[name].parent ~= parent then
			local value = xrpPrivate.profiles[name].parent
			XRPEditor.Parent.contents = value
			XRPEditor.Parent:SetFormattedText("Parent: %s",  value or "None")
		end

		XRPEditor:CheckFields()
	end)

	function XRPEditor:Load(name)
		ClearAllFocus()

		local profile, inherits = xrpPrivate.profiles[name].fields, xrpPrivate.profiles[name].inherits
		for field, control in pairs(self.fields) do
			control:SetAttribute("inherited", false)
			control:SetAttribute("contents", profile[field])
			control.Inherit:SetChecked(inherits[field] ~= false)
		end

		if self.Profiles.contents ~= name and not self.panes[1]:IsVisible() then
			self.Tab1:Click()
		end

		self.Profiles.contents = name
		UIDropDownMenu_SetText(self.Profiles, name)

		local value = xrpPrivate.profiles[name].parent
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
				local parentcontent = xrpPrivate.profiles[parent].fields[field]
				if parentcontent then
					control:SetAttribute("contents", parentcontent)
				else
					local parentinherit = xrpPrivate.profiles[parent].inherits[field]
					if type(parentinherit) == "string" and parentinherit ~= name then
						control:SetAttribute("contents", xrpPrivate.profiles[parentinherit].fields[field])
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

	function XRPEditor:CheckFields(field)
		local name, parent = self.Profiles.contents, self.Parent.contents
		if not xrpPrivate.profiles[name] then return end
		local profile, inherits = xrpPrivate.profiles[name].fields, xrpPrivate.profiles[name].inherits
		if self.fields[field] then
			self.modified[field] = CheckField(self.fields[field], name, parent, profile, inherits, field)
		else
			for field, control in pairs(self.fields) do
				self.modified[field] = CheckField(control, name, parent, profile, inherits, field)
			end
		end
		if parent ~= xrpPrivate.profiles[name].parent or next(self.modified) then
			self.SaveButton:Enable()
			self.RevertButton:Enable()
		else
			self.SaveButton:Disable()
			self.RevertButton:Disable()
		end
	end
end

do
	local function Checked(self)
		return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
	end

	do
		local function Profiles_Click(self, arg1, arg2, checked)
			if not checked then
				XRPEditor:Load(arg1)
			end
		end

		XRPEditor.Profiles.ArrowButton:SetScript("PreClick", function(self, button, down)
			local parent = self:GetParent()
			parent.baseMenuList = {}
			for i, profile in ipairs(xrpPrivate.profiles:List()) do
				parent.baseMenuList[i] = { text = profile, checked = Checked, arg1 = profile, func = Profiles_Click }
			end
		end)
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
		XRPEditor.Parent:SetScript("PreClick", function(self, button, down)
			self.baseMenuList = { NONE }
			local editingProfile = XRPEditor.Profiles.contents
			for i, profile in ipairs(xrpPrivate.profiles:List()) do
				if profile ~= editingProfile and not xrpPrivate:DoesParentLoop(editingProfile, profile) then
					self.baseMenuList[#self.baseMenuList + 1] = { text = profile, checked = Checked, arg1 = profile, func = Parent_Click }
				end
			end
		end)
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
			local iString = tostring(i)
			baseMenuList[i + 1] = { text = FC[iString], checked = Checked, arg1 = i ~= 0 and iString or nil, func = FC_Click }
		end
		XRPEditor.fields.FC.baseMenuList = baseMenuList
	end
end

XRPEditor.ExportProfile:SetScript("OnClick", function(self, button, down)
	local profile = XRPEditor.Profiles.contents
	xrp:ExportPopup(profile, xrpPrivate.profiles[profile]:Export())
end)

XRPEditor.HelpButton:SetScript("PreClick", function(self, button, down)
	if XRPEditor.panes[1]:IsVisible() then
		if XRPEditor.Automation:IsVisible() then
			XRPEditor.helpPlates = xrpPrivate.Help.EditorAppearanceAuto
		else
			XRPEditor.helpPlates = xrpPrivate.Help.EditorAppearanceNoAuto
		end
	else
		if XRPEditor.Automation:IsVisible() then
			XRPEditor.helpPlates = xrpPrivate.Help.EditorBiographyAuto
		else
			XRPEditor.helpPlates = xrpPrivate.Help.EditorBiographyNoAuto
		end
	end
end)

function xrp:Edit(profile)
	if not profile and XRPEditor:IsShown() then
		HideUIPanel(XRPEditor)
		return
	end
	ShowUIPanel(XRPEditor)
	if profile then
		XRPEditor:Load(profile)
	end
end
