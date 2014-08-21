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
local failed = UNKNOWN

do
	-- This will request fields in the order listed.
	local display = {
		"VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", -- In TT.
		"AE", "AH", "AW", "AG", "HH", "HB", "MO", -- Not in TT.
		"DE", "HI", -- High-bandwidth.
	}

	function xrp.viewer:SetField(field, contents)
		-- This does not need to be very smart. SetText() should be mapped to
		-- the appropriate 'real' function if needed. However, the character
		-- tables will return nil on an empty value, so watch for that.
		if field == "NI" then
			self[field]:SetText(contents and L["\"%s\""]:format(xrp:StripEscapes(contents)) or "")
		elseif field == "NA" then
			self.TitleText:SetText(xrp:StripEscapes(contents) or Ambiguate(current, "none") or UNKNOWN)
		elseif field == "VA" then
			self[field]:SetText(contents and xrp:StripEscapes(contents:gsub(";", ", ")) or ("%s/%s"):format(UNKNOWN, NONE))
		elseif field == "AH" then
			self[field]:SetText(xrp:ConvertHeight(xrp:StripEscapes(contents), "user") or "")
		elseif field == "AW" then
			self[field]:SetText(xrp:ConvertWeight(xrp:StripEscapes(contents), "user") or "")
		elseif field == "CU" or field == "DE" or field == "MO" or field == "HI" then
			self[field]:SetText(xrp:LinkURLs(xrp:StripEscapes(contents)) or "")
		else
			self[field]:SetText(xrp:StripEscapes(contents) or "")
		end
	end

	function xrp.viewer:Load(character)
		for _, field in ipairs(display) do
			self:SetField(field, character[field] or (field == "RA" and xrp.values.GR[character.GR]) or (field == "RC" and xrp.values.GC[character.GC]) or nil)
		end
		self.Bookmark:SetChecked(xrp.bookmarks[current] ~= nil)
		if xrp.bookmarks[current] == 0 then
			-- Own character, disable checkbox.
			self.Bookmark:Disable()
		else
			self.Bookmark:Enable()
		end
	end

	local supported = {}
	for _, field in ipairs(display) do
		supported[field] = true
	end
	xrp:HookEvent("MSP_FIELD", function(name, field)
		if current == name and supported[field] then
			--print("Trying to set: "..field.." for "..name..".")
			xrp.viewer:SetField(field, xrp.characters[name][field])
		elseif current == name and (field == "GR" and not xrp.cache[name].RA) or (field == "GC" and not xrp.cache[name].RC) then
			xrp.viewer:SetField((field == "GR" and "RA") or (field == "GC" and "RC"), (field == "GR" and xrp.values.GR[xrp.characters[name].GR]) or (field == "GC" and xrp.values.GC[xrp.characters[name].GC]) or nil)
		end
	end)
end

function xrp.viewer:ViewUnit(unit)
	if not xrp.units[unit] then
		return
	end
	current = xrp:UnitNameWithRealm(unit)
	failed = nil
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
	failed = nil
	self.XC:SetText("")
	self:Load(xrp.characters[name])
	do
		local GF = xrp.characters[name].GF
		SetPortraitToTexture(self.portrait, GF and ((GF == "Alliance" and "Interface\\Icons\\INV_BannerPVP_02") or (GF == "Horde" and "Interface\\Icons\\INV_BannerPVP_01")) or "Interface\\Icons\\INV_Misc_Book_17")
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
		if failed == name then
			failed = nil
			xrp.viewer.XC:SetText("")
			xrp.viewer:Load(xrp.characters[name])
		else
			xrp.viewer.XC:SetText(L["Received!"])
		end
	end
end)

xrp:HookEvent("MSP_NOCHANGE", function(name)
	if current == name then
		if failed == name then
			failed = nil
			xrp.viewer.XC:SetText("")
			xrp.viewer:Load(xrp.characters[name])
		else
			local XC = xrp.viewer.XC:GetText()
			if not XC or XC:find("^Receiving") then
				xrp.viewer.XC:SetText(L["No changes."])
			end
		end
	end
end)

xrp:HookEvent("MSP_CHUNK", function(name, chunk, totalchunks)
	if current == name then
		local XC = xrp.viewer.XC:GetText()
		if chunk ~= totalchunks or not XC or XC:find("^Receiv") then
			xrp.viewer.XC:SetFormattedText(totalchunks and (chunk == totalchunks and L["Received! (%u/%u)"] or L["Receiving... (%u/%u)"]) or L["Receiving... (%u/??)"], chunk, totalchunks)
		end
	end
end)

xrp:HookEvent("MSP_FAIL", function(name, reason)
	if current == name then
		failed = current
		if not xrp.viewer.XC:GetText() then
			if reason == "offline" then
				xrp.viewer.XC:SetText(L["Character is not online."])
			elseif reason == "faction" then
				xrp.viewer.XC:SetText(L["Character is opposite faction."])
			elseif reason == "nomsp" then
				xrp.viewer.XC:SetText(L["No RP addon appears to be active."])
			end
		end
	end
end)

xrp.viewer.Bookmark:SetScript("OnClick", function(self, button, down)
	if not down then
		if xrp.bookmarks[current] then
			xrp.bookmarks[current] = false
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:SetText(xrp.L["Bookmark"])
			GameTooltip:Show()
		else
			xrp.bookmarks[current] = true
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:SetText(xrp.L["Unbookmark"])
			GameTooltip:Show()
		end
	end
end)

StaticPopupDialogs["XRP_VIEWER_URL"] = {
	text = (IsWindowsClient() or IsLinuxClient()) and L["Copy the URL (Ctrl+C) and paste into your web browser."] or IsMacClient() and L["Copy the URL (Cmd+C) and paste into your web browser."] or L["Copy the URL and paste into your web browser."],
	button1 = DONE,
	hasEditBox = true,
	OnShow = function (self, url)
		self.editBox:SetWidth(self.editBox:GetWidth() + 100)
		self.editBox:SetText(url or "")
		self.editBox:SetFocus()
		self.editBox:HighlightText()
	end,
	EditBoxOnTextChanged = function(self, url)
		self:SetText(url or "")
		self:HighlightText()
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function viewer_OnHyperlinkClick(self, url, link, button)
	StaticPopup_Show("XRP_VIEWER_URL", nil, nil, url)
end

-- Setup shorthand access for easier looping later.
-- Appearance tab
for _, field in ipairs({ "AE", "RA", "RC", "AH", "AW" }) do
	xrp.viewer[field] = xrp.viewer.Appearance[field]
end
-- EditBox is inside ScrollFrame
for _, field in ipairs({ "CU", "DE" }) do
	xrp.viewer[field] = xrp.viewer.Appearance[field].EditBox
	xrp.viewer[field]:SetHyperlinksEnabled(true)
	xrp.viewer[field]:SetScript("OnHyperlinkClick", viewer_OnHyperlinkClick)
end
-- Biography tab
for _, field in ipairs({ "AG", "HH", "HB" }) do
	xrp.viewer[field] = xrp.viewer.Biography[field]
end
-- EditBox is inside ScrollFrame
for _, field in ipairs({ "MO", "HI" }) do
	xrp.viewer[field] = xrp.viewer.Biography[field].EditBox
	xrp.viewer[field]:SetHyperlinksEnabled(true)
	xrp.viewer[field]:SetScript("OnHyperlinkClick", viewer_OnHyperlinkClick)
end
