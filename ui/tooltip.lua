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

local cu = {}

local tooltip_RenderTooltip
do
	local function tooltip_Truncate(text, length, offset, double)
		if type(text) ~= "string" then
			return nil
		end
		offset = offset or 0
		if double == nil then
			double = true
		end
		text = text:gsub("\n+", " ")
		local line1 = text
		local line2
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
				line2 = text:sub(line1pos, position - 1)..CONTINUED
			elseif double then
				line2 = text:sub(position + 1)
			else
				line1 = line1..CONTINUED
			end
		end
		return line1 and line2 and line1.."\n"..line2 or line1
	end

	local tooltip_ParseVA
	do
		-- Use uppercase for keys.
		local profile_addons = {
			["XRP"] = "XRP",
			["MYROLEPLAY"] = "MRP",
			["TOTALRP2"] = "TRP2",
			["TOTALRP3"] = "TRP3",
			["GNOMTEC_BADGE"] = "GTEC",
			["FLAGRSP"] = "RSP",
			["FLAGRSP2"] = "RSP2",
			["HIDDEN"] = "Hidden", -- Pseudo-addon used to mark as hidden.
		}
		local extra_addons = {
			["GHI"] = "GHI",
			["TONGUES"] = "T",
		}

		function tooltip_ParseVA(VA)
			local VAshort = {}
			local hasrp = false
			for addon in VA:upper():gmatch("([^/;]+)/[^/;]+") do
				if profile_addons[addon] and not hasrp then
					VAshort[#VAshort + 1] = profile_addons[addon]
					hasrp = true
				elseif extra_addons[addon]then
					VAshort[#VAshort + 1] = extra_addons[addon]
				end
			end
			if not hasrp then
				table.insert(VAshort, 1, "RP")
			end
			return table.concat(VAshort, ", ")
		end
	end

	local oldlines, numline = 0, 0
	local gttl, gttr = "GameTooltipTextLeft%u", "GameTooltipTextRight%u"
	local function tooltip_RenderLine(left, right)
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
			local leftline = gttl:format(numline)
			local rightline = gttr:format(numline)
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

	local hidden = { VA = "Hidden/0" }

	function tooltip_RenderTooltip(character)
		oldlines = GameTooltip:NumLines()
		numline = 0
		character = character.hide and hidden or character.fields

		if cu.type == "player" then

			tooltip_RenderLine(cu.nameformat:format(tooltip_Truncate(xrp:StripEscapes(character.NA), 65, 0, false) or xrp:NameWithoutRealm(cu.name)), cu.icons)

			if character.NI then
				tooltip_RenderLine(("|cff6070a0Nickname:|r |cff99b3e6\"%s\"|r"):format(tooltip_Truncate(xrp:StripEscapes(character.NI), 70, 8, false)))
			end

			if character.NT then
				tooltip_RenderLine(("|cffcccccc%s|r"):format(tooltip_Truncate(xrp:StripEscapes(character.NT), 70)))
			end

			if xrpPrivate.settings.tooltip.extraspace then
				tooltip_RenderLine(" ")
			end

			tooltip_RenderLine(cu.guild)

			tooltip_RenderLine(cu.titlerealm, character.VA and ("|cff7f7f7f%s|r"):format(tooltip_ParseVA(character.VA)) or nil)

			if xrpPrivate.settings.tooltip.extraspace then
				tooltip_RenderLine(" ")
			end

			if character.CU then
				tooltip_RenderLine(("|cffa08050Currently:|r |cffe6b399%s|r"):format(tooltip_Truncate(xrp:StripEscapes(character.CU), 70, 9)))
			end

			tooltip_RenderLine(cu.info:format(not xrpPrivate.settings.tooltip.norprace and tooltip_Truncate(xrp:StripEscapes(character.RA), 40, 0, false) or cu.race or UNKNOWN, not xrpPrivate.settings.tooltip.norpclass and tooltip_Truncate(xrp:StripEscapes(character.RC), 40, 0, false) or cu.class or UNKNOWN, 40, 0, false))

			if (character.FR and character.FR ~= "0") or (character.FC and character.FC ~= "0") then
				local color = character.FC == "1" and "ff99664d" or "ff66b380"
				-- AAAAAAAAAAAAAAAAAAAAAAAA. The boolean logic.
				local frline = ("|c%s%s|r"):format(color, tooltip_Truncate((character.FR == "0" or not character.FR) and " " or tonumber(character.FR) and xrp.values.FR[tonumber(character.FR)] or xrp:StripEscapes(character.FR), 35, 0, false))
				local fcline
				if character.FC and character.FC ~= "0" then
					fcline = ("|c%s%s|r"):format(color, tooltip_Truncate(tonumber(character.FC) and xrp.values.FC[tonumber(character.FC)] or xrp:StripEscapes(character.FC), 35, 0, false))
				end
				tooltip_RenderLine(frline, fcline)
			end

			tooltip_RenderLine(cu.location)
		elseif cu.type == "pet" then
			tooltip_RenderLine(cu.nameformat, cu.icons)
			tooltip_RenderLine(cu.titlerealm:format(character.NA and tooltip_Truncate(xrp:StripEscapes(character.NA), 60, 0, false) or xrp:NameWithoutRealm(cu.name)))
			tooltip_RenderLine(cu.info)
		end
		-- In rare cases (test case: target without RP addon, is PvP flagged)
		-- there will be some leftover lines at the end of the tooltip. This
		-- hides them, if they exist.
		while numline < oldlines do
			numline = numline + 1
			_G[gttl:format(numline)]:Hide()
			_G[gttr:format(numline)]:Hide()
		end

		if cu.icons and (cu.type == "pet" or character.NI or character.NT or cu.guild or not character.VA) then
			GameTooltipTextRight2:SetText(" ")
			GameTooltipTextRight2:Show()
		end

		GameTooltip:Show()
	end
end

local tooltip_SetPlayerUnit, tooltip_SetPetUnit
do
	local faction_colors = {
		Horde = { dark = "ffe60d12", light = "ffff6468" },
		Alliance = { dark = "ff4a54e8", light = "ff868eff" },
		Neutral = { dark = "ffe6b300", light = "ffffdb5c" },
	}

	local reaction_colors = {
		friendly = "ff00991a",
		neutral = "ffe6b300",
		hostile = "ffcc4d38",
	}
	local unknown = { fields = {} }

	function tooltip_SetPlayerUnit(unit)
		cu.name = xrp:UnitNameWithRealm(unit)

		local faction = UnitFactionGroup(unit)
		if not faction or type(faction_colors[faction]) ~= "table" then
			faction = "Neutral"
		end

		local attackme = UnitCanAttack(unit, "player")
		local meattack = UnitCanAttack("player", unit)
		local connected = UnitIsConnected(unit)

		do
			local color = not xrpPrivate.settings.tooltip.faction and reaction_colors[(meattack and attackme and "hostile") or (faction == xrp.current.fields.GF and not attackme and not meattack and "friendly") or ((faction == xrp.current.fields.GF or faction == "Neutral") and "neutral") or "hostile"] or faction_colors[faction].dark
			-- Can only ever be one of AFK, DND, or offline.
			cu.nameformat = "|c"..color.."%s|r"..((UnitIsAFK(unit) and " |cff99994d"..CHAT_FLAG_AFK.."|r") or (UnitIsDND(unit) and " |cff994d4d"..CHAT_FLAG_DND.."|r") or (not connected and " |cff888888<"..PLAYER_OFFLINE..">|r") or "")
		end

		do
			local watchicon = (xrpPrivate.settings.tooltip.watching and UnitIsUnit("player", unit.."target") and "|TInterface\\LFGFrame\\BattlenetWorking0:32:32:10:-2|t") or nil
			local ffa = UnitIsPVPFreeForAll(unit)
			local pvpicon = (UnitIsPVP(unit) or ffa) and ("|TInterface\\TargetingFrame\\UI-PVP-"..((ffa or faction == "Neutral") and "FFA" or faction)..":20:20:4:-2:8:8:0:5:0:5:255:255:255|t") or nil
			cu.icons = watchicon and pvpicon and watchicon..pvpicon or watchicon or pvpicon
		end

		do
			local guildname, guildrank, guildindex = GetGuildInfo(unit)
			cu.guild = guildname and (xrpPrivate.settings.tooltip.guildrank and (xrpPrivate.settings.tooltip.guildindex and "%s (%u) of <%s>" or "%s of <%s>") or "<%s>"):format(xrpPrivate.settings.tooltip.guildrank and guildrank or guildname, xrpPrivate.settings.tooltip.guildindex and (guildindex + 1) or guildname, guildname) or nil
		end

		do
			local realm = cu.name:match(FULL_PLAYER_NAME:format(".+", "(.+)"))
			if realm == xrpPrivate.realm then
				realm = nil
			end
			cu.titlerealm = "|c"..faction_colors[faction].light..(UnitPVPName(unit) or xrp:NameWithoutRealm(cu.name))..(realm and (" ("..xrp:RealmNameWithSpacing(realm)..")|r") or "|r")
		end

		cu.race = UnitRace(unit) or UnitCreatureType(unit)
		do
			local level = UnitLevel(unit)
			local class, classid = UnitClassBase(unit)
			cu.class = class
			cu.info = ("%s %%s |c%s%%s|r (%s)"):format((level < 1 and UNIT_LETHAL_LEVEL_TEMPLATE or UNIT_LEVEL_TEMPLATE):format(level), RAID_CLASS_COLORS[classid] and RAID_CLASS_COLORS[classid].colorStr or "ffffffff", PLAYER)
		end

		do
			-- Ew, screen-scraping.
			local location = not UnitIsVisible(unit) and connected and GameTooltipTextLeft3:GetText() or nil
			cu.location = location and ("|cffffeeaa%s:|r %s"):format(ZONE, location) or nil
		end

		cu.type = "player"
		tooltip_RenderTooltip((not xrpPrivate.settings.tooltip.noopfaction or (faction == xrp.current.fields.GF or faction == "Neutral")) and (not xrpPrivate.settings.tooltip.nohostile or (not attackme or not meattack)) and xrp.units[unit] or unknown)
	end

	function tooltip_SetPetUnit(unit)
		local faction = UnitFactionGroup(unit)
		if not faction or type(faction_colors[faction]) ~= "table" then
			faction = UnitIsUnit(unit, "playerpet") and xrp.current.fields.GF or "Neutral"
		end
		local attackme = UnitCanAttack(unit, "player")
		local meattack = UnitCanAttack("player", unit)

		do
			local name = UnitName(unit)
			local color = not xrpPrivate.settings.tooltip.faction and reaction_colors[(meattack and attackme and "hostile") or (faction == xrp.current.fields.GF and not attackme and not meattack and "friendly") or ((faction == xrp.current.fields.GF or faction == "Neutral") and "neutral") or "hostile"] or faction_colors[faction].dark
			cu.nameformat = "|c"..color..name.."|r"
		end

		do
			local ffa = UnitIsPVPFreeForAll(unit)
			local pvpicon = (UnitIsPVP(unit) or ffa) and ("|TInterface\\TargetingFrame\\UI-PVP-"..((ffa or faction == "Neutral") and "FFA" or faction)..":20:20:4:-2:8:8:0:5:0:5:255:255:255|t") or nil
			local watchicon = (xrpPrivate.settings.tooltip.watching and UnitIsUnit("player", unit.."target") and "|TInterface\\LFGFrame\\BattlenetWorking0:32:32:10:-2|t") or nil
			cu.icons = watchicon and pvpicon and watchicon..pvpicon or watchicon or pvpicon
		end

		do
			-- I hate how fragile this is.
			local ownership = GameTooltipTextLeft2:GetText()
			local owner, pettype = ownership:match(UNITNAME_TITLE_PET:format("(.+)")), UNITNAME_TITLE_PET
			if not owner then
				owner, pettype = ownership:match(UNITNAME_TITLE_MINION:format("(.+)")), UNITNAME_TITLE_MINION
			end
			-- If there's still no owner, we can't do anything useful.
			if not owner then return end
			local realm = owner:match(FULL_PLAYER_NAME:format(".+", "(.+)"))

			cu.titlerealm = "|c"..faction_colors[faction].light..pettype..(realm and realm ~= "" and (" ("..xrp:RealmNameWithSpacing(realm)..")|r") or "|r")

			cu.name = xrp:NameWithRealm(owner)
			local race = UnitCreatureFamily(unit) or UnitCreatureType(unit)
			if race == "Ghoul" or race == "Water Elemental" or race == "MT - Water Elemental" then
				race = UnitCreatureType(unit)
			elseif not race then
				race = UNKNOWN
			end
			-- Mages, death knights, and warlocks have minions, hunters have 
			-- pets. Mages and death knights only have one pet family each.
			local classid = (pettype == UNITNAME_TITLE_MINION and ((race == "Elemental" and "MAGE") or (race == "Undead" and "DEATHKNIGHT") or "WARLOCK")) or (pettype == UNITNAME_TITLE_PET and "HUNTER")
			local level = UnitLevel(unit)

			cu.info = ("%s |c%s%s|r (%s)"):format((level < 1 and UNIT_LETHAL_LEVEL_TEMPLATE or UNIT_LEVEL_TEMPLATE):format(level), RAID_CLASS_COLORS[classid] and RAID_CLASS_COLORS[classid].colorStr or "ffffffff", race, PET)
		end

		cu.type = "pet"
		tooltip_RenderTooltip((not xrpPrivate.settings.tooltip.noopfaction or (faction == xrp.current.fields.GF or faction == "Neutral")) and (not xrpPrivate.settings.tooltip.nohostile or (not attackme or not meattack)) and xrp.characters[cu.name] or unknown)
	end
end

local enabled

local function XRPTooltip_MSP_RECEIVE(character)
	if not enabled or character ~= cu.name then return end
	local tooltip, unit = GameTooltip:GetUnit()
	if tooltip and cu.type == "player" then
		tooltip_RenderTooltip(unit and xrp.units[unit] or xrp.characters[character])
	elseif tooltip and cu.type == "pet" then
		tooltip_RenderTooltip(xrp.characters[character])
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

local fixframe
local function XRPTooltip_OnTooltipSetUnit(self)
	if not enabled then return end
	cu.type = nil
	local tooltip, unit = self:GetUnit()
	if not unit then
		fixframe:Show()
	elseif UnitIsPlayer(unit) then
		tooltip_SetPlayerUnit(unit)
	elseif UnitIsOtherPlayersPet(unit) or UnitIsUnit("playerpet", unit) then
		tooltip_SetPetUnit(unit)
	end
end

xrpPrivate.settingsToggles.tooltip = {
	enabled = function(setting)
		if setting then
			if enabled == nil then
				fixframe = CreateFrame("Frame")
				fixframe:Hide()
				fixframe:SetScript("OnUpdate", function(self, elapsed)
					-- GameTooltip:GetUnit() will sometimes return nil,
					-- especially when custom unit frames call
					-- GameTooltip:SetUnit() with something 'odd' like
					-- targettarget. By the next frame draw, the tooltip will
					-- correctly be able to identify such units (usually as
					-- mouseover).
					self:Hide()
					local tooltip, unit = GameTooltip:GetUnit()
					if not unit then
						return
					elseif UnitIsPlayer(unit) then
						tooltip_SetPlayerUnit(unit)
					elseif UnitIsOtherPlayersPet(unit) or unit and UnitIsUnit("playerpet", unit) then
						tooltip_SetPetUnit(unit)
					end
				end)
				xrp:HookEvent("MSP_RECEIVE", XRPTooltip_MSP_RECEIVE)
				GameTooltip:HookScript("OnTooltipSetUnit", XRPTooltip_OnTooltipSetUnit)
			end
			enabled = true
		elseif enabled ~= nil then
			enabled = false
		end
	end,
}
