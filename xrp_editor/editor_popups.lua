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
		if xrp_profiles[name] then
			StaticPopup_Show("XRP_EDITOR_FAIL", name)
		else
			xrp.editor:Load(self.editBox:GetText())
		end
	end,
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
		xrp.profiles[xrp.editor.Profiles:GetText()] = nil
		xrp.editor:Load(L["Default"])
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
		if not xrp.profiles[xrp.editor.Profiles:GetText()]("rename", name) then
			StaticPopup_Show("XRP_EDITOR_FAIL", name)
		else
			xrp.editor:Load(name)
		end
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
		if not xrp.profiles[xrp.editor.Profiles:GetText()]("copy", name) then
			StaticPopup_Show("XRP_EDITOR_FAIL", name)
		else
			xrp.editor:Load(name)
		end
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["XRP_EDITOR_FAIL"] = {
	text = L["A profile named \"%s\" already exists (or something went wrong)."],
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["XRP_EDITOR_9000"] = {
	text = L["Your combined profile length is over 9000 characters. This may slow loading for others."],
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
StaticPopupDialogs["XRP_EDITOR_16000"] = {
	text = L["Your combined profile length is above 16000 characters. There is a chance of this causing serious problems with others loading it, and it will significantly increase load times for them."],
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
