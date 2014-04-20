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

StaticPopupDialogs["XRPUI_EDITOR_ADD"] = {
	text = "Please enter a name for the new profile.",
	button1 = ACCEPT,
	button2 = CANCEL,
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
		xrpui.editor:Load(self.editBox:GetText())
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
--	sound = ,
}
StaticPopupDialogs["XRPUI_EDITOR_DELETE"] = {
	text = "Are you sure you want to remove this profile?",
	button1 = NO,
	button2 = YES,
	OnCancel = function(self, data, data2)
		xrp.profiles[xrpui.editor.Profiles:GetText()] = nil
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
	preferredIndex = 3,
--	sound = ,
}
StaticPopupDialogs["XRPUI_EDITOR_RENAME"] = {
	text = "Please enter a new name for the profile.",
	button1 = ACCEPT,
	button2 = CANCEL,
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
		local profile = xrpui.editor.Profiles:GetText()
		local text = self.editBox:GetText()
		xrp.profiles[profile](text)
		xrpui.editor:Load(text)
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
--	sound = ,
}
StaticPopupDialogs["XRPUI_EDITOR_COPY"] = {
	text = "Please enter a name for the copied profile.",
	button1 = ACCEPT,
	button2 = CANCEL,
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
		local profile = xrpui.editor.Profiles:GetText()
		local text = self.editBox:GetText()
		xrp.profiles[text](profile)
		xrpui.editor:Load(text)
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
--	sound = ,
}
StaticPopupDialogs["XRPUI_EDITOR_6000"] = {
	text = "Your combined profile length is above 6000 characters. This may slow loading for others.",
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
--	sound = ,
}
StaticPopupDialogs["XRPUI_EDITOR_12000"] = {
	text = "Your combined profile length is above 12000 characters. This may cause SERIOUS PROBLEMS with others reading it. It is strongly recommended that you reduce this.",
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
--	sound = ,
}
