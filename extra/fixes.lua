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

-- Closing interface options after viewing the raid profiles (compact raid
-- frames) section tends to horrifically taint most of the UI. Warn users about
-- that.
local cufOpened, blamed = false, nil
CompactUnitFrameProfiles:HookScript("OnShow", function(self)
	cufOpened = true
	local isSecure, blameName = issecurevariable("UIDROPDOWNMENU_MENU_LEVEL")
	if not isSecure then
		blamed = blameName
	end
end)
CompactUnitFrameProfiles:HookScript("OnHide", function(self)
	if not cufOpened or blamed then return end
	local isSecure, blameName = issecurevariable("UIDROPDOWNMENU_MENU_LEVEL")
	if not isSecure then
		blamed = blameName
	else
		-- If it was secure at open and close, it should be safe. This isn't a
		-- perfect guarantee, but it's close.
		cufOpened = false
	end
end)
InterfaceOptionsFrame:HookScript("OnHide", function(self)
	if not cufOpened then return end
	cufOpened = false
	StaticPopup_Show("XRP_RELOAD", _xrp.L.CUF_WARNING:format(GetAddOnMetadata(blamed, "Title")))
	blamed = nil
end)

-- This is kinda terrifying, but it fixes some major UI tainting when the user
-- presses "Cancel" in the Interface Options (out of combat). The drawback is
-- that any changes made to the default compact raid frames aren't actually
-- cancelled (they're not saved, but they're still active). Still, this is
-- better than having the Cancel button completely taint the raid frames, and
-- then have that taint spread further.
function CompactUnitFrameProfiles_CancelChanges(self)
	InterfaceOptionsPanel_Cancel(self)

	-- The following is disabled to make it more obvious that changes aren't
	-- really cancelled.
	--RestoreRaidProfileFromCopy()

	CompactUnitFrameProfiles_UpdateCurrentPanel()

	-- The following is disabled because it's the actual function that taints
	-- everything. The execution path is tainted by the time this function is
	-- called if there's any addon with an Interface Options panel.
	--CompactUnitFrameProfiles_ApplyCurrentSettings()
end
