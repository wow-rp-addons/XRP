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

xrp = {
	translation = {},
	version = GetAddOnMetadata(addonName, "Version"),
}

do
	local locale = GetLocale()
	local translation = xrp.translation
	xrp.L = setmetatable({}, {
		__index = function(self, key)
			return translation[locale] and translation[locale][key] or key
		end,
		__newindex = function() end,
		__metatable = false,
	})
end

do
	local events = {}

	function private:FireEvent(event, ...)
		if type(events[event]) ~= "table" then
			return false
		end
		for _, func in ipairs(events[event]) do
			pcall(func, ...)
		end
		return true
	end

	function xrp:HookEvent(event, func)
		if type(func) ~= "function" then
			return false
		elseif type(events[event]) ~= "table" then
			events[event] = {}
		end
		events[event][#events[event] + 1] = func
		return true
	end
end

do
	local onload = {}
	function xrp:HookLoad(func)
		if type(func) ~= "function" then
			return false
		elseif not onload then
			pcall(func)
		else
			onload[#onload + 1] = func
		end
		return true
	end

	local onlogin = {}
	function xrp:HookLogin(func)
		if type(func) ~= "function" then
			return false
		elseif not onlogin then
			pcall(func)
		else
			onlogin[#onlogin + 1] = func
		end
		return true
	end

	local onlogout = {}
	function xrp:HookLogout(func)
		if type(func) ~= "function" then
			return false
		else
			onlogout[#onlogout + 1] = func
		end
		return true
	end

	local function CompareVersion(new_version, old_version)
		local new_major, new_minor, new_patch, new_rev, new_addon, new_reltype, new_relrev = new_version:match("(%d+)%.(%d+)%.(%d+)(%l?)%.(%d+)%_?(%l*)(%d*)")
		local old_major, old_minor, old_patch, old_rev, old_addon, old_reltype, old_relrev = old_version:match("(%d+)%.(%d+)%.(%d+)(%l?)%.(%d+)%_?(%l*)(%d*)")

		new_reltype = (new_reltype == "alpha" and 1) or (new_reltype == "beta" and 2) or (new_reltype == "rc" and 3) or 4
		old_reltype = (old_reltype == "alpha" and 1) or (old_reltype == "beta" and 2) or (old_reltype == "rc" and 3) or 4

		local new_wow = (tonumber(new_major) * 1000000) + (tonumber(new_minor) * 10000) + (tonumber(new_patch) * 100) + ((new_rev and new_rev:lower():byte() or 96) - 96)
		local old_wow = (tonumber(old_major) * 1000000) + (tonumber(old_minor) * 10000) + (tonumber(old_patch) * 100) + ((old_rev and old_rev:lower():byte() or 96) - 96)

		if new_wow < old_wow then
			return -1
		elseif new_reltype < old_reltype and new_wow > old_wow then
			return 0
		elseif new_wow > old_wow then
			return 1
		end

		local new_xrp = (tonumber(new_addon) * 10000) + (new_reltype * 100) + (tonumber(new_relrev) or 0)
		local old_xrp = (tonumber(old_addon) * 10000) + (old_reltype * 100) + (tonumber(old_relrev) or 0)

		if new_xrp <= old_xrp then
			return -1
		elseif new_reltype < old_reltype and new_xrp > old_xrp then
			return 0
		else
			return 1
		end
	end

	function private:AddonUpdate(version)
		if not version or version == xrp.version or version == xrp.settings.newversion then return end
		if CompareVersion(version, xrp.settings.newversion or xrp.version) >= 0 then
			xrp.settings.newversion = version
		end
	end

	local init = CreateFrame("Frame")
	local addons = {
		"GHI",
		"Tongues",
	}
	local addonstring = "%s/%s"
	init:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == addonName then
			xrp.toon = xrp:UnitNameWithRealm("player")

			for _, func in ipairs(onload) do
				pcall(func, "LOADED")
			end
			onload = nil

			self:UnregisterEvent("ADDON_LOADED")
			self:RegisterEvent("PLAYER_LOGIN")
		elseif event == "PLAYER_LOGIN" then
			local newfields
			do
				local fullversion = addonstring:format(GetAddOnMetadata(addonName, "Title"), xrp.version)
				for _, addon in ipairs(addons) do
					local name, title, notes, enabled, reason, secure, loadable = GetAddOnInfo(addon)
					if enabled or loadable then
						fullversion = fullversion..";"..addonstring:format(name, GetAddOnMetadata(name, "Version"))
					end
				end
				newfields = {
					GC = select(2, UnitClassBase("player")),
					GF = UnitFactionGroup("player"),
					GR = select(2, UnitRace("player")),
					GS = tostring(UnitSex("player")),
					GU = UnitGUID("player"),
					NA = UnitName("player"), -- Fallback NA field.
					VA = fullversion,
				}
			end
			local fields, versions = xrpSaved.meta.fields, xrpSaved.meta.versions
			for field, contents in pairs(newfields) do
				if contents ~= fields[field] then
					fields[field] = contents
					versions[field] = private:NewVersion(field)
				end
			end
			fields.VP = tostring(private.msp)
			versions.VP = private.msp

			if xrp.settings.cachetidy then
				private:CacheTidy()
			end

			if xrp.settings.newversion then
				local update = CompareVersion(xrp.settings.newversion, xrp.version)
				local now = time()
				if update == 1 and (not xrp.settings.versionwarning or xrp.settings.versionwarning < now - 21600) then
					C_Timer.After(8, function()
						print(xrp.L["There is a new version of |cffabd473XRP|r available. You should update to %s as soon as possible."]:format(xrp.settings.newversion))
						xrp.settings.versionwarning = now
					end)
				elseif update == -1 then
					xrp.settings.newversion = nil
					xrp.settings.versionwarning = nil
				end
			end

			for _, func in ipairs(onlogin) do
				pcall(func, "LOGIN")
			end
			onlogin = nil

			self:UnregisterEvent("PLAYER_LOGIN")
			if fields.GF == "Neutral" then
				self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
			end
			self:RegisterEvent("PLAYER_LOGOUT")
		elseif event == "PLAYER_LOGOUT" then
			-- Note: This code must be thoroughly tested if any changes are
			-- made. If there are any errors in here, they are not visible in
			-- any manner in-game.
			do
				local current = xrp.current
				local fields, versions = current:List(), {}
				for field, _ in pairs(fields) do
					versions[field] = current.versions[field]
				end
				xrpCache[xrp.toon] = {
					fields = fields,
					versions = versions,
					own = true,
					lastreceive = time(),
				}
			end
			for _, func in ipairs(onlogout) do
				pcall(func, "LOGOUT")
			end
		elseif event == "NEUTRAL_FACTION_SELECT_RESULT" then
			xrpSaved.meta.fields.GF = UnitFactionGroup("player")
			xrpSaved.meta.versions.GF = private:NewVersion("GF")
			private:FireEvent("FIELD_UPDATE", "GF")
			self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		end
	end)
	init:RegisterEvent("ADDON_LOADED")
end

do
	local default_settings = {
		height = "ft",
		weight = "lb",
		cachetime = 864000, -- 10 days
		cachetidy = true,
	}
	xrp:HookLoad(function()
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
	end)
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
