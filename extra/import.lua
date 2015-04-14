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

local hasMRP, hasTRP2, hasTRP3 = (IsAddOnLoaded("MyRolePlay")), (IsAddOnLoaded("totalRP2")), (IsAddOnLoaded("totalRP3"))
if not (hasMRP or hasTRP2 or hasTRP3) then return end

local addonName, xrpLocal = ...
local _S = xrpLocal.strings

local MRP_NO_IMPORT = { TT = true, VA = true, VP = true, GC = true, GF = true, GR = true, GS = true, GU = true }

StaticPopupDialogs["XRP_IMPORT_RELOAD"] = {
	text = _S.IMPORT_RELOAD,
	button1 = RELOADUI,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
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
		local profile = xrp.profiles:Add("MRP-" .. profileName)
		if profile then
			importedList[#importedList + 1] = tostring(profile)
			for field, value in pairs(oldProfile) do
				if not MRP_NO_IMPORT[field] and field:find("^%u%u$") then
					if field == "FC" then
						if not tonumber(value) and value ~= "" then
							value = "2"
						elseif value == "0" then
							value = ""
						end
					elseif field == "FR" and tonumber(value) then
						value = value ~= "0" and xrp.values.FR[value] or ""
					end
					profile.fields[field] = value ~= "" and value or nil
				end
			end
			imported = imported + 1
		end
	end
	for i, name in ipairs(importedList) do
		if name ~= "MRP-Default" then
			xrp.profiles[name].parent = "MRP-Default"
		end
	end
	return imported
end

local ImportTotalRP2
do
	local TRP2_HEIGHT = {
		[1] = _S.HEIGHT_VSHORT,
		[2] = _S.HEIGHT_SHORT,
		[3] = _S.HEIGHT_AVERAGE,
		[4] = _S.HEIGHT_TALL,
		[5] = _S.HEIGHT_VTALL,
	}
	local TRP2_WEIGHT = {
		[1] = _S.WEIGHT_HEAVY,
		[2] = _S.WEIGHT_REGULAR,
		[3] = _S.WEIGHT_MUSCULAR,
		[4] = _S.WEIGHT_SKINNY,
	}
	-- This is a bit more complex. And partly in French.
	function ImportTotalRP2()
		if not TRP2_Module_PlayerInfo then
			return 0
		end
		local profile = xrp.profiles:Add("TRP2")
		if not profile then
			return 0
		end
		local realm = GetRealmName()
		local oldProfile = TRP2_Module_PlayerInfo[realm][xrpLocal.player]
		if oldProfile.Actu then
			profile.fields.CU = oldProfile.Actu.ActuTexte
			profile.fields.FC = oldProfile.Actu.StatutRP and oldProfile.Actu.StatutRP ~= 0 and tostring(oldProfile.Actu.StatutRP) or nil
		end
		local DE = {}
		if oldProfile.Registre and oldProfile.Registre.TraitVisage then
			DE[#DE + 1] = _S.IMPORT_FACE:format(oldProfile.Registre.TraitVisage)
		end
		if oldProfile.Registre and oldProfile.Registre.Piercing then
			DE[#DE + 1] = _S.IMPORT_MODS:format(oldProfile.Registre.Piercing)
		end
		if oldProfile.Physique and oldProfile.Physique.PhysiqueTexte then
			DE[#DE + 1] = oldProfile.Physique.PhysiqueTexte
		end
		profile.fields.DE = table.concat(DE, "\n\n")
		if oldProfile.Histoire then
			profile.fields.HI = oldProfile.Histoire.HistoireTexte
		end
		if oldProfile.Registre then
			do
				local NA = ("%s %s"):format(oldProfile.Registre.Prenom or "", oldProfile.Registre.Nom or ""):trim()
				profile.fields.NA = NA ~= "" and NA or nil
			end
			profile.fields.RA = oldProfile.Registre.RacePerso
			profile.fields.RC = oldProfile.Registre.ClassePerso
			profile.fields.AE = oldProfile.Registre.YeuxVisage
			do
				local NT = ("%s | %s"):format(oldProfile.Registre.Titre or "", oldProfile.Registre.TitreComplet or ""):trim(" |")
				profile.fields.NT = NT ~= "" and NT or nil
			end
			profile.fields.AG = oldProfile.Registre.Age
			profile.fields.HH = oldProfile.Registre.Habitation
			profile.fields.HB = oldProfile.Registre.Origine
			profile.fields.AH = TRP2_HEIGHT[oldProfile.Registre.Taille or 3]
			profile.fields.AW = TRP2_WEIGHT[oldProfile.Registre.Silhouette or 2]
		end
		return 1
	end
end

-- They really like intricate data structures.
local function ImportTotalRP3()
	if not TRP3_Profiles or not TRP3_Characters then
		return 0
	end
	local oldProfile = TRP3_Profiles[TRP3_Characters[xrpLocal.playerWithRealm].profileID]
	if not oldProfile then
		return 0
	end
	local profile = xrp.profiles:Add("TRP3-" .. oldProfile.profileName)
	if not profile then
		return 0
	end
	do
		local NA = {}
		NA[#NA + 1] = oldProfile.player.characteristics.TI
		NA[#NA + 1] = oldProfile.player.characteristics.FN or xrpLocal.player
		NA[#NA + 1] = oldProfile.player.characteristics.LN
		profile.fields.NA = table.concat(NA, " ")
	end
	profile.fields.NT = oldProfile.player.characteristics.FT
	profile.fields.AG = oldProfile.player.characteristics.AG
	profile.fields.RA = oldProfile.player.characteristics.RA
	profile.fields.RC = oldProfile.player.characteristics.CL
	profile.fields.AW = oldProfile.player.characteristics.WE
	profile.fields.AH = oldProfile.player.characteristics.HE
	profile.fields.HH = oldProfile.player.characteristics.RE
	profile.fields.HB = oldProfile.player.characteristics.BP
	profile.fields.AE = oldProfile.player.characteristics.EC
	if oldProfile.player.characteristics.MI then
		local NI, NH, MO = {}, {}, {}
		for i, custom in ipairs(oldProfile.player.characteristics.MI) do
			if custom.NA == _S.TRP3_NICKNAME then
				NI[#NI + 1] = custom.VA
			elseif custom.NA == _S.TRP3_HOUSE_NAME then
				NH[#NH + 1] = custom.VA
			elseif custom.NA == _S.TRP3_MOTTO then
				MO[#MO + 1] = custom.VA
			end
		end
		profile.fields.NI = table.concat(NI, " | ")
		profile.fields.NH = table.concat(NH, " | ")
		profile.fields.MO = table.concat(MO, " | ")
	end
	do
		local CU = {}
		CU[#CU + 1] = oldProfile.player.character.CU
		if oldProfile.player.character.CO then
			CU[#CU + 1] = ("((%s))"):format(oldProfile.player.character.CO)
		end
		profile.fields.CU = table.concat(CU, " ")
	end
	profile.fields.FC = tostring(oldProfile.player.character.RP)
	if oldProfile.player.about.TE == 1 then
		profile.fields.DE = oldProfile.player.about["T1"].TX
	elseif oldProfile.player.about.TE == 2 then
		local DE = {}
		for i, block in ipairs(oldProfile.player.about["T2"]) do
			DE[#DE + 1] = block.TX
		end
		profile.fields.DE = table.concat(DE, "\n\n")
	elseif oldProfile.player.about.TE == 3 then
		local HI = {}
		profile.fields.DE = oldProfile.player.about["T3"].PH.TX
		HI[#HI + 1] = oldProfile.player.about["T3"].PS.TX
		HI[#HI + 1] = oldProfile.player.about["T3"].HI.TX
		profile.fields.HI = table.concat(HI, "\n\n")
	end
	return 1
end

xrpLocal:HookGameEvent("PLAYER_LOGIN", function(event)
	local imported = false
	if hasMRP then
		local count = ImportMyRolePlay()
		if count > 0 then
			DisableAddOn("MyRolePlay", xrpLocal.player)
			imported = true
		end
	end
	if hasTRP2 then
		local count = ImportTotalRP2()
		if count > 0 then
			DisableAddOn("totalRP2", xrpLocal.player)
			imported = true
		end
	end
	if hasTRP3 then
		local count = ImportTotalRP3()
		if count > 0 then
			DisableAddOn("totalRP3", xrpLocal.player)
			imported = true
		end
	end
	if imported then
		StaticPopup_Show("XRP_IMPORT_RELOAD")
	end
end)
