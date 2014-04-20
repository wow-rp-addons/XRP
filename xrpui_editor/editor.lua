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

local xrpui_editor_warn6000 = false

local function xrpui_editor_clearfocus(self)
	self.NA:SetFocus()
	self.NA:ClearFocus()
	self.AG:SetFocus()
	self.AG:ClearFocus()
end

local xrpui_editor_saving = false
function xrpui.editor:Save()
	xrpui_editor_clearfocus(self)
	xrpui_editor_saving = true

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
		else
			xrp.profiles[name][field] = self[field]:GetText()
		end
	end

	xrpui_editor_saving = false

	local length = xrp.profiles[name](6000)
	if length and length > 12000 then
		StaticPopup_Show("XRPUI_EDITOR_12000")
	elseif length and not xrpui_editor_warn6000 then
		xrpui_editor_warn6000 = true
		StaticPopup_Show("XRPUI_EDITOR_6000")
	end
	-- TODO: Some sort of output to confirm the button did something?
end

function xrpui.editor:Load(name)
	xrpui_editor_clearfocus(self)
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed.
	for field, _ in pairs(supportedfields) do
		if field == "FC" then
			self[field]:SetText(tonumber(xrp.profiles[name][field]) and xrp.profiles[name][field] or "0")
		else
			self[field]:SetText(xrp.profiles[name][field] or "")
			self[field]:SetCursorPosition(0)
		end
	end

	if self:IsVisible() and not self.Appearance:IsVisible() then
		PanelTemplates_SetTab(self, 1)
		self.Biography:Hide()
		self.Appearance:Show()
		PlaySound("igCharacterInfoTab")
	end

	self.Profiles:SetText(name)
end

local function xrpui_editor_field_save(name, field)
	if not xrpui_editor_saving and xrpui.editor.Profiles:GetText() == name then
		if supportedfields[field] then
			if field == "FC" then
				xrpui.editor[field]:SetText(tonumber(xrp.profiles[name][field]) and xrp.profiles[name][field] or "0")
			else
				xrpui.editor[field]:SetText(xrp.profiles[name][field])
				xrpui.editor[field]:SetCursorPosition(0)
			end
		end
	end
end

local function xrpui_editor_OnEvent(self, event, addon)
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

		xrp:HookEvent("PROFILE_FIELD_SAVE", xrpui_editor_field_save)

		self:Load("Default")
		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrpui.editor:SetScript("OnEvent", xrpui_editor_OnEvent)
xrpui.editor:RegisterEvent("ADDON_LOADED")

-- Setup shorthand access.
-- Appearance tab
local xrpui_editor_appearance = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU" }
for key, field in pairs(xrpui_editor_appearance) do
	xrpui.editor[field] = xrpui.editor.Appearance[field]
	xrpui.editor[field].nextEditBox = xrpui.editor.Appearance[xrpui_editor_appearance[key + 1]] or xrpui.editor.Appearance["DE"].EditBox
end
-- EditBox is inside ScrollFrame
xrpui.editor["DE"] = xrpui.editor.Appearance["DE"].EditBox
xrpui.editor["DE"].nextEditBox = xrpui.editor.Appearance["NA"]

-- Biography tab
local xrpui_editor_biography = { "AG", "HH", "HB", "MO", "FR", "FC" }
for key, field in pairs(xrpui_editor_biography) do
	xrpui.editor[field] = xrpui.editor.Biography[field]
	if field == "MO" then
		xrpui.editor[field].nextEditBox = xrpui.editor.Biography["HI"].EditBox
	elseif field == "FR" then
		xrpui.editor[field].nextEditBox = xrpui.editor.Biography["AG"]
	elseif field ~= "FC" then
		xrpui.editor[field].nextEditBox = xrpui.editor.Biography[xrpui_editor_biography[key + 1]]
	end
end
-- EditBox is inside ScrollFrame
xrpui.editor["HI"] = xrpui.editor.Biography["HI"].EditBox
xrpui.editor["HI"].nextEditBox = xrpui.editor.Biography["FR"]
