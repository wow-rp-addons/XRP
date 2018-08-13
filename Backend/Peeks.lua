--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local GlancesCache = setmetatable({}, AddOn.WeakValueMetatable)

local PEMetatable = {}
function PEMetatable:__eq(toCompare)
	if #self ~= #toCompare then
		return false
	end
	for i, peek in ipairs(self) do
		local compPeek = toCompare[i]
		if peek.IC ~= compPeek.IC or peek.NA ~= compPeek.NA or peek.DE ~= compPeek.DE then
			return false
		end
	end
	return true
end

PEMetatable.__metatable = false

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
	local icon = str:match("%f[^\n%z]|T([^:|]+)[^|]*|t%f[\n%z]")
	local name = str:match("%f[^\n%z]#+% *(.-)% *%f[\n%z]")
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
		return setmetatable(ClonePE(GlancesCache[str]), PEMetatable)
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
	return setmetatable(PE, PEMetatable)
end

function AddOn.PEToString(PE)
	if not PE then
		return nil
	end
	local peeks = {}
	for i, peek in ipairs(PE) do
		if peek.IC or peek.NA or peek.DE then
			if i > 1 then
				peeks[#peeks + 1] = "\n\n---\n\n"
			end
			if peek.IC then
				peeks[#peeks + 1] = "|T"
				peeks[#peeks + 1] = peek.IC
				peeks[#peeks + 1] = ":32:32|t\n"
			end
			if peek.NA then
				peeks[#peeks + 1] = "#"
				peeks[#peeks + 1] = peek.NA
				peeks[#peeks + 1] = "\n\n"
			end
			if peek.DE then
				peeks[#peeks + 1] = peek.DE
			end
		end
	end
	return table.concat(peeks)
end

function AddOn.GetEmptyPE()
	return setmetatable({}, PEMetatable)
end
