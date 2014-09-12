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

xrp:HookLoad(function()
	if not xrp_overrides.logout or xrp_overrides.logout + 600 < time() then
		wipe(xrp_overrides.fields)
		wipe(xrp_overrides.versions)
	end
	xrp_overrides.logout = nil
end)

xrp:HookLogout(function()
	if next(xrp_overrides.fields) then
		xrp_overrides.logout = time()
	end
end)

function xrp:NewVersion(field)
	xrp_versions[field] = (xrp_versions[field] or 0) + 1
	return xrp_versions[field]
end

-- Current public profile (includes overrides).
xrp.current = setmetatable({}, {
	__index = function(self, field)
		local contents
		if xrp_overrides.fields[field] then
			contents = xrp_overrides.fields[field] ~= "" and xrp_overrides.fields[field] or nil
		elseif xrp_profiles[xrp_selectedprofile].fields[field] then
			contents = xrp_profiles[xrp_selectedprofile].fields[field]
		elseif xrp_profiles[xrp.inherits[xrp_selectedprofile][field]] then
			contents = xrp_profiles[xrp.inherits[xrp_selectedprofile][field]].fields[field]
		elseif xrp.toon.fields[field] then
			contents = xrp.toon.fields[field]
		else
			return nil
		end
		return field == "AH" and xrp:ConvertHeight(contents, "msp") or field == "AW" and xrp:ConvertWeight(contents, "msp") or contents
	end,
	__newindex = function(self, field, contents)
		if xrp_overrides.fields[field] == contents or xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then return end
		xrp_overrides.fields[field] = contents
		xrp_overrides.versions[field] = contents ~= nil and xrp:NewVersion(field) or nil
		xrp:FireEvent("FIELD_UPDATE", field)
	end,
	__call = function(self)
		local out = {}
		for field, contents in pairs(xrp.toon.fields) do
			out[field] = contents
		end
		do
			local parents, count = {}, 0, inherit = xrp_profiles[xrp_selectedprofile].parent
			while inherit and count < 5 do
				count = count + 1
				parents[#parents + 1] = inherit
				inherit = xrp_profiles[inherit].parent
			end
			for _, profile in pairs(parents) do
				for field, contents in pairs(xrp_profiles[profile]) do
					if xrp.inherits[xrp_selectedprofile][field] == profile then
						out[field] = contents
					end
				end
			end
		end
		for field, contents in pairs(xrp_profiles[xrp_selectedprofile].fields) do
			out[field] = contents
		end
		for field, contents in pairs(xrp_overrides.fields) do
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
		local contents
		if xrp_profiles[xrp_selectedprofile].fields[field] then
			contents = xrp_profiles[xrp_selectedprofile].fields[field]
		elseif xrp_profiles[xrp.inherits[xrp_selectedprofile][field]] then
			contents = xrp_profiles[xrp.inherits[xrp_selectedprofile][field]].fields[field]
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
		return xrp.toon.versions[field] or xrp_overrides.versions[field] or xrp_profiles[xrp_selectedprofile].versions[field] or (xrp_profiles[xrp.inherits[xrp_selectedprofile][field]] and xrp_profiles[xrp.inherits[xrp_selectedprofile][field]].versions[field]) or nil
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
			return xrp_profiles[profile].fields[field] or nil
		end,
		__newindex = function(self, field, contents)
			if xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then
				return
			end
			local profile = self[pk]
			contents = type(contents) == "string" and contents ~= "" and contents or nil
			if xrp_profiles[profile] and xrp_profiles[profile].fields[field] ~= contents then
				xrp_profiles[profile].fields[field] = contents
				xrp_profiles[profile].versions[field] = contents ~= nil and xrp:NewVersion(field) or nil
				if profile == xrp_selectedprofile or profile == xrp.inherits[xrp_selectedprofile][field] then
					xrp:FireEvent("FIELD_UPDATE", field)
				end
			end
		end,
		__call = function(self, action, argument)
			if not xrp_profiles[self[pk]] then
				return false
			elseif action == "length" then
				local length = 0
				for field, contents in pairs(xrp_profiles[self[pk]].fields) do
					length = length + #contents
				end
				return length
			elseif action == "rename" and type(argument) == "string" then
				local profile = self[pk]
				if type(xrp_profiles[profile]) == "table" and type(xrp_profiles[argument]) ~= "table" then
					-- Rename profile to the nonexistant table provided.
					xrp_profiles[argument] = xrp_profiles[profile]
					for name, contents in pairs(xrp_profiles) do
						if contents.parent == profile then
							contents.parent = argument
						end
					end
					-- Select the new name if this is our active profile.
					if xrp_selectedprofile == profile then
						xrp_selectedprofile = argument
					end
					xrp.profiles[profile] = nil
					return true
				end
			elseif action == "copy" and type(argument) == "string" then
				local profile = self[pk]
				if type(xrp_profiles[profile]) == "table" and type(xrp_profiles[argument]) ~= "table" then
					-- Copy profile into the empty table called.
					xrp_profiles[argument] = {
						fields = {},
						inherits = {},
						versions = {},
						parent = xrp_profiles[profile].parent,
					}
					for field, contents in pairs(xrp_profiles[profile].fields) do
						xrp_profiles[argument].fields[field] = contents
					end
					for field, setting in pairs(xrp_profiles[profile].inherits) do
						xrp_profiles[argument].inherits[field] = setting
					end
					for field, version in pairs(xrp_profiles[profile].versions) do
						xrp_profiles[argument].versions[field] = version
					end
					return true
				end
			elseif not action then
				local profile = self[pk]
				local ret = {}
				for field, contents in pairs(xrp_profiles[profile].fields) do
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
			if not xrp_profiles[profile] then
				xrp_profiles[profile] = {
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
				xrp_profiles[profile] = nil
				profs[profile] = nil
				inhs[profile] = nil
				if profile == xrp_selectedprofile then
					-- TODO: HANDLE SOMEHOW.
					xrp.profiles("Default")
				end
			end
		end,
		__call = function(self, profile, keepoverrides)
			if not profile then
				local list = {}
				for profile, _ in pairs(xrp_profiles) do
					list[#list + 1] = profile
				end
				table.sort(list)
				return list
			elseif type(profile) == "string" and xrp_profiles[profile] then
				xrp_selectedprofile = profile
				if not keepoverrides then
					wipe(xrp_overrides.fields)
					wipe(xrp_overrides.versions)
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
			if not xrp_profiles[profile].inherits[field] then
				return false
			end
			local inherit = xrp_profiles[profile].parent
			if xrp_profiles[profile].fields[field] ~= nil or not xrp_profiles[inherit] then
				return true
			end
			local count = 0
			while count < 5 do
				count = count + 1
				if xrp_profiles[inherit] and xrp_profiles[inherit].fields[field] then
					return inherit
				elseif xrp_profiles[inherit] and xrp_profiles[inherit].inherits[field] and xrp_profiles[xrp_profiles[inherit].parent] then
					inherit = xrp_profiles[inherit].parent
				else
					return true
				end
			end
			return true
		end,
		__newindex = function(self, field, state)
			local profile = self[pk]
			if not xrp_profiles[profile] or xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then return end
			if state ~= xrp_profiles[profile].inherits[field] then
				local current = xrp.inherits[xrp_selectedprofile][field]
				xrp_profiles[profile].inherits[field] = state
				if current ~= xrp.inherits[xrp_selectedprofile][field] then
					xrp:FireEvent("FIELD_UPDATE", field)
				end
			end
		end,
		__metatable = false,
	}

	xrp.inherits = setmetatable({}, {
		__index = function(self, profile)
			if not xrp_profiles[profile] then
				return nil
			end
			if not inhs[profile] then
				inhs[profile] = setmetatable({ [pk] = profile }, inhmt)
			end
			return inhs[profile]
		end,
		__newindex = function(self, profile, parent)
			if not xrp_profiles[profile] then return end
			if parent ~= xrp_profiles[profile].parent then
				local count, isused, inherit = 0, profile == xrp_selectedprofile, xrp_profiles[xrp_selectedprofile].parent
				while inherit and not isused and count < 5 do
					count = count + 1
					if inherit == profile then
						isused = true
					elseif xrp_profiles[inherit] and xrp_profiles[inherit].parent then
						inherit = xrp_profiles[inherit].parent
					else
						inherit = nil
					end
				end
				xrp_profiles[profile].parent = parent
				if isused then
					xrp:FireEvent("FIELD_UPDATE")
				end
			end
		end,
		__metatable = false,
	})
end
