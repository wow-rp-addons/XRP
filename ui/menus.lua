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

local BNGetGameAccountInfo = BNGetGameAccountInfo
local bnetIDAccount = "bnetIDAccount"
if not BNGetGameAccountInfo then
	BNGetGameAccountInfo = BNGetToonInfo
	bnetIDAccount = "presenceID"
end

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
		XRPViewer:View(xrp.FullName(UIDROPDOWNMENU_INIT_MENU.name, UIDROPDOWNMENU_INIT_MENU.server))
	elseif self.value == "XRP_VIEW_UNIT" then
		XRPViewer:View(UIDROPDOWNMENU_INIT_MENU.unit)
	elseif self.value == "XRP_VIEW_BN" then
		local active, characterName, client, realmName = BNGetGameAccountInfo(select(6, BNGetFriendInfoByID(UIDROPDOWNMENU_INIT_MENU[bnetIDAccount])))
		if client == BNET_CLIENT_WOW and realmName ~= "" then
			XRPViewer:View(xrp.FullName(characterName, realmName))
		end
	end
end

local function UnitPopup_HideButtons_Hook()
	if not standard or UIDROPDOWNMENU_INIT_MENU.which ~= "BN_FRIEND" or UIDROPDOWNMENU_MENU_VALUE and UIDROPDOWNMENU_MENU_VALUE ~= "BN_FRIEND" then return end
	for i, button in ipairs(UnitPopupMenus["BN_FRIEND"]) do
		if button == "XRP_VIEW_BN" then
			if not UIDROPDOWNMENU_INIT_MENU[bnetIDAccount] then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 0
			else
				local active, characterName, client, realmName = BNGetGameAccountInfo(select(6, BNGetFriendInfoByID(UIDROPDOWNMENU_INIT_MENU[bnetIDAccount])))
				if client ~= BNET_CLIENT_WOW or realmName == "" then
					UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 0
				else
					UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 1
				end
			end
			break
		end
	end
end

local Buttons_Profile = { text = _xrp.L.ROLEPLAY_PROFILE, dist = 0 }

local isHooked
_xrp.settingsToggles.menus = {
	standard = function(setting)
		if setting then
			if not isHooked then
				hooksecurefunc("UnitPopup_OnClick", UnitPopup_OnClick_Hook)
				isHooked = true
			end
			if standard == nil then
				hooksecurefunc("UnitPopup_HideButtons", UnitPopup_HideButtons_Hook)
				for i, button in ipairs(UnitPopupMenus["FRIEND"]) do
					if button == "TARGET" or button == "PVP_REPORT_AFK" then
						table.remove(UnitPopupMenus["FRIEND"], i)
					end
				end
				for i, button in ipairs(UnitPopupMenus["GUILD"]) do
					if button == "TARGET" then
						table.remove(UnitPopupMenus["GUILD"], i)
						break
					end
				end
				for i, button in ipairs(UnitPopupMenus["CHAT_ROSTER"]) do
					if button == "TARGET" then
						table.remove(UnitPopupMenus["CHAT_ROSTER"], i)
						break
					end
				end
				for i, button in ipairs(UnitPopupMenus["BN_FRIEND"]) do
					if button == "BN_TARGET" then
						table.remove(UnitPopupMenus["BN_FRIEND"], i)
						break
					end
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
			for i, button in ipairs(UnitPopupMenus["FRIEND"]) do
				if button == "XRP_VIEW_CHARACTER" then
					table.remove(UnitPopupMenus["FRIEND"], i)
					break
				end
			end
			for i, button in ipairs(UnitPopupMenus["GUILD"]) do
				if button == "XRP_VIEW_CHARACTER" then
					table.remove(UnitPopupMenus["GUILD"], i)
					break
				end
			end
			for i, button in ipairs(UnitPopupMenus["CHAT_ROSTER"]) do
				if button == "XRP_VIEW_CHARACTER" then
					table.remove(UnitPopupMenus["CHAT_ROSTER"], i)
					break
				end
			end
			for i, button in ipairs(UnitPopupMenus["BN_FRIEND"]) do
				if button == "XRP_VIEW_BN" then
					table.remove(UnitPopupMenus["BN_FRIEND"], i)
					break
				end
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
				for i, button in ipairs(UnitPopupMenus["PLAYER"]) do
					if button == "SET_FOCUS" then
						table.remove(UnitPopupMenus["PLAYER"], i)
						break
					end
				end
				for i, button in ipairs(UnitPopupMenus["PARTY"]) do
					if button == "SET_FOCUS" or button == "PVP_REPORT_AFK" then
						table.remove(UnitPopupMenus["PARTY"], i)
					end
				end
				for i, button in ipairs(UnitPopupMenus["RAID_PLAYER"]) do
					if button == "SET_FOCUS" or button == "PVP_REPORT_AFK" then
						table.remove(UnitPopupMenus["RAID_PLAYER"], i)
					end
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
			for i, button in ipairs(UnitPopupMenus["PLAYER"]) do
				if button == "XRP_VIEW_UNIT" then
					table.remove(UnitPopupMenus["PLAYER"], i)
					break
				end
			end
			for i, button in ipairs(UnitPopupMenus["PARTY"]) do
				if button == "XRP_VIEW_UNIT" then
					table.remove(UnitPopupMenus["PARTY"], i)
					break
				end
			end
			for i, button in ipairs(UnitPopupMenus["RAID_PLAYER"]) do
				if button == "XRP_VIEW_UNIT" then
					table.remove(UnitPopupMenus["RAID_PLAYER"], i)
					break
				end
			end
			units = false
		end
	end,
}
