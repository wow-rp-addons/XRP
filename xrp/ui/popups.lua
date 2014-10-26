--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

StaticPopupDialogs["XRP_CURRENTLY"] = {
	text = L["What are you currently doing?\n(This will reset ten minutes after logout.)"],
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
	text = L["Are you sure you wish to empty the profile cache?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		xrp:CacheTidy(60)
		StaticPopup_Show("XRP_NOTIFICATION", L["The cache has been cleared."])
	end,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
