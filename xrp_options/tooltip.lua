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
if not (select(4, GetAddOnInfo("xrp_tooltip"))) then
	return
end

local settings
do
	local tooltip_settings = { "faction", "watching", "guildrank", "guildindex", "norprace", "norpclass", "noopfaction", "nohostile", "extraspace" }

	function xrp.options.tooltip:okay()
		for _, tt in ipairs(tooltip_settings) do
			settings[tt] = self[tt]:GetChecked()
		end
	end

	function xrp.options.tooltip:refresh()
		for _, tt in ipairs(tooltip_settings) do
			self[tt]:SetChecked(settings[tt])
		end
		self.guildindex:SetEnabled(self.guildrank:GetChecked())
	end
end

function xrp.options.tooltip:default()
	for tt, setting in pairs(settings) do
		settings[tt] = nil
	end
	self:refresh()
end

xrp.options.tooltip.parent = XRP
xrp.options.tooltip.name = xrp.L["Tooltip"]
InterfaceOptions_AddCategory(xrp.options.tooltip)

xrp:HookLoad(function()
	settings = xrp.settings.tooltip
	xrp.options.tooltip:refresh()
end)
