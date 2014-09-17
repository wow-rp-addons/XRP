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

local overrides, profiles, versions

xrp:HookLoad(function()
	overrides = xrpSaved.overrides
	profiles = xrpSaved.profiles
	versions = xrpSaved.versions
	if not overrides.logout or overrides.logout + 600 < time() then
		wipe(overrides.fields)
		wipe(overrides.versions)
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

-- Current public profile (includes overrides).
xrp.current = setmetatable({}, {
	__index = function(self, field)
		local selected = xrpSaved.selected
		local contents
		if overrides.fields[field] then
			contents = overrides.fields[field] ~= "" and overrides.fields[field] or nil
		elseif profiles[selected].fields[field] then
			contents = profiles[selected].fields[field]
		elseif profiles[xrp.inherits[selected][field]] then
			contents = profiles[xrp.inherits[selected][field]].fields[field]
		elseif xrp.toon.fields[field] then
			contents = xrp.toon.fields[field]
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
	__call = function(self)
		local out, selected = {}, xrpSaved.selected
		for field, contents in pairs(xrp.toon.fields) do
			out[field] = contents
		end
		do
			local parents, count, inherit = {}, 0, profiles[selected].parent
			while inherit and count < 5 do
				count = count + 1
				parents[#parents + 1] = inherit
				inherit = profiles[inherit].parent
			end
			for _, profile in pairs(parents) do
				for field, contents in pairs(profiles[profile]) do
					if xrp.inherits[selected][field] == profile then
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
	__metatable = false,
})

local nonewindex = function() end

-- Current selected profile (no overrides).
xrp.selected = setmetatable({}, {
	__index = function(self, field)
		local selected = xrpSaved.selected
		local contents
		if profiles[selected].fields[field] then
			contents = profiles[selected].fields[field]
		elseif profiles[xrp.inherits[selected][field]] then
			contents = profiles[xrp.inherits[selected][field]].fields[field]
		elseif xrp.toon.fields[field] then
			contents = xrp.toon.fields[field]
		else
			return nil
		end
		return field == "AH" and xrp:ConvertHeight(contents, "msp") or field == "AW" and xrp:ConvertWeight(contents, "msp") or contents
	end,
	__newindex = nonewindex,
	__metatable = false,
})

xrp.versions = setmetatable({}, {
	__index = function (self, field)
		local selected = xrpSaved.selected
		return xrp.toon.versions[field] or overrides.versions[field] or profiles[selected].versions[field] or (profiles[xrp.inherits[selected][field]] and profiles[xrp.inherits[selected][field]].versions[field]) or nil
	end,
	__newindex = nonewindex,
	__metatable = false,
})

local pk = {}

local profs = setmetatable({}, { __mode = "v" })
local inhs = setmetatable({}, { __mode = "v" })

do
	local profmt = {
		__index = function(self, field)
			local profile = self[pk]
			return profiles[profile].fields[field] or nil
		end,
		__newindex = function(self, field, contents)
			if xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then
				return
			end
			local profile = self[pk]
			contents = type(contents) == "string" and contents ~= "" and contents or nil
			if profiles[profile] and profiles[profile].fields[field] ~= contents then
				profiles[profile].fields[field] = contents
				profiles[profile].versions[field] = contents ~= nil and xrp:NewVersion(field) or nil
				if profile == xrpSaved.selected or profile == xrp.inherits[xrpSaved.selected][field] then
					xrp:FireEvent("FIELD_UPDATE", field)
				end
			end
		end,
		__call = function(self, action, argument)
			if not profiles[self[pk]] then
				return false
			elseif action == "length" then
				local length = 0
				for field, contents in pairs(profiles[self[pk]].fields) do
					length = length + #contents
				end
				return length
			elseif action == "rename" and type(argument) == "string" then
				local profile = self[pk]
				if type(profiles[profile]) == "table" and type(profiles[argument]) ~= "table" then
					-- Rename profile to the nonexistant table provided.
					profiles[argument] = profiles[profile]
					for name, contents in pairs(profiles) do
						if contents.parent == profile then
							contents.parent = argument
						end
					end
					-- Select the new name if this is our active profile.
					if xrpSaved.selected == profile then
						xrpSaved.selected = argument
					end
					xrp.profiles[profile] = nil
					return true
				end
			elseif action == "copy" and type(argument) == "string" then
				local profile = self[pk]
				if type(profiles[profile]) == "table" and type(profiles[argument]) ~= "table" then
					-- Copy profile into the empty table called.
					profiles[argument] = {
						fields = {},
						inherits = {},
						versions = {},
						parent = profiles[profile].parent,
					}
					for field, contents in pairs(profiles[profile].fields) do
						profiles[argument].fields[field] = contents
					end
					for field, setting in pairs(profiles[profile].inherits) do
						profiles[argument].inherits[field] = setting
					end
					for field, version in pairs(profiles[profile].versions) do
						profiles[argument].versions[field] = version
					end
					return true
				end
			elseif not action then
				local profile = self[pk]
				local ret = {}
				for field, contents in pairs(profiles[profile].fields) do
					ret[field] = contents
				end
				return ret
			end
			return false
		end,
		__metatable = false,
	}

	xrp.profiles = setmetatable({}, {
		__index = function(self, profile)
			if not profiles[profile] then
				profiles[profile] = {
					fields = {},
					inherits = {},
					versions = {},
				}
			end
			if not profs[profile] then
				profs[profile] = setmetatable({ [pk] = profile }, profmt)
			end
			return profs[profile]
		end,
		__newindex = function(self, profile, data)
			if type(data) == "table" then
				if not profs[profile] then
					profs[profile] = setmetatable({ [pk] = profile }, profmt)
				end
				for field, contents in pairs(data) do
					profs[profile][field] = contents
				end
			elseif data == nil then
				profiles[profile] = nil
				profs[profile] = nil
				inhs[profile] = nil
				if profile == xrpSaved.selected then
					-- TODO: HANDLE SOMEHOW.
					xrp.profiles("Default")
				end
			end
		end,
		__call = function(self, profile, keepoverrides)
			if not profile then
				local list = {}
				for profile, _ in pairs(profiles) do
					list[#list + 1] = profile
				end
				table.sort(list)
				return list
			elseif type(profile) == "string" and profiles[profile] then
				xrpSaved.selected = profile
				if not keepoverrides then
					wipe(overrides.fields)
					wipe(overrides.versions)
				end
				xrp:FireEvent("FIELD_UPDATE")
				return true
			end
			return false
		end,
		__metatable = false,
	})
end

do
	local inhmt = {
		__index = function(self, field)
			local profile = self[pk]
			if profiles[profile].inherits[field] == false then
				return false
			end
			local inherit = profiles[profile].parent
			if profiles[profile].fields[field] ~= nil or not profiles[inherit] then
				return true
			end
			local count = 0
			while count < 5 do
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
			local profile = self[pk]
			if not profiles[profile] or xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then return end
			if state ~= profiles[profile].inherits[field] then
				local current = xrp.inherits[xrpSaved.selected][field]
				profiles[profile].inherits[field] = state
				if current ~= xrp.inherits[xrpSaved.selected][field] then
					xrp:FireEvent("FIELD_UPDATE", field)
				end
			end
		end,
		__metatable = false,
	}

	xrp.inherits = setmetatable({}, {
		__index = function(self, profile)
			if not profiles[profile] then
				return nil
			end
			if not inhs[profile] then
				inhs[profile] = setmetatable({ [pk] = profile }, inhmt)
			end
			return inhs[profile]
		end,
		__newindex = function(self, profile, parent)
			if not profiles[profile] then return end
			if parent ~= profiles[profile].parent then
				local count, isused, inherit = 0, profile == xrpSaved.selected, profiles[xrpSaved.selected].parent
				while inherit and not isused and count < 5 do
					count = count + 1
					if inherit == profile then
						isused = true
					elseif profiles[inherit] and profiles[inherit].parent then
						inherit = profiles[inherit].parent
					else
						inherit = nil
					end
				end
				profiles[profile].parent = parent
				if isused then
					xrp:FireEvent("FIELD_UPDATE")
				end
			end
		end,
		__metatable = false,
	})
end
