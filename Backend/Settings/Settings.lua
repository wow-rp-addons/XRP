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

local FOLDER, _xrp = ...

_xrp.settingsToggles = {
	display = {},
}

local DATA_VERSION = 6
local DATA_VERSION_ACCOUNT = 18

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
		for section, defaults in pairs(_xrp.DEFAULT_SETTINGS) do
			if not xrpAccountSaved.settings[section] then
				xrpAccountSaved.settings[section] = {}
			end
			for option, setting in pairs(defaults) do
				xrpAccountSaved.settings[section][option] = setting
			end
		end
	end
	if not xrpSaved then
		xrpSaved = {
			auto = {},
			meta = {
				fields = {},
			},
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
		StaticPopup_Show("XRP_ERROR", _xrp.L.PROFILE_MISSING)
	end
end

function _xrp.SavedVariableSetup()
	InitializeSavedVariables()
	if (xrpAccountSaved.dataVersion or 1) < DATA_VERSION_ACCOUNT then
		for i = (xrpAccountSaved.dataVersion or 1) + 1, DATA_VERSION_ACCOUNT do
			if _xrp.UpgradeAccountVars[i] then
				xpcall(_xrp.UpgradeAccountVars[i], geterrorhandler())
			end
		end
		xrpAccountSaved.dataVersion = DATA_VERSION_ACCOUNT
	end
	if (xrpSaved.dataVersion or 1) < DATA_VERSION then
		for i = (xrpSaved.dataVersion or 1) + 1, DATA_VERSION do
			if _xrp.UpgradeVars[i] then
				xpcall(_xrp.UpgradeVars[i], geterrorhandler())
			end
		end
		xrpSaved.dataVersion = DATA_VERSION
	end
	_xrp.UpgradeAccountVars = nil
	_xrp.UpgradeVars = nil

	for section, defaults in pairs(_xrp.DEFAULT_SETTINGS) do
		if not xrpAccountSaved.settings[section] then
			xrpAccountSaved.settings[section] = {}
		end
		for option, setting in pairs(defaults) do
			if xrpAccountSaved.settings[section][option] == nil then
				xrpAccountSaved.settings[section][option] = setting
			end
		end
	end
	_xrp.settings = xrpAccountSaved.settings
end

function _xrp.LoadSettings()
	for xrpTable, category in pairs(_xrp.settingsToggles) do
		for xrpSetting, func in pairs(category) do
			xpcall(func, geterrorhandler(), _xrp.settings[xrpTable][xrpSetting], xrpSetting)
		end
	end
end

function _xrp.CacheTidy(timer, isInit)
	if type(timer) ~= "number" or timer < 30 then
		timer = _xrp.settings.cache.time
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
				_xrp.DropCache(name)
			else
				if not isInit then
					_xrp.ResetCacheTimers(name)
				end
				xrpCache[name] = nil
			end
		end
	end
	if not isInit then
		collectgarbage()
		_xrp.FireEvent("DROP", "ALL")
	end
	return true
end
