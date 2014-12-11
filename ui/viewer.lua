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

local XRPViewer_SetField, XRPViewer_Load, XRPViewer_FIELD
do
	-- This will request fields in the order listed.
	local display = {
		"VA", "NA", "NH", "NI", "NT", "RA", "RC", "CU", -- In TT.
		"AE", "AH", "AW", "AG", "HH", "HB", "MO", -- Not in TT.
		"DE", "HI", -- High-bandwidth.
	}

	function XRPViewer_SetField(self, field, contents)
		contents = contents and xrp:StripEscapes(contents) or nil
		if field == "NA" then
			contents = contents or Ambiguate(self.current, "none") or UNKNOWN
		elseif field == "VA" then
			contents = contents and contents:gsub(";", ", ") or "Unknown/None"
		elseif not contents then
			contents = ""
		elseif field == "NI" then
			contents = ("\"%s\""):format(contents)
		elseif field == "AH" then
			contents = xrp:ConvertHeight(contents, "user")
		elseif field == "AW" then
			contents = xrp:ConvertWeight(contents, "user")
		elseif field == "CU" or field == "DE" or field == "MO" or field == "HI" then
			contents = xrp:LinkURLs(contents)
		end
		self.fields[field]:SetText(contents)
	end

	function XRPViewer_Load(self, character)
		for _, field in ipairs(display) do
			self:SetField(field, character[field] or (field == "RA" and xrp.values.GR[character.GR]) or (field == "RC" and xrp.values.GC[character.GC]) or nil)
		end
		if xrp.characters[self.current].own then
			self.Menu:Hide()
		else
			self.Menu:Show()
		end
	end

	local supported = {}
	for _, field in ipairs(display) do
		supported[field] = true
	end
	function XRPViewer_FIELD(event, name, field)
		local viewer = xrpPrivate.viewer
		if viewer.current == name and supported[field] then
			viewer:SetField(field, xrp.characters[name].fields[field])
		elseif viewer.current == name and (field == "GR" and not xrp.cache[name].fields.RA) or (field == "GC" and not xrp.cache[name].fields.RC) then
			viewer:SetField((field == "GR" and "RA") or (field == "GC" and "RC"), (field == "GR" and xrp.values.GR[xrp.characters[name].fields.GR]) or (field == "GC" and xrp.values.GC[xrp.characters[name].fields.GC]) or nil)
		end
	end
end

local function XRPViewer_RECEIVE(event, name)
	local viewer = xrpPrivate.viewer
	if viewer.current == name then
		if viewer.failed == name then
			viewer.failed = nil
			viewer:Load(xrp.characters[name].fields)
		end
		local XC = viewer.XC:GetText()
		if not XC or not XC:find("^Received") then
			viewer.XC:SetText("Received!")
		end
	end
end

local function XRPViewer_NOCHANGE(event, name)
	local viewer = xrpPrivate.viewer
	if viewer.current == name then
		if viewer.failed == name then
			viewer.failed = nil
			viewer:Load(xrp.characters[name].fields)
		end
		local XC = viewer.XC:GetText()
		if not XC or not XC:find("^Received") then
			viewer.XC:SetText("No changes.")
		end
	end
end

local function XRPViewer_CHUNK(event, name, chunk, totalchunks)
	local viewer = xrpPrivate.viewer
	if viewer.current == name then
		local XC = viewer.XC:GetText()
		if chunk ~= totalchunks or not XC or XC:find("^Receiv") then
			viewer.XC:SetFormattedText(totalchunks and (chunk == totalchunks and "Received! (%u/%u)" or "Receiving... (%u/%u)") or "Receiving... (%u/??)", chunk, totalchunks)
		end
	end
end

local function XRPViewer_FAIL(event, name, reason)
	local viewer = xrpPrivate.viewer
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

local XRPViewerMenu_baseMenuList
do
	local function XRPViewerMenu_Checked(self)
		if self.arg1 == 1 then
			return xrp.characters[UIDROPDOWNMENU_INIT_MENU:GetParent().current].bookmark ~= nil
		elseif self.arg1 == 2 then
			return xrp.characters[UIDROPDOWNMENU_INIT_MENU:GetParent().current].hide ~= nil
		end
	end
	local function XRPViewerMenu_Click(self, arg1, arg2, checked)
		if arg1 == 1 then
			xrp.characters[UIDROPDOWNMENU_OPEN_MENU:GetParent().current].bookmark = not checked
		elseif arg1 == 2 then
			xrp.characters[UIDROPDOWNMENU_OPEN_MENU:GetParent().current].hide = not checked
		elseif arg1 == 3 then
			xrp:View(UIDROPDOWNMENU_OPEN_MENU:GetParent().current)
		end
	end
	XRPViewerMenu_baseMenuList = {
		{ text = "Bookmark", arg1 = 1, isNotRadio = true, checked = XRPViewerMenu_Checked, func = XRPViewerMenu_Click, },
		{ text = "Hide profile", arg1 = 2, isNotRadio = true, checked = XRPViewerMenu_Checked, func = XRPViewerMenu_Click, },
		{ text = "Refresh", arg1 = 3, notCheckable = true, func = XRPViewerMenu_Click, },
	}
end

function xrpPrivate:GetViewer()
	if xrpPrivate.viewer then
		return xrpPrivate.viewer
	end
	local frame = CreateFrame("Frame", "XRPViewer", UIParent, "XRPViewerTemplate")
	frame.Menu.baseMenuList = XRPViewerMenu_baseMenuList
	frame.SetField = XRPViewer_SetField
	frame.Load = XRPViewer_Load
	xrp:HookEvent("FIELD", XRPViewer_FIELD)
	xrp:HookEvent("RECEIVE", XRPViewer_RECEIVE)
	xrp:HookEvent("NOCHANGE", XRPViewer_NOCHANGE)
	xrp:HookEvent("CHUNK", XRPViewer_CHUNK)
	xrp:HookEvent("FAIL", XRPViewer_FAIL)
	xrpPrivate.viewer = frame
	return frame
end
