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

	AddOn.RunEvent("UPDATE")
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
		error("AddOn_XRP.SetField(): field: expected string or nil, got " .. type(field), 2)
	elseif contents and type(contents) ~= "string" then
		error("AddOn_XRP.SetField(): contents: expected string or nil, got " .. type(contents), 2)
	elseif NO_PROFILE[field] or not field:find("^%u%u$") then
		error("AddOn_XRP.SetField(): field: invalid field:" .. field, 2)
	elseif xrpSaved.overrides[field] == contents then
		return
	end
	xrpSaved.overrides[field] = contents
	AddOn.RunEvent("UPDATE", field)
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
			if not fields[field] then
				fields[field] = contents
			end
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

local nameMap = setmetatable({}, AddOn.WeakKeyMetatable)

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
			xrpSaved.overrides = {}
		end
		AddOn.RunEvent("UPDATE")
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
				AddOn.RunEvent("UPDATE", field)
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
		for field, contents in pairs(AddOn.FallbackFields) do
			if not fields[field] then
				fields[field] = contents
			end
		end
		return AddOn.ExportText(("%s - %s"):format(L.NAME_REALM:format(AddOn.SplitCharacterID(AddOn.characterID)), name), fields)
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
				AddOn.RunEvent("UPDATE", field)
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
			AddOn.RunEvent("UPDATE")
		end
	end,
	__tostring = function(self)
		return nameMap[self]
	end,
	__metatable = false,
}

local profileTables = setmetatable({}, AddOn.WeakValueMetatable)

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
