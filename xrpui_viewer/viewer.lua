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

local supportedfields = { "NA", "NI", "NT", "NH", "AE", "RA", "AH", "AW", "CU", "DE", "AG", "HH", "HB", "MO", "HI", "VA" }

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
			XRP:HookEvent("REMOTE_RECEIVE", function(name)
				if XRP.Viewer.CurrentTarget == name then
					XRP.Viewer:Get(name)
				end
			end)
		self:UnregisterEvent("ADDON_LOADED")
		end
	end)

	self:SetScript("OnHide", function(self)
		self.CurrentTarget = UNKNOWN
	end)

	-- Setup shorthand access for easier looping later.
	-- Appearance tab
	for _, field in pairs({"AE", "RA", "AH", "AW"}) do
		XRP.Viewer[field] = XRP.Viewer.Appearance[field]
	end
	-- EditBox is inside ScrollFrame
	for _, field in pairs({"CU", "DE"}) do
		XRP.Viewer[field] = XRP.Viewer.Appearance[field].EditBox
	end

	-- Biography tab
	for _, field in pairs({"AG", "HH", "HB"}) do
		XRP.Viewer[field] = XRP.Viewer.Biography[field]
	end
	-- EditBox is inside ScrollFrame
	for _, field in pairs({"MO", "HI"}) do
		XRP.Viewer[field] = XRP.Viewer.Biography[field].EditBox
	end

	self.CurrentTarget = UNKNOWN
	self:RegisterEvent("ADDON_LOADED")
end

function XRP.Viewer:Load(profile)
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed. The Remote module always fills the
	-- entire profile with values, even if they're empty, so we do not need to
	-- empty anything first.
	for field, contents in pairs(profile) do
		if field == "NI" then
			self[field]:SetText(contents ~= "" and format("\"%s\"", contents) or contents)
		elseif field == "NA" then
			self.TitleText:SetText(contents)
		elseif field == "VA" then
			self[field]:SetText(contents ~= UNKNOWN.."/"..NONE and contents:gsub(";", ", ") or contents)
		else
			self[field]:SetText(contents)
		end
	end
end

function XRP.Viewer:ViewUnit(unit)
	if not UnitIsPlayer(unit) then
		unit = "player"
	end
	local name = XRP:UnitNameWithRealm(unit)
	self.CurrentTarget = name
	self:Get(name)
	SetPortraitTexture(self.portrait, unit)
	ShowUIPanel(self)
end

function XRP.Viewer:View(name)
	-- If the realm isn't attached (search for separator '-', as it's invalid
	-- in an actual name), attach our own realm name. It's probably what was
	-- intended.
	name = XRP:NameWithRealm(name)
	self.CurrentTarget = name
	self:Get(name)
	SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_Misc_Book_17")
	ShowUIPanel(self)
end

-- This is a wrapper for Load that allows us to access local supportedfields.
function XRP.Viewer:Get(name)
	XRP.Viewer:Load(XRP.Remote:Get(name, supportedfields))
end

init()
