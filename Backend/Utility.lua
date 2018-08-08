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

AddOn.WeakValueMetatable = { __mode = "v" }
AddOn.WeakKeyMetatable = { __mode = "k" }

function AddOn.DoNothing() end

function xrp.UnitCharacterID(unit)
	if type(unit) ~= "string" or unit ~= "player" and not UnitIsPlayer(unit) then
		return nil
	end
	return AddOn_Chomp.NameMergedRealm(UnitFullName(unit))
end

function xrp.BuildCharacterID(name, realm)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	return AddOn_Chomp.NameMergedRealm(name, realm)
end

function xrp.CharacterIDToName(characterID)
	if type(characterID) ~= "string" then
		return UNKNOWN
	end
	return characterID:match("^([^%-]+)")
end

-- Realms just needing title case spacing are handled via gsub. These are more
-- complex, such as lower case words or dashes.
local SPECIAL_REALMS = {
	-- English
	["AltarofStorms"] = "Altar of Storms",
	["AzjolNerub"] = "Azjol-Nerub",
	["ChamberofAspects"] = "Chamber of Aspects",
	["SistersofElune"] = "Sisters of Elune",
	-- French
	["Arakarahm"] = "Arak-arahm",
	["Chantséternels"] = "Chants éternels",
	["ConfrérieduThorium"] = "Confrérie du Thorium",
	["ConseildesOmbres"] = "Conseil des Ombres",
	["CultedelaRivenoire"] = "Culte de la Rive noire",
	["LaCroisadeécarlate"] = "La Croisade écarlate",
	["MarécagedeZangar"] = "Marécage de Zangar",
	["Templenoir"] = "Temple noir",
	-- German
	["DerabyssischeRat"] = "Der abyssische Rat",
	["DerRatvonDalaran"] = "Der Rat von Dalaran",
	["DieewigeWacht"] = "Die ewige Wacht",
	["FestungderStürme"] = "Festung der Stürme",
	["KultderVerdammten"] = "Kult der Verdammten",
	["ZirkeldesCenarius"] = "Zirkel des Cenarius",
	-- Russian
	["Борейскаятундра"] = "Борейская тундра",
	["ВечнаяПесня"] = "Вечная Песня",
	["Пиратскаябухта"] = "Пиратская бухта ",
	["ТкачСмерти"] = "Ткач Смерти",
	["Корольлич"] = "Король-лич",
	["Ревущийфьорд"] = "Ревущий фьорд",
	["Свежевательдуш"] = "Свежеватель душ",
	["СтражСмерти"] = "Страж Смерти",
	["ЧерныйШрам"] = "Черный Шрам",
	["Ясеневыйлес"] = "Ясеневый лес",
	-- Italian
	["Pozzodell'Eternità"] = "Pozzo dell'Eternità",
	-- Korean
	["불타는군단"] = "불타는 군단",
}

function xrp.RealmDisplayName(realm)
	if type(realm) ~= "string" then
		return UNKNOWN
	end
	-- gsub: spaces lower followed by upper/number (i.e., Wyrmrest Accord).
	return SPECIAL_REALMS[realm] or (realm:gsub("(%l)([%u%d])", "%1 %2"))
end

function xrp.Strip(text, allowIndent)
	if type(text) ~= "string" then
		return nil
	end
	if type(text) ~= "string" or text == "" then
		return nil
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

	if allowIndent then
		text = text:trim("\r\n"):match("^(.-)%s*$")
	else
		text = text:trim()
	end
	return text ~= "" and text or nil
end

function xrp.Link(text)
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

function xrp.MergeCurrently(CU, CO)
	if not CU and not CO then
		return nil
	elseif CU and not CO then
		return CU
	elseif not CU then
		return L.OOC_TEXT:format(CO:match(L.OOC_STRIP) or CO)
	elseif CU:find("\n", nil, true) or CO:find("\n", nil, true) then
		return ("%s\n\n%s"):format(CU, L.OOC_TEXT:format(CO:match(L.OOC_STRIP) or CO))
	end
	return ("%s %s"):format(CU, L.OOC_TEXT:format(CO:match(L.OOC_STRIP) or CO))
end

function xrp.Status(desiredStatus)
	if desiredStatus and type(desiredStatus) ~= "string" then
		desiredStatus = tostring(desiredStatus)
	end
	local profileStatus = xrp.profiles.SELECTED.fullFields.FC or "0"
	if not desiredStatus then
		local currentStatus = xrp.current.FC
		local currentIC, profileIC = currentStatus ~= nil and currentStatus ~= "1" and currentStatus ~= "0", profileStatus ~= nil and profileStatus ~= "1" and profileStatus ~= "0"
		desiredStatus = currentStatus ~= profileStatus and currentIC ~= profileIC and profileStatus or currentIC and "1" or "2"
	end
	if desiredStatus ~= profileStatus then
		xrp.current.FC = desiredStatus ~= "0" and desiredStatus or ""
	else
		xrp.current.FC = nil
	end
end
