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

local MAX_DEPTH = 50

local NO_PROFILE = { TT = true, VP = true, VA = true, GC = true, GF = true, GR = true, GS = true, GU = true }

AddOn.PROFILE_MAX_DEPTH = MAX_DEPTH

xrp.current = setmetatable({}, {
	__index = function(self, field)
		local contents = xrpSaved.overrides.fields[field] or xrp.profiles.SELECTED.fullFields[field] or xrpSaved.meta.fields[field]
		if not contents or contents == "" then
			return nil
		elseif field == "AH" then
			contents = AddOn.ConvertHeight(contents, "msp")
		elseif field == "AW" then
			contents = AddOn.ConvertWeight(contents, "msp")
		end
		return contents
	end,
	__newindex = function(self, field, contents)
		if xrpSaved.overrides.fields[field] == contents or NO_PROFILE[field] or not field:find("^%u%u$") then return end
		contents = type(contents) == "string" and contents or nil
		xrpSaved.overrides.fields[field] = contents
		AddOn.FireEvent("UPDATE", field)
	end,
	__metatable = false,
})

local function IsUsed(name, field)
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

local nameMap = setmetatable({}, AddOn.weakKeyMeta)

local FORBIDDEN_NAMES = {
	Add = true,
	List = true,
	SELECTED = true,
}

local profileFunctions = {
	Delete = function(self)
		local name = nameMap[self]
		if IsUsed(name) then
			return false
		end
		local profiles = xrpSaved.profiles
		for profileName, profile in pairs(profiles) do
			if profile.parent == name then
				profile.parent = profiles[name].parent
			end
		end
		for form, profileName in pairs(xrpSaved.auto) do
			if profileName == name then
				AddOn.auto[form] = nil
			end
		end
		profiles[name] = nil
		return true
	end,
	Rename = function(self, newName)
		local name = nameMap[self]
		if type(newName) ~= "string" or FORBIDDEN_NAMES[newName] or xrpSaved.profiles[newName] ~= nil or type(xrpSaved.profiles[name]) ~= "table" then
			return false
		end
		xrpSaved.profiles[newName] = xrpSaved.profiles[name]
		for profileName, profile in pairs(xrpSaved.profiles) do
			if profile.parent == name then
				profile.parent = newName
			end
		end
		if xrpSaved.selected == name then
			xrpSaved.selected = newName
		end
		nameMap[self] = newName
		for key, value in pairs(self) do
			if nameMap[value] then
				nameMap[value] = newName
			end
		end
		for form, profileName in pairs(xrpSaved.auto) do
			if profileName == name then
				xrpSaved.auto[form] = newName
			end
		end
		xrpSaved.profiles[name] = nil
		return true
	end,
	Copy = function(self, newName)
		local name = nameMap[self]
		if type(newName) ~= "string" or FORBIDDEN_NAMES[newName] or xrpSaved.profiles[newName] ~= nil or type(xrpSaved.profiles[name]) ~= "table" then
			return false
		end
		local profile = xrpSaved.profiles[name]
		xrpSaved.profiles[newName] = {
			fields = {},
			inherits = {},
			parent = profile.parent,
		}
		for field, contents in pairs(profile.fields) do
			xrpSaved.profiles[newName].fields[field] = contents
		end
		for field, setting in pairs(profile.inherits) do
			xrpSaved.profiles[newName].inherits[field] = setting
		end
		return true
	end,
	Activate = function(self, keepOverrides)
		local name = nameMap[self]
		if xrpSaved.selected == name or not xrpSaved.profiles[name] then
			return false
		end
		xrpSaved.selected = name
		if not keepOverrides then
			xrpSaved.overrides.fields = {}
		end
		AddOn.FireEvent("UPDATE")
		return true
	end,
	IsParentValid = function(self, testName)
		if not testName then
			return true
		end
		local name = nameMap[self]
		for i = 1, MAX_DEPTH do
			local profile = xrpSaved.profiles[testName]
			if testName == name then
				return false
			elseif xrpSaved.profiles[profile.parent] then
				testName = profile.parent
			else
				return true
			end
		end
		return true
	end,
}

local fieldsMeta = {
	__index = function(self, field)
		if NO_PROFILE[field] or not field:find("^%u%u$") then
			return nil
		end
		return xrpSaved.profiles[nameMap[self]].fields[field]
	end,
	__newindex = function(self, field, contents)
		if NO_PROFILE[field] or not field:find("^%u%u$") then return end
		local name = nameMap[self]
		contents = type(contents) == "string" and contents ~= "" and contents or nil
		local profile = xrpSaved.profiles[name]
		if profile and profile.fields[field] ~= contents then
			profile.fields[field] = contents
			if IsUsed(name, field) then
				AddOn.FireEvent("UPDATE", field)
			end
		end
	end,
	__tostring = function(self)
		local name = nameMap[self]
		local fields = {}
		local profiles, inherit = { xrpSaved.profiles[name] }, xrpSaved.profiles[name].parent
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
				if not fields[field] then
					fields[field] = contents
				end
			end
		end
		for field, contents in pairs(xrpSaved.meta.fields) do
			if not fields[field] then
				fields[field] = contents
			end
		end
		return AddOn.ExportText(("%s - %s"):format(L.NAME_REALM:format(AddOn.player, xrp.RealmDisplayName(AddOn.realm)), name), fields)
	end,
	__metatable = false,
}

local fullFieldsMeta = {
	__index = function(self, field)
		local profile = xrpSaved.profiles[nameMap[self]]
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
	end,
	__newindex = AddOn.DoNothing,
	__metatable = false,
}

local inheritMeta = {
	__index = function(self, field)
		if NO_PROFILE[field] or not field:find("^%u%u$") or xrpSaved.profiles[nameMap[self]].inherits[field] == false then
			return false
		end
		return true
	end,
	__newindex = function(self, field, state)
		if NO_PROFILE[field] or not field:find("^%u%u$") then return end
		local name = nameMap[self]
		local profile = xrpSaved.profiles[name]
		if state == true then
			state = nil
		end
		if state ~= profile.inherits[field] then
			profile.inherits[field] = state
			if not profile.fields[field] and IsUsed(name, field) then
				AddOn.FireEvent("UPDATE", field)
			end
		end
	end,
	__metatable = false,
}

local profileMeta = {
	__index = function(self, component)
		local name = nameMap[self]
		if not xrpSaved.profiles[name] then
			return nil
		elseif profileFunctions[component] then
			return profileFunctions[component]
		elseif component == "fields" then
			local fields = setmetatable({}, fieldsMeta)
			nameMap[fields] = name
			rawset(self, component, fields)
			return fields
		elseif component == "fullFields" then
			local fullFields = setmetatable({}, fullFieldsMeta)
			nameMap[fullFields] = name
			rawset(self, component, fullFields)
			return fullFields
		elseif component == "inherit" then
			local inherit = setmetatable({}, inheritMeta)
			nameMap[inherit] = name
			rawset(self, component, inherit)
			return inherit
		elseif component == "parent" then
			return xrpSaved.profiles[name].parent
		end
		return nil
	end,
	__newindex = function(self, component, value)
		local name, profiles = nameMap[self], xrpSaved.profiles
		if component ~= "parent" or value == profiles[name].parent or not self:IsParentValid(value) then return end
		profiles[name].parent = value
		if IsUsed(name) then
			AddOn.FireEvent("UPDATE")
		end
	end,
	__tostring = function(self)
		return nameMap[self]
	end,
	__metatable = false,
}

local profileTables = setmetatable({}, AddOn.weakMeta)

xrp.profiles = setmetatable({
	Add = function(self, name)
		if type(name) ~= "string" or xrpSaved.profiles[name] or FORBIDDEN_NAMES[name] then
			return false
		end
		xrpSaved.profiles[name] = {
			fields = {},
			inherits = {},
		}
		return self[name]
	end,
	List = function(self)
		local list = {}
		for profileName, profile in pairs(xrpSaved.profiles) do
			list[#list + 1] = profileName
		end
		table.sort(list)
		return list
	end,
}, {
	__index = function(self, name)
		if name == "SELECTED" then
			name = xrpSaved.selected
		end
		if not xrpSaved.profiles[name] then
			return nil
		elseif not profileTables[name] then
			local profile = setmetatable({}, profileMeta)
			nameMap[profile] = name
			profileTables[name] = profile
		end
		return profileTables[name]
	end,
	__newindex = AddOn.DoNothing,
	__metatable = false,
})
