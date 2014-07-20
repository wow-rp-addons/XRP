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

local L = xrp.L

StaticPopupDialogs["XRP_IMPORT_RELOAD"] = {
	text = L["Available profiles have been imported and may be found in the editor's profile list. You should reload your UI now."],
	button1 = L["Reload UI"],
	button2 = CANCEL,
	OnAccept = function()
		ReloadUI()
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	cancels = "XRP_MSP_DISABLE", -- We know, it's supposed to do that.
}

StaticPopupDialogs["XRP_IMPORT_FAILED"] = {
	text = L["No supported RP addons found to import from. You should log out and re-enable XRP: Import along with MyRolePlay and/or TotalRP2 if you wish to import profiles."],
	button1 = OKAY,
	showAlert = true,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- This is easy. Using a very similar storage format (i.e., MSP fields).
local function import_MyRolePlay()
	for name, profile in pairs(mrpSaved.Profiles) do
		for field, value in pairs(profile) do
			if not xrp.fields.unit[field] and not xrp.fields.meta[field] and not xrp.fields.dummy[field] and field:find("^%u%u$") then
				if field == "FC" and not tonumber(value) and value ~= "" then
					value = "2"
				end
				xrp.profiles["MRP-"..name][field] = value ~= "" and value or nil
			end
		end
	end
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
		local realm = GetRealmName()
		local player = (UnitName("player"))
		local profile = TRP2_Module_PlayerInfo[realm][player]
		if profile.Actu then
			xrp.profiles["TRP2"].CU = profile.Actu.ActuTexte
			xrp.profiles["TRP2"].FC = profile.Actu.StatutRP and tostring(profile.Actu.StatutRP) or nil
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
		xrp.profiles["TRP2"].DE = DE ~= "" and DE:match("^(.-)\n?\n?$") or nil
		if profile.Histoire then
			xrp.profiles["TRP2"].HI = profile.Histoire.HistoireTexte
		end
		if profile.Registre then
			local NA = ("%s %s"):format(profile.Registre.Prenom or player, profile.Registre.Nom or ""):match("^%s*(.-)%s*$")
			xrp.profiles["TRP2"].NA = NA ~= "" and NA or nil
			xrp.profiles["TRP2"].RA = profile.Registre.RacePerso
			xrp.profiles["TRP2"].AE = profile.Registre.YeuxVisage
			local NT = ("%s | %s | %s"):format(profile.Registre.ClassePerso or "", profile.Registre.Titre or "", profile.Registre.TitreComplet or ""):match("^[%s|]*(.-)[%s|]*$")
			xrp.profiles["TRP2"].NT = NT ~= "" and NT or nil
			xrp.profiles["TRP2"].AG = profile.Registre.Age
			xrp.profiles["TRP2"].HH = profile.Registre.Habitation
			xrp.profiles["TRP2"].HB = profile.Registre.Origine
			xrp.profiles["TRP2"].AH = trp2_height[profile.Registre.Taille or 3]
			xrp.profiles["TRP2"].AW = trp2_weight[profile.Registre.Silhouette or 2]
		end
	end
end

local import = CreateFrame("Frame")
import:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_import" then

		local mrploaded = (select(4, GetAddOnInfo("MyRolePlay")))
		if mrploaded then
			import_MyRolePlay()
			DisableAddOn("MyRolePlay")
		end

		local trp2loaded = (select(4, GetAddOnInfo("totalRP2")))
		if trp2loaded then
			import_totalRP2()
			DisableAddOn("totalRP2")
		end

		DisableAddOn(addon)

		if mrploaded or trp2loaded then
			StaticPopup_Show("XRP_IMPORT_RELOAD")
		else
			StaticPopup_Show("XRP_IMPORT_FAILED")
		end

		self:UnregisterAllEvents()
		self:SetScript("OnEvent", nil)
	end
end)
import:RegisterEvent("ADDON_LOADED")
