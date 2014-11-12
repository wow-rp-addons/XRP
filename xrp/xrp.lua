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
	toon = xrp:UnitNameWithRealm("player"),
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
			pcall(func, "LOADED")
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
			pcall(func, "LOGIN")
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

	local function CompareVersion(newVersion, oldVersion)
		local newMajor, newMinor, newPatch, newRev, newAddOn, newRelType, newRelRev = newVersion:match("(%d+)%.(%d+)%.(%d+)(%l?)%.(%d+)%_?(%l*)(%d*)")
		local oldMajor, oldMinor, oldPatch, oldRev, oldAddOn, oldRelType, oldRelRev = oldVersion:match("(%d+)%.(%d+)%.(%d+)(%l?)%.(%d+)%_?(%l*)(%d*)")

		newRelType = (newRelType == "alpha" and 1) or (newRelType == "beta" and 2) or (newRelType == "rc" and 3) or 4
		oldRelType = (oldRelType == "alpha" and 1) or (oldRelType == "beta" and 2) or (oldRelType == "rc" and 3) or 4

		local newWoW = (tonumber(newMajor) * 1000000) + (tonumber(newMinor) * 10000) + (tonumber(newPatch) * 100) + ((newRev and newRev:lower():byte() or 96) - 96)
		local oldWoW = (tonumber(oldMajor) * 1000000) + (tonumber(oldMinor) * 10000) + (tonumber(oldPatch) * 100) + ((oldRev and oldRev:lower():byte() or 96) - 96)

		if newWoW < oldWoW then
			return -1
		elseif newRelType < oldRelType and newWoW > oldWoW then
			return 0
		elseif newWoW > oldWoW then
			return 1
		end

		local newXRP = (tonumber(newAddOn) * 10000) + (newRelType * 100) + (tonumber(newRelRev) or 0)
		local oldXRP = (tonumber(oldAddOn) * 10000) + (oldRelType * 100) + (tonumber(oldRelRev) or 0)

		if newXRP <= oldXRP then
			return -1
		elseif newRelType < oldRelType and newXRP > oldXRP then
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
	init:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == addonName then
			private:InitSettings()

			local newfields
			do
				local addonString = "%s/%s"
				local fullVA = addonString:format(GetAddOnMetadata(addonName, "Title"), xrp.version)
				for _, addon in ipairs(addons) do
					local name, title, notes, enabled, reason, secure, loadable = GetAddOnInfo(addon)
					if enabled or loadable then
						fullVA = fullVA..";"..addonString:format(name, GetAddOnMetadata(name, "Version"))
					end
				end
				newfields = {
					GC = select(2, UnitClassBase("player")),
					GF = UnitFactionGroup("player"),
					GR = select(2, UnitRace("player")),
					GS = tostring(UnitSex("player")),
					GU = UnitGUID("player"),
					NA = UnitName("player"), -- Fallback NA field.
					VA = fullVA,
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

			for _, func in ipairs(onload) do
				pcall(func, "LOADED")
			end
			onload = nil

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

			self:UnregisterEvent("ADDON_LOADED")
			if fields.GF == "Neutral" then
				self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
			end
			self:RegisterEvent("PLAYER_LOGIN")
		elseif event == "PLAYER_LOGIN" then
			for _, func in ipairs(onlogin) do
				pcall(func, "LOGIN")
			end
			onlogin = nil

			self:UnregisterEvent("PLAYER_LOGIN")
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
