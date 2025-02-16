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

local function GetBattleNetCharacterID(gameAccountInfo)
	local characterName = gameAccountInfo.characterName;
	local realmName = gameAccountInfo.realmName;
	local ambiguatedName;

	characterName = (characterName ~= "" and characterName or UNKNOWNOBJECT);
	realmName = (realmName ~= "" and realmName or GetNormalizedRealmName());
	ambiguatedName = Ambiguate(string.join("-", characterName, realmName), "none");

	if string.find(ambiguatedName, UNKNOWNOBJECT, 1, true) == 1 then
		ambiguatedName = nil;
	end

	return ambiguatedName;
end

local function ShouldShowOpenBattleNetProfile(contextData)
	local accountInfo = contextData.accountInfo;
	local gameAccountInfo = accountInfo and accountInfo.gameAccountInfo or nil;

	if not gameAccountInfo then
		return false;
	elseif gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW then
		return false;
	elseif gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID then
		return false;
	elseif not gameAccountInfo.isInCurrentRegion then
		return false;
	end

	local characterID = GetBattleNetCharacterID(gameAccountInfo);

	if not characterID then
		return false;
	else
		return true;
	end
end

for menuTagSuffix, buttonType in pairs(allowedUnits) do
	local function OnMenuOpen(owner, rootDescription, contextData)
		if not owner or owner:IsForbidden() then
			return nil;  -- Invalid or forbidden owner.
		elseif (menuTagSuffix == "CHAT_ROSTER" and not xrpAccountSaved.settings.menusChat or
				menuTagSuffix ~= "CHAT_ROSTER" and not xrpAccountSaved.settings.menusUnits) then
			return nil;  -- Disabled in settings.
		end

		rootDescription:QueueDivider();

		local OnClick;
		if buttonType == "player" then
			local unit = contextData.unit;
			local name = contextData.name;
			local server = contextData.server;
			local fullName = string.join("-", name or UNKNOWNOBJECT, server or GetNormalizedRealmName());

			local unitName;
			if UnitExists(unit) then
				unitName = unit;
			elseif not string.find(fullName, UNKNOWNOBJECT, 1, true) then
				unitName = fullName;
			else
				return nil;
			end

			OnClick = function(contextData)
				XRPViewer:View(unitName);
			end
		elseif buttonType == "bnet" then
			if not ShouldShowOpenBattleNetProfile(contextData) then
				return nil;
			end

			OnClick = function(contextData)
				local accountInfo = contextData.accountInfo;
				local gameAccountInfo = accountInfo and accountInfo.gameAccountInfo or nil;

				-- Only a basic sanity test is required here.
				if not gameAccountInfo then
					return;
				end

				local characterID = GetBattleNetCharacterID(gameAccountInfo);
				XRPViewer:View(characterID);
			end
		else
			return nil
		end

		local elementDescription = rootDescription:CreateButton(buttons[buttonType].text);
		elementDescription:SetResponder(OnClick);
		elementDescription:SetData(contextData);
		--return elementDescription;

		rootDescription:ClearQueuedDescriptions();
	end

	local menuTag = "MENU_UNIT_" .. menuTagSuffix;
	Menu.ModifyMenu(menuTag, OnMenuOpen);
end