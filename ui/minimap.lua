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

local minimap

local function minimap_UpdateIcon()
	if not minimap then return end
	if xrp.units.target and xrp.units.target.fields.VA then
		minimap.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_03")
		return
	end
	local FC = xrp.current.fields.FC
	if not FC or FC == "0" or FC == "1" then
		minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red")
	else
		minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green")
	end
end

local function minimap_ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 30, 4)
	GameTooltip:SetText(xrp.current.fields.NA)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(("Profile: |cffffffff%s|r"):format(xrpSaved.selected))
	local FC = xrp.current.fields.FC
	if FC and FC ~= "0" then
		GameTooltip:AddLine(("Status: |cff%s%s|r"):format(FC == "1" and "99664d" or "66b380", xrp.values.FC[tonumber(FC)] or FC))
	end
	local CU = xrp.current.fields.CU
	if CU then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Currently:")
		GameTooltip:AddLine(("|cffe6b399%s|r"):format(CU or "None"), nil, nil, nil, true)
	end
	GameTooltip:AddLine(" ")
	if xrp.units.target and xrp.units.target.fields.VA then
		GameTooltip:AddLine("|cffffffffClick to view your target's profile.|r")
	elseif not FC or FC == "0" or FC == "1" then
		GameTooltip:AddLine("|cff66b380Click for in character.|r")
	else
		GameTooltip:AddLine("|cff99664dClick for out of character.|r")
	end
	GameTooltip:AddLine("|cffffffffRight click for the menu.|r")
	GameTooltip:Show()
end

local minimap_OnClickHandler
do
	local menulist_status = {}
	do
		local function minimap_StatusSelect(self, status, arg2, checked)
			local FC = xrp.profiles.SELECTED.fields.FC
			if not checked and (status ~= FC or (not FC and status ~= "0")) then
				xrp.current.fields.FC = status ~= "0" and status or ""
			elseif not checked then
				xrp.current.fields.FC = nil
			end
			CloseDropDownMenus()
		end
		local function minimap_StatusChecked(self)
			return self.arg1 == (xrp.current.fields.FC or "0")
		end

		local FC = xrp.values.FC
		for i = 0, #FC, 1 do
			menulist_status[#menulist_status + 1] = { text = FC[i], checked = minimap_StatusChecked, arg1 = tostring(i), func = minimap_StatusSelect, }
		end
	end

	local menulist_profiles = {}
	local minimap_menulist = {
		{ text = "XRP", isTitle = true, notCheckable = true, },
		{ text = "Profiles", notCheckable = true, hasArrow = true, menuList = menulist_profiles, },
		{ text = "Character status", notCheckable = true, hasArrow = true, menuList = menulist_status, },
		{ text = "Currently...", notCheckable = true, func = function() StaticPopup_Show("XRP_CURRENTLY") end, },
		{ text = "Editor...", notCheckable = true, func = function() xrp:Edit() end, },
		{ text = "Automation...", notCheckable = true, func = function() xrp:Automation() end, },
		{ text = "Viewer...", notCheckable = true, func = function() xrp:View() end, },
		{ text = "Options...", notCheckable = true, func = function() xrp:Options() end, },
		{ text = CANCEL, notCheckable = true, },
	}

	do
		local function minimap_ProfileSelect(self, name, arg2, checked)
			if not checked and xrp.profiles[name] then
				xrp.profiles[name]:Activate()
			end
			CloseDropDownMenus()
		end

		function minimap_OnClickHandler(self, button, down)
			if not down then
				if button == "LeftButton" then
					if xrp.units.target and xrp.units.target.fields.VA then
						xrp:View("target")
					else
						local FC, FCnil = xrp.current.fields.FC, xrp.profiles.SELECTED.fields.FC
						local IC, ICnil = FC ~= nil and FC ~= "1" and FC ~= "0", FCnil ~= nil and FCnil ~= "1" and FCnil ~= "0"
						if FC ~= FCnil and IC ~= ICnil then
							xrp.current.fields.FC = nil
						elseif IC then
							xrp.current.fields.FC = "1"
						else
							xrp.current.fields.FC = "2"
						end
					end
					if not self.settings.hidett then
						self:ShowTooltip()
					end
					CloseDropDownMenus()
				elseif button == "RightButton" then
					wipe(menulist_profiles)
					local selected = xrpSaved.selected
					for _, name in ipairs(xrp.profiles:List()) do
						menulist_profiles[#menulist_profiles + 1] = { text = name, checked = selected == name, arg1 = name, func = minimap_ProfileSelect, }
					end
					ToggleDropDownMenu(nil, nil, self.Menu, self, -2, 5, minimap_menulist)
					if not self.settings.hidett then
						GameTooltip:Hide()
					end
				end
			end
		end
	end
end

local attachedMinimap, detachedMinimap

xrpPrivate.settingsToggles.minimap = {
	enabled = function(setting)
		if setting then
			if minimap == nil then
				xrp:HookEvent("UPDATE", minimap_UpdateIcon)
				xrp:HookEvent("RECEIVE", minimap_UpdateIcon)
			end
			local detached = xrpPrivate.settings.minimap.detached
			if detached then
				if not detachedMinimap then
					detachedMinimap = CreateFrame("Button", nil, UIParent, "XRPButton")
					detachedMinimap.settings = xrpPrivate.settings.minimap
					detachedMinimap.ShowTooltip = minimap_ShowTooltip
					detachedMinimap:SetScript("OnClick", minimap_OnClickHandler)
					detachedMinimap:SetScript("OnEvent", minimap_UpdateIcon)
					detachedMinimap:UpdatePosition()
				end
				if minimap and minimap == attachedMinimap then
					minimap:UnregisterAllEvents()
					minimap:Hide()
				end
				minimap = detachedMinimap
			else
				if not attachedMinimap then
					attachedMinimap = CreateFrame("Button", "LibDBIcon10_XRP", Minimap, "XRPMinimap")
					attachedMinimap.settings = xrpPrivate.settings.minimap
					attachedMinimap.ShowTooltip = minimap_ShowTooltip
					attachedMinimap:SetScript("OnClick", minimap_OnClickHandler)
					attachedMinimap:SetScript("OnEvent", minimap_UpdateIcon)
					attachedMinimap:UpdatePosition()
				end
				if minimap and minimap == detachedMinimap then
					minimap:UnregisterAllEvents()
					minimap:Hide()
				end
				minimap = attachedMinimap
			end
			minimap_UpdateIcon()
			minimap:RegisterEvent("PLAYER_TARGET_CHANGED")
			minimap:Show()
		elseif minimap ~= nil then
			minimap:UnregisterAllEvents()
			minimap:Hide()
			minimap = nil
		end
	end,
	detached = function(setting)
		if not xrpPrivate.settings.minimap.enabled or not minimap or (setting and minimap == detachedMinimap) or (not setting and minimap == attachedMinimap) then return end
		xrpPrivate.settingsToggles.minimap.enabled(true)
	end,
}
