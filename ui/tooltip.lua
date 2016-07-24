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

local addonName, _xrp = ...

local currentUnit = {
	lines = {},
}

local Tooltip, replace, rendering

local GTTL, GTTR = "GameTooltipTextLeft%d", "GameTooltipTextRight%d"

local RenderTooltip
do
	local TruncateLine
	do
		local SINGLE, DOUBLE = "%s", "%s\n%s"
		local SINGLE_TRUNC, DOUBLE_TRUNC = ("%s|r%s"):format(SINGLE, CONTINUED), ("%s|r%s"):format(DOUBLE, CONTINUED)
		function TruncateLine(text, length, offset, double)
			if not text then return end
			if not offset then offset = 0 end
			text = text:gsub("\n+", " ")
			local textLen = strlenutf8(text)
			local line1, line2 = text
			local isTruncated = false
			if textLen > length - offset then
				local nextText = text:match("(.-) ")
				if nextText and strlenutf8(nextText) <= length - offset then
					local position = #nextText
					local nextPos = text:find(" ", position + 1, true)
					while nextPos and strlenutf8(nextText) <= length - offset do
						position = nextPos
						nextPos = text:find(" ", nextPos + 1, true)
						nextText = nextPos and text:sub(1, nextPos - 1)
					end
					line1 = text:sub(1, position - 1)
					if double ~= false then
						local lineLen, linePos = strlenutf8(line1), position + 1
						if textLen - lineLen > lineLen + offset then
							nextPos = text:find(" ", linePos, true)
							nextText = nextPos and text:sub(linePos, nextPos - 1)
							while nextPos and strlenutf8(nextText) <= lineLen + offset - 3 do
								position = nextPos
								nextPos = text:find(" ", nextPos + 1, true)
								nextText = nextPos and text:sub(linePos, nextPos - 1)
							end
							if position > linePos then
								line2 = text:sub(linePos, position - 1)
							end
							isTruncated = true
						else
							line2 = text:sub(linePos)
						end
					else
						isTruncated = true
					end
				else
					local chars = {}
					for char in text:gmatch("[\1-\127\192-\255][\128-\191]*") do
						chars[#chars + 1] = char
					end
					local line1t = {}
					for i = 1, length - offset do
						line1t[i] = chars[i]
					end
					line1 = table.concat(line1t)
					if double ~= false then
						local line2t = {}
						for i = #line1t + 1, #line1t * 2 + offset - 3 do
							line2t[#line2t + 1] = chars[i]
						end
						line2 = table.concat(line2t)
						if #chars > #line1t + #line2t then
							isTruncated = true
						end
					else
						isTruncated = true
					end
				end
			end
			return (line2 and (isTruncated and DOUBLE_TRUNC or DOUBLE) or isTruncated and SINGLE_TRUNC or SINGLE):format(line1, line2)
		end
	end

	local ParseVersion
	do
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
		function ParseVersion(VA)
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
	end

	local oldLines, lineNum = 0, 0
	local function RenderLine(left, right, lR, lG, lB, rR, rG, rB)
		if not left and not right then
			return
		elseif left == true then
			left = nil
		end
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
				Tooltip:AddDoubleLine(left or " ", right, lR or 1, lG or 0.82, lB or 0, rR or 1, rG or 0.82, rB or 0)
			else
				Tooltip:AddLine(left or " ", lR or 1, lG or 0.82, lB or 0)
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
	local NI_FORMAT = ("|cff6070a0%s|r %s"):format(STAT_FORMAT:format(xrp.L.FIELDS.NI), _xrp.L.NICKNAME)
	local NI_FORMAT_NOQUOTE = ("|cff6070a0%s|r %s"):format(STAT_FORMAT:format(xrp.L.FIELDS.NI), "%s")
	local CU_FORMAT = ("|cffa08050%s|r %%s"):format(STAT_FORMAT:format(xrp.L.FIELDS.CU))
	local NI_LENGTH = strlenutf8(NI_FORMAT) - 14
	local CU_LENGTH = strlenutf8(CU_FORMAT) - 14
	function RenderTooltip()
		oldLines = Tooltip:NumLines()
		lineNum = 0
		local showProfile = not (currentUnit.noProfile or currentUnit.character.hide)
		local fields = currentUnit.character.fields

		if currentUnit.type == "player" then
			if not replace then
				XRPTooltip:ClearLines()
				XRPTooltip:SetOwner(GameTooltip, "ANCHOR_TOPRIGHT")
				if currentUnit.character.hide then
					RenderLine(_xrp.L.HIDDEN, nil, 0.5, 0.5, 0.5)
					XRPTooltip:Show()
					return
				elseif (not showProfile or not fields.VA) then
					XRPTooltip:Hide()
					return
				end
			end
			RenderLine(currentUnit.nameFormat:format(showProfile and TruncateLine(xrp.Strip(fields.NA), 65, 0, false) or xrp.ShortName(tostring(currentUnit.character))), currentUnit.icons)
			if replace and currentUnit.reaction then
				RenderLine(currentUnit.reaction, nil, 1, 1, 1)
			end
			if showProfile then
				local NI = xrp.Strip(fields.NI)
				RenderLine(NI and (not NI:find(_xrp.L.QUOTE_MATCH) and NI_FORMAT or NI_FORMAT_NOQUOTE):format(TruncateLine(NI, 70, NI_LENGTH, false)), nil, 0.6, 0.7, 0.9)
				RenderLine(TruncateLine(xrp.Strip(fields.NT), 70), nil, 0.8, 0.8, 0.8)
			end
			if _xrp.settings.tooltip.extraSpace then
				RenderLine(true)
			end
			if replace then
				RenderLine(currentUnit.guild, nil, 1, 1, 1)
				local color = COLORS[currentUnit.faction]
				RenderLine(currentUnit.titleRealm, currentUnit.character.hide and _xrp.L.HIDDEN or showProfile and ParseVersion(fields.VA), color.r, color.g, color.b, 0.5, 0.5, 0.5)
				if _xrp.settings.tooltip.extraSpace then
					RenderLine(true)
				end
			end
			if showProfile then
				local CU = xrp.Strip(fields.CU)
				local CO = xrp.Strip(fields.CO)
				RenderLine((CU or CO) and CU_FORMAT:format(xrp.Link(TruncateLine(xrp.MergeCurrently(xrp.Link(CU, "prelink"), xrp.Link(CO, "prelink")), 70, CU_LENGTH), "fakelink")), nil, 0.9, 0.7, 0.6)
			end
			RenderLine(currentUnit.info:format(showProfile and not _xrp.settings.tooltip.noRace and TruncateLine(xrp.Strip(fields.RA), 40, 0, false) or xrp.L.VALUES.GR[fields.GR] or UNKNOWN, showProfile and not _xrp.settings.tooltip.noClass and TruncateLine(xrp.Strip(fields.RC), 40, 0, false) or xrp.L.VALUES.GC[fields.GS][fields.GC] or UNKNOWN), not replace and ParseVersion(fields.VA), 1, 1, 1, 0.5, 0.5, 0.5)
			if showProfile then
				local FR, FC = xrp.Strip(fields.FR), xrp.Strip(fields.FC)
				local color = COLORS[FC == "1" and "OOC" or "IC"]
				RenderLine(xrp.L.VALUES.FR[FR] or FR ~= "0" and TruncateLine(FR, 35, 0, false), xrp.L.VALUES.FC[FC] or FC ~= "0" and TruncateLine(FC, 35, 0, false), color.r, color.g, color.b, color.r, color.g, color.b)
			end
			if replace then
				RenderLine(currentUnit.location, nil, 1, 1, 1)
			end
		elseif currentUnit.type == "pet" then
			RenderLine(currentUnit.nameFormat, currentUnit.icons)
			if currentUnit.reaction then
				RenderLine(currentUnit.reaction, nil, 1, 1, 1)
				if _xrp.settings.tooltip.extraSpace then
					RenderLine(true)
				end
			end
			local color = COLORS[currentUnit.faction]
			RenderLine(currentUnit.titleRealm:format(showProfile and TruncateLine(xrp.Strip(fields.NA), 60, 0, false) or xrp.ShortName(tostring(currentUnit.character))), nil, color.r, color.g, color.b)
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

		Tooltip:Show()
	end
end

local SetUnit, active
do
	local MERCENARY = {
		Alliance = "Horde",
		Horde = "Alliance",
	}
	local COLORS = {
		friendly = "00991a",
		neutral = "e6b300",
		hostile = "cc4d38",
	}
	local PVP_ICON = "|TInterface\\TargetingFrame\\UI-PVP-%s:18:18:4:0:8:8:0:5:0:5|t"
	local FLAG_OFFLINE = (" |cff888888%s|r"):format(CHAT_FLAG_AFK:gsub(AFK, PLAYER_OFFLINE))
	local FLAG_AFK = (" |cff99994d%s|r"):format(CHAT_FLAG_AFK)
	local FLAG_DND = (" |cff994d4d%s|r"):format(CHAT_FLAG_DND)
	local REACTION = "FACTION_STANDING_LABEL%d"
	local LOCATION = ("|cffffeeaa%s|r %%s"):format(ZONE_COLON)
	function SetUnit(unit)
		currentUnit.type = UnitIsPlayer(unit) and "player" or replace and (UnitIsOtherPlayersPet(unit) or UnitIsUnit("playerpet", unit)) and "pet"
		if not currentUnit.type then return end

		local defaultLines = 3
		local playerFaction = xrp.current.GF
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
			local color = COLORS[(not inRaid and UnitIsEnemy("player", unit) or attackMe and meAttack) and "hostile" or (meAttack or attackMe) and "neutral" or "friendly"]
			local watchIcon = _xrp.settings.tooltip.watching and UnitIsUnit("player", unit .. "target") and "|TInterface\\LFGFrame\\BattlenetWorking0:28:28:8:1|t"
			local bookmarkIcon = _xrp.settings.tooltip.bookmark and currentUnit.character.bookmark and "|TInterface\\MINIMAP\\POIICONS:18:18:4:0:256:512:54:72:54:72|t"
			local GC = currentUnit.character.fields.GC

			if replace then
				local colorblind = GetCVar("colorblindMode") == "1"
				-- Can only ever be one of AFK, DND, or offline.
				local isAFK = connected and UnitIsAFK(unit)
				local isDND = connected and not isAFK and UnitIsDND(unit)
				currentUnit.nameFormat = ("|cff%s%%s|r%s"):format(color, not connected and FLAG_OFFLINE or isAFK and FLAG_AFK or isDND and FLAG_DND or "")

				local ffa = UnitIsPVPFreeForAll(unit)
				local pvpIcon = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction)
				if watchIcon or pvpIcon or bookmarkIcon then
					currentUnit.icons = ("%s%s%s"):format(watchIcon or "", pvpIcon or "", bookmarkIcon or "")
				else
					currentUnit.icons = nil
				end

				local guildName, guildRank, guildIndex = GetGuildInfo(unit)
				currentUnit.guild = guildName and (_xrp.settings.tooltip.guildRank and (_xrp.settings.tooltip.guildIndex and _xrp.L.GUILD_RANK_INDEX or _xrp.L.GUILD_RANK) or _xrp.L.GUILD):format(_xrp.settings.tooltip.guildRank and guildRank or guildName, _xrp.settings.tooltip.guildIndex and guildIndex + 1 or guildName, guildName)

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
				level = effectiveLevel == level and tostring(level) or effectiveLevel < 1 and tostring(level) or EFFECTIVE_LEVEL_FORMAT:format(tostring(effectiveLevel), tostring(level))
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
				currentUnit.nameFormat = ("|cff%s%%s|r"):format(color)
				if watchIcon or bookmarkIcon then
					currentUnit.icons = (watchIcon or "") .. (bookmarkIcon or "")
				else
					currentUnit.icons = nil
				end
				currentUnit.info = ("%%s |c%s%%s|r"):format(RAID_CLASS_COLORS[GC] and RAID_CLASS_COLORS[GC].colorStr or "ffffffff")
			end
		elseif currentUnit.type == "pet" then
			local colorblind = GetCVar("colorblindMode") == "1"
			currentUnit.faction = UnitFactionGroup(unit) or UnitIsUnit(unit, "playerpet") and playerFaction or "Neutral"

			local name = UnitName(unit)
			local color = COLORS[(UnitIsEnemy("player", unit) or attackMe and meAttack) and "hostile" or (meAttack or attackMe) and "neutral" or "friendly"]
			currentUnit.nameFormat = ("|cff%s%s|r"):format(color, name)

			local ffa = UnitIsPVPFreeForAll(unit)
			currentUnit.icons = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction)

			local ownership = _G[GTTL:format(colorblind and 3 or 2)]:GetText()
			local owner, petType = ownership:match(UNITNAME_TITLE_PET:format("(.+)")), UNITNAME_TITLE_PET
			if not owner then
				owner, petType = ownership:match(UNITNAME_TITLE_MINION:format("(.+)")), UNITNAME_TITLE_MINION
			end

			if not owner then return end
			currentUnit.character = xrp.characters.byName[owner]

			local realm = owner:match("%-([^%-]+)$")
			currentUnit.titleRealm = (colorblind and _xrp.L.ASIDE or "%s"):format(realm and _xrp.L.NAME_REALM:format(petType, xrp.RealmDisplayName(realm)) or petType, colorblind and xrp.L.VALUES.GF[currentUnit.faction])

			currentUnit.reaction = colorblind and GetText(REACTION:format(UnitReaction("player", unit)), UnitSex(unit))

			local race = UnitCreatureFamily(unit) or UnitCreatureType(unit)
			if race == _xrp.L.PET_GHOUL or race == _xrp.L.PET_WATER_ELEMENTAL or race == _xrp.L.PET_MT_WATER_ELEMENTAL then
				race = UnitCreatureType(unit)
			elseif not race then
				race = UNKNOWN
			end
			-- Mages, death knights, and warlocks have minions, hunters have 
			-- pets. Mages and death knights only have one pet family each.
			local GC = petType == UNITNAME_TITLE_MINION and (race == _xrp.L.PET_ELEMENTAL and "MAGE" or race == _xrp.L.PET_UNDEAD and "DEATHKNIGHT" or "WARLOCK") or petType == UNITNAME_TITLE_PET and "HUNTER"
			local level = UnitLevel(unit)
			local effectiveLevel = UnitEffectiveLevel(unit)
			level = effectiveLevel == level and tostring(level) or effectiveLevel < 1 and tostring(level) or EFFECTIVE_LEVEL_FORMAT:format(tostring(effectiveLevel), tostring(level))
			currentUnit.info = TOOLTIP_UNIT_LEVEL_CLASS_TYPE:format(level, ("|c%s%s|r"):format(RAID_CLASS_COLORS[GC] and RAID_CLASS_COLORS[GC].colorStr or "ffffffff", race), colorblind and ("%s %s"):format(xrp.L.VALUES.GC[currentUnit.character.fields.GS][GC], PET) or PET)

			if currentUnit.icons then
				defaultLines = defaultLines + 1
			end
			if colorblind then
				defaultLines = defaultLines + 1
			end
		end
		currentUnit.noProfile = _xrp.settings.tooltip.noOpFaction and currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or _xrp.settings.tooltip.noHostile and attackMe and meAttack

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

_xrp.settingsToggles.tooltip = {
	enabled = function(setting)
		if setting then
			if enabled == nil then
				GameTooltip:HookScript("OnTooltipSetUnit", GameTooltip_OnTooltipSetUnit_Hook)
				GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared_Hook)
			end
			xrp.HookEvent("RECEIVE", Tooltip_RECEIVE)
			enabled = true
			_xrp.settingsToggles.tooltip.replace(_xrp.settings.tooltip.replace)
		elseif enabled ~= nil then
			enabled = false
			xrp.UnhookEvent("RECEIVE", Tooltip_RECEIVE)
		end
	end,
	replace = function(setting)
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
	end,
}
