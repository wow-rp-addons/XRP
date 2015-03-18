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

local addonName, xrpLocal = ...

local RecheckForm

xrpLocal.auto = setmetatable({}, {
	__index = function(self, form)
		local profile = xrpSaved.auto[form]
		if not xrpSaved.profiles[profile] then
			return nil
		end
		return profile
	end,
	__newindex = function(self, form, profile)
		if profile and not xrpSaved.profiles[profile] then return end
		xrpSaved.auto[form] = profile
		RecheckForm()
	end,
})

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
				elseif not classForm and UnitBuff("player", "Treant Form") then
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
			local numSets = GetNumEquipmentSets()
			local bestMatch, bestScore = nil, 0
			for i = 1, numSets do
				local name, icon, setID, equipped, numItems, numEquip, numInv, numMissing = GetEquipmentSetInfo(i)
				if equipped then
					lastEquipSet = name
					break
				elseif not lastEquipSet and numItems > 0 then
					local score
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

local swap = CreateFrame("Frame")
swap.timer = 0
do
	local function TestForm(self, event)
		if InCombatLockdown() then return end
		if event == "PLAYER_REGEN_DISABLED" then
			self:Hide()
			return
		end
		local race, class, equip = GetCurrentForm()
		local newForm = self.class ~= class or self.race ~= race or self.equip ~= equip
		if event == "PLAYER_REGEN_ENABLED" and (newForm or self.timer > 0) then
			self.timer = 6
			self.race = race
			self.class = class
			self.equip = equip
			self:Show()
		elseif newForm then
			self.timer = 3
			self.race = race
			self.class = class
			self.equip = equip
			self:Show()
		end
	end
	function RecheckForm()
		swap.race = nil
		swap.class = nil
		swap.equip = nil
		TestForm(swap)
		-- This forces a form check immediately, for new profile assignments.
		swap.timer = 0
	end
	swap:SetScript("OnEvent", TestForm)
end
swap:SetScript("OnUpdate", function(self, elapsed)
	self.timer = self.timer - elapsed
	if self.timer > 0 then return end
	self.timer = 0
	self:Hide()

	-- Priority (W = Worgen):
	-- 1: RACE-CLASS-Equipment (W)
	-- 2: RACE-CLASS (W)
	-- 3: RACE-Equipment (W) or CLASS-Equipment
	-- 4: RACE (W) or CLASS
	-- 5: DEFAULT-CLASS-Equipment (W)
	-- 6: DEFAULT-Equipment
	-- 9: DEFAULT

	local auto, form = xrpLocal.auto
	if self.race then
		-- RACE-CLASS-Equipment (Worgen only)
		if self.class and self.equip then
			form = ("%s\30%s\29%s"):format(self.race, self.class, self.equip)
		end
		-- RACE-CLASS (Worgen only)
		if not auto[form] and self.class then
			form = ("%s\30%s"):format(self.race, self.class)
		end
	end
	-- RACE-Equipment (Worgen only)/CLASS-Equipment
	if not auto[form] and (self.race or self.class) and self.equip then
		form = ("%s\29%s"):format(self.race or self.class, self.equip)
	end
	-- RACE (Worgen only)/CLASS
	if not auto[form] and (self.race or self.class) then
		form = self.race or self.class
	end
	-- DEFAULT-CLASS-Equipment (Worgen only)
	if not auto[form] and self.race and self.race ~= "DEFAULT" and self.class and self.equip then
		form = ("DEFAULT\30%s\29%s"):format(self.class, self.equip)
	end
	-- DEFAULT-Equipment
	if not auto[form] and self.equip then
		form = ("DEFAULT\29%s"):format(self.equip)
	end
	-- DEFAULT
	if not auto[form] then
		form = "DEFAULT"
	end

	if not auto[form] then
		return
	end

	--print("Swapping to: "..auto[form])
	xrpLocal.profiles[auto[form]]:Activate(true)
end)
swap:Hide()

-- Shadowform (and possibly others) don't trigger a portrait update. Worgen
-- form and equipment sets don't trigger a shapeshift update.
swap:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
swap:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
swap:RegisterEvent("PLAYER_REGEN_DISABLED")
swap:RegisterEvent("PLAYER_REGEN_ENABLED")
