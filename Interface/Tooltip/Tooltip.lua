--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local Names, Values = AddOn_XRP.Strings.Names, AddOn_XRP.Strings.Values
local ShortNames = AddOn_XRP.Strings.ShortNames

local currentUnit = {
	lines = {},
}

local maxLinesAdjusted = {}

local Tooltip, replace, rendering

local GTTL, GTTR = "GameTooltipTextLeft%d", "GameTooltipTextRight%d"
local XTTL, XTTR = "XRPTooltipTextLeft%d", "XRPTooltipTextRight%d"

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
local function RenderLine(multiLine, leftRatio, left, right, lR, lG, lB, rR, rG, rB)
	if not left and not right then
		return
	elseif left == true then
		left = nil
	end
	if left then
		left = left:gsub("%s+", " ")
	end
	if right then
		right = right:gsub("%s+", " ")
	end
	if not leftRatio then
		leftRatio = 0.5
	end
	local leftMax = AddOn.Settings.tooltipMaxWidth * (left and right and leftRatio or 1)
	local rightMax = AddOn.Settings.tooltipMaxWidth * (left and right and (1 - leftRatio) or 1)
	rendering = true
	lineNum = lineNum + 1
	local LeftLine = replace and _G[GTTL:format(lineNum)] or _G[XTTL:format(lineNum)]
	local RightLine = replace and _G[GTTR:format(lineNum)] or _G[XTTR:format(lineNum)]
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
	if LeftLine:GetWidth() > leftMax then
		LeftLine:SetWidth(leftMax)
		if multiLine then
			LeftLine:SetMaxLines(AddOn.Settings.tooltipMaxMultiLines)
		else
			LeftLine:SetMaxLines(1)
		end
		maxLinesAdjusted[#maxLinesAdjusted + 1] = LeftLine
	end
	if RightLine:GetWidth() > rightMax then
		RightLine:SetWidth(rightMax)
		if multiLine then
			RightLine:SetMaxLines(AddOn.Settings.tooltipMaxMultiLines)
		else
			RightLine:SetMaxLines(1)
		end
		maxLinesAdjusted[#maxLinesAdjusted + 1] = RightLine
	end
	rendering = nil
end

local COLORS = {
	OOC = CreateColor(0.6, 0.4, 0.3),
	IC = CreateColor(0.4, 0.7, 0.5),
	CU = CreateColor(0.9, 0.7, 0.6),
	CU_LABEL = CreateColor(0.63, 0.5, 0.31),
	CO = CreateColor(0.6, 0.6, 0.6),
	CO_LABEL = CreateColor(0.4, 0.4, 0.4),
	Alliance = CreateColor( 0.38, 0.42, 1.00),
	Horde = CreateColor(1.00, 0.38, 0.42),
	Neutral = CreateColor(FACTION_BAR_COLORS[4].r, FACTION_BAR_COLORS[4].g, FACTION_BAR_COLORS[4].b),
}
local NI_FORMAT = ("|cff6070a0%s|r %s"):format(STAT_FORMAT:format(Names.NI), L.NICKNAME)
local NI_FORMAT_NOQUOTE = ("|cff6070a0%s|r %s"):format(STAT_FORMAT:format(Names.NI), "%s")
local CU_FORMAT = COLORS.CU_LABEL:WrapTextInColorCode(STAT_FORMAT:format(Names.CU)) .. " %s"
local CO_FORMAT = COLORS.CO_LABEL:WrapTextInColorCode(STAT_FORMAT:format(ShortNames.CO)) .. " %s"
local function RenderTooltip()
	oldLines = Tooltip:NumLines()
	lineNum = 0
	local character = currentUnit.character
	local showProfile = not (currentUnit.noProfile or character.hidden)

	if currentUnit.type == "player" then
		if not replace then
			XRPTooltip:ClearLines()
			XRPTooltip:SetOwner(GameTooltip, "ANCHOR_TOPRIGHT")
			if character.hidden then
				RenderLine(false, 1, L.HIDDEN, nil, 0.5, 0.5, 0.5)
				XRPTooltip:Show()
				return
			elseif (not showProfile or not character.hasProfile) then
				XRPTooltip:Hide()
				return
			end
		end
		local PX, NA = character.PX, character.NA
		if PX then
			NA = ("%s %s"):format(PX, NA)
		end
		RenderLine(false, 0.75, currentUnit.nameFormat:format(showProfile and AddOn_XRP.RemoveTextFormats(NA) or character.name), currentUnit.icons)
		if replace and currentUnit.reaction then
			RenderLine(false, nil, currentUnit.reaction, nil, 1, 1, 1)
		end
		if showProfile then
			local NI = AddOn_XRP.RemoveTextFormats(character.NI)
			RenderLine(false, nil,  NI and (not NI:find(L.QUOTE_MATCH) and NI_FORMAT or NI_FORMAT_NOQUOTE):format(NI), nil, 0.6, 0.7, 0.9)
			RenderLine(true, nil, AddOn_XRP.RemoveTextFormats(character.NT), nil, 0.8, 0.8, 0.8)
			if AddOn.Settings.tooltipShowHouse then
				RenderLine(true, nil, AddOn_XRP.RemoveTextFormats(character.NH), nil, 0.4, 0.6, 0.7)
			end
		end
		if AddOn.Settings.tooltipShowExtraSpace then
			RenderLine(false, nil, true)
		end
		if replace then
			RenderLine(false, nil, currentUnit.guild, nil, 1, 1, 1)
			local color = COLORS[currentUnit.faction]
			RenderLine(false, 0.75, currentUnit.titleRealm, character.hidden and L.HIDDEN or showProfile and ParseVersion(character.VA), color.r, color.g, color.b, 0.5, 0.5, 0.5)
			if AddOn.Settings.tooltipShowExtraSpace then
				RenderLine(false, nil, true)
			end
		end
		if showProfile then
			local CU = AddOn.LinkURLs(AddOn_XRP.RemoveTextFormats(character.CU))
			RenderLine(true, nil, CU and CU_FORMAT:format(CU), nil, COLORS.CU.r, COLORS.CU.g, COLORS.CU.b)
			local CO = AddOn.LinkURLs(AddOn_XRP.RemoveTextFormats(character.CO))
			CO = CO and CO_FORMAT:format(CO) or nil
			RenderLine(true, nil, CO, nil, COLORS.CO.r, COLORS.CO.g, COLORS.CO.b)
		end
		local inlineLength = math.ceil(AddOn.Settings.tooltipMaxWidth / 15)
		local RA = showProfile and not AddOn.Settings.tooltipHideRace and AddOn_XRP.RemoveTextFormats(character.RA) or Values.GR[character.GR] or UNKNOWN
		local RAlen = #RA
		RA = AddOn_Chomp.SafeSubString(RA, 1, inlineLength)
		if #RA < RAlen then
			RA = RA .. CONTINUED
		end
		local RC = showProfile and not AddOn.Settings.tooltipHideClass and AddOn_XRP.RemoveTextFormats(character.RC) or Values.GC[character.GS][character.GC] or UNKNOWN
		local RClen = #RC
		RC = AddOn_Chomp.SafeSubString(RC, 1, inlineLength)
		if #RC < RClen then
			RC = RC .. CONTINUED
		end
		RenderLine(false, nil, currentUnit.info:format(RA, RC), not replace and ParseVersion(character.VA), 1, 1, 1, 0.5, 0.5, 0.5)
		if showProfile then
			local FR, FC = AddOn_XRP.RemoveTextFormats(character.FR), AddOn_XRP.RemoveTextFormats(character.FC)
			local color = COLORS[FC == "1" and "OOC" or "IC"]
			RenderLine(false, 0.5, Values.FR[FR] or FR ~= "0" and FR, Values.FC[FC] or FC ~= "0" and FC, color.r, color.g, color.b, color.r, color.g, color.b)
		end
		if replace then
			RenderLine(false, nil, currentUnit.location, nil, 1, 1, 1)
		end
	elseif currentUnit.type == "pet" then
		RenderLine(false, 0.75, currentUnit.nameFormat, currentUnit.icons)
		if currentUnit.reaction then
			RenderLine(false, nil, currentUnit.reaction, nil, 1, 1, 1)
			if AddOn.Settings.tooltipShowExtraSpace then
				RenderLine(false, nil, true)
			end
		end
		local color = COLORS[currentUnit.faction]
		RenderLine(false, nil, currentUnit.titleRealm:format(showProfile and AddOn_XRP.RemoveTextFormats(character.NA) or character.name), nil, color.r, color.g, color.b)
		RenderLine(false, nil, currentUnit.info, nil, 1, 1, 1)
	end

	if replace then
		for i, line in ipairs(currentUnit.lines) do
			if line.double then
				RenderLine(false, nil, unpack(line))
			else
				RenderLine(false, nil, line[1], nil, unpack(line, 2))
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
		if hex ~= "ffff80" then
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
	if title:find("%s", nil, true) and title ~= "%s" then
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
	[L.PET_BEAST] = "HUNTER",
	[L.PET_MECHANICAL] = "HUNTER",
	[L.PET_UNDEAD] = "DEATHKNIGHT",
	[L.PET_ELEMENTAL] = "MAGE",
	[L.PET_DEMON] = "WARLOCK",
}
local function SetUnit(unit)
	local character = AddOn_XRP.Characters.byUnit[unit]
	currentUnit.type = character and "player" or replace and UnitPlayerControlled(unit) and not UnitIsBattlePet(unit) and "pet"
	if not currentUnit.type then return end

	local defaultLines = 3
	local playerFaction = UnitFactionGroup("player")
	if UnitIsMercenary("player") then
		playerFaction = MERCENARY[playerFaction]
	end
	local attackMe = UnitCanAttack(unit, "player")
	local meAttack = UnitCanAttack("player", unit)
	if currentUnit.type == "player" then
		currentUnit.character = character

		local inRaid = UnitInRaid(unit)

		currentUnit.faction = (inRaid or UnitIsUnit("player", unit)) and playerFaction or character.GF or "Neutral"

		local connected = UnitIsConnected(unit)
		local r, g, b = UnitSelectionColor(unit)
		local color = SELECTION_COLORS[("%02x%02x%02x"):format(math.ceil(math.floor((r * 10) + 0.5) * 25.5), math.ceil(math.floor((g * 10) + 0.5) * 25.5), math.ceil(math.floor((b * 10) + 0.5) * 25.5))]

		local watchIcon = AddOn.Settings.tooltipShowWatchEye and unit ~= "player" and UnitIsUnit("player", unit .. "target") and "|TInterface\\LFGFrame\\BattlenetWorking0:28:28:8:1|t"
		local bookmarkIcon = AddOn.Settings.tooltipShowBookmarkFlag and character.bookmark and "|TInterface\\MINIMAP\\POIICONS:18:18:4:0:256:512:54:72:54:72|t"
		local GC = character.GC

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
			currentUnit.guild = guildName and (AddOn.Settings.tooltipShowGuildRank and (AddOn.Settings.tooltipShowGuildIndex and L.GUILD_RANK_INDEX or L.GUILD_RANK) or L.GUILD):format(AddOn.Settings.tooltipShowGuildRank and guildRank or guildName, AddOn.Settings.tooltipShowGuildIndex and guildIndex + 1 or guildName, guildName)

			local name = UnitPVPName(unit) or character.name
			local realm = character.realm
			if realm == AddOn.characterRealm then
				realm = nil
			end
			currentUnit.titleRealm = (colorblind and L.ASIDE or "%s"):format(realm and L.NAME_REALM:format(name, realm) or name, colorblind and Values.GF[currentUnit.faction])

			local GS = colorblind and character.GS
			currentUnit.reaction = colorblind and GetText(REACTION:format(UnitReaction("player", unit)), tonumber(GS))

			local level = UnitLevel(unit)
			local effectiveLevel = UnitEffectiveLevel(unit)
			level = effectiveLevel == level and (level < 1 and L.LETHAL_LEVEL or tostring(level)) or effectiveLevel < 1 and tostring(level) or EFFECTIVE_LEVEL_FORMAT:format(tostring(effectiveLevel), tostring(level))
			currentUnit.info = (TOOLTIP_UNIT_LEVEL_RACE_TYPE):format(level, "%s " .. (RAID_CLASS_COLORS[GC] and RAID_CLASS_COLORS[GC]:WrapTextInColorCode("%s") or "%s"), colorblind and Values.GC[GS][GC] or PLAYER)

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

		character = AddOn_XRP.Characters.byName[owner]
		currentUnit.character = character

		local isOwnPet = UnitIsUnit(unit, "playerpet") or owner == AddOn.characterName
		currentUnit.faction = UnitFactionGroup(unit) or isOwnPet and playerFaction or character.GF or "Neutral"

		local name = UnitName(unit)
		local r, g, b, a = UnitSelectionColor(unit)
		local color = SELECTION_COLORS[("%02x%02x%02x"):format(math.ceil(math.floor((r * 10) + 0.5) * 25.5), math.ceil(math.floor((g * 10) + 0.5) * 25.5), math.ceil(math.floor((b * 10) + 0.5) * 25.5))]
		currentUnit.nameFormat = ("%s%s|r"):format(color, name)

		local ffa = UnitIsPVPFreeForAll(unit)
		currentUnit.icons = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction)

		local race = UnitCreatureFamily(unit)
		local creatureType = UnitCreatureType(unit)
		local GC = (isOwnPet or UnitIsOtherPlayersPet(unit)) and PET_TITLE_CLASS[petLabel] == true and PET_TYPE_CLASS[creatureType] or PET_TITLE_CLASS[petLabel]

		if race == L.PET_GHOUL then
			race = creatureType
		elseif name == L.PET_NAME_RISEN_SKULKER then
			GC = "DEATHKNIGHT"
		elseif name == L.PET_NAME_HATI then
			GC = "HUNTER"
		elseif GC == "HUNTER" and not race or GC == "MAGE" and race ~= L.PET_WATER_ELEMENTAL or UnitIsCharmed(unit) then
			GC = nil
		end

		local realm = owner:match("%-([^%-]+)$")
		currentUnit.titleRealm = (colorblind and L.ASIDE or "%s"):format(realm and L.NAME_REALM:format(petLabel, character.realm) or petLabel, colorblind and Values.GF[currentUnit.faction])

		currentUnit.reaction = colorblind and GetText(REACTION:format(UnitReaction("player", unit)), UnitSex(unit))

		local level = UnitLevel(unit)
		local effectiveLevel = UnitEffectiveLevel(unit)
		level = effectiveLevel == level and (level < 1 and L.LETHAL_LEVEL or tostring(level)) or effectiveLevel < 1 and tostring(level) or EFFECTIVE_LEVEL_FORMAT:format(tostring(effectiveLevel), tostring(level))
		currentUnit.info = TOOLTIP_UNIT_LEVEL_RACE_TYPE:format(level, GC and ("|c%s%s|r"):format(RAID_CLASS_COLORS[GC] and RAID_CLASS_COLORS[GC].colorStr or "ffffffff", race or creatureType or UNKNOWN) or race or creatureType or UNKNOWN, colorblind and GC and ("%s %s"):format(Values.GC[character.GS][GC], PET) or PET)

		if currentUnit.icons then
			defaultLines = defaultLines + 1
		end
		if colorblind then
			defaultLines = defaultLines + 1
		end
	end
	currentUnit.noProfile = AddOn.Settings.tooltipHideInstanceCombat and InCombatLockdown() and (IsInInstance() or IsInActiveWorldPVP()) or AddOn.Settings.tooltipHideOppositeFaction and currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or AddOn.Settings.tooltipHideHostile and attackMe and meAttack

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
	if not active or name ~= currentUnit.character.id then return end
	local _, unit, guid = TooltipUtil.GetDisplayedUnit(GameTooltip)
	if guid then
		RenderTooltip()
		-- If the mouse has already left the unit, the tooltip will get stuck
		-- visible. This bounces it back into visibility if it's partly faded
		-- out, but it'll just fade again.
		if replace and unit ~= "mouseover" then
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
	if not enabled then return end
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
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, GameTooltip_OnTooltipSetUnit_Hook)
	GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared_Hook)
end

AddOn.SettingsToggles.tooltipEnabled = function(setting)
	if setting then
		if enabled == nil then
			if not IsLoggedIn() then
				AddOn.RegisterGameEventCallback("PLAYER_LOGIN", DoHooks)
			else
				DoHooks()
			end
		end
		AddOn_XRP.RegisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", Tooltip_RECEIVE)
		enabled = true
		AddOn.SettingsToggles.tooltipReplace(AddOn.Settings.tooltipReplace)
	elseif enabled ~= nil then
		enabled = false
		AddOn_XRP.UnregisterEventCallback("ADDON_XRP_PROFILE_RECEIVED", Tooltip_RECEIVE)
	end
end

AddOn.SettingsToggles.tooltipReplace = function(setting)
	if not enabled then return end
	if Tooltip then
		GameTooltip:Hide()
	end
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
