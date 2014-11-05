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

local L = xrp.L

StaticPopupDialogs["XRP_EDITOR_ADD"] = {
	text = L["Enter a name for the new profile:"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = function(self, data)
		self.button1:Disable()
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= "" then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnAccept = function(self, data, data2)
		local name = self.editBox:GetText()
		if not xrp.profiles:Add(name) then
			StaticPopup_Show("XRP_ERROR", L["The name \"%s\" is unavailable or already in use."]:format(name))
		else
			private.editor:Load(name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			local name = self:GetText()
			if not xrp.profiles:Add(name) then
				StaticPopup_Show("XRP_ERROR", L["The name \"%s\" is unavailable or already in use."]:format(name))
			else
				private.editor:Load(name)
			end
		end
		parent:Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["XRP_EDITOR_DELETE"] = {
	text = L["Are you sure you want to remove \"%s\"?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data, data2)
		local name = private.editor.Profiles:GetText()
		if not xrp.profiles[name]:Delete() then
			StaticPopup_Show("XRP_ERROR", L["The profile\"%s\" is currently active. Active profiles cannot be removed."]:format(name))
		else
			private.editor:Load(xrpSaved.selected)
		end
	end,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["XRP_EDITOR_RENAME"] = {
	text = L["Enter a new name for \"%s\":"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = function(self, data)
		self.button1:Disable()
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= "" then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnAccept = function(self, data, data2)
		local name = self.editBox:GetText()
		if not xrp.profiles[private.editor.Profiles:GetText()]:Rename(name) then
			StaticPopup_Show("XRP_ERROR", L["The name \"%s\" is unavailable or already in use."]:format(name))
		else
			private.editor:Load(name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			local name = self:GetText()
			if not xrp.profiles[private.editor.Profiles:GetText()]:Rename(name) then
				StaticPopup_Show("XRP_ERROR", L["The name \"%s\" is unavailable or already in use."]:format(name))
			else
				private.editor:Load(name)
			end
		end
		parent:Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["XRP_EDITOR_COPY"] = {
	text = L["Enter a name for the copy of \"%s\":"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = function(self, data)
		self.button1:Disable()
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= "" then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnAccept = function(self, data, data2)
		local name = self.editBox:GetText()
		if not xrp.profiles[private.editor.Profiles:GetText()]:Copy(name) then
			StaticPopup_Show("XRP_ERROR", L["The name \"%s\" is unavailable or already in use."]:format(name))
		else
			private.editor:Load(name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			local name = self:GetText()
			if not xrp.profiles[private.editor.Profiles:GetText()]:Copy(name) then
				StaticPopup_Show("XRP_ERROR", L["The name \"%s\" is unavailable or already in use."]:format(name))
			else
				private.editor:Load(name)
			end
		end
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
