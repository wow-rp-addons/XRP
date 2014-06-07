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

local import = CreateFrame("Frame")

local L = xrp.L

StaticPopupDialogs["XRP_IMPORT_RELOAD"] = {
	text = L["Available profiles have been imported. You should reload your UI now."],
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

-- This is easy. Using a very similar storage format (i.e., MSP fields).
local function import_MyRolePlay()
	for name, profile in pairs(mrpSaved.Profiles) do
		for field, value in pairs(profile) do
			if not xrp.msp.unitfields[field] and not xrp.msp.metafields[field] and not xrp.msp.dummyfields[field] then
				xrp.profiles["MRP-"..name][field] = value ~= "" and value or nil
			end
		end
	end
end

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
local function import_totalRP2()
	local realm = GetRealmName()
	local player = (UnitName("player"))
	local profile = TRP2_Module_PlayerInfo[realm][player]
	if profile.Actu then
		xrp.profiles["TRP2"].CU = profile.Actu.ActuTexte
		xrp.profiles["TRP2"].FC = tostring(profile.Actu.StatutRP)
	end
	local DE = ""
	if profile.Registre and profile.Registre.TraitVisage then
		DE = format(L["%sFace: %s\n\n"], DE, profile.Registre.TraitVisage)
	end
	if profile.Registre and profile.Registre.Piercing then
		DE = format(L["%sPiercings/Tattoos: %s\n\n"], DE, profile.Registre.Piercing)
	end
	if profile.Physique and profile.Physique.PhysiqueTexte then
		DE = format("%s%s", DE, profile.Physique.PhysiqueTexte)
	end
	xrp.profiles["TRP2"].DE = DE ~= "" and DE:match("^(.-)\n?\n?$") or nil
	if profile.Histoire then
		xrp.profiles["TRP2"].HI = profile.Histoire.HistoireTexte
	end
	if profile.Registre then
		local NA = format("%s %s", profile.Registre.Prenom or player, profile.Registre.Nom or ""):match("^%s*(.-)%s*$")
		xrp.profiles["TRP2"].NA = NA ~= "" and NA or nil
		xrp.profiles["TRP2"].RA = profile.Registre.RacePerso
		xrp.profiles["TRP2"].AE = profile.Registre.YeuxVisage
		local NT = format("%s | %s | %s", profile.Registre.ClassePerso or "", profile.Registre.Titre or "", profile.Registre.TitreComplet or ""):match("^[%s|]*(.-)[%s|]*$")
		xrp.profiles["TRP2"].NT = NT ~= "" and NT or nil
		xrp.profiles["TRP2"].AG = profile.Registre.Age
		xrp.profiles["TRP2"].HH = profile.Registre.Habitation
		xrp.profiles["TRP2"].HB = profile.Registre.Origine
		xrp.profiles["TRP2"].AH = trp2_height[profile.Registre.Taille or 3]
		xrp.profiles["TRP2"].AW = trp2_weight[profile.Registre.Silhouette or 2]
	end
end

local function import_OnEvent(self, event, addon)
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
		end

		self:UnregisterEvent("ADDON_LOADED")
	end
end
import:SetScript("OnEvent", import_OnEvent)
import:RegisterEvent("ADDON_LOADED")
