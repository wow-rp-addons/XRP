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

local FOLDER, _xrp = ...

local currentUnit = {
	lines = {},
}

local maxLinesAdjusted = {}

local Tooltip, replace, rendering

local GTTL, GTTR = "GameTooltipTextLeft%d", "GameTooltipTextRight%d"

local TOOLTIP_WIDTH = 500
local INLINE_LENGTH = 26

local PROFILE_ADDONS = {
	["XRP"] = "XRP",
	["MYROLEPLAY"] = "MRP",
	["TOTALRP2"] = "TRP",
	["TOTALRP3"] = "TRP",
	["GNOMTEC_BADGE"] = "GTB",
	["FLAGRSP"] = "RSP",
	["FLAGRSP2"] = "RSP",
}
local EXTRA_ADDONS = {
	["GHI"] = "GHI",
	["TONGUES"] = "T",
}
local function ParseVersion(VA)
	if not VA then return end
	local short, hasProfile = {}
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
	return table.concat(short, PLAYER_LIST_DELIMITER)
end

local oldLines, lineNum = 0, 0
local function RenderLine(multiLine, left, right, lR, lG, lB, rR, rG, rB)
	if not left and not right then
		return
	elseif left == true then
		left = nil
	end
	local maxWidth = TOOLTIP_WIDTH / (left and right and 2 or 1)
	rendering = true
	lineNum = lineNum + 1
	local LeftLine = _G[GTTL:format(lineNum)]
	local RightLine = _G[GTTR:format(lineNum)]
	-- First case: If there's already a line to replace. This only happens if
	-- using the GameTooltip, as XRPTooltip is cleared before rendering starts.
	if lineNum <= oldLines then
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
			Tooltip:AddDoubleLine(left or " ", right, lR or 1, lG or 0.82, lB or 0, rR or 1, rG or 0.82, rB or 0)
		else
			Tooltip:AddLine(left or " ", lR or 1, lG or 0.82, lB or 0)
		end
	end
	if LeftLine:GetWidth() > maxWidth then
		LeftLine:SetWidth(maxWidth)
		if multiLine then
			LeftLine:SetMaxLines(3)
		else
			LeftLine:SetMaxLines(1)
		end
		maxLinesAdjusted[#maxLinesAdjusted + 1] = LeftLine
	end
	if RightLine:GetWidth() > maxWidth then
		RightLine:SetWidth(maxWidth)
		if multiLine then
			RightLine:SetMaxLines(3)
		else
			RightLine:SetMaxLines(1)
		end
		maxLinesAdjusted[#maxLinesAdjusted + 1] = RightLine
	end
	rendering = nil
end

local COLORS = {
	OOC = { r = 0.6, g = 0.4, b = 0.3 },
	IC = { r = 0.4, g = 0.7, b = 0.5 },
	Alliance = { r = 0.38, g = 0.42, b = 1.00},
	Horde = { r = 1.00, g = 0.38, b = 0.42},
	Neutral = FACTION_BAR_COLORS[4],
}
local NI_FORMAT = ("|cff6070a0%s|r %s"):format(STAT_FORMAT:format(xrp.L.FIELDS.NI), _xrp.L.NICKNAME)
local NI_FORMAT_NOQUOTE = ("|cff6070a0%s|r %s"):format(STAT_FORMAT:format(xrp.L.FIELDS.NI), "%s")
local CU_FORMAT = ("|cffa08050%s|r %%s"):format(STAT_FORMAT:format(xrp.L.FIELDS.CU))
local function RenderTooltip()
	oldLines = Tooltip:NumLines()
	lineNum = 0
	local showProfile = not (currentUnit.noProfile or currentUnit.character.hide)
	local fields = currentUnit.character.fields

	if currentUnit.type == "player" then
		if not replace then
			XRPTooltip:ClearLines()
			XRPTooltip:SetOwner(GameTooltip, "ANCHOR_TOPRIGHT")
			if currentUnit.character.hide then
				RenderLine(false, _xrp.L.HIDDEN, nil, 0.5, 0.5, 0.5)
				XRPTooltip:Show()
				return
			elseif (not showProfile or not fields.VA) then
				XRPTooltip:Hide()
				return
			end
		end
		RenderLine(false, currentUnit.nameFormat:format(showProfile and xrp.Strip(fields.NA) or xrp.ShortName(tostring(currentUnit.character))), currentUnit.icons)
		if replace and currentUnit.reaction then
			RenderLine(false, currentUnit.reaction, nil, 1, 1, 1)
		end
		if showProfile then
			local NI = xrp.Strip(fields.NI)
			RenderLine(false, NI and (not NI:find(_xrp.L.QUOTE_MATCH) and NI_FORMAT or NI_FORMAT_NOQUOTE):format(NI), nil, 0.6, 0.7, 0.9)
			RenderLine(true, xrp.Strip(fields.NT), nil, 0.8, 0.8, 0.8)
			if _xrp.settings.tooltipShowHouse then
				RenderLine(true, xrp.Strip(fields.NH), nil, 0.4, 0.6, 0.7)
			end
		end
		if _xrp.settings.tooltipShowExtraSpace then
			RenderLine(false, true)
		end
		if replace then
			RenderLine(false, currentUnit.guild, nil, 1, 1, 1)
			local color = COLORS[currentUnit.faction]
			RenderLine(false, currentUnit.titleRealm, currentUnit.character.hide and _xrp.L.HIDDEN or showProfile and ParseVersion(fields.VA), color.r, color.g, color.b, 0.5, 0.5, 0.5)
			if _xrp.settings.tooltipShowExtraSpace then
				RenderLine(false, true)
			end
		end
		if showProfile then
			local CU, CO = xrp.Strip(fields.CU), xrp.Strip(fields.CO)
			RenderLine(true, (CU or CO) and CU_FORMAT:format(xrp.MergeCurrently(xrp.Link(CU), xrp.Link(CO))), nil, 0.9, 0.7, 0.6)
		end
		local RA = showProfile and not _xrp.settings.tooltipHideRace and xrp.Strip(fields.RA) or xrp.L.VALUES.GR[fields.GR] or UNKNOWN
		local RAlen = #RA
		RA = AddOn_Chomp.SafeSubString(RA, 1, INLINE_LENGTH)
		if #RA < RAlen then
			RA = RA .. CONTINUED
		end
		local RC = showProfile and not _xrp.settings.tooltipHideClass and xrp.Strip(fields.RC) or xrp.L.VALUES.GC[fields.GS][fields.GC] or UNKNOWN
		local RClen = #RC
		RC = AddOn_Chomp.SafeSubString(RC, 1, INLINE_LENGTH)
		if #RC < RClen then
			RC = RC .. CONTINUED
		end
		RenderLine(false, currentUnit.info:format(RA, RC), not replace and ParseVersion(fields.VA), 1, 1, 1, 0.5, 0.5, 0.5)
		if showProfile then
			local FR, FC = xrp.Strip(fields.FR), xrp.Strip(fields.FC)
			local color = COLORS[FC == "1" and "OOC" or "IC"]
			RenderLine(false, xrp.L.VALUES.FR[FR] or FR ~= "0" and FR, xrp.L.VALUES.FC[FC] or FC ~= "0" and FC, color.r, color.g, color.b, color.r, color.g, color.b)
		end
		if replace then
			RenderLine(false, currentUnit.location, nil, 1, 1, 1)
		end
	elseif currentUnit.type == "pet" then
		RenderLine(false, currentUnit.nameFormat, currentUnit.icons)
		if currentUnit.reaction then
			RenderLine(false, currentUnit.reaction, nil, 1, 1, 1)
			if _xrp.settings.tooltipShowExtraSpace then
				RenderLine(false, true)
			end
		end
		local color = COLORS[currentUnit.faction]
		RenderLine(false, currentUnit.titleRealm:format(showProfile and xrp.Strip(fields.NA) or xrp.ShortName(tostring(currentUnit.character))), nil, color.r, color.g, color.b)
		RenderLine(false, currentUnit.info, nil, 1, 1, 1)
	end

	if replace then
		for i, line in ipairs(currentUnit.lines) do
			if line.double then
				RenderLine(false, unpack(line))
			else
				RenderLine(false, line[1], nil, unpack(line, 2))
			end
		end
		-- In rare cases (test case: target without RP addon, is PvP flagged)
		-- there will be some leftover lines at the end of the tooltip. This
		-- hides them, if they exist.
		while lineNum < oldLines do
			lineNum = lineNum + 1
			_G[GTTL:format(lineNum)]:Hide()
			_G[GTTR:format(lineNum)]:Hide()
		end
	end

	Tooltip:Show()
end

local active
local MERCENARY = {
	Alliance = "Horde",
	Horde = "Alliance",
}
local SELECTION_COLORS = setmetatable({
	["0000ff"] = RGBToColorCode(LIGHTBLUE_FONT_COLOR:GetRGB()), -- Blue
	["00ff00"] = RGBTableToColorCode(FACTION_BAR_COLORS[5]), -- Green
	["ff0000"] = RGBTableToColorCode(FACTION_BAR_COLORS[2]), -- Red
	["ff8000"] = RGBTableToColorCode(FACTION_BAR_COLORS[3]), -- Orange
	["ffff00"] = RGBTableToColorCode(FACTION_BAR_COLORS[4]), -- Yellow
}, {
	__index = function(self, hex)
		if hex ~= "ffff8b" then
			return "|cffffffff"
		end
		if UnitIsPVP("player") then
			return self["00ff00"]
		end
		return self["0000ff"]
	end,
})
local PVP_ICON = "|TInterface\\TargetingFrame\\UI-PVP-%s:18:18:4:0:8:8:0:5:0:5|t"
local FLAG_OFFLINE = (" |cff888888%s|r"):format(CHAT_FLAG_AFK:gsub(AFK, PLAYER_OFFLINE))
local FLAG_AFK = (" |cff99994d%s|r"):format(CHAT_FLAG_AFK)
local FLAG_DND = (" |cff994d4d%s|r"):format(CHAT_FLAG_DND)
local REACTION = "FACTION_STANDING_LABEL%d"
local LOCATION = ("|cffffeeaa%s|r %%s"):format(ZONE_COLON)
local UNITNAME_TITLE, UNITNAME_MATCH = {}, {}
for i = 1, 99 do
	local title = _G[("UNITNAME_SUMMON_TITLE%d"):format(i)]
	if not title then break end
	if title:find("%s", nil, true) and not title:find("^%%s$") then
		UNITNAME_TITLE[#UNITNAME_TITLE + 1] = title
		UNITNAME_MATCH[#UNITNAME_MATCH + 1] = title:format("(.+)")
	end
end
local PET_TITLE_CLASS = {
	[UNITNAME_SUMMON_TITLE1] = true,
	[UNITNAME_SUMMON_TITLE3] = true,
	[UNITNAME_SUMMON_TITLE4] = "SHAMAN",
	[UNITNAME_SUMMON_TITLE14] = "WARLOCK",
	[UNITNAME_SUMMON_TITLE16] = "MONK",
}
local PET_TYPE_CLASS = {
	[_xrp.L.PET_BEAST] = "HUNTER",
	[_xrp.L.PET_MECHANICAL] = "HUNTER",
	[_xrp.L.PET_UNDEAD] = "DEATHKNIGHT",
	[_xrp.L.PET_ELEMENTAL] = "MAGE",
	[_xrp.L.PET_DEMON] = "WARLOCK",
}
local function SetUnit(unit)
	currentUnit.type = UnitIsPlayer(unit) and "player" or replace and UnitPlayerControlled(unit) and not UnitIsBattlePet(unit) and "pet"
	if not currentUnit.type then return end

	local defaultLines = 3
	local playerFaction = UnitFactionGroup("player")
	if UnitIsMercenary("player") then
		playerFaction = MERCENARY[playerFaction]
	end
	local attackMe = UnitCanAttack(unit, "player")
	local meAttack = UnitCanAttack("player", unit)
	if currentUnit.type == "player" then
		currentUnit.character = xrp.characters.byUnit[unit]

		local inRaid = UnitInRaid(unit)

		currentUnit.faction = (inRaid or UnitIsUnit("player", unit)) and playerFaction or currentUnit.character.fields.GF or "Neutral"

		local connected = UnitIsConnected(unit)
		local r, g, b = UnitSelectionColor(unit)
		local color = SELECTION_COLORS[("%02x%02x%02x"):format(math.ceil(math.floor((r * 10) + 0.5) * 25.5), math.ceil(math.floor((g * 10) + 0.5) * 25.5), math.ceil(math.floor((b * 10) + 0.5) * 25.5))]

		local watchIcon = _xrp.settings.tooltipShowWatchEye and unit ~= "player" and UnitIsUnit("player", unit .. "target") and "|TInterface\\LFGFrame\\BattlenetWorking0:28:28:8:1|t"
		local bookmarkIcon = _xrp.settings.tooltipShowBookmarkFlag and currentUnit.character.bookmark and "|TInterface\\MINIMAP\\POIICONS:18:18:4:0:256:512:54:72:54:72|t"
		local GC = currentUnit.character.fields.GC

		if replace then
			local colorblind = GetCVarBool("colorblindMode")
			-- Can only ever be one of AFK, DND, or offline.
			local isAFK = connected and UnitIsAFK(unit)
			local isDND = connected and not isAFK and UnitIsDND(unit)
			currentUnit.nameFormat = ("%s%%s|r%s"):format(color, not connected and FLAG_OFFLINE or isAFK and FLAG_AFK or isDND and FLAG_DND or "")

			local ffa = UnitIsPVPFreeForAll(unit)
			local pvpIcon = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction)
			if watchIcon or pvpIcon or bookmarkIcon then
				currentUnit.icons = ("%s%s%s"):format(watchIcon or "", pvpIcon or "", bookmarkIcon or "")
			else
				currentUnit.icons = nil
			end

			local guildName, guildRank, guildIndex = GetGuildInfo(unit)
			currentUnit.guild = guildName and (_xrp.settings.tooltipShowGuildRank and (_xrp.settings.tooltipShowGuildIndex and _xrp.L.GUILD_RANK_INDEX or _xrp.L.GUILD_RANK) or _xrp.L.GUILD):format(_xrp.settings.tooltipShowGuildRank and guildRank or guildName, _xrp.settings.tooltipShowGuildIndex and guildIndex + 1 or guildName, guildName)

			local realm = tostring(currentUnit.character):match("%-([^%-]+)$")
			if realm == _xrp.realm then
				realm = nil
			end
			local name = UnitPVPName(unit) or xrp.ShortName(tostring(currentUnit.character))
			currentUnit.titleRealm = (colorblind and _xrp.L.ASIDE or "%s"):format(realm and _xrp.L.NAME_REALM:format(name, xrp.RealmDisplayName(realm)) or name, colorblind and xrp.L.VALUES.GF[currentUnit.faction])

			local GS = colorblind and currentUnit.character.fields.GS
			currentUnit.reaction = colorblind and GetText(REACTION:format(UnitReaction("player", unit)), tonumber(GS))

			local level = UnitLevel(unit)
			local effectiveLevel = UnitEffectiveLevel(unit)
			level = effectiveLevel == level and (level < 1 and _xrp.L.LETHAL_LEVEL or tostring(level)) or effectiveLevel < 1 and tostring(level) or EFFECTIVE_LEVEL_FORMAT:format(tostring(effectiveLevel), tostring(level))
			currentUnit.info = (TOOLTIP_UNIT_LEVEL_RACE_CLASS_TYPE):format(level, "%s", ("|c%s%%s|r"):format(RAID_CLASS_COLORS[GC] and RAID_CLASS_COLORS[GC].colorStr or "ffffffff"), colorblind and xrp.L.VALUES.GC[GS][GC] or PLAYER)

			local location = connected and not UnitIsVisible(unit) and GameTooltipTextLeft3:GetText()
			currentUnit.location = location and LOCATION:format(location)

			if pvpIcon then
				defaultLines = defaultLines + 1
			end
			if guildName then
				defaultLines = defaultLines + 1
			end
			if colorblind and currentUnit.reaction then
				defaultLines = defaultLines + 1
			end
		else
			currentUnit.nameFormat = ("%s%%s|r"):format(color)
			if watchIcon or bookmarkIcon then
				currentUnit.icons = (watchIcon or "") .. (bookmarkIcon or "")
			else
				currentUnit.icons = nil
			end
			currentUnit.info = ("%%s |c%s%%s|r"):format(RAID_CLASS_COLORS[GC] and RAID_CLASS_COLORS[GC].colorStr or "ffffffff")
		end
	elseif currentUnit.type == "pet" then
		local colorblind = GetCVarBool("colorblindMode")
		local ownership = _G[GTTL:format(colorblind and 3 or 2)]:GetText()
		if not ownership then return end
		local owner, petLabel
		for i, pattern in ipairs(UNITNAME_MATCH) do
			owner = ownership:match(pattern)
			if owner then
				petLabel = UNITNAME_TITLE[i]
				break
			end
		end

		if not owner or not petLabel then return end

		currentUnit.character = xrp.characters.byName[owner]

		local isOwnPet = UnitIsUnit(unit, "playerpet") or owner == _xrp.player
		currentUnit.faction = UnitFactionGroup(unit) or isOwnPet and playerFaction or currentUnit.character.fields.GF or "Neutral"

		local name = UnitName(unit)
		local r, g, b = UnitSelectionColor(unit)
		local color = SELECTION_COLORS[("%02x%02x%02x"):format(math.ceil(r * 255), math.ceil(g * 255), math.ceil(b * 255))]
		currentUnit.nameFormat = ("%s%s|r"):format(color, name)

		local ffa = UnitIsPVPFreeForAll(unit)
		currentUnit.icons = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction)

		local race = UnitCreatureFamily(unit)
		local creatureType = UnitCreatureType(unit)
		local GC = (isOwnPet or UnitIsOtherPlayersPet(unit)) and PET_TITLE_CLASS[petLabel] == true and PET_TYPE_CLASS[creatureType] or PET_TITLE_CLASS[petLabel]

		if race == _xrp.L.PET_GHOUL then
			race = creatureType
		elseif name == _xrp.L.PET_NAME_RISEN_SKULKER then
			GC = "DEATHKNIGHT"
		elseif name == _xrp.L.PET_NAME_HATI then
			GC = "HUNTER"
		elseif GC == "HUNTER" and not race or GC == "MAGE" and race ~= _xrp.L.PET_WATER_ELEMENTAL or UnitIsCharmed(unit) then
			GC = nil
		end

		local realm = owner:match("%-([^%-]+)$")
		currentUnit.titleRealm = (colorblind and _xrp.L.ASIDE or "%s"):format(realm and _xrp.L.NAME_REALM:format(petLabel, xrp.RealmDisplayName(realm)) or petLabel, colorblind and xrp.L.VALUES.GF[currentUnit.faction])

		currentUnit.reaction = colorblind and GetText(REACTION:format(UnitReaction("player", unit)), UnitSex(unit))

		local level = UnitLevel(unit)
		local effectiveLevel = UnitEffectiveLevel(unit)
		level = effectiveLevel == level and (level < 1 and _xrp.L.LETHAL_LEVEL or tostring(level)) or effectiveLevel < 1 and tostring(level) or EFFECTIVE_LEVEL_FORMAT:format(tostring(effectiveLevel), tostring(level))
		currentUnit.info = TOOLTIP_UNIT_LEVEL_CLASS_TYPE:format(level, GC and ("|c%s%s|r"):format(RAID_CLASS_COLORS[GC] and RAID_CLASS_COLORS[GC].colorStr or "ffffffff", race or creatureType or UNKNOWN) or race or creatureType or UNKNOWN, colorblind and GC and ("%s %s"):format(xrp.L.VALUES.GC[currentUnit.character.fields.GS][GC], PET) or PET)

		if currentUnit.icons then
			defaultLines = defaultLines + 1
		end
		if colorblind then
			defaultLines = defaultLines + 1
		end
	end
	currentUnit.noProfile = _xrp.settings.tooltipHideInstanceCombat and InCombatLockdown() and (IsInInstance() or IsInActiveWorldPVP()) or _xrp.settings.tooltipHideOppositeFaction and currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or _xrp.settings.tooltipHideHostile and attackMe and meAttack

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

local function Tooltip_RECEIVE(event, name)
	if not active or name ~= tostring(currentUnit.character) then return end
	local tooltip, unit = GameTooltip:GetUnit()
	if tooltip then
		RenderTooltip()
		-- If the mouse has already left the unit, the tooltip will get stuck
		-- visible. This bounces it back into visibility if it's partly faded
		-- out, but it'll just fade again.
		if replace and not GameTooltip:IsUnit("mouseover") then
			Tooltip:FadeOut()
		end
	end
end

local enabled
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

local function GameTooltip_OnTooltipCleared_Hook(self)
	active = nil
	for i, line in ipairs(maxLinesAdjusted) do
		line:SetMaxLines(0)
	end
	table.wipe(maxLinesAdjusted)
	if not replace then
		Tooltip:Hide()
	end
end

local function NoUnit()
	-- GameTooltip:GetUnit() will sometimes return nil, especially when custom
	-- unit frames call GameTooltip:SetUnit() with something 'odd' like
	-- targettarget. By the next frame draw, the tooltip will correctly be able
	-- to identify such units (usually as mouseover).
	local tooltip, unit = GameTooltip:GetUnit()
	if not unit then return end
	SetUnit(unit)
end

local function GameTooltip_OnTooltipSetUnit_Hook(self)
	if not enabled then return end
	local tooltip, unit = self:GetUnit()
	if not unit then
		C_Timer.After(0, NoUnit)
	else
		SetUnit(unit)
	end
end

local function DoHooks()
	GameTooltip:HookScript("OnTooltipSetUnit", GameTooltip_OnTooltipSetUnit_Hook)
	GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared_Hook)
end

_xrp.settingsToggles.tooltipEnabled = function(setting)
	if setting then
		if enabled == nil then
			if not IsLoggedIn() then
				_xrp.HookGameEvent("PLAYER_LOGIN", DoHooks)
			else
				DoHooks()
			end
		end
		xrp.HookEvent("RECEIVE", Tooltip_RECEIVE)
		enabled = true
		_xrp.settingsToggles.tooltipReplace(_xrp.settings.tooltipReplace)
	elseif enabled ~= nil then
		enabled = false
		xrp.UnhookEvent("RECEIVE", Tooltip_RECEIVE)
	end
end

_xrp.settingsToggles.tooltipReplace = function(setting)
	if not enabled then return end
	if setting then
		if replace == nil then
			hooksecurefunc(GameTooltip, "AddLine", GameTooltip_AddLine_Hook)
			hooksecurefunc(GameTooltip, "AddDoubleLine", GameTooltip_AddDoubleLine_Hook)
		end
		Tooltip = GameTooltip
		replace = true
	else
		if not XRPTooltip then
			CreateFrame("GameTooltip", "XRPTooltip", GameTooltip, "GameTooltipTemplate")
		end
		Tooltip = XRPTooltip
		if replace ~= nil then
			replace = false
		end
	end
end
