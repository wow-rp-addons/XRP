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

xrpPrivate.settingsToggles = {
	display = {},
}

local DATA_VERSION = 3
local DATA_VERSION_ACCOUNT = 9

local DEFAULT_SETTINGS = {
	cache = {
		autoClean = true,
		time = 864000,
	},
	chat = {
		names = true,
		["CHAT_MSG_SAY"] = true,
		["CHAT_MSG_YELL"] = true,
		["CHAT_MSG_EMOTE"] = true, -- CHAT_MSG_TEXT_EMOTE.
		["CHAT_MSG_GUILD"] = false, -- CHAT_MSG_OFFICER.
		["CHAT_MSG_WHISPER"] = false, -- CHAT_MSG_WHISPER_*, CHAT_MSG_AFK, CHAT_MSG_DND
		["CHAT_MSG_PARTY"] = false, -- CHAT_MSG_PARTY_LEADER
		["CHAT_MSG_RAID"] = false, -- CHAT_MSG_RAID_LEADER
		["CHAT_MSG_INSTANCE_CHAT"] = false, -- CHAT_MSG_INSTANCE_CHAT_LEADER
		emoteBraced = false,
		replacements = true,
	},
	display = {
		closeOnEscapeViewer = true,
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
		angle = 200,
		detached = false,
		point = "CENTER",
		x = 0,
		y = 0,
	},
	tooltip = {
		enabled = true,
		replace = true,
		watching = false,
		extraSpace = false,
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
		newSettings.minimap.angle = DEFAULT_SETTINGS.minimap.angle

		newSettings.tooltip = settings.tooltip or {}

		for section, defaults in pairs(DEFAULT_SETTINGS) do
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
			settings.interact.rightClick = DEFAULT_SETTINGS.interact.rightClick
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
		C_Timer.After(6, function() print("XRP has been updated to 6.0.3.0+. Please note that if you were formerly disabling the tooltip or chat names via the addons menu, those settings are now found in the XRP interface options.") end)
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
		settings.display.movableViewer = DEFAULT_SETTINGS.display.movableViewer
	end,
	[7] = function() -- 6.0.3.3
		if xrpAccountSaved.settings.display.preloadViewer == true and xrpAccountSaved.settings.display.movableViewer == true then
			-- Preserve current behaviour for users with viewer made movable.
			xrpAccountSaved.settings.display.closeOnEscapeViewer = false
		else
			-- Make sure movable viewer is disabled if it would be disabled
			-- for them (i.e., preload disabled or movable disabled).
			xrpAccountSaved.settings.display.movableViewer = false
			xrpAccountSaved.settings.display.closeOnEscapeViewer = DEFAULT_SETTINGS.display.closeOnEscapeViewer
		end
		xrpAccountSaved.settings.display.preloadViewer = nil
	end,
	[8] = function() -- 6.1.0.0
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
	end,
	[9] = function() -- 6.1.0.0
		xrpAccountSaved.settings.tooltip.replace = DEFAULT_SETTINGS.tooltip.replace
		xrpAccountSaved.settings.display.preloadBookmarks = nil
		xrpAccountSaved.settings.display.preloadEditor = nil
	end,
}

local upgradeVars = {
	[3] = function() -- 6.0.3.0
		if type(xrpSaved.auto) ~= "table" then
			xrpSaved.auto = {}
		end
		xrpSaved.versions.VP = nil
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
			settings = {},
			dataVersion = DATA_VERSION_ACCOUNT,
		}
		for section, defaults in pairs(DEFAULT_SETTINGS) do
			if not xrpAccountSaved.settings[section] then
				xrpAccountSaved.settings[section] = {}
			end
			for option, setting in pairs(defaults) do
				if xrpAccountSaved.settings[section][option] == nil then
					xrpAccountSaved.settings[section][option] = setting
				end
			end
		end
	end
	if not xrpSaved then
		if type(xrp_profiles) == "table" then
			xrpSaved = {
				meta = {
					fields = {},
					versions = {},
				},
				overrides = {
					fields = {},
					versions = {},
				},
				profiles = xrp_profiles,
				selected = xrp_selectedprofile,
				versions = xrp_versions or {},
				dataVersion = 1, -- Leave this at 1.
			}
			for name, profile in pairs(xrpSaved.profiles) do
				if type(profile.versions) ~= "table" then
					profile.versions = {}
					for field, contents in pairs(profile.fields) do
						profile.versions[field] = xrpPrivate:NewVersion(field)
					end
				end
				if type(profile.inherits) ~= "table" then
					profile.inherits = profile.defaults or {}
					profile.defaults = nil
					if name ~= "Default" then
						profile.parent = "Default"
					end
				end
				if name == "Add" or name == "List" then
					xrpSaved.profiles[name .. " Renamed"] = profile
					if xrpSaved.selected == name then
						xrpSaved.selected = name .. " Renamed"
					end
					xrpSaved.profiles[name] = nil
				end
			end
		else
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
					["Default"] = {
						fields = {},
						inherits = {},
						versions = {},
					},
				},
				selected = "Default",
				versions = {},
				dataVersion = DATA_VERSION,
			}
		end
	end
end

function xrpPrivate:SavedVariableSetup()
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

	self.settings = xrpAccountSaved.settings
end

function xrpPrivate:LoadSettings()
	for xrpTable, category in pairs(self.settingsToggles) do
		for xrpSetting, func in pairs(category) do
			func(self.settings[xrpTable][xrpSetting])
		end
	end
end

function xrpPrivate:CacheTidy(timer)
	if type(timer) ~= "number" or timer < 30 then
		timer = self.settings.cache.time
		if type(timer) ~= "number" or timer < 30 then
			return false
		end
	end
	local now = time()
	local before = now - timer
	local beforeOwn = now - math.max(timer * 3, 604800)
	local bookmarks = xrpAccountSaved.bookmarks
	for name, data in pairs(xrpCache) do
		if type(data.lastReceive) ~= "number" then
			data.lastReceive = now
		elseif not data.own and not bookmarks[name] and data.lastReceive < before then
			xrpCache[name] = nil
		elseif data.own and not bookmarks[name] and data.lastReceive < beforeOwn then
			xrpCache[name] = nil
		end
	end
	if timer <= 60 then
		-- Explicitly collect garbage, as there may be a hell of a lot of it
		-- (the user probably clicked "Clear Cache" in the options).
		collectgarbage()
	end
	return true
end
