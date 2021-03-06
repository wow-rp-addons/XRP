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

local Values = AddOn_XRP.Strings.Values

AddOn.WeakValueMetatable = { __mode = "v" }
AddOn.WeakKeyMetatable = { __mode = "k" }

function AddOn.DoNothing() end

function AddOn.BuildCharacterID(name, realm)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	return AddOn_Chomp.NameMergedRealm(name, realm)
end

function AddOn.SanitizeText(text)
	if not text or text == "" then
		return nil
	elseif type(text) ~= "string" then
		error("XRP: AddOn.SanitizeText(): text: expected string or nil, got " .. type(text), 2)
	end
	local gsub = string.gsub
	text = gsub(text, "\192\160", "\032") -- Non-break space.
	text = gsub(text, "\009", "\032\032\032\032\032\032\032\032") -- Tabs.
	text = gsub(text, "\013\010?", "\010") -- CR/CRLF to LF
	-- The rest of these deal with non-printable ASCII and invalid UTF-8.
	text = gsub(text, "[%z\001-\009\011-\031\127\192\193\245-\255]", "")
	text = gsub(text, "([\010\032-\126])[\128-\191]*", "%1")
	text = gsub(text, "[\194-\244]+([\194-\244])", "%1")
	text = gsub(text, "[\194-\244]([\010\032-\126])", "%1")

	if text:trim() == "" then
		return nil
	end
	return text
end

function AddOn_XRP.RemoveTextFormats(text, permitIndent)
	if not text or text == "" then
		return nil
	elseif type(text) ~= "string" then
		error("AddOn_XRP.RemoveTextFormats(): text: expected string or nil, got " .. type(text), 2)
	end
	local gsub = string.gsub
	-- This fully removes all color escapes, texture escapes, and most types of
	-- link and chat link escapes. Other UI escape sequences are escaped
	-- themselves to not render on display (|| instead of |).
	text = gsub(text, "||", "\001") -- Avoid an issue with triple pipes and %f.
	text = gsub(text, "%f[|]|c%x%x%x%x%x%x%x%x", "")
	text = gsub(text, "%f[|]|r", "")
	text = gsub(text, "%f[|]|H.-|h(.-)|h", "%1")
	text = gsub(text, "%f[|]|T.-|t", "")
	text = gsub(text, "%f[|]|K.-|k.-|k", "")
	text = gsub(text, "\001", "||") -- Part two of above issue-avoiding.
	text = gsub(text, "%f[|]|%f[^|]", "||")

	local trimmedText = text:trim()
	if trimmedText == "" then
		return nil
	elseif permitIndent then
		return text:trim("\r\n"):match("^(.-)%s*$")
	end
	return trimmedText
end

function AddOn.LinkURLs(text)
	if type(text) ~= "string" then
		return nil
	end
	local gsub = string.gsub
	text = gsub(text, "%f[%@%w]([%w%-%.]+%.com%f[^%w%/])", "http://%1")
	text = gsub(text, "%f[%@%w]([%w%-%.]+%.net%f[^%w%/])", "http://%1")
	text = gsub(text, "%f[%@%w]([%w%-%.]+%.org%f[^%w%/])", "http://%1")
	text = gsub(text, "([%w%-%.]+%.[%w%-]+%/)", "http://%1")
	text = gsub(text, "(https?://)http://", "%1")
	text = gsub(text, "%f[%w%@]%@([%w%_]+)%f[^%w%_%.]", "https://twitter.com/%1")
	text = gsub(text, "https?://[Tt]witter.com/([%w%_]+)%f[^%w%_%/]", "|H@%1|h|cff00aced@%1|r|h")
	text = gsub(text, "<?(https?://[%w%%%-%.%_%~%:%/%?#%[%]%@%!%$%&%'%(%)%*%+%,%;%=]+)>?", "|H%1|h|cffc845fa<%1>|r|h")
	return text
end

local BASIC = "^%%s*%s%%s*$"
local KG1, KG2 = BASIC:format(L.KG1), BASIC:format(L.KG2)
local LBS1, LBS2 = BASIC:format(L.LBS1), BASIC:format(L.LBS2)
function AddOn.ConvertWeight(weight, units)
	local number = tonumber(weight)
	if not number and type(weight) ~= "string" then
		return nil
	elseif not number then
		-- Match "50kg", "50 kg", "50 kilograms", etc..
		number = tonumber(weight:lower():match(KG1)) or tonumber(weight:lower():match(KG2))
	end
	if not number then
		-- Match "50lbs", "50 lbs", "50 pounds", etc.
		number = tonumber(weight:lower():match(LBS1)) or tonumber(weight:lower():match(LBS2))
		number = number and number / 2.20462
	end
	if not units then
		units = AddOn.Settings.weightUnits
	end
	if not number then
		return weight
	elseif number < 0 then
		return nil
	elseif units == "msp" then -- MSP internal format: kg without units as string.
		return ("%.1f"):format(number)
	elseif units == "kg" then
		return L.KG:format(number)
	elseif units == "lb" then
		return L.LBS:format(number * 2.20462)
	end
	return weight
end

local CM1, CM2 = BASIC:format(L.CM1), BASIC:format(L.CM2)
local M1, M2 = BASIC:format(L.M1), BASIC:format(L.M2)
local FT1, FT2, FT3 = BASIC:format(L.FT1), BASIC:format(L.FT2), BASIC:format(L.FT3)
function AddOn.ConvertHeight(height, units)
	local number = tonumber(height)
	if not number and type(height) ~= "string" then
		return nil
	elseif number and number <= 10 then
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
		number = number ~= 0 and number
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
		number = feet and (((tonumber(feet) * 12) + (tonumber(inches) or 0)) * 2.54)
	end
	if not units then
		units = AddOn.Settings.heightUnits
	end
	if not number then
		return height
	elseif number < 0 then
		return nil
	elseif units == "msp" then -- MSP internal format: cm without units as string.
		return ("%.0f"):format(number)
	elseif units == "cm" then
		return L.CM:format(number)
	elseif units == "m" then
		return L.M:format(number * 0.01)
	elseif units == "ft" then
		local feet, inches = math.modf(number / 30.48)
		inches = inches * 12
		if inches >= 11.5 then
			feet = feet + 1
			inches = 0
		end
		return L.FT:format(feet, inches)
	end
	return height
end

local IC_STATUS = {
	["2"] = true,
	["3"] = true,
	["4"] = true,
}
function AddOn.IsStatusIC(status)
	return IC_STATUS[status] or false
end

function AddOn_XRP.SetStatus(status)
	local statusType = type(status)
	if statusType == "number" then
		status = tostring(status)
	end
	if Values.FC[status] then
		AddOn_XRP.SetField("FC", status)
	else
		local profileIC = AddOn.IsStatusIC(AddOn_XRP.Profiles.SELECTED.Full.FC)
		if status == "ic" and profileIC then
			AddOn_XRP.SetField("FC", nil)
		elseif status == "ic" then
			AddOn_XRP.SetField("FC", "2")
		elseif status == "ooc" and not profileIC then
			AddOn_XRP.SetField("FC", nil)
		elseif status == "ooc" then
			AddOn_XRP.SetField("FC", "1")
		else
			error("AddOn_XRP.SetStatus(): status: expected number in range 1-4 or string with value \"ic\" or \"ooc\"", 2)
		end
	end
end

function AddOn_XRP.ToggleStatus()
	return AddOn_XRP.SetStatus(AddOn_XRP.Characters.byUnit.player.inCharacter and "ooc" or "ic")
end
