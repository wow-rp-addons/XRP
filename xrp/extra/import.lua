--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

if not select(4, GetAddOnInfo("MyRolePlay")) and not select(4, GetAddOnInfo("totalRP2")) then return end

local L = xrp.L

StaticPopupDialogs["XRP_IMPORT_RELOAD"] = {
	text = L["Available profiles have been imported and may be found in the editor's profile list. You should reload your UI now."],
	button1 = L["Reload UI"],
	button2 = CANCEL,
	OnAccept = function()
		ReloadUI()
	end,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	cancels = "XRP_MSP_DISABLE",
}

-- This is easy. Using a very similar storage format (i.e., MSP fields).
local function import_MyRolePlay()
	if not mrpSaved then
		return 0
	end
	local imported = 0
	for name, profile in pairs(mrpSaved.Profiles) do
		local newname = "MRP-"..name
		if xrp.profiles:Add(newname) then
			for field, value in pairs(profile) do
				if not xrp.fields.unit[field] and not xrp.fields.meta[field] and not xrp.fields.dummy[field] and field:find("^%u%u$") then
					if field == "FC" then
						if not tonumber(value) and value ~= "" then
							value = "2"
						elseif value == "0" then
							value = ""
						end
					elseif field == "FR" and tonumber(value) then
						value = value ~= "0" and xrp.values.FR[tonumber(value)] or ""
					end
					xrp.profiles[newname].fields[field] = value ~= "" and value or nil
				end
			end
			imported = imported + 1
		end
	end
	return imported
end

local import_totalRP2
do
	-- These values should be taken from TotalRP2 when localizing.
	local trp2_height = {
		L["Very short"],
		L["Short"],
		L["Average"],
		L["Tall"],
		L["Very tall"],
	}
	local trp2_weight = {
		L["Overweight"],
		L["Regular"],
		L["Muscular"],
		L["Skinny"],
	}

	-- This is a bit more complex. And partly in French.
	function import_totalRP2()
		if not TRP2_Module_PlayerInfo or not xrp.profiles:Add("TRP2") then
			return 0
		end
		local realm = GetRealmName()
		local player = (UnitName("player"))
		local profile = TRP2_Module_PlayerInfo[realm][player]
		if profile.Actu then
			xrp.profiles["TRP2"].fields.CU = profile.Actu.ActuTexte
			xrp.profiles["TRP2"].fields.FC = profile.Actu.StatutRP and profile.Actu.StatutRP ~= 0 and tostring(profile.Actu.StatutRP) or nil
		end
		local DE = ""
		if profile.Registre and profile.Registre.TraitVisage then
			DE = L["%sFace: %s\n\n"]:format(DE, profile.Registre.TraitVisage)
		end
		if profile.Registre and profile.Registre.Piercing then
			DE = L["%sPiercings/Tattoos: %s\n\n"]:format(DE, profile.Registre.Piercing)
		end
		if profile.Physique and profile.Physique.PhysiqueTexte then
			DE = ("%s%s"):format(DE, profile.Physique.PhysiqueTexte)
		end
		xrp.profiles["TRP2"].fields.DE = DE ~= "" and DE:match("^(.-)\n+$") or nil
		if profile.Histoire then
			xrp.profiles["TRP2"].fields.HI = profile.Histoire.HistoireTexte
		end
		if profile.Registre then
			do
				local NA = ("%s %s"):format(profile.Registre.Prenom or player, profile.Registre.Nom or ""):trim()
				xrp.profiles["TRP2"].fields.NA = NA ~= "" and NA or nil
			end
			xrp.profiles["TRP2"].fields.RA = profile.Registre.RacePerso
			xrp.profiles["TRP2"].fields.RC = profile.Registre.ClassePerso
			xrp.profiles["TRP2"].fields.AE = profile.Registre.YeuxVisage
			do
				local NT = ("%s | %s"):format(profile.Registre.Titre or "", profile.Registre.TitreComplet or ""):match("^[%s|]*(.-)[%s|]*$")
				xrp.profiles["TRP2"].fields.NT = NT ~= "" and NT or nil
			end
			xrp.profiles["TRP2"].fields.AG = profile.Registre.Age
			xrp.profiles["TRP2"].fields.HH = profile.Registre.Habitation
			xrp.profiles["TRP2"].fields.HB = profile.Registre.Origine
			xrp.profiles["TRP2"].fields.AH = trp2_height[profile.Registre.Taille or 3]
			xrp.profiles["TRP2"].fields.AW = trp2_weight[profile.Registre.Silhouette or 2]
		end
		return 1
	end
end

local import = CreateFrame("Frame")
import:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" and addon == "MyRolePlay" then
		local count = import_MyRolePlay()
		if count > 0 then
			DisableAddOn("MyRolePlay")
			self:RegisterEvent("PLAYER_LOGIN")
		end
	elseif event == "ADDON_LOADED" and addon == "totalRP2" then
		local count = import_totalRP2()
		if count > 0 then
			DisableAddOn("totalRP2")
			self:RegisterEvent("PLAYER_LOGIN")
		end
	elseif event == "PLAYER_LOGIN" then
		StaticPopup_Show("XRP_IMPORT_RELOAD")
	end
end)
import:RegisterEvent("ADDON_LOADED")
