--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local function ClickButton(self)
	self:GetParent():GetButton1():Click()
end

local function ButtonToggle(self)
	if self:GetText() ~= "" then
		self:GetParent():GetButton1():Enable()
	else
		self:GetParent():GetButton1():Disable()
	end
end

local function DisableButton(self)
	self:GetButton1():Disable()
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
	text = L"Copy the URL (%s) and paste into your web browser.":format(not IsMacClient() and "Ctrl+C" or "Cmd+C"),
	button1 = DONE,
	hasEditBox = true,
	editBoxWidth = 250,
	OnShow = function(self, url)
		self:GetEditBox():SetText(url or "")
		self:GetEditBox():HighlightText()
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
	OnAccept = C_UI.Reload,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_REPORT"] = {
	text = L"|cffdd380fYou must submit a ticket to Blizzard to report a profile.|r\n\nYou should copy the information from the text box below (%s) to add to your ticket.":format(not IsMacClient() and "Ctrl+C" or "Cmd+C"),
	button1 = OKAY,
	hasEditBox = true,
	editBoxWidth = 250,
	OnShow = function(self, info)
		self:GetEditBox():SetText(info or "")
		self:GetEditBox():HighlightText()
		self:GetEditBox():SetCursorPosition(0)
	end,
	EditBoxOnTextChanged = function(self, info)
		self:SetText(info or "")
		self:HighlightText()
		self:SetCursorPosition(0)
	end,
	EditBoxOnEnterPressed = HideParentPanel,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CURRENTLY"] = {
	text = L"What are you currently doing?\n(This will reset fifteen minutes after logout; use the editor to set this more permanently.)",
	button1 = ACCEPT,
	button2 = RESET,
	button3 = CANCEL,
	hasEditBox = true,
	editBoxWidth = 350,
	OnShow = function(self)
		local CU = AddOn_XRP.Characters.byUnit.player.CU
		self:GetEditBox():SetText(CU or "")
		self:GetEditBox():HighlightText()
		self:GetButton1():Disable()
		if CU == AddOn_XRP.Profiles.SELECTED.Full.CU then
			self:GetButton2():Disable()
		end
	end,
	EditBoxOnTextChanged = function(self)
		if self:GetText() ~= (AddOn_XRP.Characters.byUnit.player.CU or "") then
			self:GetParent():GetButton1():Enable()
		else
			self:GetParent():GetButton1():Disable()
		end
	end,
	OnAccept = function(self)
		AddOn_XRP.SetField("CU", self:GetEditBox():GetText())
	end,
	OnCancel = function(self) -- Reset button.
		AddOn_XRP.SetField("CU", nil)
	end,
	EditBoxOnEnterPressed = ClickButton,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CACHE_SINGLE"] = {
	text = L"It is typically unnecessary to indiviudally drop cached profiles.\n\nAre you sure you wish to drop %s from the cache anyway?",
	button1 = YES,
	button2 = NO,
	showAlert = true,
	OnAccept = function(self, character)
		character:DropCache()
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_FORCE_REFRESH"] = {
	text = L"Force refreshing is rarely necessary and should be done sparingly.\n\nDo you wish to forcibly refresh all fields for %s as soon as possible anyway?",
	button1 = YES,
	button2 = NO,
	showAlert = true,
	OnAccept = function(self, character)
		character:ForceRefresh()
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CACHE_CLEAR"] = {
	text = L"Are you sure you wish to fully clear the cache?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		AddOn.CacheTidy(60)
		StaticPopup_Show("XRP_NOTIFICATION", L"The cache has been cleared.")
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_CACHE_TIDY"] = {
	text = L"Old entries have been pruned from the cache.",
	button1 = OKAY,
	OnShow = function(self)
		AddOn.CacheTidy()
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_UNSAVED"] = {
	text = L"You have unsaved changes to \"%s\". Discard them?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, profile)
		XRPEditor:Edit(profile)
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_ADD"] = {
	text = L"Enter a name for the new profile:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self:GetEditBox():GetText()
		if AddOn_XRP.Profiles[name] then
			StaticPopup_Show("XRP_ERROR", L"The profile \"%s\" already exists.":format(name))
		else
			AddOn_XRP.AddProfile(name)
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
	text = L"Are you sure you want to remove \"%s\"?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		local name = XRPEditor.Profiles.contents
		local profile = AddOn_XRP.Profiles[name]
		if profile:IsInUse() then
			StaticPopup_Show("XRP_ERROR", L"The profile \"%s\" is currently in-use directly or as a parent profile. In-use profiles cannot be removed.":format(name))
		else
			profile:Delete()
			XRPEditor:Edit(AddOn_XRP.Profiles.SELECTED.name)
		end
	end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["XRP_EDITOR_RENAME"] = {
	text = L"Enter a new name for \"%s\":",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self:GetEditBox():GetText()
		if AddOn_XRP.Profiles[name] then
			StaticPopup_Show("XRP_ERROR", L"The profile \"%s\" already exists.":format(name))
		else
			AddOn_XRP.Profiles[XRPEditor.Profiles.contents]:Rename(name)
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
	text = L"Enter a name for the copy of \"%s\":",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	OnShow = DisableButton,
	EditBoxOnTextChanged = ButtonToggle,
	OnAccept = function(self)
		local name = self:GetEditBox():GetText()
		if AddOn_XRP.Profiles[name] then
			StaticPopup_Show("XRP_ERROR", L"The profile \"%s\" already exists.":format(name))
		else
			AddOn_XRP.Profiles[XRPEditor.Profiles.contents]:Copy(name)
			XRPEditor:Edit(name)
		end
	end,
	EditBoxOnEnterPressed = ClickButton,
	EditBoxOnEscapePressed = HideParentPanel,
	enterClicksFirstButton = true,
	whileDead = true,
	hideOnEscape = true,
}
