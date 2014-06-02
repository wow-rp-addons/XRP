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

local default_settings = { __index = {
	reaction = true,
	watching = false,
	guildrank = false,
	rprace = true,
	nohostile = false,
	noopfaction = false,
	extraspace = false,
}}

local faction_colors = {
	Horde = { dark = "e60d12", light = "ff6468" },
	Alliance = { dark = "4a54e8", light = "868eff" },
	Neutral = { dark = "e6b300", light = "ffdb5c" },
}

local reaction_colors = {
	friendly = "00991a",
	neutral = "e6b300",
	hostile = "cc4d38",
}

local fc_colors = {
	"99664d",
	"66b380",
}

local oldlines
local numline
local function render_line(lefttext, righttext)
	if not lefttext and not righttext then
		return
	end
	numline = numline + 1
	-- This is a bit scary-looking, but it's a sane way to replace tooltip
	-- lines without needing to completely redo the tooltip from scratch
	-- (and lose the tooltip's state of what it's looking at if we do).
	--
	-- NOTE: Do not use SetColor. This can taint raid frames and such.
	--
	-- First case: If there's already a line to replace.
	if numline <= oldlines then
		-- Can't have an empty left text line ever -- if a line exists, it
		-- needs to have a space at minimum to not muck up line spacing.
		_G["GameTooltipTextLeft"..numline]:SetText(lefttext or " ")
		_G["GameTooltipTextLeft"..numline]:Show()
		if righttext then
			_G["GameTooltipTextRight"..numline]:SetText(righttext)
			_G["GameTooltipTextRight"..numline]:Show()
		else
			_G["GameTooltipTextRight"..numline]:Hide()
		end
	-- Second case: If there are no more lines to replace.
	else
		if righttext then
			GameTooltip:AddDoubleLine(lefttext or " ", righttext)
		elseif lefttext then
			GameTooltip:AddLine(lefttext)
		end
	end
end

-- Use uppercase for keys.
local profile_addons = {
	["XRP"] = "XRP",
	["MYROLEPLAY"] = "MRP",
	["TOTALRP2"] = "TRP2",
	["GNOMTEC_BADGE"] = "GTEC",
	["FLAGRSP"] = "RSP",
	["FLAGRSP2"] = "RSP2",
}
local extra_addons = {
	["GHI"] = "GHI",
	["TONGUES"] = "T",
}

local function parse_VA(VA)
	local VAshort = ""
	local hasrp = false
	for addon in VA:upper():gmatch("(%a[^/]+)/[^;]+") do
		if profile_addons[addon] and not hasrp then
			VAshort = VAshort..profile_addons[addon]..", "
			hasrp = true
		elseif extra_addons[addon]then
			VAshort = VAshort..extra_addons[addon]..", "
		end
	end
	if not hasrp then
		VAshort = "RP, "..VAshort
	end
	return (VAshort:gsub(", $", ""))
end

local function truncate_lines(text, length, offset, double)
	offset = offset or 0
	if double == nil then
		double = true
	end
	text = (text:gsub("\n+", " "))
	local line1 = text
	local line2
	if #text > length - offset and text:find(" ", 1, true) then
		local position = 0
		local line1pos = 0
		while text:find(" ", position + 1, true) and (text:find(" ", position + 1, true)) <= (length - offset) do
			position = (text:find(" ", position + 1, true))
		end
		line1 = text:sub(1, position - 1)
		line1pos = position + 1
		if double and #text - #line1 > line1pos + offset then
			while text:find(" ", position + 1, true) and (text:find(" ", position + 1, true)) <= (length - offset + length) do
				position = (text:find(" ", position + 1, true))
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

-- Everything in here is using color pipe escapes because Blizzard will
-- occasionally interact with the tooltip's text lines' SetColor, and if we've
-- touched them (i.e., by setting or especially changing them), it will taint
-- some stuff pretty nastily (i.e., compact raid frames).
local cu = {}
local unknown = {}
local function tooltip_RenderPlayer(character)
	oldlines = GameTooltip:NumLines()
	numline = 0

	render_line(cu.nameformat:format(character.NA and truncate_lines((character.NA:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60, 0, false) or xrp:NameWithoutRealm(cu.name)), cu.icons)

	if character.NI then
		render_line(format("|cff6070a0%s: |cff99b3e6\"%s\"", XRP_NI, truncate_lines((character.NI:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60, #XRP_NI, false)))
	end

	if character.NT then
		render_line(format("|cffcccccc%s", truncate_lines((character.NT:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60)))
	end

	if xrp_settings.tooltip.extraspace then
		render_line(" ")
	end

	render_line(cu.guild)

	render_line(cu.titlerealm, character.VA and format("|cff7f7f7f%s", parse_VA(character.VA)) or nil)

	if character.CU then
		render_line(format("|cffa08050%s:|cffe6b399 %s", XRP_CU, truncate_lines((character.CU:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60, #XRP_CU)))
	end

	if xrp_settings.tooltip.extraspace and (cu.guild or character ~= unknown or character.CU) then
		render_line(" ")
	end

	local race = character.RA and xrp_settings.tooltip.rprace and (character.RA:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")) or cu.race
	render_line(cu.info:format(truncate_lines(race, 40, 0, false)))

	if (character.FR and character.FR ~= "0") or (character.FC and character.FC ~= "0") then
		-- AAAAAAAAAAAAAAAAAAAAAAAA. The boolean logic.
		local frline = format("|cff%s%s", (character.FC and character.FC ~= "0" and fc_colors[character.FC == "1" and 1 or 2]) or "ffffff", truncate_lines((character.FR == "0" or not character.FR) and " " or tonumber(character.FR) and xrp.values.FR[tonumber(character.FR)] or (character.FR:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 40, 0, false))
		local fcline
		if character.FC and character.FC ~= "0" then
			fcline = format("|cff%s%s", fc_colors[character.FC == "1" and 1 or 2], truncate_lines(tonumber(character.FC) and xrp.values.FC[tonumber(character.FC)] or (character.FC:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 40, 0, false))
		end
		render_line(frline, fcline)
	end

	render_line(cu.location)

	-- In rare cases (test case: target without RP addon, is PvP flagged) there
	-- will be some leftover lines at the end of the tooltip. This hides them,
	-- if they exist.
	while numline < oldlines do
		numline = numline + 1
		_G["GameTooltipTextLeft"..numline]:Hide()
		_G["GameTooltipTextRight"..numline]:Hide()
	end

	-- TODO: Show right text 2 if PvP flagged?
	GameTooltip:Show()
end

local function tooltip_SetPlayerUnit(unit)
	cu.name = xrp:UnitNameWithRealm(unit)

	local faction = (UnitFactionGroup(unit))
	if not faction or type(faction_colors[faction]) ~= "table" then
		faction = "Neutral"
	end

	local attackme = UnitCanAttack(unit, "player") -- Used two times.
	local meattack = UnitCanAttack("player", unit)
	local color = xrp_settings.tooltip.reaction and reaction_colors[faction ~= xrp.toon.fields.GF and "hostile" or (faction == xrp.toon.fields.GF and not meattack and not attackme and "friendly") or "neutral"] or faction_colors[faction].dark

	local connected = UnitIsConnected(unit)
	cu.nameformat = "|cff"..color.."%s"..((UnitIsAFK(unit) and " |cff99994d"..CHAT_FLAG_AFK) or (UnitIsDND(unit) and " |cff994d4d"..CHAT_FLAG_DND) or (not connected and " |cff888888<"..PLAYER_OFFLINE..">") or "")
	local ffa = UnitIsPVPFreeForAll(unit)
	local pvpicon = (UnitIsPVP(unit) or ffa) and ("|TInterface\\TargetingFrame\\UI-PVP-"..((ffa or faction == "Neutral") and "FFA" or faction)..":20:20:4:-2:8:8:0:5:0:5:255:255:255|t") or nil
	local watchicon = (xrp_settings.tooltip.watching and UnitIsUnit("player", unit.."target") and "\124TInterface\\LFGFrame\\BattlenetWorking0:32:32:10:-2\124t") or nil
	cu.icons = watchicon and pvpicon and watchicon..pvpicon or watchicon or pvpicon

	local guildname, guildrank, _ = GetGuildInfo(unit)
	cu.guild = guildname and (xrp_settings.tooltip.guildrank == true and guildrank.." of <"..guildname..">" or "<"..guildname..">") or nil

	local realm = select(2, UnitName(unit))
	cu.titlerealm = "|cff"..faction_colors[faction].light..(UnitPVPName(unit) or xrp:NameWithoutRealm(cu.name))..(realm and realm ~= "" and (" ("..xrp:RealmNameWithSpacing(realm)..")") or "") or nil

	cu.race = (UnitRace(unit)) or UnitCreatureType(unit)
	local level = UnitLevel(unit)
	local class, classid = UnitClass(unit)
	-- RAID_CLASS_COLORS is AARRGGBB.
	cu.info = format("|cffffffff%s %%s |c%s%s|cffffffff (%s)", format(level < 1 and UNIT_LETHAL_LEVEL_TEMPLATE or UNIT_LEVEL_TEMPLATE, level), RAID_CLASS_COLORS[classid] and RAID_CLASS_COLORS[classid].colorStr or "ffffffff", class, PLAYER)

	-- Ew, screen-scraping.
	local location = not UnitIsVisible(unit) and connected and GameTooltipTextLeft3:GetText() or nil
	cu.location = location and format("|cffffeeaa%s: |cffffffff%s", ZONE, location) or nil

	tooltip_RenderPlayer((not xrp_settings.tooltip.noopfaction or faction == xrp.toon.fields.GF) and (not xrp_settings.tooltip.nohostile or (not attackme or not meattack)) and xrp.units[unit] or unknown)
end

local function tooltip_RenderPet(character)
	oldlines = GameTooltip:NumLines()
	numline = 0

	render_line(cu.nameformat, cu.icons)

	render_line(cu.titlerealm:format(character.NA and truncate_lines((character.NA:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60, 0, false) or xrp:NameWithoutRealm(cu.name)))

	render_line(cu.info)

	while numline < oldlines do
		numline = numline + 1
		_G["GameTooltipTextLeft"..numline]:Hide()
		_G["GameTooltipTextRight"..numline]:Hide()
	end

	GameTooltip:Show()
end

local function tooltip_SetPetUnit(unit)
	local name = (UnitName(unit))
	local faction = (UnitFactionGroup(unit))
	if not faction or type(faction_colors[faction]) ~= "table" then
		faction = "Neutral"
	end

	local attackme = UnitCanAttack(unit, "player") -- Used two times.
	local meattack = UnitCanAttack("player", unit)
	local color = xrp_settings.tooltip.reaction and reaction_colors[faction ~= xrp.toon.fields.GF and "hostile" or (faction == xrp.toon.fields.GF and not meattack and not attackme and "friendly") or "neutral"] or faction_colors[faction].dark

	cu.nameformat = "|cff"..color..name
	local ffa = UnitIsPVPFreeForAll(unit)
	local pvpicon = (UnitIsPVP(unit) or ffa) and ("|TInterface\\TargetingFrame\\UI-PVP-"..((ffa or faction == "Neutral") and "FFA" or faction)..":20:20:4:-2:8:8:0:5:0:5:255:255:255|t") or nil
	local watchicon = (xrp_settings.tooltip.watching and UnitIsUnit("player", unit.."target") and "\124TInterface\\LFGFrame\\BattlenetWorking0:32:32:10:-2\124t") or nil
	cu.icons = watchicon and pvpicon and watchicon..pvpicon or watchicon or pvpicon

	-- I hate how fragile this is.
	local ownership = GameTooltipTextLeft2:GetText()
	local owner, pettype = ownership:match(UNITNAME_TITLE_PET:format("(.+)")), UNITNAME_TITLE_PET
	if not owner then
		owner, pettype = ownership:match(UNITNAME_TITLE_MINION:format("(.+)")), UNITNAME_TITLE_MINION
	end
	-- If there's still no owner, we can't do anything useful.
	if not owner then return end
	local realm = owner:match(FULL_PLAYER_NAME:format(".+", "(.+)"))

	cu.titlerealm = "|cff"..faction_colors[faction].light..pettype..(realm and realm ~= "" and (" ("..xrp:RealmNameWithSpacing(realm)..")") or "")

	cu.name = xrp:NameWithRealm(owner)
	local L = xrp.L
	local race = UnitCreatureFamily(unit) or UnitCreatureType(unit)
	if race == L["Ghoul"] or race == L["Water Elemental"] or not race then
		race = UnitCreatureType(unit)
	end
	if not race then
		race = UNKNOWN
	end
	-- Mages, death knights, and warlocks have minions, hunters have pets. Mages
	-- and death knights only have one pet family each.
	local classid = (pettype == UNITNAME_TITLE_MINION and ((race == L["Elemental"] and "MAGE") or (race == L["Undead"] and "DEATHKNIGHT") or "WARLOCK")) or (pettype == UNITNAME_TITLE_PET and "HUNTER")
	local level = UnitLevel(unit)

	cu.info = format("|cffffffff%s |c%s%s|cffffffff (%s)", format(level < 1 and UNIT_LETHAL_LEVEL_TEMPLATE or UNIT_LEVEL_TEMPLATE, level), RAID_CLASS_COLORS[classid] and RAID_CLASS_COLORS[classid].colorStr or "ffffffff", race, PET)

	tooltip_RenderPet((not xrp_settings.tooltip.noopfaction or faction == xrp.toon.fields.GF) and (not xrp_settings.tooltip.nohostile or (not attackme or not meattack)) and xrp.characters[cu.name] or unknown)
end

local tooltip = CreateFrame("Frame")

local function tooltip_OnTooltipSetUnit(self)
	-- GetUnit() will not return any sort of the non-basic unit strings, such
	-- as "targettarget", "pettarget", etc. It'll only spit out the name in the
	-- first parameter, which is not something we can use. This mainly causes
	-- problems for custom unit frames which call GameTooltip:SetUnit() with
	-- such unit strings.  Bizarrely, a split-second later it will often
	-- properly return a unit string such as "mouseover" that we could have
	-- used.
	local unit = select(2, self:GetUnit())
	if UnitIsPlayer(unit) then
		tooltip_SetPlayerUnit(unit)
	elseif UnitIsOtherPlayersPet(unit) or unit and UnitIsUnit("playerpet", unit) then
		tooltip_SetPetUnit(unit)
	elseif unit == nil then
		tooltip:Show()
	end
end

local function tooltip_MSP_RECEIVE(character)
	local tooltip, unit = GameTooltip:GetUnit()
	-- Off-realm units DO NOT have realms attached. This could cause
	-- inappropriate refreshes or, very rarely, a pet tooltip being mucked up
	-- with a player tooltip.
	--
	-- TODO: Fix the possibility for player/pet mix-ups. Try to handle pet
	-- refreshes somehow.
	if tooltip and tooltip == xrp:NameWithoutRealm(character) then
		tooltip_RenderPlayer(unit and xrp.units[unit] or xrp.characters[character])
		-- If the mouse has already left the unit, the tooltip will get
		-- stuck visible if we don't do this. It still bounces back
		-- into visibility if it's partly faded out, but it'll just
		-- fade again.
		if not GameTooltip:IsUnit("mouseover") then
			GameTooltip:FadeOut()
		end
	end
end

local function tooltip_OnEvent(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp_tooltip" then

		if type(xrp_settings.tooltip) ~= "table" then
			xrp_settings.tooltip = {}
		end
		setmetatable(xrp_settings.tooltip, default_settings)

		GameTooltip:HookScript("OnTooltipSetUnit", tooltip_OnTooltipSetUnit)

		xrp:HookEvent("MSP_RECEIVE", tooltip_MSP_RECEIVE)

		self:UnregisterEvent("ADDON_LOADED")
	end
end

tooltip:SetScript("OnEvent", tooltip_OnEvent)
tooltip:RegisterEvent("ADDON_LOADED")

-- WORKAROUND: GameTooltip:GetUnit() will sometimes return nil, especially when
-- custom unit frames call GameTooltip:SetUnit() with something 'odd' like
-- targettarget. On the very next frame draw, the tooltip will often correctly
-- be able to identify such units (typically as mouseover), so this will
-- functionally delay the tooltip draw for these cases by at most one frame.
local function tooltip_OnUpdate(self, elapsed)
	self:Hide() -- Hiding stops OnUpdate.
	local unit = select(2, GameTooltip:GetUnit())
	if UnitIsPlayer(unit) then
		tooltip_SetPlayerUnit(unit)
	elseif UnitIsOtherPlayersPet(unit) or unit and UnitIsUnit("playerpet", unit) then
		tooltip_SetPetUnit(unit)
	end
end

tooltip:Hide()
tooltip:SetScript("OnUpdate", tooltip_OnUpdate)
