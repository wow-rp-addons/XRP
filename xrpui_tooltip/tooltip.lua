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

--[[XRP_FACTION_COLORS = {
	Horde = PLAYER_FACTION_COLORS[0], -- e60d12 LIGHT: ff595e
	Alliance = PLAYER_FACTION_COLORS[1], -- 4a54e8 LIGHT: 96a1ff
	Neutral = { r = 0.9, g = 0.7, b = 0.0 }, -- e6b300 LIGHT: TODO!
}]]

local faction_colors = {
	Horde = { dark = "e60d12", light = "ff595e" },
	Alliance = { dark = "4a54e8", light = "96a1ff" },
	Neutral = { dark = "e6b300", light = "ffffcc" },
}

local fccolors = {
	"99664d",
	"66b380",
	--{ r = 0.6, g = 0.4, b = 0.3 }, -- 99664d
	--{ r = 0.4, g = 0.7, b = 0.5 }, -- 66b380
}

local unknown = {}

local currentunit = {}
local lines

local oldnumlines
local numline

local function xrpui_tooltip_render_line(lefttext, righttext)
	numline = numline + 1
	-- This is a bit scary-looking, but it's a sane way to replace tooltip
	-- lines without needing to completely redo the tooltip from scratch
	-- (and lose the tooltip's state of what it's looking at if we do).
	--
	-- First case: If there's already a line to replace.
	if numline <= oldnumlines then
		-- Can't have an empty left text line ever -- if a line exists, it
		-- needs to have a space at minimum to not muck up line spacing.
		_G["GameTooltipTextLeft"..numline]:SetText(lefttext or " ")
		if righttext then
			_G["GameTooltipTextRight"..numline]:SetText(righttext)
			_G["GameTooltipTextRight"..numline]:Show()
		else
			_G["GameTooltipTextRight"..numline]:Hide()
		end
	-- Second case: If there are no more lines to replace.
	else
		if not righttext then
			GameTooltip:AddLine(lefttext or "")
		else
			GameTooltip:AddDoubleLine(lefttext or " ", righttext)
		end
	end
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
	-- The currentunit table stores, as it says on the tin, the current (well,
	-- technically last) unit we rendered a tooltip for. This allows for a
	-- refresh of the tooltip as it fades, rather than only being able to
	-- refresh if the mouse is still over the unit.
	currentunit.name = xrp:UnitNameWithRealm(unit)
	currentunit.faction = UnitFactionGroup(unit)
	if not currentunit.faction or type(faction_colors[currentunit.faction]) ~= "table" then
		currentunit.faction = "Neutral"
	end
	currentunit.afk = UnitIsAFK(unit)
	currentunit.dnd = UnitIsDND(unit)
	currentunit.pvp = UnitIsPVP(unit)
	currentunit.canattack = UnitCanAttack(unit, "player")
	currentunit.canbeattacked = UnitCanAttack("player", unit)
	currentunit.visible = UnitIsVisible(unit)
	currentunit.connected = UnitIsConnected(unit)
	currentunit.location = (not currentunit.visible and currentunit.connected and GameTooltipTextLeft3:GetText()) or nil
	currentunit.guild = GetGuildInfo(unit)
	currentunit.pvpname = UnitPVPName(unit) or xrp:NameWithoutRealm(currentunit.name)
	currentunit.realm = select(2, UnitName(unit))
	currentunit.level = UnitLevel(unit)
	currentunit.race, currentunit.raceid = UnitRace(unit)
	currentunit.class, currentunit.classid = UnitClass(unit)

	xrpui.tooltip:RefreshPlayer(xrp.units[unit])
end

-- Everything in here is using color pipe escapes because Blizzard will
-- occasionally interact with the tooltip's text lines' SetColor, and if
-- we've touched them (i.e., by setting or especially changing them), it will
-- taint some stuff pretty nastily (i.e., compact raid frames).
function xrpui.tooltip:RefreshPlayer(character)
	oldnumlines = GameTooltip:NumLines()
	numline = 0
	character = currentunit.visible and character or unknown
	
	local namestring = format("|cff%s%.80s", faction_colors[currentunit.faction].dark, character.NA or xrp:NameWithoutRealm(currentunit.name))
	if currentunit.afk then
		namestring = format("%s |cff99994d%s", namestring, CHAT_FLAG_AFK)
	elseif currentunit.dnd then
		namestring = format("%s |cff994d4d%s", namestring, CHAT_FLAG_DND)
	end
	if currentunit.pvp then
		local colorstring
		if currentunit.canattack then
			-- If they can attack us.
			colorstring = "ffbf4d00"
		elseif currentunit.canbeattacked or currentunit.faction ~= xrp.toon.fields.GF then
			-- If we can attack them (or is opposite faction, for Sanctuary).
			colorstring = "ffe6b300"
		else
			-- Otherwise, must be friendly.
			colorstring = "ff009919"
		end
		namestring = format("%s |c%s<%s>", namestring, colorstring, PVP)
	end
	if not currentunit.connected then
		namestring = format("%s |cff888888<%s>", namestring, PLAYER_OFFLINE)
	end
	xrpui_tooltip_render_line(namestring)

	if character.NI then
		-- TODO: Graceful truncation (using quotation marks?)
	xrpui_tooltip_render_line(format("|cff6070a0%s: |cff99b3e6\"%.70s\"", XRPUI_NI, character.NI))
	end

	if character.NT then
		local profilestring = character.NT
		-- Try to gracefully truncate TRP2's slew of titles.
		-- TODO: Check more common separators.
		if #profilestring > 80 and profilestring:find("|", 1, true) then
			local position = 0
			while profilestring:find("|", position + 1, true) and (profilestring:find("|", position + 1, true)) <= 80 do
				position = (profilestring:find("|", position + 1, true))
			end
			profilestring = profilestring:sub(1, position - 2)
		end
		xrpui_tooltip_render_line(format("%.80s", profilestring))
	end

	if currentunit.guild then
		xrpui_tooltip_render_line(format("<%s>", currentunit.guild))
	end

	if currentunit.visible then
		local pvpnamestring = format("|cff%s%s", faction_colors[currentunit.faction].light, currentunit.pvpname)
		if currentunit.realm and currentunit.realm ~= "" then
			pvpnamestring = format("%s (%s)", pvpnamestring, xrp:RealmNameWithSpacing(currentunit.realm))
		end
		xrpui_tooltip_render_line(pvpnamestring, character.VA and "|cff7f7f7fRP" or nil)
	end

	if character.CU then
		xrpui_tooltip_render_line(format("|cffa08050%s:|cffe6b399 %.70s%s", XRPUI_CU, character.CU, character.CU:len()>70 and CONTINUED or ""))
	end

	local race = character.RA or currentunit.race
	-- Note: RAID_CLASS_COLORS[classid].colorStr does *not* have a pipe
	-- escape in it -- it's just the AARRGGBB string. Some other default
	-- color strings do, so be sure to check.
	xrpui_tooltip_render_line(format("|cffffffff%s %d %.40s |c%s%s|cffffffff (%s)", LEVEL, currentunit.level, race, RAID_CLASS_COLORS[currentunit.classid].colorStr, currentunit.class, PLAYER))

	if (character.FR and character.FR ~= "0") or (character.FC and character.FC ~= "0") then
		local frline = format("|cff%s%.40s", (character.FC and character.FC ~= "0" and fccolors[character.FC == "1" and 1 or 2]) or "ffffff", (character.FR == "0" or not character.FR) and " " or tonumber(character.FR) and xrpui.values.FR[tonumber(character.FR)] or character.FR)
		local fcline
		if character.FC and character.FC ~= "0" then
			fcline = format("|cff%s%.40s", fccolors[character.FC == "1" and 1 or 2], tonumber(character.FC) and xrpui.values.FC[tonumber(character.FC)] or character.FC)
		end
		xrpui_tooltip_render_line(frline, fcline)
	end

	if not currentunit.visible and currentunit.location then
		-- TODO: Color the Zone: label.
		xrpui_tooltip_render_line(format("%s: %s", ZONE, currentunit.location))
	end

	-- In rare cases (test case: target without RP addon, is PvP flagged) there
	-- will be some leftover lines at the end of the tooltip. This hides them,
	-- if they exist.
	while numline < oldnumlines do
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
			-- Note: This will pointlessly re-render if there are two players
			-- with the same base name from different realms.  No harm done,
			-- just a few extra CPU cycles.
			--
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
