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
do
	local mouseover, profile, friendly, clicking, mountable
	do
		local now
		hooksecurefunc("TurnOrActionStart", function()
			if not settings.rightclick then return end
			now = GetTime()
			clicking = true
		end)
		hooksecurefunc("TurnOrActionStop", function()
			-- 0.75s interaction time is guessed as Blizzard number from
			-- in-game testing. Used for consistency.
			-- TODO: Deal with CheckInteractDistance and UnitVehicleSeatCount > 0
			if settings.rightclick and profile and GetTime() - now < 0.75 and mouseover == xrp:UnitNameWithRealm("target") then
				local mountrange = (UnitInParty("mouseover") or UnitInRaid("mouseover")) and IsItemInRange(88589, "mouseover") == 1
				if mountable and not mountrange then
					UIErrorsFrame:Clear() -- Hides errors on inteactable mount players.
					xrp:ShowViewerUnit("target")
				elseif not mountable then
					xrp:ShowViewerUnit("target")
				end
			end
			clicking = false
		end)
	end
	local cursor = CreateFrame("Frame", nil, UIParent)
	cursor:SetFrameStrata("TOOLTIP")
	cursor:SetWidth(24)
	cursor:SetHeight(24)
	do
		local cursorimage = cursor:CreateTexture(nil, "BACKGROUND")
		--cursorimage:SetTexture("Interface\\CURSOR\\Trainer")
		cursorimage:SetTexture("Interface\\MINIMAP\\TRACKING\\Class")
		cursorimage:SetAllPoints(cursor)
	end
	cursor:Hide()
	xrp:HookEvent("MSP_RECEIVE", function(name)
		if settings.rightclick and not profile and friendly and name == xrp:UnitNameWithRealm("mouseover") then
			profile = true
			cursor:Show()
		end
	end)
	cursor:SetScript("OnEvent", function(self, event)
		if not settings.rightclick or GetMouseFocus() ~= WorldFrame then
			return
		end
		mouseover = xrp:UnitNameWithRealm("mouseover")
		if xrp.units.mouseover and xrp.units.mouseover.VA and not InCombatLockdown() then
			friendly = not UnitCanAttack("player", "mouseover")
			mountable = UnitVehicleSeatCount("mouseover") > 0
			local mountrange = (UnitInParty("mouseover") or UnitInRaid("mouseover")) and IsItemInRange(88589, "mouseover") == 1
			profile = friendly and not (mountable and mountrange)
			self:Show()
		else
			profile = false
			self:Hide()
		end
	end)
	do
		local previousX, previousY
		--IsItemInRange(88589, "mouseover")
		-- Crazy optimization crap since it's run every frame.
		local UnitExists, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, UIParent, GetEffectiveScale = UnitExists, InCombatLockdown, GetMouseFocus, WorldFrame, GetCursorPosition, UIParent, UIParent.GetEffectiveScale
		cursor:SetScript("OnUpdate", function(self, elapsed)
			if not UnitExists("mouseover") or InCombatLockdown() then
				profile = profile and clicking
				self:Hide()
				return
			elseif GetMouseFocus() ~= WorldFrame then
				profile = false
				self:Hide()
				return
			end
			local x, y = GetCursorPosition()
			if x == previousX and y == previousY then return end
			if IsItemInRange(88589, "mouseover") then
				profile = false
				self:Hide()
				return
			end
			local scale = GetEffectiveScale(UIParent)
			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale + 36, y/scale - 4)
			previousX, previousY = x, y
		end)
	end
	cursor:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

-- Interact keybind integration
--
-- Permits using the Blizzard interact with mouseover/target keybindings as
-- RP profile view bindings. Don't do it for hostile targets -- interact keybinds
-- start attack there.
hooksecurefunc("InteractUnit", function(unit)
	-- TODO: Deal with CheckInteractDistance and UnitVehicleSeatCount > 0
	if not settings.interact or UnitCanAttack("player", unit) then return end
	local mountable = UnitVehicleSeatCount(unit) > 0
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
			text = text:gsub("%%xt", UnitExists("target") and (xrp.units.target and xrp.units.target.NA or UnitName("target")) or xrp.L["nobody"])
		end
		if text:find("%xf", nil, true) then
			text = text:gsub("%%xf", UnitExists("focus") and (xrp.units.focus and xrp.units.focus.NA or UnitName("focus")) or xrp.L["nobody"])
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
UnitPopupButtons["XRP_VIEW_CHARACTER"] = { text = xrp.L["RP Profile"], dist = 0 }
UnitPopupButtons["XRP_VIEW_UNIT"] = { text = xrp.L["RP Profile"], dist = 0 }

hooksecurefunc("UnitPopup_OnClick", function(self)
	if self.value == "XRP_VIEW_CHARACTER" then
		xrp:ShowViewerCharacter(xrp:NameWithRealm(UIDROPDOWNMENU_INIT_MENU.name, UIDROPDOWNMENU_INIT_MENU.server))
	elseif self.value == "XRP_VIEW_UNIT" then
		xrp:ShowViewerUnit(UIDROPDOWNMENU_INIT_MENU.unit)
	end
end)
xrp:HookLoad(function()
	if settings.menus then
		-- Chat names and some other places.
		table.insert(UnitPopupMenus["FRIEND"], 3, "XRP_VIEW_CHARACTER")
		table.insert(UnitPopupMenus["FRIEND_OFFLINE"], 1, "XRP_VIEW_CHARACTER")
		-- Guild list.
		table.insert(UnitPopupMenus["GUILD"], 3, "XRP_VIEW_CHARACTER")
		table.insert(UnitPopupMenus["GUILD_OFFLINE"], 2, "XRP_VIEW_CHARACTER")
		-- Chat channel roster.
		table.insert(UnitPopupMenus["CHAT_ROSTER"], 2, "XRP_VIEW_CHARACTER")
	end
	if settings.unitmenus then
		-- Player target/misc.
		table.insert(UnitPopupMenus["PLAYER"], 5, "XRP_VIEW_UNIT")
		if UnitPopupMenus["PLAYER"][3] == "SET_FOCUS" then
			table.remove(UnitPopupMenus["PLAYER"], 3)
		end
		-- Player in party.
		table.insert(UnitPopupMenus["PARTY"], 13, "XRP_VIEW_UNIT")
		if UnitPopupMenus["PARTY"][3] == "SET_FOCUS" then
			table.remove(UnitPopupMenus["PARTY"], 3)
		end
		-- Player in raid.
		table.insert(UnitPopupMenus["RAID_PLAYER"], 11, "XRP_VIEW_UNIT")
		if UnitPopupMenus["RAID_PLAYER"][3] == "SET_FOCUS" then
			table.remove(UnitPopupMenus["RAID_PLAYER"], 3)
		end
	end
end)
