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

local hasMRP, hasTRP3 = (C_AddOns.GetAddOnEnableState(AddOn.characterName, "MyRolePlay") == 2), (C_AddOns.GetAddOnEnableState(AddOn.characterName, "totalRP3") == 2)
if not (hasMRP or hasTRP3) then return end

local MRP_NO_IMPORT = { TT = true, VA = true, VP = true, GC = true, GF = true, GR = true, GS = true, GU = true }

StaticPopupDialogs["XRP_IMPORT_RELOAD"] = {
	text = L"Available profiles have been imported and may be found in the XRP editor's profile list.\n\n|cffdd380fYou should disable any RP addons you don't wish to use and then reload your UI.|r",
	button1 = OKAY,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	cancels = "XRP_MSP_DISABLE",
}

-- This is easy. Using a very similar storage format (i.e., MSP fields).
local function ImportMyRolePlay()
	if not mrpSaved then
		return 0
	end
	local imported = 0
	local importedList = {}
	for profileName, oldProfile in pairs(mrpSaved.Profiles) do
		local newName = "MRP-" .. profileName
		if not AddOn_XRP.Profiles[newName] then
			AddOn_XRP.AddProfile(newName)
			local profile = AddOn_XRP.Profiles[newName]
			importedList[#importedList + 1] = profile
			for field, value in pairs(oldProfile) do
				if not MRP_NO_IMPORT[field] and field:find("^%u%u$") then
					if field == "FC" then
						if not tonumber(value) and value ~= "" then
							value = "2"
						elseif value == "0" then
							value = ""
						end
					elseif field == "FR" and tonumber(value) then
						value = AddOn_XRP.Strings.Values.FR[value] or ""
					end
					profile.Field[field] = value ~= "" and value or nil
				end
			end
			imported = imported + 1
		end
	end
	for i, profile in ipairs(importedList) do
		if profile:IsParentValid("MRP-Default") then
			profile.parent = "MRP-Default"
		end
	end
	return imported
end

-- They really like intricate data structures.
local function ImportTotalRP3()
	if not TRP3_Profiles or not TRP3_Characters then
		return 0
	end
	local oldProfile = TRP3_Profiles[TRP3_Characters[AddOn.characterID].profileID]
	if not oldProfile then
		return 0
	end
	local newName = "TRP3-" .. oldProfile.profileName
	if AddOn_XRP.Profiles[newName] then
		return 0
	end

	AddOn_XRP.AddProfile(newName)
	local profile = AddOn_XRP.Profiles[newName]

	local NA = {}
	NA[#NA + 1] = oldProfile.player.characteristics.TI
	NA[#NA + 1] = oldProfile.player.characteristics.FN or AddOn.characterName
	NA[#NA + 1] = oldProfile.player.characteristics.LN
	profile.Field.NA = table.concat(NA, " ")
	profile.Field.NT = oldProfile.player.characteristics.FT
	profile.Field.AG = oldProfile.player.characteristics.AG
	profile.Field.RA = oldProfile.player.characteristics.RA
	profile.Field.RC = oldProfile.player.characteristics.CL
	profile.Field.AW = oldProfile.player.characteristics.WE
	profile.Field.AH = oldProfile.player.characteristics.HE
	profile.Field.HH = oldProfile.player.characteristics.RE
	profile.Field.HB = oldProfile.player.characteristics.BP
	profile.Field.AE = oldProfile.player.characteristics.EC
	if oldProfile.player.characteristics.MI then
		local NI, NH, MO = {}, {}, {}
		for i, custom in ipairs(oldProfile.player.characteristics.MI) do
			if custom.NA == L.TRP3_NICKNAME then
				NI[#NI + 1] = custom.VA
			elseif custom.NA == L.TRP3_HOUSE_NAME then
				NH[#NH + 1] = custom.VA
			elseif custom.NA == L.TRP3_MOTTO then
				MO[#MO + 1] = custom.VA
			end
		end
		profile.Field.NI = table.concat(NI, " | ")
		profile.Field.NH = table.concat(NH, " | ")
		profile.Field.MO = table.concat(MO, " | ")
	end
	profile.Field.CU = oldProfile.player.character.CU
	profile.Field.CO = oldProfile.player.character.CO
	profile.Field.FC = tostring(oldProfile.player.character.RP)
	if oldProfile.player.about.TE == 1 then
		profile.Field.DE = oldProfile.player.about["T1"].TX
	elseif oldProfile.player.about.TE == 2 then
		local DE = {}
		for i, block in ipairs(oldProfile.player.about["T2"]) do
			DE[#DE + 1] = block.TX
		end
		profile.Field.DE = table.concat(DE, "\n\n")
	elseif oldProfile.player.about.TE == 3 then
		local HI = {}
		profile.Field.DE = oldProfile.player.about["T3"].PH.TX
		HI[#HI + 1] = oldProfile.player.about["T3"].PS.TX
		HI[#HI + 1] = oldProfile.player.about["T3"].HI.TX
		profile.Field.HI = table.concat(HI, "\n\n")
	end
	return 1
end

AddOn.RegisterGameEventCallback("PLAYER_LOGIN", function(event)
	local imported = false
	if hasMRP and select(2, C_AddOns.IsAddOnLoaded("MyRolePlay")) then
		local count = ImportMyRolePlay()
		if count > 0 then
			imported = true
		end
	end
	if hasTRP3 and select(2, C_AddOns.IsAddOnLoaded("totalRP3")) then
		local count = ImportTotalRP3()
		if count > 0 then
			imported = true
		end
	end
	if imported then
		StaticPopup_Show("XRP_IMPORT_RELOAD")
	end
end)
