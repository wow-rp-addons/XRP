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

local L = xrp.L
local current = UNKNOWN

do
	local supportedfields = { NA = true, NI = true, NT = true, NH = true, AE = true, RA = true, AH = true, AW = true, CU = true, DE = true, AG = true, HH = true, HB = true, MO = true, HI = true, VA = true }

	function xrp.viewer:Load(character)
		-- This does not need to be very smart. SetText() should be mapped to
		-- the appropriate 'real' function if needed. However, the character
		-- tables will return nil on an empty value, so watch for that.
		for field, _ in pairs(supportedfields) do
			if field == "NI" then
				local NI = character[field]
				self[field]:SetText(NI and L["\"%s\""]:format(xrp:StripEscapes(NI)) or "")
			elseif field == "NA" then
				self.TitleText:SetText(xrp:StripEscapes(character[field]) or Ambiguate(current, "none") or UNKNOWN)
			elseif field == "VA" then
				local VA = character[field]
				self[field]:SetText(VA and xrp:StripEscapes(VA:gsub(";", ", ")) or ("%s/%s"):format(UNKNOWN, NONE))
			elseif field == "AH" then
				self[field]:SetText(xrp:ConvertHeight(xrp:StripEscapes(character[field]), "user") or "")
			elseif field == "AW" then
				self[field]:SetText(xrp:ConvertWeight(xrp:StripEscapes(character[field]), "user") or "")
			elseif field == "RA" then
				self[field]:SetText(xrp:StripEscapes(character[field]) or xrp.values.GR[character.GR] or "")
			else
				self[field]:SetText(xrp:StripEscapes(character[field]) or "")
			end
		end
	end
end

function xrp.viewer:ViewUnit(unit)
	if not xrp.units[unit] then
		return
	end
	current = xrp:UnitNameWithRealm(unit)
	self.XC:SetText("")
	self:Load(xrp.units[unit])
	SetPortraitTexture(self.portrait, unit)
	ShowUIPanel(self)
	if not self.Appearance:IsVisible() then
		PanelTemplates_SetTab(self, 1)
		self.Biography:Hide()
		self.Appearance:Show()
		PlaySound("igCharacterInfoTab")
	end
end

function xrp.viewer:ViewCharacter(name)
	if type(name) ~= "string" or name == "" then
		return
	end
	name = xrp:NameWithRealm(name) -- If there's not a realm, add our realm.
	current = name
	self.XC:SetText("")
	self:Load(xrp.characters[name])
	do
		local GF = xrp.characters[name].GF
		if GF and GF == "Alliance" then
			SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_BannerPVP_02")
		elseif GF and GF == "Horde" then
			SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_BannerPVP_01")
		else
			SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_Misc_Book_17")
		end
	end
	ShowUIPanel(self)
	if not self.Appearance:IsVisible() then
		PanelTemplates_SetTab(self, 1)
		self.Biography:Hide()
		self.Appearance:Show()
		PlaySound("igCharacterInfoTab")
	end
end

xrp:HookEvent("MSP_RECEIVE", function(name)
	if current == name then
		xrp.viewer:Load(xrp.characters[name])
		xrp.viewer.XC:SetText(L["Received!"])
	end
end)

xrp:HookEvent("MSP_NOCHANGE", function(name)
	if current == name then
		xrp.viewer.XC:SetText(L["No changes."])
	end
end)

xrp:HookEvent("MSP_CHUNK", function(name, chunk, totalchunks)
	if current == name then
		if chunk == totalchunks then
			xrp.viewer.XC:SetFormattedText(L["Received! (%u/%u)"], chunk, totalchunks)
		else
			xrp.viewer.XC:SetFormattedText(totalchunks and L["Receiving... (%u/%u)"] or L["Receiving... (%u/??)"], chunk, totalchunks)
		end
	end
end)

xrp:HookEvent("MSP_FAIL", function(name, reason)
	if current == name then
		if not xrp.viewer.XC:GetText() then
			if reason == "offline" then
				xrp.viewer.XC:SetText(L["Character is not online."])
			elseif reason == "faction" then
				xrp.viewer.XC:SetText(L["Character is opposite faction."])
			elseif reason == "nomsp" then
				xrp.viewer.XC:SetText(L["No RP addon appears to be active."])
			elseif reason == "time" then
				xrp.viewer.XC:SetText(L["Too soon for updates."])
			end
		end
	end
end)

xrp.viewer:SetScript("OnHide", function(self)
	self.XC:SetText("")
	current = UNKNOWN
	PlaySound("igCharacterInfoClose")
end)

-- Setup shorthand access for easier looping later.
-- Appearance tab
for _, field in ipairs({ "AE", "RA", "AH", "AW" }) do
	xrp.viewer[field] = xrp.viewer.Appearance[field]
end
-- EditBox is inside ScrollFrame
for _, field in ipairs({ "CU", "DE" }) do
	xrp.viewer[field] = xrp.viewer.Appearance[field].EditBox
end
-- Biography tab
for _, field in ipairs({ "AG", "HH", "HB" }) do
	xrp.viewer[field] = xrp.viewer.Biography[field]
end
-- EditBox is inside ScrollFrame
for _, field in ipairs({ "MO", "HI" }) do
	xrp.viewer[field] = xrp.viewer.Biography[field].EditBox
end
