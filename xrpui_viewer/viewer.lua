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

local supportedfields = { NA = true, NI = true, NT = true, NH = true, AE = true, RA = true, AH = true, AW = true, CU = true, DE = true, AG = true, HH = true, HB = true, MO = true, HI = true, VA = true }

local function init()
	local self = xrpui.viewer

	self:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == "xrpui_viewer" then
			XRP_VIEWER_VERSION = GetAddOnMetadata(addon, "Title").."/"..GetAddOnMetadata(addon, "Version")
			self:SetAttribute("UIPanelLayout-defined", true)
			self:SetAttribute("UIPanelLayout-enabled", true)
			self:SetAttribute("UIPanelLayout-area", "left")
			self:SetAttribute("UIPanelLayout-pushable", 1)
			self:SetAttribute("UIPanelLayout-whileDead", true)
			PanelTemplates_SetNumTabs(self, 2)
			PanelTemplates_SetTab(self, 1)
--[[			self:SetScript("OnShow", function()
				SetPortraitTexture(self.portrait, "player")
				self:SetScript("OnShow", nil)
			end)]]
			xrp:HookEvent("MSP_RECEIVE", function(name)
				if xrpui.viewer.CurrentTarget == name then
					xrpui.viewer:Load(xrp.characters[name])
					xrpui.viewer.XC:SetText("Received!")
				end
			end)
			xrp:HookEvent("MSP_RECEIVE_CHUNK", function(name, chunk, totalchunks)
				if xrpui.viewer.CurrentTarget == name then
--					print(format("%s: %u/%u", name, chunk, totalchunks or 0))
					if chunk == totalchunks then
						xrpui.viewer.XC:SetText("Received!")
					else
						xrpui.viewer.XC:SetFormattedText("Receiving: %u of %s...", chunk, totalchunks and tostring(totalchunks) or "??")
					end
				end
			end)
		self:UnregisterEvent("ADDON_LOADED")
		end
	end)
	self:RegisterEvent("ADDON_LOADED")

	self:SetScript("OnHide", function(self)
		self.CurrentTarget = UNKNOWN
	end)

	-- Setup shorthand access for easier looping later.
	-- Appearance tab
	for _, field in pairs({ "AE", "RA", "AH", "AW" }) do
		xrpui.viewer[field] = xrpui.viewer.Appearance[field]
	end
	-- EditBox is inside ScrollFrame
	for _, field in pairs({ "CU", "DE" }) do
		xrpui.viewer[field] = xrpui.viewer.Appearance[field].EditBox
	end

	-- Biography tab
	for _, field in pairs({ "AG", "HH", "HB" }) do
		xrpui.viewer[field] = xrpui.viewer.Biography[field]
	end
	-- EditBox is inside ScrollFrame
	for _, field in pairs({ "MO", "HI" }) do
		xrpui.viewer[field] = xrpui.viewer.Biography[field].EditBox
	end

	self.CurrentTarget = UNKNOWN
end

function xrpui.viewer:Load(character)
	-- This does not need to be very smart. SetText() should be mapped to the
	-- appropriate 'real' function if needed. The Remote module always fills the
	-- entire profile with values, even if they're empty, so we do not need to
	-- empty anything first.
	for field, _ in pairs(supportedfields) do
		if field == "NI" then
			self[field]:SetText(character[field] and format("\"%s\"", character[field]) or "")
		elseif field == "NA" then
			self.TitleText:SetText(character[field] or UNKNOWN)
		elseif field == "VA" then
			self[field]:SetText(character[field] and (character[field]:gsub(";", ", ")) or UNKNOWN.."/"..NONE)
		elseif field == "AH" then
			self[field]:SetText(xrp:ConvertHeight(character[field], "user") or "")
		elseif field == "AW" then
			self[field]:SetText(xrp:ConvertWeight(character[field], "user") or "")
		elseif field == "RA" then
			self[field]:SetText(character[field] or xrpui.values.RA[character.GR] or "")
		else
			self[field]:SetText(character[field] or "")
		end
	end
	self.XC:SetText("")
end

function xrpui.viewer:ViewUnit(unit)
	if not UnitIsPlayer(unit) then
		unit = "player"
	end
	local name = xrp:UnitNameWithRealm(unit)
	self.CurrentTarget = name
	self:Load(xrp.units[unit])
	SetPortraitTexture(self.portrait, unit)
	ShowUIPanel(self)
end

function xrpui.viewer:ViewCharacter(name)
	-- If the realm isn't attached (search for separator '-', as it's invalid
	-- in an actual name), attach our own realm name. It's probably what was
	-- intended.
	name = xrp:NameWithRealm(name)
	self.CurrentTarget = name
	self:Load(xrp.characters[name])
	SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_Misc_Book_17")
	ShowUIPanel(self)
end

init()
