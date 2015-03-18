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

local currentUnit = {
	lines = {},
}

local TooltipFrame, replace, active, rendering

local GTTL, GTTR = "GameTooltipTextLeft%d", "GameTooltipTextRight%d"

local RenderTooltip
do
	local function TruncateLine(text, length, offset, double)
		if not text then return end
		offset = offset or 0
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
			if double ~= false and #text - #line1 > line1pos + offset then
				while text:find(" ", position + 1, true) and (text:find(" ", position + 1, true)) <= (length - offset + length) do
					position = text:find(" ", position + 1, true)
				end
				isTruncated = true
				line2 = text:sub(line1pos, position - 1)
			elseif double ~= false then
				line2 = text:sub(position + 1)
			else
				isTruncated = true
			end
		end
		return (line2 and (isTruncated and "%s\n%s..." or "%s\n%s") or isTruncated and "%s..." or "%s"):format(line1, line2)
	end

	local ParseVersion
	do
		local PROFILE_ADDONS = {
			["XRP"] = "XRP",
			["MYROLEPLAY"] = "MRP",
			["TOTALRP2"] = "TRP2",
			["TOTALRP3"] = "TRP3",
			["GNOMTEC_BADGE"] = "GTEC",
			["FLAGRSP"] = "RSP",
		}
		local EXTRA_ADDONS = {
			["GHI"] = "GHI",
			["TONGUES"] = "T",
		}
		function ParseVersion(VA)
			if not VA then return end
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

	local oldLines, lineNum = 0, 0
	local function RenderLine(left, right, lR, lG, lB, rR, rG, rB)
		if not left and not right then return end
		rendering = true
		lineNum = lineNum + 1
		-- First case: If there's already a line to replace. This only happens
		-- if using the GameTooltip, as XRPTooltip is cleared before rendering
		-- starts.
		if lineNum <= oldLines then
			local LeftLine = _G[GTTL:format(lineNum)]
			local RightLine = _G[GTTR:format(lineNum)]
			-- Can't have an empty left text line ever -- if a line exists, it
			-- needs to have a space at minimum to not muck up line spacing.
			LeftLine:SetText(left or " ")
			LeftLine:SetTextColor(lR or 1, lG or 0.82, lB or 0)
			LeftLine:Show()
			if right then
				RightLine:SetText(right)
				RightLine:SetTextColor(rR or 1, rG or 0.82, rB or 0)
				RightLine:Show()
			else
				RightLine:Hide()
			end
		else -- Second case: If there are no more lines to replace.
			if right then
				TooltipFrame:AddDoubleLine(left or " ", right, lR or 1, lG or 0.82, lB or 0, rR or 1, rG or 0.82, rB or 0)
			elseif left then
				TooltipFrame:AddLine(left, lR or 1, lG or 0.82, lB or 0)
			end
		end
		rendering = nil
	end

	local COLORS = {
		OOC = { r = 0.6, g = 0.4, b = 0.3 },
		IC = { r = 0.4, g = 0.7, b = 0.5 },
		Alliance = { r = 0.53, g = 0.56, b = 1 },
		Horde = { r = 1, g = 0.39, b = 0.41 },
		Neutral = { r = 1, g = 0.86, b = 0.36 },
	}
	function RenderTooltip()
		if not replace then
			TooltipFrame:ClearLines()
			TooltipFrame:SetOwner(GameTooltip, "ANCHOR_TOPRIGHT")
		end
		oldLines = TooltipFrame:NumLines()
		lineNum = 0
		local showProfile = not (currentUnit.noProfile or currentUnit.character.hide)
		local fields = currentUnit.character.fields

		if currentUnit.type == "player" then
			if not replace then
				if currentUnit.character.hide then
					RenderLine("Hidden", nil, 0.5, 0.5, 0.5)
					TooltipFrame:Show()
					return
				elseif (not showProfile or not fields.VA) then
					TooltipFrame:Hide()
					return
				end
			end
			RenderLine(currentUnit.nameFormat:format(showProfile and TruncateLine(xrp:Strip(fields.NA), 65, 0, false) or xrp:Ambiguate(currentUnit.character.name)), currentUnit.icons)
			if showProfile then
				local NI = fields.NI
				RenderLine(NI and ("|cff6070a0Nickname:|r \"%s\""):format(TruncateLine(xrp:Strip(NI), 70, 12, false)) or nil, nil, 0.6, 0.7, 0.9)
				RenderLine(TruncateLine(xrp:Strip(fields.NT), 70), nil, 0.8, 0.8, 0.8)
			end
			if xrpLocal.settings.tooltip.extraSpace then
				RenderLine(" ")
			end
			if replace then
				RenderLine(currentUnit.guild, nil, 1, 1, 1)
				local color = COLORS[currentUnit.faction]
				RenderLine(currentUnit.titleRealm, currentUnit.character.hide and "Hidden" or showProfile and ParseVersion(fields.VA), color.r, color.g, color.b, 0.5, 0.5, 0.5)
				if xrpLocal.settings.tooltip.extraSpace then
					RenderLine(" ")
				end
			end
			if showProfile then
				local CU = fields.CU
				RenderLine(CU and ("|cffa08050Currently:|r %s"):format(TruncateLine(xrp:Strip(CU), 70, 11)) or nil, nil, 0.9, 0.7, 0.6)
			end
			RenderLine(currentUnit.info:format(showProfile and not xrpLocal.settings.tooltip.noRace and TruncateLine(xrp:Strip(fields.RA), 40, 0, false) or xrp.values.GR[fields.GR] or UNKNOWN, showProfile and not xrpLocal.settings.tooltip.noClass and TruncateLine(xrp:Strip(fields.RC), 40, 0, false) or xrp.values.GC[fields.GC] or UNKNOWN, 40, 0, false), not replace and ParseVersion(fields.VA), 1, 1, 1, 0.5, 0.5, 0.5)
			if showProfile then
				local FR, FC = fields.FR, fields.FC
				if FR and FR ~= "0" or FC and FC ~= "0" then
					local color = COLORS[FC == "1" and "OOC" or "IC"]
					RenderLine((not FR or FR == "0") and " " or xrp.values.FR[FR] or TruncateLine(xrp:Strip(FR), 35, 0, false), FC and FC ~= "0" and (xrp.values.FC[FC] or TruncateLine(xrp:Strip(FC), 35, 0, false)) or nil, color.r, color.g, color.b, color.r, color.g, color.b)
				end
			end
			if replace then
				RenderLine(currentUnit.location, nil, 1, 1, 1)
			end
		elseif currentUnit.type == "pet" then
			RenderLine(currentUnit.nameFormat, currentUnit.icons)
			local color = COLORS[currentUnit.faction]
			RenderLine(currentUnit.titleRealm:format(showProfile and TruncateLine(xrp:Strip(fields.NA), 60, 0, false) or xrp:Ambiguate(currentUnit.character.name)), nil, color.r, color.g, color.b)
			RenderLine(currentUnit.info, nil, 1, 1, 1)
		end

		if replace then
			for i, line in ipairs(currentUnit.lines) do
				if line.double then
					RenderLine(unpack(line))
				else
					RenderLine(line[1], nil, unpack(line, 2))
				end
			end
			-- In rare cases (test case: target without RP addon, is PvP
			-- flagged) there will be some leftover lines at the end of the
			-- tooltip. This hides them, if they exist.
			while lineNum < oldLines do
				lineNum = lineNum + 1
				_G[GTTL:format(lineNum)]:Hide()
				_G[GTTR:format(lineNum)]:Hide()
			end
		end

		TooltipFrame:Show()
	end
end

local SetUnit
do
	local COLORS = {
		friendly = "00991a",
		neutral = "e6b300",
		hostile = "cc4d38",
	}
	local PVP_ICON = "|TInterface\\TargetingFrame\\UI-PVP-%s:18:18:4:0:8:8:0:5:0:5|t"
	function SetUnit(unit)
		currentUnit.type = UnitIsPlayer(unit) and "player" or replace and (UnitIsOtherPlayersPet(unit) or UnitIsUnit("playerpet", unit)) and "pet" or nil
		if not currentUnit.type then return end

		local defaultLines = 3
		local playerFaction = xrp.current.fields.GF
		local attackMe = UnitCanAttack(unit, "player")
		local meAttack = UnitCanAttack("player", unit)
		if currentUnit.type == "player" then
			currentUnit.character = xrp.characters.byUnit[unit]

			currentUnit.faction = currentUnit.character.fields.GF or "Neutral"

			local connected = UnitIsConnected(unit)
			local color = COLORS[(currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or attackMe and meAttack) and "hostile" or (currentUnit.faction == "Neutral" or meAttack or attackMe) and "neutral" or "friendly"]
			local watchIcon = xrpLocal.settings.tooltip.watching and UnitIsUnit("player", unit .. "target") and "|TInterface\\LFGFrame\\BattlenetWorking0:28:28:10:0|t" or nil
			local class, classID = UnitClassBase(unit)

			if replace then
				-- Can only ever be one of AFK, DND, or offline.
				local isAFK = connected and UnitIsAFK(unit)
				local isDND = connected and not isAFK and UnitIsDND(unit)
				currentUnit.nameFormat = ("|cff%s%%s|r%s"):format(color, not connected and " |cff888888<Offline>|r" or isAFK and " |cff99994d<Away>|r" or isDND and " |cff994d4d<Busy>|r" or "")

				local ffa = UnitIsPVPFreeForAll(unit)
				local pvpIcon = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction) or nil
				currentUnit.icons = watchIcon and pvpIcon and watchIcon .. pvpIcon or watchIcon or pvpIcon

				local guildName, guildRank, guildIndex = GetGuildInfo(unit)
				currentUnit.guild = guildName and (xrpLocal.settings.tooltip.guildRank and (xrpLocal.settings.tooltip.guildIndex and "%s (%d) of <%s>" or "%s of <%s>") or "<%s>"):format(xrpLocal.settings.tooltip.guildRank and guildRank or guildName, xrpLocal.settings.tooltip.guildIndex and guildIndex + 1 or guildName, guildName) or nil

				local realm = currentUnit.character.name:match(FULL_PLAYER_NAME:format(".+", "(.+)"))
				if realm == xrpLocal.realm then
					realm = nil
				end
				local name = UnitPVPName(unit) or xrp:Ambiguate(currentUnit.character.name)
				currentUnit.titleRealm = realm and ("%s (%s)"):format(name, xrp:RealmDisplayName(realm)) or name

				local level = UnitLevel(unit)
				currentUnit.info = ("%s %%s |c%s%%s|r (%s)"):format((level < 1 and UNIT_LETHAL_LEVEL_TEMPLATE or UNIT_LEVEL_TEMPLATE):format(level), RAID_CLASS_COLORS[classID] and RAID_CLASS_COLORS[classID].colorStr or "ffffffff", PLAYER)

				local location = connected and not UnitIsVisible(unit) and GameTooltipTextLeft3:GetText() or nil
				currentUnit.location = location and ("|cffffeeaaZone:|r %s"):format(location) or nil

				if pvpIcon then
					defaultLines = defaultLines + 1
				end
				if guildName then
					defaultLines = defaultLines + 1
				end
			else
				currentUnit.nameFormat = ("|cff%s%%s|r"):format(color)
				currentUnit.icons = watchIcon
				currentUnit.info = ("%%s |c%s%%s|r"):format(RAID_CLASS_COLORS[classID] and RAID_CLASS_COLORS[classID].colorStr or "ffffffff")
			end
		elseif currentUnit.type == "pet" then
			currentUnit.faction = UnitFactionGroup(unit) or UnitIsUnit(unit, "playerpet") and playerFaction or "Neutral"

			local name = UnitName(unit)
			local color = COLORS[(currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or attackMe and meAttack) and "hostile" or (currentUnit.faction == "Neutral" or meAttack or attackMe) and "neutral" or "friendly"]
			currentUnit.nameFormat = ("|cff%s%s|r"):format(color, name)

			local ffa = UnitIsPVPFreeForAll(unit)
			currentUnit.icons = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction) or nil

			local ownership = GameTooltipTextLeft2:GetText()
			local owner, petType = ownership:match(UNITNAME_TITLE_PET:format("(.+)")), UNITNAME_TITLE_PET
			if not owner then
				owner, petType = ownership:match(UNITNAME_TITLE_MINION:format("(.+)")), UNITNAME_TITLE_MINION
			end

			if not owner then return end
			currentUnit.character = xrp.characters.byName[owner]

			local realm = owner:match(FULL_PLAYER_NAME:format(".+", "(.+)"))
			currentUnit.titleRealm = realm and ("%s (%s)"):format(petType, xrp:RealmDisplayName(realm)) or petType

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

			if currentUnit.icons then
				defaultLines = defaultLines + 1
			end
		end
		currentUnit.noProfile = xrpLocal.settings.tooltip.noOpFaction and currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or xrpLocal.settings.tooltip.noHostile and attackMe and meAttack

		if replace then
			table.wipe(currentUnit.lines)
			local currentLines = GameTooltip:NumLines()
			if defaultLines < currentLines then
				for i = defaultLines + 1, currentLines do
					local LeftLine = _G[GTTL:format(i)]
					local RightLine = _G[GTTR:format(i)]
					if RightLine:IsVisible() then
						currentUnit.lines[#currentUnit.lines + 1] = { double = true, LeftLine:GetText(), RightLine:GetText(), LeftLine:GetTextColor(), RightLine:GetTextColor() }
					else
						currentUnit.lines[#currentUnit.lines + 1] = { LeftLine:GetText(), LeftLine:GetTextColor() }
					end
				end
			end
		end

		active = true
		RenderTooltip()
	end
end

local enabled
local function Tooltip_RECEIVE(event, name)
	if not enabled or not active or name ~= currentUnit.character.name then return end
	local tooltip, unit = GameTooltip:GetUnit()
	if tooltip then
		RenderTooltip()
		-- If the mouse has already left the unit, the tooltip will get stuck
		-- visible. This bounces it back into visibility if it's partly faded
		-- out, but it'll just fade again.
		if not GameTooltip:IsUnit("mouseover") then
			TooltipFrame:FadeOut()
			if not replace then
				GameTooltip:Show()
				GameTooltip:FadeOut()
			end
		end
	end
end

local function XRPTooltip_OnUpdate(self, elapsed)
	if not self.fading and not UnitExists("mouseover") then
		self.fading = true
		self:FadeOut()
	end
end

local function XRPTooltip_OnHide(self)
	self.fading = nil
	GameTooltip_OnHide(self)
end

local function GameTooltip_AddLine_Hook(self, ...)
	if enabled and replace and active and not rendering then
		currentUnit.lines[#currentUnit.lines + 1] = { ... }
	end
end

local function GameTooltip_AddDoubleLine_Hook(self, ...)
	if enabled and replace and active and not rendering then
		currentUnit.lines[#currentUnit.lines + 1] = { double = true, ... }
	end
end

local function GameTooltip_FadeOut_Hook(self)
	if enabled and not replace then
		TooltipFrame:FadeOut()
	end
end

local function GameTooltip_OnTooltipCleared_Hook(self)
	active = nil
	if enabled and not replace then
		TooltipFrame:Hide()
	end
end

local NoUnit
local function GameTooltip_OnTooltipSetUnit_Hook(self)
	if not enabled then return end
	local tooltip, unit = self:GetUnit()
	if not unit then
		NoUnit:Show()
	else
		SetUnit(unit)
	end
end

local function NoUnit_OnUpdate(self, elapsed)
	-- GameTooltip:GetUnit() will sometimes return nil, especially when custom
	-- unit frames call GameTooltip:SetUnit() with something 'odd' like
	-- targettarget. By the next frame draw, the tooltip will correctly be able
	-- to identify such units (usually as mouseover).
	self:Hide()
	local tooltip, unit = GameTooltip:GetUnit()
	if not unit then return end
	SetUnit(unit)
end

xrpLocal.settingsToggles.tooltip = {
	enabled = function(setting)
		if setting then
			if enabled == nil then
				NoUnit = CreateFrame("Frame")
				NoUnit:Hide()
				NoUnit:SetScript("OnUpdate", NoUnit_OnUpdate)
				xrp:HookEvent("RECEIVE", Tooltip_RECEIVE)
				GameTooltip:HookScript("OnTooltipSetUnit", GameTooltip_OnTooltipSetUnit_Hook)
				GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared_Hook)
			end
			enabled = true
			xrpLocal.settingsToggles.tooltip.replace(xrpLocal.settings.tooltip.replace)
		elseif enabled ~= nil then
			enabled = false
		end
	end,
	replace = function(setting)
		if not enabled then return end
		if setting then
			if replace == nil then
				hooksecurefunc(GameTooltip, "AddLine", GameTooltip_AddLine_Hook)
				hooksecurefunc(GameTooltip, "AddDoubleLine", GameTooltip_AddDoubleLine_Hook)
			end
			TooltipFrame = GameTooltip
			replace = true
		else
			if not XRPTooltip then
				CreateFrame("GameTooltip", "XRPTooltip", UIParent, "GameTooltipTemplate")
				XRPTooltip:SetScript("OnUpdate", XRPTooltip_OnUpdate)
				XRPTooltip:SetScript("OnHide", XRPTooltip_OnHide)
				hooksecurefunc(GameTooltip, "FadeOut", GameTooltip_FadeOut_Hook)
			end
			TooltipFrame = XRPTooltip
			if replace ~= nil then
				replace = false
			end
		end
	end,
}
