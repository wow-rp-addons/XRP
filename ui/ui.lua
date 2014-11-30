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

local addonName, xrpPrivate = ...

function xrp:View(player)
	local isUnit = UnitExists(player)
	if isUnit and not UnitIsPlayer(player) then return end
	if not xrpPrivate.viewer then
		xrpPrivate.viewer = CreateFrame("Frame", "XRPViewer", UIParent, "XRPViewerTemplate")
	end
	local viewer = xrpPrivate.viewer
	if not player then
		if viewer:IsShown() then
			HideUIPanel(viewer)
			return
		end
		if viewer.current == UNKNOWN then
			failed = nil
			SetPortraitTexture(viewer.portrait, "player")
			viewer:Load(xrp.units.player.fields)
		end
		ShowUIPanel(viewer)
		return
	end
	if not isUnit then
		local unit = Ambiguate(player, "none")
		isUnit = UnitExists(unit)
		player = isUnit and unit or xrp:NameWithRealm(player):gsub("^%l", string.upper)
	end
	viewer.current = isUnit and xrp:UnitNameWithRealm(player) or player
	viewer.failed = nil
	viewer.XC:SetText("")
	viewer:Load(isUnit and xrp.units[player].fields or xrp.characters[player].fields)
	if isUnit then
		SetPortraitTexture(viewer.portrait, player)
	else
		local GF = xrp.characters[player].fields.GF
		SetPortraitToTexture(viewer.portrait, GF and ((GF == "Alliance" and "Interface\\Icons\\INV_BannerPVP_02") or (GF == "Horde" and "Interface\\Icons\\INV_BannerPVP_01")) or "Interface\\Icons\\INV_Misc_Book_17")
	end
	ShowUIPanel(viewer)
	if not viewer.Appearance:IsVisible() then
		PanelTemplates_SetTab(viewer, 1)
		viewer.Biography:Hide()
		viewer.Appearance:Show()
		PlaySound("igCharacterInfoTab")
	end
end

function xrp:Edit(profile)
	if not xrpPrivate.editor then
		xrpPrivate.editor = CreateFrame("Frame", "XRPEditor", UIParent, "XRPEditorTemplate")
	end
	local editor = xrpPrivate.editor
	if not profile and editor:IsShown() then
		HideUIPanel(editor)
		return
	end
	ShowUIPanel(editor)
	if profile then
		editor:Load(profile)
	end
end

function xrp:Automation(form)
	if not xrpPrivate.automation then
		xrpPrivate.automation = CreateFrame("Frame", "XRPAutomation", UIParent, "XRPAutomationTemplate")
	end
	local automation = xrpPrivate.automation
	if not form and automation:IsShown() then
		HideUIPanel(automation)
		return
	end
	ShowUIPanel(automation)
	if form then
		automation.Form:SetValue(form)
	end
end

-- Global strings for keybinds.
BINDING_HEADER_XRP = "XRP"
BINDING_NAME_XRP_EDITOR = "Open/close RP profile editor"
BINDING_NAME_XRP_VIEWER = "View target's or mouseover's RP profile"
BINDING_NAME_XRP_VIEWER_TARGET = "View target's RP profile"
BINDING_NAME_XRP_VIEWER_MOUSEOVER = "View mouseover's RP profile"