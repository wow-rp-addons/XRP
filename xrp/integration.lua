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
local settings
do
	local default_settings = {
		rightclick = true,
		disableinstance = false,
		disablepvp = false,
		interact = true,
		replacements = true,
		menus = true,
		unitmenus = false,
	}
	xrp:HookLoad(function()
		if type(xrp.settings.integration) ~= "table" then
			xrp.settings.integration = {}
		end
		settings = setmetatable(xrp.settings.integration, { __index = default_settings })
	end)
end

-- Right click integration (game world)
--
-- This allows right-clicking on player targets with RP profiles to view those
-- profiles, like how interacting with NPCs works.
xrp:HookLogin(function()
	-- Cache item data for range checking.
	IsItemInRange(88589, "player")
end)
do
	local cursor = CreateFrame("Frame", nil, UIParent)
	-- Pretending to be part of the mouse cursor, so better be above everything
	-- we possibly can.
	cursor:SetFrameStrata("TOOLTIP")
	cursor:SetFrameLevel(255)
	cursor:SetWidth(24)
	cursor:SetHeight(24)
	do
		local cursorimage = cursor:CreateTexture(nil, "BACKGROUND")
		cursorimage:SetTexture("Interface\\MINIMAP\\TRACKING\\Class")
		cursorimage:SetAllPoints(cursor)
	end
	do
		-- There is no mouseover unit available during TurnOrAction*, but
		-- if a unit is right-clicked, it will be the target unit by Stop.
		local now, mouseover, autointeract
		hooksecurefunc("TurnOrActionStart", function()
			if not settings.rightclick or InCombatLockdown() or not cursor:IsVisible() then return end
			mouseover = cursor.current
			now = GetTime()
			if cursor.mountable then
				autointeract = GetCVar("AutoInteract") == "1"
				if autointeract then
					SetCVar("AutoInteract", "0")
				end
			end
		end)
		hooksecurefunc("TurnOrActionStop", function()
			if not mouseover then return end
			-- 0.75s interaction time is guessed as Blizzard number from
			-- in-game testing. Used for consistency.
			if GetTime() - now < 0.75 and mouseover == xrp:UnitNameWithRealm("target") then
				if cursor.mountable then
					UIErrorsFrame:Clear() -- Hides errors on inteactable mount players.
				end
				xrp:ShowViewerUnit("target")
			end
			if autointeract then
				SetCVar("AutoInteract", "1")
			end
			mouseover = nil
			autointeract = nil
		end)
	end
	cursor:SetScript("OnEvent", function(self, event)
		if not settings.rightclick or InCombatLockdown() or (settings.disableinstance and (IsInInstance() or IsInActiveWorldPVP())) or (settings.disablepvp and (UnitIsPVP("player") or UnitIsPVPFreeForAll("player"))) or GetMouseFocus() ~= WorldFrame or not xrp.units.mouseover then
			self:Hide()
			return
		end
		self.current = not UnitCanAttack("player", "mouseover") and xrp:UnitNameWithRealm("mouseover") or nil
		-- Following two must be separate for UIErrorsFrame:Clear().
		self.inparty = self.current and (UnitInParty("mouseover") or UnitInRaid("mouseover"))
		self.mountable = self.current and UnitVehicleSeatCount("mouseover") > 0
		if self.current and xrp.units.mouseover.fields.VA and not (self.mountable and self.inparty and IsItemInRange(88589, "mouseover")) then
			self:Show()
		else
			self:Hide()
		end
	end)
	do
		local previousX, previousY
		-- Crazy optimization crap since it's run every frame.
		local UnitIsPlayer, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, IsItemInRange, UIParent, GetEffectiveScale = UnitIsPlayer, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, IsItemInRange, UIParent, UIParent.GetEffectiveScale
		cursor:SetScript("OnUpdate", function(self, elapsed)
			if not UnitIsPlayer("mouseover") or InCombatLockdown() or GetMouseFocus() ~= WorldFrame then
				self:Hide()
				return
			end
			local x, y = GetCursorPosition()
			if x == previousX and y == previousY then return end
			if self.mountable and self.inparty and IsItemInRange(88589, "mouseover") then
				self:Hide()
				return
			end
			local scale = GetEffectiveScale(UIParent)
			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale + 36, y/scale - 4)
			previousX, previousY = x, y
		end)
	end
	xrp:HookEvent("MSP_RECEIVE", function(name)
		if settings.rightclick and name == cursor.current and not InCombatLockdown() and not cursor:IsVisible() and not (cursor.mountable and cursor.inparty and IsItemInRange(88589, "mouseover")) then
			cursor:Show()
		end
	end)
	cursor:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	cursor:Hide()
end

-- Interact keybind integration
--
-- Permits using the Blizzard interact with mouseover/target keybindings as
-- RP profile view bindings. Don't do it for hostile targets -- interact
-- keybinds start attack there.
hooksecurefunc("InteractUnit", function(unit)
	if not settings.interact or InCombatLockdown() or UnitCanAttack("player", unit) then return end
	local mountable = UnitVehicleSeatCount(unit) > 0
	if mountable and (((UnitInParty(unit) or UnitInRaid(unit)) and IsItemInRange(88589, unit)) or GetCVar("AutoInteract") == "1") then return end
	if mountable then
		UIErrorsFrame:Clear() -- Hides errors on inteactable mount players.
	end
	xrp:ShowViewerUnit(unit)
end)

-- Chat box integration (%xt/%xf)
--
-- This replaces %xt and %xf with the target's/focus's RP name or, if that is
-- unavailable, unit name. Note that this has the minor oddity of saving the
-- replaced value in the chat history, rather than the %xt/%xf replacement
-- pattern.
hooksecurefunc("ChatEdit_ParseText", function(line, send)
	if send == 1 and settings.replacements then
		local oldtext = line:GetText()
		local text = oldtext
		if text:find("%xt", nil, true) then
			text = text:gsub("%%xt", UnitExists("target") and (xrp.units.target and xrp.units.target.fields.NA or UnitName("target")) or xrp.L["nobody"])
		end
		if text:find("%xf", nil, true) then
			text = text:gsub("%%xf", UnitExists("focus") and (xrp.units.focus and xrp.units.focus.fields.NA or UnitName("focus")) or xrp.L["nobody"])
		end
		if text ~= oldtext then
			line:SetText(text)
		end
	end
end)

-- Right-click menu integration
--
-- This adds RP Profile menu entries to several menus for a more convenient
-- way to access profiles (including chat names, guild lists, and chat
-- rosters).
--
-- Note: Cannot be added to menus which call protected functions without
-- causing taint problems. This includes all unit menus with a "SET_FOCUS"
-- button. The menus can be found in Blizzard's UnitPopups.lua.
UnitPopupButtons["XRP_VIEW_CHARACTER"] = { text = xrp.L["Roleplay Profile"], dist = 0 }
UnitPopupButtons["XRP_VIEW_UNIT"] = { text = xrp.L["Roleplay Profile"], dist = 0 }

hooksecurefunc("UnitPopup_OnClick", function(self)
	local button = self.value
	if button == "XRP_VIEW_CHARACTER" then
		xrp:ShowViewerCharacter(xrp:NameWithRealm(UIDROPDOWNMENU_INIT_MENU.name, UIDROPDOWNMENU_INIT_MENU.server))
	elseif button == "XRP_VIEW_UNIT" then
		xrp:ShowViewerUnit(UIDROPDOWNMENU_INIT_MENU.unit)
	end
end)
xrp:HookLoad(function()
	if settings.menus then
		-- Chat names and some other places.
		table.insert(UnitPopupMenus["FRIEND"], 5, "XRP_VIEW_CHARACTER")
		table.insert(UnitPopupMenus["FRIEND_OFFLINE"], 2, "INTERACT_SUBSECTION_TITLE")
		table.insert(UnitPopupMenus["FRIEND_OFFLINE"], 3, "XRP_VIEW_CHARACTER")
		-- Guild list.
		table.insert(UnitPopupMenus["GUILD"], 4, "XRP_VIEW_CHARACTER")
		table.insert(UnitPopupMenus["GUILD_OFFLINE"], 3, "XRP_VIEW_CHARACTER")
		-- Chat channel roster.
		table.insert(UnitPopupMenus["CHAT_ROSTER"], 3, "XRP_VIEW_CHARACTER")
	end
	if settings.unitmenus then
		-- Player target/misc.
		table.insert(UnitPopupMenus["PLAYER"], 6, "XRP_VIEW_UNIT")
		if UnitPopupMenus["PLAYER"][2] == "SET_FOCUS" then
			table.remove(UnitPopupMenus["PLAYER"], 2)
		end
		-- Player in party.
		table.insert(UnitPopupMenus["PARTY"], 6, "XRP_VIEW_UNIT")
		if UnitPopupMenus["PARTY"][2] == "SET_FOCUS" then
			table.remove(UnitPopupMenus["PARTY"], 2)
		end
		-- Player in raid.
		table.insert(UnitPopupMenus["RAID_PLAYER"], 3, "XRP_VIEW_UNIT")
		if UnitPopupMenus["RAID_PLAYER"][2] == "SET_FOCUS" then
			table.remove(UnitPopupMenus["RAID_PLAYER"], 2)
		end
	end
end)
