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

local addonName, _xrp = ...

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
	text = _xrp.L.POPUP_URL:format(not IsMacClient() and "Ctrl+C" or "Cmd+C"),
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
	button2 = CANCEL,
	showAlert = true,
	OnAccept = ReloadUI,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CURRENTLY"] = {
	text = _xrp.L.POPUP_CURRENTLY,
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
	text = _xrp.L.POPUP_ASK_CACHE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		_xrp.CacheTidy(60)
		StaticPopup_Show("XRP_NOTIFICATION", _xrp.L.POPUP_CLEAR_CACHE)
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CACHE_TIDY"] = {
	text = _xrp.L.POPUP_TIDY_CACHE,
	button1 = OKAY,
	OnShow = function(self)
		_xrp.CacheTidy()
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_ADD"] = {
	text = _xrp.L.POPUP_EDITOR_ADD,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self.editBox:GetText()
		if not xrp.profiles:Add(name) then
			StaticPopup_Show("XRP_ERROR", _xrp.L.POPUP_EDITOR_UNAVAILABLE:format(name))
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
	text = _xrp.L.POPUP_EDITOR_DELETE,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		local name = XRPEditor.Profiles.contents
		if not xrp.profiles[name]:Delete() then
			StaticPopup_Show("XRP_ERROR", _xrp.L.POPUP_EDITOR_INUSE:format(name))
		else
			XRPEditor:Edit(tostring(xrp.profiles.SELECTED))
		end
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_RENAME"] = {
	text = _xrp.L.POPUP_EDITOR_RENAME,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self.editBox:GetText()
		if not xrp.profiles[XRPEditor.Profiles.contents]:Rename(name) then
			StaticPopup_Show("XRP_ERROR", _xrp.L.POPUP_EDITOR_UNAVAILABLE:format(name))
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
	text = _xrp.L.POPUP_EDITOR_COPY,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self.editBox:GetText()
		if not xrp.profiles[XRPEditor.Profiles.contents]:Copy(name) then
			StaticPopup_Show("XRP_ERROR", _xrp.L.POPUP_EDITOR_UNAVAILABLE:format(name))
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
