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
		wipe(xrp_overrides)
	else
		xrp_overrides.logout = nil
	end
end)

xrp:HookLogout(function()
	if next(xrp_overrides) then
		xrp_overrides.logout = time()
	end
end)

local L = xrp.L
-- Current public profile (includes overrides).
xrp.current = setmetatable({}, {
	__index = function(self, field)
		local contents
		if xrp.toon.fields[field] then
			contents = xrp.toon.fields[field]
		elseif xrp_overrides[field] then
			contents = xrp_overrides[field] ~= "" and xrp_overrides[field] or nil
		elseif xrp_profiles[xrp_selectedprofile].fields[field] then
			contents = xrp_profiles[xrp_selectedprofile].fields[field]
		elseif xrp.defaults[xrp_selectedprofile][field] == true and xrp_profiles[L["Default"]].fields[field] then
			contents = xrp_profiles[L["Default"]].fields[field]
		else
			return nil
		end
		if field == "AH" then
			return xrp:ConvertHeight(contents, "msp")
		elseif field == "AW" then
			return xrp:ConvertWeight(contents, "msp")
		else
			return contents
		end
	end,
	__newindex = function(self, field, contents)
		if xrp_overrides[field] == contents or xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then
			return
		end
		xrp_overrides[field] = contents
		xrp:UpdateField(field)
	end,
	__call = function(self)
		local out = {}
		for field, contents in pairs(xrp_profiles[L["Default"]].fields) do
			if xrp.defaults[xrp_selectedprofile][field] then
				out[field] = contents
			end
		end
		for field, contents in pairs(xrp_profiles[xrp_selectedprofile].fields) do
			out[field] = contents
		end
		for field, contents in pairs(xrp_overrides) do
			out[field] = contents ~= "" and contents or nil
		end
		for field, contents in pairs(xrp.toon.fields) do
			out[field] = contents
		end
		out.AW = out.AW and xrp:ConvertWeight(out.AW, "msp") or nil
		out.AH = out.AH and xrp:ConvertHeight(out.AH, "msp") or nil
		return out
	end,
	__metatable = false,
})

-- Current selected profile (no overrides).
xrp.selected = setmetatable({}, {
	__index = function(self, field)
		local contents
		if xrp.toon.fields[field] then
			contents = xrp.toon.fields[field]
		elseif xrp_profiles[xrp_selectedprofile].fields[field] then
			contents = xrp_profiles[xrp_selectedprofile].fields[field]
		elseif xrp.defaults[xrp_selectedprofile][field] == true and xrp_profiles[L["Default"]].fields[field] then
			contents = xrp_profiles[L["Default"]].fields[field]
		else
			return nil
		end
		if field == "AH" then
			return xrp:ConvertHeight(contents, "msp")
		elseif field == "AW" then
			return xrp:ConvertWeight(contents, "msp")
		else
			return contents
		end
	end,
	__newindex = nonewindex,
	__call = function(self)
		local out = {}
		for field, contents in pairs(xrp_profiles[L["Default"]].fields) do
			if xrp.defaults[xrp_selectedprofile][field] then
				out[field] = contents
			end
		end
		for field, contents in pairs(xrp_profiles[xrp_selectedprofile].fields) do
			out[field] = contents
		end
		for field, contents in pairs(xrp.toon.fields) do
			out[field] = contents
		end
		out.AW = out.AW and xrp:ConvertWeight(out.AW, "msp") or nil
		out.AH = out.AH and xrp:ConvertHeight(out.AH, "msp") or nil
		return out
	end,
	__metatable = false,
})

local nonewindex = function() end

local nk = {}

local profs = setmetatable({}, { __mode = "v" })
local defs = setmetatable({}, { __mode = "v" })

do
	local profmt = {
		__index = function(self, field)
			local name = self[nk]
			return xrp_profiles[name].fields[field] or nil
		end,
		__newindex = function(self, field, contents)
			if xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then
				return
			end
			local name = self[nk]
			if type(contents) == "string" and contents ~= "" and xrp_profiles[name] and xrp_profiles[name].fields[field] ~= contents then
				xrp_profiles[name].fields[field] = contents
				if name == xrp_selectedprofile or (name == L["Default"] and xrp.defaults[xrp_selectedprofile][field] == true) then
					xrp:UpdateField(field)
				end
			elseif (not contents or contents == "") and xrp_profiles[name] and xrp_profiles[name].fields[field] ~= nil then
				xrp_profiles[name].fields[field] = nil
				if name == xrp_selectedprofile or (name == L["Default"] and xrp.defaults[xrp_selectedprofile][field] == true) then
					xrp:UpdateField(field)
				end
			end
		end,
		__call = function(self, action, argument)
			if not xrp_profiles[self[nk]] then
				return false
			elseif action == "length" then
				local length = 0
				for field, contents in pairs(xrp_profiles[self[nk]].fields) do
					length = length + #contents
				end
				return length
			elseif action == "rename" and type(argument) == "string" then
				local name = self[nk]
				if type(xrp_profiles[name]) == "table" and name ~= L["Default"] and (type(xrp_profiles[argument]) ~= "table" or (argument == L["Default"] and name ~= argument and (not xrp_profiles[L["Default (Old)"]] or name == L["Default (Old)"]))) then
					if argument == L["Default"] and name ~= L["Default (Old)"] then
						xrp_profiles[L["Default (Old)"]] = xrp_profiles[argument]
					end
					-- Rename profile to the nonexistant table provided.
					xrp_profiles[argument] = xrp_profiles[name]
					-- Select the new name if this is our active profile.
					if xrp_selectedprofile == argument then
						xrp.profiles(argument)
					end
					xrp.profiles[name] = nil -- Use table access to save Default.
					return true
				end
			elseif action == "copy" and type(argument) == "string" then
				local name = self[nk]
				if type(xrp_profiles[name]) == "table" and (type(xrp_profiles[argument]) ~= "table" or (argument == L["Default"] and argument ~= name and (not xrp_profiles[L["Default (Old)"]] or name == L["Default (Old)"]))) then
					if argument == L["Default"] and name ~= L["Default (Old)"] then
						xrp_profiles[L["Default (Old)"]] = xrp_profiles[argument]
					end
					-- Copy profile into the empty table called.
					xrp_profiles[argument] = {
						fields = {},
						defaults = {},
					}
					for field, contents in pairs(xrp_profiles[name].fields) do
						xrp_profiles[argument].fields[field] = contents
					end
					for field, setting in pairs(xrp_profiles[name].defaults) do
						xrp_profiles[argument].defaults[field] = setting
					end
					-- Will only happen if copying over Default.
					if xrp_selectedprofile == argument then
						xrp:Update()
					end
					return true
				end
			elseif not action then
				local name = self[nk]
				local profile = {}
				for field, contents in pairs(xrp_profiles[name].fields) do
					profile[field] = contents
				end
				return profile
			end
			return false
		end,
		__metatable = false,
	}

	xrp.profiles = setmetatable({}, {
		__index = function(self, name)
			if not xrp_profiles[name] then
				xrp_profiles[name] = {
					fields = {},
					defaults = {},
				}
			end
			if not profs[name] then
				profs[name] = setmetatable({ [nk] = name }, profmt)
			end
			return profs[name]
		end,
		__newindex = function(self, name, profile)
			if type(profile) == "table" then
				if not profs[name] then
					profs[name] = setmetatable({ [nk] = name }, profmt)
				end
				for field, contents in pairs(profile) do
					profs[name][field] = contents
				end
			elseif profile == nil then
				if name ~= L["Default"] then
					xrp_profiles[name] = nil
					profs[name] = nil
					defs[name] = nil
				else
					-- New, almost-blank profile if Default.
					xrp_profiles[name] = {
						fields = {
							NA = xrp.toon.name,
						},
						defaults = {},
					}
				end
				if name == xrp_selectedprofile then
					xrp.profiles(L["Default"])
				end
			end
		end,
		__call = function(self, name, keepoverrides)
			if not name then
				local list = {}
				for name, _ in pairs(xrp_profiles) do
					list[#list + 1] = name ~= L["Default"] and name or nil
				end
				table.sort(list)
				table.insert(list, 1, L["Default"])
				return list
			elseif type(name) == "string" and xrp_profiles[name] then
				xrp_selectedprofile = name
				if not keepoverrides then
					wipe(xrp_overrides)
				end
				xrp:Update()
				return true
			end
			return false
		end,
		__metatable = false,
	})
end

do
	local defmt = {
		__index = function(self, field)
			local profile = self[nk]
			if profile == L["Default"] or not xrp_profiles[profile] then
				return false
			elseif xrp_profiles[profile].defaults[field] ~= nil then
				return xrp_profiles[profile].defaults[field]
			end
			return true
		end,
		__newindex = function(self, field, state)
			local profile = self[nk]
			if profile == L["Default"] or not xrp_profiles[profile] or xrp.fields.unit[field] or xrp.fields.meta[field] or xrp.fields.dummy[field] or not field:find("^%u%u$") then
				return
			end
			if state ~= xrp_profiles[profile].defaults[field] then
				xrp_profiles[profile].defaults[field] = state
				if profile == xrp_selectedprofile then
					xrp:UpdateField(field)
				end
			end
		end,
		__metatable = false,
	}

	xrp.defaults = setmetatable({}, {
		__index = function(self, name)
			if not xrp_profiles[name] then
				return nil
			end
			if not xrp_profiles[profile].defaults then
				xrp_profiles[name].defaults = {}
			end
			if not defs[name] then
				defs[name] = setmetatable({ [nk] = name }, defmt)
			end
			return defs[name]
		end,
		__newindex = nonewindex,
		__metatable = false,
	})
end
