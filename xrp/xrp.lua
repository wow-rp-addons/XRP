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
	local loaded = false
	local onload = {}
	function xrp:HookLoad(func)
		if type(func) ~= "function" then
			return false
		elseif loaded then
			func()
		else
			onload[#onload + 1] = func
		end
		return true
	end

	local onunload = {}
	function xrp:HookUnload(func)
		if type(func) ~= "function" then
			return false
		else
			onunload[#onunload + 1] = func
		end
		return true
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
					VP = tostring(xrp.msp.protocol),
				},
			}

			for _, func in ipairs(onload) do
				func()
			end
			onload = nil
			loaded = true

			self:UnregisterEvent("ADDON_LOADED")
			self:RegisterEvent("PLAYER_LOGIN")
		elseif event == "PLAYER_LOGIN" then
			local fields = xrp.toon.fields
			fields.GC = select(2, UnitClass("player"))
			fields.GF = UnitFactionGroup("player")
			fields.GR = select(2, UnitRace("player"))
			fields.GS = tostring(UnitSex("player"))
			fields.GU = UnitGUID("player")
			xrp.msp:Update()

			if xrp.settings.cachetidy then
				xrp:CacheTidy()
			end

			self:UnregisterEvent("PLAYER_LOGIN")
			if fields.GF == "Neutral" then
				self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
			end
			self:RegisterEvent("PLAYER_LOGOUT")
		elseif event == "PLAYER_LOGOUT" then
			for _, func in ipairs(onunload) do
				func()
			end
		elseif event == "NEUTRAL_FACTION_SELECT_RESULT" then
			xrp.toon.fields.GF = UnitFactionGroup("player")
			xrp.msp:UpdateField("GF")
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
		cachetime = 604800, -- 7 days
		cachetidy = true,
	}
	xrp:HookLoad(function()
		for _, t in ipairs({ "xrp_settings", "xrp_cache", "xrp_defaults", "xrp_overrides", "xrp_profiles", "xrp_versions" }) do
			if type(_G[t]) ~= "table" then
				_G[t] = {}
			end
		end

		do
			local L = xrp.L
			if type(xrp_profiles[L["Default"]]) ~= "table" then
				xrp_profiles[L["Default"]] = {}
			end
			if type(xrp_profiles[L["Default"]].NA) ~= "string" then
				xrp_profiles[L["Default"]].NA = xrp.toon.name
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
		setmetatable(xrp.settings.defaults, { __index = function() return true end })
	end)
end

function xrp:CacheTidy(timer)
	if type(timer) ~= "number" or timer < 60 then
		timer = xrp.settings.cachetime
	end
	if not timer or type(timer) ~= "number" or timer < 60 then
		return false
	end
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

-- This is kinda terrifying, but it fixes some major UI tainting when the user
-- presses "Cancel" in the Interface Options (out of combat). The drawback is
-- that any changes made aren't actually cancelled (they're not saved, but
-- they're still active). Still, this is better than having the Cancel button
-- completely taint the raid frames.
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
	text = L["The cache has been tidied."],
	button1 = OKAY,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
