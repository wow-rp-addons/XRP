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

-- This adds RP Profile menu entries to several menus for a more convenient
-- way to access profiles (including chat names, guild lists, and chat
-- rosters).
--
-- Note: Cannot be added to menus which call protected functions without
-- causing taint problems. This includes all unit menus with a "SET_FOCUS"
-- button. The menus can be found in Blizzard's UnitPopups.lua.

local function UnitPopup_Hook(self)
	local button = self.value
	if button == "XRP_VIEW_CHARACTER" then
		xrp:View(xrp:Name(UIDROPDOWNMENU_INIT_MENU.name, UIDROPDOWNMENU_INIT_MENU.server))
	elseif button == "XRP_VIEW_UNIT" then
		xrp:View(UIDROPDOWNMENU_INIT_MENU.unit)
	end
end

local Buttons_Profile = { text = "Roleplay Profile", dist = 0 }

local isHooked, standard, units
xrpPrivate.settingsToggles.menus = {
	standard = function(setting)
		if setting then
			if not isHooked then
				hooksecurefunc("UnitPopup_OnClick", UnitPopup_Hook)
				isHooked = true
			end
			if standard == nil then
				if UnitPopupMenus["FRIEND"][2] == "TARGET" then
					table.remove(UnitPopupMenus["FRIEND"], 2)
				end
				if UnitPopupMenus["GUILD"][1] == "TARGET" then
					table.remove(UnitPopupMenus["GUILD"], 1)
				end
				if UnitPopupMenus["CHAT_ROSTER"][1] == "TARGET" then
					table.remove(UnitPopupMenus["CHAT_ROSTER"], 1)
				end
			end
			if not standard then
				UnitPopupButtons["XRP_VIEW_CHARACTER"] = Buttons_Profile
				table.insert(UnitPopupMenus["FRIEND"], 1, "XRP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["GUILD"], 1, "XRP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["CHAT_ROSTER"], 1, "XRP_VIEW_CHARACTER")
			end
			standard = true
		elseif standard ~= nil then
			UnitPopupButtons["XRP_VIEW_CHARACTER"] = nil
			if UnitPopupMenus["FRIEND"][1] == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["FRIEND"], 1)
			end
			if UnitPopupMenus["GUILD"][1] == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["GUILD"], 1)
			end
			if UnitPopupMenus["CHAT_ROSTER"][1] == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["CHAT_ROSTER"], 1)
			end
			standard = false
		end
	end,
	units = function(setting)
		if setting then
			if not isHooked then
				hooksecurefunc("UnitPopup_OnClick", UnitPopup_Hook)
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
