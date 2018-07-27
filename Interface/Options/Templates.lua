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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

XRPOptionsControl_Mixin = {}

function XRPOptionsControl_Mixin:Get()
	local settingsTable = AddOn.Settings
	if self.xrpTable then
		settingsTable = AddOn.Settings[self.xrpTable]
	end
	return settingsTable[self.xrpSetting]
end

function XRPOptionsControl_Mixin:Set(value)
	local settingsTable = AddOn.Settings
	if self.xrpTable then
		settingsTable = AddOn.Settings[self.xrpTable]
	end
	settingsTable[self.xrpSetting] = value
	local settingsToggleTable = AddOn.SettingsToggles
	if self.xrpTable then
		settingsToggleTable = AddOn.SettingsToggles[self.xrpTable]
	end
	if settingsToggleTable and settingsToggleTable[self.xrpSetting] then
		xpcall(settingsToggleTable[self.xrpSetting], geterrorhandler(), value, self.xrpSetting)
	end
end

XRPOptions_Mixin = {}

function XRPOptions_Mixin:okay()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomOkay then
			xpcall(control.CustomOkay, geterrorhandler(), control)
		else
			control.oldValue = control.value
		end
	end
end

function XRPOptions_Mixin:refresh()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomRefresh then
			xpcall(control.CustomRefresh, geterrorhandler(), control)
		else
			local setting = control:Get()
			control.value = setting
			if control.oldValue == nil then
				control.oldValue = setting
			end
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(setting)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				for i, entry in ipairs(control.baseMenuList) do
					if entry.arg1 == control.value then
						control.Text:SetText(entry.text)
						break
					end
				end
			end
		end
		if control.dependsOn then
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self[control.dependsOn]:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				local setting = self[control.dependsOn]:GetChecked()
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

function XRPOptions_Mixin:cancel()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomCancel then
			xpcall(control.CustomCancel, geterrorhandler(), control)
		else
			control:Set(control.oldValue)
			control.value = control.oldValue
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(control.value)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				for i, entry in ipairs(control.baseMenuList) do
					if entry.arg1 == control.value then
						control.Text:SetText(entry.text)
						break
					end
				end
			end
		end
		if control.dependsOn then
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self[control.dependsOn]:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				local setting = self[control.dependsOn]:GetChecked()
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

function XRPOptions_Mixin:default()
	if not self.controls then return end
	for i, control in ipairs(self.controls) do
		if control.CustomDefault then
			xpcall(control.CustomDefault, geterrorhandler(), control)
		else
			local defaultValue
			if control.xrpTable then
				defaultValue = AddOn.DEFAULT_SETTINGS[control.xrpTable][control.xrpSetting]
			else
				defaultValue = AddOn.DEFAULT_SETTINGS[control.xrpSetting]
			end
			control:Set(defaultValue)
			control.value = defaultValue
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetChecked(control.value)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				for i, entry in ipairs(control.baseMenuList) do
					if entry.arg1 == control.value then
						control.Text:SetText(entry.text)
						break
					end
				end
			end
		end
		if control.dependsOn then
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self[control.dependsOn]:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				local setting = self[control.dependsOn]:GetChecked()
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

local OPTIONS_NAME = {
	GENERAL = GENERAL,
	DISPLAY = DISPLAY,
	CHAT = CHAT,
	TOOLTIP = L.TOOLTIP,
	ADVANCED = ADVANCED_LABEL,
}
local OPTIONS_DESCRIPTION = {
	GENERAL = L"Configure the core XRP options, dealing with the user interface. Note that some of these options may require a UI reload (/reload) to fully disable.",
	DISPLAY = L"Configure the display options for XRP, changing how some roleplay information is displayed in-game.",
	CHAT = L"Configure the chat-related options for XRP, primarily roleplay names in chat.",
	TOOLTIP = L"Configure the options available for XRP's tooltip display. By default, this overwrites the default tooltip and may conflict with other tooltip-modifying addons.",
	ADVANCED = L"Configure advanced XRP options. Please exercise caution when changing these.",
}
function XRPOptions_Mixin:OnLoad()
	self.name = OPTIONS_NAME[self.paneID]
	self.Title:SetFormattedText(SUBTITLE_FORMAT, "XRP", self.name)
	self.SubText:SetText(OPTIONS_DESCRIPTION[self.paneID])
	self:GetParent().XRP[self.paneID] = self
	InterfaceOptions_AddCategory(self)
end

function XRPOptions_Mixin:OnShow()
	if not self.wasShown then
		self.wasShown = true
		self:refresh()
	end
	self:GetParent().XRP.lastShown = self.paneID
end

local OPTIONS_TEXT = {
	chatType = {
		SAY = SAY,
		EMOTE = EMOTE,
		YELL = YELL,
		WHISPER = WHISPER,
		GUILD = GUILD,
		OFFICER = OFFICER,
		PARTY = PARTY,
		RAID = RAID,
		INSTANCE_CHAT = INSTANCE_CHAT,
	},
	cacheRetainTime = L"Cache expiry time",
	cacheAutoClean = L"Automatically clean old cache entries",
	chatNames = L"Enable roleplay names in chat for:",
	chatEmoteBraced = L"Show square brackets around names in emotes",
	chatReplacements = L"Replace %xt and %xf with roleplay names of target and focus in chat",
	altScourge = L"Display %s as race of %s player characters":format(L.VALUE_GR_SCOURGE_ALT, L.VALUE_GR_SCOURGE),
	altScourgeLimit = L"Only when on a character of that race",
	altScourgeForce = L"Force others to see it, if appropriate",
	altElven = L"Display native race names for %s player characters":format(L.ALT_RACE_ELVEN),
	altElvenLimit = L"Only when on a character of those races",
	altElvenForce = L"Force others to see it, if appropriate",
	altTauren = L"Display native race names for %s player characters":format(L.ALT_RACE_TAUREN),
	altTaurenLimit = L"Only when on a character of those races",
	altTaurenForce = L"Force others to see it, if appropriate",
	viewerMovable = L"Enable profile viewer movement via click/drag on title bar",
	viewerCloseOnEscape = L"Close profile viewer by pressing escape",
	friendsOnly = L"Show profiles only for users on friends list (in-game and Battle.net)",
	friendsIncludeGuild = L"Treat all guild members as friends when on a guilded character",
	heightUnits = L"Height display units",
	weightUnits = L"Weight display units",
	cursorEnabled = L"Display book icon next to cursor if character has a roleplay profile",
	cursorRightClick = L"View profile on right click",
	cursorDisableInstance = L"Disable in instances (PvE and PvP)",
	cursorDisablePvP = L"Disable while PvP flagged",
	viewOnInteract = L"Enable profile viewing via Blizzard interact with target/mouseover keybinds",
	menusChat = L"Enable right-click menu in chat, friends, guild (disables \"Target\", \"Report player Away\")",
	menusUnits = L"Enable right-click menu on unit frames (disables \"Set Focus\", \"Report player Away\")",
	mainButtonEnabled = L"Enable minimap button (if disabled, use /xrp commands to access XRP features)",
	mainButtonDetached = L"Detach button from minimap (shift + right click and drag to move)",
	ldbObject = L"Provide a LibDataBroker object (for Titan Panel, Chocolate Bar, etc.)",
	tooltipEnabled = L"Enable tooltip",
	tooltipReplace = L"Replace default tooltip for players and pets",
	tooltipShowWatchEye = L"Show eye icon if player is targeting you",
	tooltipShowBookmarkFlag = L"Show flag icon if player's profile is bookmarked",
	tooltipShowExtraSpace = L"Add extra spacing lines to the tooltip",
	tooltipShowHouse = L"Display house/clan/tribe in tooltip",
	tooltipShowGuildRank = L"Display guild rank in tooltip",
	tooltipShowGuildIndex = L"Also display guild rank index (numerical ranking) in tooltip",
	tooltipHideHostile = L"Disable roleplay information display on hostile characters",
	tooltipHideOppositeFaction = L"Disable roleplay information display on all opposite faction characters",
	tooltipHideInstanceCombat = L"Disable roleplay information display while in instanced combat",
	tooltipHideClass = L"Hide roleplay class information on tooltip",
	tooltipHideRace = L"Hide roleplay race information on tooltip",
}

function XRPOptionsControl_Mixin:OnLoad()
	if self.type == CONTROLTYPE_CHECKBOX then
		self.dependentControls = {}
	end
	if self.dependsOn then
		local depends = self:GetParent()[self.dependsOn].dependentControls
		depends[#depends + 1] = self
	end
	local optionsText = self.xrpSetting and (self.xrpTable and OPTIONS_TEXT[self.xrpTable][self.xrpSetting] or OPTIONS_TEXT[self.xrpSetting])
	if self.type == CONTROLTYPE_CHECKBOX and self.xrpSetting then
		self.Text:SetText(optionsText)
	elseif self.type == CONTROLTYPE_DROPDOWN and self.xrpSetting then
		self.Label:SetText(optionsText)
	end
	if self.textString then
		self.Text:SetText(self.textString)
	end
end

XRPOptionsCheckButton_Mixin = {}

function XRPOptionsCheckButton_Mixin:OnClick(button, down)
	local setting = self:GetChecked()
	PlaySound(setting and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	self.value = setting
	if self.dependentControls then
		for i, control in ipairs(self.dependentControls) do
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(setting)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				if setting then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
	if setting and self.enableWarn then
		StaticPopup_Show("XRP_ERROR", L[self.enableWarn])
	elseif not setting and self.disableWarn then
		StaticPopup_Show("XRP_ERROR", L[self.disableWarn])
	end
	self:Set(setting)
end

function XRPOptionsCheckButton_Mixin:OnEnable()
	self.Text:SetTextColor(self.Text:GetFontObject():GetTextColor())
	if self.dependentControls then
		for i, control in ipairs(self.dependentControls) do
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(self:GetChecked())
			elseif control.type == CONTROLTYPE_DROPDOWN then
				if self:GetChecked() then
					UIDropDownMenu_EnableDropDown(control)
				else
					UIDropDownMenu_DisableDropDown(control)
				end
			end
		end
	end
end

function XRPOptionsCheckButton_Mixin:OnDisable()
	self.Text:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
	if self.dependentControls then
		for i, control in ipairs(self.dependentControls) do
			if control.type == CONTROLTYPE_CHECKBOX then
				control:SetEnabled(false)
			elseif control.type == CONTROLTYPE_DROPDOWN then
				UIDropDownMenu_DisableDropDown(control)
			end
		end
	end
end

local function DropDown_OnClick(self, arg1, arg2, checked)
	if not checked then
		UIDROPDOWNMENU_INIT_MENU.Text:SetText(arg2)
		UIDROPDOWNMENU_INIT_MENU.value = arg1
		UIDROPDOWNMENU_INIT_MENU:Set(arg1)
	end
end

local function DropDown_Checked(self)
	return self.arg1 == UIDROPDOWNMENU_INIT_MENU.value
end

XRPOptionsGeneralHeight_baseMenuList = {
	{ text = L.CENTIMETERS, arg1 = "cm", arg2 = L.CENTIMETERS, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.FEET_INCHES, arg1 = "ft", arg2 = L.FEET_INCHES, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.METERS, arg1 = "m", arg2 = L.METERS, checked = DropDown_Checked, func = DropDown_OnClick },
}

XRPOptionsGeneralWeight_baseMenuList = {
	{ text = L.KILOGRAMS, arg1 = "kg", arg2 = L.KILOGRAMS, checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L.POUNDS, arg1 = "lb", arg2 = L.POUNDS, checked = DropDown_Checked, func = DropDown_OnClick },
}

XRPOptionsAdvancedTime_baseMenuList = {
	{ text = L"1 Day", arg1 = 86400, arg2 = L"1 Day", checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L"3 Days", arg1 = 259200, arg2 = L"3 Days", checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L"7 Days", arg1 = 604800, arg2 = L"7 Days", checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L"10 Days", arg1 = 864000, arg2 = L"10 Days", checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L"2 Weeks", arg1 = 1209600, arg2 = L"2 Weeks", checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L"1 Month", arg1 = 2419200, arg2 = L"1 Month", checked = DropDown_Checked, func = DropDown_OnClick },
	{ text = L"3 Months", arg1 = 7257600, arg2 = L"3 Months", checked = DropDown_Checked, func = DropDown_OnClick },
}
