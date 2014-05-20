--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

local L = xrp.L

function xrp:UnitNameWithRealm(unit)
	local name, realm = UnitName(unit)
	if not name then
		return nil
	end
	local isplayer = UnitIsPlayer(unit)
	if (realm == nil or realm == "") and isplayer then
		return FULL_PLAYER_NAME:format(name, GetRealmName():gsub("%s+", ""))
	elseif realm and isplayer then
		return FULL_PLAYER_NAME:format(name, realm)
	end
	return name
end

function xrp:NameWithRealm(name, realm)
	if name:find("-", 1, true) then
		-- Searching for a '-' will indicate if it already has a realm name.
		return name
	elseif realm and realm ~= "" then
		-- If a realm was provided, use it (after stripping spaces).
		return FULL_PLAYER_NAME:format(name, (realm:gsub("%s+", "")))
	end
	-- Fall back to using our own realm (after stripping spaces).
	return FULL_PLAYER_NAME:format(name, (GetRealmName():gsub("%s+", "")))
end

-- Dumb version of Ambiguate() which always strips.
function xrp:NameWithoutRealm(name)
	if type(name) ~= "string" then
		return UNKNOWN
	end
	return name:match(FULL_PLAYER_NAME:format("(.+)", ".+")) or name
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
		number = ((tonumber((weight:lower():gsub("%a*(%d+)%s*lb.*", "%1"))) or tonumber((weight:lower():gsub("%a*(%d+)%s*pounds?.*", "%1")))) or 0) / 2.20462
		number = number ~= 0 and number or nil
	end
	if not number then
		return weight
	end

	units = (not units or units == "user") and xrp_settings.weight or units
	if units == "msp" then -- MSP internal format: kg without units as string.
		return format(L["%u"], number + 0.5)
	elseif units == "kg" then
		return format(L["%u kg"], number + 0.5)
	elseif units == "lb" then
		return format(L["%u lbs"], (number * 2.20462) + 0.5)
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
		number = (((tonumber((height:lower():gsub("%a*(%d+)'%d*.*", "%1"))) or tonumber((height:lower():gsub("%a*(%d+)%s*ft.*", "%1"))) or 0) * 12) + (tonumber((height:lower():gsub("%a*%d+'(%d*).*", "%1"))) or tonumber((height:lower():gsub("%a*%d+%s*ft%.?%s*(%d+)%s*in.*", "%1"))) or 0)) * 2.54
		number = number ~= 0 and number or nil
	end
	if not number then
		return height
	end

	units = (not units or units == "user") and xrp_settings.height or units
	if units == "msp" then -- MSP internal format: cm without units as string.
		return format("%d", number)
	elseif units == "cm" then
		return format(L["%u cm"], number + 0.5)
	elseif units == "m" then
		return format(L["%.2f m"], math.floor(number + 0.5) * 0.01) -- Round first.
	elseif units == "ft" then
		local feet, inches = math.modf(number / 30.48)
		inches = (inches * 12) + 0.5
		if inches >= 12 then
			feet = feet + 1
			inches = 0
		end
		return format(L["%u'%u\""], feet, inches)
	else
		return height
	end
end

StaticPopupDialogs["XRP_CACHE_CLEAR"] = {
	text = L["Are you sure you wish to empty the profile cache?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		xrp:CacheTidy(60)
		StaticPopup_Show("XRP_CACHE_CLEARED")
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_CACHE_CLEARED"] = {
	text = L["The cache has been cleared."],
	button1 = OKAY,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["XRP_CACHE_TIDIED"] = {
	text = L["The cache has been tidied."],
	button1 = OKAY,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function xrp:CacheTidy(timer)
	if type(timer) ~= "number" or timer <= 0 then
		timer = xrp_settings.cachetime
	end
	if not timer then return false end
	local now = time()
	local before = now - timer
	for character, data in pairs(xrp_cache) do
		if not data.lastreceive then
			-- Pre-beta5 didn't have this value. Might be able to be dropped
			-- at some point in the distant future (or just left as a
			-- safeguard).
			data.lastreceive = now
		elseif data.lastreceive < before then
			xrp_cache[character] = nil
		end
	end
	-- Explicitly collect garbage, as there may be a hell of a lot of it.
	collectgarbage()
	return true
end

local events = {}

function xrp:FireEvent(event, ...)
	if type(events[event]) ~= "table" then
		events[event] = {}
	end
	for _, func in ipairs(events[event]) do
		func(...)
	end
end

function xrp:HookEvent(event, func)
	if type(events[event]) ~= "table" then
		events[event] = {}
	end
	events[event][#events[event]+1] = func
end
