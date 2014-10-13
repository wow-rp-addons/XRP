--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

local overrides, profiles

xrp:HookLoad(function()
	overrides = xrpSaved.overrides
	profiles = xrpSaved.profiles
	if not overrides.logout or overrides.logout + 600 < time() then
		overrides.fields = {}
		overrides.versions = {}
	end
	overrides.logout = nil
end)

xrp:HookLogout(function()
	if next(overrides.fields) then
		overrides.logout = time()
	end
end)

function xrp:NewVersion(field)
	xrpSaved.versions[field] = (xrpSaved.versions[field] or 0) + 1
	return xrpSaved.versions[field]
end

local nonewindex = function() end

xrp.current = setmetatable({
	fields = setmetatable({}, {
		__index = function(self, field)
			local selected = xrpSaved.selected
			local contents
			if overrides.fields[field] then
				contents = overrides.fields[field] ~= "" and overrides.fields[field] or nil
			elseif profiles[selected].fields[field] then
				contents = profiles[selected].fields[field]
			elseif profiles[xrp.profiles[selected].inherits[field]] then
				contents = profiles[xrp.profiles[selected].inherits[field]].fields[field]
			elseif xrpSaved.meta.fields[field] then
				contents = xrpSaved.meta.fields[field]
			else
				return nil
			end
			return field == "AH" and xrp:ConvertHeight(contents, "msp") or field == "AW" and xrp:ConvertWeight(contents, "msp") or contents
		end,
		__newindex = function(self, field, contents)
			if overrides.fields[field] == contents or xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then return end
			overrides.fields[field] = contents
			overrides.versions[field] = contents ~= nil and xrp:NewVersion(field) or nil
			xrp:FireEvent("FIELD_UPDATE", field)
		end,
		__metatable = false,
	}),
	versions = setmetatable({}, {
		__index = function (self, field)
			local selected = xrpSaved.selected
			return overrides.versions[field] or profiles[selected].versions[field] or (profiles[xrp.profiles[selected].inherits[field]] and profiles[xrp.profiles[selected].inherits[field]].versions[field]) or xrpSaved.meta.versions[field] or nil
		end,
		__newindex = nonewindex,
		__metatable = false,
	}),
	overrides = setmetatable({}, {
		__index = function(self, field)
			return overrides.fields[field] ~= nil
		end,
		__newindex = nonewindex,
		__metatable = false,
	}),
	List = function(self)
		local out, selected = {}, xrpSaved.selected
		for field, contents in pairs(xrpSaved.meta.fields) do
			out[field] = contents
		end
		do
			local parents, count, inherit = {}, 0, profiles[selected].parent
			while inherit and count < 16 do
				count = count + 1
				parents[#parents + 1] = inherit
				inherit = profiles[inherit].parent
			end
			for _, profile in ipairs(parents) do
				for field, contents in pairs(profiles[profile].fields) do
					if xrp.profiles[selected].inherits[field] == profile then
						out[field] = contents
					end
				end
			end
		end
		for field, contents in pairs(profiles[selected].fields) do
			out[field] = contents
		end
		for field, contents in pairs(overrides.fields) do
			out[field] = contents ~= "" and contents or nil
		end
		out.AW = out.AW and xrp:ConvertWeight(out.AW, "msp") or nil
		out.AH = out.AH and xrp:ConvertHeight(out.AH, "msp") or nil
		return out
	end,
}, { __newindex = nonewindex, })

local nk = {}
local FORBIDDEN_NAMES = {
	Add = true,
	List = true,
	SELECTED = true,
}

local profile_mt
do
	local profile_Functions = {
		Delete = function(self)
			local name = self[nk]
			local selected = xrpSaved.selected
			if name == selected then
				return false
			end
			-- Walk through the selected profile's parentage to see if we're in
			-- the chain anywhere.
			local isused, count, inherit = name == selected, 0, profiles[selected].parent
			while inherit and not isused and count < 16 do
				count = count + 1
				if inherit == name then
					isused = true
				elseif profiles[inherit] and profiles[inherit].parent then
					inherit = profiles[inherit].parent
				else
					inherit = nil
				end
			end
			for _, profile in pairs(profiles) do
				if profile.parent == name then
					profile.parent = profiles[name].parent or nil
				end
			end
			profiles[name] = nil
			if isused then
				xrp:FireEvent("FIELD_UPDATE")
			end
			return true
		end,
		Rename = function(self, newname)
			local name = self[nk]
			if type(newname) ~= "string" or FORBIDDEN_NAMES[newname] or type(profiles[newname]) == "table" or type(profiles[name]) ~= "table" then
				return false
			end
			-- Rename profile to the nonexistant table provided.
			profiles[newname] = profiles[name]
			-- Update parentage of other profiles
			for _, profile in pairs(profiles) do
				if profile.parent == name then
					profile.parent = newname
				end
			end
			-- Select the new name if this is our active profile.
			if xrpSaved.selected == name then
				xrpSaved.selected = newname
			end
			profiles[name] = nil
			return true
		end,
		Copy = function(self, newname)
			local name = self[nk]
			if type(newname) ~= "string" or FORBIDDEN_NAMES[newname] or type(profiles[newname]) == "table" or type(profiles[name]) ~= "table" then
				return false
			end
			-- Copy profile into the empty table called.
			profiles[newname] = {
				fields = {},
				inherits = {},
				versions = {},
				parent = profiles[name].parent,
			}
			for field, contents in pairs(profiles[name].fields) do
				profiles[newname].fields[field] = contents
			end
			for field, setting in pairs(profiles[name].inherits) do
				profiles[newname].inherits[field] = setting
			end
			for field, version in pairs(profiles[name].versions) do
				profiles[newname].versions[field] = version
			end
			return true
		end,
		Activate = function(self, keepoverrides)
			local name = self[nk]
			if xrpSaved.selected == name or type(profiles[name]) ~= "table" then
				return false
			end
			xrpSaved.selected = name
			if not keepoverrides then
				overrides.fields = {}
				overrides.versions = {}
			end
			xrp:FireEvent("FIELD_UPDATE")
			return true
		end,
		List = function(self)
			local name, list = self[nk], {}
			for field, contents in pairs(profiles[name].fields) do
				list[field] = contents
			end
			return list
		end,
	}

	local fields_mt = {
		__index = function(self, field)
			if xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then
				return nil
			end
			return profiles[self[nk]].fields[field] or nil
		end,
		__newindex = function(self, field, contents)
			if xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then return end
			local name = self[nk]
			contents = type(contents) == "string" and contents ~= "" and contents or nil
			if profiles[name] and profiles[name].fields[field] ~= contents then
				local selected = xrpSaved.selected
				local isused = name == selected or name == xrp.profiles[selected].inherits[field]
				profiles[name].fields[field] = contents
				profiles[name].versions[field] = contents ~= nil and xrp:NewVersion(field) or nil
				if isused or name == xrp.profiles[xrpSaved.selected].inherits[field] then
					xrp:FireEvent("FIELD_UPDATE", field)
				end
			end
		end,
		__metatable = false,
	}

	local inherits_mt = {
		__index = function(self, field)
			local name = self[nk]
			if xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") or profiles[name].inherits[field] == false then
				return false
			end
			local inherit = profiles[name].parent
			if profiles[name].fields[field] ~= nil or not profiles[inherit] then
				return true
			end
			local count = 0
			while count < 16 do
				count = count + 1
				if profiles[inherit] and profiles[inherit].fields[field] then
					return inherit
				elseif profiles[inherit] and profiles[inherit].inherits[field] and profiles[profiles[inherit].parent] then
					inherit = profiles[inherit].parent
				else
					return true
				end
			end
			return true
		end,
		__newindex = function(self, field, state)
			if xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then return end
			local name, selected = self[nk], xrpSaved.selected
			if state ~= profiles[name].inherits[field] then
				local current = xrp.profiles[selected].inherits[field]
				profiles[name].inherits[field] = state
				if current ~= xrp.profiles[selected].inherits[field] then
					xrp:FireEvent("FIELD_UPDATE", field)
				end
			end
		end,
		__metatable = false,
	}

	profile_mt = {
		__index = function(self, component)
			local name = self[nk]
			if not profiles[name] then
				return nil
			end
			if profile_Functions[component] then
				return profile_Functions[component]
			elseif component == "fields" then
				rawset(self, "fields", setmetatable({ [nk] = name }, fields_mt))
				return self.fields
			elseif component == "inherits" then
				rawset(self, "inherits", setmetatable({ [nk] = name }, inherits_mt))
				return self.inherits
			elseif component == "parent" then
				return profiles[name].parent
			end
			return nil
		end,
		__newindex = function(self, component, value)
			local name = self[nk]
			if component ~= "parent" or value == profiles[name].parent then return end
			-- Walk through the new parentage to make sure there's no looping.
			local count, inherit = 0, value
			while inherit and count < 16 do
				if inherit == name then return end
				count = count + 1
				if profiles[inherit] and profiles[inherit].parent then
					inherit = profiles[inherit].parent
				else
					inherit = nil
				end
			end
			-- Walk through the selected profile's parentage to see if we're in
			-- the chain anywhere.
			local selected = xrpSaved.selected
			local isused = name == selected
			count, inherit = 0, profiles[selected].parent
			while inherit and not isused and count < 16 do
				count = count + 1
				if inherit == name then
					isused = true
				elseif profiles[inherit] and profiles[inherit].parent then
					inherit = profiles[inherit].parent
				else
					inherit = nil
				end
			end
			profiles[name].parent = value
			if isused then
				xrp:FireEvent("FIELD_UPDATE")
			end
		end,
		__metatable = false,
	}
end

local profiles_Functions
do
	profiles_Functions = {
		Add = function(self, name)
			if profiles[name] or FORBIDDEN_NAMES[name] then
				return false
			end
			profiles[name] = {
				fields = {},
				inherits = {},
				versions = {},
			}
			return true
		end,
		List = function(self)
			local list = {}
			for name, _ in pairs(profiles) do
				list[#list + 1] = name
			end
			table.sort(list)
			return list
		end,
	}
end

local profs = setmetatable({}, { __mode = "v" })

xrp.profiles = setmetatable({}, {
	__index = function(self, name)
		if profiles_Functions[name] then
			return profiles_Functions[name]
		elseif name == "SELECTED" then
			return xrp.profiles[xrpSaved.selected]
		elseif not profiles[name] then
			return nil
		end
		if not profs[name] then
			profs[name] = setmetatable({ [nk] = name }, profile_mt)
		end
		return profs[name]
	end,
	__newindex = nonewindex,
	__metatable = false,
})
