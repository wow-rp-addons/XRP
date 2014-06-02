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

local tooltip_settings = { "reaction", "watching", "guildrank", "rprace", "noopfaction", "nohostile", "extraspace" }

local function tooltip_Okay()
	for _, tt in ipairs(tooltip_settings) do
		xrp_settings.tooltip[tt] = xrp.options.tooltip[tt]:GetChecked() and true or false
	end
end

local function tooltip_Refresh()
	for _, tt in ipairs(tooltip_settings) do
		xrp.options.tooltip[tt]:SetChecked(xrp_settings.tooltip[tt])
	end
end

local function tooltip_Default()
	for tt, setting in pairs(xrp_settings.tooltip) do
		xrp_settings.tooltip[tt] = nil
	end

	tooltip_Refresh()
end

local function tooltip_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_options" then
		if (select(4, GetAddOnInfo("xrp_tooltip"))) then
			self.name = xrp.L["Tooltip"]
			self.refresh = tooltip_Refresh
			self.okay = tooltip_Okay
			self.default = tooltip_Default
			self.parent = XRP
			InterfaceOptions_AddCategory(self)
			tooltip_Refresh()
		end

		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrp.options.tooltip:SetScript("OnEvent", tooltip_OnEvent)
xrp.options.tooltip:RegisterEvent("ADDON_LOADED")
