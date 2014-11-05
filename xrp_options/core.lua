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

local addonName, private = ...

private.core = XRPOptionsCore
XRPOptionsCore = nil

local settings
local L = xrp.L

do
	local CORE_BOOLEAN = { "cachetidy" }
	local CORE_MENU = { "height", "weight", "cachetime" }
	local MINIMAP_BOOLEAN = { "hidett", "detached" }
	local INTEGRATION_BOOLEAN = { "rightclick", "disableinstance", "disablepvp", "interact", "replacements", "menus", "unitmenus" }

	function private.core:okay()
		if settings.minimap.detached ~= self.detached:GetChecked() or settings.integration.menus ~= self.menus:GetChecked() or settings.integration.unitmenus ~= self.unitmenus:GetChecked() then
			StaticPopup_Show("XRP_RELOAD", L["You have changed an XRP option which requires a UI reload to take effect."])
		end

		for _, setting in ipairs(CORE_BOOLEAN) do
			settings[setting] = self[setting]:GetChecked()
		end

		for _, setting in ipairs(CORE_MENU) do
			settings[setting] = UIDropDownMenu_GetSelectedValue(self[setting])
		end

		for _, setting in ipairs(MINIMAP_BOOLEAN) do
			settings.minimap[setting] = self[setting]:GetChecked()
		end

		for _, setting in ipairs(INTEGRATION_BOOLEAN) do
			settings.integration[setting] = self[setting]:GetChecked()
		end
	end

	function private.core:refresh()
		for _, setting in ipairs(CORE_BOOLEAN) do
			self[setting]:SetChecked(settings[setting])
		end

		for _, setting in ipairs(CORE_MENU) do
			UIDropDownMenu_Initialize(self[setting], self[setting].initialize)
			UIDropDownMenu_SetSelectedValue(self[setting], settings[setting])
		end

		for _, setting in ipairs(MINIMAP_BOOLEAN) do
			self[setting]:SetChecked(settings.minimap[setting])
		end

		for _, setting in ipairs(INTEGRATION_BOOLEAN) do
			self[setting]:SetChecked(settings.integration[setting])
		end
		self.disableinstance:SetEnabled(settings.integration.rightclick)
		self.disablepvp:SetEnabled(settings.integration.rightclick)
	end

	function private.core:default()
		for _, setting in ipairs(CORE_BOOLEAN) do
			settings[setting] = nil
		end

		for _, setting in ipairs(CORE_MENU) do
			settings[setting] = nil
		end

		for _, setting in ipairs(MINIMAP_BOOLEAN) do
			settings.minimap[setting] = nil
		end

		for _, setting in ipairs(INTEGRATION_BOOLEAN) do
			settings.integration[setting] = nil
		end

		self:refresh()
	end

end

private.core.parent = XRP

private.core.name = L["Core"]
InterfaceOptions_AddCategory(private.core)

do
	local infofunc = function(self, arg1, arg2, checked)
		if not checked then
			UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
		end
	end

	do
		local heights = { L["Centimeters"], L["Feet/Inches"], L["Meters"] }
		table.sort(heights)
		function private.core.height:initialize(level, menuList)
			for _, text in ipairs(heights) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = text == L["Centimeters"] and "cm" or text == L["Feet/Inches"] and "ft" or text == L["Meters"] and "m"
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end
	end

	do
		local weights = { L["Kilograms"], L["Pounds"] }
		table.sort(weights)
		function private.core.weight:initialize(level, menuList)
			for _, text in ipairs(weights) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = text == L["Kilograms"] and "kg" or text == L["Pounds"] and "lb"
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end
	end

	do
		local times = { L["1 day"], L["3 days"], L["7 days"], L["10 days"], L["2 weeks"], L["1 month"], L["3 months"] }
		local seconds = { 86400, 259200, 604800, 864000, 1209600, 2419200, 7257600 }
		function private.core.cachetime:initialize(level, menuList)
			for index, text in ipairs(times) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = text
				info.value = seconds[index]
				info.func = infofunc
				UIDropDownMenu_AddButton(info)
			end
		end
	end
end

xrp:HookLoad(function()
	settings = xrp.settings
	private.core:refresh()
end)
