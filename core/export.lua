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

local addonName, _xrp = ...

-- Fields to export.
local EXPORT_FIELDS = { "NA", "NI", "NT", "NH", "RA", "RC", "AE", "AH", "AW", "AG", "HH", "HB", "CU", "MO", "DE", "HI" }
local EXPORT_FORMATS = {}

local SIMPLE = SUBTITLE_FORMAT:format("%s", "%%s\n")
local QUOTED = SUBTITLE_FORMAT:format("%s", _xrp.L.NICKNAME:format("%%s")) .. "\n"
local SPACED = STAT_FORMAT:format("\n%s") .. "\n%%s\n"
local function UNDERLINED(text)
	local colon = STAT_FORMAT:format(text)
	local ret = { "\n", colon, "\n" }
	for i = 1, #colon do
		ret[#ret + 1] = "-"
	end
	ret[#ret + 1] = "\n%s\n"
	return table.concat(ret)
end

for i, field in ipairs(EXPORT_FIELDS) do
	if field == "NI" then
		EXPORT_FORMATS[field] = QUOTED:format(xrp.fields[field])
	elseif field == "CU" or field =="MO" then
		EXPORT_FORMATS[field] = SPACED:format(xrp.fields[field])
	elseif field == "DE" or field == "HI" then
		EXPORT_FORMATS[field] = UNDERLINED(xrp.fields[field])
	else
		EXPORT_FORMATS[field] = SIMPLE:format(xrp.fields[field])
	end
end

function _xrp.ExportText(title, fields)
	local export = { title, "\n" }
	for i = 1, #title do
		export[#export + 1] = "="
	end
	export[#export + 1] = "\n"
	for i, field in ipairs(EXPORT_FIELDS) do
		local fieldText = fields[field]
		if fieldText then
			if field == "AH" then
				fieldText = xrp:Height(fieldText)
			elseif field == "AW" then
				fieldText = xrp:Weight(fieldText)
			end
			export[#export + 1] = EXPORT_FORMATS[field]:format(fieldText)
		end
	end
	return table.concat(export)
end
