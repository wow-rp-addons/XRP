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

local addonName, xrpLocal = ...

function xrp:ExportPopup(title, text)
	if not title or not text then return end
	XRPExport.currentText = text
	XRPExport.Text.EditBox:SetText(text)
	XRPExport.Text.EditBox:SetCursorPosition(0)
	XRPExport.Text:SetVerticalScroll(0)
	XRPExport.HeaderText:SetFormattedText("Export: %s", title)
	ShowUIPanel(XRPExport)
end

local function ClickButton(self)
	self:GetParent().button1:Click()
end

local function ButtonToggle(self)
	if self:GetText() ~= "" then
		self:GetParent().button1:Enable()
	else
		self:GetParent().button1:Disable()
	end
end

local function DisableButton(self)
	self.button1:Disable()
end

StaticPopupDialogs["XRP_NOTIFICATION"] = {
	text = "%s",
	button1 = OKAY,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_ERROR"] = {
	text = "%s",
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_URL"] = {
	text = not IsMacClient() and "Copy the URL (Ctrl+C) and paste into your web browser." or "Copy the URL (Cmd+C) and paste into your web browser.",
	button1 = DONE,
	hasEditBox = true,
	editBoxWidth = 250,
	OnShow = function (self, url)
		self.editBox:SetText(url or "")
		self.editBox:HighlightText()
	end,
	EditBoxOnTextChanged = function(self, url)
		self:SetText(url or "")
		self:HighlightText()
	end,
	EditBoxOnEnterPressed = HideParentPanel,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_RELOAD"] = {
	text = "%s",
	button1 = RELOADUI,
	button2 = "Not now",
	showAlert = true,
	OnAccept = ReloadUI,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CURRENTLY"] = {
	text = "What are you currently doing?\n(This will reset ten minutes after logout; use the editor to set this more permanently.)",
	button1 = ACCEPT,
	button2 = RESET,
	button3 = CANCEL,
	hasEditBox = true,
	editBoxWidth = 350,
	OnShow = function(self)
		self.editBox:SetText(xrp.current.fields.CU or "")
		self.editBox:HighlightText()
		self.button1:Disable()
		if not xrp.current.overrides.CU then
			self.button2:Disable()
		end
	end,
	EditBoxOnTextChanged = function(self)
		if self:GetText() ~= (xrp.current.fields.CU or "") then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnAccept = function(self)
		xrp.current.fields.CU = self.editBox:GetText()
	end,
	OnCancel = function(self) -- Reset button.
		xrp.current.fields.CU = nil
	end,
	EditBoxOnEnterPressed = ClickButton,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CACHE_CLEAR"] = {
	text = "Are you sure you wish to fully clear the cache?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		xrpLocal:CacheTidy(60)
		StaticPopup_Show("XRP_NOTIFICATION", "The cache has been cleared.")
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CACHE_TIDY"] = {
	text = "Old entries have been pruned from the cache.",
	button1 = OKAY,
	OnShow = function(self)
		xrpLocal:CacheTidy()
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_ADD"] = {
	text = "Enter a name for the new profile:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self.editBox:GetText()
		if not xrp.profiles:Add(name) then
			StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
		else
			XRPEditor:Edit(name)
		end
	end,
	EditBoxOnEnterPressed = ClickButton,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_DELETE"] = {
	text = "Are you sure you want to remove \"%s\"?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		local name = XRPEditor.Profiles.contents
		if not xrp.profiles[name]:Delete() then
			StaticPopup_Show("XRP_ERROR", ("The profile \"%s\" is currently in-use directly or as a parent profile. In-use profiles cannot be removed."):format(name))
		else
			XRPEditor:Edit(tostring(xrp.profiles.SELECTED))
		end
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_RENAME"] = {
	text = "Enter a new name for \"%s\":",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self.editBox:GetText()
		if not xrp.profiles[XRPEditor.Profiles.contents]:Rename(name) then
			StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
		else
			XRPEditor:Edit(name)
		end
	end,
	EditBoxOnEnterPressed = ClickButton,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_COPY"] = {
	text = "Enter a name for the copy of \"%s\":",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self.editBox:GetText()
		if not xrp.profiles[XRPEditor.Profiles.contents]:Copy(name) then
			StaticPopup_Show("XRP_ERROR", ("The name \"%s\" is unavailable or already in use."):format(name))
		else
			XRPEditor:Edit(name)
		end
	end,
	EditBoxOnEnterPressed = ClickButton,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}
