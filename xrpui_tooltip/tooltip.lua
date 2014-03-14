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

local function init()
	local self = XRP.Tooltip
	self:RegisterEvent("ADDON_LOADED")
	self:SetScript("OnEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == "XRP_Tooltip" then

			GameTooltip:HookScript("OnTooltipSetUnit", function(self)
				-- GetUnit() will not return any sort of the non-basic unit
				-- strings, such as "targettarget", "pettarget", etc. It'll
				-- only spit out the name in the first parameter, which is
				-- not something we can use. This mainly causes problems for
				-- custom unit frames which call GameTooltip:SetUnit() with
				-- such unit strings. Bizarrely, a split-second later it will
				-- often properly return a unit string such as "mouseover"
				-- that we could have used.
				--
				-- TODO: Maybe it's worth using an OnUpdate script to try one
				-- more time on the next screen render to get a useful unit
				-- string, if unit == nil?
				local unit = select(2, self:GetUnit())
				if UnitIsPlayer(unit) then
					XRP.Tooltip:PlayerUnit(unit)
				end
			end)

			XRP:HookEvent("PROFILE_RECEIVE", function(name)
				local tooltip, unit = GameTooltip:GetUnit()
				-- Note: This will pointlessly re-render if there are two
				-- players with the same base name from different realms.
				-- No harm done, just a few extra CPU cycles.
				--
				-- TODO: Check if the off-realm tooltip targets have their
				-- realms attached. If so, use names with realms by attaching
				-- a realm name if needed.
				if tooltip and tooltip == XRP:NameWithoutRealm(name) then
					XRP.Tooltip:RefreshPlayer()
					-- If the mouse has already left the unit, the tooltip
					-- will get stuck visible if we don't do this. It still
					-- bounces back into visibility if it's partly faded out,
					-- but it'll just fade again.
					if not unit or not UnitIsUnit(unit, "mouseover") then
						GameTooltip:FadeOut()
					end
				end
			end)

			-- WORKAROUND: Blizzard's compact raid frames reset the colors
			-- of the first line in the tooltip ... *AFTER* calling SetUnit().
			-- This hook runs right after the code that changes the color and
			-- it just changes it back (without redoing the entire tooltip).
			--
			-- If there are any other instances of this sort of idiocy, this
			-- function should be made into a local and used as a hook on
			-- any such code.
			hooksecurefunc("UnitFrame_UpdateTooltip", function()
				local unit = select(2, GameTooltip:GetUnit())
				if UnitIsPlayer(unit) then
					local faction = UnitFactionGroup(unit)
					if not faction or type(XRP_FACTION_COLORS[faction]) ~= "table" then
						faction = "Neutral"
					end
					GameTooltipTextLeft1:SetTextColor(XRP_FACTION_COLORS[faction].r or 1.0, XRP_FACTION_COLORS[faction].g or 1.0, XRP_FACTION_COLORS[faction].b or 1.0)
				end
			end)

			self:UnregisterEvent("ADDON_LOADED")
		end
	end)
end

XRP_FACTION_COLORS = {
	Horde = PLAYER_FACTION_COLORS[0],
	Alliance = PLAYER_FACTION_COLORS[1],
	Neutral = {
		r = 1.0,
		g = 1.0,
		b = 0.0,
	},
}

local FC_COLORS = {
	{ r = 0.6, g = 0.4, b = 0.3 },
	{ r = 0.4, g = 0.7, b = 0.5 },
}

local DEFAULT_COLOR = {}

local currentunit = {}
local lines = {}

local function rendertooltip()
	local oldnumlines = GameTooltip:NumLines()
	-- This is a bit scary-looking, but it's a sane way to replace tooltip
	-- lines without needing to completely redo the tooltip from scratch
	-- (and lose the tooltip's state of what it's looking at if we do).
	for num, line in pairs(lines) do
		-- First case: If there's already a line to replace.
		if num <= oldnumlines then
			-- Can't have an empty left text line ever -- if a line exists, it
			-- needs to have a space at minimum to not muck up line spacing.
			_G["GameTooltipTextLeft"..num]:SetText(line.left.text or " ")
			_G["GameTooltipTextLeft"..num]:SetTextColor(line.left.color.r or 1.0, line.left.color.g or 1.0, line.left.color.b or 1.0)
			if line.right and line.right.text then
				_G["GameTooltipTextRight"..num]:SetText(line.right.text)
				_G["GameTooltipTextRight"..num]:SetTextColor(line.right.color.r or 1.0, line.right.color.g or 1.0, line.right.color.b or 1.0)
				_G["GameTooltipTextRight"..num]:Show()
			else
				_G["GameTooltipTextRight"..num]:Hide()
				if line.left.wrap then
					_G["GameTooltipTextLeft"..num]:SetWordWrap(true)
				end
			end
		-- Second case: If there are no more lines to replace.
		else
			if not line.right or not line.right.text then
				GameTooltip:AddLine(line.left.text, line.left.color.r or 1.0, line.left.color.g or 1.0, line.left.color.b or 1.0, line.left.wrap or nil)
			else
				GameTooltip:AddDoubleLine(line.left.text, line.right.text, line.left.color.r or 1.0, line.left.color.g or 1.0, line.left.color.b or 1.0, line.right.color.r or 1.0, line.right.color.g or 1.0, line.right.color.b or 1.0)
			end
		end
	end

	-- In rare cases (test case: target without RP addon, is PvP flagged) there
	-- will be some leftover lines at the end of the tooltip. This hides them,
	-- if they exist.
	local newnumlines = #lines
	while newnumlines < oldnumlines do
		newnumlines = newnumlines + 1
		_G["GameTooltipTextLeft"..newnumlines]:Hide()
		_G["GameTooltipTextRight"..newnumlines]:Hide()
	end

	GameTooltip:Show()
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
	[Current Location]

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

function XRP.Tooltip:PlayerUnit(unit)
	-- The currentunit table stores, as it says on the tin, the current (well,
	-- technically last) unit we rendered a tooltip for. This allows for a
	-- refresh of the tooltip as it fades, rather than only being able to
	-- refresh if the mouse is still over the unit.
	currentunit.name = XRP:UnitNameWithRealm(unit)
	currentunit.faction = UnitFactionGroup(unit)
	if not currentunit.faction or type(XRP_FACTION_COLORS[currentunit.faction]) ~= "table" then
		currentunit.faction = "Neutral"
	end
	currentunit.afk = UnitIsAFK(unit)
	currentunit.dnd = UnitIsDND(unit)
	currentunit.pvp = UnitIsPVP(unit)
	currentunit.visible = UnitIsVisible(unit)
	currentunit.connected = UnitIsConnected(unit)
	currentunit.location = (not currentunit.visible and currentunit.connected and GameTooltipTextLeft3:GetText()) or nil
	currentunit.guild = GetGuildInfo(unit)
	currentunit.pvpname = UnitPVPName(unit) or XRP:NameWithoutRealm(currentunit.name)
	currentunit.realm = select(2, UnitName(unit))
	currentunit.level = UnitLevel(unit)
	currentunit.race = UnitRace(unit)
	currentunit.class, currentunit.classid = UnitClass(unit)

	XRP.Tooltip:RefreshPlayer()
end

function XRP.Tooltip:RefreshPlayer()
	-- Caveat: Getting a tooltip for UNKNOWN fills some fields badly, like NA,
	-- which will always be "Unknown".
	--
	-- TODO: Maybe make a true dummy profile table instead? Or alternately be
	-- sure to not *require* the presence of fields and use an empty table?
	local profile = currentunit.visible and XRP.Remote:Get(currentunit.name, "TT") or XRP.Remote:Get(UNKNOWN, "TT")

	lines = {}
	local namestring = format("%.80s", profile.NA ~= UNKNOWN and profile.NA or XRP:NameWithoutRealm(currentunit.name))
	if currentunit.afk then
		namestring = format("%s |cff99994d%s|r", namestring, CHAT_FLAG_AFK)
	elseif currentunit.dnd then
		namestring = format("%s |cff994d4d%s|r", namestring, CHAT_FLAG_DND)
	end
	if currentunit.pvp then
		-- TODO: Better coloration:
		-- 		 - RED for hostile (you+them flagged, opposite faction)
		-- 		 - YELLOW for hostile (them flagged, opposite faction)
		-- 		 - GREEN for friendly (them flagged, same faction)
		-- 		 - YELLOW (?) for hostile (them flagged, same faction,
		-- 		   free-for-all PvP flag).
		-- 		 - RED (?) for hostile (you+them flagged, same faction,
		-- 		   free-for-all PvP flag)
		namestring = format("%s |cffff00ff<%s>|r", namestring, PVP)
	end
	if not currentunit.connected then
		namestring = format("%s |cff888888<%s>|r", namestring, PLAYER_OFFLINE)
	end
	lines[#lines+1] = {
		left = {
			text = namestring,
			color = XRP_FACTION_COLORS[currentunit.faction],
		},
	}

	if profile.NI ~= "" then
		lines[#lines+1] = {
			left = {
				text = format("|cff6070a0%s: |r\"%.80s\"", XRP_NI, profile.NI),
				color = { r = 0.6, g = 0.7, b = 0.9 },
			},
		}
	end

	if profile.NT ~= "" then
		lines[#lines+1] = {
			left = {
				text = profile.NT,
				color = DEFAULT_COLOR,
			},
		}
	end

	if currentunit.guild then
		lines[#lines+1] = {
			left = {
				text = format("<%s>", currentunit.guild),
				color = DEFAULT_COLOR,
			},
		}
	end

	local pvpnamestring = currentunit.pvpname
	if currentunit.realm and currentunit.realm ~= "" then
		pvpnamestring = format("%s (%s)", pvpnamestring, XRP:RealmNameWithSpacing(currentunit.realm))
	end
	lines[#lines+1] = {
		left = {
			text = pvpnamestring,
			color = {
				r = XRP_FACTION_COLORS[currentunit.faction].r + 0.3,
				g = XRP_FACTION_COLORS[currentunit.faction].g + 0.3,
				b = XRP_FACTION_COLORS[currentunit.faction].b + 0.3,
			},
		},
		right = {
			text = profile.VA ~= UNKNOWN.."/"..NONE and "RP" or nil,
			color = { r = 0.5, g = 0.5, b = 0.5 },
		},
	}

	if profile.CU ~= "" then
		lines[#lines+1] = {
			left = {
				text = format("|cffa08050%s:|r %.80s%s", XRP_CU, profile.CU, profile.CU:len()>80 and CONTINUED or ""),
				color = { r = 0.9, g = 0.7, b = 0.6},
			},
		}
	end

	local race = profile.RA ~= UNKNOWN and profile.RA or currentunit.race
	lines[#lines+1] = {
		left = {
			-- Note: RAID_CLASS_COLORS[classid].colorStr does *not* have a pipe
			-- escape in it -- it's just the AARRGGBB string. Some other default
			-- color strings do, so be sure to check.
			text = format("%s %d %.40s |c%s%s|r (%s)", LEVEL, currentunit.level, race, RAID_CLASS_COLORS[currentunit.classid].colorStr, currentunit.class, PLAYER),
			color = DEFAULT_COLOR,
		},
	}

	if profile.FR ~= "0" or profile.FC ~= "0" then
		lines[#lines+1] = {
			left = {
				text = format("%.40s", profile.FR == "0" and " " or (tonumber(profile.FR) and XRP_VALUES.FR[tonumber(profile.FR)+1]) or profile.FR),
				color = FC_COLORS[profile.FC == "1" and 1 or 2],
			},
			right = {
				text = format("%.40s", profile.FC == "0" and "" or tonumber(profile.FC) and XRP_VALUES.FC[tonumber(profile.FC)+1] or profile.FC),
				color = FC_COLORS[profile.FC == "1" and 1 or 2],
			},
		}
	end

	if not currentunit.visible and currentunit.location then
		lines[#lines+1] = {
			left = {
				text = format("%s: %s", ZONE, currentunit.location),
				color = DEFAULT_COLOR,
			},
		}
	end
	rendertooltip()
end

init()
