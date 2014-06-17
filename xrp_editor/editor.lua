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
	local supportedfields = { NA = true, NI = true, NT = true, NH = true, AE = true, RA = true, AH = true, AW = true, CU = true, DE = true, AG = true, HH = true, HB = true, MO = true, HI = true, FR = true, FC = true }
	do
		local warn9000 = false
		function xrp.editor:Save()
			self:ClearFocus()
			-- This doesn't need to be smart. GetText() should be mapped to the
			-- appropriate 'real' function if GetText() isn't already right. The
			-- profile code will assume an empty string means an empty field.
			local name = self.Profiles:GetText()
			for field, _ in pairs(supportedfields) do
				if field == "FC" then
					local fc = self[field]:GetText()
					xrp.profiles[name][field] = fc ~= "0" and fc or nil
				else
					local text = self[field]:GetText()
					xrp.profiles[name][field] = text
				end
				xrp.defaults[name][field] = self.checkboxes[field]:GetChecked() and true or false
			end
			local length = xrp.profiles[name]("length", 9000)
			if length and length > 16000 then
				StaticPopup_Show("XRP_EDITOR_16000")
			elseif length and not warn9000 then
				warn9000 = true
				StaticPopup_Show("XRP_EDITOR_9000")
			end
			-- Save and Revert buttons will disable after saving.
			self:CheckFields()
		end
	end

	do
		local reverting = false
		function xrp.editor:Load(name)
			self:ClearFocus()
			-- This does not need to be very smart. SetText() should be mapped to the
			-- appropriate 'real' function if needed.
			local isdef = name == xrp.L["Default"]
			local profile = xrp.profiles[name]
			local defaults = xrp.defaults[name]
			for field, _ in pairs(supportedfields) do
				if field == "FC" then
					self[field]:SetText(tonumber(profile[field]) and profile[field] or "0")
				else
					self[field]:SetText(profile[field] or "")
					self[field]:SetCursorPosition(0)
				end
				self.checkboxes[field]:SetChecked(defaults[field])
				if isdef then
					self.checkboxes[field]:Disable()
				else
					self.checkboxes[field]:Enable()
				end
			end

			if self:IsVisible() and not self.Appearance:IsVisible() and not reverting then
				PanelTemplates_SetTab(self, 1)
				self.Biography:Hide()
				self.Appearance:Show()
				PlaySound("igCharacterInfoTab")
			end

			self.Profiles:SetText(name)
			self:CheckFields()
		end

		function xrp.editor:Revert()
			reverting = true
			self:Load(self.Profiles:GetText());
			reverting = false
		end
	end
	function xrp.editor:CheckFields()
		local changes = false
		local profile = xrp.profiles[self.Profiles:GetText()]
		local defaults = xrp.defaults[self.Profiles:GetText()]
		for field, _ in pairs(supportedfields) do
			if not changes and (self[field]:GetText() ~= (profile[field] or "") or (self.checkboxes[field]:GetChecked() and true or false) ~= defaults[field]) then
				changes = true
			end
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
	local appearance = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU" }
	for key, field in ipairs(appearance) do
		xrp.editor[field] = xrp.editor.Appearance[field]
		xrp.editor[field].nextEditBox = xrp.editor.Appearance[appearance[key + 1]] or xrp.editor.Appearance["DE"].EditBox
		xrp.editor.checkboxes[field] = xrp.editor.Appearance[field.."Default"]
	end
	-- EditBox is inside ScrollFrame
	xrp.editor["DE"] = xrp.editor.Appearance["DE"].EditBox
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
		xrp.editor.checkboxes[field] = xrp.editor.Biography[field.."Default"]
	end
	-- EditBox is inside ScrollFrame
	xrp.editor["HI"] = xrp.editor.Biography["HI"].EditBox
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
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
		end
	end

	UIDropDownMenu_Initialize(xrp.editor.Profiles, function()
		local info
		for _, value in ipairs(xrp.profiles()) do
			info = UIDropDownMenu_CreateInfo()
			info.text = value
			info.value = value
			if value == xrp.L["Default"] then
				info.colorCode = "|cffeecc00"
			end
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
	end)
end

do
	local function infofunc(self, arg1, arg2, checked)
		if not checked then
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			xrp.editor:CheckFields()
		end
	end

	UIDropDownMenu_Initialize(xrp.editor.FC, function()
		local info = UIDropDownMenu_CreateInfo()
		info.text = xrp.values.FC_EMPTY
		info.value = "0"
		info.func = infofunc
		UIDropDownMenu_AddButton(info)
		for value, text in ipairs(xrp.values.FC) do
			info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.value = tostring(value)
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
	end)
end

xrp:HookLoad(function()
	xrp.editor:Load(xrp.L["Default"])
end)
