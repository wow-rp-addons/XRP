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

_xrp.settingsToggles = {
	display = {},
}

local DATA_VERSION = 6
local DATA_VERSION_ACCOUNT = 17

_xrp.DEFAULT_SETTINGS = {
	cache = {
		autoClean = true,
		time = 864000,
	},
	chat = {
		names = true,
		["SAY"] = true,
		["YELL"] = true,
		["EMOTE"] = true,
		["GUILD"] = false,
		["OFFICER"] = false,
		["WHISPER"] = false,
		["PARTY"] = false,
		["RAID"] = false,
		["INSTANCE_CHAT"] = false,
		emoteBraced = false,
		replacements = false,
	},
	display = {
		altBloodElf = false,
		altBloodElfForce = false,
		altNightElf = false,
		altNightElfForce = false,
		altScourge = true,
		altScourgeForce = false,
		altTauren = false,
		altTaurenForce = false,
		closeOnEscapeViewer = true,
		friendsOnly = false,
		guildIsFriends = true,
		height = "ft",
		movableViewer = false,
		weight = "lb",
	},
	interact = {
		cursor = true,
		rightClick = true,
		disableInstance = false,
		disablePvP = false,
		keybind = true,
	},
	menus = {
		standard = true,
		units = false,
	},
	minimap = {
		enabled = true,
		angle = 193,
		detached = false,
		point = "CENTER",
		x = 0,
		y = 0,
		ldbObject = false,
	},
	tooltip = {
		enabled = true,
		replace = true,
		watching = true,
		bookmark = true,
		extraSpace = false,
		showHouse = false,
		guildRank = false,
		guildIndex = false,
		noHostile = true,
		noOpFaction = false,
		noClass = false,
		noRace = false,
	},
}

local upgradeAccountVars = {
	[2] = function() -- 6.0.3.0
		local settings = xrpAccountSaved.settings
		local newSettings = {}

		newSettings.cache = {
			autoclean = settings.cachetidy,
			time = settings.cachetime,
		}

		newSettings.chat = settings.chatnames or {}
		newSettings.chat.replacements = settings.integration.replacements

		newSettings.display = {
			height = settings.height,
			weight = settings.weight,
		}

		newSettings.interact = {
			rightclick = settings.integration.rightclick,
			disableinstance = settings.integration.disableinstance,
			disablepvp = settings.integration.disablepvp,
			keybind = settings.integration.interact,
		}

		newSettings.menus = {
			standard = settings.integration.menus,
			units = settings.integration.unitmenus,
		}

		newSettings.minimap = settings.minimap or {}
		-- Minimap button was getting hidden by garrison button.
		newSettings.minimap.angle = _xrp.DEFAULT_SETTINGS.minimap.angle

		newSettings.tooltip = settings.tooltip or {}

		for section, defaults in pairs(_xrp.DEFAULT_SETTINGS) do
			for option, setting in pairs(defaults) do
				if newSettings[section][option] == nil then
					newSettings[section][option] = setting
				end
			end
		end

		xrpAccountSaved.settings = newSettings
	end,
	[5] = function() -- 6.0.3.0
		local settings = xrpAccountSaved.settings
		settings.minimap.hidett = nil
		settings.tooltip.faction = nil

		if settings.cache.autoclean ~= nil then
			settings.cache.autoClean = settings.cache.autoclean
			settings.cache.autoclean = nil
		end
		if settings.chat.rpnames ~= nil then
			settings.chat.names = settings.chat.rpnames
			settings.chat.rpnames = nil
		end
		if settings.interact.rightclick ~= nil then
			settings.interact.cursor = settings.interact.rightclick
			settings.interact.rightClick = _xrp.DEFAULT_SETTINGS.interact.rightClick
			settings.interact.rightclick = nil
		end

		local now = time()
		for name, data in pairs(xrpCache) do
			if not data.lastReceive then
				if not data.lastreceive or data.lastreceive == 2147483647 then
					data.lastReceive = now
					data.lastreceive = nil
				else
					data.lastReceive = data.lastreceive
					data.lastreceive = nil
				end
			end
		end
	end,
	[6] = function() -- 6.0.3.2
		local settings = xrpAccountSaved.settings
		if settings.cache.autoclean ~= nil then
			settings.cache.autoclean = nil
		end
		if settings.chat.emotebraced ~= nil then
			settings.chat.emoteBraced = settings.chat.emotebraced
			settings.chat.emotebraced = nil
		end
		if settings.interact.rightclick ~= nil then
			settings.interact.cursor = settings.interact.rightclick
			settings.interact.rightclick = nil
		end
		if settings.interact.disableinstance ~= nil then
			settings.interact.disableInstance = settings.interact.disableinstance
			settings.interact.disableinstance = nil
		end
		if settings.interact.disablepvp ~= nil then
			settings.interact.disablePvP = settings.interact.disablepvp
			settings.interact.disablepvp = nil
		end
		if settings.tooltip.extraspace ~= nil then
			settings.tooltip.extraSpace = settings.tooltip.extraspace
			settings.tooltip.extraspace = nil
		end
		if settings.tooltip.guildrank ~= nil then
			settings.tooltip.guildRank = settings.tooltip.guildrank
			settings.tooltip.guildrank = nil
		end
		if settings.tooltip.guildindex ~= nil then
			settings.tooltip.guildIndex = settings.tooltip.guildindex
			settings.tooltip.guildindex = nil
		end
		if settings.tooltip.nohostile ~= nil then
			settings.tooltip.noHostile = settings.tooltip.nohostile
			settings.tooltip.nohostile = nil
		end
		if settings.tooltip.noopfaction ~= nil then
			settings.tooltip.noOpFaction = settings.tooltip.noopfaction
			settings.tooltip.noopfaction = nil
		end
		if settings.tooltip.norpclass ~= nil then
			settings.tooltip.noClass = settings.tooltip.norpclass
			settings.tooltip.norpclass = nil
		end
		if settings.tooltip.norprace ~= nil then
			settings.tooltip.noRace = settings.tooltip.norprace
			settings.tooltip.norprace = nil
		end
		settings.display.movableViewer = _xrp.DEFAULT_SETTINGS.display.movableViewer
	end,
	[7] = function() -- 6.0.3.3
		if xrpAccountSaved.settings.display.preloadViewer == true and xrpAccountSaved.settings.display.movableViewer == true then
			-- Preserve current behaviour for users with viewer made movable.
			xrpAccountSaved.settings.display.closeOnEscapeViewer = false
		else
			-- Make sure movable viewer is disabled if it would be disabled
			-- for them (i.e., preload disabled or movable disabled).
			xrpAccountSaved.settings.display.movableViewer = false
			xrpAccountSaved.settings.display.closeOnEscapeViewer = _xrp.DEFAULT_SETTINGS.display.closeOnEscapeViewer
		end
		xrpAccountSaved.settings.display.preloadViewer = nil
	end,
	[9] = function() -- 6.1.0.0
		if not xrpAccountSaved.bookmarks then
			xrpAccountSaved.bookmarks = {}
		end
		if not xrpAccountSaved.hidden then
			xrpAccountSaved.hidden = {}
		end
		for name, cache in pairs(xrpCache) do
			if cache.bookmark then
				xrpAccountSaved.bookmarks[name] = cache.bookmark
				cache.bookmark = nil
			end
			if cache.hide then
				xrpAccountSaved.hidden[name] = true
				cache.hide = nil
				if not next(cache.fields) then
					xrpCache[name] = nil
				end
			end
		end
		xrpAccountSaved.settings.tooltip.replace = _xrp.DEFAULT_SETTINGS.tooltip.replace
		xrpAccountSaved.settings.display.preloadBookmarks = nil
		xrpAccountSaved.settings.display.preloadEditor = nil
	end,
	[10] = function() -- 6.1.2.0
		xrpAccountSaved.settings.display.altBloodElf = _xrp.DEFAULT_SETTINGS.display.altBloodElf
		xrpAccountSaved.settings.display.altBloodElfForce = _xrp.DEFAULT_SETTINGS.display.altBloodElfForce
		xrpAccountSaved.settings.display.altNightElf = _xrp.DEFAULT_SETTINGS.display.altNightElf
		xrpAccountSaved.settings.display.altNightElfForce = _xrp.DEFAULT_SETTINGS.display.altNightElfForce
		xrpAccountSaved.settings.display.altScourge = _xrp.DEFAULT_SETTINGS.display.altScourge
		xrpAccountSaved.settings.display.altScourgeForce = _xrp.DEFAULT_SETTINGS.display.altScourgeForce
		xrpAccountSaved.settings.display.altTauren = _xrp.DEFAULT_SETTINGS.display.altTauren
		xrpAccountSaved.settings.display.altTaurenForce = _xrp.DEFAULT_SETTINGS.display.altTaurenForce
	end,
	[12] = function() -- 6.1.2.0
		if not xrpAccountSaved.notes then
			xrpAccountSaved.notes = {}
		end
	end,
	[13] = function() -- 6.2.2.2
		for name, cache in pairs(xrpCache) do
			cache.fields.reliable = nil
		end
	end,
	[14] = function() -- 6.2.3.1
		xrpAccountSaved.settings.minimap.ldbObject = _xrp.DEFAULT_SETTINGS.minimap.ldbObject
		xrpAccountSaved.settings.tooltip.bookmark = _xrp.DEFAULT_SETTINGS.tooltip.bookmark
		local newSettings = {}
		for setting, value in pairs(xrpAccountSaved.settings.chat) do
			if setting:find("^CHAT_MSG_") then
				xrpAccountSaved.settings.chat[setting] = nil
				newSettings[setting:match("^CHAT_MSG_(.+)$")] = value
			end
		end
		for setting, value in pairs(newSettings) do
			xrpAccountSaved.settings.chat[setting] = value
		end
	end,
	[15] = function() -- 6.2.4.0
		xrpAccountSaved.settings.display.friendsOnly = _xrp.DEFAULT_SETTINGS.display.friendsOnly
		xrpAccountSaved.settings.display.guildIsFriends = _xrp.DEFAULT_SETTINGS.display.guildIsFriends
	end,
	[16] = function() -- 7.0.3.0
		xrpAccountSaved.settings.chat["OFFICER"] = xrpAccountSaved.settings.chat["GUILD"]
	end,
	[17] = function() -- 7.0.3.2
		xrpAccountSaved.settings.tooltip.showHouse = _xrp.DEFAULT_SETTINGS.tooltip.showHouse
	end,
}

local upgradeVars = {
	[3] = function() -- 6.0.3.0
		if type(xrpSaved.auto) ~= "table" then
			xrpSaved.auto = {}
		end
		xrpSaved.versions.VP = nil
	end,
	[6] = function() -- 6.1.2.0
		xrpSaved.versions.FC = nil
		for name, profile in pairs(xrpSaved.profiles) do
			if name == "SELECTED" then
				local newName = _xrp.L.RENAMED_FORMAT:format("SELECTED")
				if xrpSaved.selected == name then
					xrpSaved.selected = newName
				end
				for inhName, inhProfile in pairs(xrpSaved.profiles) do
					if inhProfile.parent == name then
						inhProfile.parent = newName
					end
				end
				xrpSaved.profiles[newName] = profile
				xrpSaved.profiles[name] = nil
				break
			end
		end
		for name, profile in pairs(xrpSaved.profiles) do
			for field, contents in pairs(profile.fields) do
				if field == "FC" then
					profile.versions[field] = _xrp.NewVersion(field, contents)
					break
				end
			end
			for field, doInherit in pairs(profile.inherits) do
				if doInherit == true then
					profile.inherits[field] = nil
				end
			end
		end
		for field, contents in pairs(xrpSaved.meta.fields) do
			if field == "FC" then
				xrpSaved.meta.versions[field] = _xrp.NewVersion(field, contents)
				break
			end
		end
		_xrp.FireEvent("UPDATE", "FC")
	end,
}

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
				versions = {},
			},
			overrides = {
				fields = {},
				versions = {},
			},
			profiles = {
				[DEFAULT] = {
					fields = {},
					inherits = {},
					versions = {},
				},
			},
			selected = DEFAULT,
			versions = {},
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
				versions = {},
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
			if upgradeAccountVars[i] then
				upgradeAccountVars[i]()
			end
		end
		xrpAccountSaved.dataVersion = DATA_VERSION_ACCOUNT
	end
	if (xrpSaved.dataVersion or 1) < DATA_VERSION then
		for i = (xrpSaved.dataVersion or 1) + 1, DATA_VERSION do
			if upgradeVars[i] then
				upgradeVars[i]()
			end
		end
		xrpSaved.dataVersion = DATA_VERSION
	end
	upgradeAccountVars = nil
	upgradeVars = nil

	_xrp.settings = xrpAccountSaved.settings
end

function _xrp.LoadSettings()
	for xrpTable, category in pairs(_xrp.settingsToggles) do
		for xrpSetting, func in pairs(category) do
			func(_xrp.settings[xrpTable][xrpSetting])
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
