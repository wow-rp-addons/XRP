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

local function Minimap_UpdateIcon()
	if not minimap then return end
	if xrp.units.target and xrp.units.target.fields.VA then
		minimap.Icon:SetTexture("Interface\\Icons\\INV_Misc_Book_03")
		return
	end
	local FC = xrp.current.fields.FC
	if not FC or FC == "0" or FC == "1" then
		minimap.Icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red")
	else
		minimap.Icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green")
	end
end

local Minimap_PreClick, Minimap_baseMenuList
do
	local Status_menuList = {}
	do
		local function Status_Click(self, status, arg2, checked)
			if not checked then
				xrp:StatusToggle(status)
			end
			CloseDropDownMenus()
		end
		local function Status_Checked(self)
			return self.arg1 == (xrp.current.fields.FC or "0")
		end

		local FC = xrp.values.FC
		for i = 0, 4, 1 do
			local iString = tostring(i)
			Status_menuList[i + 1] = { text = FC[iString], checked = Status_Checked, arg1 = iString, func = Status_Click, }
		end
	end

	local Profiles_menuList = {}
	Minimap_baseMenuList = {
		{ text = "XRP", isTitle = true, notCheckable = true, },
		{ text = "Profiles", notCheckable = true, hasArrow = true, menuList = Profiles_menuList, },
		{ text = "Character status", notCheckable = true, hasArrow = true, menuList = Status_menuList, },
		{ text = "Currently...", notCheckable = true, func = function() StaticPopup_Show("XRP_CURRENTLY") end, },
		{ text = "Editor...", notCheckable = true, func = function() xrp:Edit() end, },
		{ text = "Viewer...", notCheckable = true, func = function() xrp:View() end, },
		{ text = "Options...", notCheckable = true, func = function() xrp:Options() end, },
		{ text = "Cancel", notCheckable = true, func = function() end, },
	}

	do
		local function Profiles_Click(self, name, arg2, checked)
			if not checked and xrpPrivate.profiles[name] then
				xrpPrivate.profiles[name]:Activate()
			end
			CloseDropDownMenus()
		end

		function Minimap_PreClick(self, button, down)
			if button == "RightButton" then
				wipe(Profiles_menuList)
				local selected = xrpSaved.selected
				for _, name in ipairs(xrpPrivate.profiles:List()) do
					Profiles_menuList[#Profiles_menuList + 1] = { text = name, checked = selected == name, arg1 = name, func = Profiles_Click, }
				end
			end
		end
	end
end

local attachedMinimap, detachedMinimap

local GetAttachedMinimap
do
	local Minmap_UpdatePosition
	do
		local MINIMAP_SHAPES = {
			["ROUND"] = { true, true, true, true },
			["SQUARE"] = { false, false, false, false },
			["CORNER-TOPLEFT"] = { false, false, false, true },
			["CORNER-TOPRIGHT"] = { false, false, true, false },
			["CORNER-BOTTOMLEFT"] = { false, true, false, false },
			["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
			["SIDE-LEFT"] = { false, true, false, true },
			["SIDE-RIGHT"] = { true, false, true, false },
			["SIDE-TOP"] = { false, false, true, true },
			["SIDE-BOTTOM"] = { true, true, false, false },
			["TRICORNER-TOPLEFT"] = { false, true, true, true },
			["TRICORNER-TOPRIGHT"] = { true, false, true, true },
			["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
			["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
		}
		function Minimap_UpdatePosition(self)
			local angle = math.rad(xrpPrivate.settings.minimap.angle)
			local x, y, q = math.cos(angle), math.sin(angle), 1
			if x < 0 then q = q + 1 end
			if y > 0 then q = q + 2 end
			if MINIMAP_SHAPES[GetMinimapShape and GetMinimapShape() or "ROUND"][q] then
				x, y = x*80, y*80
			else
				-- 103.13708498985 = math.sqrt(2*(80)^2)-10
				x = math.max(-80, math.min(x*103.13708498985, 80))
				y = math.max(-80, math.min(y*103.13708498985, 80))
			end
			self:ClearAllPoints()
			self:SetPoint("CENTER", Minimap, "CENTER", x, y)
		end
	end
	local function Minimap_OnUpdate(self, elapsed)
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		xrpPrivate.settings.minimap.angle = math.deg(math.atan2(py - my, px - mx)) % 360
		Minimap_UpdatePosition(self)
	end

	function GetAttachedMinimap()
		if not attachedMinimap then
			attachedMinimap = CreateFrame("Button", "LibDBIcon10_XRP", Minimap, "XRPMinimap")
			attachedMinimap.baseMenuList = Minimap_baseMenuList
			attachedMinimap:SetScript("PreClick", Minimap_PreClick)
			attachedMinimap:SetScript("OnEvent", Minimap_UpdateIcon)
			attachedMinimap.OnUpdate = Minimap_OnUpdate
			Minimap_UpdatePosition(attachedMinimap)
		end
		return attachedMinimap
	end
end

local GetDetachedMinimap
do
	local function Minimap_OnDragStop(self)
		if self.moving then
			self:StopMovingOrSizing()
			xrpPrivate.settings.minimap.point, xrpPrivate.settings.minimap.x, xrpPrivate.settings.minimap.y = select(3, self:GetPoint())
			self:UnlockHighlight()
			self.moving = nil
		end
	end

	function GetDetachedMinimap()
		if not detachedMinimap then
			detachedMinimap = CreateFrame("Button", nil, UIParent, "XRPButton")
			detachedMinimap.baseMenuList = Minimap_baseMenuList
			detachedMinimap:SetScript("OnDragStop", Minimap_OnDragStop)
			detachedMinimap:SetScript("PreClick", Minimap_PreClick)
			detachedMinimap:SetScript("OnEvent", Minimap_UpdateIcon)
			detachedMinimap:ClearAllPoints()
			detachedMinimap:SetPoint(xrpPrivate.settings.minimap.point, UIParent, xrpPrivate.settings.minimap.point, xrpPrivate.settings.minimap.x, xrpPrivate.settings.minimap.y)
		end
		return detachedMinimap
	end
end

xrpPrivate.settingsToggles.minimap = {
	enabled = function(setting)
		if setting then
			if minimap == nil then
				xrp:HookEvent("UPDATE", Minimap_UpdateIcon)
				xrp:HookEvent("RECEIVE", Minimap_UpdateIcon)
			end
			local needsUpdate
			if xrpPrivate.settings.minimap.detached then
				needsUpdate = true
				if minimap and minimap == attachedMinimap then
					minimap:UnregisterAllEvents()
					minimap:Hide()
				end
				minimap = GetDetachedMinimap()
			else
				needsUpdate = true
				if minimap and minimap == detachedMinimap then
					minimap:UnregisterAllEvents()
					minimap:Hide()
				end
				minimap = GetAttachedMinimap()
			end
			Minimap_UpdateIcon()
			minimap:RegisterEvent("PLAYER_TARGET_CHANGED")
			minimap:Show()
		elseif minimap ~= nil then
			minimap:UnregisterAllEvents()
			minimap:Hide()
			minimap = nil
		end
	end,
	detached = function(setting)
		if not xrpPrivate.settings.minimap.enabled or not minimap or setting and minimap == detachedMinimap or not setting and minimap == attachedMinimap then return end
		xrpPrivate.settingsToggles.minimap.enabled(xrpPrivate.settings.minimap.enabled)
	end,
}
