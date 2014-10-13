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

do
	local supported = { NA = true, NI = true, NT = true, NH = true, AE = true, RA = true, RC = true, AH = true, AW = true, CU = true, DE = true, AG = true, HH = true, HB = true, MO = true, HI = true, FR = true, FC = true }
	function xrp.editor:Save()
		self:ClearFocus()
		-- This doesn't need to be smart. GetText() should be mapped to the
		-- appropriate 'real' function if GetText() isn't already right. The
		-- profile code will assume an empty string means an empty field.
		local name = self.Profiles:GetText()
		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		for field, _ in pairs(supported) do
			profile[field] = self[field].inherited and "" or self[field]:GetText()
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

	function xrp.editor:Load(name)
		self:ClearFocus()
		-- This does not need to be very smart. SetText() should be mapped to
		-- the appropriate 'real' function if needed.
		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		for field, _ in pairs(supported) do
			self[field]:SetText(profile[field] or "")
			self[field]:SetTextColor(1.0, 1.0, 1.0, 1.0)
			self[field]:SetCursorPosition(0)
			self[field].inherited = false
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

	function xrp.editor:CheckFields()
		local name, parent = self.Profiles:GetText(), self.Parent:GetText()
		if not xrp.profiles[name] then return end
		if parent == "" then
			parent = nil
		end
		local profile, inherits = xrp.profiles[name].fields, xrp.profiles[name].inherits
		local changes = parent ~= xrp.profiles[name].parent
		for field, _ in pairs(supported) do
			if parent then
				self.checkboxes[field]:Show()
				if not self[field]:HasFocus() and (self[field]:GetText() == "" or self[field].inherited) then
					if self.checkboxes[field]:GetChecked() then
						self[field].inherited = true
						self[field]:SetTextColor(0.5, 0.5, 0.5, 1.0)
						local parentinherit = xrp.profiles[parent].inherits[field]
						self[field]:SetText(xrp.profiles[parent].fields[field] or (type(parentinherit) == "string" and xrp.profiles[parentinherit].fields[field]) or "")
						self[field]:SetCursorPosition(0)
					else
						self[field]:SetText("")
						self[field]:SetTextColor(1.0, 1.0, 1.0, 1.0)
						self[field].inherited = false
					end
				end
			else
				self.checkboxes[field]:Hide()
				if self[field].inherited then
					self[field]:SetText("")
					self[field]:SetTextColor(1.0, 1.0, 1.0, 1.0)
					self[field].inherited = false
				end
			end
			changes = changes or (self[field].inherited and profile[field] ~= nil) or (not self[field].inherited and self[field]:GetText() ~= (profile[field] or "")) or (self.checkboxes[field]:GetChecked()) ~= (inherits[field] ~= false)
		end
		if changes then
			self.SaveButton:Enable()
			self.RevertButton:Enable()
		else
			self.SaveButton:Disable()
			self.RevertButton:Disable()
		end
	end
end

function xrp.editor:ClearFocus()
	self.NA:SetFocus()
	self.NA:ClearFocus()
	self.AG:SetFocus()
	self.AG:ClearFocus()
end

do
	-- Setup shorthand access and other stuff.
	xrp.editor.checkboxes = {}
	-- Appearance tab
	local appearance = { "NA", "NI", "NT", "NH", "AE", "RA", "RC", "AH", "AW", "CU" }
	for key, field in ipairs(appearance) do
		xrp.editor[field] = xrp.editor.Appearance[field]
		xrp.editor[field].fieldName = field
		xrp.editor[field].nextEditBox = xrp.editor.Appearance[appearance[key + 1]] or xrp.editor.Appearance["DE"].EditBox
		xrp.editor.checkboxes[field] = xrp.editor.Appearance[field.."Default"]
	end
	-- EditBox is inside ScrollFrame
	xrp.editor["DE"] = xrp.editor.Appearance["DE"].EditBox
	xrp.editor["DE"].fieldName = "DE"
	xrp.editor["DE"].nextEditBox = xrp.editor.Appearance["NA"]
	xrp.editor.checkboxes["DE"] = xrp.editor.Appearance["DEDefault"]

	-- Biography tab
	local biography = { "AG", "HH", "HB", "MO", "FR", "FC" }
	for key, field in ipairs(biography) do
		xrp.editor[field] = xrp.editor.Biography[field]
		if field == "MO" then
			xrp.editor[field].nextEditBox = xrp.editor.Biography["HI"].EditBox
		elseif field == "FR" then
			xrp.editor[field].nextEditBox = xrp.editor.Biography["AG"]
		elseif field ~= "FC" then
			xrp.editor[field].nextEditBox = xrp.editor.Biography[biography[key + 1]]
		end
		xrp.editor[field].fieldName = field
		xrp.editor.checkboxes[field] = xrp.editor.Biography[field.."Default"]
	end
	-- EditBox is inside ScrollFrame
	xrp.editor["HI"] = xrp.editor.Biography["HI"].EditBox
	xrp.editor["HI"].fieldName = "HI"
	xrp.editor["HI"].nextEditBox = xrp.editor.Biography["FR"]
	xrp.editor.checkboxes["HI"] = xrp.editor.Biography["HIDefault"]
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
			xrp.editor:Load(self.value)
		end
	end

	UIDropDownMenu_Initialize(xrp.editor.Profiles, function()
		for _, value in ipairs(xrp.profiles:List()) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = value
			info.value = value
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
	end)
end

do
	local function infofunc(self, arg1, arg2, checked)
		if not checked then
			xrp.editor.Parent:SetValue(arg1)
			xrp.editor:CheckFields()
		end
	end

	UIDropDownMenu_Initialize(xrp.editor.Parent.Menu, function()
		do
			local info = UIDropDownMenu_CreateInfo()
			info.text = xrp.L["None"]
			info.arg1 = ""
			info.value = ""
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
		local profile = xrp.editor.Profiles:GetText()
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
	end)
end

do
	local function infofunc(self, arg1, arg2, checked)
		if not checked or xrp.editor.FC.inherited then
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			if xrp.editor.FC.inherited then
				xrp.editor.FC.inherited = false
				xrp.editor.FC:SetTextColor(1.0, 1.0, 1.0, 1.0)
			end
			xrp.editor:CheckFields()
		end
	end

	local FC = xrp.values.FC
	UIDropDownMenu_Initialize(xrp.editor.FC, function()
		for i = 0, #FC, 1 do
			local info = UIDropDownMenu_CreateInfo()
			info.text = FC[i]
			info.value = i == 0 and "" or tostring(i)
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
	end)
end

xrp:HookLoad(function()
	xrp.editor:Load(xrpSaved.selected)
end)
