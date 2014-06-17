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

do
	local core_defaultfields = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU", "DE", "AG", "HH", "HB", "MO", "HI", "FR", "FC" }

	function xrp.options.core:okay()
		xrp_settings.height = UIDropDownMenu_GetSelectedValue(self.AHUnits)
		xrp_settings.weight = UIDropDownMenu_GetSelectedValue(self.AWUnits)

		for _, field in ipairs(core_defaultfields) do
			xrp_settings.defaults[field] = self[field]:GetChecked() and true or false
		end

		xrp_settings.cachetime = UIDropDownMenu_GetSelectedValue(self.CacheTime)
		xrp_settings.cachetidy = self.CacheAuto:GetChecked() and true or false
	end

	function xrp.options.core:refresh()
		UIDropDownMenu_Initialize(self.AHUnits, self.AHUnits.initialize)
		UIDropDownMenu_SetSelectedValue(self.AHUnits, xrp_settings.height)

		UIDropDownMenu_Initialize(self.AWUnits, self.AWUnits.initialize)
		UIDropDownMenu_SetSelectedValue(self.AWUnits, xrp_settings.weight)

		for _, field in ipairs(core_defaultfields) do
			self[field]:SetChecked(xrp_settings.defaults[field])
		end

		UIDropDownMenu_Initialize(self.CacheTime, self.CacheTime.initialize)
		UIDropDownMenu_SetSelectedValue(self.CacheTime, xrp_settings.cachetime)
		self.CacheAuto:SetChecked(xrp_settings.cachetidy)
	end
end

function xrp.options.core:default()
	xrp_settings.height = nil
	xrp_settings.weight = nil

	for field, setting in pairs(xrp_settings.defaults) do
		xrp_settings.defaults[field] = nil
	end

	xrp_settings.cachetime = nil
	xrp_settings.cachetidy = nil

	self:refresh()
end

xrp.options.core.parent = XRP

local L = xrp.L
xrp.options.core.name = L["Core"]
InterfaceOptions_AddCategory(xrp.options.core)

do
	local infofunc = function(self, arg1, arg2, checked)
		if not checked then
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
		end
	end

	-- TODO: Sort values in first two menus (post-localization).
	do
		local heights = { L["Centimeters"], L["Feet/Inches"], L["Meters"] }
		UIDropDownMenu_Initialize(xrp.options.core.AHUnits, function()
			for key, text in ipairs(heights) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = key == 1 and "cm" or key == 2 and "ft" or key == 3 and "m"
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end)
	end

	do
		local weights = { L["Kilograms"], L["Pounds"] }
		UIDropDownMenu_Initialize(xrp.options.core.AWUnits, function()
			for key, text in ipairs(weights) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = key == 1 and "kg" or key == 2 and "lb"
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end)
	end

	do
		local times = { L["1 day"], L["3 days"], L["7 days"], L["10 days"], L["2 weeks"], L["1 month"], L["3 months"] }
		local seconds = { 86400, 259200, 604800, 864000, 1209600, 2419200, 7257600 }
		UIDropDownMenu_Initialize(xrp.options.core.CacheTime, function()
			for key, text in ipairs(times) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = seconds[key]
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end)
	end
end

xrp:HookLoad(function()
	xrp.options.core:refresh()
end)
