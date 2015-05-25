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

function xrp.UnitFullName(unit)
	if not (unit == "player" or UnitIsPlayer(unit)) then
		return nil
	end
	return xrp.FullName(UnitName(unit))
end

function xrp.FullName(name, realm)
	if not name or name == "" then
		return nil
	elseif name:find("-", nil, true) then
		return name
	elseif realm and realm ~= "" then
		return FULL_PLAYER_NAME:format(name, (realm:gsub("%s*%-*", "")))
	end
	return FULL_PLAYER_NAME:format(name, (GetRealmName():gsub("%s*%-*", "")))
end

-- Dumb version of Ambiguate() which always strips.
function xrp.ShortName(name)
	if type(name) ~= "string" then
		return UNKNOWN
	end
	return name:match("^([^%-]+)")
end

do
	-- Realms just needing title case spacing are handled via gsub. These are
	-- more complex, such as lower case words or dashes.
	local SPECIAL_REALMS = {
		["AltarofStorms"] = "Altar of Storms",
		["AzjolNerub"] = "Azjol-Nerub",
		["ChamberofAspects"] = "Chamber of Aspects",
		["SistersofElune"] = "Sisters of Elune",
	}

	function xrp.RealmDisplayName(realm)
		-- gsub: spaces lower followed by upper/number (i.e., Wyrmrest Accord).
		return SPECIAL_REALMS[realm] or (realm:gsub("(%l)([%u%d])", "%1 %2"))
	end
end

function xrp.Strip(text, allowIndent)
	if type(text) ~= "string" then
		return nil
	end
	-- This fully removes all color escapes, texture escapes, and most types of
	-- link and chat link escapes. Other UI escape sequences are escaped
	-- themselves to not render on display (|| instead of |).
	text = text:gsub("%f[|]|c%x%x%x%x%x%x%x%x", ""):gsub("%f[|]|r", ""):gsub("%f[|]|H.-|h(.-)|h", "%1"):gsub("%f[|]|T.-|t", ""):gsub("%f[|]|K.-|k.-|k", ""):gsub("%f[|]|%f[^|]", "||")
	if allowIndent then
		return text:trim("\r\n"):match("^(.-)%s*$")
	else
		return text:trim()
	end
end

local BASIC = "^%%s*%s%%s*$"
local KG1, KG2 = BASIC:format(_xrp.L.KG1), BASIC:format(_xrp.L.KG2)
local LBS1, LBS2 = BASIC:format(_xrp.L.LBS1), BASIC:format(_xrp.L.LBS2)
function xrp.Weight(weight, units)
	if not weight then
		return nil
	end
	local number = tonumber(weight)
	if not number then
		-- Match "50kg", "50 kg", "50 kilograms", etc..
		number = tonumber(weight:lower():match(KG1)) or tonumber(weight:lower():match(KG2))
	end
	if not number then
		-- Match "50lbs", "50 lbs", "50 pounds", etc.
		number = ((tonumber(weight:lower():match(LBS1)) or tonumber(weight:lower():match(LBS2))) or 0) / 2.20462
		number = number ~= 0 and number or nil
	end
	if not units then
		units = _xrp.settings.display.weight
	end
	if not number then
		return weight
	elseif number < 0 then
		return nil
	elseif units == "msp" then -- MSP internal format: kg without units as string.
		return ("%.1f"):format(number + 0.05)
	elseif units == "kg" then
		return _xrp.L.KG:format(number + 0.05)
	elseif units == "lb" then
		return _xrp.L.LBS:format((number * 2.20462) + 0.5)
	end
	return weight
end

local CM1, CM2 = BASIC:format(_xrp.L.CM1), BASIC:format(_xrp.L.CM2)
local M1, M2 = BASIC:format(_xrp.L.M1), BASIC:format(_xrp.L.M2)
local FT1, FT2, FT3 = BASIC:format(_xrp.L.FT1), BASIC:format(_xrp.L.FT2), BASIC:format(_xrp.L.FT3)
function xrp.Height(height, units)
	if not height then
		return nil
	end
	local number = tonumber(height)
	if number and number <= 10 then
		-- Under 10 is assumed to be meters if a plain number.
		number = number * 100
	end
	if not number then
		-- Match "100cm", "100 cm", "100 centimeters", "100 centimetres", etc.
		number = tonumber(height:lower():match(CM1)) or tonumber(height:lower():match(CM2))
	end
	if not number then
		-- Match "1.05m", "1.05 m", "1.05 meters", "1.05 metres" etc..
		number = (tonumber(height:lower():match(M1)) or tonumber(height:lower():match(M2)) or 0) * 100
		number = number ~= 0 and number or nil
	end
	if not number then
		-- Match "4'9", "4'9"", "4 ft 9 in", etc.
		local feet, inches = height:lower():match(FT1)
		if not feet then
			feet, inches = height:lower():match(FT2)
		end
		if not feet then
			feet, inches = height:lower():match(FT3)
		end
		number = feet and (((tonumber(feet) * 12) + (tonumber(inches) or 0)) * 2.54) or nil
	end
	if not units then
		units = _xrp.settings.display.height
	end
	if not number then
		return height
	elseif number < 0 then
		return nil
	elseif units == "msp" then -- MSP internal format: cm without units as string.
		return ("%d"):format(number + 0.5)
	elseif units == "cm" then
		return _xrp.L.CM:format(number + 0.5)
	elseif units == "m" then
		return _xrp.L.M:format(math.floor(number + 0.5) * 0.01) -- Round first.
	elseif units == "ft" then
		local feet, inches = math.modf(number / 30.48)
		inches = (inches * 12) + 0.5
		if inches >= 12 then
			feet = feet + 1
			inches = 0
		end
		return _xrp.L.FT:format(feet, inches)
	end
	return height
end

function xrp.Status(desiredStatus)
	local profileStatus = xrp.profiles.SELECTED.fullFields.FC or "0"
	if not desiredStatus then
		local currentStatus = xrp.current.fields.FC
		local currentIC, profileIC = currentStatus ~= nil and currentStatus ~= "1" and currentStatus ~= "0", profileStatus ~= nil and profileStatus ~= "1" and profileStatus ~= "0"
		desiredStatus = currentStatus ~= profileStatus and currentIC ~= profileIC and profileStatus or currentIC and "1" or "2"
	end
	if desiredStatus ~= profileStatus then
		xrp.current.fields.FC = desiredStatus ~= "0" and desiredStatus or ""
	else
		xrp.current.fields.FC = nil
	end
end
