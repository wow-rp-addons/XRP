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

local addonName, xrpLocal = ...
local _S = xrpLocal.strings

XRP_AUTO = _S.AUTO
XRP_AUTOMATION = _S.AUTOMATION

local isWorgen, playerClass = select(2, UnitRace("player")) == "Worgen", select(2, UnitClassBase("player"))
if not (playerClass == "DRUID" or playerClass == "PRIEST" or playerClass == "SHAMAN") then
	playerClass = nil
end

local FORM_NAMES = {
	["DEFAULT"] = isWorgen and xrp.values.GR.Worgen or playerClass and (playerClass == "PRIEST" and _S.STANDARD or _S.HUMANOID) or _S.NOEQUIP,
	["CAT"] = _S.CAT,
	["BEAR"] = _S.BEAR,
	["MOONKIN"] = _S.MOONKIN,
	["ASTRAL"] = _S.ASTRAL,
	["AQUATIC"] = _S.AQUATIC,
	["TRAVEL"] = _S.TRAVEL,
	["FLIGHT"] = _S.FLIGHT,
	["TREANT"] = _S.TREANT,
	["SHADOWFORM"] = _S.SHADOWFORM,
	["GHOSTWOLF"] = _S.GHOST_WOLF,
	["HUMAN"] = xrp.values.GR.Human,
	["DEFAULT\30SHADOWFORM"] = _S.WORGEN_SHADOW,
	["HUMAN\30SHADOWFORM"] = _S.HUMAN_SHADOW,
}

local function MakeWords(text)
	local form, equipment = text:match("^([^\29]+)\29?([^\29]*)$")
	if not equipment or equipment == "" then
		return FORM_NAMES[form]
	elseif not isWorgen and not playerClass then
		return equipment
	else
		return SUBTITLE_FORMAT:format(FORM_NAMES[form], equipment)
	end
end

local function ToggleButtons(self)
	local form, profile = self.Form.contents, self.Profile.contents
	local changes = xrpLocal.auto[form] ~= profile
	if next(xrpSaved.auto) and not xrpLocal.auto["DEFAULT"] then
		self.Warning:Show()
		self.Warning:SetFormattedText(_S.WARN_FALLBACK, FORM_NAMES["DEFAULT"])
	else
		self.Warning:Hide()
	end
	self.Revert:SetEnabled(changes)
	self.Save:SetEnabled(changes)
end

function XRPEditorAutomationSave_OnClick(self, button, down)
	local parent = self:GetParent()
	local form, profile = parent.Form.contents, parent.Profile.contents
	xrpLocal.auto[form] = profile
	ToggleButtons(parent)
end

function XRPEditorAutomationRevert_OnClick(self, button, down)
	local parent = self:GetParent()
	local formProfile = xrpLocal.auto[parent.Form.contents]
	parent.Profile.contents = formProfile
	parent.Profile.Text:SetText(formProfile or NONE)
	ToggleButtons(parent)
end

do
	local function Profile_Checked(self)
		return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
	end

	local function Profile_Click(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.contents = arg1
			UIDROPDOWNMENU_OPEN_MENU.Text:SetText(arg1 or NONE)
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
	end

	local NONE = { text = NONE, checked = Profile_Checked, arg1 = nil, func = Profile_Click }
	function XRPEditorAutomationProfile_PreClick(self, button, down)
		local parent = self:GetParent()
		parent.baseMenuList = { NONE }
		for i, profile in ipairs(xrp.profiles:List()) do
			parent.baseMenuList[i + 1] = { text = profile, checked = Profile_Checked, arg1 = profile, func = Profile_Click }
		end
	end
end

local equipSets = {}
do
	local function equipSets_Click(self, arg1, arg2, checked)
		if not checked then
			local set = (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value
			UIDROPDOWNMENU_OPEN_MENU.contents = set
			UIDROPDOWNMENU_OPEN_MENU.Text:SetText(MakeWords(set))
			local Profile, setProfile = UIDROPDOWNMENU_OPEN_MENU:GetParent().Profile, xrpLocal.auto[set]
			Profile.contents = setProfile
			Profile.Text:SetText(setProfile or NONE)
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
		CloseDropDownMenus()
	end

	local function equipSets_Check(self)
		return (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value == UIDROPDOWNMENU_INIT_MENU.contents
	end

	local noSet = not isWorgen and not playerClass and { text = FORM_NAMES["DEFAULT"], value = "", checked = equipSets_Check, func = equipSets_Click, } or nil

	function XRPEditorAutomationForm_PreClick(self, button, down)
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
				text = _S.NO_SETS,
				disabled = true,
			}
		end
	end
end

do
	local function forms_Click(self, arg1, arg2, checked)
		if not checked then
			UIDROPDOWNMENU_OPEN_MENU.contents = self.value
			UIDROPDOWNMENU_OPEN_MENU.Text:SetText(MakeWords(self.value))
			local Profile, formProfile = UIDROPDOWNMENU_OPEN_MENU:GetParent().Profile, xrpLocal.auto[self.value]
			Profile.contents = formProfile
			Profile.Text:SetText(formProfile or NONE)
			ToggleButtons(UIDROPDOWNMENU_OPEN_MENU:GetParent())
		end
		CloseDropDownMenus()
	end

	local function forms_Check(self)
		return UIDROPDOWNMENU_INIT_MENU.contents == self.value
	end

	if isWorgen then
		if playerClass == "DRUID" then
			XRPEditorAutomationForm_baseMenuList = {
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
			XRPEditorAutomationForm_baseMenuList = {
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
			XRPEditorAutomationForm_baseMenuList = {
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
			XRPEditorAutomationForm_baseMenuList = {
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
			XRPEditorAutomationForm_baseMenuList = {
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
			XRPEditorAutomationForm_baseMenuList = {
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
			XRPEditorAutomationForm_baseMenuList = equipSets
		end
	end
end

function XRPEditorAutomation_OnShow(self)
	local selectedForm, needsUpdate = self.Form.contents, false
	if not selectedForm then
		selectedForm = "DEFAULT"
		self.Form.contents = "DEFAULT"
		self.Form.Text:SetText(MakeWords("DEFAULT"))
	end
	if selectedForm:find("\29", nil, true) then
		if not GetEquipmentSetInfoByName(selectedForm:match("^.*\29(.+)$")) then
			selectedForm = "DEFAULT"
			self.Form.Text:SetText(MakeWords(selectedForm))
			self.Form.contents = selectedForm
			needsUpdate = true
		end
	end
	needsUpdate = needsUpdate or not xrp.profiles[self.Profile.contents]
	if needsUpdate then
		local newProfile = xrpLocal.auto[selectedForm]
		self.Profile.contents = newProfile
		self.Profile.Text:SetText(newProfile or NONE)
	end
	ToggleButtons(self)
	PlaySound("UChatScrollButton")
end
