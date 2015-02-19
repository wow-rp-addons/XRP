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

-- This adds "Roleplay Profile" menu entries to several menus for a more
-- convenient way to access profiles (including chat names, guild lists, and
-- chat rosters).
--
-- Note: Cannot be added to menus which call protected functions without
-- causing taint problems. This includes all unit menus with a "SET_FOCUS"
-- button. The menus can be found in Blizzard's UnitPopups.lua.

local standard, units

local function UnitPopup_OnClick_Hook(self)
	if not standard and not units then return end
	if self.value == "XRP_VIEW_CHARACTER" then
		xrp:View(xrp:Name(UIDROPDOWNMENU_INIT_MENU.name, UIDROPDOWNMENU_INIT_MENU.server))
	elseif self.value == "XRP_VIEW_UNIT" then
		xrp:View(UIDROPDOWNMENU_INIT_MENU.unit)
	elseif self.value == "XRP_VIEW_BN" then
		local active, toonName, client, realmName = BNGetToonInfo(select(6, BNGetFriendInfoByID(UIDROPDOWNMENU_INIT_MENU.presenceID)))
		if client == "WoW" and realmName ~= "" then
			xrp:View(xrp:Name(toonName, realmName))
		end
	end
end

local function UnitPopup_HideButtons_Hook()
	if not standard or UIDROPDOWNMENU_INIT_MENU.which ~= "BN_FRIEND" then return end
	for i, button in ipairs(UnitPopupMenus["BN_FRIEND"]) do
		if button == "XRP_VIEW_BN" then
			if select(3, BNGetToonInfo(select(6, BNGetFriendInfoByID(UIDROPDOWNMENU_INIT_MENU.presenceID)))) ~= "WoW" then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 0
			else
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 1
			end
			break
		end
	end
end

local Buttons_Profile = { text = "Roleplay Profile", dist = 0 }

local isHooked
xrpPrivate.settingsToggles.menus = {
	standard = function(setting)
		if setting then
			if not isHooked then
				hooksecurefunc("UnitPopup_OnClick", UnitPopup_OnClick_Hook)
				isHooked = true
			end
			if standard == nil then
				hooksecurefunc("UnitPopup_HideButtons", UnitPopup_HideButtons_Hook)
				if UnitPopupMenus["FRIEND"][2] == "TARGET" then
					table.remove(UnitPopupMenus["FRIEND"], 2)
				end
				if UnitPopupMenus["GUILD"][1] == "TARGET" then
					table.remove(UnitPopupMenus["GUILD"], 1)
				end
				if UnitPopupMenus["CHAT_ROSTER"][1] == "TARGET" then
					table.remove(UnitPopupMenus["CHAT_ROSTER"], 1)
				end
				if UnitPopupMenus["BN_FRIEND"][2] == "BN_TARGET" then
					table.remove(UnitPopupMenus["BN_FRIEND"], 2)
				end
			end
			if not standard then
				UnitPopupButtons["XRP_VIEW_CHARACTER"] = Buttons_Profile
				UnitPopupButtons["XRP_VIEW_BN"] = Buttons_Profile
				table.insert(UnitPopupMenus["FRIEND"], 1, "XRP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["GUILD"], 1, "XRP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["CHAT_ROSTER"], 1, "XRP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["BN_FRIEND"], 1, "XRP_VIEW_BN")
			end
			standard = true
		elseif standard ~= nil then
			UnitPopupButtons["XRP_VIEW_CHARACTER"] = nil
			UnitPopupButtons["XRP_VIEW_BN"] = nil
			if UnitPopupMenus["FRIEND"][1] == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["FRIEND"], 1)
			end
			if UnitPopupMenus["GUILD"][1] == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["GUILD"], 1)
			end
			if UnitPopupMenus["CHAT_ROSTER"][1] == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["CHAT_ROSTER"], 1)
			end
			if UnitPopupMenus["BN_FRIEND"][1] == "XRP_VIEW_BN" then
				table.remove(UnitPopupMenus["BN_FRIEND"], 1)
			end
			standard = false
		end
	end,
	units = function(setting)
		if setting then
			if not isHooked then
				hooksecurefunc("UnitPopup_OnClick", UnitPopup_OnClick_Hook)
				isHooked = true
			end
			if units == nil then
				if UnitPopupMenus["PLAYER"][2] == "SET_FOCUS" then
					table.remove(UnitPopupMenus["PLAYER"], 2)
				end
				if UnitPopupMenus["PARTY"][2] == "SET_FOCUS" then
					table.remove(UnitPopupMenus["PARTY"], 2)
				end
				if UnitPopupMenus["RAID_PLAYER"][2] == "SET_FOCUS" then
					table.remove(UnitPopupMenus["RAID_PLAYER"], 2)
				end
			end
			if not units then
				UnitPopupButtons["XRP_VIEW_UNIT"] = Buttons_Profile
				table.insert(UnitPopupMenus["PLAYER"], 1, "XRP_VIEW_UNIT")
				table.insert(UnitPopupMenus["PARTY"], 1, "XRP_VIEW_UNIT")
				table.insert(UnitPopupMenus["RAID_PLAYER"], 1, "XRP_VIEW_UNIT")
			end
			units = true
		elseif units ~= nil then
			UnitPopupButtons["XRP_VIEW_UNIT"] = nil
			if UnitPopupMenus["PLAYER"][1] == "XRP_VIEW_UNIT" then
				table.remove(UnitPopupMenus["PLAYER"], 1)
			end
			if UnitPopupMenus["PARTY"][1] == "XRP_VIEW_UNIT" then
				table.remove(UnitPopupMenus["PARTY"], 1)
			end
			if UnitPopupMenus["RAID_PLAYER"][1] == "XRP_VIEW_UNIT" then
				table.remove(UnitPopupMenus["RAID_PLAYER"], 1)
			end
			units = false
		end
	end,
}
