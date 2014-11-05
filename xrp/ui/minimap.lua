--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>
	(C) 2008-2011 Rabbit <rabbit.magtheridon@gmail.com>

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

local minimap = LibDBIcon10_XRP
LibDBIcon10_XRP = nil

local L = xrp.L
local settings
xrp:HookLoad(function()
	local default_settings = {
		angle = 225,
		hidett = false,
		detached = false,
		x = 0,
		y = 0,
		point = "CENTER",
	}
	-- 5.4.8.1
	if type(xrp.settings.minimap) == "number" then
		local minimap = {
			angle = xrp.settings.minimap,
			hidett = xrp.settings.hideminimaptt,
			detached = xrp.settings.minimapdetached,
			x = xrp.settings.minimapx,
			y = xrp.settings.minimapy,
			point = xrp.settings.minimappoint,
		}
		xrp.settings.minimap = minimap
		xrp.settings.hideminimaptt = nil
		xrp.settings.minimapdetached = nil
		xrp.settings.minimapx = nil
		xrp.settings.minimapy = nil
		xrp.settings.minimappoint = nil
	elseif type(xrp.settings.minimap) ~= "table" then
		xrp.settings.minimap = {}
	end
	settings = setmetatable(xrp.settings.minimap, { __index = default_settings })
end)

do
	local minimap_OnDragStart, minimap_OnDragStop, minimap_UpdatePosition
	do
		do
			local minimapShapes = {
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

			function minimap_UpdatePosition(self)
				local angle = math.rad(settings.angle)
				local x, y, q = math.cos(angle), math.sin(angle), 1
				if x < 0 then q = q + 1 end
				if y > 0 then q = q + 2 end
				if minimapShapes[GetMinimapShape and GetMinimapShape() or "ROUND"][q] then
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

		do
			local function minimap_OnUpdate(self)
				local mx, my = Minimap:GetCenter()
				local px, py = GetCursorPosition()
				local scale = Minimap:GetEffectiveScale()
				px, py = px / scale, py / scale
				settings.angle = math.deg(math.atan2(py - my, px - mx)) % 360
				minimap_UpdatePosition(self)
			end

			function minimap_OnDragStart(self)
				self:LockHighlight()
				self:SetScript("OnUpdate", minimap_OnUpdate)
			end
		end
		function minimap_OnDragStop(self)
			self:SetScript("OnUpdate", nil)
			self:UnlockHighlight()
		end
	end

	local function minimap_UpdatePositionDetached(self)
		self:ClearAllPoints()
		self:SetPoint(settings.point, self:GetParent(), settings.point, settings.x, settings.y)
	end

	local function minimap_OnDragStartDetached(self)
		if IsShiftKeyDown() then
			self:LockHighlight()
			self:StartMoving()
			self.moving = true
		end
	end

	local function minimap_OnDragStopDetached(self)
		if self.moving then
			self:StopMovingOrSizing()
			settings.point, settings.x, settings.y = select(3, self:GetPoint())
			self:UnlockHighlight()
			self.moving = nil
		end
	end

	local function minimap_UpdateIcon()
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

	xrp:HookEvent("FIELD_UPDATE", minimap_UpdateIcon)
	xrp:HookEvent("MSP_RECEIVE", minimap_UpdateIcon)

	xrp:HookLoad(function()
		if settings.detached then
			-- Set scripts for free-form moving.
			minimap:SetScript("OnDragStart", minimap_OnDragStartDetached)
			minimap:SetScript("OnDragStop", minimap_OnDragStopDetached)
			minimap:RegisterForDrag("RightButton")
			minimap:SetClampedToScreen(true)
			minimap_UpdatePositionDetached(minimap)
		else
			-- Set scripts for minimap-attached moving.
			minimap:SetScript("OnDragStart", minimap_OnDragStart)
			minimap:SetScript("OnDragStop", minimap_OnDragStop)
			minimap:RegisterForDrag("LeftButton")
			minimap:SetParent(Minimap)
			minimap:SetClampedToScreen(false)
			minimap_UpdatePosition(minimap)
		end
		minimap_UpdateIcon()
		minimap:SetScript("OnEvent", minimap_UpdateIcon)
		minimap:RegisterEvent("PLAYER_TARGET_CHANGED")
	end)
end

local function ShowMinimapTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 30, 4)
	GameTooltip:SetText(xrp.current.fields.NA)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Profile: |cffffffff%s|r"]:format(xrpSaved.selected))
	local FC = xrp.current.fields.FC
	if FC and FC ~= "0" then
		GameTooltip:AddLine(L["Status: |cff%s%s|r"]:format(FC == "1" and "99664d" or "66b380", xrp.values.FC[tonumber(FC)] or FC))
	end
	local CU = xrp.current.fields.CU
	if CU then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Currently:"])
		GameTooltip:AddLine(("|cffe6b399%s|r"):format(CU or "None"), nil, nil, nil, true)
	end
	GameTooltip:AddLine(" ")
	if xrp.units.target and xrp.units.target.fields.VA then
		GameTooltip:AddLine(L["|cffffffffClick to view your target's profile.|r"])
	elseif not FC or FC == "0" or FC == "1" then
		GameTooltip:AddLine(L["|cff66b380Click for in character.|r"])
	else
		GameTooltip:AddLine(L["|cff99664dClick for out of character.|r"])
	end
	GameTooltip:AddLine(L["|cffffffffRight click for the menu.|r"])
	GameTooltip:Show()
end

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
		{ text = XRP, isTitle = true, notCheckable = true, },
		{ text = L["Profiles"], notCheckable = true, hasArrow = true, menuList = menulist_profiles, },
		{ text = XRP_FC, notCheckable = true, hasArrow = true, menuList = menulist_status, },
		{ text = XRP_CU..CONTINUED, notCheckable = true, func = function() StaticPopup_Show("XRP_CURRENTLY") end, },
		{ text = L["Editor..."], notCheckable = true, func = function() xrp:Edit() end, },
		{ text = L["Automation..."], notCheckable = true, func = function() xrp:Auto() end, },
		{ text = L["Viewer..."], notCheckable = true, func = function() xrp:View() end, },
		{ text = L["Options..."], notCheckable = true, func = function() xrp:Options() end, },
		{ text = CANCEL, notCheckable = true, },
	}

	-- Reverse order or indexes would change.
	do
		local loaded, reason = select(4, GetAddOnInfo("xrp_options"))
		if not loaded and reason ~= "DEMAND_LOADED" then
			table.remove(minimap_menulist, 8)
		end
		loaded, reason = select(4, GetAddOnInfo("xrp_viewer"))
		if not loaded and reason ~= "DEMAND_LOADED" then
			table.remove(minimap_menulist, 7)
		end
		loaded, reason = select(4, GetAddOnInfo("xrp_editor"))
		if not loaded and reason ~= "DEMAND_LOADED" then
			table.remove(minimap_menulist, 6)
			table.remove(minimap_menulist, 5)
		end
	end

	do
		local function minimap_ProfileSelect(self, name, arg2, checked)
			if not checked and xrp.profiles[name] then
				xrp.profiles[name]:Activate()
			end
			CloseDropDownMenus()
		end

		minimap:SetScript("OnClick", function(self, button, down)
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
					if not settings.hidett then
						ShowMinimapTooltip(self)
					end
					CloseDropDownMenus()
				elseif button == "RightButton" then
					wipe(menulist_profiles)
					local selected = xrpSaved.selected
					for _, name in ipairs(xrp.profiles:List()) do
						menulist_profiles[#menulist_profiles + 1] = { text = name, checked = selected == name, arg1 = name, func = minimap_ProfileSelect, }
					end
					ToggleDropDownMenu(nil, nil, self.Menu, self, -2, 5, minimap_menulist)
					if not settings.hidett then
						GameTooltip:Hide()
					end
				end
			end
		end)
		minimap.Menu.initialize = EasyMenu_Initialize
		minimap.Menu.displayMode = "MENU"
	end
end

minimap:SetScript("OnEnter", function(self, motion)
	if motion and not settings.hidett then
		ShowMinimapTooltip(self)
	end
end)

minimap:SetScript("OnLeave", function(self, motion)
	if not settings.hidett then
		GameTooltip:Hide()
	end
	self.dim:Hide()
end)
