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

local hasMRP, hasTRP2 = (select(4, GetAddOnInfo("MyRolePlay"))), (select(4, GetAddOnInfo("totalRP2")))
if not (hasMRP or hasTRP2) then return end

local addonName, xrpPrivate = ...

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
		if xrpPrivate.profiles:Add(newProfileName) then
			for field, value in pairs(profile) do
				if not xrpPrivate.fields.unit[field] and not xrpPrivate.fields.meta[field] and not xrpPrivate.fields.dummy[field] and field:find("^%u%u$") then
					if field == "FC" then
						if not tonumber(value) and value ~= "" then
							value = "2"
						elseif value == "0" then
							value = ""
						end
					elseif field == "FR" and tonumber(value) then
						value = value ~= "0" and xrp.values.FR[value] or ""
					end
					xrpPrivate.profiles[newProfileName].fields[field] = value ~= "" and value or nil
				end
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
		if not TRP2_Module_PlayerInfo or not xrpPrivate.profiles:Add("TRP2") then
			return 0
		end
		local realm = GetRealmName()
		local profile = TRP2_Module_PlayerInfo[realm][xrpPrivate.player]
		if profile.Actu then
			xrpPrivate.profiles["TRP2"].fields.CU = profile.Actu.ActuTexte
			xrpPrivate.profiles["TRP2"].fields.FC = profile.Actu.StatutRP and profile.Actu.StatutRP ~= 0 and tostring(profile.Actu.StatutRP) or nil
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
		xrpPrivate.profiles["TRP2"].fields.DE = DE ~= "" and DE:match("^(.-)\n+$") or nil
		if profile.Histoire then
			xrpPrivate.profiles["TRP2"].fields.HI = profile.Histoire.HistoireTexte
		end
		if profile.Registre then
			do
				local NA = ("%s %s"):format(profile.Registre.Prenom or "", profile.Registre.Nom or ""):trim()
				xrpPrivate.profiles["TRP2"].fields.NA = NA ~= "" and NA or nil
			end
			xrpPrivate.profiles["TRP2"].fields.RA = profile.Registre.RacePerso
			xrpPrivate.profiles["TRP2"].fields.RC = profile.Registre.ClassePerso
			xrpPrivate.profiles["TRP2"].fields.AE = profile.Registre.YeuxVisage
			do
				local NT = ("%s | %s"):format(profile.Registre.Titre or "", profile.Registre.TitreComplet or ""):match("^[%s|]*(.-)[%s|]*$")
				xrpPrivate.profiles["TRP2"].fields.NT = NT ~= "" and NT or nil
			end
			xrpPrivate.profiles["TRP2"].fields.AG = profile.Registre.Age
			xrpPrivate.profiles["TRP2"].fields.HH = profile.Registre.Habitation
			xrpPrivate.profiles["TRP2"].fields.HB = profile.Registre.Origine
			xrpPrivate.profiles["TRP2"].fields.AH = TRP2_HEIGHT[profile.Registre.Taille or 3]
			xrpPrivate.profiles["TRP2"].fields.AW = TRP2_WEIGHT[profile.Registre.Silhouette or 2]
		end
		return 1
	end
end

local import = CreateFrame("Frame")
import:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		local imported = false
		if hasMRP then
			local count = ImportMyRolePlay()
			if count > 0 then
				DisableAddOn("MyRolePlay")
				imported = true
			end
		end
		if hasTRP2 then
			local count = ImportTotalRP2()
			if count > 0 then
				DisableAddOn("totalRP2")
				imported = true
			end
		end
		if imported then
			StaticPopup_Show("XRP_IMPORT_RELOAD")
		end
	end
end)
import:RegisterEvent("PLAYER_LOGIN")
