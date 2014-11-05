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

local addonName, private = ...

private.tooltip = XRPOptionsTooltip
XRPOptionsTooltip = nil

local settings
do
	local TOOLTIP_BOOLEAN = { "faction", "watching", "guildrank", "guildindex", "norprace", "norpclass", "noopfaction", "nohostile", "extraspace" }

	function private.tooltip:okay()
		for _, setting in ipairs(TOOLTIP_BOOLEAN) do
			settings[setting] = self[setting]:GetChecked()
		end
	end

	function private.tooltip:refresh()
		for _, setting in ipairs(TOOLTIP_BOOLEAN) do
			self[setting]:SetChecked(settings[setting])
		end
		self.guildindex:SetEnabled(self.guildrank:GetChecked())
	end
end

function private.tooltip:default()
	for setting, _ in pairs(settings) do
		settings[setting] = nil
	end
	self:refresh()
end

private.tooltip.parent = XRP
private.tooltip.name = xrp.L["Tooltip"]
InterfaceOptions_AddCategory(private.tooltip)

xrp:HookLoad(function()
	settings = xrp.settings.tooltip
	private.tooltip:refresh()
end)
