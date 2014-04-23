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

local faction_colors = {
	Horde = { dark = "e60d12", light = "ff595e" },
	Alliance = { dark = "4a54e8", light = "96a1ff" },
	Neutral = { dark = "e6b300", light = "ffffcc" },
}

local fc_colors = {
	"99664d",
	"66b380",
}

local unknown = {}

local cu = {}

local oldlines
local numline
local function render_line(lefttext, righttext)
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
local known_addons = {
	["XRP"] = "XRP",
	["MYROLEPLAY"] = "MRP",
	["TOTALRP2"] = "TRP2",
	["GHI"] = "GHI",
	["TONGUES"] = "T",
}

local function tooltip_parse_VA(VA)
	local VAshort = ""
	for addon in VA:upper():gmatch("(%a[^/]+)/[^;]+") do
		VAshort = VAshort..known_addons[addon]..", "
	end
	VAshort = (VAshort:gsub(", $", ""))
	if VAshort:match("^[,%s]*$") then
		VAshort = "RP"
	end
	return VAshort
end

local function truncate_lines(text, length, offset, double)
	offset = offset or 0
	if double == nil then
		double = true
	end
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
	local line = line1 and line2 and line1.."\n"..line2 or line1
	return line
end

--[[
	Tooltip lines ([ ] denotes only if applicable):

	Name/Roleplay Name [<Away>|<Busy>] [<PvP>] [<Offline>]
	[Nickname: "RP Nickname"]
	[RP Title]
	[<Guild>]
	Name with Title [(Realm Name)]					  [RP]
	[Currently: RP currently doing.]
	Level 00 Race Class (Player)
	[Roleplaying style]					[Character status]
	[Zone: Current Location]

	Notes:
	  *	Most of the user input fields (i.e., RP fields) are truncated if they
		are too long. The goal is to have lines no more than ~90 characters,
		which is generous. The Currently field truncates with an ellipsis, but
		all others currently hard truncate (since they really shouldn't be
		long enough to trigger this).
	  * This doesn't, and probably should never, use line wrapping. It would be
		great for several of these fields, but is tricky and inconsistent to
		use, and can cause problems in the default tooltips.
	  *	"Name/Roleplay Name" is NA field if available, otherwise base name of
		the character (stripped of server name).
	  *	"Name with Title" is the in-game name/title, such as "Assistant
		Professor Smith".
	  *	"Realm Name" is run through a function that (should) space the name
		correctly.
	  *	"Current Location" is rare. It should only show up if the player is
		far away from you, yet you can still see their tooltip (i.e., raid or
		party unit frames).
	  *	When the unit is not visible (out of range), in addition to the added
		location line, much of the standard information is either unavailable
		or intentionally stripped. It's only a slight modification of the
		default tooltip, with coloration and some rearrangement.
]]

function xrpui.tooltip:PlayerUnit(unit)
	-- The cu table stores, as it says on the tin, the current (well,
	-- technically last) unit we rendered a tooltip for. This allows for a
	-- refresh of the tooltip as it fades, rather than only being able to
	-- refresh if the mouse is still over the unit.
	cu.name = xrp:UnitNameWithRealm(unit)
	cu.faction = UnitFactionGroup(unit)
	if not cu.faction or type(faction_colors[cu.faction]) ~= "table" then
		cu.faction = "Neutral"
	end
	cu.afk = UnitIsAFK(unit)
	cu.dnd = UnitIsDND(unit)
	cu.pvp = UnitIsPVP(unit)
	cu.canattack = UnitCanAttack(unit, "player")
	cu.canbeattacked = UnitCanAttack("player", unit)
	cu.visible = UnitIsVisible(unit)
	cu.connected = UnitIsConnected(unit)
	-- Ew, screen-scraping.
	cu.location = (not cu.visible and cu.connected and GameTooltipTextLeft3:GetText()) or nil
	cu.guild = GetGuildInfo(unit)
	cu.pvpname = UnitPVPName(unit) or xrp:NameWithoutRealm(cu.name)
	cu.realm = select(2, UnitName(unit))
	cu.level = UnitLevel(unit)
	cu.race, cu.raceid = UnitRace(unit)
	cu.class, cu.classid = UnitClass(unit)

	xrpui.tooltip:RefreshPlayer(xrp.units[unit])
end

-- Everything in here is using color pipe escapes because Blizzard will
-- occasionally interact with the tooltip's text lines' SetColor, and if
-- we've touched them (i.e., by setting or especially changing them), it will
-- taint some stuff pretty nastily (i.e., compact raid frames).
function xrpui.tooltip:RefreshPlayer(character)
	oldlines = GameTooltip:NumLines()
	numline = 0
	character = cu.visible and character or unknown
	
	local namestring = format("|cff%s%s", faction_colors[cu.faction].dark, character.NA and truncate_lines((character.NA:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60, 0, false) or xrp:NameWithoutRealm(cu.name))
	if cu.afk then
		namestring = format("%s |cff99994d%s", namestring, CHAT_FLAG_AFK)
	elseif cu.dnd then
		namestring = format("%s |cff994d4d%s", namestring, CHAT_FLAG_DND)
	end
	if cu.pvp then
		local colorstring
		if cu.canattack then
			-- If they can attack us.
			colorstring = faction_colors[xrp.toon.fields.GF].light
		elseif cu.canbeattacked or cu.faction ~= xrp.toon.fields.GF then
			-- If we can attack them (or is opposite faction, for Sanctuary).
			colorstring = faction_colors["Neutral"].dark
		else
			-- Otherwise, must be friendly.
			colorstring = "009919"
		end
		namestring = format("%s |cff%s<%s>", namestring, colorstring, PVP)
	end
	if not cu.connected then
		namestring = format("%s |cff888888<%s>", namestring, PLAYER_OFFLINE)
	end
	render_line(namestring)

	if character.NI then
		render_line(format("|cff6070a0%s: |cff99b3e6\"%s\"", XRPUI_NI, truncate_lines((character.NI:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60, #XRPUI_NI, false)))
	end

	if character.NT then
		render_line(format("|cffcccccc%s", truncate_lines((character.NT:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60)))
	end

	if cu.guild then
		render_line(format("<%s>", cu.guild))
	end

	if cu.visible then
		local pvpnamestring = format("|cff%s%s", faction_colors[cu.faction].light, cu.pvpname)
		if cu.realm and cu.realm ~= "" then
			pvpnamestring = format("%s (%s)", pvpnamestring, xrp:RealmNameWithSpacing(cu.realm))
		end
		render_line(pvpnamestring, character.VA and format("|cff7f7f7f%s", tooltip_parse_VA(character.VA)) or nil)
	end

	if character.CU then
		render_line(format("|cffa08050%s:|cffe6b399 %s", XRPUI_CU, truncate_lines((character.CU:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 60, #XRPUI_CU)))
	end

	local race = character.RA and (character.RA:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")) or cu.race
	-- Note: RAID_CLASS_COLORS[classid].colorStr does *not* have a pipe
	-- escape in it -- it's just the AARRGGBB string. Some other default
	-- color strings do, so be sure to check.
	render_line(format("|cffffffff%s %d %s |c%s%s|cffffffff (%s)", LEVEL, cu.level, truncate_lines(race, 40, 0, false), RAID_CLASS_COLORS[cu.classid].colorStr, cu.class, PLAYER))

	if (character.FR and character.FR ~= "0") or (character.FC and character.FC ~= "0") then
		-- AAAAAAAAAAAAAAAAAAAAAAAA. The boolean logic.
		local frline = format("|cff%s%s", (character.FC and character.FC ~= "0" and fc_colors[character.FC == "1" and 1 or 2]) or "ffffff", truncate_lines((character.FR == "0" or not character.FR) and " " or tonumber(character.FR) and xrpui.values.FR[tonumber(character.FR)] or (character.FR:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 40, 0, false))
		local fcline
		if character.FC and character.FC ~= "0" then
			fcline = format("|cff%s%s", fc_colors[character.FC == "1" and 1 or 2], truncate_lines(tonumber(character.FC) and xrpui.values.FC[tonumber(character.FC)] or (character.FC:gsub("||?c%x%x%x%x%x%x%x%x%s*", "")), 40, 0, false))
		end
		render_line(frline, fcline)
	end

	if not cu.visible and cu.location then
		-- TODO: Color the Zone: label.
		render_line(format("|cffffeeaa%s: |cffffffff%s", ZONE, cu.location))
	end

	-- In rare cases (test case: target without RP addon, is PvP flagged) there
	-- will be some leftover lines at the end of the tooltip. This hides them,
	-- if they exist.
	while numline < oldlines do
		numline = numline + 1
		_G["GameTooltipTextLeft"..numline]:Hide()
		_G["GameTooltipTextRight"..numline]:Hide()
	end

	GameTooltip:Show()
end

xrpui.tooltip:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" and addon == "xrpui_tooltip" then

		GameTooltip:HookScript("OnTooltipSetUnit", function(self)
			-- GetUnit() will not return any sort of the non-basic unit
			-- strings, such as "targettarget", "pettarget", etc. It'll only
			-- spit out the name in the first parameter, which is not something
			-- we can use. This mainly causes problems for custom unit frames
			-- which call GameTooltip:SetUnit() with such unit strings.
			-- Bizarrely, a split-second later it will often properly return a
			-- unit string such as "mouseover" that we could have used.
			local unit = select(2, self:GetUnit())
			if UnitIsPlayer(unit) then
				xrpui.tooltip:PlayerUnit(unit)
			elseif unit == nil then
				xrpui.tooltip:Show()
			end
		end)

		xrp:HookEvent("MSP_RECEIVE", function(name)
			local tooltip, unit = GameTooltip:GetUnit()
			-- TODO: Check if the off-realm tooltip targets have their realms
			-- attached. If so, use names with realms by attaching a realm name
			-- if needed.
			if tooltip and tooltip == xrp:NameWithoutRealm(name) then
				xrpui.tooltip:RefreshPlayer(xrp.characters[name])
				-- If the mouse has already left the unit, the tooltip will get
				-- stuck visible if we don't do this. It still bounces back
				-- into visibility if it's partly faded out, but it'll just
				-- fade again.
				if not unit or not UnitIsUnit(unit, "mouseover") then
					GameTooltip:FadeOut()
				end
			end
		end)

		self:UnregisterEvent("ADDON_LOADED")
	end
end)
xrpui.tooltip:RegisterEvent("ADDON_LOADED")

-- WORKAROUND: GameTooltip:GetUnit() will sometimes return nil, especially when
-- custom unit frames call GameTooltip:SetUnit() with something 'odd' like
-- targettarget. On the very next frame draw, the tooltip will often correctly
-- be able to identify such units (typically as mouseover), so this will
-- functionally delay the tooltip draw for these cases by at most one frame.
xrpui.tooltip:SetScript("OnUpdate", function(self, elapsed)
	self:Hide() -- Hiding stops OnUpdate.
	local unit = select(2, GameTooltip:GetUnit())
	if UnitIsPlayer(unit) then
		xrpui.tooltip:PlayerUnit(unit)
	end
end)
