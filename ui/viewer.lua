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

local viewer

local Load, FIELD
do
	-- This will request fields in the order listed.
	local display = {
		"VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", -- In TT.
		"AE", "AH", "AW", "AG", "HH", "HB", "MO", -- Not in TT.
		"DE", "HI", -- High-bandwidth.
	}

	local function SetField(field, contents)
		contents = contents and xrp:Strip(contents) or nil
		if field == "NA" then
			contents = contents or xrp:NameWithoutRealm(viewer.current) or UNKNOWN
		elseif field == "VA" then
			contents = contents and contents:gsub(";", ", ") or "Unknown/None"
		elseif not contents then
			contents = ""
		elseif field == "NI" then
			contents = ("\"%s\""):format(contents)
		elseif field == "AH" then
			contents = xrp:Height(contents, "user")
		elseif field == "AW" then
			contents = xrp:Weight(contents, "user")
		elseif field == "CU" or field == "DE" or field == "MO" or field == "HI" then
			-- Link URLs in scrolling fields.
			contents = contents:gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.com[^%w])", "http://%1"):gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.net[^%w])", "http://%1"):gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.org[^%w])", "http://%1"):gsub("(bit%.ly%/)", "http://%1"):gsub("(https?://)http://", "%1"):gsub("(https?://[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%%%-%.%_%~%:%/%?#%[%]%@%!%$%&%'%(%)%*%+%,%;%=]+)", "|H%1|h|cffc845fa[%1]|r|h")
		end
		viewer.fields[field]:SetText(contents)
		if field == "DE" or field == "HI" then
			viewer.lastFieldSet = GetTime()
		end
	end

	function Load(character)
		for _, field in ipairs(display) do
			SetField(field, character[field] or field == "RA" and xrp.values.GR[character.GR] or field == "RC" and xrp.values.GC[character.GC] or nil)
		end
		if xrp.characters[viewer.current].own then
			viewer.Menu:Hide()
		else
			viewer.Menu:Show()
		end
	end

	local supported = {}
	for _, field in ipairs(display) do
		supported[field] = true
	end
	function FIELD(event, name, field)
		if viewer.current == name and supported[field] then
			SetField(field, xrp.characters[name].fields[field])
		elseif viewer.current == name and (field == "GR" and not xrp.cache[name].fields.RA or field == "GC" and not xrp.cache[name].fields.RC) then
			SetField(field == "GR" and "RA" or field == "GC" and "RC", field == "GR" and xrp.values.GR[xrp.characters[name].fields.GR] or field == "GC" and xrp.values.GC[xrp.characters[name].fields.GC] or nil)
		end
	end
end

local function RECEIVE(event, name)
	if viewer.current == name then
		if viewer.failed == name then
			viewer.failed = nil
			Load(xrp.characters[name].fields)
		end
		local XC = viewer.XC:GetText()
		if not XC or not XC:find("^Received") then
			viewer.XC:SetText(event == "NOCHANGE" and "No changes." or "Received!")
		end
	end
end

local function CHUNK(event, name, chunk, totalchunks)
	if viewer.current == name then
		local XC = viewer.XC:GetText()
		if chunk ~= totalchunks or not XC or XC:find("^Receiv") then
			viewer.XC:SetFormattedText(totalchunks and (chunk == totalchunks and "Received! (%u/%u)" or "Receiving... (%u/%u)") or "Receiving... (%u/??)", chunk, totalchunks)
		end
	end
end

local function FAIL(event, name, reason)
	if viewer.current == name then
		viewer.failed = viewer.current
		if not viewer.XC:GetText() then
			if reason == "offline" then
				viewer.XC:SetText("Character is not online.")
			elseif reason == "faction" then
				viewer.XC:SetText("Character is opposite faction.")
			elseif reason == "nomsp" then
				viewer.XC:SetText("No RP addon appears to be active.")
			end
		end
	end
end

local Menu_baseMenuList
do
	local function Menu_Checked(self)
		if self.arg1 == 1 then
			return xrp.characters[UIDROPDOWNMENU_INIT_MENU:GetParent().current].bookmark ~= nil
		elseif self.arg1 == 2 then
			return xrp.characters[UIDROPDOWNMENU_INIT_MENU:GetParent().current].hide ~= nil
		end
	end
	local function Menu_Click(self, arg1, arg2, checked)
		if arg1 == 1 then
			xrp.characters[UIDROPDOWNMENU_OPEN_MENU:GetParent().current].bookmark = not checked
		elseif arg1 == 2 then
			xrp.characters[UIDROPDOWNMENU_OPEN_MENU:GetParent().current].hide = not checked
		elseif arg1 == 3 then
			xrp:View(UIDROPDOWNMENU_OPEN_MENU:GetParent().current)
		end
	end
	Menu_baseMenuList = {
		{ text = "Bookmark", arg1 = 1, isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Hide profile", arg1 = 2, isNotRadio = true, checked = Menu_Checked, func = Menu_Click, },
		{ text = "Refresh", arg1 = 3, notCheckable = true, func = Menu_Click, },
	}
end

local function Menu_PreClick(self, button, down)
	if self:GetParent().lastFieldSet + 30 > GetTime() then
		self.baseMenuList[3].disabled = true
	else
		self.baseMenuList[3].disabled = nil
	end
end

local function CreateViewer()
	local frame = CreateFrame("Frame", "XRPViewer", UIParent, "XRPViewerTemplate")
	frame.Menu.baseMenuList = Menu_baseMenuList
	frame.Menu:SetScript("PreClick", Menu_PreClick)
	xrp:HookEvent("FIELD", FIELD)
	xrp:HookEvent("RECEIVE", RECEIVE)
	xrp:HookEvent("NOCHANGE", RECEIVE)
	xrp:HookEvent("CHUNK", CHUNK)
	xrp:HookEvent("FAIL", FAIL)
	return frame
end

function xrp:View(player)
	local isUnit = UnitExists(player)
	if isUnit and not UnitIsPlayer(player) then return end
	if not viewer then
		viewer = CreateViewer()
	end
	if not player then
		if viewer:IsShown() then
			HideUIPanel(viewer)
			return
		end
		if viewer.current == UNKNOWN then
			viewer.failed = nil
			viewer.current = xrpPrivate.playerWithRealm
			SetPortraitTexture(viewer.portrait, "player")
			Load(self.units.player.fields)
		end
		ShowUIPanel(viewer)
		return
	end
	if not isUnit then
		local unit = Ambiguate(player, "none")
		isUnit = UnitExists(unit)
		player = isUnit and unit or self:Name(player):gsub("^%l", string.upper)
	end
	local newCurrent = isUnit and self:UnitName(player) or player
	local isRefresh = viewer.current == newCurrent
	viewer.current = newCurrent
	viewer.failed = nil
	viewer.XC:SetText("")
	Load(isUnit and self.units[player].fields or self.characters[player].fields)
	if isUnit and not isRefresh then
		SetPortraitTexture(viewer.portrait, player)
	elseif not isRefresh then
		local faction = self.characters[player].fields.GF
		SetPortraitToTexture(viewer.portrait, faction == "Alliance" and "Interface\\Icons\\INV_BannerPVP_02" or faction == "Horde" and "Interface\\Icons\\INV_BannerPVP_01" or "Interface\\Icons\\INV_Misc_Book_17")
	end
	ShowUIPanel(viewer)
	if not viewer.panes[1]:IsVisible() then
		viewer.Tab1:Click()
	end
end
