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

xrp = {
	translation = {},
	version = GetAddOnMetadata("xrp", "Version"),
}

do
	local locale = GetLocale()
	local translation = xrp.translation
	xrp.L = setmetatable({}, {
		__index = function(self, key)
			return translation[locale] and translation[locale][key] or key
		end,
		__newindex = function()
		end,
		__metatable = false,
	})
end

do
	local events = {}

	function xrp:FireEvent(event, ...)
		if type(events[event]) ~= "table" then
			return false
		end
		for _, func in ipairs(events[event]) do
			func(...)
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
			func()
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
			func()
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

	local function xrp_CompareVersion(new_version, old_version)
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

	function xrp:UpdateVersion(version)
		if not version or version == self.version or version == self.settings.newversion then return end
		if xrp_CompareVersion(version, self.settings.newversion or self.version) >= 0 then
			self.settings.newversion = version
		end
	end

	local init = CreateFrame("Frame")
	local addons = {
		"GHI",
		"Tongues",
	}
	local addonstring = "%s/%s"
	init:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == "xrp" then
			local fullversion = addonstring:format(GetAddOnMetadata("xrp", "Title"), xrp.version)
			for _, addon in ipairs(addons) do
				local name, title, notes, enabled, loadable, reason = GetAddOnInfo(addon)
				if enabled or loadable then
					fullversion = fullversion..";"..addonstring:format(name, GetAddOnMetadata(name, "Version"))
				end
			end

			local name = UnitName("player")
			xrp.toon = {
				name = name,
				withrealm = xrp:NameWithRealm(name),
				fields = {
					VA = fullversion,
					VP = tostring(xrp.msp),
				},
			}

			for _, func in ipairs(onload) do
				func()
			end
			onload = nil

			self:UnregisterEvent("ADDON_LOADED")
			self:RegisterEvent("PLAYER_LOGIN")
		elseif event == "PLAYER_LOGIN" then
			local fields = xrp.toon.fields
			fields.GC = select(2, UnitClass("player"))
			fields.GF = UnitFactionGroup("player")
			fields.GR = select(2, UnitRace("player"))
			fields.GS = tostring(UnitSex("player"))
			fields.GU = UnitGUID("player")
			xrp:Update()

			if xrp.settings.cachetidy then
				xrp:CacheTidy()
			end

			if xrp.settings.newversion then
				local update = xrp_CompareVersion(xrp.settings.newversion, xrp.version)
				local now = time()
				if update == 1 and (not xrp.settings.versionwarning or xrp.settings.versionwarning < now - 86400) then
					local timer = 0
					self:SetScript("OnUpdate", function(self, elapsed)
						timer = timer + elapsed
						if timer > 8 then
							print(xrp.L["There is a new version of |cffabd473XRP|r available. You should update to %s as soon as possible."]:format(xrp.settings.newversion))
							xrp.settings.versionwarning = now
							self:SetScript("OnUpdate", nil)
						end
					end)
				elseif update == -1 then
					xrp.settings.newversion = nil
					xrp.settings.versionwarning = nil
				end
			end

			for _, func in ipairs(onlogin) do
				func()
			end
			onlogin = nil

			self:UnregisterEvent("PLAYER_LOGIN")
			if fields.GF == "Neutral" then
				self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
			end
			self:RegisterEvent("PLAYER_LOGOUT")
		elseif event == "PLAYER_LOGOUT" then
			for _, func in ipairs(onlogout) do
				func()
			end
		elseif event == "NEUTRAL_FACTION_SELECT_RESULT" then
			xrp.toon.fields.GF = UnitFactionGroup("player")
			xrp:UpdateField("GF")
			self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		end
	end)
	init:RegisterEvent("ADDON_LOADED")
end

do
	local default_settings = {
		height = "ft",
		weight = "lb",
		minimap = 225,
		cachetime = 864000, -- 10 days
		cachetidy = true,
		hideminimaptt = false,
		minimapdetached = false,
		minimapx = 0,
		minimapy = 0,
		minimappoint = "CENTER",
	}
	xrp:HookLoad(function()
		-- Account-wide.
		if type(xrp_settings) ~= "table" then
			xrp_settings = {}
		end
		if type(xrp_cache) ~= "table" then
			xrp_cache = {}
		end

		-- Character-specific.
		if type(xrp_overrides) ~= "table" then
			xrp_overrides = {}
		end
		if type(xrp_profiles) ~= "table" then
			xrp_profiles = {}
		end
		if type(xrp_versions) ~= "table" then
			xrp_versions = {}
		end

		-- Pre-5.4.8.0_rc6.
		if xrp_defaults ~= nil then
			for profile, contents in pairs(xrp_profiles) do
				if type(contents) == "table" then
					xrp_profiles[profile] = {
						fields = contents,
						defaults = xrp_defaults[profile] or {},
					}
				end
			end
			xrp_defaults = nil
		end

		do
			local L = xrp.L
			if type(xrp_profiles[L["Default"]]) ~= "table" then
				xrp_profiles[L["Default"]] = {
					fields = {},
				}
			end
			if type(xrp_profiles[L["Default"]].fields.NA) ~= "string" then
				xrp_profiles[L["Default"]].fields.NA = xrp.toon.name
			end
			if type(xrp_selectedprofile) ~= "string" or type(xrp_profiles[xrp_selectedprofile]) ~= "table" then
				xrp_selectedprofile = L["Default"]
			end
		end

		if type(xrp_cache[xrp.toon.withrealm]) ~= "table" then
			xrp_cache[xrp.toon.withrealm] = {
				fields = {},
				versions = {},
			}
		end

		xrp.settings = setmetatable(xrp_settings, { __index = default_settings })
		-- Pre-5.4.8.0_rc3.
		if type(xrp.settings.defaults == "table") then
			xrp.settings.defaults = nil
		end
	end)
end

function xrp:CacheTidy(timer)
	if type(timer) ~= "number" or timer < 60 then
		timer = xrp.settings.cachetime
		if type(timer) ~= "number" or timer < 60 then
			return false
		end
	end
	local now = time()
	local before = now - timer
	for character, data in pairs(xrp_cache) do
		if not data.lastreceive then
			-- Pre-5.4.8.0_beta5.
			data.lastreceive = now
		elseif data.lastreceive < before then
			xrp_cache[character] = nil
		end
	end
	-- Explicitly collect garbage, as there may be a hell of a lot of it.
	collectgarbage()
	return true
end

-- This is kinda terrifying, but it fixes some major UI tainting when the user
-- presses "Cancel" in the Interface Options (out of combat). The drawback is
-- that any changes made to the default compact raid frames aren't actually
-- cancelled (they're not saved, but they're still active). Still, this is
-- better than having the Cancel button completely taint the raid frames.
function CompactUnitFrameProfiles_CancelChanges(self)
	InterfaceOptionsPanel_Cancel(self)

	-- The following is disabled to make it more obvious that changes aren't
	-- really cancelled.
	--RestoreRaidProfileFromCopy()

	CompactUnitFrameProfiles_UpdateCurrentPanel()

	-- The following is disabled because it's the actual function that taints
	-- everything. The execution path is tainted by the time this function is
	-- called if there's any addon with an Interface Options panel.
	--CompactUnitFrameProfiles_ApplyCurrentSettings()
end

local L = xrp.L
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
	text = L["Old entries have been pruned from the cache."],
	button1 = OKAY,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
