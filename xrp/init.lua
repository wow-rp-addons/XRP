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

xrp:SetScript("OnEvent", function(xrp, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp" then
		xrp.toon = {}
		xrp.toon.withrealm = xrp:UnitNameWithRealm("player")
		xrp.toon.name = xrp:NameWithoutRealm(xrp.toon.withrealm)
		xrp.toon.fields = { -- NONE of these are localized.
			GC = (select(2, UnitClass("player"))),
			GF = (UnitFactionGroup("player")),
			GR = (select(2, UnitRace("player"))),
			GS = tostring(UnitSex("player")),
			GU = UnitGUID("player"),
			VA = xrp.versionstring,
			VP = tostring(xrp.msp.protocol),
		}

		-- TODO: Convert to metatables for defaults.
		if type(xrp_settings) ~= "table" then
			xrp_settings = {
				height = "cm",
				weight = "kg",
				loglevel = 6,
			}
		end

		if type(xrp_profiles) ~= "table" then
			xrp_profiles = {
				Default = {
					NA = xrp.toon.name,
					RA = xrp.toon.race,
				},
			}
		end

		if type(xrp_profiles.Default) ~= "table" then
			xrp_profiles.Default = {
				NA = xrp.toon.name,
				RA = xrp.toon.race,
			}
		end

		if type(xrp_selectedprofile) ~= "string" or type(xrp_profiles[xrp_selectedprofile]) ~= "table" then
			xrp_selectedprofile = "Default"
		end

		if type(xrp_cache) ~= "table" then
			xrp_cache = {}
		end

		if not xrp_cache[xrp.toon.withrealm] then
			xrp_cache[xrp.toon.withrealm] = {
				fields = {},
				time = {},
				versions = {},
			}
		end

		xrp:UnregisterEvent("ADDON_LOADED")
		xrp:RegisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_LOGIN" then
		xrp.profiles(xrp_selectedprofile)
		xrp:UnregisterEvent("PLAYER_LOGIN")
	end
end)
xrp:RegisterEvent("ADDON_LOADED")
