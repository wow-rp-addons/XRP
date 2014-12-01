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

local addonName, xrpPrivate = ...

StaticPopupDialogs["XRP_NOTIFICATION"] = {
	text = "%s",
	button1 = OKAY,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_ERROR"] = {
	text = "%s",
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_URL"] = {
	text = (IsWindowsClient() or IsLinuxClient()) and "Copy the URL (Ctrl+C) and paste into your web browser." or IsMacClient() and "Copy the URL (Cmd+C) and paste into your web browser." or "Copy the URL and paste into your web browser.",
	button1 = DONE,
	hasEditBox = true,
	OnShow = function (self, url)
		self.editBox:SetWidth(self.editBox:GetWidth() + 100)
		self.editBox:SetText(url or "")
		self.editBox:SetFocus()
		self.editBox:HighlightText()
	end,
	EditBoxOnTextChanged = function(self, url)
		self:SetText(url or "")
		self:HighlightText()
	end,
	EditBoxOnEnterPressed = function(self)
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

StaticPopupDialogs["XRP_RELOAD"] = {
	text = "%s",
	button1 = "Reload UI",
	button2 = "Not now",
	showAlert = true,
	OnAccept = ReloadUI,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_CURRENTLY"] = {
	text = "What are you currently doing?\n(This will reset ten minutes after logout.)",
	button1 = ACCEPT,
	button2 = RESET,
	button3 = CANCEL,
	hasEditBox = true,
	OnShow = function(self, data)
		self.editBox:SetWidth(self.editBox:GetWidth() + 150)
		self.editBox:SetText(xrp.current.fields.CU or "")
		self.editBox:HighlightText()
		self.button1:Disable()
		if not xrp.current.overrides.CU then
			self.button2:Disable()
		end
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= (xrp.current.fields.CU or "") then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnAccept = function(self, data, data2)
		xrp.current.fields.CU = self.editBox:GetText()
	end,
	OnCancel = function(self, data, data2) -- Reset button.
		xrp.current.fields.CU = nil
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			xrp.current.fields.CU = self:GetText()
			parent:Hide()
		end
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

StaticPopupDialogs["XRP_CACHE_CLEAR"] = {
	text = "Are you sure you wish to fully clear the cache?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		xrpPrivate:CacheTidy(60)
		StaticPopup_Show("XRP_NOTIFICATION", "The cache has been cleared.")
	end,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_CACHE_TIDY"] = {
	text = "Old entries have been pruned from the cache.",
	button1 = OKAY,
	OnShow = function(self, data)
		xrpPrivate:CacheTidy()
	end,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_EDITOR_ADD"] = {
	text = "Enter a name for the new profile:",
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
			StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
		else
			xrpPrivate.editor:Load(name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			local name = self:GetText()
			if not xrp.profiles:Add(name) then
				StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
			else
				xrpPrivate.editor:Load(name)
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
	text = "Are you sure you want to remove \"%s\"?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data, data2)
		local name = xrpPrivate.editor.Profiles:GetText()
		if not xrp.profiles[name]:Delete() then
			StaticPopup_Show("XRP_ERROR", ("The profile\"%s\" is currently active. Active profiles cannot be removed."):format(name))
		else
			xrpPrivate.editor:Load(xrpSaved.selected)
		end
	end,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_EDITOR_RENAME"] = {
	text = "Enter a new name for \"%s\":",
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
		if not xrp.profiles[xrpPrivate.editor.Profiles:GetText()]:Rename(name) then
			StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
		else
			xrpPrivate.editor:Load(name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			local name = self:GetText()
			if not xrp.profiles[xrpPrivate.editor.Profiles:GetText()]:Rename(name) then
				StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
			else
				xrpPrivate.editor:Load(name)
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
	text = "Enter a name for the copy of \"%s\":",
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
		if not xrp.profiles[xrpPrivate.editor.Profiles:GetText()]:Copy(name) then
			StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
		else
			xrpPrivate.editor:Load(name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			local name = self:GetText()
			if not xrp.profiles[xrpPrivate.editor.Profiles:GetText()]:Copy(name) then
				StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
			else
				xrpPrivate.editor:Load(name)
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
