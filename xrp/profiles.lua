--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this program.  If not, see
	<http://www.gnu.org/licenses/>.
]]

local overrides = {}
local converted = {}

xrp.profile = setmetatable({}, {
	__index = function(profile, field)
		if xrp.toon.fields[field] then
			return xrp.toon.fields[field]
		elseif converted[field] then
			return converted[field]
		elseif overrides[field] then
			return overrides[field]
		elseif xrp_profiles[xrp_selectedprofile] and xrp_profiles[xrp_selectedprofile][field] then
			return xrp_profiles[xrp_selectedprofile][field]
		else
			return nil
		end
	end,
	__newindex = function(profile, field, contents)
		-- TODO: Field name checking.
		if type(contents) == "string" and overrides[field] ~= contents then
			overrides[field] = contents
			if field == "AH" then
				local AH = xrp:ConvertHeight(contents, "msp")
				converted.AH = AH == contents and nil or AH
			elseif field == "AW" then
				local AW = xrp:ConvertWeight(contents, "msp")
				converted.AW = AW == contents and nil or AW
			end
			xrp.msp:UpdateField(field)
		elseif contents == nil and overrides[field] then
			overrides[field] = nil
			if field == "AH" then
				converted.AH = nil
				local AH = xrp:ConvertHeight(xrp.profile.AH, "msp")
				converted.AH = AH == xrp.profile.AH and nil or AH
			elseif field == "AW" then
				converted.AW = nil
				local AW = xrp:ConvertWeight(xrp.profile.AW, "msp")
				converted.AW = AW == xrp.profile.AW and nil or AW
			end
			xrp.msp:UpdateField(field)
		end
	end,
	__call = function(profile)
		local out = {}
		for field, contents in pairs(xrp_profiles[xrp_selectedprofile]) do
			out[field] = contents
		end
		for field, contents in pairs(overrides) do
			out[field] = contents
		end
		for field, contents in pairs(xrp.toon.fields) do
			out[field] = contents
		end
		return out
	end,
	__metatable = false,
})

-- This key is used to hide the name of a profile inside its own metaprofile
-- table. Someone could probably access it if they iterated through
-- xrp.profiles.Name, but this is an edge case. The main intent is to prevent
-- it from being mucked with by accident.
local namekey = {}

local metaprofiles = {}

local profilemt = {
	__index = function(profile, field)
		if xrp_profiles[profile[namekey]][field] then
			return xrp_profiles[field]
		end
		return nil
	end,
	__newindex = function(profile, field, contents)
		-- TODO: Check field name for proper formatting.
		local name = profile[namekey]
		if type(contents) == "string" and contents ~= "" and (not xrp_profiles[name] or xrp_profiles[name][field] ~= contents) then
			if not xrp_profiles[name] then
				xrp_profiles[name] = {}
			end
			xrp_profiles[name][field] = contents
			if name == xrp_selectedprofile then
				xrp.msp:UpdateField(field)
			end
			xrp:FireEvent("PROFILE_FIELD_SAVE", name, field)
		elseif (contents == "" or not contents) and xrp_profiles[name] and xrp_profiles[name][field] then
			xrp_profiles[name][field] = nil
			if next(xrp_profiles[name]) then
				if name == xrp_selectedprofile then
					xrp.msp:UpdateField(field)
				end
				xrp:FireEvent("PROFILE_FIELD_SAVE", name, field)
			else
				metaprofiles[name] = nil
				xrp_profiles[name] = nil
				xrp:FireEvent("PROFILE_DELETE", name)
			end
		end
	end,
	__call = function(profile, newname)
		local name = profile[namekey]
		if type(newname) == "string" then
			if type(xrp_profiles[name]) ~= "table" and type(xrp_profiles[newname]) == "table" then
				-- Copy profile into the empty table called.
				xrp_profiles[name] = {}
				for field, contents in pairs(xrp_profiles[newname]) do
					xrp_profiles[name][field] = contents
				end
				return true
			elseif type(xrp_profiles[name]) == "table" and type(xrp_profiles[newname]) ~= "table" then
				xrp_profiles[newname] = xrp_profiles[name]
				xrp_profiles[name] = nil
				xrp:FireEvent("PROFILE_RENAME", name, newname)
				return true
			end
			return false
		elseif not newname then
			local profile = {}
			for field, contents in pairs(xrp_profiles[name]) do
				profile[field] = contents
			end
			return profile
		end
	end,
	__metatable = false,
}

xrp.profiles = setmetatable({}, {
	__index = function(profiles, name)
		if not metaprofiles[name] then
			metaprofiles[name] = setmetatable({ [namekey] = name }, profilemt)
		end
		return metaprofiles[name]
	end,
	__newindex = function(profiles, name, profile)
		if type(profile) == "table" then
			if not metaprofiles[name] then
				metaprofiles[name] = setmetatable({ [namekey] = name }, profilemt)
			end
			for field, contents in pairs(profile) do
				metaprofiles[name][field] = contents
			end
		elseif profile == "" or profile == nil then
			metaprofiles[name] = nil
			xrp_profiles[name] = nil
			xrp:FireEvent("PROFILE_DELETE", name)
		end
	end,
	__call = function(profiles, name)
		if not name then
			local list = {}
			for name, _ in pairs(xrp_profiles) do
				list[#list+1] = name
			end
			table.sort(list)
			return list
		elseif type(name) == "string" and xrp_profiles[name] then
			xrp_selectedprofile = name

			wipe(converted)
			wipe(overrides) -- TODO: Should this really wipe the overrides?

			local AH = xrp:ConvertHeight(xrp_profiles[name].AH, "msp")
			converted.AH = AH == xrp_profiles[name].AH and nil or AH
			
			local AW = xrp:ConvertWeight(xrp_profiles[name].AW, "msp")
			converted.AW = AW == xrp_profiles[name].AW and nil or AW
			
			xrp.msp:Update()
			return true
		end
		return false
	end,
	__metatable = false,
})

function xrp:Logout()
	-- Add one to the versions of any overriden fields. This means we can
	-- just pick them up where we left off next time (leading to lower
	-- bandwidth usage if the player doesn't change big fields often!),
	-- rather than incrementing by one on each and every login.
	local ttchanges = false
	for field, _ in pairs(overrides) do
		xrp_versions[field] = xrp_versions[field] + 1
		if not ttchanges and xrp.msp.ttfields[field] then
			ttchanges = true
		end
	end
	if ttchanges then
		xrp_versions.TT = xrp_versions.TT + 1
	end
end
