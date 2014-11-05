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

local addonName, private = ...

private.editor = XRPEditor

function private.editor:Save()
	self:ClearFocus()
	-- This doesn't need to be smart. GetText() should be mapped to the
	-- appropriate 'real' function if GetText() isn't already right. The
	-- profile code will assume an empty string means an empty field.
	local name = self.Profiles:GetText()
	local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
	for field, control in pairs(self.fields) do
		profile[field] = control.inherited and "" or control:GetText()
		inherits[field] = self.checkboxes[field]:GetChecked()
	end
	local parent = self.Parent:GetText()
	if parent == "" then
		parent = nil
	end
	xrp.profiles[name].parent = parent
	if xrp.profiles[name].parent ~= parent then
		self.Parent:SetText(xrp.profiles[name].parent or "")
	end
	-- Save and Revert buttons will disable after saving.
	self:CheckFields()
end

function private.editor:Load(name)
	self:ClearFocus()
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed.
	local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
	for field, control in pairs(self.fields) do
		control:SetText(profile[field] or "")
		control:SetTextColor(1.0, 1.0, 1.0, 1.0)
		control:SetCursorPosition(0)
		control.inherited = false
		self.checkboxes[field]:SetChecked(inherits[field] ~= false)
	end

	if self.Profiles:GetText() ~= name and not self.Appearance:IsVisible() then
		PanelTemplates_SetTab(self, 1)
		self.Biography:Hide()
		self.Appearance:Show()
		PlaySound("igCharacterInfoTab")
	end

	self.Profiles:SetText(name)
	self.Parent:SetText(xrp.profiles[name].parent or "")
	self:CheckFields()
end

do
	local function CheckField(self, name, parent, profile, inherits, field, control)
		if parent then
			self.checkboxes[field]:Show()
			if not control:HasFocus() and (control:GetText() == "" or control.inherited) then
				if self.checkboxes[field]:GetChecked() then
					control.inherited = true
					control:SetTextColor(0.5, 0.5, 0.5, 1.0)
					local parentcontent = xrp.profiles[parent].fields[field]
					if parentcontent then
						control:SetText(parentcontent)
					else
						local parentinherit = xrp.profiles[parent].inherits[field]
						if type(parentinherit) == "string" and parentinherit ~= name then
							control:SetText(xrp.profiles[parentinherit].fields[field])
						elseif field == "NA" or field == "RA" or field == "RC" then
							local metafield = field == "RA" and "GR" or field == "RC" and "GC" or nil
							control:SetText(xrpSaved.meta.fields[field] or xrp.values[metafield][xrpSaved.meta.fields[metafield]] or "")
						else
							control:SetText("")
						end
					end
					control:SetCursorPosition(0)
				elseif field == "NA" or field == "RA" or field == "RC" then
					control.inherited = true
					control:SetTextColor(0.5, 0.5, 0.5, 1.0)
					local metafield = field == "RA" and "GR" or field == "RC" and "GC" or nil
					control:SetText(xrpSaved.meta.fields[field] or xrp.values[metafield][xrpSaved.meta.fields[metafield]] or "")
					control:SetCursorPosition(0)
				else
					control:SetText("")
					control:SetTextColor(1.0, 1.0, 1.0, 1.0)
					control.inherited = false
				end
			end
		else
			self.checkboxes[field]:Hide()
			if (field == "NA" or field == "RA" or field == "RC") and not control:HasFocus() and (control:GetText() == "" or control.inherited) then
				control.inherited = true
				control:SetTextColor(0.5, 0.5, 0.5, 1.0)
				local metafield = field == "RA" and "GR" or field == "RC" and "GC" or nil
				control:SetText(xrpSaved.meta.fields[field] or xrp.values[metafield][xrpSaved.meta.fields[metafield]] or "")
				control:SetCursorPosition(0)
			elseif control.inherited then
				control:SetText("")
				control:SetTextColor(1.0, 1.0, 1.0, 1.0)
				control.inherited = false
			end
		end
		return (control.inherited and profile[field] ~= nil) or (not control.inherited and control:GetText() ~= (profile[field] or "")) or (self.checkboxes[field]:GetChecked()) ~= (inherits[field] ~= false) or nil
	end

	local modified = {}
	function private.editor:CheckFields(field)
		local name, parent = self.Profiles:GetText(), self.Parent:GetText()
		if not xrp.profiles[name] then return end
		if parent == "" then
			parent = nil
		end
		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		if type(field) == "string" and self.fields[field] then
			modified[field] = CheckField(self, name, parent, profile, inherits, field, self.fields[field])
		else
			for field, control in pairs(self.fields) do
				modified[field] = CheckField(self, name, parent, profile, inherits, field, control)
			end
		end
		if parent ~= xrp.profiles[name].parent or next(modified) then
			self.SaveButton:Enable()
			self.RevertButton:Enable()
		else
			self.SaveButton:Disable()
			self.RevertButton:Disable()
		end
	end
end

function private.editor:ClearFocus()
	self.fields.NA:SetFocus()
	self.fields.NA:ClearFocus()
	self.fields.AG:SetFocus()
	self.fields.AG:ClearFocus()
end

do
	-- Setup shorthand access and other stuff.
	private.editor.fields, private.editor.checkboxes = {}, {}
	-- Appearance tab
	local appearance = { "NA", "NI", "AH", "NT", "NH", "AW", "AE", "RA", "RC", "CU" }
	for index, field in ipairs(appearance) do
		local control = private.editor.Appearance[field]
		private.editor.fields[field] = control
		control.fieldName = field
		control.nextEditBox = private.editor.Appearance[appearance[index + 1]] or private.editor.Appearance["DE"].EditBox
		private.editor.checkboxes[field] = private.editor.Appearance[field.."Default"]
	end
	do
		-- EditBox is inside ScrollFrame
		local control = private.editor.Appearance["DE"].EditBox
		private.editor.fields["DE"] = control
		control.fieldName = "DE"
		control.nextEditBox = private.editor.Appearance["NA"]
		private.editor.checkboxes["DE"] = private.editor.Appearance["DEDefault"]
	end

	-- Biography tab
	local biography = { "AG", "HH", "HB", "MO", "FR", "FC" }
	for index, field in ipairs(biography) do
		local control = private.editor.Biography[field]
		private.editor.fields[field] = control
		control.fieldName = field
		if field == "MO" then
			control.nextEditBox = private.editor.Biography["HI"].EditBox
		elseif field == "FR" then
			control.nextEditBox = private.editor.Biography["AG"]
		elseif field ~= "FC" then
			control.nextEditBox = private.editor.Biography[biography[index + 1]]
		end
		private.editor.checkboxes[field] = private.editor.Biography[field.."Default"]
	end
	do
		-- EditBox is inside ScrollFrame
		local control = private.editor.Biography["HI"].EditBox
		private.editor.fields["HI"] = control
		control.fieldName = "HI"
		control.nextEditBox = private.editor.Biography["FR"]
		private.editor.checkboxes["HI"] = private.editor.Biography["HIDefault"]
	end
end

-- Ugh, DropDownMenus. These are a royal pain in the ass to work with, but make
-- for a really nice-looking UI. In theory a menuList variable can be used
-- instead of these static functions but Blizzard's code somehow ends up wiping
-- that variable out, at least when there's multiple menus. Also be sure to
-- call UIDropDownMenu_Initialize(A.Menu, A.Menu.initialize) before setting
-- their values in code, or it does funny things.
do
	local function infofunc(self, arg1, arg2, checked)
		if not checked then
			private.editor:Load(self.value)
		end
	end

	function private.editor.Profiles:initialize(level, menuList)
		for _, value in ipairs(xrp.profiles:List()) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = value
			info.value = value
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
	end
end

do
	local function infofunc(self, arg1, arg2, checked)
		if not checked then
			private.editor.Parent:SetValue(arg1)
			private.editor:CheckFields()
		end
	end

	function private.editor.Parent.Menu:initialize(level, menuList)
		do
			local info = UIDropDownMenu_CreateInfo()
			info.text = xrp.L["None"]
			info.arg1 = ""
			info.value = ""
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
		local profile = private.editor.Profiles:GetText()
		for _, value in ipairs(xrp.profiles:List()) do
			if value ~= profile then
				local info = UIDropDownMenu_CreateInfo()
				info.text = value
				info.arg1 = value
				info.value = value
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end
	end
end

do
	local function infofunc(self, arg1, arg2, checked)
		if not checked or private.editor.fields.FC.inherited then
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			if private.editor.fields.FC.inherited then
				private.editor.FC.fields.inherited = false
				private.editor.fields.FC:SetTextColor(1.0, 1.0, 1.0, 1.0)
			end
			private.editor:CheckFields()
		end
	end

	local FC = xrp.values.FC
	function private.editor.fields.FC:initialize(level, menuList)
		for i = 0, #FC, 1 do
			local info = UIDropDownMenu_CreateInfo()
			info.text = FC[i]
			info.value = i == 0 and "" or tostring(i)
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
	end
end

xrp:HookLoad(function()
	private.editor:Load(xrpSaved.selected)
end)

function xrp:Edit(profile)
	if profile then
		private.editor:Load(profile)
	elseif private.editor:IsShown() then
		HideUIPanel(private.editor)
		return true
	end
	ShowUIPanel(private.editor)
	return true
end
