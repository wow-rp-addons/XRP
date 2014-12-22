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

local currentUnit = {}

local RenderTooltip
do
	local function TruncateLine(text, length, offset, double)
		if type(text) ~= "string" then
			return nil
		end
		offset = offset or 0
		if double == nil then
			double = true
		end
		text = text:gsub("\n+", " ")
		local line1, line2 = text
		local isTruncated = false
		if #text > length - offset and text:find(" ", 1, true) then
			local position = 0
			local line1pos = 0
			while text:find(" ", position + 1, true) and (text:find(" ", position + 1, true)) <= (length - offset) do
				position = text:find(" ", position + 1, true)
			end
			line1 = text:sub(1, position - 1)
			line1pos = position + 1
			if double and #text - #line1 > line1pos + offset then
				while text:find(" ", position + 1, true) and (text:find(" ", position + 1, true)) <= (length - offset + length) do
					position = text:find(" ", position + 1, true)
				end
				isTruncated = true
				line2 = text:sub(line1pos, position - 1)
			elseif double then
				line2 = text:sub(position + 1)
			else
				isTruncated = true
			end
		end
		return (line2 and (isTruncated and "%s\n%s..." or "%s\n%s") or isTruncated and "%s..." or "%s"):format(line1, line2)
	end

	local ParseVersion
	do
		-- Use uppercase for keys.
		local PROFILE_ADDONS = {
			["XRP"] = "XRP",
			["MYROLEPLAY"] = "MRP",
			["TOTALRP2"] = "TRP2",
			["TOTALRP3"] = "TRP3",
			["GNOMTEC_BADGE"] = "GTEC",
			["FLAGRSP"] = "RSP",
			["FLAGRSP2"] = "RSP2",
			["HIDDEN"] = "Hidden", -- Pseudo-addon used to mark as hidden.
		}
		local EXTRA_ADDONS = {
			["GHI"] = "GHI",
			["TONGUES"] = "T",
		}

		function ParseVersion(VA)
			local short = {}
			local hasProfile = false
			for addon in VA:upper():gmatch("([^/;]+)/[^/;]+") do
				if PROFILE_ADDONS[addon] and not hasProfile then
					short[#short + 1] = PROFILE_ADDONS[addon]
					hasProfile = true
				elseif EXTRA_ADDONS[addon]then
					short[#short + 1] = EXTRA_ADDONS[addon]
				end
			end
			if not hasProfile then
				-- They must have some sort of addon, just not a known one.
				table.insert(short, 1, "RP")
			end
			return table.concat(short, ", ")
		end
	end

	local oldlines, numline = 0, 0
	local GTTL, GTTR = "GameTooltipTextLeft%u", "GameTooltipTextRight%u"
	local function RenderLine(left, right)
		if not left and not right then
			return
		end
		numline = numline + 1
		-- This is a bit scary-looking, but it's a sane way to replace tooltip
		-- lines without needing to completely redo the tooltip from scratch
		-- (and lose the tooltip's state of what it's looking at if we do).
		--
		-- First case: If there's already a line to replace.
		if numline <= oldlines then
			local leftline = GTTL:format(numline)
			local rightline = GTTR:format(numline)
			-- Can't have an empty left text line ever -- if a line exists, it
			-- needs to have a space at minimum to not muck up line spacing.
			_G[leftline]:SetText(left or " ")
			_G[leftline]:SetTextColor(1, 1, 1)
			_G[leftline]:Show()
			if right then
				_G[rightline]:SetText(right)
				_G[rightline]:SetTextColor(1, 1, 1)
				_G[rightline]:Show()
			else
				_G[rightline]:Hide()
			end
		-- Second case: If there are no more lines to replace.
		else
			if right then
				GameTooltip:AddDoubleLine(left or " ", right, 1, 1, 1, 1, 1, 1)
			elseif left then
				GameTooltip:AddLine(left, 1, 1, 1)
			end
		end
	end

	local HIDDEN = { VA = "Hidden/0" }

	function RenderTooltip(character)
		oldlines = GameTooltip:NumLines()
		numline = 0
		local fields = character.hide and HIDDEN or character.fields

		if currentUnit.type == "player" then

			RenderLine(currentUnit.nameFormat:format(TruncateLine(xrp:Strip(fields.NA), 65, 0, false) or xrp:Ambiguate(currentUnit.name)), currentUnit.icons)

			if fields.NI then
				RenderLine(("|cff6070a0Nickname:|r |cff99b3e6\"%s\"|r"):format(TruncateLine(xrp:Strip(fields.NI), 70, 10, false)))
			end

			if fields.NT then
				RenderLine(("|cffcccccc%s|r"):format(TruncateLine(xrp:Strip(fields.NT), 70)))
			end

			if xrpPrivate.settings.tooltip.extraSpace then
				RenderLine(" ")
			end

			RenderLine(currentUnit.guild)

			RenderLine(currentUnit.titleRealm, fields.VA and ("|cff7f7f7f%s|r"):format(ParseVersion(fields.VA)) or nil)

			if xrpPrivate.settings.tooltip.extraSpace then
				RenderLine(" ")
			end

			if fields.CU then
				RenderLine(("|cffa08050Currently:|r |cffe6b399%s|r"):format(TruncateLine(xrp:Strip(fields.CU), 70, 11)))
			end

			RenderLine(currentUnit.info:format(not xrpPrivate.settings.tooltip.noRace and TruncateLine(xrp:Strip(fields.RA), 40, 0, false) or currentUnit.race or UNKNOWN, not xrpPrivate.settings.tooltip.noClass and TruncateLine(xrp:Strip(fields.RC), 40, 0, false) or currentUnit.class or UNKNOWN, 40, 0, false))

			if fields.FR and fields.FR ~= "0" or fields.FC and fields.FC ~= "0" then
				local color = fields.FC == "1" and "ff99664d" or "ff66b380"
				-- AAAAAAAAAAAAAAAAAAAAAAAA. The boolean logic.
				local frline = ("|c%s%s|r"):format(color, TruncateLine((fields.FR == "0" or not fields.FR) and " " or xrp.values.FR[fields.FR] or xrp:Strip(fields.FR), 35, 0, false))
				local fcline
				if fields.FC and fields.FC ~= "0" then
					fcline = ("|c%s%s|r"):format(color, TruncateLine(xrp.values.FC[fields.FC] or xrp:Strip(fields.FC), 35, 0, false))
				end
				RenderLine(frline, fcline)
			end

			RenderLine(currentUnit.location)
		elseif currentUnit.type == "pet" then
			RenderLine(currentUnit.nameFormat, currentUnit.icons)
			RenderLine(currentUnit.titleRealm:format(fields.NA and TruncateLine(xrp:Strip(fields.NA), 60, 0, false) or xrp:Ambiguate(currentUnit.name)))
			RenderLine(currentUnit.info)
		end
		-- In rare cases (test case: target without RP addon, is PvP flagged)
		-- there will be some leftover lines at the end of the tooltip. This
		-- hides them, if they exist.
		while numline < oldlines do
			numline = numline + 1
			_G[GTTL:format(numline)]:Hide()
			_G[GTTR:format(numline)]:Hide()
		end

		if currentUnit.icons and (currentUnit.type == "pet" or fields.NI or fields.NT or currentUnit.guild or not fields.VA) then
			GameTooltipTextRight2:SetText(" ")
			GameTooltipTextRight2:Show()
		end

		GameTooltip:Show()
	end
end

local SetPlayerUnit, SetPetUnit
do
	local FACTION_COLORS = {
		Horde = "ffff6468", -- Dark: ffe60d12
		Alliance = "ff868eff", -- Dark: ff4a54e8
		Neutral = "ffffdb5c", -- Dark: ffe6b300
	}

	local REACTION_COLORS = {
		friendly = "ff00991a",
		neutral = "ffe6b300",
		hostile = "ffcc4d38",
	}
	local NO_RP_PROFILE = { fields = {} }

	function SetPlayerUnit(unit)
		currentUnit.name = xrp:UnitName(unit)

		local faction = UnitFactionGroup(unit)
		local playerFaction = xrp.current.fields.GF
		if not faction or not FACTION_COLORS[faction] then
			faction = "Neutral"
		end

		local attackMe = UnitCanAttack(unit, "player")
		local meAttack = UnitCanAttack("player", unit)
		local connected = UnitIsConnected(unit)

		do
			local color = REACTION_COLORS[(faction ~= playerFaction and faction ~= "Neutral" or attackMe and meAttack) and "hostile" or (faction == "Neutral" or meAttack or attackMe) and "neutral" or "friendly"]
			-- Can only ever be one of AFK, DND, or offline.
			local isAFK = connected and UnitIsAFK(unit)
			local isDND = connected and not isAFK and UnitIsDND(unit)
			currentUnit.nameFormat = ("|c%s%%s|r%s"):format(color, not connected and " |cff888888<Offline>|r" or isAFK and " |cff99994d<Away>|r" or isDND and " |cff994d4d<Busy>|r" or "")
		end

		do
			local watchIcon = xrpPrivate.settings.tooltip.watching and UnitIsUnit("player", unit .. "target") and "|TInterface\\LFGFrame\\BattlenetWorking0:32:32:10:-2|t" or nil
			local ffa = UnitIsPVPFreeForAll(unit)
			local pvpIcon = (UnitIsPVP(unit) or ffa) and ("|TInterface\\TargetingFrame\\UI-PVP-%s:20:20:4:-2:8:8:0:5:0:5:255:255:255|t"):format((ffa or faction == "Neutral") and "FFA" or faction) or nil
			currentUnit.icons = watchIcon and pvpIcon and watchIcon .. pvpIcon or watchIcon or pvpIcon
		end

		do
			local guildName, guildRank, guildIndex = GetGuildInfo(unit)
			currentUnit.guild = guildName and (xrpPrivate.settings.tooltip.guildRank and (xrpPrivate.settings.tooltip.guildIndex and "%s (%u) of <%s>" or "%s of <%s>") or "<%s>"):format(xrpPrivate.settings.tooltip.guildRank and guildRank or guildName, xrpPrivate.settings.tooltip.guildIndex and guildIndex + 1 or guildName, guildName) or nil
		end

		do
			local realm = currentUnit.name:match(FULL_PLAYER_NAME:format(".+", "(.+)"))
			if realm == xrpPrivate.realm then
				realm = nil
			end
			currentUnit.titleRealm = (realm and "|c%s%s (%s)|r" or "|c%s%s|r"):format(FACTION_COLORS[faction], UnitPVPName(unit) or xrp:Ambiguate(currentUnit.name), realm and xrp:RealmDisplayName(realm))
		end

		currentUnit.race = UnitRace(unit) or UnitCreatureType(unit)
		do
			local level = UnitLevel(unit)
			local class, classID = UnitClassBase(unit)
			currentUnit.class = class
			currentUnit.info = ("%s %%s |c%s%%s|r (%s)"):format((level < 1 and UNIT_LETHAL_LEVEL_TEMPLATE or UNIT_LEVEL_TEMPLATE):format(level), RAID_CLASS_COLORS[classID] and RAID_CLASS_COLORS[classID].colorStr or "ffffffff", PLAYER)
		end

		do
			-- Ew, screen-scraping.
			local location = connected and not UnitIsVisible(unit) and GameTooltipTextLeft3:GetText() or nil
			currentUnit.location = location and ("|cffffeeaaZone:|r %s"):format(location) or nil
		end

		currentUnit.type = "player"
		RenderTooltip((not xrpPrivate.settings.tooltip.noOpFaction or faction == playerFaction or faction == "Neutral") and (not xrpPrivate.settings.tooltip.noHostile or not attackMe or not meAttack) and xrp.characters.byUnit[unit] or NO_RP_PROFILE)
	end

	function SetPetUnit(unit)
		local faction = UnitFactionGroup(unit)
		local playerFaction = xrp.current.fields.GF
		if not faction or not FACTION_COLORS[faction] then
			faction = UnitIsUnit(unit, "playerpet") and playerFaction or "Neutral"
		end
		local attackMe = UnitCanAttack(unit, "player")
		local meAttack = UnitCanAttack("player", unit)

		do
			local name = UnitName(unit)
			local color = REACTION_COLORS[(faction ~= playerFaction and faction ~= "Neutral" or attackMe and meAttack) and "hostile" or (faction == "Neutral" or meAttack or attackMe) and "neutral" or "friendly"]
			currentUnit.nameFormat = ("|c%s%s|r"):format(color, name)
		end

		do
			local ffa = UnitIsPVPFreeForAll(unit)
			currentUnit.icons = (UnitIsPVP(unit) or ffa) and ("|TInterface\\TargetingFrame\\UI-PVP-%s:20:20:4:-2:8:8:0:5:0:5:255:255:255|t"):format((ffa or faction == "Neutral") and "FFA" or faction) or nil
		end

		do
			-- I hate how fragile this is.
			local ownership = GameTooltipTextLeft2:GetText()
			local owner, petType = ownership:match(UNITNAME_TITLE_PET:format("(.+)")), UNITNAME_TITLE_PET
			if not owner then
				owner, petType = ownership:match(UNITNAME_TITLE_MINION:format("(.+)")), UNITNAME_TITLE_MINION
			end
			-- If there's still no owner, we can't do anything useful.
			if not owner then return end
			local realm = owner:match(FULL_PLAYER_NAME:format(".+", "(.+)"))

			currentUnit.titleRealm = (realm and "|c%s%s (%s)|r" or "|c%s%s|r"):format(FACTION_COLORS[faction], petType, realm and xrp:RealmDisplayName(realm))

			currentUnit.name = xrp:Name(owner)
			local race = UnitCreatureFamily(unit) or UnitCreatureType(unit)
			if race == "Ghoul" or race == "Water Elemental" or race == "MT - Water Elemental" then
				race = UnitCreatureType(unit)
			elseif not race then
				race = UNKNOWN
			end
			-- Mages, death knights, and warlocks have minions, hunters have 
			-- pets. Mages and death knights only have one pet family each.
			local classID = petType == UNITNAME_TITLE_MINION and (race == "Elemental" and "MAGE" or race == "Undead" and "DEATHKNIGHT" or "WARLOCK") or petType == UNITNAME_TITLE_PET and "HUNTER"
			local level = UnitLevel(unit)

			currentUnit.info = ("%s |c%s%s|r (%s)"):format((level < 1 and UNIT_LETHAL_LEVEL_TEMPLATE or UNIT_LEVEL_TEMPLATE):format(level), RAID_CLASS_COLORS[classID] and RAID_CLASS_COLORS[classID].colorStr or "ffffffff", race, PET)
		end

		currentUnit.type = "pet"
		RenderTooltip((not xrpPrivate.settings.tooltip.noOpFaction or faction == playerFaction or faction == "Neutral") and (not xrpPrivate.settings.tooltip.noHostile or not attackMe or not meAttack) and xrp.characters.byName[currentUnit.name] or NO_RP_PROFILE)
	end
end

local enabled
local function RECEIVE(event, character)
	if not enabled or character ~= currentUnit.name then return end
	local tooltip, unit = GameTooltip:GetUnit()
	if tooltip and currentUnit.type == "player" then
		RenderTooltip(unit and xrp.characters.byUnit[unit] or xrp.characters.byName[character])
	elseif tooltip and currentUnit.type == "pet" then
		RenderTooltip(xrp.characters.byName[character])
	else
		return
	end
	-- If the mouse has already left the unit, the tooltip will get stuck
	-- visible if we don't do this. It still bounces back into visibility if
	-- it's partly faded out, but it'll just fade again.
	if not GameTooltip:IsUnit("mouseover") then
		GameTooltip:FadeOut()
	end
end

local NoUnit
local function OnTooltipSetUnit(self)
	if not enabled then return end
	currentUnit.type = nil
	local tooltip, unit = self:GetUnit()
	if not unit then
		NoUnit:Show()
	elseif UnitIsPlayer(unit) then
		SetPlayerUnit(unit)
	elseif UnitIsOtherPlayersPet(unit) or UnitIsUnit("playerpet", unit) then
		SetPetUnit(unit)
	end
end

local function NoUnit_OnUpdate(self, elapsed)
	-- GameTooltip:GetUnit() will sometimes return nil, especially when custom
	-- unit frames call GameTooltip:SetUnit() with something 'odd' like
	-- targettarget. By the next frame draw, the tooltip will correctly be able
	-- to identify such units (usually as mouseover).
	self:Hide()
	local tooltip, unit = GameTooltip:GetUnit()
	if not unit then
		return
	elseif UnitIsPlayer(unit) then
		SetPlayerUnit(unit)
	elseif UnitIsOtherPlayersPet(unit) or UnitIsUnit("playerpet", unit) then
		SetPetUnit(unit)
	end
end

xrpPrivate.settingsToggles.tooltip = {
	enabled = function(setting)
		if setting then
			if enabled == nil then
				NoUnit = CreateFrame("Frame")
				NoUnit:Hide()
				NoUnit:SetScript("OnUpdate", NoUnit_OnUpdate)
				xrp:HookEvent("RECEIVE", RECEIVE)
				GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
			end
			enabled = true
		elseif enabled ~= nil then
			enabled = false
		end
	end,
}
