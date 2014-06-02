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

	for _, field in ipairs(core_defaultfields) do
		xrp_settings.defaults[field] = xrp.options.core[field]:GetChecked() and true or false
	end

	xrp_settings.cachetime = UIDropDownMenu_GetSelectedValue(xrp.options.core.CacheTime)
	xrp_settings.cachetidy = xrp.options.core.CacheAuto:GetChecked() and true or false
end

local function core_Refresh()
	UIDropDownMenu_Initialize(xrp.options.core.AHUnits, xrp.options.core.AHUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.core.AHUnits, xrp_settings.height)

	UIDropDownMenu_Initialize(xrp.options.core.AWUnits, xrp.options.core.AWUnits.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.core.AWUnits, xrp_settings.weight)

	for _, field in ipairs(core_defaultfields) do
		xrp.options.core[field]:SetChecked(xrp_settings.defaults[field])
	end

	UIDropDownMenu_Initialize(xrp.options.core.CacheTime, xrp.options.core.CacheTime.initialize)
	UIDropDownMenu_SetSelectedValue(xrp.options.core.CacheTime, xrp_settings.cachetime)
	xrp.options.core.CacheAuto:SetChecked(xrp_settings.cachetidy)
end

local function core_Default()
	xrp_settings.height = nil
	xrp_settings.weight = nil

	for field, setting in pairs(xrp_settings.defaults) do
		xrp_settings.defaults[field] = nil
	end

	xrp_settings.cachetime = nil
	xrp_settings.cachetidy = nil

	core_Refresh()
end

local function core_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_options" then
		local L = xrp.L
		self.name = L["Core"]
		self.refresh = core_Refresh
		self.okay = core_Okay
		self.default = core_Default
		self.parent = XRP
		InterfaceOptions_AddCategory(self)

		-- TODO: Sort values in first two menus (post-localization).
		UIDropDownMenu_Initialize(self.AHUnits, function()
			local info
			for key, text in ipairs({ L["Centimeters"], L["Feet/Inches"], L["Meters"] }) do
				local value = key == 1 and "cm" or key == 2 and "ft" or key == 3 and "m"
				info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = value
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
			for key, text in ipairs({ L["Kilograms"], L["Pounds"] }) do
				local value = key == 1 and "kg" or key == 2 and "lb"
				info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = value
				info.func = function(self, arg1, arg2, checked)
					if not checked then
						UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
					end
				end
				UIDropDownMenu_AddButton(info)
			end
		end)
		UIDropDownMenu_Initialize(self.CacheTime, function()
			local info
			for key, text in ipairs({ L["1 day"], L["3 days"], L["1 week"], L["2 weeks"], L["1 month"], L["3 months"] }) do
				local value = key == 1 and 86400 or key == 2 and 259200 or key == 3 and 604800 or key == 4 and 1209600 or key == 5 and 2419200 or key == 6 and 7257600
				info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = value
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
