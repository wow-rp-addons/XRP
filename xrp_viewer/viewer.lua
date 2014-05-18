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

local current = UNKNOWN

local function parse_versions(VA)
	if not VA then
		return UNKNOWN.." or "..NONE
	end
	return (VA:gsub(";", ", "))
end

function xrp.viewer:Load(character)
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
			self["VA"]:SetText(parse_versions(character[field]))
		elseif field == "AH" then
			self[field]:SetText(xrp:ConvertHeight(character[field], "user") or "")
		elseif field == "AW" then
			self[field]:SetText(xrp:ConvertWeight(character[field], "user") or "")
		elseif field == "RA" then
			self[field]:SetText(character[field] or xrp.values.RA[character.GR] or "")
		else
			self[field]:SetText(character[field] or "")
		end
	end
end

function xrp.viewer:ViewUnit(unit)
	if not UnitIsPlayer(unit) then
		unit = "player"
	end
	local name = xrp:UnitNameWithRealm(unit)
	current = name
	self.XC:SetText("")
	self:Load(xrp.units[unit])
	SetPortraitTexture(self.portrait, unit)
	ShowUIPanel(self)
	if self:IsVisible() and not self.Appearance:IsVisible() then
		PanelTemplates_SetTab(self, 1)
		self.Biography:Hide()
		self.Appearance:Show()
		PlaySound("igCharacterInfoTab")
	end
end

function xrp.viewer:ViewCharacter(name)
	name = xrp:NameWithRealm(name) -- If there's not a realm, add our realm.
	current = name
	self.XC:SetText("")
	self:Load(xrp.characters[name])
	-- TODO: Horde/Alliance emblems instead if GF available.
	SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_Misc_Book_17")
	ShowUIPanel(self)
	if self:IsVisible() and not self.Appearance:IsVisible() then
		PanelTemplates_SetTab(self, 1)
		self.Biography:Hide()
		self.Appearance:Show()
		PlaySound("igCharacterInfoTab")
	end
end

local function msp_receive(name)
	if current == name then
		local XC = xrp.viewer.XC:GetText()
		xrp.viewer:Load(xrp.characters[name])
		if not XC then
			xrp.viewer.XC:SetText("Received!")
		end
	end
end

local function msp_receive_chunk(name, chunk, totalchunks)
	if current == name then
		if chunk == totalchunks then
			xrp.viewer.XC:SetFormattedText("Received! (%u/%u)", chunk, totalchunks)
		else
			xrp.viewer.XC:SetFormattedText("Receiving... (%u/%s)", chunk, totalchunks and tostring(totalchunks) or "??")
		end
	end
end

local function msp_nochange(name)
	if current == name then
		local XC = xrp.viewer.XC:GetText()
		xrp.viewer:Load(xrp.characters[name])
		if not XC then
			xrp.viewer.XC:SetText("No changes.")
		end
	end
end

local function msp_offline(name)
	if current == name then
		if not xrp.viewer.XC:GetText() then
			xrp.viewer.XC:SetText("Character is offline.")
		end
	end
end

local function msp_norequest(name)
	if current == name then
		if not xrp.viewer.XC:GetText() then
			xrp.viewer.XC:SetText("Too soon for updates.")
		end
	end
end

local function msp_nomsp(name)
	if current == name then
		if not xrp.viewer.XC:GetText() then
			xrp.viewer.XC:SetText("No RP addon appears to be active.")
		end
	end
end

local function viewer_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_viewer" then
		self:SetAttribute("UIPanelLayout-defined", true)
		self:SetAttribute("UIPanelLayout-enabled", true)
		self:SetAttribute("UIPanelLayout-area", "left")
		self:SetAttribute("UIPanelLayout-pushable", 1)
		self:SetAttribute("UIPanelLayout-whileDead", true)
		PanelTemplates_SetNumTabs(self, 2)
		PanelTemplates_SetTab(self, 1)

		xrp:HookEvent("MSP_RECEIVE", msp_receive)
		xrp:HookEvent("MSP_RECEIVE_CHUNK", msp_receive_chunk)
		xrp:HookEvent("MSP_NOCHANGE", msp_nochange)
		xrp:HookEvent("MSP_OFFLINE", msp_offline)
		xrp:HookEvent("MSP_NOREQUEST", msp_norequest)
		xrp:HookEvent("MSP_NOMSP", msp_nomsp)
		self:UnregisterEvent("ADDON_LOADED")
	end
end
xrp.viewer:SetScript("OnEvent", viewer_OnEvent)
xrp.viewer:RegisterEvent("ADDON_LOADED")

local function viewer_OnHide(self)
	self.XC:SetText("")
	current = UNKNOWN
	PlaySound("igCharacterInfoClose")
end

xrp.viewer:SetScript("OnHide", viewer_OnHide)

-- Setup shorthand access for easier looping later.
-- Appearance tab
for _, field in pairs({ "AE", "RA", "AH", "AW" }) do
	xrp.viewer[field] = xrp.viewer.Appearance[field]
end
-- EditBox is inside ScrollFrame
for _, field in pairs({ "CU", "DE" }) do
	xrp.viewer[field] = xrp.viewer.Appearance[field].EditBox
end

-- Biography tab
for _, field in pairs({ "AG", "HH", "HB" }) do
	xrp.viewer[field] = xrp.viewer.Biography[field]
end
-- EditBox is inside ScrollFrame
for _, field in pairs({ "MO", "HI" }) do
	xrp.viewer[field] = xrp.viewer.Biography[field].EditBox
end
