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

local function clearfocus(self)
	self.NA:SetFocus()
	self.NA:ClearFocus()
	self.AG:SetFocus()
	self.AG:ClearFocus()
end

function xrpui.editor:Save()
	clearfocus(self)
	self.Saving = true

	-- This doesn't need to be smart. GetText() should be mapped to the
	-- appropriate 'real' function if GetText() isn't already right. Further,
	-- the Storage module expects empty strings (which is what GetText() gets
	-- when the field is empty) for actually empty fields. If it's nil, it's
	-- assumed that the field should be left alone, rather than emptied.
	local name = self.Profiles:GetText()
	for field, _ in pairs(supportedfields) do
		xrp.profiles[name][field] = self[field]:GetText()
	end

	self.Saving = false

	-- TODO: Some sort of output?
end

function xrpui.editor:Load(name)
	clearfocus(self)
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

	--TODO: Swap to first tab

	self.Profiles:SetText(name)
end

local function xrpui_editor_field_save(name, field)
	if xrpui.editor.Saving then
		return
	end
	if xrpui.editor.Profiles:GetText() == name then
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
		XRPUI_EDITOR_VERSION = GetAddOnMetadata(addon, "Title").."/"..GetAddOnMetadata(addon, "Version")
		-- Initializing the frame into a proper, tabbed UI panel.
		self:SetAttribute("UIPanelLayout-defined", true)
		self:SetAttribute("UIPanelLayout-enabled", true)
		self:SetAttribute("UIPanelLayout-area", "left")
		self:SetAttribute("UIPanelLayout-pushable", 2)
		self:SetAttribute("UIPanelLayout-whileDead", true)
		PanelTemplates_SetNumTabs(self, 2)
		PanelTemplates_SetTab(self, 1)
		self.TitleText:SetText(XRPUI_EDITOR_VERSION)

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

-- Setup shorthand access for easier looping later.
-- Appearance tab
for _, field in pairs({ "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU" }) do
	xrpui.editor[field] = xrpui.editor.Appearance[field]
end
-- EditBox is inside ScrollFrame
xrpui.editor["DE"] = xrpui.editor.Appearance["DE"].EditBox

-- Biography tab
for _, field in pairs({ "AG", "HH", "HB", "MO", "FR", "FC" }) do
	xrpui.editor[field] = xrpui.editor.Biography[field]
end
-- EditBox is inside ScrollFrame
xrpui.editor["HI"] = xrpui.editor.Biography["HI"].EditBox
