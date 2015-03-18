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

local MRP_NO_IMPORT = { TT = true, VA = true, VP = true, GC = true, GF = true, GR = true, GS = true, GU = true }

StaticPopupDialogs["XRP_IMPORT_RELOAD"] = {
	text = "Available profiles have been imported and may be found in the editor's profile list. You should reload your UI now.",
	button1 = "Reload UI",
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
	for profileName, profile in pairs(mrpSaved.Profiles) do
		local newProfileName = "MRP-" .. profileName
		if xrpLocal.profiles:Add(newProfileName) then
			for field, value in pairs(profile) do
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
					xrpLocal.profiles[newProfileName].fields[field] = value ~= "" and value or nil
				end
			end
			if newProfileName ~= "MRP-Default" then
				xrpSaved.profiles[newProfileName].parent = "MRP-Default"
			end
			imported = imported + 1
		end
	end
	return imported
end

local ImportTotalRP2
do
	local TRP2_HEIGHT = {
		"Very short",
		"Short",
		"Average",
		"Tall",
		"Very tall",
	}
	local TRP2_WEIGHT = {
		"Overweight",
		"Regular",
		"Muscular",
		"Skinny",
	}

	-- This is a bit more complex. And partly in French.
	function ImportTotalRP2()
		if not TRP2_Module_PlayerInfo or not xrpLocal.profiles:Add("TRP2") then
			return 0
		end
		local realm = GetRealmName()
		local profile = TRP2_Module_PlayerInfo[realm][xrpLocal.player]
		if profile.Actu then
			xrpLocal.profiles["TRP2"].fields.CU = profile.Actu.ActuTexte
			xrpLocal.profiles["TRP2"].fields.FC = profile.Actu.StatutRP and profile.Actu.StatutRP ~= 0 and tostring(profile.Actu.StatutRP) or nil
		end
		local DE = ""
		if profile.Registre and profile.Registre.TraitVisage then
			DE = ("%sFace: %s\n\n"):format(DE, profile.Registre.TraitVisage)
		end
		if profile.Registre and profile.Registre.Piercing then
			DE = ("%sPiercings/Tattoos: %s\n\n"):format(DE, profile.Registre.Piercing)
		end
		if profile.Physique and profile.Physique.PhysiqueTexte then
			DE = DE .. profile.Physique.PhysiqueTexte
		end
		xrpLocal.profiles["TRP2"].fields.DE = DE ~= "" and DE:match("^(.-)\n+$") or nil
		if profile.Histoire then
			xrpLocal.profiles["TRP2"].fields.HI = profile.Histoire.HistoireTexte
		end
		if profile.Registre then
			do
				local NA = ("%s %s"):format(profile.Registre.Prenom or "", profile.Registre.Nom or ""):trim()
				xrpLocal.profiles["TRP2"].fields.NA = NA ~= "" and NA or nil
			end
			xrpLocal.profiles["TRP2"].fields.RA = profile.Registre.RacePerso
			xrpLocal.profiles["TRP2"].fields.RC = profile.Registre.ClassePerso
			xrpLocal.profiles["TRP2"].fields.AE = profile.Registre.YeuxVisage
			do
				local NT = ("%s | %s"):format(profile.Registre.Titre or "", profile.Registre.TitreComplet or ""):match("^[%s|]*(.-)[%s|]*$")
				xrpLocal.profiles["TRP2"].fields.NT = NT ~= "" and NT or nil
			end
			xrpLocal.profiles["TRP2"].fields.AG = profile.Registre.Age
			xrpLocal.profiles["TRP2"].fields.HH = profile.Registre.Habitation
			xrpLocal.profiles["TRP2"].fields.HB = profile.Registre.Origine
			xrpLocal.profiles["TRP2"].fields.AH = TRP2_HEIGHT[profile.Registre.Taille or 3]
			xrpLocal.profiles["TRP2"].fields.AW = TRP2_WEIGHT[profile.Registre.Silhouette or 2]
		end
		return 1
	end
end

-- They really like intricate data structures.
local function ImportTotalRP3()
	if not TRP3_Profiles or not TRP3_Characters then
		return 0
	end
	local toImport = TRP3_Profiles[TRP3_Characters[xrpLocal.playerWithRealm].profileID]
	if not toImport then
		return 0
	end
	local profileName = "TRP3-" .. toImport.profileName
	if not xrpLocal.profiles:Add(profileName) then
		return 0
	end
	local profile = xrpLocal.profiles[profileName].fields
	do
		local NA = {}
		NA[#NA + 1] = toImport.player.characteristics.TI
		NA[#NA + 1] = toImport.player.characteristics.FN or xrpLocal.player
		NA[#NA + 1] = toImport.player.characteristics.LN
		profile.NA = table.concat(NA, " ")
	end
	profile.NT = toImport.player.characteristics.FT
	profile.AG = toImport.player.characteristics.AG
	profile.RA = toImport.player.characteristics.RA
	profile.RC = toImport.player.characteristics.CL
	profile.AW = toImport.player.characteristics.WE
	profile.AH = toImport.player.characteristics.HE
	profile.HH = toImport.player.characteristics.RE
	profile.HB = toImport.player.characteristics.BP
	profile.AE = toImport.player.characteristics.EC
	if toImport.player.characteristics.MI then
		local NI, NH, MO = {}, {}, {}
		for i, custom in ipairs(toImport.player.characteristics.MI) do
			if custom.NA == "Nickname" then
				NI[#NI + 1] = custom.VA
			elseif custom.NA == "House name" then
				NH[#NH + 1] = custom.VA
			elseif custom.NA == "Motto" then
				MO[#MO + 1] = custom.VA
			end
		end
		profile.NI = table.concat(NI, " | ")
		profile.NH = table.concat(NH, " | ")
		profile.MO = table.concat(MO, " | ")
	end
	do
		local CU = {}
		CU[#CU + 1] = toImport.player.character.CU
		if toImport.player.character.CO then
			CU[#CU + 1] = ("((%s))"):format(toImport.player.character.CO)
		end
		profile.CU = table.concat(CU, " ")
	end
	profile.FC = tostring(toImport.player.character.RP)
	if toImport.player.about.TE == 1 then
		profile.DE = toImport.player.about["T1"].TX
	elseif toImport.player.about.TE == 2 then
		local DE = {}
		for i, block in ipairs(toImport.player.about["T2"]) do
			DE[#DE + 1] = block.TX
		end
		profile.DE = table.concat(DE, "\n\n")
	elseif toImport.player.about.TE == 3 then
		local HI = {}
		profile.DE = toImport.player.about["T3"].PH.TX
		HI[#HI + 1] = toImport.player.about["T3"].PS.TX
		HI[#HI + 1] = toImport.player.about["T3"].HI.TX
		profile.HI = table.concat(HI, "\n\n")
	end
	return 1
end

local import = CreateFrame("Frame")
import:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
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
	end
end)
import:RegisterEvent("PLAYER_LOGIN")
