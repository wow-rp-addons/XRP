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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

AddOn_XRP.Profiles = {}

local MAX_DEPTH = 50

local NO_PROFILE = {
	TT = true, VP = true, VA = true, VW = true, GC = true, GF = true,
	GR = true, GS = true, GU = true,
}

AddOn.RegisterGameEventCallback("ADDON_LOADED", function(event, addon)
	local addonString = "%s/%s"
	local VA = { addonString:format(FOLDER_NAME, GetAddOnMetadata(FOLDER_NAME, "Version")) }
	for i, addon in ipairs({ "GHI", "Tongues" }) do
		if IsAddOnLoaded(addon) then
			VA[#VA + 1] = addonString:format(addon, GetAddOnMetadata(addon, "Version"))
		end
	end
	local VW = { GetAddOnMetadata(FOLDER_NAME, "X-WoW-Version"), GetAddOnMetadata(FOLDER_NAME, "X-WoW-Build"), GetAddOnMetadata(FOLDER_NAME, "X-Interface") }
	AddOn.FallbackFields = {
		FC = "1",
		NA = AddOn.characterName,
		VA = table.concat(VA, ";"),
		VW = table.concat(VW, ";"),
	}

	if not xrpSaved.overrides.logout or xrpSaved.overrides.logout + 900 < time() then
		xrpSaved.overrides = {}
	else
		xrpSaved.overrides.logout = nil
	end

	AddOn.ProfileUpdate()
end)

AddOn.RegisterGameEventCallback("PLAYER_LOGOUT", function(event)
	-- Note: This code must be thoroughly tested if any changes are
	-- made. If there are any errors in here, they are not visible in
	-- any manner in-game.
	if next(xrpSaved.overrides) then
		xrpSaved.overrides.logout = time()
	end
end)

function AddOn_XRP.SetField(field, contents)
	if type(field) ~= "string" then
		error("AddOn_XRP.SetField(): field: expected string, got " .. type(field), 2)
	elseif field == "PE" then
		if contents and type(contents) ~= "table" then
			error("AddOn_XRP.SetField(): contents (PE): expected table or nil, got " .. type(contents), 2)
		end
		contents = AddOn.PEToString(contents)
	elseif contents and type(contents) ~= "string" then
		error("AddOn_XRP.SetField(): contents: expected string or nil, got " .. type(contents), 2)
	elseif NO_PROFILE[field] or not field:find("^%u%u$") then
		error("AddOn_XRP.SetField(): field: invalid field:" .. field, 2)
	end
	if xrpSaved.overrides[field] == contents then
		return
	end
	xrpSaved.overrides[field] = contents
	AddOn.ProfileUpdate(field)
end

function AddOn.GetFullCurrentProfile()
	local fields = {}
	local profiles, inherit = { xrpSaved.profiles[xrpSaved.selected] }, xrpSaved.profiles[xrpSaved.selected].parent
	for i = 1, MAX_DEPTH do
		if not xrpSaved.profiles[inherit] then
			break
		end
		profiles[#profiles + 1] = xrpSaved.profiles[inherit]
		inherit = xrpSaved.profiles[inherit].parent
	end
	for i = #profiles, 1, -1 do
		local profile = profiles[i]
		for field, doInherit in pairs(profile.inherits) do
			if doInherit == false then
				fields[field] = nil
			end
		end
		for field, contents in pairs(profile.fields) do
			fields[field] = contents
		end
	end
	for field, contents in pairs(AddOn.FallbackFields) do
		if not fields[field] then
			fields[field] = contents
		end
	end
	for field, contents in pairs(xrpSaved.overrides) do
		if contents == "" then
			fields[field] = nil
		else
			fields[field] = contents
		end
	end
	if fields.AW then
		fields.AW = AddOn.ConvertWeight(fields.AW, "msp")
	end
	if fields.AH then
		fields.AH = AddOn.ConvertHeight(fields.AH, "msp")
	end
	return fields
end

function AddOn.GetProfileField(field, profile)
	local profile = xrpSaved.profiles[profile or xrpSaved.selected]
	for i = 0, MAX_DEPTH do
		if profile.fields[field] then
			return profile.fields[field]
		elseif profile.inherits[field] == false or not xrpSaved.profiles[profile.parent] then
			return nil
		else
			profile = xrpSaved.profiles[profile.parent]
		end
	end
	return nil
end

local FORBIDDEN_NAMES = {
	SELECTED = true,
}

function AddOn_XRP.AddProfile(name)
	if type(name) ~= "string" then
		error("AddOn_XRP.AddProfile(): name: expected string, got " .. type(name), 2)
	elseif FORBIDDEN_NAMES[name] then
		error("AddOn_XRP.AddProfile(): name: name is forbidden: " .. name, 2)
	elseif xrpSaved.profiles[name] then
		error("AddOn_XRP.AddProfile(): name: profile already exists: " .. name, 2)
	end
	xrpSaved.profiles[name] = {
		fields = {},
		inherits = {},
	}
end

function AddOn_XRP.GetProfileList()
	local list = {}
	for name in pairs(xrpSaved.profiles) do
		list[#list + 1] = name
	end
	table.sort(list)
	return list
end

function AddOn_XRP.SetProfile(name, isAutomated)
	if type(name) ~= "string" then
		error("AddOn_XRP.SetProfile(): name: expected string, got " .. type(name), 2)
	elseif FORBIDDEN_NAMES[name] then
		error("AddOn_XRP.SetProfile(): name: name is forbidden: " .. name, 2)
	elseif not xrpSaved.profiles[name] then
		error("AddOn_XRP.SetProfile(): name: profile doesn't exist: " .. name, 2)
	end
	if xrpSaved.selected ~= name then
		xrpSaved.selected = name
		if not isAutomated then
			xrpSaved.overrides = {}
		end
		AddOn.ProfileUpdate()
	end
end

local function IsInUse(name, field)
	local testName = xrpSaved.selected
	for i = 0, MAX_DEPTH do
		local profile = xrpSaved.profiles[testName]
		if testName == name then
			return true
		elseif field and (profile.fields[field] or profile.inherits[field] == false) then
			return false
		elseif xrpSaved.profiles[profile.parent] then
			testName = profile.parent
		else
			return false
		end
	end
	return false
end

-- TODO: more error checking when indexing ProfileNameMap?
local ProfileNameMap = setmetatable({}, AddOn.WeakKeyMetatable)

local ProfileMethods = {}

function ProfileMethods:Delete()
	local name = ProfileNameMap[self]
	if IsInUse(name) then
		error("AddOn_XRP.Profiles: ProfileTable:Delete(): in-use profile cannot be deleted: " .. name, 2)
	end
	local profiles = xrpSaved.profiles
	for otherName, profile in pairs(profiles) do
		if profile.parent == name then
			profile.parent = profiles[name].parent
		end
	end
	for form, autoProfileName in pairs(xrpSaved.auto) do
		if autoProfileName == name then
			AddOn.auto[form] = nil
		end
	end
	profiles[name] = nil
end

function ProfileMethods:Rename(name)
	if type(name) ~= "string" then
		error("AddOn_XRP.Profiles: ProfileTable:Rename(): name: expected string, got " .. type(name), 2)
	elseif FORBIDDEN_NAMES[name] then
		error("AddOn_XRP.Profiles: ProfileTable:Rename(): name is forbidden: " .. name, 2)
	elseif xrpSaved.profiles[name] then
		error("AddOn_XRP.Profiles: ProfileTable:Rename(): profile already exists: " .. name, 2)
	end
	local oldName = ProfileNameMap[self]
	xrpSaved.profiles[name] = xrpSaved.profiles[oldName]
	for profileName, profile in pairs(xrpSaved.profiles) do
		if profile.parent == oldName then
			profile.parent = name
		end
	end
	if xrpSaved.selected == oldName then
		xrpSaved.selected = name
	end
	ProfileNameMap[self] = name
	for key, value in pairs(self) do
		if ProfileNameMap[value] then
			ProfileNameMap[value] = name
		end
	end
	for form, profileName in pairs(xrpSaved.auto) do
		if profileName == oldName then
			xrpSaved.auto[form] = name
		end
	end
	xrpSaved.profiles[oldName] = nil
end

function ProfileMethods:Copy(name)
	if type(name) ~= "string" then
		error("AddOn_XRP.Profiles: ProfileTable:Copy(): name: expected string, got " .. type(name), 2)
	elseif FORBIDDEN_NAMES[name] then
		error("AddOn_XRP.Profiles: ProfileTable:Copy(): name is forbidden: " .. name, 2)
	elseif xrpSaved.profiles[name] then
		error("AddOn_XRP.Profiles: ProfileTable:Copy(): profile already exists: " .. name, 2)
	end
	local oldName = ProfileNameMap[self]
	local profile = xrpSaved.profiles[oldName]
	xrpSaved.profiles[name] = {
		fields = {},
		inherits = {},
		parent = profile.parent,
	}
	for field, contents in pairs(profile.fields) do
		xrpSaved.profiles[name].fields[field] = contents
	end
	for field, setting in pairs(profile.inherits) do
		xrpSaved.profiles[name].inherits[field] = setting
	end
end

function ProfileMethods:IsParentValid(name)
	if name == nil then
		return true
	elseif type(name) ~= "string" then
		error("AddOn_XRP.Profiles: ProfileTable:IsParentValid(): name: expected string, got " .. type(name), 2)
	elseif FORBIDDEN_NAMES[name] then
		error("AddOn_XRP.Profiles: ProfileTable:IsParentValid(): name is forbidden: " .. name, 2)
	elseif not xrpSaved.profiles[name] then
		error("AddOn_XRP.Profiles: ProfileTable:IsParentValid(): profile doesn't exist: " .. name, 2)
	end
	local childName = ProfileNameMap[self]
	local testName = name
	for i = 1, MAX_DEPTH do
		local profile = xrpSaved.profiles[testName]
		if testName == childName then
			return false
		elseif xrpSaved.profiles[profile.parent] then
			testName = profile.parent
		else
			return true
		end
	end
	return true
end

function ProfileMethods:IsInUse()
	local name = ProfileNameMap[self]
	return IsInUse(name)
end

local CharacterFieldMetatable = {}

function CharacterFieldMetatable:__index(field)
	if type(field) ~= "string" then
		error("AddOn_XRP.Characters: ProfileFieldTable: field: expected string or nil, got " .. type(field), 2)
	elseif NO_PROFILE[field] or not field:find("^%u%u$") then
		error("AddOn_XRP.Characters: ProfileFieldTable: field: invalid field:" .. field, 2)
	end
	local contents = xrpSaved.profiles[ProfileNameMap[self]].fields[field]
	if field == "PE" then
		contents = AddOn.StringToPE(contents) or AddOn.GetEmptyPE()
	end
	return contents
end

function CharacterFieldMetatable:__newindex(field, contents)
	if type(field) ~= "string" then
		error("AddOn_XRP.Characters: ProfileFieldTable: field: expected string or nil, got " .. type(field), 2)
	elseif field == "PE" then
		if contents and type(contents) ~= "table" then
			error("AddOn_XRP.SetField(): contents (PE): expected table or nil, got " .. type(contents), 2)
		end
		contents = AddOn.PEToString(contents)
	elseif NO_PROFILE[field] or not field:find("^%u%u$") then
		error("AddOn_XRP.Characters: ProfileFieldTable: field: invalid field:" .. field, 2)
	elseif contents and type(contents) ~= "string" then
		error("AddOn_XRP.Characters: ProfileFieldTable: contents: expected string or nil, got " .. type(contents), 2)
	end
	local name = ProfileNameMap[self]
	contents = contents ~= "" and contents or nil
	local profile = xrpSaved.profiles[name]
	if profile and profile.fields[field] ~= contents then
		profile.fields[field] = contents
		if IsInUse(name, field) then
			AddOn.ProfileUpdate(field)
		end
	end
end

CharacterFieldMetatable.__metatable = false

local CharacterFullMetatable = {}

function CharacterFullMetatable:__index(field)
	if type(field) ~= "string" then
		error("AddOn_XRP.Characters: ProfileFullTable: field: expected string or nil, got " .. type(field), 2)
	elseif NO_PROFILE[field] or not field:find("^%u%u$") then
		error("AddOn_XRP.Characters: ProfileFullTable: field: invalid field:" .. field, 2)
	end
	local contents = AddOn.GetProfileField(field, ProfileNameMap[self])
	if field == "PE" then
		contents = AddOn.StringToPE(contents)
	end
	return contents
end

CharacterFullMetatable.__newindex = AddOn.DoNothing

CharacterFullMetatable.__metatable = false

local CharacterInheritMetatable = {}

function CharacterInheritMetatable:__index(field)
	if type(field) ~= "string" then
		error("AddOn_XRP.Characters: ProfileInheritTable: field: expected string or nil, got " .. type(field), 2)
	elseif NO_PROFILE[field] or not field:find("^%u%u$") then
		error("AddOn_XRP.Characters: ProfileInheritTable: field: invalid field:" .. field, 2)
	end
	if xrpSaved.profiles[ProfileNameMap[self]].inherits[field] == false then
		return false
	end
	return true
end

function CharacterInheritMetatable:__newindex(field, state)
	if type(field) ~= "string" then
		error("AddOn_XRP.Characters: ProfileInheritTable: field: expected string or nil, got " .. type(field), 2)
	elseif NO_PROFILE[field] or not field:find("^%u%u$") then
		error("AddOn_XRP.Characters: ProfileInheritTable: field: invalid field:" .. field, 2)
	elseif type(state) ~= "boolean" then
		error("AddOn_XRP.Characters: ProfileInheritTable: state: expected boolean, got " .. type(state), 2)
	end
	if state == true then
		-- True is stored as nil to keep saved variables a bit cleaner.
		state = nil
	end
	local name = ProfileNameMap[self]
	local profile = xrpSaved.profiles[name]
	if state ~= profile.inherits[field] then
		profile.inherits[field] = state
		if not profile.fields[field] and IsInUse(name, field) then
			AddOn.ProfileUpdate(field)
		end
	end
end

CharacterInheritMetatable.__metatable = false

local ProfileMetatable = {}

function ProfileMetatable:__index(index)
	local name = ProfileNameMap[self]
	if index == "name" then
		return name
	elseif ProfileMethods[index] then
		return ProfileMethods[index]
	elseif index == "Field" then
		local Field = setmetatable({}, CharacterFieldMetatable)
		ProfileNameMap[Field] = name
		rawset(self, index, Field)
		return Field
	elseif index == "Full" then
		local Full = setmetatable({}, CharacterFullMetatable)
		ProfileNameMap[Full] = name
		rawset(self, index, Full)
		return Full
	elseif index == "Inherit" then
		local Inherit = setmetatable({}, CharacterInheritMetatable)
		ProfileNameMap[Inherit] = name
		rawset(self, index, Inherit)
		return Inherit
	elseif index == "parent" then
		return xrpSaved.profiles[name].parent
	elseif index == "exportPlainText" then
		return AddOn.ExportText(("%s - %s"):format(AddOn_XRP.Characters.byUnit.player.fullDisplayName, name), self.Full)
	end
	error("AddOn_XRP.Profiles: ProfileTable: invalid index " .. index, 2)
end

function ProfileMetatable:__newindex(index, value)
	if type(index) ~= "string" then
		error("AddOn_XRP.Profiles: ProfileTable: expected to set string index, got " .. type(index), 2)
	end
	local name = ProfileNameMap[self]
	local profiles = xrpSaved.profiles
	if index == "parent" then
		if value ~= nil and type(value) ~= "string" then
			error("AddOn_XRP.Profiles: ProfileTable.parent: expected string or nil value, got " .. type(value), 2)
		elseif not self:IsParentValid(value) then
			error("AddOn_XRP.Profiles: ProfileTable.parent: unable to set parent due to loop: " .. value, 2)
		elseif value ~= profiles[name].parent then
			profiles[name].parent = value
			if IsInUse(name) then
				AddOn.ProfileUpdate()
			end
		end
	else
		error("AddOn_XRP.Profiles: ProfileTable: could not set invalid or read-only index: " .. index, 2)
	end
end

ProfileMetatable.__metatable = false

local Profiles = setmetatable({}, AddOn.WeakValueMetatable)

local ProfileAPIMetatable = {}

function ProfileAPIMetatable:__index(name)
	if name == "SELECTED" then
		name = xrpSaved.selected
	end
	if not xrpSaved.profiles[name] then
		return nil
	elseif not Profiles[name] then
		local profile = setmetatable({}, ProfileMetatable)
		ProfileNameMap[profile] = name
		Profiles[name] = profile
	end
	return Profiles[name]
end

ProfileAPIMetatable.__newindex = AddOn.DoNothing

ProfileAPIMetatable.__metatable = false

setmetatable(AddOn_XRP.Profiles, ProfileAPIMetatable)
