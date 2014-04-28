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

local core_defaultfields = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU", "DE", "AG", "HH", "HB", "MO", "HI", "FR", "FC" }

local function core_Okay()
	xrp_settings.height = UIDropDownMenu_GetSelectedValue(xrp.options.core.AHUnits)
	xrp_settings.weight = UIDropDownMenu_GetSelectedValue(xrp.options.core.AWUnits)
	for _, field in pairs(core_defaultfields) do
		xrp_settings.defaults[field] = xrp.options.core[field]:GetChecked() and true or false
	end
end

local function core_Default()
	UIDropDownMenu_Initialize(xrp.options.core.AHUnits, xrp.options.core.AHUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.core.AHUnits, "ft")
	UIDropDownMenu_Initialize(xrp.options.core.AWUnits, xrp.options.core.AWUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.core.AWUnits, "lb")
	for _, field in pairs(core_defaultfields) do
		xrp.options.core[field]:SetChecked(true)
	end
end

local function core_Refresh()
	UIDropDownMenu_Initialize(xrp.options.core.AHUnits, xrp.options.core.AHUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.core.AHUnits, xrp_settings.height)		UIDropDownMenu_Initialize(xrp.options.core.AWUnits, xrp.options.core.AWUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.core.AWUnits, xrp_settings.weight)
	for _, field in pairs(core_defaultfields) do
		xrp.options.core[field]:SetChecked(xrp_settings.defaults[field] == nil and true or xrp_settings.defaults[field])
	end
end

local function core_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_options" then
		self.name = "Core"
		self.refresh = core_Refresh
		self.okay = core_Okay
		self.default = core_Default
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

		core_Refresh()

		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrp.options.core:SetScript("OnEvent", core_OnEvent)
xrp.options.core:RegisterEvent("ADDON_LOADED")
