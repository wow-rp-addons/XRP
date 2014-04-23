--[[
	© Justin Snelgrove
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

--[[ Begin LibDBIcon portions (by Rabbit) ]]--
local minimapShapes = {
	["ROUND"] = {true, true, true, true},
	["SQUARE"] = {false, false, false, false},
	["CORNER-TOPLEFT"] = {false, false, false, true},
	["CORNER-TOPRIGHT"] = {false, false, true, false},
	["CORNER-BOTTOMLEFT"] = {false, true, false, false},
	["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
	["SIDE-LEFT"] = {false, true, false, true},
	["SIDE-RIGHT"] = {true, false, true, false},
	["SIDE-TOP"] = {false, false, true, true},
	["SIDE-BOTTOM"] = {true, true, false, false},
	["TRICORNER-TOPLEFT"] = {false, true, true, true},
	["TRICORNER-TOPRIGHT"] = {true, false, true, true},
	["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
	["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}

local function updatePosition(button)
	local angle = math.rad(xrpui_settings.minimap_position or 225)
	local x, y, q = math.cos(angle), math.sin(angle), 1
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local quadTable = minimapShapes[minimapShape]
	if quadTable[q] then
		x, y = x*80, y*80
	else
		local diagRadius = 103.13708498985 --math.sqrt(2*(80)^2)-10
		x = math.max(-80, math.min(x*diagRadius, 80))
		y = math.max(-80, math.min(y*diagRadius, 80))
	end
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function onUpdate(self)
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	px, py = px / scale, py / scale
	xrpui_settings.minimap_position = math.deg(math.atan2(py - my, px - mx)) % 360
	updatePosition(self)
end

local function onDragStart(self)
	self:LockHighlight()
	self.dim:Hide()
	self:SetScript("OnUpdate", onUpdate)
end

local function onDragStop(self)
	self:SetScript("OnUpdate", nil)
	self:UnlockHighlight()
end
--[[ End LibDBIcon portions. ]]--

local function profiles_select(self, name, arg2, checked)
	if not checked then
		xrp.profiles(name)
	end
	ToggleDropDownMenu(nil, nil, xrpui.minimap.menu)
end

local function status_select(self, status, arg2, checked)
	if not checked then
		xrp.profile.FC = status
	end
	ToggleDropDownMenu(nil, nil, xrpui.minimap.menu)
end

local function height_select(self, height, arg2, checked)
	if not checked then
		xrp_settings.height = height
	end
	ToggleDropDownMenu(nil, nil, xrpui.minimap.menu)
end

local function weight_select(self, weight, arg2, checked)
	if not checked then
		xrp_settings.weight = weight
	end
	ToggleDropDownMenu(nil, nil, xrpui.minimap.menu)
end

local menulist_profiles = {}
local menulist_status = {
	{ text = xrpui.values.FC_EMPTY, checked = false, arg1 = "0", func = status_select },
}
for value, text in pairs(xrpui.values.FC) do
	menulist_status[#menulist_status + 1] = { text = text, checked = false, arg1 = tostring(value), func = status_select, }
end
local function menulist_editor(self, arg1, arg2, checked)
	xrpui:ToggleEditor()
end
local function menulist_viewer(self, arg1, arg2, checked)
	xrpui:ToggleViewer()
end

local menulist_height = {
	{ text = "Centimeters", checked = false, arg1 = "cm", func = height_select, },
	{ text = "Feet/Inches", checked = false, arg1 = "ft", func = height_select, },
	{ text = "Meters", checked = false, arg1 = "m", func = height_select, },
}

local menulist_weight = {
	{ text = "Kilograms", checked = false, arg1 = "kg", func = weight_select, },
	{ text = "Pounds", checked = false, arg1 = "lb", func = weight_select, },
}

local menulist_settings = {
	{ text = "Height", notCheckable = true, hasArrow = true, menuList = menulist_height, },
	{ text = "Weight", notCheckable = true, hasArrow = true, menuList = menulist_weight, },
}

local minimap_menulist = {
	{ text = "XRP", isTitle = true, notCheckable = true, },
	{ text = "Profiles", notCheckable = true, hasArrow = true, menuList = menulist_profiles, },
	{ text = "Character status", notCheckable = true, hasArrow = true, menuList = menulist_status, },
	{ text = "Profile editor", notCheckable = true, func = menulist_editor, },
	{ text = "Profile viewer", notCheckable = true, func = menulist_viewer, },
	{ text = "Settings", notCheckable = true, hasArrow = true, menuList = menulist_settings, },
	{ text = "Cancel", notCheckable = true, },
}

local function update_settings()
	local currentweight = xrp_settings.weight
	local currentheight = xrp_settings.height
	local currentstatus = xrp.profile.FC or "0"
	local menu = menulist_settings
	for _, menuitem in pairs(menu) do
		if menuitem.text == "Height" then
			for _, submenuitem in pairs(menuitem.menuList) do
				submenuitem.checked = currentheight == submenuitem.arg1
			end
		elseif menuitem.text == "Weight" then
			for _, submenuitem in pairs(menuitem.menuList) do
				submenuitem.checked = currentweight == submenuitem.arg1
			end
		end
	end
end

local function update_status()
	local currentstatus = xrp.profile.FC or "0"
	local menu = menulist_status
	for _, menuitem in pairs(menu) do
		menuitem.checked = currentstatus == menuitem.arg1
	end
end

local function update_profiles()
	local list = xrp.profiles()
	local profile = xrp.profile(true)
	local menu = menulist_profiles
	wipe(menu)
	for _, name in pairs(list) do
		menu[#menu + 1] = { text = name, checked = profile == name, arg1 = name, func = profiles_select, }
	end
end

local function update_icon()
	if xrp.units.target and xrp.units.target.VA then
		xrpui.minimap.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_03")
	else
		if xrp.profile.FC == "1" then
			xrpui.minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red")
		elseif not xrp.profile.FC or xrp.profile.FC == "0" then
			xrpui.minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Yellow")
		else
			xrpui.minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green")
		end
	end
end

local function minimap_OnEnter(self, motion)
	if motion then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 30, 4)
		--GameTooltip:SetText("XRP", 1.0, 1.0, 1.0)
		GameTooltip:SetText("Click to:")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("|TInterface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red:20|t/|TInterface\\Icons\\Ability_Malkorok_BlightofYshaarj_Yellow:20|t: Toggle your status to IC.", nil, nil, nil, true)
		GameTooltip:AddLine("|TInterface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green:20|t: Toggle your status to OOC.", nil, nil, nil, true)
		GameTooltip:AddLine("|TInterface\\Icons\\INV_Misc_Book_03:20|t: View your target's profile.", nil, nil, nil, true)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Right click for the menu.")
		GameTooltip:Show()
	end
end
xrpui.minimap:SetScript("OnEnter", minimap_OnEnter)
xrpui.minimap:SetScript("OnLeave", function(self, motion)
	GameTooltip:Hide()
end)

local toggled = false
local function minimap_OnClick(self, button, down)
	if not down then
		if button == "LeftButton" then
			if xrp.units.target and xrp.units.target.VA then
				xrpui:ShowViewerUnit("target")
			elseif toggled then
				xrp.profile.FC = nil
				toggled = false
			else
				local FC = xrp.profile.FC
				if FC ~= "1" and FC ~= "0" and FC then
					xrp.profile.FC = "1"
				else
					xrp.profile.FC = "2"
				end
				toggled = true
			end
		elseif button == "RightButton" then
			update_profiles()
			update_status()
			update_settings()
			EasyMenu(minimap_menulist, xrpui_minimap_menu, xrpui_minimap, 3, 10, "MENU", nil)
		end
	end
end

local function minimap_OnEvent(self, event, addon)
	if event == "PLAYER_TARGET_CHANGED" then
		update_icon()
	elseif event == "ADDON_LOADED" and addon == "xrpui" then
		self:SetScript("OnDragStart", onDragStart)
		self:SetScript("OnDragStop", onDragStop)
		self:SetScript("OnClick", minimap_OnClick)
		updatePosition(self)
		xrp:HookEvent("MSP_UPDATE", update_icon)
		xrp:HookEvent("MSP_RECEIVE", update_icon)
		xrpui.minimap:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("ADDON_LOADED")
	end
end

xrpui.minimap:SetScript("OnEvent", minimap_OnEvent)
xrpui.minimap:RegisterEvent("ADDON_LOADED")
