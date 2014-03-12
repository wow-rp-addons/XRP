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
				-- Ugh, this isn't even perfect. GetUnit() won't return 'odd'
				-- units, like "targettarget" even if they're completely valid.
				local unit = select(2, self:GetUnit())
				if UnitIsPlayer(unit) then
					XRP.Tooltip:PlayerUnit(unit)
				end
			end)

			XRP:HookEvent("PROFILE_RECEIVE", function(name)
				local tooltip, unit = GameTooltip:GetUnit()
				-- Note: This will pointlessly re-render if there are two
				-- players with the same base name from different realms.
				-- No harm done, just extra CPU cycles.
				if tooltip and tooltip == Ambiguate(name, "none") then
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
			-- it just changes it back.
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
	Tooltip example (line numbers are for reference only):

	1 Boromir, Son of Denethor <Away> <PvP>
	2 Nickname: "Ringstealer"
	3 Robber of Hobbits
	4 <Gondor Needs No Guild>
	5 Boromir the Beloved (WyrmrestAccord)			 RP
	6 Currently: Not stealing rings.
	7 Level 60 Human Warrior (Player)
	8 Normal roleplayer				Looking for contact

	Line-by-line description:
	1: Name, AFK/DND flag, PvP flag. Name is faction colored, others are item-
	   specific colors.
	2: Nickname. Specific colors, mildly subdued.
	3: Title. White, plain.
	4: Guild (in angle brackets). White, plain.
	5: In-game unit name, with in-game title. Realm in brackets if not same
	   realm. RP tag at the far end of the line indicates the presence of an
	   RP addon. TODO: Maybe make the RP tag more MRP-like with identifiers.
	6: Currently line. Brown-ish, moderately subdued.
	7: Game information (race is RP race). White colors, except class which is
	   class-colored. TODO: Maybe make the level colored to match difficulty.
	8: Roleplaying style and roleplaying status. NYI, need to consider colors.
]]

function XRP.Tooltip:PlayerUnit(unit)
	currentunit.name = XRP:UnitNameWithRealm(unit)
	currentunit.faction = UnitFactionGroup(unit)
	if not currentunit.faction or type(XRP_FACTION_COLORS[currentunit.faction]) ~= "table" then
		currentunit.faction = "Neutral"
	end
	currentunit.afk = UnitIsAFK(unit)
	currentunit.dnd = UnitIsDND(unit)
	currentunit.pvp = UnitIsPVP(unit)
	currentunit.connected = UnitIsConnected(unit)
	currentunit.guild = GetGuildInfo(unit)
	currentunit.pvpname = UnitPVPName(unit) or Ambiguate(currentunit.name, "none")
	currentunit.realm = select(2, UnitName(unit))
	currentunit.level = UnitLevel(unit)
	currentunit.race = UnitRace(unit)
	currentunit.class, currentunit.classid = UnitClass(unit)

	XRP.Tooltip:RefreshPlayer()
end

function XRP.Tooltip:RefreshPlayer()
	local profile = XRP.Remote:Get(currentunit.name, "TT")

	lines = {}

	local namestring = profile.NA or Ambiguate(currentunit.name, "none")
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
				text = format("|cff6070a0%s: |r\"%s\"", XRP_NI, profile.NI),
				color = { r = 0.6, g = 0.7, b = 0.9 },
			},
		}
	end

	if profile.NT ~= "" then
		lines[#lines+1] = {
			left = {
				text = profile.NT,
				color = { r = 1.0, g = 1.0, b = 1.0 },
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
		-- TODO: Would be really nice to format the realm with spaces. This
		-- is complex, however, as there are realms like Aman'Thul, Area 52,
		-- and Sisters of Elune that cause problems with automated spacing.
		-- Strange that Blizzard has no way to get the 'localized' name.
		pvpnamestring = format("%s (%s)", pvpnamestring, currentunit.realm)
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
				text = format("|cffa08050%s:|r %s", XRP_CU, profile.CU),
				color = { r = 0.9, g = 0.7, b = 0.6},
				wrap = true,
			},
		}
	end

	local race = profile.RA ~= UNKNOWN and profile.RA or currentunit.race
	lines[#lines+1] = {
		left = {
			-- Note: RAID_CLASS_COLORS[classid].colorStr does *not* have a pipe
			-- escape in it -- it's just the AARRGGBB string. Some other default
			-- color strings do, so be sure to check.
			text = format("%s %d %s |c%s%s|r (%s)", LEVEL, currentunit.level, race, RAID_CLASS_COLORS[currentunit.classid].colorStr, currentunit.class, PLAYER),
			color = DEFAULT_COLOR,
		},
	}

	if profile.FR ~= "0" or profile.FC ~= "0" then
		lines[#lines+1] = {
			left = {
				text = profile.FR == "0" and " " or (tonumber(profile.FR) and XRP_VALUES.FR[tonumber(profile.FR)+1]) or profile.FR,
				color = FC_COLORS[profile.FC == "1" and 1 or 2],
			},
			right = {
				text = profile.FC == "0" and "" or tonumber(profile.FC) and XRP_VALUES.FC[tonumber(profile.FC)+1] or profile.FC,
				color = FC_COLORS[profile.FC == "1" and 1 or 2],
			},
		}
	end
	rendertooltip()
end

init()
