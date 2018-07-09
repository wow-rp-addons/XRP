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

_xrp.UpgradeAccountVars = {
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
		xrpAccountSaved.settings.display.preloadBookmarks = nil
		xrpAccountSaved.settings.display.preloadEditor = nil
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
	[16] = function() -- 7.0.3.0
		xrpAccountSaved.settings.chat["OFFICER"] = xrpAccountSaved.settings.chat["GUILD"]
	end,
	[18] = function() -- 7.0.3.3
		for channel, isEnabled in pairs(xrpAccountSaved.settings.chat) do
			if not isEnabled and channel:find("^CHANNEL_") then
				xrpAccountSaved.settings.chat[channel] = nil
			end
		end
	end,
}

_xrp.UpgradeVars = {
	[3] = function() -- 6.0.3.0
		if type(xrpSaved.auto) ~= "table" then
			xrpSaved.auto = {}
		end
	end,
	[6] = function() -- 6.1.2.0
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
			for field, doInherit in pairs(profile.inherits) do
				if doInherit == true then
					profile.inherits[field] = nil
				end
			end
		end
		_xrp.FireEvent("UPDATE", "FC")
	end,
}
