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

local addonName, xrpLocal = ...

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
		GF = {
			Alliance = "Alliance",
			Horde = "Horde",
			Neutral = "Neutral",
		},
		GR = {
			BloodElf = "Blood Elf",
			Draenei = "Draenei",
			Dwarf = "Dwarf",
			Gnome = "Gnome",
			Goblin = "Goblin",
			Human = "Human",
			NightElf = "Night Elf",
			Orc = "Orc",
			Pandaren = "Pandaren",
			Scourge = "Undead", -- Yes, Scourge.
			Tauren = "Tauren",
			Troll = "Troll",
			Worgen = "Worgen",
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
BINDING_NAME_XRP_STATUS = "Toggle IC/OOC status"
BINDING_NAME_XRP_BOOKMARKS = "Open/close bookmarks panel"
BINDING_NAME_XRP_VIEWER = "View target's or mouseover's RP profile"
BINDING_NAME_XRP_VIEWER_TARGET = "View target's RP profile"
BINDING_NAME_XRP_VIEWER_MOUSEOVER = "View mouseover's RP profile"
BINDING_NAME_XRP_EDITOR = "Open/close RP profile editor"

xrpLocal.version = GetAddOnMetadata(addonName, "Version")
xrpLocal.noFunc = function() end
xrpLocal.weakMeta = { __mode = "v" }
xrpLocal.weakKeyMeta = { __mode = "k" }

-- Fields to export and their formats.
xrpLocal.EXPORT_FIELDS = { "NA", "NI", "NT", "NH", "RA", "RC", "AE", "AH", "AW", "AG", "HH", "HB", "CU", "MO", "DE", "HI" }
xrpLocal.EXPORT_FORMATS = {
	NA = "Name: %s\n",
	NI = "Nickname: \"%s\"\n",
	NT = "Title: %s\n",
	NH = "House/Clan/Tribe: %s\n",
	RA = "Race: %s\n",
	RC = "Class: %s\n",
	AE = "Eyes: %s\n",
	AH = "Height: %s\n",
	AW = "Weight: %s\n",
	AG = "Age: %s\n",
	HH = "Home: %s\n",
	HB = "Birthplace: %s\n",
	CU = "\nCurrently:\n%s\n",
	MO = "\nMotto:\n%s\n",
	DE = "\nDescription:\n------------\n%s\n",
	HI = "\nHistory:\n--------\n%s\n",
}

do
	local events = {}

	function xrpLocal:FireEvent(event, ...)
		if type(events[event]) ~= "table" then
			return false
		end
		for i, func in ipairs(events[event]) do
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

	function xrpLocal:AddonUpdate(version)
		if not version or version == self.version or version == xrpLocal.settings.newversion then return end
		if CompareVersion(version, xrpLocal.settings.newversion or self.version) >= 0 then
			xrpLocal.settings.newversion = version
		end
	end

	local init = CreateFrame("Frame")
	local addons = {
		"GHI",
		"Tongues",
	}
	init:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == addonName then
			xrpLocal.playerWithRealm = xrp:UnitName("player")
			xrpLocal.player, xrpLocal.realm = xrpLocal.playerWithRealm:match(FULL_PLAYER_NAME:format("(.+)", "(.+)"))
			xrpLocal:SavedVariableSetup()

			local newFields
			do
				local addonString = "%s/%s"
				local VA = { addonString:format(GetAddOnMetadata(addonName, "Title"), xrpLocal.version) }
				for i, addon in ipairs(addons) do
					if IsAddOnLoaded(addon) then
						VA[#VA + 1] = addonString:format(addon, GetAddOnMetadata(addon, "Version"))
					end
				end
				newFields = {
					GC = select(2, UnitClassBase("player")),
					GF = UnitFactionGroup("player"),
					GR = select(2, UnitRace("player")),
					GS = tostring(UnitSex("player")),
					NA = xrpLocal.player, -- Fallback NA field.
					VA = table.concat(VA, ";"),
				}
			end
			local fields, versions = xrpSaved.meta.fields, xrpSaved.meta.versions
			for field, contents in pairs(newFields) do
				if contents ~= fields[field] then
					fields[field] = contents
					versions[field] = xrpLocal:NewVersion(field)
				end
			end
			fields.VP = tostring(xrpLocal.msp)
			versions.VP = xrpLocal.msp

			if not xrpSaved.overrides.logout or xrpSaved.overrides.logout + 600 < time() then
				xrpSaved.overrides.fields = {}
				xrpSaved.overrides.versions = {}
			end
			xrpSaved.overrides.logout = nil

			if xrpLocal.settings.cache.autoClean then
				xrpLocal:CacheTidy()
			end

			xrpLocal:LoadSettings()

			if xrpLocal.settings.newversion then
				local update = CompareVersion(xrpLocal.settings.newversion, xrpLocal.version)
				local now = time()
				if update == 1 and (not xrpLocal.settings.versionwarning or xrpLocal.settings.versionwarning < now - 21600) then
					C_Timer.After(8, function()
						print(("There is a new version of |cffabd473XRP|r available. You should update to %s as soon as possible."):format(xrpLocal.settings.newversion))
						xrpLocal.settings.versionwarning = now
					end)
				elseif update == -1 then
					xrpLocal.settings.newversion = nil
					xrpLocal.settings.versionwarning = nil
				end
			end

			self:UnregisterEvent("ADDON_LOADED")
			if fields.GF == "Neutral" then
				self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
			end
			self:RegisterEvent("PLAYER_LOGIN")
			self:RegisterEvent("PLAYER_LOGOUT")
		elseif event == "PLAYER_LOGIN" then
			-- UnitGUID() does not work prior to first PLAYER_LOGIN (but does
			-- work after ReloadUI()).
			local GU = UnitGUID("player")
			if xrpSaved.meta.fields.GU ~= GU then
				xrpSaved.meta.fields.GU = GU
				xrpSaved.meta.versions.GU = xrpLocal:NewVersion("GU")
			end
			self:UnregisterEvent("PLAYER_LOGIN")
		elseif event == "PLAYER_LOGOUT" then
			-- Note: This code must be thoroughly tested if any changes are
			-- made. If there are any errors in here, they are not visible in
			-- any manner in-game.
			local now = time()
			do
				local fields, versions = {}, {}
				local profiles, inherit = { xrpSaved.profiles[xrpSaved.selected] }, xrpSaved.profiles[xrpSaved.selected].parent
				for i = 1, 16 do
					profiles[#profiles + 1] = xrpSaved.profiles[inherit]
					inherit = xrpSaved.profiles[inherit].parent
					if not xrpSaved.profiles[inherit] then
						break
					end
				end
				for i = #profiles, 1, -1 do
					local profile = profiles[i]
					for field, doInherit in pairs(profile.inherits) do
						if doInherit == false then
							fields[field] = nil
							versions[field] = nil
						end
					end
					for field, contents in pairs(profile.fields) do
						if not fields[field] then
							fields[field] = contents
							versions[field] = profile.versions[field]
						end
					end
				end
				for field, contents in pairs(xrpSaved.meta.fields) do
					if not fields[field] then
						fields[field] = contents
						versions[field] = xrpSaved.meta.versions[field]
					end
				end
				for field, contents in pairs(xrpSaved.overrides.fields) do
					if contents == "" then
						fields[field] = nil
						versions[field] = nil
					else
						fields[field] = contents
						versions[field] = xrpSaved.overrides.versions[field]
					end
				end
				if fields.AW then
					fields.AW = xrp:Weight(fields.AW, "msp")
				end
				if fields.AH then
					fields.AH = xrp:Height(fields.AH, "msp")
				end
				xrpCache[xrpLocal.playerWithRealm] = {
					fields = fields,
					versions = versions,
					own = true,
					lastReceive = now,
				}
			end
			if next(xrpSaved.overrides.fields) then
				xrpSaved.overrides.logout = now
			end
		elseif event == "NEUTRAL_FACTION_SELECT_RESULT" then
			xrpSaved.meta.fields.GF = UnitFactionGroup("player")
			xrpSaved.meta.versions.GF = xrpLocal:NewVersion("GF")
			xrpLocal:FireEvent("UPDATE", "GF")
			self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		end
	end)
	init:RegisterEvent("ADDON_LOADED")
end
