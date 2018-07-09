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
		altScourge = true,
		altScourgeLimit = false,
		altScourgeForce = false,
		altBloodElf = false,
		altBloodElfLimit = true,
		altBloodElfForce = false,
		altNightElf = false,
		altNightElfLimit = true,
		altNightElfForce = false,
		altTauren = false,
		altTaurenLimit = true,
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
		noCombatInstance = false,
		noClass = false,
		noRace = false,
		oldColors = false,
	},
}
