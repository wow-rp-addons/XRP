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
		self:LockHighlight()
		if not self.locked then
			self:StartMoving()
		end
	end

	local function minimap_OnDragStopDetached(self)
		if not self.locked then
			self:StopMovingOrSizing()
			settings.point, settings.x, settings.y = select(3, self:GetPoint())
		end
		self:UnlockHighlight()
	end

	do
		local detached = nil
		function xrp.minimap:SetDetached(detach)
			if detach == detached then
				return
			elseif detach then
				-- Set scripts for free-form moving.
				self:SetScript("OnDragStart", minimap_OnDragStartDetached)
				self:SetScript("OnDragStop", minimap_OnDragStopDetached)
				self:SetParent(UIParent)
				self:Show()
				self:SetClampedToScreen(true)
				minimap_UpdatePositionDetached(self)
				self.locked = false
				if detached ~= nil then
					print(L["The |cffabd473XRP|r button has been detached from the minimap and is unlocked. You may need to reload your UI (/reload), but note doing so will lock the button's position."])
				end
				detached = true
			else
				-- Set script for minimap-attached moving.
				self:SetScript("OnDragStart", minimap_OnDragStart)
				self:SetScript("OnDragStop", minimap_OnDragStop)
				self:SetParent(Minimap)
				self:Show()
				self:SetClampedToScreen(false)
				minimap_UpdatePosition(self)
				if detached ~= nil then
					print(L["The |cffabd473XRP|r button has been attached to the minimap. You may need to reload your UI (/reload)."])
				end
				detached = false
			end
		end
	end
end

do
	local function minimap_UpdateIcon()
		if xrp.units.target and xrp.units.target.fields.VA then
			xrp.minimap.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_03")
			return
		end
		local FC = xrp.current.fields.FC
		if not FC or FC == "0" or FC == "1" then
			xrp.minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red")
		else
			xrp.minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green")
		end
	end

	xrp:HookEvent("FIELD_UPDATE", minimap_UpdateIcon)
	xrp:HookEvent("MSP_RECEIVE", minimap_UpdateIcon)

	xrp:HookLoad(function()
		xrp.minimap:SetDetached(settings.detached)
		xrp.minimap.locked = true
		minimap_UpdateIcon()
		xrp.minimap:SetScript("OnEvent", minimap_UpdateIcon)
		xrp.minimap:RegisterEvent("PLAYER_TARGET_CHANGED")
	end)
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
		{ text = L["Editor..."], notCheckable = true, func = function() xrp:ToggleEditor() end, },
		{ text = L["Automation..."], notCheckable = true, func = function() xrp:ToggleAuto() end, },
		{ text = L["Viewer..."], notCheckable = true, func = function() xrp:ToggleViewer() end, },
		{ text = L["Options..."], notCheckable = true, func = function() xrp:ShowOptions() xrp:ShowOptions() end, },
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

		xrp.minimap:SetScript("OnClick", function(self, button, down)
			if not down then
				if button == "LeftButton" then
					if xrp.units.target and xrp.units.target.fields.VA then
						xrp:ShowViewerUnit("target")
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
					CloseDropDownMenus()
				elseif button == "RightButton" then
					if settings.detached and not self.locked then
						self.locked = true
						GameTooltip:Hide()
					else
						wipe(menulist_profiles)
						local selected = xrpSaved.selected
						for _, name in ipairs(xrp.profiles:List()) do
							menulist_profiles[#menulist_profiles + 1] = { text = name, checked = selected == name, arg1 = name, func = minimap_ProfileSelect, }
						end

						ToggleDropDownMenu(nil, nil, self.Menu, self, -2, 5, minimap_menulist)
					end
				end
			end
		end)
		xrp.minimap.Menu.initialize = EasyMenu_Initialize
		xrp.minimap.Menu.displayMode = "MENU"
	end
end

xrp.minimap:SetScript("OnEnter", function(self, motion)
	if motion and settings.detached and not self.locked then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 30, 4)
		GameTooltip:SetText(L["Right click to lock icon position."])
	elseif motion and not settings.hidett then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 30, 4)
		GameTooltip:SetText(L["Click to:"])
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(("|TInterface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red:20|t: %s"):format(L["Toggle your status to IC."]))
		GameTooltip:AddLine(("|TInterface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green:20|t: %s"):format(L["Toggle your status to OOC."]))
		GameTooltip:AddLine(("|TInterface\\Icons\\INV_Misc_Book_03:20|t: %s"):format(L["View your target's profile."]))
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Right click for the menu."])
		GameTooltip:Show()
	end
end)

xrp.minimap:SetScript("OnLeave", function(self, motion)
	if not settings.hidett or (settings.detached and not self.locked) then
		GameTooltip:Hide()
	end
	self.dim:Hide()
end)

StaticPopupDialogs["XRP_CURRENTLY"] = {
	text = L["What are you currently doing?\n(This will reset ten minutes after logout.)"],
	button1 = ACCEPT,
	button2 = RESET,
	button3 = CANCEL,
	hasEditBox = true,
	OnShow = function(self, data)
		self.editBox:SetWidth(self.editBox:GetWidth() + 150)
		self.editBox:SetText(xrp.current.fields.CU or "")
		self.editBox:HighlightText()
		self.button1:Disable()
		if not xrp.current.overrides.CU then
			self.button2:Disable()
		end
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= (xrp.current.fields.CU or "") then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnAccept = function(self, data, data2)
		xrp.current.fields.CU = self.editBox:GetText()
	end,
	OnCancel = function(self, data, data2) -- Reset button.
		xrp.current.fields.CU = nil
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if parent.button1:IsEnabled() then
			xrp.current.fields.CU = self:GetText()
			parent:Hide()
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
