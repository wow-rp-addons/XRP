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

local Names = AddOn_XRP.Strings.Names

-- Fields to export.
local EXPORT_FIELDS = { "NA", "NI", "NT", "NH", "RA", "RC", "AE", "AH", "AW", "AG", "HH", "HB", "CU", "CO", "MO", "DE", "HI" }
local ALLOW_INDENT = { CU = true, MO = true, DE = true, HI = true }
local EXPORT_FORMATS = {}

local SIMPLE = SUBTITLE_FORMAT:format("%s", "%%s\n")
local QUOTED = SUBTITLE_FORMAT:format("%s", L.NICKNAME:format("%%s")) .. "\n"
local SPACED = STAT_FORMAT:format("\n%s") .. "\n%%s\n"
local function UNDERLINED(text)
	local colon = STAT_FORMAT:format(text)
	local ret = { "\n", colon, "\n" }
	for i = 1, strlenutf8(colon) do
		ret[#ret + 1] = "-"
	end
	ret[#ret + 1] = "\n%s\n"
	return table.concat(ret)
end

for i, field in ipairs(EXPORT_FIELDS) do
	if field == "NI" then
		EXPORT_FORMATS[field] = QUOTED:format(Names[field])
	elseif field == "CU" or field =="MO" then
		EXPORT_FORMATS[field] = SPACED:format(Names[field])
	elseif field == "DE" or field == "HI" then
		EXPORT_FORMATS[field] = UNDERLINED(Names[field])
	else
		EXPORT_FORMATS[field] = SIMPLE:format(Names[field])
	end
end

function AddOn.ExportText(title, fields)
	local export = { title, "\n" }
	for i = 1, strlenutf8(title) do
		export[#export + 1] = "="
	end
	export[#export + 1] = "\n"
	for i, field in ipairs(EXPORT_FIELDS) do
		local fieldText = AddOn_XRP.RemoveTextFormats(fields[field], ALLOW_INDENT[field])
		if ALLOW_INDENT[field] then
			fieldText = AddOn.LinkURLs(fieldText)
		end
		if fieldText then
			if field == "AH" then
				fieldText = AddOn.ConvertHeight(fieldText)
			elseif field == "AW" then
				fieldText = AddOn.ConvertWeight(fieldText)
			end
			export[#export + 1] = EXPORT_FORMATS[field]:format(fieldText)
		end
	end
	return table.concat(export)
end
