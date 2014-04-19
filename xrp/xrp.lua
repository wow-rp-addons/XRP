--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this program.  If not, see
	<http://www.gnu.org/licenses/>.
]]

xrp = CreateFrame("Frame")

xrp.version = GetAddOnMetadata("xrp", "Version")
xrp.versionstring = format("%s/%s", GetAddOnMetadata("xrp", "Title"), xrp.version)

function xrp:Debug(priority, message)
	if priority >= 5 and priority <= xrp.settings.loglevel then -- Debug.
		DEFAULT_CHAT_FRAME:AddMessage(format("|cFFABD473xrp: |cFF0000FF(DEBUG) |r%s", message))
	elseif priority == 1 and priority <= xrp.settings.debug then -- Critical.
		DEFAULT_CHAT_FRAME:AddMessage(format("|cFFABD473xrp:: |cFFFF0000(CRITICAL) |r%s", message))
	elseif priority == 2 and priority <= xrp.settings.debug then -- Errors.
		DEFAULT_CHAT_FRAME:AddMessage(format("|cFFABD473xrp: |cFFFF3333(ERROR) |r%s", message))
	elseif priority == 3 and priority <= xrp.settings.debug then -- Warnings.
		DEFAULT_CHAT_FRAME:AddMessage(format("|cFFABD473xrp: |cFFFFA500(WARNING) |r%s", message))
	elseif priority == 4 and priority <= xrp.settings.loglevel then -- Informational.
		DEFAULT_CHAT_FRAME:AddMessage(format("|cFFABD473xrp: |r%s", message))
	end
end

function xrp:UnitNameWithRealm(unit)
	local name, realm = UnitName(unit)
	local isplayer = UnitIsPlayer(unit)
	if name ~= nil then
		if (realm == nil or realm == "") and isplayer then
			return format("%s-%s", name, GetRealmName():gsub("%s+", ""))
		elseif realm and isplayer then
			return format("%s-%s", name, realm)
		else
			return name
		end
	end
	return nil
end

function xrp:NameWithRealm(name)
	-- Searching for a '-' will indicate if it already has a realm name. '-'
	-- is not valid in a base name.
	return not name:find("-", 1, true) and format("%s-%s", name, (GetRealmName():gsub("%s+", ""))) or name
end

-- Dumb version of Ambiguate().
function xrp:NameWithoutRealm(name)
	if type(name) ~= "string" then
		return UNKNOWN
	end
	return (name:gsub("-.+", ""))
end

function xrp:RealmNameWithSpacing(name)
	-- First gsub: spaces lower followed by upper (i.e., Wyrmrest Accord).
	-- Second gsub: spaces lower followed by digit (i.e., Area 52).
	-- Third gsub: spaces lower followed by 'of' (i.e., Sisters of Elune).
	return (name:gsub("(%l)(%u)", "%1 %2"):gsub("(%l)(%d)", "%1 %2"):gsub("(%l)of ", "%1 of "))
end

function xrp:ConvertWeight(weight, units)
	if not weight then
		return nil
	end
	local number = tonumber(weight)
	if not number then
		-- Match "50kg", "50 kg", "50 kilograms", etc..
		number = tonumber((weight:lower():gsub("%a*(%d+)%s*kg.*", "%1"))) or tonumber((weight:lower():gsub("%a*(%d+)%s*kilograms?.*", "%1")))
	end
	if not number then
		-- Match "50lbs", "50 lbs", "50 pounds", etc.
		-- TODO: Should this handle insane corner cases, i.e. "Ib"/"Ibs"?
		number = ((tonumber((weight:lower():gsub("%a*(%d+)%s*lb.*", "%1"))) or tonumber((weight:lower():gsub("%a*(%d+)%s*pounds?.*", "%1")))) or 0) / 2.20462
		number = number ~= 0 and number or nil
	end
	if not number then
		return weight
	end

	units = (not units or units == "user") and xrp.settings.weight or units
	if units == "msp" then -- MSP internal format: kg without units as string.
		return format("%d", math.floor(number + 0.5))
	elseif units == "kg" then
		return format("%d kg", math.floor(number + 0.5))
	elseif units == "lb" then
		return format("%d lbs", math.floor((number * 2.20462) + 0.5))
	else
		return weight -- If no unit conversion requested, pass through.
	end
end

function xrp:ConvertHeight(height, units)
	if not height then
		return nil
	end
	local number = tonumber(height)
	if number and number <= 10 then
		number = number * 100
	end
	if not number then
		-- Match "100cm", "100 cm", "100 centimeters", "100 centimetres", etc.
		number = tonumber((height:lower():gsub("%a*(%d+)%s*cm.*", "%1"))) or tonumber((height:lower():gsub("%a*(%d+)%s*centimetr?er?s?.*", "%1")))
	end
	if not number then
		-- Match "1.05m", "1.05 m", "1.05 meters", "1.05 metres" etc..
		number = ((tonumber((height:lower():gsub("%a*(%d+%.?%d*)%s*m.*", "%1"))) or tonumber((height:lower():gsub("%a*(%d+%.?%d*)%s*metr?er?s?.*", "%1")))) or 0) * 100
		number = number ~= 0 and number or nil
	end
	if not number then
		-- Match "4'9", "4'9"", "4 ft 9 in", etc.
		-- TODO: weight:match() may be a quicker way to get this.
		number = (((tonumber((height:lower():gsub("%a*(%d+)'%d*.*", "%1"))) or tonumber((height:lower():gsub("%a*(%d+)%s*ft.*", "%1"))) or 0) * 12) + (tonumber((height:lower():gsub("%a*%d+'(%d*).*", "%1"))) or tonumber((height:lower():gsub("%a*%d+%s*ft%.?%s*(%d+)%s*in.*", "%1"))) or 0)) * 2.54
		number = number ~= 0 and number or nil
	end
	if not number then
		return height
	end

	units = (not units or units == "user") and xrp.settings.height or units
	if units == "msp" then -- MSP internal format: cm without units as string.
		return format("%d", number)
	elseif units == "cm" then
		return format("%d cm", math.floor(number + 0.5))
	elseif units == "m" then
		return format("%.2f m", math.floor(number + 0.5) * 0.01) -- Round first.
	elseif units == "ft" then
		local inches = math.floor((number / 2.54) + 0.5)
		local feet = math.floor(inches / 12)
		return format("%d'%d\"", feet, inches - (feet * 12))
	else
		return height
	end
end

local events = {}

function xrp:FireEvent(event, ...)
	if type(events[event]) ~= "table" then
		events[event] = {}
	end
	-- TODO: Add in event as argument at start?
	for _, func in ipairs(events[event]) do
		func(...)
	end
end

function xrp:HookEvent(event, func)
	if type(events[event]) ~= "table" then
		events[event] = {}
	end
--	table.insert(events[event], func)
	events[event][#events[event]+1] = func
end
