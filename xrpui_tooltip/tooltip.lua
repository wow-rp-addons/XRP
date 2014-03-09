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
				if UnitIsPlayer(select(2, self:GetUnit())) then
					XRP.Tooltip:Update(self)
				end
			end)
			XRP:HookEvent("PROFILE_RECEIVE", function(name)
				local tooltip = select(2, GameTooltip:GetUnit())
				if tooltip and UnitIsPlayer(tooltip) and XRP:UnitNameWithRealm(tooltip) == name then
					XRP.Tooltip:Update(GameTooltip)
					-- If the mouse has already left the unit, the tooltip
					-- will get stuck visible if we don't do this. It still
					-- bounces back into visibility if it's partly faded out,
					-- but it'll just fade again.
					if not UnitIsUnit(tooltip, "mouseover") then
						GameTooltip:FadeOut()
					end
				end
			end)
			self:UnregisterEvent("ADDON_LOADED")
		end
	end)
end

-- Tooltip example:
-- 
--				 Bor Blasthammer <PvP>
--				 Nickname: "Something"
--							 Mercenary
--						  <Guild Name>
-- Bor the Proven Assailant (Alliance)
--			 Currently: Being awesome.
--				 Level 90 Dwarf Hunter
--
-- Colors: Name in dull blue for Alliance, dull red for Horde. PvP flag in
-- bright blue for Alliance, bright red for Horde. Also use similar AFK/Busy
-- flagging, with appropriate colors (less severe) for those.
-- Nickname: Dull color. Blue-ish?
-- Title: Similar to nickname?
-- Name/faction: Maybe remove faction? Dull, subdued color. Faction colored?
-- Currently: Brown?
-- Level: normal-ish. Race: Unique colors for races? Class: Class color.
function XRP.Tooltip:Update(tt)
	local tinsert = table.insert
	local oldnumlines = GameTooltip:NumLines()

	local unit = select(2, tt:GetUnit())
	local name = XRP:UnitNameWithRealm(unit)
	local profile = XRP.Remote:Get(name, "TT")
	local guild = GetGuildInfo(unit)
	local namewithtitle = UnitPVPName(unit)
	local level = UnitLevel(unit)
	local class, classid = UnitClass(unit)
	local pvp = UnitIsPVP(unit)
	local afk = UnitIsAFK(unit)
	local dnd = UnitIsDND(unit)
	local realm = select(2, UnitName(unit))
	local factionid, faction = UnitFactionGroup(unit)
	local factionnum
	if factionid == "Horde" then
		factionnum = 0
	elseif factionid == "Alliance" then
		factionnum = 1
	else
		factionnum = nil
	end
--	local reaction = UnitReaction("player", unit)

	local lines = {}

	local namestring = profile.NA or Ambiguate(name, "none")
	if afk then
		namestring = format("%s |cff99994d%s|r", namestring, CHAT_FLAG_AFK)
	elseif dnd then
		namestring = format("%s |cff994d4d%s|r", namestring, CHAT_FLAG_DND)
	end
	if pvp then
		namestring = format("%s |cffff00ff<%s>|r", namestring, PVP)
	end
	tinsert(lines, {
		left = {
			text = namestring,
			color = PLAYER_FACTION_COLORS[factionnum],
		},
	})

	if profile.NI ~= "" then
		tinsert(lines, {
			left = {
				text = format("|cff6070a0Nickname: |r\"%s\"", profile.NI),
				color = { r = 0.6, g = 0.7, b = 0.9 },
			},
		})
	end
	if profile.NT ~= "" then
		tinsert(lines, {
			left = {
				text = profile.NT,
				color = { r = 1.0, g = 1.0, b = 1.0 },
			},
		})
	end
	if guild then
		tinsert(lines, {
			left = {
				text = format("<%s>", guild),
				color = {},
			},
		})
	end
	if realm then
		namewithtitle = format("%s (%s)", namewithtitle, realm)
	end
	tinsert (lines, {
		left = {
			text = namewithtitle,
			color = {
				r = PLAYER_FACTION_COLORS[factionnum].r + 0.3,
				g = PLAYER_FACTION_COLORS[factionnum].g + 0.3,
				b = PLAYER_FACTION_COLORS[factionnum].b + 0.3,
			},
		},
		right = {
			text = (profile.VA ~= "Unknown/None" and "RP") or " ",
			color = { r = 0.5, g = 0.5, b = 0.5 },
		},
	})
	if profile.CU ~= "" then
		tinsert(lines, {
			left = {
				text = format("|cffa08050Currently:|r %s", profile.CU),
				color = { r = 0.9, g = 0.7, b = 0.6},
				wrap = true,
			},
		})
	end
	tinsert(lines, {
		left = {
			text = format("Level %s %s |c%s%s|r (%s)", tostring(level), profile.RA, RAID_CLASS_COLORS[classid].colorStr, class, PLAYER),
			color = {},
		},
	})

	for num, line in pairs(lines) do
		-- TODO: May need to hide TextRight.
		if not line.right then
			if num <= oldnumlines then
				_G["GameTooltipTextLeft"..num]:SetText(line.left.text)
				_G["GameTooltipTextLeft"..num]:SetTextColor(line.left.color.r or 1.0, line.left.color.g or 1.0, line.left.color.b or 1.0)
				if line.left.wrap then
					_G["GameTooltipTextLeft"..num]:SetWordWrap(true)
				end
			else
				GameTooltip:AddLine(line.left.text, line.left.color.r or 1.0, line.left.color.g or 1.0, line.left.color.b or 1.0, line.left.wrap or nil)
			end
		else
			if num <= oldnumlines then
				_G["GameTooltipTextLeft"..num]:SetText(line.left.text)
				_G["GameTooltipTextLeft"..num]:SetTextColor(line.left.color.r or 1.0, line.left.color.g or 1.0, line.left.color.b or 1.0)
				_G["GameTooltipTextRight"..num]:SetText(line.right.text)
				_G["GameTooltipTextRight"..num]:SetTextColor(line.right.color.r or 1.0, line.right.color.g or 1.0, line.right.color.b or 1.0)
				_G["GameTooltipTextRight"..num]:Show()
			else
				GameTooltip:AddDoubleLine(line.left.text, line.right.text, line.left.color.r or 1.0, line.left.color.g or 1.0, line.left.color.b or 1.0, line.right.color.r or 1.0, line.right.color.g or 1.0, line.right.color.b or 1.0)
			end
		end
	end
	local newnumlines = #lines
	while newnumlines < oldnumlines do
		newnumlines = newnumlines + 1
		_G["GameTooltipTextLeft"..newnumlines]:Hide()
		_G["GameTooltipTextRight"..newnumlines]:Hide()
	end
	tt:Show()
end

-- Run initial setup.
init()
