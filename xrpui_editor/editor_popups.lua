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
		local text = self.editBox:GetText()
		local var = xrp.profiles[text]
		xrpui.editor:Load(text)
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
--	sound = ,
}
StaticPopupDialogs["XRPUI_EDITOR_DELETE"] = {
	text = "Are you sure you want to remove this profile?",
	button1 = NO,
	button2 = YES,
--	OnShow = function(self, data)
--		self.text = "Are you sure you want to remove \""..xrpui.editor.Profiles:GetText().."\"?"
--	end,
	OnCancel = function(self, data, data2)
		xrp.profiles[xrpui.editor.Profiles:GetText()] = nil
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
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
		local text = self.editBox:GetText()
		xrp.profiles[xrpui.editor.Profiles:GetText()](text)
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
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
		local text = self.editBox:GetText()
		xrp.profiles[text](xrpui.editor.Profiles:GetText())
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
--	sound = ,
}
