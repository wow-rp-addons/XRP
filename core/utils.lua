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

local addonName, xrpPrivate = ...

function xrp:UnitNameWithRealm(unit)
	if not (unit == "player" or UnitIsPlayer(unit)) then
		return nil
	end
	return self:NameWithRealm(UnitName(unit))
end

function xrp:NameWithRealm(name, realm)
	if not name or name == "" then
		return nil
	elseif name:find(FULL_PLAYER_NAME:format(".+", ".+")) then
		return name
	elseif realm and realm ~= "" then
		-- If a realm was provided, use it.
		return FULL_PLAYER_NAME:format(name, (realm:gsub("%s*%-*", "")))
	end
	return FULL_PLAYER_NAME:format(name, (GetRealmName():gsub("%s*%-*", "")))
end

-- Dumb version of Ambiguate() which always strips.
function xrp:NameWithoutRealm(name)
	if type(name) ~= "string" then
		return UNKNOWN
	end
	return name:match(FULL_PLAYER_NAME:format("(.+)", ".+")) or name
end

do
	-- Realms just needing title case spacing are handled via gsub. These are
	-- more complex, such as lower case words, digits, or dashes.
	local realms = {
		["AltarofStorms"] = "Altar of Storms",
		["Area52"] = "Area 52",
		["AzjolNerub"] = "Azjol-Nerub",
		["ChamberofAspects"] = "Chamber of Aspects",
		["SistersofElune"] = "Sisters of Elune",
	}

	function xrp:RealmNameWithSpacing(realm)
		-- gsub: spaces lower followed by upper (i.e., Wyrmrest Accord).
		return realms[realm] or (realm:gsub("(%l)(%u)", "%1 %2"))
	end
end

function xrp:StripEscapes(text)
	if type(text) ~= "string" then
		return nil
	end
	-- This fully removes all color escapes, newline escapes, texture escapes,
	-- and most types of link and chat link escapes. Other UI escape sequences
	-- are escaped themselves to not render on display (|| instead of |).
	return text:gsub("||", "|"):gsub("|n", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|K.-|k.-|k", ""):gsub("|", "||"):trim()
end

function xrp:LinkURLs(text)
	if type(text) ~= "string" then
		return nil
	end
	-- Garbled mess? Not as much.
	-- 1) Add http:// to .com URLs.
	-- 2) Add http:// to .net URLs.
	-- 3) Add http:// to .org URLs.
	-- 4) Strip excess added http://.
	-- 5) Make all links into hyperlinks.
	return (text:gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.com[^%w])", "http://%1"):gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.net[^%w])", "http://%1"):gsub("([ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-%.]+%.org[^%w])", "http://%1"):gsub("(bit%.ly%/)", "http://%1"):gsub("(https?://)http://", "%1"):gsub("(https?://[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%%%-%.%_%~%:%/%?#%[%]%@%!%$%&%'%(%)%*%+%,%;%=]+)", "|H%1|h|cffc845fa[%1]|r|h"))
end

function xrp:ConvertWeight(weight, units)
	if not weight then
		return nil
	end
	local number = tonumber(weight)
	if not number then
		-- Match "50kg", "50 kg", "50 kilograms", etc..
		number = tonumber(weight:lower():match("^%s*(%d+)%s*kg")) or tonumber(weight:lower():match("^%s*(%d+)%s*kilo"))
	end
	if not number then
		-- Match "50lbs", "50 lbs", "50 pounds", etc.
		number = ((tonumber(weight:lower():match("^%s*(%d+)%s*lb")) or tonumber(weight:lower():match("^%s*(%d+)%s*pound"))) or 0) / 2.20462
		number = number ~= 0 and number or nil
	end
	if not number then
		return weight
	end

	units = (not units or units == "user") and xrpPrivate.settings.display.weight or units
	if units == "msp" then -- MSP internal format: kg without units as string.
		return ("%.1f"):format(number + 0.05)
	elseif units == "kg" then
		return ("%u kg"):format(number + 0.5)
	elseif units == "lb" then
		return ("%u lbs"):format((number * 2.20462) + 0.5)
	else
		return weight
	end
end

function xrp:ConvertHeight(height, units)
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
		number = tonumber(height:lower():match("^%s*(%d+)%s*cm")) or tonumber(height:lower():match("^%s*(%d+)%s*centimet"))
	end
	if not number then
		-- Match "1.05m", "1.05 m", "1.05 meters", "1.05 metres" etc..
		number = (tonumber(height:lower():match("^%s*(%d+%.?%d*)%s*m")) or 0) * 100
		number = number ~= 0 and number or nil
	end
	if not number then
		-- Match "4'9", "4'9"", "4 ft 9 in", etc.
		local feet, inches = height:lower():match("^%s*(%d+)%s*'%s*(%d*)")
		if not feet then
			feet, inches = height:lower():match("^%s*(%d+)%s*ft%.?%s*(%d*)")
		end
		if not feet then
			feet, inches = height:lower():match("^%s*(%d+)%s*feet%s*(%d*)")
		end
		number = feet and (((tonumber(feet) * 12) + (tonumber(inches) or 0)) * 2.54) or nil
	end
	if not number then
		return height
	end

	units = (not units or units == "user") and xrpPrivate.settings.display.height or units
	if units == "msp" then -- MSP internal format: cm without units as string.
		return ("%u"):format(number + 0.5)
	elseif units == "cm" then
		return ("%u cm"):format(number + 0.5)
	elseif units == "m" then
		return ("%.2f m"):format(math.floor(number + 0.5) * 0.01) -- Round first.
	elseif units == "ft" then
		local feet, inches = math.modf(number / 30.48)
		inches = (inches * 12) + 0.5
		if inches >= 12 then
			feet = feet + 1
			inches = 0
		end
		return ("%u'%u\""):format(feet, inches)
	else
		return height
	end
end
