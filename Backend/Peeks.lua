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

local GlancesCache = setmetatable({}, AddOn.WeakValueMetatable)

local function ClonePE(PE)
	if not PE then
		return nil
	end
	local clone = {}
	for i, peek in ipairs(PE) do
		clone[i] = {
			IC = peek.IC,
			NA = peek.NA,
			DE = peek.DE,
		}
	end
	return clone
end

local function StringToPeek(str)
	local icon = str:match("%f[^\n%z]|T([^:|]+)[^|]*|t%f[\n%z]") or "Interface\\Icons\\TEMP"
	local name = str:match("%f[^\n%z]#+% *(.-)% *%f[\n%z]") or UNKNOWN
	local description = str:match("%f[^\n%z]% *([^|#].-)%s*$")
	return {
		IC = icon,
		NA = name,
		DE = description,
	}
end

function AddOn.StringToPE(str)
	if not str then
		return nil
	elseif GlancesCache[str] then
		return ClonePE(GlancesCache[str])
	end
	local PE = {}
	local index = 1
	local i = 1
	while index do
		local nextSplit, nextIndex = str:find("\n\n---\n\n", index, true)
		PE[i] = StringToPeek(str:sub(index, nextSplit or #str))
		i = i + 1
		index = nextIndex
	end
	GlancesCache[str] = ClonePE(PE)
	return PE
end

function AddOn.PEToString(PE)
	if not PE then
		return nil
	end
	local peeks = {}
	for i, peek in ipairs(PE) do
		if i > 1 then
			peeks[#peeks + 1] = "\n\n---\n\n"
		end
		peeks[#peeks + 1] = "|T"
		peeks[#peeks + 1] = peek.IC
		peeks[#peeks + 1] = ":32:32|t\n"
		if peek.NA then
			peeks[#peeks + 1] = "#"
			peeks[#peeks + 1] = peek.NA
			peeks[#peeks + 1] = "\n\n"
		end
		if peek.DE then
			peeks[#peeks + 1] = peek.DE
		end
	end
	return table.concat(peeks)
end
