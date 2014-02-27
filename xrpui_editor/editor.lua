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

function XRP.Editor:Init(addon, ...)
	XRP_EDITOR_SAVE = "Save"
	XRP_EDITOR_SAVEUSE = "Save and Use"
	XRP_EDITOR = GetAddOnMetadata(addon, "Title")
	XRP_EDITOR_VERSION = GetAddOnMetadata(addon, "Version")
	self:SetAttribute("UIPanelLayout-defined", true)
	self:SetAttribute("UIPanelLayout-enabled", true)
	self:SetAttribute("UIPanelLayout-area", "left")
	self:SetAttribute("UIPanelLayout-pushable", 4)
	self:SetAttribute("UIPanelLayout-whileDead", true)
	PanelTemplates_SetNumTabs(self, 2)
	PanelTemplates_SetTab(self, 1)
	self:SetScript("OnShow", function()
		SetPortraitTexture(self.portrait, "player")
		self:SetScript("OnShow", nil)
	end)
	self.TitleText:SetText(XRP_EDITOR.." ("..XRP_EDITOR_VERSION..")")
	StaticPopupDialogs["XRP_EDITOR_ADD"] = {
		text = "Please enter a name for the new profile.",
		button1 = "Accept",
		button2 = "Cancel",
		hasEditBox = true,
		OnShow = function(self, data)
			self.button1:Disable()
		end,
		EditBoxOnTextChanged = function(self, data)
			if self:GetText() ~= "" then
				self:GetParent().button1:Enable()
			end
		end,
		OnAccept = function(self, data, data2)
			local text = self.editBox:GetText()
			if XRP.Profiles:Add(text) then
				XRP.Editor:Load(XRP.Profiles:Get(text), text)
			else
				XRP:Console("Profile already exists, loading it in the editor.")
				XRP.Editor:Load(XRP.Profiles:Get(text), text)
			end
		end,
		enterClicksFirstButton = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
--		sound = ,
	}
	StaticPopupDialogs["XRP_EDITOR_DELETE"] = {
		text = "Are you sure you want to remove this profile?",
		button1 = "No",
		button2 = "Yes",
		OnShow = function(self, data)
			self.text = "Are you sure you want to remove \""..XRP.Editor.Profiles:GetText().."\"?"
		end,
		OnCancel = function(self, data, data2)
			if XRP.Profiles:Delete(XRP.Editor.Profiles:GetText()) then
				XRP:Console("Profile deleted successfully.")
			else
				XRP:Console("Profile does not exist. (This shouldn't happen!)")
			end
		end,
		enterClicksFirstButton = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false,
--		sound = ,
	}
	UIDropDownMenu_Initialize(self.Profiles, self.Profiles.initialize)
	UIDropDownMenu_Initialize(self.FR, self.FR.initialize)
	UIDropDownMenu_Initialize(self.FC, self.FC.initialize)
	XRP.Profiles:HookSet(self.SetHook)
	XRP.Profiles:HookDelete(self.DeleteHook)
end

-- Setup shorthand access for easier looping later.
-- Appearance tab
for _, key in pairs({"NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU"}) do
	XRP.Editor[key] = XRP.Editor.Appearance[key]
end
-- EditBox is inside ScrollFrame
XRP.Editor["DE"] = XRP.Editor.Appearance["DE"].EditBox

-- Biography tab
for _, key in pairs({"AG", "HH", "HB", "MO",  "FR", "FC"}) do
	XRP.Editor[key] = XRP.Editor.Biography[key]
end
-- EditBox is inside ScrollFrame
XRP.Editor["HI"] = XRP.Editor.Biography["HI"].EditBox

XRP.Editor.CurrentProfile = ""

function XRP.Editor:Save()
	-- This is a quick way to clear input focus.
	XRP.Editor.NA:SetFocus()
	XRP.Editor.NA:ClearFocus()
	local name = XRP.Editor.Profiles:GetText()
	local profile = {}

	-- This doesn't need to be smart. GetText() should be mapped to the
	-- appropriate 'real' function if GetText() isn't already right. Further,
	-- the logic behind saving a value vs. nil is contained in the Profiles
	-- modules. No need to duplicate it.
	for key in pairs(XRP.Fields.Codes) do
		profile[key] = XRP.Editor[key]:GetText()
	end

	if not XRP.Profiles:Save(profile, name) then
		XRP:Console("No changes to save for "..name..".")
	else
		XRP:Console("Changes were saved to "..name..".")
	end
end

function XRP.Editor:Load(profile, name)
	-- This is a quick way to clear input focus.
	XRP.Editor.NA:SetFocus()
	XRP.Editor.NA:ClearFocus()
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed. The Profiles module always
	-- fills the entire profile with values, even if they're empty, so we do
	-- not need to empty anything first.
	for key, value in pairs(profile) do
		XRP.Editor[key]:SetText(value)
		if key ~= "FR" and key ~= "FC" then
			XRP.Editor[key]:SetCursorPosition(0)
		end
	end

	XRP.Editor.Profiles:SetText(name)
end

function XRP.Editor:DeleteHook(name, selected)
	if not selected and XRP.Editor.Profiles:GetText() == name then
		XRP.Editor:Load(XRP.Profiles:Get("Default"), "Default")
	end
end

function XRP.Editor:SetHook(profile, name, oldname)
--	if name == oldname or name == XRP.Editor.CurrentProfile then
--		return
--	else
		XRP.Editor:Load(profile, name)
--	end
end

function XRP.Editor.Profiles:initialize(value)
	local info
	for _, value in pairs(XRP.Profiles:List()) do
		info = UIDropDownMenu_CreateInfo()
		info.text = value
		info.value = value
		info.func = function(self, arg1, arg2, checked)
			if not checked then
				XRP.Editor:Load(XRP.Profiles:Get(self.value), self.value)
				UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			end
		end
		UIDropDownMenu_AddButton(info)
	end
end

function XRP.Editor.Profiles:SetText(value)
	UIDropDownMenu_Initialize(self, self.initialize)
	UIDropDownMenu_SetSelectedValue(self, value)
end

function XRP.Editor.Profiles:GetText(value)
	return UIDropDownMenu_GetSelectedValue(self)
end

function XRP.Editor.FR:initialize(value)
	local info
	for value, text in pairs(XRP.Fields.Values.FR) do
		info = UIDropDownMenu_CreateInfo()
		info.text = text
		info.value = tostring(value - 1)
		info.func = function(self, arg1, arg2, checked)
			if not checked then
				UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			end
		end
		UIDropDownMenu_AddButton(info)
	end
end

function XRP.Editor.FR:SetText(value)
	UIDropDownMenu_Initialize(self, self.initialize)
	UIDropDownMenu_SetSelectedValue(self, value)
end

function XRP.Editor.FR:GetText(value)
	return UIDropDownMenu_GetSelectedValue(self)
end

function XRP.Editor.FC:initialize(value)
	local info
	for value, text in pairs(XRP.Fields.Values.FC) do
		info = UIDropDownMenu_CreateInfo()
		info.text = text
		info.value = tostring(value - 1)
		info.func = function(self, arg1, arg2, checked)
			if not checked then
				UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
			end
		end
		UIDropDownMenu_AddButton(info)
	end
end

function XRP.Editor.FC:SetText(value)
	UIDropDownMenu_Initialize(self, self.initialize)
	UIDropDownMenu_SetSelectedValue(self, value)
end

function XRP.Editor.FC:GetText(value)
	return UIDropDownMenu_GetSelectedValue(self)
end
