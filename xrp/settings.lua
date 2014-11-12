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

local addonName, private = ...

local function InitSettingsTable(tableName, metaTable, initFunction)
end

local settingsToInit = {}

do
	local default_settings = {
		height = "ft",
		weight = "lb",
		cachetime = 864000, -- 10 days
		cachetidy = true,
	}
	function private:InitSettings()
		if not xrpCache then
			if type(xrp_cache) == "table" then
				xrpCache = xrp_cache
				xrp_cache = nil
			else
				xrpCache = {}
			end
		end
		if not xrpAccountSaved then
			if type(xrp_settings) == "table" then
				-- Pre-5.4.8.0_rc3.
				if type(xrp_settings.defaults == "table") then
					xrp_settings.defaults = nil
				end
				xrpAccountSaved = {
					settings = xrp_settings,
					dataVersion = 1,
				}
				xrp_settings = nil
			else
				xrpAccountSaved = {
					settings = {},
					dataVersion = 1,
				}
			end
		end
		if not xrpSaved then
			if type(xrp_profiles) == "table" then
				-- Pre-5.4.8.0_rc6.
				if type(xrp_defaults) == "table" then
					for profile, contents in pairs(xrp_profiles) do
						if type(contents) == "table" then
							xrp_profiles[profile] = {
								fields = contents,
								inherits = xrp_defaults[profile] or {},
								versions = {},
							}
						end
					end
					xrp_defaults = nil
				end
				xrpSaved = {
					auto = {},
					meta = {
						fields = {},
						versions = {},
					},
					overrides = {
						fields = {},
						versions = {},
					},
					profiles = xrp_profiles,
					selected = xrp_selectedprofile,
					versions = xrp_versions or {},
					--TODO
					dataVersion = 1,
				}
				for name, profile in pairs(xrpSaved.profiles) do
					if type(profile.versions) ~= "table" then
						profile.versions = {}
						for field, contents in pairs(profile.fields) do
							profile.versions[field] = private:NewVersion(field)
						end
					end
					if type(profile.inherits) ~= "table" then
						profile.inherits = profile.defaults or {}
						profile.defaults = nil
						if name ~= xrp.L["Default"] then
							profile.parent = xrp.L["Default"]
						end
					end
					if name == "Add" or name == "List" or name == "SELECTED" then
						xrpSaved.profiles[name.." Renamed"] = profile
						if xrpSaved.selected == name then
							xrpSaved.selected = name.." Renamed"
						end
						xrpSaved.profiles[name] = nil
					end
				end
				xrp_overrides = nil
				xrp_profiles = nil
				xrp_selectedprofile = nil
				xrp_versions = nil
			else
				xrpSaved = {
					auto = {},
					meta = {
						fields = {},
						versions = {},
					},
					overrides = {
						fields = {},
						versions = {},
					},
					profiles = {
						[xrp.L["Default"]] = {
							fields = {},
							inherits = {},
							versions = {},
						},
					},
					selected = xrp.L["Default"],
					versions = {},
					--TODO
					dataVersion = 1,
				}
			end
		end
		if xrpSaved.dataVersion < 2 then
			if type(xrpSaved.auto) ~= "table" then
				xrpSaved.auto = {}
			end
			--TODO
			--xrpSaved.dataVersion = 2
			--xrpAccountSaved.dataVersion = 1
		end

		xrp.settings = setmetatable(xrpAccountSaved.settings, { __index = default_settings })
	end
end

function xrp:RegisterSettings(tableName, metaTable, initFunction)
	assert(type(tableName) == "string" and type(metaTable) == "table" and type(initFunction) == "function", "Usage: xrp:RegisterSettings(\"tableName\", metaTable, initFunction)")
	if not metaTable.__index then
		metaTable = { __index = metaTable }
	end
	if not self.settings then
		settingsToInit[#settingsToInit + 1] = { tableName = tableName, metaTable = metaTable, initFunction = initFunction }
		return false
	end
	InitSettingsTable(tableName, metaTable, initFunction)
	return true
end

function private:CacheTidy(timer)
	if type(timer) ~= "number" or timer < 60 then
		timer = xrp.settings.cachetime
		if type(timer) ~= "number" or timer < 60 then
			return false
		end
	end
	local now = time()
	local before = now - timer
	for character, data in pairs(xrpCache) do
		if not data.lastreceive then
			data.lastreceive = now
		elseif not data.bookmark and data.lastreceive < before then
			if data.hide == nil then
				xrpCache[character] = nil
			else
				xrpCache[character].fields = {}
				xrpCache[character].versions = {}
				xrpCache[character].lastreceive = now
			end
		end
	end
	if timer <= 300 then
		-- Explicitly collect garbage, as there may be a hell of a lot of it
		-- (the user probably clicked "Clear Cache" in the options).
		collectgarbage()
	end
	return true
end
