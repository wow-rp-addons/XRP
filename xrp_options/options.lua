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

local defaultfields = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU", "DE", "AG", "HH", "HB", "MO", "HI", "FR", "FC" }

local chattypes = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER" }

local function options_Okay()
	xrp_settings.height = UIDropDownMenu_GetSelectedValue(xrp.options.AHUnits)
	xrp_settings.weight = UIDropDownMenu_GetSelectedValue(xrp.options.AWUnits)
	for _, field in pairs(defaultfields) do
		xrp_settings.defaults[field] = xrp.options[field]:GetChecked() and true or false
	end
	for _, chat in pairs(chattypes) do
		xrp_settings.chatnames[chat] = xrp.options[chat]:GetChecked() and true or false
		if chat == "CHAT_MSG_WHISPER" then
			xrp_settings.chatnames["CHAT_MSG_WHISPER_INFORM"] = xrp.options[chat]:GetChecked() and true or false
		elseif chat == "CHAT_MSG_EMOTE" then
			xrp_settings.chatnames["CHAT_MSG_TEXT_EMOTE"] = xrp.options[chat]:GetChecked() and true or false
		end
	end
end

local function options_Default()
	UIDropDownMenu_Initialize(xrp.options.AHUnits, xrp.options.AHUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.AHUnits, "ft")
	UIDropDownMenu_Initialize(xrp.options.AWUnits, xrp.options.AWUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.AWUnits, "lb")
	for _, field in pairs(defaultfields) do
		xrp.options[field]:SetChecked(true)
	end
	for _, chat in pairs(chattypes) do
		xrp.options[chat]:SetChecked(true)
	end
end

local function options_Refresh()
	UIDropDownMenu_Initialize(xrp.options.AHUnits, xrp.options.AHUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.AHUnits, xrp_settings.height)		UIDropDownMenu_Initialize(xrp.options.AWUnits, xrp.options.AWUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.AWUnits, xrp_settings.weight)
	for _, field in pairs(defaultfields) do
		xrp.options[field]:SetChecked(xrp_settings.defaults[field] == nil and true or xrp_settings.defaults[field])
	end
	for _, chat in pairs(chattypes) do
		xrp.options[chat]:SetChecked(xrp_settings.chatnames[chat] == nil and true or xrp_settings.chatnames[chat])
	end
end

local function options_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_options" then
		self.name = "Options"
		self.refresh = options_Refresh
		self.okay = options_Okay
		self.default = options_Default
		self.parent = XRP
		InterfaceOptions_AddCategory(self)

		UIDropDownMenu_Initialize(self.AHUnits, function()
			local info
			for key, text in pairs({ "Centimeters", "Feet/Inches", "Meters" }) do
				local value = key == 1 and "cm" or key == 2 and "ft" or key == 3 and "m"
				info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = tostring(value)
				info.func = function(self, arg1, arg2, checked)
					if not checked then
						UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
					end
				end
				UIDropDownMenu_AddButton(info)
			end
		end)
		UIDropDownMenu_Initialize(self.AWUnits, function()
			local info
			for key, text in pairs({ "Kilograms", "Pounds" }) do
				local value = key == 1 and "kg" or key == 2 and "lb"
				info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = tostring(value)
				info.func = function(self, arg1, arg2, checked)
					if not checked then
						UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
					end
				end
				UIDropDownMenu_AddButton(info)
			end
		end)

		options_Refresh()

		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrp.options:SetScript("OnEvent", options_OnEvent)
xrp.options:RegisterEvent("ADDON_LOADED")
