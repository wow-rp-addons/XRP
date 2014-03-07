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

local function init()
	local self = XRP.Viewer

	self:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == "XRP_Viewer" then
			XRP_VIEWER_VERSION = GetAddOnMetadata(addon, "Title").."/"..GetAddOnMetadata(addon, "Version")
			self:SetAttribute("UIPanelLayout-defined", true)
			self:SetAttribute("UIPanelLayout-enabled", true)
			self:SetAttribute("UIPanelLayout-area", "left")
			self:SetAttribute("UIPanelLayout-pushable", 1)
			self:SetAttribute("UIPanelLayout-whileDead", true)
			PanelTemplates_SetNumTabs(self, 2)
			PanelTemplates_SetTab(self, 1)
			self:SetScript("OnShow", function()
				SetPortraitTexture(self.portrait, "player")
				self:SetScript("OnShow", nil)
			end)
			self.SupportedFields = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU", "AG", "HH", "HB", "MO", "HI", "FR", "FC", "VA", "GC", "GR", "GS" }
			XRP:HookEvent("PROFILE_RECEIVE", function(name)
				if XRP.Viewer.CurrentTarget == name then
					XRP.Viewer:Load(XRP.Remote:Get(name, XRP.Viewer.SupportedFields))
				end
			end)
		self:UnregisterEvent("ADDON_LOADED")
		end
	end)

	-- Setup shorthand access for easier looping later.
	-- Appearance tab
	for _, key in pairs({"AE", "RA", "AH", "AW", "FR", "FC"}) do
		XRP.Viewer[key] = XRP.Viewer.Appearance[key]
	end
	-- EditBox is inside ScrollFrame
	for _, key in pairs({"CU", "DE"}) do
		XRP.Viewer[key] = XRP.Viewer.Appearance[key].EditBox
	end

	-- Biography tab
	for _, key in pairs({"AG", "HH", "HB"}) do
		XRP.Viewer[key] = XRP.Viewer.Biography[key]
	end
	-- EditBox is inside ScrollFrame
	for _, key in pairs({"MO", "HI"}) do
		XRP.Viewer[key] = XRP.Viewer.Biography[key].EditBox
	end

	self.CurrentTarget = XRP.Character.Name
	self:RegisterEvent("ADDON_LOADED")
end


function XRP.Viewer:Load(profile)
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed. The Remote module always fills the
	-- entire profile with values, even if they're empty, so we do not need to
	-- empty anything first.
	for _, key in pairs(self.SupportedFields) do
		if key == "FR" or key == "FC" then
			if tonumber(profile[key]) ~= nil then
				self[key]:SetText(XRP_VALUES[key][tonumber(profile[key])+1])
			else
				self[key]:SetText(profile[key])
			end
		elseif key == "NI" then
			if profile[key] ~= "" then
				self[key]:SetText("\""..profile[key].."\"")
			else
				self[key]:SetText("")
			end
		elseif key == "NA" then
			self.TitleText:SetText(profile[key])
		elseif key ~= "GC" and key ~= "GR" and key ~= "GS" then -- Non-visible use.
			self[key]:SetText(profile[key])
		end
	end
end

function XRP.Viewer:ViewUnit(unit)
	if not UnitIsPlayer(unit) then
		unit = "player"
	end
	local name = XRP:UnitNameWithRealm(unit)
	XRP.Remote:CacheUnit(unit)
	self.CurrentTarget = name
	self:Load(XRP.Remote:Get(name, XRP.Viewer.SupportedFields))
	ShowUIPanel(self)
	SetPortraitTexture(self.portrait, unit)
end

function XRP.Viewer:View(name)
	self.CurrentTarget = name
	self:Load(XRP.Remote:Get(name, XRP.Viewer.SupportedFields))
	ShowUIPanel(self)
	SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_Misc_Book_17")
end

init()
