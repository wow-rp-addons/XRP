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

local GetCurrentForm
do
	local isWorgen = select(2, UnitRace("player")) == "Worgen"
	local playerClass = select(2, UnitClassBase("player"))
	if not (playerClass == "DRUID" or playerClass == "PRIEST" or playerClass == "SHAMAN") then
		playerClass = nil
	end
	local FORM_ID = {
		[1] = "CAT",
		[3] = "TRAVEL",
		[4] = "AQUATIC",
		[5] = "BEAR",
		[16] = "GHOSTWOLF",
		[27] = "FLIGHT",
		[28] = "SHADOWFORM",
		[29] = "FLIGHT",
		[31] = "MOONKIN",
	}
	local FORM_NO_RACE = {
		["CAT"] = true,
		["TREANT"] = true,
		["TRAVEL"] = true,
		["AQUATIC"] = true,
		["BEAR"] = true,
		["GHOSTWOLF"] = true,
		["FLIGHT"] = true,
		["MOONKIN"] = true,
		["ASTRAL"] = true, -- Shows worgen model, but cannot be human and astral.
	}
	local FORM_NO_EQUIPMENT = {
		["CAT"] = true,
		["TREANT"] = true,
		["TRAVEL"] = true,
		["AQUATIC"] = true,
		["BEAR"] = true,
		["GHOSTWOLF"] = true,
		["FLIGHT"] = true,
		["MOONKIN"] = true,
	}
	local lastEquipSet
	function GetCurrentForm()
		local classForm
		if playerClass then
			if playerClass == "DRUID" then
				classForm = FORM_ID[GetShapeshiftFormID()]
				if classForm == "MOONKIN" then
					for i = 1, NUM_GLYPH_SLOTS do
						local spellID = select(4, GetGlyphSocketInfo(i))
						if spellID == 114301 then
							classForm = "ASTRAL"
							break
						end
					end
				elseif not classForm and UnitBuff("player", _xrp.L.TREANT_BUFF) then
					classForm = "TREANT"
				end
			elseif playerClass == "PRIEST" or playerClass == "SHAMAN" then
				classForm = FORM_ID[GetShapeshiftFormID()]
			end
		end

		local raceForm
		if isWorgen and not FORM_NO_RACE[classForm] then
			raceForm = select(2, HasAlternateForm()) and "HUMAN" or "DEFAULT"
		end

		local equipSet
		if not FORM_NO_EQUIPMENT[classForm] then
			local bestMatch, bestScore = nil, 0
			for i = 1, GetNumEquipmentSets() do
				local name, icon, setID, equipped, numItems, numEquip, numInv, numMissing = GetEquipmentSetInfo(i)
				if equipped then
					lastEquipSet = name
					break
				elseif not lastEquipSet and numItems > 0 then
					if numEquip == numItems then
						-- Sets with all items equipped (but slots that should
						-- be empty aren't) are penalized slightly. No way to
						-- find out how many slots should be empty.
						numEquip = numEquip - 1
					end
					-- Sets with items not in inventory are penalized.
					local score = numEquip / (numItems + numMissing)
					if score > bestScore then
						bestScore = score
						bestMatch = name
					end
				end
			end
			equipSet = lastEquipSet or bestMatch
		end

		return raceForm, classForm, equipSet
	end
end

local timer
local function CancelTimer()
	if timer and not timer._cancelled then
		timer:Cancel()
	end
end

local race, class, equip

local function DoSwap()
	timer = nil

	local form
	if race then
		-- RACE-CLASS-Equipment (Worgen only)
		if class and equip then
			form = ("%s\30%s\29%s"):format(race, class, equip)
		end
		-- RACE-CLASS (Worgen only)
		if not _xrp.auto[form] and class then
			form = ("%s\30%s"):format(race, class)
		end
	end
	-- RACE-Equipment (Worgen only)/CLASS-Equipment
	if not _xrp.auto[form] and (race or class) and equip then
		form = ("%s\29%s"):format(race or class, equip)
	end
	-- RACE (Worgen only)/CLASS
	if not _xrp.auto[form] and (race or class) then
		form = race or class
	end
	-- DEFAULT-CLASS-Equipment (Worgen only)
	if not _xrp.auto[form] and race and race ~= "DEFAULT" and class and equip then
		form = ("DEFAULT\30%s\29%s"):format(class, equip)
	end
	-- DEFAULT-Equipment
	if not _xrp.auto[form] and equip then
		form = ("DEFAULT\29%s"):format(equip)
	end
	-- DEFAULT
	if not _xrp.auto[form] then
		form = "DEFAULT"
	end

	--print(form and (form:gsub("\30", "-"):gsub("\29", "-")) or "NONE")
	if not _xrp.auto[form] then
		return
	end
	xrp.profiles[_xrp.auto[form]]:Activate(true)
end

local function TestForm(event, unit)
	if InCombatLockdown() or event == "UNIT_PORTRAIT_UPDATE" and unit ~= "player" then return end
	local newRace, newClass, newEquip = GetCurrentForm()
	local newForm = class ~= newClass or race ~= newRace or equip ~= newEquip
	if event == "PLAYER_REGEN_ENABLED" and (newForm or timer and timer._cancelled) then
		race = newRace
		class = newClass
		equip = newEquip
		CancelTimer()
		timer = C_Timer.NewTimer(6, DoSwap)
	elseif newForm then
		race = newRace
		class = newClass
		equip = newEquip
		CancelTimer()
		timer = C_Timer.NewTimer(3, DoSwap)
	end
end

local function RecheckForm()
	race, class, equip = GetCurrentForm()
	CancelTimer()
	DoSwap()
end

-- Shadowform (and possibly others) don't trigger a portrait update. Worgen
-- form and equipment sets don't trigger a shapeshift update.
_xrp.HookGameEvent("UNIT_PORTRAIT_UPDATE", TestForm, "player")
_xrp.HookGameEvent("UPDATE_SHAPESHIFT_FORM", TestForm)
_xrp.HookGameEvent("PLAYER_REGEN_ENABLED", TestForm)
_xrp.HookGameEvent("PLAYER_REGEN_DISABLED", CancelTimer)

_xrp.auto = setmetatable({}, {
	__index = function(self, form)
		local profile = xrpSaved.auto[form]
		if not xrpSaved.profiles[profile] then
			return nil
		end
		return profile
	end,
	__newindex = function(self, form, profile)
		if profile == xrpSaved.auto[form] or profile and not xrpSaved.profiles[profile] then return end
		xrpSaved.auto[form] = profile
		RecheckForm()
	end,
})
