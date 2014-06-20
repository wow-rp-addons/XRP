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

local settings
do
	local core_defaultfields = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU", "DE", "AG", "HH", "HB", "MO", "HI", "FR", "FC" }

	function xrp.options.core:okay()
		settings.height = UIDropDownMenu_GetSelectedValue(self.AHUnits)
		settings.weight = UIDropDownMenu_GetSelectedValue(self.AWUnits)

		for _, field in ipairs(core_defaultfields) do
			settings.defaults[field] = self[field]:GetChecked() and true or false
		end

		settings.cachetime = UIDropDownMenu_GetSelectedValue(self.CacheTime)
		settings.cachetidy = self.CacheAuto:GetChecked() and true or false
	end

	function xrp.options.core:refresh()
		UIDropDownMenu_Initialize(self.AHUnits, self.AHUnits.initialize)
		UIDropDownMenu_SetSelectedValue(self.AHUnits, settings.height)

		UIDropDownMenu_Initialize(self.AWUnits, self.AWUnits.initialize)
		UIDropDownMenu_SetSelectedValue(self.AWUnits, settings.weight)

		for _, field in ipairs(core_defaultfields) do
			self[field]:SetChecked(settings.defaults[field])
		end

		UIDropDownMenu_Initialize(self.CacheTime, self.CacheTime.initialize)
		UIDropDownMenu_SetSelectedValue(self.CacheTime, settings.cachetime)
		self.CacheAuto:SetChecked(settings.cachetidy)
	end
end

function xrp.options.core:default()
	settings.height = nil
	settings.weight = nil

	for field, setting in pairs(settings.defaults) do
		settings.defaults[field] = nil
	end

	settings.cachetime = nil
	settings.cachetidy = nil

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

	do
		local heights = { L["Centimeters"], L["Feet/Inches"], L["Meters"] }
		table.sort(heights)
		UIDropDownMenu_Initialize(xrp.options.core.AHUnits, function()
			for _, text in ipairs(heights) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = text == L["Centimeters"] and "cm" or text == L["Feet/Inches"] and "ft" or text == L["Meters"] and "m"
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end)
	end

	do
		local weights = { L["Kilograms"], L["Pounds"] }
		table.sort(weights)
		UIDropDownMenu_Initialize(xrp.options.core.AWUnits, function()
			for _, text in ipairs(weights) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = text == L["Kilograms"] and "kg" or text == L["Pounds"] and "lb"
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
	settings = xrp.settings
	xrp.options.core:refresh()
end)
