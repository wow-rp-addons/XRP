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

local isWorgen, playerClass = select(2, UnitRace("player")) == "Worgen", select(2, UnitClassBase("player"))
if not (playerClass == "DRUID" or playerClass == "PRIEST" or playerClass == "SHAMAN") then
	playerClass = nil
end

local FORM_NAMES = {
	["DEFAULT"] = isWorgen and "Worgen" or playerClass and (playerClass == "PRIEST" and "Standard" or "Humanoid") or "No equipment set",
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

local function MakeWords(text)
	local form, equipment = text:match("^([^\29]+)\29?([^\29]*)$")
	if not equipment or equipment == "" then
		return FORM_NAMES[form]
	elseif not isWorgen and not playerClass then
		return equipment
	else
		return ("%s: %s"):format(FORM_NAMES[form], equipment)
	end
end

local function ToggleButtons(self)
	local form, profile = self.Form.contents, self.Profile.contents
	local changes = xrpPrivate.auto[form] ~= profile
	if next(xrpSaved.auto) and not xrpPrivate.auto["DEFAULT"] then
		self.Warning:Show()
		self.Warning:SetFormattedText("You should set a fallback profile for \"%s\".", FORM_NAMES["DEFAULT"])
	else
		self.Warning:Hide()
	end
	self.Revert:SetEnabled(changes)
	self.Save:SetEnabled(changes)
end

XRPEditor.Automation.Save:SetScript("OnClick", function(self, button, down)
	local parent = self:GetParent()
	local form, profile = parent.Form.contents, parent.Profile.contents
	xrpPrivate.auto[form] = profile
	ToggleButtons(parent)
end)

XRPEditor.Automation.Revert:SetScript("OnClick", function(self, button, down)
	local parent = self:GetParent()
	local formProfile = xrpPrivate.auto[parent.Form.contents]
	parent.Profile.contents = formProfile
	parent.Profile.MenuText:SetText(formProfile or "None")
	ToggleButtons(parent)
end)

do
	local function Profile_Checked(self)
		return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
	end

	local function Profile_Click(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.contents = arg1
			UIDROPDOWNMENU_OPEN_MENU.MenuText:SetText(arg1 or "None")
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
	end

	local NONE = { text = "None", checked = Profile_Checked, arg1 = nil, func = Profile_Click }
	XRPEditor.Automation.Profile.ArrowButton:SetScript("PreClick", function(self, button, down)
		local parent = self:GetParent()
		parent.baseMenuList = { NONE }
		for i, profile in ipairs(xrpPrivate.profiles:List()) do
			parent.baseMenuList[i + 1] = { text = profile, checked = Profile_Checked, arg1 = profile, func = Profile_Click }
		end
	end)
end

local equipSets = {}
do
	local function equipSets_Click(self, arg1, arg2, checked)
		if not checked then
			local set = (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value
			UIDROPDOWNMENU_OPEN_MENU.contents = set
			UIDROPDOWNMENU_OPEN_MENU.MenuText:SetText(MakeWords(set))
			local Profile, setProfile = UIDROPDOWNMENU_OPEN_MENU:GetParent().Profile, xrpPrivate.auto[set]
			Profile.contents = setProfile
			Profile.MenuText:SetText(setProfile or "None")
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
		CloseDropDownMenus()
	end

	local function equipSets_Check(self)
		return (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value == UIDROPDOWNMENU_INIT_MENU.contents
	end

	local noSet = not isWorgen and not playerClass and { text = FORM_NAMES["DEFAULT"], value = "", checked = equipSets_Check, func = equipSets_Click, } or nil

	XRPEditor.Automation.Form.ArrowButton:SetScript("PreClick", function(self, button, down)
		table.wipe(equipSets) -- Keep table reference the same.
		equipSets[1] = noSet
		local numsets = GetNumEquipmentSets()
		if numsets and numsets > 0 then
			for i = 1, numsets do
				local name = GetEquipmentSetInfo(i)
				equipSets[#equipSets + 1] = {
					text = name,
					value = "\29" .. name,
					checked = equipSets_Check,
					func = equipSets_Click,
				}
			end
		elseif not noSet then
			equipSets[#equipSets + 1]  = {
				text = "No equipment sets",
				disabled = true,
			}
		end
	end)
end

do
	local function forms_Click(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.contents = self.value
			UIDROPDOWNMENU_OPEN_MENU.MenuText:SetText(MakeWords(self.value))
			local Profile, formProfile = UIDROPDOWNMENU_OPEN_MENU:GetParent().Profile, xrpPrivate.auto[self.value]
			Profile.contents = formProfile
			Profile.MenuText:SetText(formProfile or "None")
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
		CloseDropDownMenus()
	end

	local function forms_Check(self)
		return UIDROPDOWNMENU_INIT_MENU.contents == self.value
	end

	if isWorgen then
		if playerClass == "DRUID" then
			XRPEditor.Automation.Form.baseMenuList = {
				{ -- Worgen
					text = FORM_NAMES["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Human
					text = FORM_NAMES["HUMAN"],
					value = "HUMAN",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Cat
					text = FORM_NAMES["CAT"],
					value = "CAT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Bear
					text = FORM_NAMES["BEAR"],
					value = "BEAR",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Moonkin
					text = FORM_NAMES["MOONKIN"],
					value = "MOONKIN",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Astral
					text = FORM_NAMES["ASTRAL"],
					value = "ASTRAL",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Travel
					text = FORM_NAMES["TRAVEL"],
					value = "TRAVEL",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Flight
					text = FORM_NAMES["FLIGHT"],
					value = "FLIGHT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Aquatic
					text = FORM_NAMES["AQUATIC"],
					value = "AQUATIC",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Treant
					text = FORM_NAMES["TREANT"],
					value = "TREANT",
					func = forms_Click,
					checked = forms_Check,
				},
			}
		elseif playerClass == "PRIEST" then
			XRPEditor.Automation.Form.baseMenuList = {
				{ -- Worgen
					text = FORM_NAMES["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Human
					text = FORM_NAMES["HUMAN"],
					value = "HUMAN",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Shadowform (Worgen)
					text = FORM_NAMES["DEFAULT\30SHADOWFORM"],
					value = "DEFAULT\30SHADOWFORM",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Shadowform (Human)
					text = FORM_NAMES["HUMAN\30SHADOWFORM"],
					value = "HUMAN\30SHADOWFORM",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
			}
		else
			XRPEditor.Automation.Form.baseMenuList = {
				{ -- Worgen
					text = FORM_NAMES["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Human
					text = FORM_NAMES["HUMAN"],
					value = "HUMAN",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
			}
		end
	else
		if playerClass == "DRUID" then
			XRPEditor.Automation.Form.baseMenuList = {
				{ -- Humanoid
					text = FORM_NAMES["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Cat
					text = FORM_NAMES["CAT"],
					value = "CAT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Bear
					text = FORM_NAMES["BEAR"],
					value = "BEAR",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Moonkin
					text = FORM_NAMES["MOONKIN"],
					value = "MOONKIN",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Astral
					text = FORM_NAMES["ASTRAL"],
					value = "ASTRAL",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Travel
					text = FORM_NAMES["TRAVEL"],
					value = "TRAVEL",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Flight
					text = FORM_NAMES["FLIGHT"],
					value = "FLIGHT",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Aquatic
					text = FORM_NAMES["AQUATIC"],
					value = "AQUATIC",
					func = forms_Click,
					checked = forms_Check,
				},
				{ -- Treant
					text = FORM_NAMES["TREANT"],
					value = "TREANT",
					func = forms_Click,
					checked = forms_Check,
				}
			}
		elseif playerClass == "PRIEST" then
			XRPEditor.Automation.Form.baseMenuList = {
				{ -- Standard
					text = FORM_NAMES["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Shadowform
					text = FORM_NAMES["SHADOWFORM"],
					value = "SHADOWFORM",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
			}
		elseif playerClass == "SHAMAN" then
			XRPEditor.Automation.Form.baseMenuList = {
				{ -- Humanoid
					text = FORM_NAMES["DEFAULT"],
					value = "DEFAULT",
					func = forms_Click,
					checked = forms_Check,
					hasArrow = true,
					menuList = equipSets,
				},
				{ -- Ghost Wolf
					text = FORM_NAMES["GHOSTWOLF"],
					value = "GHOSTWOLF",
					func = forms_Click,
					checked = forms_Check,
				},
			}
		else
			XRPEditor.Automation.Form.baseMenuList = equipSets
		end
	end
end

XRPEditor.Automation:SetScript("OnShow", function(self)
	local selectedForm, needsUpdate = self.Form.contents, false
	if not selectedForm then
		selectedForm = "DEFAULT"
		self.Form.contents = "DEFAULT"
		self.Form.MenuText:SetText(MakeWords("DEFAULT"))
	end
	if selectedForm:find("\29", nil, true) then
		if not GetEquipmentSetInfoByName(selectedForm:match("^.*\29(.+)$")) then
			selectedForm = "DEFAULT"
			self.Form.MenuText:SetText(MakeWords(selectedForm))
			self.Form.contents = selectedForm
			needsUpdate = true
		end
	end
	needsUpdate = needsUpdate or not xrpPrivate.profiles[self.Profile.contents]
	if needsUpdate then
		local newProfile = xrpPrivate.auto[selectedForm]
		self.Profile.contents = newProfile
		self.Profile.MenuText:SetText(newProfile or "None")
	end
	ToggleButtons(self)
	PlaySound("UChatScrollButton")
end)
