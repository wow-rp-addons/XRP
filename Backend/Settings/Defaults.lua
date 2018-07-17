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
	-- Cache
	cacheAutoClean = true,
	cacheRetainTime = 864000,

	-- Chat
	chatNames = true,
	chatEmoteBraced = false,
	chatReplacements = false,

	-- Chat channels
	chatType = {
		["SAY"] = true,
		["YELL"] = true,
		["EMOTE"] = true,
		["GUILD"] = false,
		["OFFICER"] = false,
		["WHISPER"] = false,
		["PARTY"] = false,
		["RAID"] = false,
		["INSTANCE_CHAT"] = false,
	},

	-- Alternate race names
	altScourge = true,
	altScourgeLimit = false,
	altScourgeForce = false,
	altElven = false,
	altElvenLimit = true,
	altElvenForce = false,
	altTauren = false,
	altTaurenLimit = true,
	altTaurenForce = false,

	-- Viewer
	viewerCloseOnEscape = true,
	viewerMovable = false,

	-- Restricted mode
	friendsOnly = false,
	friendsIncludeGuild = true,

	-- Units
	heightUnits = "ft",
	weightUnits = "lb",

	-- Interaction cursor
	cursorEnabled = true,
	cursorRightClick = true,
	cursorDisableInstance = false,
	cursorDisablePvP = false,

	-- Keybind hook
	viewOnInteract = true,

	-- UnitPopup menus
	menusChat = true,
	menusUnit = false,

	-- LDB
	ldbObject = false,

	-- Buttons
	mainButtonEnabled = true,
	mainButtonDetached = false,
	mainButtonMinimapAngle = 193,
	mainButtonDetachedX = 0,
	mainButtonDetachedY = 0,
	mainButtonDetachedPoint = "CENTER",

	-- Tooltip
	tooltipEnabled = true,
	tooltipReplace = true,
	tooltipShowWatchEye = true,
	tooltipShowBookmarkFlag = true,
	tooltipShowExtraSpace = false,
	tooltipShowHouse = false,
	tooltipShowGuildRank = false,
	tooltipShowGuildIndex = false,
	tooltipHideHostile = true,
	tooltipHideOppositeFaction = false,
	tooltipHideInstanceCombat = false,
	tooltipHideClass = false,
	tooltipHideRace = false,
}
