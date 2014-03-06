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

local function init()
	local self = XRP.Editor
	self:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == "XRP_Editor" then
			XRP_EDITOR_VERSION = GetAddOnMetadata(addon, "Title").."/"..GetAddOnMetadata(addon, "Version")
			-- Initializing the frame into a proper, tabbed UI panel.
			self:SetAttribute("UIPanelLayout-defined", true)
			self:SetAttribute("UIPanelLayout-enabled", true)
			self:SetAttribute("UIPanelLayout-area", "left")
			self:SetAttribute("UIPanelLayout-pushable", 2)
			self:SetAttribute("UIPanelLayout-whileDead", true)
			PanelTemplates_SetNumTabs(self, 2)
			PanelTemplates_SetTab(self, 1)
			self.TitleText:SetText(XRP_EDITOR_VERSION)

			self.SupportedFields = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU", "AG", "HH", "HB", "MO", "HI", "FR", "FC" }

			-- Ugh, DropDownMenus. These are a royal pain in the ass to work
			-- with, but make for a really nice-looking UI. In theory a
			-- menuList variable can be used instead of these static
			-- functions but Blizzard's code somehow ends up wiping that
			-- variable out, at least when there's multiple menus. Also be
			-- sure to call UIDropDownMenu_Initialize(A.Menu, A.Menu.initialize)
			-- before setting their values in code, or it does funny things.
			UIDropDownMenu_Initialize(self.Profiles, function()
				local info
				for _, value in pairs(XRP.Storage:List()) do
					info = UIDropDownMenu_CreateInfo()
					info.text = value
					info.value = value
					info.func = function(self, arg1, arg2, checked)
						if not checked then
							XRP.Editor:Load(XRP.Storage:Get(self.value), self.value)
							UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
						end
					end
					UIDropDownMenu_AddButton(info)
				end
			end)

			UIDropDownMenu_Initialize(self.FR, function()
				local info
				for value, text in pairs(XRP_VALUES.FR) do
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
			end)

			UIDropDownMenu_Initialize(self.FC, function()
				local info
				for value, text in pairs(XRP_VALUES.FC) do
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
			end)

			XRP.Storage:HookDelete(function(name)
				if XRP.Editor.Profiles:GetText() == name then
					XRP.Editor:Load(XRP.Storage:Get("Default"), "Default")
				end
			end)

			XRP.Storage:HookRename(function(name, newname)
				if XRP.Editor.Profiles:GetText() == Name then
					XRP.Editor:Load(XRP.Storage:Get(newname), newname)
				end
			end)

			self:UnregisterEvent("ADDON_LOADED")
			self:RegisterEvent("PLAYER_LOGIN")
		elseif event == "PLAYER_LOGIN" then
			self:Load(XRP.Storage:Get("Default"), "Default")
			self:UnregisterEvent("PLAYER_LOGIN")
		end
	end)
	self:RegisterEvent("ADDON_LOADED")
--	self:SetScript("OnShow", function(self)
		-- For some reason this won't always work OnLoad, and sometimes even
		-- unsets itself.
--		SetPortraitTexture(self.portrait, "player")
--	end)
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
			if XRP.Storage:Add(text) then
				XRP.Editor:Load(XRP.Storage:Get(text), text)
			else
				XRP:Console(4, "Editor", "Profile already exists, loading it in the editor.")
				XRP.Editor:Load(XRP.Storage:Get(text), text)
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
--		OnShow = function(self, data)
--			self.text = "Are you sure you want to remove \""..XRP.Editor.Profiles:GetText().."\"?"
--		end,
		OnCancel = function(self, data, data2)
			if XRP.Storage:Delete(XRP.Editor.Profiles:GetText()) then
				XRP:Console(6, "Editor", "Profile deleted successfully.")
			else
				XRP:Console(4, "Editor", "Profile does not exist.")
			end
		end,
		enterClicksFirstButton = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false,
--		sound = ,
	}
	StaticPopupDialogs["XRP_EDITOR_RENAME"] = {
		text = "Please enter a new name for the profile.",
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
			XRP.Storage:Rename(XRP.Editor.Profiles:GetText(), text)
		end,
		enterClicksFirstButton = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
--		sound = ,
	}

	-- Setup shorthand access for easier looping later.
	-- Appearance tab
	for _, field in pairs({"NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU"}) do
		XRP.Editor[field] = XRP.Editor.Appearance[field]
	end
	-- EditBox is inside ScrollFrame
	XRP.Editor["DE"] = XRP.Editor.Appearance["DE"].EditBox

	-- Biography tab
	for _, field in pairs({"AG", "HH", "HB", "MO",  "FR", "FC"}) do
		XRP.Editor[field] = XRP.Editor.Biography[field]
	end
	-- EditBox is inside ScrollFrame
	XRP.Editor["HI"] = XRP.Editor.Biography["HI"].EditBox
end

local function clearfocus(self)
	self.NA:SetFocus()
	self.NA:ClearFocus()
end

function XRP.Editor:Save()
	clearfocus(self)
	local name = self.Profiles:GetText()
	local profile = {}

	-- This doesn't need to be smart. GetText() should be mapped to the
	-- appropriate 'real' function if GetText() isn't already right. Further,
	-- the Storage module does compaction on its own.
	for _, field in pairs(self.SupportedFields) do
		profile[field] = self[field]:GetText()
	end

	if XRP.Storage:Save(profile, name) then
		XRP:Console(6, "Editor", "Changes were saved to "..name..".")
	else
		XRP:Console(6, "Editor", "No changes to save for "..name..".")
	end
end

function XRP.Editor:Load(profile, name)
	clearfocus(self)
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed.
	for _, field in pairs(self.SupportedFields) do
		if field == "FC" or field == "FR" then
			self[field]:SetText(profile[field] or "0")
		elseif field == "RA" then
			self[field]:SetText(profile[field] or XRP:LocalizeRace(XRP.Character.Fields.GR))
			self[field]:SetCursorPosition(0)
		else
			self[field]:SetText(profile[field] or "")
			self[field]:SetCursorPosition(0)
		end
	end

	self.Profiles:SetText(name)
end

init()
