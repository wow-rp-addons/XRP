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

local addonName, xrpPrivate = ...

local CursorFrame, cursor, rightClick

local Cursor_TurnOrActionStart, Cursor_TurnOrActionStop
do
	-- There is no mouseover unit available during TurnOrAction*, but
	-- if a unit is right-clicked, it will be the target unit by Stop.
	local now, mouseover, autoInteract
	function Cursor_TurnOrActionStart()
		if not cursor or not rightClick or InCombatLockdown() or not CursorFrame:IsVisible() then return end
		mouseover = CursorFrame.current
		now = GetTime()
		if CursorFrame.mountable then
			autoInteract = GetCVar("AutoInteract") == "1"
			if autoInteract then
				SetCVar("AutoInteract", "0")
			end
		end
	end
	function Cursor_TurnOrActionStop()
		if not mouseover then return end
		-- 0.75s interaction time is guessed as Blizzard number from
		-- in-game testing. Used for consistency.
		if GetTime() - now < 0.75 and mouseover == xrp:UnitName("target") then
			if CursorFrame.mountable then
				UIErrorsFrame:Clear() -- Hides errors on inteactable mount players.
			end
			xrp:View("target")
		end
		if autoInteract then
			SetCVar("AutoInteract", "1")
		end
		mouseover = nil
		autoInteract = nil
	end
end

local function Cursor_OnEvent(self, event)
	if not cursor or InCombatLockdown() or xrpPrivate.settings.interact.disableInstance and (IsInInstance() or IsInActiveWorldPVP()) or xrpPrivate.settings.interact.disablePvP and (UnitIsPVP("player") or UnitIsPVPFreeForAll("player")) or GetMouseFocus() ~= WorldFrame then
		self:Hide()
		return
	end
	local character = xrp.characters.byUnit.mouseover
	if not character or character.hide then
		self:Hide()
		return
	end
	self.current = not UnitCanAttack("player", "mouseover") and character.name or nil
	-- Following two must be separate for UIErrorsFrame:Clear().
	self.mountable = rightClick and self.current and UnitVehicleSeatCount("mouseover") > 0
	self.mountInParty = self.mountable and (UnitInParty("mouseover") or UnitInRaid("mouseover"))
	if self.current and character.fields.VA and (not self.mountInParty or not IsItemInRange(88589, "mouseover")) then
		self:Show()
	else
		self:Hide()
	end
end

local Cursor_OnUpdate
do
	local previousX, previousY
	-- Crazy optimization crap since it's run every frame.
	local UnitIsPlayer, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, IsItemInRange, UIParent, GetEffectiveScale = UnitIsPlayer, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, IsItemInRange, UIParent, UIParent.GetEffectiveScale
	function Cursor_OnUpdate(self, elapsed)
		if not UnitIsPlayer("mouseover") or InCombatLockdown() or GetMouseFocus() ~= WorldFrame then
			self:Hide()
			return
		end
		local x, y = GetCursorPosition()
		if x == previousX and y == previousY then return end
		if self.mountInParty and IsItemInRange(88589, "mouseover") then
			self:Hide()
			return
		end
		local scale = GetEffectiveScale(UIParent)
		self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale + 36, y/scale - 4)
		previousX, previousY = x, y
	end
end

local function Cursor_RECEIVE(event, name)
	if cursor and name == CursorFrame.current and not InCombatLockdown() and not CursorFrame:IsVisible() and (not CursorFrame.mountInParty or not IsItemInRange(88589, "mouseover")) then
		CursorFrame:Show()
	end
end

-- Permits using the Blizzard interact with mouseover/target keybindings as
-- RP profile view bindings. Don't do it for hostile targets -- interact
-- keybinds start attack there.
local keybind
local function InteractUnit_Hook(unit)
	if not keybind or InCombatLockdown() or not UnitIsPlayer(unit) or UnitCanAttack("player", unit) then return end
	local mountable = UnitVehicleSeatCount(unit) > 0
	if mountable and ((UnitInParty(unit) or UnitInRaid(unit)) and IsItemInRange(88589, unit) or GetCVar("AutoInteract") == "1") then return end
	if mountable then
		UIErrorsFrame:Clear() -- Hides errors on inteactable mount players.
	end
	xrp:View(unit)
end

local function CreateCursor()
	-- Cache item data for range checking.
	IsItemInRange(88589, "player")
	CursorFrame = CreateFrame("Frame", nil, UIParent)
	-- Pretending to be part of the mouse cursor, so better be above
	-- everything we possibly can.
	CursorFrame:SetFrameStrata("TOOLTIP")
	CursorFrame:SetFrameLevel(127)
	CursorFrame:SetWidth(24)
	CursorFrame:SetHeight(24)
	CursorFrame.Image = CursorFrame:CreateTexture(nil, "BACKGROUND")
	CursorFrame.Image:SetTexture("Interface\\MINIMAP\\TRACKING\\Class")
	CursorFrame.Image:SetAllPoints(CursorFrame)
	CursorFrame:Hide()
	CursorFrame:SetScript("OnEvent", Cursor_OnEvent)
	CursorFrame:SetScript("OnUpdate", Cursor_OnUpdate)
	xrp:HookEvent("RECEIVE", Cursor_RECEIVE)
end

xrpPrivate.settingsToggles.interact = {
	cursor = function(setting)
		if setting then
			if not CursorFrame then
				CreateCursor()
			end
			CursorFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			cursor = true
		elseif cursor ~= nil then
			CursorFrame:UnregisterAllEvents()
			CursorFrame:Hide()
			cursor = false
		end
	end,
	rightClick = function(setting)
		if setting then
			if rightClick == nil then
				hooksecurefunc("TurnOrActionStart", Cursor_TurnOrActionStart)
				hooksecurefunc("TurnOrActionStop", Cursor_TurnOrActionStop)
			end
			rightClick = true
		elseif rightClick ~= nil then
			rightClick = false
		end
	end,
	keybind = function(setting)
		if setting then
			if keybind == nil then
				hooksecurefunc("InteractUnit", InteractUnit_Hook)
			end
			keybind = true
		elseif keybind ~= nil then
			keybind = false
		end
	end,
}
