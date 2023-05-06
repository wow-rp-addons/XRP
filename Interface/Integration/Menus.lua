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
local L = AddOn.GetText

local LibDropDownExtension = LibStub:GetLibrary("LibDropDownExtension-1.0");

-- This adds "Roleplay Profile" menu entries to several menus for a more
-- convenient way to access profiles (including chat names, guild lists, and
-- chat rosters).

local function OpenPlayerProfile()
	if UnitExists(UIDROPDOWNMENU_INIT_MENU.unit) then
		XRPViewer:View(UIDROPDOWNMENU_INIT_MENU.unit)
	else
		XRPViewer:View(AddOn_Chomp.NameMergedRealm(UIDROPDOWNMENU_INIT_MENU.name, UIDROPDOWNMENU_INIT_MENU.server))
	end
end

local function OpenBNetProfile()
	local gameAccountInfo = C_BattleNet.GetAccountInfoByID(UIDROPDOWNMENU_INIT_MENU.bnetIDAccount).gameAccountInfo;
	local characterName = gameAccountInfo.characterName or "";
	local client = gameAccountInfo.clientProgram;
	local realmName = gameAccountInfo.realmName or "";
	if client == BNET_CLIENT_WOW and realmName ~= "" then
		XRPViewer:View(AddOn_Chomp.NameMergedRealm(characterName, realmName))
	end
end

local buttons = {
	player = {text = L.ROLEPLAY_PROFILE, func = OpenPlayerProfile, notCheckable = true},
	bnet = {text = L.ROLEPLAY_PROFILE, func = OpenBNetProfile, notCheckable = true},
}

local allowedUnits = {
	CHAT_ROSTER = "player",
	FRIEND = "player",
	FRIEND_OFFLINE = "player",
	BN_FRIEND = "bnet",
	GUILD = "player",
	GUILD_OFFLINE = "player",
	PARTY = "player",
	PLAYER = "player",
	RAID = "player",
	RAID_PLAYER = "player",
}

local function UnitPopup_OnShowMenu_Hook(dropdownMenu, _, options)
	if not dropdownMenu or dropdownMenu:IsForbidden() then
		return  -- Invalid or forbidden menu.
	elseif UIDROPDOWNMENU_MENU_LEVEL ~= 1 then
		return  -- We don't support submenus.
	end

	table.wipe(options);

	local menuType = dropdownMenu.which
	if not allowedUnits[menuType] then
		return  -- No buttons to be shown.
	end

	if menuType == "BN_FRIEND" then
		if not UIDROPDOWNMENU_INIT_MENU.bnetIDAccount then
			return
		else
			local gameAccountInfo = C_BattleNet.GetAccountInfoByID(UIDROPDOWNMENU_INIT_MENU.bnetIDAccount).gameAccountInfo
			local client = gameAccountInfo.clientProgram
			local realmName = gameAccountInfo.realmName or ""
			if client ~= BNET_CLIENT_WOW or realmName == "" then
				return
			end
		end
	end

	if UnitExists(UIDROPDOWNMENU_INIT_MENU.unit) then
		if not xrpAccountSaved.settings.menusUnits then
			return
		end
	else
		if not xrpAccountSaved.settings.menusChat then
			return
		end
	end

	table.insert(options, buttons[allowedUnits[menuType]]);

	return true;
end

LibDropDownExtension:RegisterEvent("OnShow", UnitPopup_OnShowMenu_Hook, MAX_DROPDOWN_LEVEL);