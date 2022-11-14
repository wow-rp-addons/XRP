--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local isWorgen, playerClass = select(2, UnitRace("player")) == "Worgen", select(2, UnitClass("player"))
if not (playerClass == "DRUID" or playerClass == "PRIEST" or playerClass == "SHAMAN") then
	playerClass = nil
end

local FORM_NAMES = {
	["DEFAULT"] = isWorgen and AddOn_XRP.Strings.Values.GR.Worgen or playerClass and (playerClass == "PRIEST" and L"Standard Form" or L"Humanoid Form") or L"No Equipment Set",
	["CAT"] = L"Cat Form",
	["BEAR"] = L"Bear Form",
	["MOONKIN"] = L"Moonkin Form",
	["ASTRAL"] = L"Astral Form",
	["AQUATIC"] = L"Travel Form (Aquatic)",
	["TRAVEL"] = L"Travel Form (Land)",
	["FLIGHT"] = L"Travel Form (Flight)",
	["TREANT"] = L"Treant Form",
	["SHADOWFORM"] = L"Shadowform",
	["GHOSTWOLF"] = L"Ghost Wolf",
	["HUMAN"] = AddOn_XRP.Strings.Values.GR.Human,
	["DEFAULT\030SHADOWFORM"] = L"Shadowform (Worgen)",
	["HUMAN\030SHADOWFORM"] = L"Shadowform (Human)",
	["MERCENARY"] = L"Mercenary Mode",
}

local function MakeWords(text)
	local form, equipment = text:match("^([^\029]+)\029?([^\029]*)$")
	if not equipment or equipment == "" then
		return FORM_NAMES[form]
	elseif not isWorgen and not playerClass then
		return equipment
	else
		return SUBTITLE_FORMAT:format(FORM_NAMES[form], equipment)
	end
end

local unsaved = {}
local function ToggleButtons(self)
	local changes = next(unsaved) ~= nil
	if next(xrpSaved.auto) and not AddOn.auto["DEFAULT"] and not unsaved["DEFAULT"] then
		self.Warning:Show()
		self.Warning:SetFormattedText(L"You should set a fallback profile for \"%s\".", FORM_NAMES["DEFAULT"])
	else
		self.Warning:Hide()
	end
	self.Revert:SetEnabled(changes)
	self.Save:SetEnabled(changes)
end

function XRPEditorAutomationSave_OnClick(self, button, down)
	for form, profile in pairs(unsaved) do
		AddOn.auto[form] = profile or nil
	end
	table.wipe(unsaved)
	ToggleButtons(self:GetParent())
end

function XRPEditorAutomationRevert_OnClick(self, button, down)
	local parent = self:GetParent()
	local formProfile = AddOn.auto[parent.Form.contents]
	parent.Profile.contents = formProfile
	parent.Profile.Text:SetText(formProfile or NONE)
	table.wipe(unsaved)
	ToggleButtons(parent)
end

local function Profile_Checked(self)
	return self.arg1 == MSA_DROPDOWNMENU_INIT_MENU.contents
end

local function Profile_Click(self, arg1, arg2, checked)
	if not checked then
		MSA_DROPDOWNMENU_INIT_MENU.contents = arg1
		MSA_DROPDOWNMENU_INIT_MENU.Text:SetText(arg1 or NONE)
		local parent = MSA_DROPDOWNMENU_INIT_MENU:GetParent()
		unsaved[parent.Form.contents] = arg1 or false
		ToggleButtons(parent)
	end
end

local NONE_MENU = { text = NONE, checked = Profile_Checked, arg1 = nil, func = Profile_Click }
function XRPEditorAutomationProfile_PreClick(self, button, down)
	local parent = self:GetParent()
	parent.baseMenuList = { NONE_MENU }
	for i, profile in ipairs(AddOn_XRP.GetProfileList()) do
		parent.baseMenuList[i + 1] = { text = profile, checked = Profile_Checked, arg1 = profile, func = Profile_Click }
	end
end

local equipSets = {}
local function equipSets_Click(self, arg1, arg2, checked)
	if not checked then
		local set = (MSA_DROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value
		MSA_DROPDOWNMENU_INIT_MENU.contents = set
		MSA_DROPDOWNMENU_INIT_MENU.Text:SetText(MakeWords(set))
		local parent = MSA_DROPDOWNMENU_INIT_MENU:GetParent()
		local setProfile
		if unsaved[set] ~= nil then
			setProfile = unsaved[set] or nil
		else
			setProfile = AddOn.auto[set]
		end
		parent.Profile.contents = setProfile
		parent.Profile.Text:SetText(setProfile or NONE)
		ToggleButtons(parent)
	end
	MSA_CloseDropDownMenus()
end

local function equipSets_Check(self)
	return (MSA_DROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value == MSA_DROPDOWNMENU_INIT_MENU.contents
end

local function forms_Click(self, arg1, arg2, checked)
	if not checked then
		MSA_DROPDOWNMENU_INIT_MENU.contents = self.value
		MSA_DROPDOWNMENU_INIT_MENU.Text:SetText(MakeWords(self.value))
		local parent = MSA_DROPDOWNMENU_INIT_MENU:GetParent()
		local formProfile
		if unsaved[self.value] ~= nil then
			formProfile = unsaved[self.value] or nil
		else
			formProfile = AddOn.auto[self.value]
		end
		parent.Profile.contents = formProfile
		parent.Profile.Text:SetText(formProfile or NONE)
		ToggleButtons(parent)
	end
	MSA_CloseDropDownMenus()
end

local function forms_Check(self)
	return MSA_DROPDOWNMENU_INIT_MENU.contents == self.value
end

local noSet = not isWorgen and not playerClass and { text = FORM_NAMES["DEFAULT"], value = "", checked = equipSets_Check, func = equipSets_Click, } or nil
local mercenarySet = not isWorgen and not playerClass and { text = FORM_NAMES["MERCENARY"], value = "MERCENARY", checked = forms_Check, func = forms_Click, } or nil

XRPEditorAutomationForm_Mixin = {
	preClick = function(self, button, down)
		table.wipe(equipSets) -- Keep table reference the same.
		equipSets[1] = noSet
		local sets = C_EquipmentSet.GetEquipmentSetIDs()
		if #sets > 0 then
			for i, id in ipairs(sets) do
				sets[i] = C_EquipmentSet.GetEquipmentSetInfo(id)
			end
			table.sort(sets)
			for i, name in ipairs(sets) do
				equipSets[#equipSets + 1] = {
					text = name,
					value = "\029" .. name,
					checked = equipSets_Check,
					func = equipSets_Click,
				}
			end
		elseif not noSet then
			equipSets[#equipSets + 1]  = {
				text = L"No Equipment Sets",
				disabled = true,
			}
		end
		equipSets[#equipSets + 1] = mercenarySet
	end,
}

local function FormMenuItem(form)
	local hasEquip = not AddOn.FORM_NO_EQUIPMENT[form]
	return {
		text = FORM_NAMES[form],
		value = form,
		func = forms_Click,
		checked = forms_Check,
		hasArrow = hasEquip and true or nil,
		menuList = hasEquip and equipSets or nil,
	}
end

if isWorgen then
	if playerClass == "DRUID" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("HUMAN"),
			FormMenuItem("CAT"),
			FormMenuItem("BEAR"),
			FormMenuItem("MOONKIN"),
			FormMenuItem("ASTRAL"),
			FormMenuItem("TRAVEL"),
			FormMenuItem("FLIGHT"),
			FormMenuItem("AQUATIC"),
			FormMenuItem("TREANT"),
			FormMenuItem("MERCENARY"),
		}
	elseif playerClass == "PRIEST" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("HUMAN"),
			FormMenuItem("DEFAULT\030SHADOWFORM"),
			FormMenuItem("HUMAN\030SHADOWFORM"),
			FormMenuItem("MERCENARY"),
		}
	else
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("HUMAN"),
			FormMenuItem("MERCENARY"),
		}
	end
else
	if playerClass == "DRUID" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("CAT"),
			FormMenuItem("BEAR"),
			FormMenuItem("MOONKIN"),
			FormMenuItem("ASTRAL"),
			FormMenuItem("TRAVEL"),
			FormMenuItem("FLIGHT"),
			FormMenuItem("AQUATIC"),
			FormMenuItem("TREANT"),
			FormMenuItem("MERCENARY"),
		}
	elseif playerClass == "PRIEST" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("SHADOWFORM"),
			FormMenuItem("MERCENARY"),
		}
	elseif playerClass == "SHAMAN" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("GHOSTWOLF"),
			FormMenuItem("MERCENARY"),
		}
	else
		XRPEditorAutomationForm_Mixin.baseMenuList = equipSets
	end
end

function XRPEditorAutomation_OnShow(self)
	local selectedForm, needsUpdate = self.Form.contents, false
	if not selectedForm then
		selectedForm = "DEFAULT"
		self.Form.contents = "DEFAULT"
		self.Form.Text:SetText(MakeWords("DEFAULT"))
	elseif selectedForm:find("\029", nil, true) then
		if not C_EquipmentSet.GetEquipmentSetID(selectedForm:match("^.*\029(.+)$")) then
			selectedForm = "DEFAULT"
			self.Form.Text:SetText(MakeWords(selectedForm))
			self.Form.contents = selectedForm
			needsUpdate = true
		end
	end
	for form, profile in pairs(unsaved) do
		if form:find("\029", nil, true) then
			if not C_EquipmentSet.GetEquipmentSetID(selectedForm:match("^.*\029(.+)$")) or not AddOn_XRP.Profiles[profile] then
				unsaved[form] = nil
			end
		end
	end
	needsUpdate = needsUpdate or not AddOn_XRP.Profiles[self.Profile.contents]
	if needsUpdate then
		local newProfile = AddOn.auto[selectedForm]
		self.Profile.contents = newProfile
		self.Profile.Text:SetText(newProfile or NONE)
	end
	ToggleButtons(self)
end
