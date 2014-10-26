--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

-- Closing interface options after viewing the raid profiles (compact raid
-- frames) section tends to horrifically taint most of the UI. Warn users about
-- that.

local cufopened = false
CompactUnitFrameProfiles:HookScript("OnShow", function(self)
	cufopened = true
end)

InterfaceOptionsFrame:HookScript("OnHide", function(self)
	if cufopened then
		StaticPopup_Show("XRP_RELOAD", xrp.L["You accessed the raid profiles options. Due to Blizzard bugs, this can cause severe UI problems for which it may (inaccurately) blame XRP. You should reload your UI now to fix this."])
		cufopened = false
	end
end)
