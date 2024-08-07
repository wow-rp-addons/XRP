--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...

local cursor, rightClick

-- There is no mouseover unit available during TurnOrAction*, but if a unit is
-- right-clicked, it will be the target unit by Stop.
local now, mouseover, autoInteract
local function Cursor_TurnOrActionStart()
	if not cursor or not rightClick or InCombatLockdown() or not XRPCursorBook:IsVisible() then return end
	mouseover = XRPCursorBook.characterName
	now = GetTime()
	if XRPCursorBook.mountable then
		autoInteract = GetCVarBool("AutoInteract")
		if autoInteract then
			SetCVar("AutoInteract", "0")
		end
	end
end
local function Cursor_TurnOrActionStop()
	if not mouseover then return end
	-- 0.75s interaction time is guessed as Blizzard number from in-game
	-- testing. Used for consistency.
	if GetTime() - now < 0.75 and mouseover == UnitName("target") then
		if XRPCursorBook.mountable then
			UIErrorsFrame:Clear() -- Hides errors on inteactable mount players.
		end
		XRPViewer:View("target")
	end
	if autoInteract then
		SetCVar("AutoInteract", "1")
	end
	mouseover = nil
	autoInteract = nil
end

local function Cursor_RECEIVE(event, name)
	if name == XRPCursorBook.characterID and not InCombatLockdown() and not XRPCursorBook:IsVisible() and (not XRPCursorBook.mountInParty or not C_Item.IsItemInRange(88589, "mouseover")) then
		XRPCursorBook:Show()
	end
end

-- Permits using the Blizzard interact with mouseover/target keybindings as
-- RP profile view bindings. Don't do it for hostile targets -- interact
-- keybinds start attack there.
local keybind
local function InteractUnit_Hook(unit)
	if not keybind or InCombatLockdown() or not UnitIsPlayer(unit) or UnitCanAttack("player", unit) then return end
	local mountable = UnitVehicleSeatCount(unit) > 0
	if mountable and ((UnitInParty(unit) or UnitInRaid(unit)) and C_Item.IsItemInRange(88589, unit) or GetCVarBool("AutoInteract")) then return end
	if mountable then
		UIErrorsFrame:Clear() -- Hides errors on inteactable mount players.
	end
	XRPViewer:View(unit)
end

AddOn.SettingsToggles.cursorEnabled = function(setting)
	if setting then
		if not XRPCursorBook then
			C_Item.IsItemInRange(88589, "player")
			CreateFrame("Frame", "XRPCursorBook", UIParent, "XRPCursorBookTemplate")
		end
		AddOn_XRP.RegisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", Cursor_RECEIVE)
		XRPCursorBook:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		cursor = true
	elseif cursor ~= nil then
		XRPCursorBook:UnregisterAllEvents()
		XRPCursorBook:Hide()
		AddOn_XRP.UnregisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", Cursor_RECEIVE)
		cursor = false
	end
end

AddOn.SettingsToggles.cursorRightClick = function(setting)
	if setting then
		if rightClick == nil then
			hooksecurefunc("TurnOrActionStart", Cursor_TurnOrActionStart)
			hooksecurefunc("TurnOrActionStop", Cursor_TurnOrActionStop)
		end
		rightClick = true
	elseif rightClick ~= nil then
		rightClick = false
	end
end

AddOn.SettingsToggles.viewOnInteract = function(setting)
	if setting then
		if keybind == nil then
			hooksecurefunc(C_PlayerInteractionManager, "InteractUnit", InteractUnit_Hook)
		end
		keybind = true
	elseif keybind ~= nil then
		keybind = false
	end
end
