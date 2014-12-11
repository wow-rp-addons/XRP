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

local GR, GC = select(2, UnitRace("player")), select(2, UnitClassBase("player"))

local formNames = {
	["DEFAULT"] = "No equipment set",
	["CAT"] = "Cat Form",
	["BEAR"] = "Bear Form",
	["MOONKIN"] = "Moonkin Form",
	["ASTRAL"] = "Astral Form",
	["AQUATIC"] = "Travel Form (Aquatic)",
	["TRAVEL"] = "Travel Form (Land)",
	["FLIGHT"] = "Travel Form (Flight)",
	["TREANT"] = "Treant Form",
	["SHADOWFORM"] = "Shadowform",
	["GHOSTWOLF"] = "Ghost Wolf",
	["HUMAN"] = "Human",
	["DEFAULT\30SHADOWFORM"] = "Shadowform (Worgen)",
	["HUMAN\30SHADOWFORM"] = "Shadowform (Human)",
}
if GR == "Worgen" then
	formNames["DEFAULT"] = "Worgen"
elseif GC == "PRIEST" then
	formNames["DEFAULT"] = "Standard"
elseif GC == "DRUID" or GC == "SHAMAN" then
	formNames["DEFAULT"] = "Humanoid"
end

local hasRace = GR == "Worgen"
local hasClass = GC == "DRUID" or GC == "PRIEST" or GC == "SHAMAN"

local function MakeWords(text)
	local form, equipment = text:match("^([^\29]+)\29?([^\29]*)$")
	if not equipment or equipment == "" then
		return formNames[form]
	elseif not hasRace and not hasClass then
		return ("%s"):format(equipment)
	else
		return ("%s: %s"):format(formNames[form], equipment)
	end
end

local function ToggleButtons(self)
	local form, profile = self.Form.contents, self.Profile.contents
	local changes = xrpSaved.auto[form] ~= (profile ~= "" and profile or nil)
	if next(xrpSaved.auto) and not xrpSaved.auto["DEFAULT"] then
		self.Warning:Show()
		self.Warning:SetFormattedText("You should set a fallback profile for \"%s\".", formNames["DEFAULT"])
	elseif self.Warning:IsVisible() then
		self.Warning:Hide()
	end
	self.Revert:SetEnabled(changes)
	self.Save:SetEnabled(changes)
end

local function Save_OnClick(self, button, down)
	local parent = self:GetParent()
	local form, profile = parent.Form.contents, parent.Profile.contents
	profile = profile ~= "" and profile or nil
	xrpSaved.auto[form] = profile
	ToggleButtons(parent)
	xrp:RecheckForm()
end

local function Revert_OnClick(self, button, down)
	local parent = self:GetParent()
	local formProfile = xrpSaved.auto[parent.Form.contents]
	parent.Profile.contents = formProfile or ""
	parent.Profile.MenuText:SetText(formProfile or "None")
	ToggleButtons(parent)
end

local Profile_PreClick
do
	local function Profile_Checked(self)
		return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
	end

	local function Profile_Click(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.contents = arg1
			UIDROPDOWNMENU_OPEN_MENU.MenuText:SetText(arg1 ~= "" and arg1 or "None")
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
	end

	local none = { text = "None", checked = Profile_Checked, arg1 = "", func = Profile_Click }
	function Profile_PreClick(self, button, down)
		local parent = self:GetParent()
		parent.baseMenuList = { none }
		for _, profile in ipairs(xrp.profiles:List()) do
			parent.baseMenuList[#parent.baseMenuList + 1] = { text = profile, checked = Profile_Checked, arg1 = profile, func = Profile_Click }
		end
	end
end

local equipSets = {}
local Form_PreClick
do
	local function equipSets_Click(self, arg1, arg2, checked)
		if not checked then
			local set = (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT")..self.value
			UIDROPDOWNMENU_OPEN_MENU.contents = set
			UIDROPDOWNMENU_OPEN_MENU.MenuText:SetText(MakeWords(set))
			local Profile, setProfile = UIDROPDOWNMENU_OPEN_MENU:GetParent().Profile, xrpSaved.auto[set]
			Profile.contents = setProfile or ""
			Profile.MenuText:SetText(setProfile or "None")
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
		CloseDropDownMenus()
	end

	local function equipSets_Check(self)
		return (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT")..self.value == UIDROPDOWNMENU_INIT_MENU.contents
	end

	local noset = not hasRace and not hasClass and { text = formNames["DEFAULT"], value = "", checked = equipSets_Check, func = equipSets_Click, } or nil

	function Form_PreClick(self, button, down)
		wipe(equipSets) -- Keep table reference the same.
		equipSets[#equipSets + 1] = noset
		local numsets = GetNumEquipmentSets()
		if numsets and numsets > 0 then
			for i = 1, numsets do
				local name = GetEquipmentSetInfo(i)
				equipSets[#equipSets + 1] = {
					text = name,
					value = "\29"..name,
					checked = equipSets_Check,
					func = equipSets_Click,
				}
			end
		elseif not noset then
			equipSets[#equipSets + 1]  = {
				text = "No equipment sets",
				disabled = true,
			}
		end
	end
end

local Form_baseMenuList
do
	local function forms_Click(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.contents = self.value
			UIDROPDOWNMENU_OPEN_MENU.MenuText:SetText(MakeWords(self.value))
			local Profile, formProfile = UIDROPDOWNMENU_OPEN_MENU:GetParent().Profile, xrpSaved.auto[self.value]
			Profile.contents = formProfile or ""
			Profile.MenuText:SetText(formProfile or "None")
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
		CloseDropDownMenus()
	end

	local function forms_Check(self)
		return UIDROPDOWNMENU_INIT_MENU.contents == self.value
	end

	if GR == "Worgen" then
		if GC == "DRUID" then
			Form_baseMenuList = {
				{ -- Worgen
					text = formNames["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Human
					text = formNames["HUMAN"],
					value = "HUMAN",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Cat
					text = formNames["CAT"],
					value = "CAT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Bear
					text = formNames["BEAR"],
					value = "BEAR",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Moonkin
					text = formNames["MOONKIN"],
					value = "MOONKIN",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Astral
					text = formNames["ASTRAL"],
					value = "ASTRAL",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Travel
					text = formNames["TRAVEL"],
					value = "TRAVEL",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Flight
					text = formNames["FLIGHT"],
					value = "FLIGHT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Aquatic
					text = formNames["AQUATIC"],
					value = "AQUATIC",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Treant
					text = formNames["TREANT"],
					value = "TREANT",
					func = forms_Click,
					checked = forms_Check,
				},
			}
		elseif GC == "PRIEST" then
			Form_baseMenuList = {
				{ -- Worgen
					text = formNames["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Human
					text = formNames["HUMAN"],
					value = "HUMAN",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Shadowform (Worgen)
					text = formNames["DEFAULT\30SHADOWFORM"],
					value = "DEFAULT\30SHADOWFORM",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Shadowform (Human)
					text = formNames["HUMAN\30SHADOWFORM"],
					value = "HUMAN\30SHADOWFORM",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
			}
		else
			Form_baseMenuList = {
				{ -- Worgen
					text = formNames["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Human
					text = formNames["HUMAN"],
					value = "HUMAN",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
			}
		end
	else
		if GR == "DRUID" then
			Form_baseMenuList = {
				{ -- Humanoid
					text = formNames["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Cat
					text = formNames["CAT"],
					value = "CAT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Bear
					text = formNames["BEAR"],
					value = "BEAR",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Moonkin
					text = formNames["MOONKIN"],
					value = "MOONKIN",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Astral
					text = formNames["ASTRAL"],
					value = "ASTRAL",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Travel
					text = formNames["TRAVEL"],
					value = "TRAVEL",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Flight
					text = formNames["FLIGHT"],
					value = "FLIGHT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Aquatic
					text = formNames["AQUATIC"],
					value = "AQUATIC",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Treant
					text = formNames["TREANT"],
					value = "TREANT",
					func = forms_Click,
					checked = forms_Check,
				}
			}
		elseif GC == "PRIEST" then
			Form_baseMenuList = {
				{ -- Standard
					text = formNames["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Shadowform
					text = formNames["SHADOWFORM"],
					value = "SHADOWFORM",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
			}
		elseif GC == "SHAMAN" then
			Form_baseMenuList = {
				{ -- Humanoid
					text = formNames["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Ghost Wolf
					text = formNames["GHOSTWOLF"],
					value = "GHOSTWOLF",
					func = forms_Click,
					checked = forms_Check,
				},
			}
		else
			Form_baseMenuList = equipSets
		end
	end
end

function xrpPrivate:SetupAutomationFrame(frame)
	frame.Form.ArrowButton:SetScript("PreClick", Form_PreClick)
	frame.Form.baseMenuList = Form_baseMenuList
	frame.Profile.ArrowButton:SetScript("PreClick", Profile_PreClick)
	frame.Save:SetScript("OnClick", Save_OnClick)
	frame.Revert:SetScript("OnClick", Revert_OnClick)

	frame.Form.contents = "DEFAULT"
	frame.Form.MenuText:SetText(MakeWords("DEFAULT"))
	local defaultProfile = xrpSaved.auto["DEFAULT"]
	frame.Profile.contents = defaultProfile or ""
	frame.Profile.MenuText:SetText(defaultProfile or "None")
	ToggleButtons(frame)
end
