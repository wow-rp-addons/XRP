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
			contents = xrp_overrides[field]
		elseif xrp_profiles[xrp_selectedprofile] and xrp_profiles[xrp_selectedprofile][field] then
			contents = xrp_profiles[xrp_selectedprofile][field]
		elseif xrp.defaults[xrp_selectedprofile][field] == true and xrp_profiles[L["Default"]][field] then
			contents = xrp_profiles[L["Default"]][field]
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
		if not xrp.msp.unitfields[field] and not xrp.msp.metafields[field] and not xrp.msp.dummyfields[field] and field:find("^%u%u$") and xrp_overrides[field] ~= contents then
			xrp_overrides[field] = contents
			xrp.msp:UpdateField(field)
		end
	end,
	__call = function(self)
		local out = {}
		for field, contents in pairs(xrp_profiles[L["Default"]]) do
			if xrp.defaults[xrp_selectedprofile][field] then
				out[field] = contents
			end
		end
		for field, contents in pairs(xrp_profiles[xrp_selectedprofile]) do
			out[field] = contents
		end
		for field, contents in pairs(xrp_overrides) do
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

-- Current selected profile (no overrides).
xrp.selected = setmetatable({}, {
	__index = function(self, field)
		local contents
		if xrp.toon.fields[field] then
			contents = xrp.toon.fields[field]
		elseif xrp_profiles[xrp_selectedprofile] and xrp_profiles[xrp_selectedprofile][field] then
			contents = xrp_profiles[xrp_selectedprofile][field]
		elseif xrp.defaults[xrp_selectedprofile][field] == true and xrp_profiles[L["Default"]][field] then
			contents = xrp_profiles[L["Default"]][field]
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
	__newindex = function() end,
	__call = function(self)
		local out = {}
		for field, contents in pairs(xrp_profiles[L["Default"]]) do
			if xrp.defaults[xrp_selectedprofile][field] then
				out[field] = contents
			end
		end
		for field, contents in pairs(xrp_profiles[xrp_selectedprofile]) do
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

-- This key is used to 'hide' the name of a profile inside its own meta
-- table. This is obviously accessible, but it just prevents accidental
-- mucking with.
local nk = {}

local profmt = {
	__index = function(self, field)
		if not xrp_profiles[self[nk]] then
			xrp_profiles[self[nk]] = {}
		end
		if xrp_profiles[self[nk]][field] then
			return xrp_profiles[self[nk]][field]
		end
		return nil
	end,
	__newindex = function(self, field, contents)
		if xrp.msp.unitfields[field] or xrp.msp.metafields[field] or xrp.msp.dummyfields[field] or not field:find("^%u%u$") then
			return
		end
		local name = self[nk]
		if type(contents) == "string" and contents ~= "" and (not xrp_profiles[name] or xrp_profiles[name][field] ~= contents) then
			if not xrp_profiles[name] then
				xrp_profiles[name] = {}
			end
			xrp_profiles[name][field] = contents
			if name == xrp_selectedprofile then
				xrp.msp:UpdateField(field)
			end
		elseif (contents == "" or not contents) and xrp_profiles[name] and xrp_profiles[name][field] then
			xrp_profiles[name][field] = nil
			if name == xrp_selectedprofile then
				xrp.msp:UpdateField(field)
			end
		end
	end,
	__call = function(self, action, argument)
		if not xrp_profiles[self[nk]] then
			return false
		elseif action == "length" then
			local length = 0
			for field, contents in pairs(xrp_profiles[self[nk]]) do
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
				if xrp_defaults[name] then
					xrp_defaults[argument] = xrp_defaults[name]
				end
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
				xrp_profiles[argument] = {}
				for field, contents in pairs(xrp_profiles[name]) do
					xrp_profiles[argument][field] = contents
				end
				if xrp_defaults[name] then
					xrp_defaults[argument] = {}
					for field, setting in pairs(xrp_defaults[name]) do
						xrp_defaults[argument][field] = setting
					end
				end
				-- Will only happen if copying over Default.
				if xrp_selectedprofile == argument then
					xrp.msp:Update()
				end
				return true
			end
		elseif not action then
			local name = self[nk]
			local profile = {}
			for field, contents in pairs(xrp_profiles[name]) do
				profile[field] = contents
			end
			return profile
		end
		return false
	end,
	__metatable = false,
}

local profs = setmetatable({}, { __mode = "v" })

xrp.profiles = setmetatable({}, {
	__index = function(self, name)
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
			profs[name] = nil
			if name ~= L["Default"] then
				xrp_profiles[name] = nil
				xrp.defaults[name] = nil
			else
				-- Wipe fields if profile is Default, but don't delete
				-- the table.
				for field, _ in pairs(xrp_profiles[name]) do
					xrp_profiles[name][field] = nil
				end
				-- Fill out one default value...
				xrp_profiles[name].NA = xrp.toon.name
			end
			if name == xrp_selectedprofile then
				xrp.profiles(L["Default"])
			end
		end
	end,
	__call = function(self, name)
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
			wipe(xrp_overrides)
			xrp.msp:Update()
			return true
		end
		return false
	end,
	__metatable = false,
})
