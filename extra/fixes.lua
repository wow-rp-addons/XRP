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

local addonName, _xrp = ...

-- ElvUI (and some others) disable the entire HelpPlate system rather than
-- specifically managing it on the frames they modify or handling the automated
-- tutorials in a more granular way.
--
-- Since XRP makes use of it as the only help system, and very comprehensively,
-- re-enable it. If those addons want to disable it on default frames, it
-- should be done just for those frames.
_xrp.HookGameEvent("PLAYER_LOGIN", function(event, ...)
	if HelpPlate:GetParent() ~= UIParent then
		HelpPlate:SetParent(UIParent)
		HelpPlate:SetFrameStrata("DIALOG")
	end
	if HelpPlateTooltip:GetParent() ~= UIParent then
		HelpPlateTooltip:SetParent(UIParent)
		HelpPlateTooltip:SetFrameStrata("FULLSCREEN_DIALOG")
		HelpPlateTooltip:SetFrameLevel(2)
	end
end)
