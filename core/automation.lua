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

local GetCurrentForm
do
	local hasrace = select(2, UnitRace("player")) == "Worgen"
	local class = select(2, UnitClassBase("player"))
	if not (class == "DRUID" or class == "PRIEST" or class == "SHAMAN") then
		class = nil
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
	local lastequipped
	function GetCurrentForm()
		local classform
		if class then
			if class == "DRUID" then
				classform = FORM_ID[GetShapeshiftFormID()]
				if classform == "MOONKIN" then
					for i = 1, NUM_GLYPH_SLOTS do
						local spellID = select(4, GetGlyphSocketInfo(i))
						if spellID == 114301 then
							classform = "ASTRAL"
							break
						end
					end
				elseif not classform and UnitBuff("player", "Treant Form") then
					classform = "TREANT"
				end
			elseif class == "PRIEST" or class == "SHAMAN" then
				classform = FORM_ID[GetShapeshiftFormID()]
			end
		end

		local raceform
		if hasrace and not FORM_NO_RACE[classform] then
			raceform = select(2, HasAlternateForm()) and "HUMAN" or "DEFAULT"
		end

		local equipset
		if not FORM_NO_EQUIPMENT[classform] then
			local numSets = GetNumEquipmentSets()
			for i = 1, numSets do
				local name, _, _, equipped = GetEquipmentSetInfo(i)
				if equipped then
					equipset = name
					lastequipped = name
					break
				end
			end
			if not equipset and numSets > 0 then
				if not lastequipped then
					-- Guess what set to use if no set has been fully equipped
					-- so far this session.
					local best, bestscore, fullset = nil, 0, false
					for i = 1, numSets do
						local name, _, _, _, numItems, numEquip, numInv = GetEquipmentSetInfo(i)
						if numInv == numItems or not fullset then
							local score = numItems / numEquip
							if score > bestscore or (numInv == numItems and not fullset) then
								bestscore = score
								best = name
								fullset = numInv == numItems
							end
						end
					end
					lastequipped = best
				end
				equipset = lastequipped
			end
		end

		return raceform, classform, equipset
	end
end

local swap = CreateFrame("Frame")
swap.timer = 0
do
	local function TestForm(self, event, unit)
		if InCombatLockdown() or (event == "UNIT_PORTRAIT_UPDATE" and unit ~= "player") then return end
		if event == "PLAYER_REGEN_DISABLED" then
			self:Hide()
			return
		end
		local race, class, equip = GetCurrentForm()
		local newform = self.class ~= class or self.race ~= race or self.equip ~= equip
		if event == "PLAYER_REGEN_ENABLED" and (newform or self.timer > 0) then
			self.timer = 6
			self.race = race
			self.class = class
			self.equip = equip
			self:Show()
		elseif newform then
			self.timer = 3
			self.race = race
			self.class = class
			self.equip = equip
			self:Show()
		end
	end
	function xrp:RecheckForm()
		swap.race = nil
		swap.class = nil
		swap.equip = nil
		TestForm(swap)
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

	local auto, form = xrpSaved.auto
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

	if not xrp.profiles[auto[form]] then
		auto[form] = nil
		--print("Profile was removed, deleting assignment and retrying.")
		self:Show()
		return
	end

	--print("Swapping to: "..auto[form])
	xrp.profiles[auto[form]]:Activate(true)
end)
swap:Hide()

-- Shadowform (and possibly others) don't trigger a portrait update. Worgen
-- form and equipment sets don't trigger a shapeshift update.
swap:RegisterEvent("UNIT_PORTRAIT_UPDATE")
swap:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
swap:RegisterEvent("PLAYER_REGEN_DISABLED")
swap:RegisterEvent("PLAYER_REGEN_ENABLED")
