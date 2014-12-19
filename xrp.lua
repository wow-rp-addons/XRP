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

local addonName, xrpPrivate = ...

xrp = {
	values = {
		GC = {
			DEATHKNIGHT = "Death Knight",
			DRUID = "Druid",
			HUNTER = "Hunter",
			MAGE = "Mage",
			MONK = "Monk",
			PALADIN = "Paladin",
			PRIEST = "Priest",
			ROGUE = "Rogue",
			SHAMAN = "Shaman",
			WARLOCK = "Warlock",
			WARRIOR = "Warrior",
		},
		GR = {
			Dwarf = "Dwarf",
			Draenei = "Draenei",
			Gnome = "Gnome",
			Human = "Human",
			NightElf = "Night Elf",
			Worgen = "Worgen",
			BloodElf = "Blood Elf",
			Goblin = "Goblin",
			Orc = "Orc",
			Scourge = "Undead", -- Yes, Scourge.
			Tauren = "Tauren",
			Troll = "Troll",
			Pandaren = "Pandaren",
		},
		GS = {
			["1"] = "Unknown",
			["2"] = "Male",
			["3"] = "Female",
		},
		FR = {
			["0"] = "(None)",
			["1"] = "Normal roleplayer",
			["2"] = "Casual roleplayer",
			["3"] = "Full-time roleplayer",
			["4"] = "Beginner roleplayer",
			["5"] = "Mature roleplayer", -- This isn't standard (?) but is used sometimes.
		},
		FC = {
			["0"] = "(None)",
			["1"] = "Out of character",
			["2"] = "In character",
			["3"] = "Looking for contact",
			["4"] = "Storyteller",
		},
	},
}

-- Global strings for keybinds.
BINDING_HEADER_XRP = "XRP"
BINDING_NAME_XRP_EDITOR = "Open/close RP profile editor"
BINDING_NAME_XRP_VIEWER = "View target's or mouseover's RP profile"
BINDING_NAME_XRP_VIEWER_TARGET = "View target's RP profile"
BINDING_NAME_XRP_VIEWER_MOUSEOVER = "View mouseover's RP profile"

xrpPrivate.version = GetAddOnMetadata(addonName, "Version")

do
	local events = {}

	function xrpPrivate:FireEvent(event, ...)
		if type(events[event]) ~= "table" then
			return false
		end
		for _, func in ipairs(events[event]) do
			pcall(func, event, ...)
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
	local function CompareVersion(newVersion, oldVersion)
		local newMajor, newMinor, newPatch, newRev, newAddOn, newRelType, newRelRev = newVersion:match("(%d+)%.(%d+)%.(%d+)(%l?)%.(%d+)%_?(%l*)(%d*)")
		local oldMajor, oldMinor, oldPatch, oldRev, oldAddOn, oldRelType, oldRelRev = oldVersion:match("(%d+)%.(%d+)%.(%d+)(%l?)%.(%d+)%_?(%l*)(%d*)")

		newRelType = newRelType == "alpha" and 1 or newRelType == "beta" and 2 or newRelType == "rc" and 3 or 4
		oldRelType = oldRelType == "alpha" and 1 or oldRelType == "beta" and 2 or oldRelType == "rc" and 3 or 4

		local newWoW = (tonumber(newMajor) * 1000000) + (tonumber(newMinor) * 10000) + (tonumber(newPatch) * 100) + (newRev and newRev:lower():byte() or 96) - 96
		local oldWoW = (tonumber(oldMajor) * 1000000) + (tonumber(oldMinor) * 10000) + (tonumber(oldPatch) * 100) + (oldRev and oldRev:lower():byte() or 96) - 96

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

	function xrpPrivate:AddonUpdate(version)
		if not version or version == self.version or version == xrpPrivate.settings.newversion then return end
		if CompareVersion(version, xrpPrivate.settings.newversion or self.version) >= 0 then
			xrpPrivate.settings.newversion = version
		end
	end

	local init = CreateFrame("Frame")
	local addons = {
		"GHI",
		"Tongues",
	}
	init:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == addonName then
			xrpPrivate.playerWithRealm = xrp:UnitNameWithRealm("player")
			xrpPrivate.player, xrpPrivate.realm = xrpPrivate.playerWithRealm:match(FULL_PLAYER_NAME:format("(.+)", "(.+)"))
			xrpPrivate:SavedVariableSetup()

			local newfields
			do
				local addonString = "%s/%s"
				local VA = { addonString:format(GetAddOnMetadata(addonName, "Title"), xrpPrivate.version) }
				for _, addon in ipairs(addons) do
					local name, title, notes, enabled, reason, secure, loadable = GetAddOnInfo(addon)
					if enabled or loadable then
						VA[#VA + 1] = addonString:format(name, GetAddOnMetadata(name, "Version"))
					end
				end
				newfields = {
					GC = select(2, UnitClassBase("player")),
					GF = UnitFactionGroup("player"),
					GR = select(2, UnitRace("player")),
					GS = tostring(UnitSex("player")),
					GU = UnitGUID("player"),
					NA = UnitName("player"), -- Fallback NA field.
					VA = table.concat(VA, ";"),
				}
			end
			local fields, versions = xrpSaved.meta.fields, xrpSaved.meta.versions
			for field, contents in pairs(newfields) do
				if contents ~= fields[field] then
					fields[field] = contents
					versions[field] = xrpPrivate:NewVersion(field)
				end
			end
			fields.VP = tostring(xrpPrivate.msp)
			versions.VP = xrpPrivate.msp

			if not xrpSaved.overrides.logout or xrpSaved.overrides.logout + 600 < time() then
				xrpSaved.overrides.fields = {}
				xrpSaved.overrides.versions = {}
			end
			xrpSaved.overrides.logout = nil

			if xrpPrivate.settings.cache.autoclean then
				xrpPrivate:CacheTidy()
			end

			xrpPrivate:LoadSettings()

			if xrpPrivate.settings.newversion then
				local update = CompareVersion(xrpPrivate.settings.newversion, xrpPrivate.version)
				local now = time()
				if update == 1 and (not xrpPrivate.settings.versionwarning or xrpPrivate.settings.versionwarning < now - 21600) then
					C_Timer.After(8, function()
						print(("There is a new version of |cffabd473XRP|r available. You should update to %s as soon as possible."):format(xrpPrivate.settings.newversion))
						xrpPrivate.settings.versionwarning = now
					end)
				elseif update == -1 then
					xrpPrivate.settings.newversion = nil
					xrpPrivate.settings.versionwarning = nil
				end
			end

			self:UnregisterEvent("ADDON_LOADED")
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
				xrpCache[xrpPrivate.playerWithRealm] = {
					fields = fields,
					versions = versions,
					own = true,
					lastreceive = time(),
				}
			end
			if next(xrpSaved.overrides.fields) then
				xrpSaved.overrides.logout = time()
			end
		elseif event == "NEUTRAL_FACTION_SELECT_RESULT" then
			xrpSaved.meta.fields.GF = UnitFactionGroup("player")
			xrpSaved.meta.versions.GF = xrpPrivate:NewVersion("GF")
			xrpPrivate:FireEvent("UPDATE", "GF")
			self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		end
	end)
	init:RegisterEvent("ADDON_LOADED")
end
