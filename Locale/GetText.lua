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

local LOCALE = GetLocale()
local LANGUAGE, COUNTRY = LOCALE:match("^(%l%l)(%u%u)$")

local DEFAULT = "en"

local constants = {}
local lookups = {}

local GetTextMetatable = {}
local GetText = setmetatable({}, GetTextMetatable)

function GetTextMetatable.__call(self, lookupStr)
	if lookups[LOCALE] and lookups[LOCALE][lookupStr] then
		return lookups[LOCALE][lookupStr]
	elseif lookups[LANGUAGE] and lookups[LANGUAGE][lookupStr] then
		return lookups[LANGUAGE][lookupStr]
	end
	return lookupStr
end

function GetTextMetatable.__index(self, constantStr)
	if constants[LOCALE] and constants[LOCALE][constantStr] then
		return constants[LOCALE][constantStr]
	elseif constants[LANGUAGE] and constants[LANGUAGE][constantStr] then
		return constants[LANGUAGE][constantStr]
	elseif constants[DEFAULT] and constants[DEFAULT][constantStr] then
		return constants[DEFAULT][constantStr]
	end
	return constantStr
end

local function AddLocale(locale, constantTable, lookupTable)
	if type(locale) ~= "string" then
		error("AddLocale(): locale: expected string, got " .. type(locale), 2)
	end
	local language, country = locale:match("^(%l%l)(%u%u)$")
	if  not language or not country then
		error("AddLocale(): locale: expected \"xxYY\" language/country locale string, got " .. locale, 2)
	elseif type(constantTable) ~= "table" then
		error("AddLocale(): constantTable: expected table, got " .. type(constantTable), 2)
	elseif lookupTable and type(lookupTable) ~= "table" then
		error("AddLocale(): lookupTable: expected table or nil, got " .. type(lookupTable), 2)
	end
	constants[locale] = constantTable
	if locale == LOCALE then
		-- This saves some function call overhead if we have the exact locale
		-- available for a translation.
		for k, v in pairs(constantTable) do
			GetText[k] = v
		end
	end
	if lookupTable then
		lookups[locale] = lookupTable
	end
	if not constants[language] then
		constants[language] = constantTable
		-- Lookup tables aren't guaranteed for the default locale, so only add
		-- a language-default one if there wasn't already a language-default
		-- constants table (which is mandatory).
		if lookupTable then
			lookups[language] = lookupTable
		end
	end
end

AddOn.GetText = GetText
AddOn.AddLocale = AddLocale
