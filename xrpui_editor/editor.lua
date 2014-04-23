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

local supportedfields = { NA = true, NI = true, NT = true, NH = true, AE = true, RA = true, AH = true, AW = true, CU = true, DE = true, AG = true, HH = true, HB = true, MO = true, HI = true, FR = true, FC = true }

local last_profile = {}
local last_defaults = {}

local warn9000 = false

local saving = false
local loading = false
local reverting = false

local function clearfocus(self)
	self.NA:SetFocus()
	self.NA:ClearFocus()
	self.AG:SetFocus()
	self.AG:ClearFocus()
end

function xrpui.editor:Save()
	clearfocus(self)
	saving = true

	-- This doesn't need to be smart. GetText() should be mapped to the
	-- appropriate 'real' function if GetText() isn't already right. Further,
	-- the Storage module expects empty strings (which is what GetText() gets
	-- when the field is empty) for actually empty fields. If it's nil, it's
	-- assumed that the field should be left alone, rather than emptied.
	local name = self.Profiles:GetText()
	for field, _ in pairs(supportedfields) do
		if field == "FC" then -- TODO: Move into xrp/profiles.lua?
			local fc = self[field]:GetText()
			xrp.profiles[name][field] = fc ~= "0" and fc or nil
			last_profile[field] = fc
		else
			local text = self[field]:GetText()
			xrp.profiles[name][field] = text
			last_profile[field] = text
		end
		xrp.defaults[name][field] = self.checkboxes[field]:GetChecked() and true or false
		last_defaults[field] = xrp.defaults[name][field]
	end

	saving = false

	local length = xrp.profiles[name](9000)
	if length and length > 16000 then
		StaticPopup_Show("XRPUI_EDITOR_16000")
	elseif length and not warn9000 then
		warn9000 = true
		StaticPopup_Show("XRPUI_EDITOR_9000")
	end

	-- Save and Revert buttons will disable after saving.
	xrpui.editor:CheckFields()
end

function xrpui.editor:Load(name)
	loading = true
	clearfocus(self)
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed.
	local isdef = name == "Default"
	local profile = xrp.profiles[name]
	for field, _ in pairs(supportedfields) do
		if field == "FC" then
			self[field]:SetText(tonumber(profile[field]) and profile[field] or "0")
			last_profile[field] = (profile[field] or "0")
		else
			self[field]:SetText(profile[field] or "")
			self[field]:SetCursorPosition(0)
			last_profile[field] = (profile[field] or "")
		end
		last_defaults[field] = xrp.defaults[name][field]
		self.checkboxes[field]:SetChecked(last_defaults[field])
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
	loading = false
end

function xrpui.editor:Revert()
	reverting = true
	self:Load(self.Profiles:GetText());
	reverting = false
end

function xrpui.editor:CheckFields()
	if not loading then -- This will still trigger after loading.
		local changes = false
		for field, _ in pairs(supportedfields) do
			if not changes and (xrpui.editor[field]:GetText() ~= (last_profile[field] or "") or (xrpui.editor.checkboxes[field]:GetChecked() and true or false) ~= last_defaults[field]) then
				changes = true
			end
		end
		if changes then
			xrpui.editor.SaveButton:Enable()
			xrpui.editor.RevertButton:Enable()
		else
			xrpui.editor.SaveButton:Disable()
			xrpui.editor.RevertButton:Disable()
		end
	end
end

local function field_save(name, field)
	if not saving and xrpui.editor.Profiles:GetText() == name then
		if supportedfields[field] then
			if field == "FC" then
				xrpui.editor[field]:SetText(tonumber(xrp.profiles[name][field]) and xrp.profiles[name][field] or "0")
				last_profile[field] = (profile[field] or "0")
			else
				xrpui.editor[field]:SetText(xrp.profiles[name][field] or "")
				xrpui.editor[field]:SetCursorPosition(0)
				last_profile[field] = (profile[field] or "")
			end
		end
	end
end

local function editor_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrpui_editor" then
		
		-- Initializing the frame into a proper, tabbed UI panel.
		self:SetAttribute("UIPanelLayout-defined", true)
		self:SetAttribute("UIPanelLayout-enabled", true)
		self:SetAttribute("UIPanelLayout-area", "left")
		self:SetAttribute("UIPanelLayout-pushable", 2)
		self:SetAttribute("UIPanelLayout-whileDead", true)
		PanelTemplates_SetNumTabs(self, 2)
		PanelTemplates_SetTab(self, 1)
		self.TitleText:SetText(GetAddOnMetadata(addon, "Title"))

		-- Ugh, DropDownMenus. These are a royal pain in the ass to work with,
		-- but make for a really nice-looking UI. In theory a menuList variable
		-- can be used instead of these static functions but Blizzard's code
		-- somehow ends up wiping that variable out, at least when there's
		-- multiple menus. Also be sure to call
		-- UIDropDownMenu_Initialize(A.Menu, A.Menu.initialize) before setting
		-- their values in code, or it does funny things.
		UIDropDownMenu_Initialize(self.Profiles, function()
			local info
			for _, value in pairs(xrp.profiles()) do
				info = UIDropDownMenu_CreateInfo()
				info.text = value
				info.value = value
				info.func = function(self, arg1, arg2, checked)
					if not checked then
						xrpui.editor:Load(self.value)
						UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
					end
				end
				UIDropDownMenu_AddButton(info)
			end
		end)

		UIDropDownMenu_Initialize(self.FC, function()
			local info = UIDropDownMenu_CreateInfo()
			info.text = xrpui.values.FC_EMPTY
			info.value = "0"
			info.func = function(self, arg1, arg2, checked)
				if not checked then
					UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
					xrpui.editor:CheckFields()
				end
			end
			UIDropDownMenu_AddButton(info)
			for value, text in pairs(xrpui.values.FC) do
				info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = tostring(value)
				info.func = function(self, arg1, arg2, checked)
					if not checked then
						UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
						xrpui.editor:CheckFields()
					end
				end
				UIDropDownMenu_AddButton(info)
			end
		end)

		xrp:HookEvent("PROFILE_DELETE", function(name)
			if xrpui.editor.Profiles:GetText() == name then
				xrpui.editor:Load("Default")
			end
		end)

		xrp:HookEvent("PROFILE_RENAME", function(name, newname)
			if xrpui.editor.Profiles:GetText() == name then
				xrpui.editor:Load(newname)
			end
		end)

		xrp:HookEvent("PROFILE_FIELD_SAVE", field_save)

		self:Load("Default")
		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrpui.editor:SetScript("OnEvent", editor_OnEvent)
xrpui.editor:RegisterEvent("ADDON_LOADED")

-- Setup shorthand access and other stuff.
xrpui.editor.checkboxes = {}
-- Appearance tab
local appearance = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU" }
for key, field in pairs(appearance) do
	xrpui.editor[field] = xrpui.editor.Appearance[field]
	xrpui.editor[field].nextEditBox = xrpui.editor.Appearance[appearance[key + 1]] or xrpui.editor.Appearance["DE"].EditBox
	xrpui.editor[field]:SetScript("OnTextChanged", function(self)
		xrpui.editor:CheckFields()
	end)
	xrpui.editor.checkboxes[field] = xrpui.editor.Appearance[field.."Default"]
end
-- EditBox is inside ScrollFrame
xrpui.editor["DE"] = xrpui.editor.Appearance["DE"].EditBox
xrpui.editor["DE"].nextEditBox = xrpui.editor.Appearance["NA"]
xrpui.editor.checkboxes["DE"] = xrpui.editor.Appearance["DEDefault"]

-- Biography tab
local biography = { "AG", "HH", "HB", "MO", "FR", "FC" }
for key, field in pairs(biography) do
	xrpui.editor[field] = xrpui.editor.Biography[field]
	if field == "MO" then
		xrpui.editor[field].nextEditBox = xrpui.editor.Biography["HI"].EditBox
	elseif field == "FR" then
		xrpui.editor[field].nextEditBox = xrpui.editor.Biography["AG"]
	elseif field ~= "FC" then
		xrpui.editor[field].nextEditBox = xrpui.editor.Biography[biography[key + 1]]
	end
	if field ~= "FC" then
		xrpui.editor[field]:SetScript("OnTextChanged", function(self)
			xrpui.editor:CheckFields()
		end)
	end
	xrpui.editor.checkboxes[field] = xrpui.editor.Biography[field.."Default"]
end
-- EditBox is inside ScrollFrame
xrpui.editor["HI"] = xrpui.editor.Biography["HI"].EditBox
xrpui.editor["HI"].nextEditBox = xrpui.editor.Biography["FR"]
xrpui.editor.checkboxes["HI"] = xrpui.editor.Biography["HIDefault"]
