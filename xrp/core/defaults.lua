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

-- This key is used to 'hide' the name of a profile inside its own meta
-- table. This is obviously accessible, but it just prevents accidental
-- mucking with.
local nk = {}

local defmt = {
	__index = function(default, field)
		if default[nk] ~= "Default" and xrp_defaults[default[nk]] and xrp_defaults[default[nk]][field] ~= nil then
			return xrp_defaults[default[nk]][field]
		end
		return xrp_settings.defaults[field]
	end,
	__newindex = function(default, field, state)
		if xrp.msp.unitfields[field] or xrp.msp.metafields[field] or not field:match("^%u%u$") or default[nk] == "Default" then
			return
		end
		if not xrp_defaults[default[nk]] then
			xrp_defaults[default[nk]] = {}
		end
		if state == nil then
			xrp_defaults[default[nk]][field] = nil
			if not next(xrp_defaults[default[nk]]) then
				xrp.defaults[default[nk]] = nil
			end
		elseif state == true or state == false then
			xrp_defaults[default[nk]][field] = state
		end
	end,
	__call = function(default)
		local out = {}
		for field, state in pairs(xrp_defaults[default[nk]]) do
			out[field] = state
		end
		return out
	end,
	__metatable = false,
}

local defs = setmetatable({}, { __mode = "v" })

xrp.defaults = setmetatable({}, {
	__index = function(defaults, name)
		if not defs[name] then
			defs[name] = setmetatable({ [nk] = name }, defmt)
		end
		return defs[name]
	end,
	__newindex = function(defaults, name, default)
		if type(default) == "table" then
			if not defs[name] then
				defs[name] = setmetatable({ [nk] = name }, defmt)
			end
			for field, default in pairs(default) do
				defs[name][field] = default
			end
		elseif default == nil then
			defs[name] = nil
		end
	end,
	__metatable = false,
})
