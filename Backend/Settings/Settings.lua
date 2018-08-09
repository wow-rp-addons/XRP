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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

AddOn.SettingsToggles = {}

local DATA_VERSION = 7
local DATA_VERSION_ACCOUNT = 19

local function InitializeSavedVariables()
	if not xrpCache then
		xrpCache = {}
	end
	if not xrpAccountSaved then
		xrpAccountSaved = {
			bookmarks = {},
			hidden = {},
			notes = {},
			settings = {},
			dataVersion = DATA_VERSION_ACCOUNT,
		}
		for optionName, setting in pairs(AddOn.DEFAULT_SETTINGS) do
			if type(setting) == "table" then
				xrpAccountSaved.settings[optionName] = {}
				for subOptionName, subSetting in pairs(setting) do
					xrpAccountSaved.settings[optionName][subOptionName] = subSetting
				end
			else
				xrpAccountSaved.settings[optionName] = setting
			end
		end
	end
	if not xrpSaved then
		xrpSaved = {
			auto = {},
			overrides = {
				fields = {},
			},
			profiles = {
				[DEFAULT] = {
					fields = {},
					inherits = {},
				},
			},
			selected = DEFAULT,
			dataVersion = DATA_VERSION,
		}
	elseif not xrpSaved.selected or not xrpSaved.profiles[xrpSaved.selected] then
		-- Something is very wrong, try to fix it.
		if xrpSaved.profiles[DEFAULT] then
			-- Try to set default.
			xrpSaved.selected = DEFAULT
		elseif next(xrpSaved.profiles) then
			-- Try to set any profile.
			local profileName, profile = next(xrpSaved.profiles)
			xrpSaved.selected = profileName
		else
			-- Make a new empty profile.
			xrpSaved.profiles[DEFAULT] = {
				fields = {},
				inherits = {},
			}
			xrpSaved.selected = DEFAULT
		end
		StaticPopup_Show("XRP_ERROR", L"Your active profile was not available to be used and XRP has tried to select an alternate profile.\n\nThis should not have happened and may indicate data corruption -- you should check your profiles for any problems.")
	end
end

function AddOn.SavedVariableSetup()
	InitializeSavedVariables()
	if (xrpAccountSaved.dataVersion or 1) < DATA_VERSION_ACCOUNT then
		for i = (xrpAccountSaved.dataVersion or 1) + 1, DATA_VERSION_ACCOUNT do
			if AddOn.UpgradeAccountVars[i] then
				xpcall(AddOn.UpgradeAccountVars[i], geterrorhandler())
			end
		end
		xrpAccountSaved.dataVersion = DATA_VERSION_ACCOUNT
	end
	if (xrpSaved.dataVersion or 1) < DATA_VERSION then
		for i = (xrpSaved.dataVersion or 1) + 1, DATA_VERSION do
			if AddOn.UpgradeVars[i] then
				xpcall(AddOn.UpgradeVars[i], geterrorhandler())
			end
		end
		xrpSaved.dataVersion = DATA_VERSION
	end
	AddOn.UpgradeAccountVars = nil
	AddOn.UpgradeVars = nil

	for optionName, setting in pairs(AddOn.DEFAULT_SETTINGS) do
		if type(setting) == "table" then
			if not xrpAccountSaved.settings[optionName] then
				xrpAccountSaved.settings[optionName] = {}
			end
			for subOptionName, subSetting in pairs(setting) do
				if xrpAccountSaved.settings[optionName][subOptionName] == nil then
					xrpAccountSaved.settings[optionName][subOptionName] = subSetting
				end
			end
		elseif xrpAccountSaved.settings[optionName] == nil then
			xrpAccountSaved.settings[optionName] = setting
		end
	end
	AddOn.Settings = xrpAccountSaved.settings
end

function AddOn.LoadSettings()
	for xrpSetting, func in pairs(AddOn.SettingsToggles) do
		xpcall(func, geterrorhandler(), AddOn.Settings[xrpSetting], xrpSetting)
	end
end

function AddOn.CacheTidy(timer, isInit)
	if type(timer) ~= "number" or timer < 30 then
		timer = AddOn.Settings.cacheRetainTime
		if type(timer) ~= "number" or timer < 30 then
			return false
		end
	end
	local doDrop = not isInit and timer > 60
	local now = time()
	local before = now - timer
	local beforeOwn = now - math.max(timer * 3, 604800)
	local bookmarks, notes = xrpAccountSaved.bookmarks, xrpAccountSaved.notes
	for name, data in pairs(xrpCache) do
		if type(data.lastReceive) ~= "number" then
			data.lastReceive = now
		elseif not bookmarks[name] and not notes[name] and (not data.own and data.lastReceive < before or data.own and data.lastReceive < beforeOwn) then
			if doDrop then
				AddOn.DropCache(name)
			else
				if not isInit then
					AddOn.ResetCacheTimers(name)
				end
				xrpCache[name] = nil
			end
		end
	end
	if not isInit then
		collectgarbage()
		AddOn.RunEvent("DROP", "ALL")
	end
	return true
end
