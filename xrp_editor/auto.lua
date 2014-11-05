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

local addonName, private = ...

private.auto = XRPAuto

local auto
xrp:HookLoad(function()
	auto = xrpSaved.auto
end)

local L = xrp.L

do
	local function infofunc(self, arg1, arg2, checked)
		if not checked then
			UIDropDownMenu_SetSelectedValue(private.auto.Profile, self.value)
			private.auto:CheckButtons()
		end
	end

	function private.auto.Profile:initialize(level, menuList)
		do
			local info = UIDropDownMenu_CreateInfo()
			info.text = xrp.L["None"]
			info.value = ""
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
		for _, value in ipairs(xrp.profiles:List()) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = value
			info.value = value
			info.func = infofunc
			UIDropDownMenu_AddButton(info)
		end
	end
end

local GR, GC = select(2, UnitRace("player")), select(2, UnitClassBase("player"))

local formNames = {
	["DEFAULT"] = L["No equipment set"],
	["CAT"] = L["Cat Form"],
	["BEAR"] = L["Bear Form"],
	["MOONKIN"] = L["Moonkin Form"],
	["ASTRAL"] = L["Astral Form"],
	["AQUATIC"] = L["Travel Form (Aquatic)"],
	["TRAVEL"] = L["Travel Form (Land)"],
	["FLIGHT"] = L["Travel Form (Flight)"],
	["TREANT"] = L["Treant Form"],
	["SHADOWFORM"] = L["Shadowform"],
	["GHOSTWOLF"] = L["Ghost Wolf"],
	["APOTHEOSIS"] = L["Dark Apotheosis"],
	["HUMAN"] = L["Human"],
	["DEFAULT\30SHADOWFORM"] = L["Shadowform (Worgen)"],
	["HUMAN\30SHADOWFORM"] = L["Shadowform (Human)"],
	["DEFAULT\30APOTHEOSIS"] = L["Dark Apotheosis (Worgen)"],
	["HUMAN\30APOTHEOSIS"] = L["Dark Apotheosis (Human)"],
}
if GR == "Worgen" then
	formNames["DEFAULT"] = L["Worgen"]
elseif GC == "PRIEST" then
	formNames["DEFAULT"] = L["Standard"]
elseif GC == "DRUID" or GC == "SHAMAN" then
	formNames["DEFAULT"] = L["Humanoid"]
end

local hasRace = GR == "Worgen"
local hasClass = GC == "DRUID" or GC == "PRIEST" or GC == "SHAMAN"

function private.auto.Form:MakeWords(text)
	local form, equipment = text:match("^([^\29]+)\29?([^\29]*)$")
	if not equipment or equipment == "" then
		return formNames[form]
	elseif not hasRace and not hasClass then
		return ("%s"):format(equipment)
	else
		return ("%s: %s"):format(formNames[form], equipment)
	end
end

function private.auto:AcceptForm()
	local form, profile = self.Form:GetText(), self.Profile:GetText()
	profile = profile ~= "" and profile or nil
	auto[form] = profile
	if profile then
		self.Status:SetFormattedText("The profile %s has been assigned to the %s form/set.", profile, self.Form:MakeWords(form))
	else
		self.Status:SetFormattedText("The assigned profile for the %s form/set has been removed.", self.Form:MakeWords(form))
	end
	self:CheckButtons()
	xrp:RecheckForm()
end

function private.auto:CheckButtons()
	local form, profile = self.Form:GetText(), self.Profile:GetText()
	local changes = auto[form] ~= (profile ~= "" and profile or nil)
	if next(auto) and not auto["DEFAULT"] then
		self.Warning:Show()
		self.Warning:SetFormattedText(L["You do not have a default/fallback profile. You should set a profile for \"%s\" to fix this."], formNames["DEFAULT"])
	else
		self.Warning:Hide()
	end
	self.Accept:SetEnabled(changes)
	self.Cancel:SetEnabled(changes)
end

local equipsets = {}
local update_EquipSets
do
	local function equipsets_Click(self, arg1, arg2, checked)
		if not checked then
			local value = (UIDROPDOWNMENU_MENU_VALUE or "default"):upper()..self.value
			private.auto.Form:SetValue(value)
		end
		CloseDropDownMenus()
	end

	local function equipsets_Check(self)
		local value = (UIDROPDOWNMENU_MENU_VALUE or "default"):upper()..self.value
		return private.auto.Form:GetText() == value
	end

	local noset = not hasRace and not hasClass and { text = formNames["DEFAULT"], value = "", checked = equipsets_Check, func = equipsets_Click, } or nil

	function update_EquipSets()
		wipe(equipsets) -- Keep table reference the same.
		equipsets[#equipsets + 1] = noset
		local numsets = GetNumEquipmentSets()
		if numsets and numsets > 0 then
			for i = 1, numsets do
				local name = GetEquipmentSetInfo(i)
				equipsets[#equipsets + 1] = {
					text = name,
					value = "\29"..name,
					checked = equipsets_Check,
					func = equipsets_Click,
				}
			end
		elseif not noset then
			equipsets[#equipsets + 1]  = {
				text = L["No equipment sets"],
				disabled = true,
			}
		end
	end
end

do
	-- This uses lower-case values (with string.upper) to work around a bug
	-- which causes our checked function to be overwritten if setting the
	-- raw value.
	local function forms_Click(self, arg1, arg2, checked)
		if not checked then
			private.auto.Form:SetValue(self.value:upper())
		end
		CloseDropDownMenus()
	end

	local function forms_Check(self)
		return private.auto.Form:GetText() == self.value:upper()
	end

	if GR == "Worgen" then
		if GC == "DRUID" then
			private.auto.Form.forms = {
				{ -- Worgen
					text = formNames["DEFAULT"],
					value = "default",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Human
					text = formNames["HUMAN"],
					value = "human",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Cat
					text = formNames["CAT"],
					value = "cat",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Bear
					text = formNames["BEAR"],
					value = "bear",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Moonkin
					text = formNames["MOONKIN"],
					value = "moonkin",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Astral
					text = formNames["ASTRAL"],
					value = "astral",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Travel
					text = formNames["TRAVEL"],
					value = "travel",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Flight
					text = formNames["FLIGHT"],
					value = "flight",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Aquatic
					text = formNames["AQUATIC"],
					value = "aquatic",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Treant
					text = formNames["TREANT"],
					value = "treant",
					func = forms_Click,
					checked = forms_Check,
				},
			}
		elseif GC == "PRIEST" then
			private.auto.Form.forms = {
				{ -- Worgen
					text = formNames["DEFAULT"],
					value = "default",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Human
					text = formNames["HUMAN"],
					value = "human",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Shadowform (Worgen)
					text = formNames["DEFAULT\30SHADOWFORM"],
					value = "default\30shadowform",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Shadowform (Human)
					text = formNames["HUMAN\30SHADOWFORM"],
					value = "human\30shadowform",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
			}
		else
			private.auto.Form.forms = {
				{ -- Worgen
					text = formNames["DEFAULT"],
					value = "default",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Human
					text = formNames["HUMAN"],
					value = "human",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
			}
		end
	else
		if GR == "DRUID" then
			private.auto.Form.forms = {
				{ -- Humanoid
					text = formNames["DEFAULT"],
					value = "default",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Cat
					text = formNames["CAT"],
					value = "cat",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Bear
					text = formNames["BEAR"],
					value = "bear",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Moonkin
					text = formNames["MOONKIN"],
					value = "moonkin",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Astral
					text = formNames["ASTRAL"],
					value = "astral",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Travel
					text = formNames["TRAVEL"],
					value = "travel",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Flight
					text = formNames["FLIGHT"],
					value = "flight",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Aquatic
					text = formNames["AQUATIC"],
					value = "aquatic",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Treant
					text = formNames["TREANT"],
					value = "treant",
					func = forms_Click,
					checked = forms_Check,
				}
			}
		elseif GC == "PRIEST" then
			private.auto.Form.forms = {
				{ -- Standard
					text = formNames["DEFAULT"],
					value = "default",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Shadowform
					text = formNames["SHADOWFORM"],
					value = "shadowform",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
			}
		elseif GC == "SHAMAN" then
			private.auto.Form.forms = {
				{ -- Humanoid
					text = formNames["DEFAULT"],
					value = "default",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipsets,
				},
				{ -- Ghost Wolf
					text = formNames["GHOSTWOLF"],
					value = "ghostwolf",
					func = forms_Click,
					checked = forms_Check,
				},
			}
		else
			private.auto.Form.forms = equipsets
		end
	end
end

_G[private.auto.Form:GetName().."Button"]:SetScript("OnClick", function(self)
	update_EquipSets()
	local parent = self:GetParent()
	ToggleDropDownMenu(nil, nil, parent, nil, nil, nil, parent.forms)
	PlaySound("igMainMenuOptionCheckBoxOn")
end)

private.auto.Form.initialize = EasyMenu_Initialize

function xrp:Auto(form)
	if form then
		private.auto.Form:SetValue(form)
	elseif private.auto:IsShown() then
		HideUIPanel(private.auto)
		return true
	end
	ShowUIPanel(private.auto)
	return true
end
