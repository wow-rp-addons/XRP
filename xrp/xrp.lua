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

xrp = CreateFrame("Frame", nil, UIParent)

xrp.version = GetAddOnMetadata("xrp", "Version")
xrp.versionstring = format("%s/%s", GetAddOnMetadata("xrp", "Title"), xrp.version)

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

	units = (not units or units == "user") and xrp_settings.weight or units
	if units == "msp" then -- MSP internal format: kg without units as string.
		return format("%u", number + 0.5)
	elseif units == "kg" then
		return format("%u kg", number + 0.5)
	elseif units == "lb" then
		return format("%u lbs", (number * 2.20462) + 0.5)
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

	units = (not units or units == "user") and xrp_settings.height or units
	if units == "msp" then -- MSP internal format: cm without units as string.
		return format("%d", number)
	elseif units == "cm" then
		return format("%u cm", number + 0.5)
	elseif units == "m" then
		return format("%.2f m", math.floor(number + 0.5) * 0.01) -- Round first.
	elseif units == "ft" then
		local feet, inches = math.modf(number / 30.48)
		inches = (inches * 12) + 0.5
		return format("%u'%u\"", feet, inches)
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
	events[event][#events[event]+1] = func
end

local function loadifneeded(addon)
	local isloaded = IsAddOnLoaded(addon)
	if not isloaded and IsAddOnLoadOnDemand(addon) then
		local loaded, reason = LoadAddOn(addon)
		if not loaded then
			return false
		else
			return true
		end
	end
	return isloaded
end

function xrp:ToggleEditor()
	if not loadifneeded("xrp_editor") then
		return
	end
	ToggleFrame(xrp.editor)
end

function xrp:ToggleViewer()
	if not loadifneeded("xrp_viewer") then
		return
	end
	ToggleFrame(xrp.viewer)
end

function xrp:ShowViewerCharacter(character)
	if not loadifneeded("xrp_viewer") then
		return
	end
	xrp.viewer:ViewCharacter(character)
end

function xrp:ShowViewerUnit(unit)
	if not loadifneeded("xrp_viewer") then
		return
	end
	xrp.viewer:ViewUnit(unit)
end
