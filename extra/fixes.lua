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

-- Making use of the raid profile dropdowns to change settings taints the
-- entire default raid frames. This warns if such changes have been made.
local doWarning
hooksecurefunc("CompactUnitFrameProfilesDropdownButton_OnClick", function(self, dropDown)
	doWarning = true
end)

InterfaceOptionsFrame:HookScript("OnHide", function(self)
	if not doWarning then return end
	doWarning = nil
	StaticPopup_Show("XRP_RELOAD", _xrp.L.CUF_WARNING)
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
	-- everything.
	--CompactUnitFrameProfiles_ApplyCurrentSettings()
end

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
