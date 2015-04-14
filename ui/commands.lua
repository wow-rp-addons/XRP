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
local _S = xrpLocal.strings

local SLASH_XRP = _S.SLASH_XRP or "/xrp"
do
	local INFO = STAT_FORMAT:format("|cff99b3e6%s") .. "|r %s"
	-- Also used in ui/options.xml.
	XRP_AUTHOR = INFO:format(_S.AUTHOR, GetAddOnMetadata(addonName, "Author"))
	XRP_VERSION = INFO:format(GAME_VERSION_LABEL, xrpLocal.version)
end

-- Cannot define commands in static table, as they make use of each other.
local xrpCmds = {}

xrpCmds.about = function(args)
	print(("|cffabd473%s|r"):format(GetAddOnMetadata(addonName, "Title")))
	print(XRP_AUTHOR)
	print(XRP_VERSION)
	for line in _S.GPL_SHORT:gmatch("[^\n]+") do
		print(line)
	end
end

do
	local USAGE = ("|cffabd473%s|r %%s"):format(STAT_FORMAT:format(_S.USAGE))
	local ARG = (" - |cfffff569%s|r %%s"):format(STAT_FORMAT:format("%s"))
	local NO_ARGS = SLASH_XRP .. " %s"
	local HAS_ARGS = SLASH_XRP .. " %s %s"
	xrpCmds.help = function(args)
		if args == "about" or args and args == _S.CMD_ABOUT then
			print(USAGE:format(NO_ARGS:format(_S.CMD_ABOUT)))
			print(_S.ABOUT_HELP)
		elseif args == "bookmarks" or args and args == _S.CMD_BOOKMARKS then
			print(USAGE:format(NO_ARGS:format(_S.CMD_BOOKMARKS)))
			print(_S.BOOKMARKS_HELP)
		elseif args == "edit" or args and args == _S.CMD_EDIT then
			print(USAGE:format(HAS_ARGS:format(_S.CMD_EDIT, _S.EDIT_ARGS)))
			print(ARG:format(_S.EDIT_ARG1, _S.EDIT_ARG1_HELP))
			print(ARG:format(_S.EDIT_ARG2, _S.EDIT_ARG2_HELP))
		elseif args == "export" or args and args == _S.CMD_EXPORT then
			print(USAGE:format(HAS_ARGS:format(_S.CMD_EXPORT, _S.EXPORT_ARG1)))
			print(ARG:format(_S.EXPORT_ARG1, _S.EXPORT_ARG1_HELP))
		elseif args == "profile" or args and args == _S.CMD_PROFILE then
			print(USAGE:format(HAS_ARGS:format(_S.CMD_PROFILE, _S.PROFILE_ARGS)))
			print(ARG:format(_S.ARG_PROFILE_LIST, _S.PROFILE_ARG1_HELP))
			print(ARG:format(_S.PROFILE_ARG2, _S.PROFILE_ARG2_HELP))
		elseif args == "status" or args and args == _S.CMD_STATUS then
			print(USAGE:format(HAS_ARGS:format(_S.CMD_STATUS, _S.STATUS_ARGS)))
			print(ARG:format(_S.ARG_STATUS_NIL, _S.STATUS_ARG1_HELP))
			print(ARG:format(_S.ARG_STATUS_IC, _S.STATUS_ARG2_HELP))
			print(ARG:format(_S.ARG_STATUS_OOC, _S.STATUS_ARG3_HELP))
			print(ARG:format(_S.ARG_STATUS_LFC, _S.STATUS_ARG4_HELP))
			print(ARG:format(_S.ARG_STATUS_ST, _S.STATUS_ARG5_HELP))
		elseif args == "toggle" or args and args == _S.CMD_TOGGLE then
			print(USAGE:format(NO_ARGS:format(_S.CMD_TOGGLE)))
			print(_S.TOGGLE_HELP)
		elseif args == "view" or args == "show" or args and args == _S.CMD_VIEW then
			print(USAGE:format(HAS_ARGS:format(_S.CMD_VIEW, _S.VIEW_ARGS)))
			print(ARG:format(_S.VIEW_ARG1, _S.VIEW_ARG1_HELP))
			print(ARG:format(_S.VIEW_ARG2, _S.VIEW_ARG2_HELP))
			print(ARG:format(_S.VIEW_ARG3, _S.VIEW_ARG3_HELP))
		else
			print(USAGE:format(HAS_ARGS:format(_S.COMMANDS, _S.ARGUMENTS)))
			print(_S.COMMANDS_HELP)
			print(ARG:format(_S.CMD_ABOUT, _S.ABOUT_HELP))
			print(ARG:format(_S.CMD_BOOKMARKS, _S.BOOKMARKS_HELP))
			print(ARG:format(_S.CMD_EDIT, _S.EDIT_HELP))
			print(ARG:format(_S.CMD_EXPORT, _S.EXPORT_HELP))
			print(ARG:format(_S.CMD_HELP, _S.HELP_HELP))
			print(ARG:format(_S.CMD_PROFILE, _S.PROFILE_HELP))
			print(ARG:format(_S.CMD_STATUS, _S.STATUS_HELP))
			print(ARG:format(_S.CMD_TOGGLE, _S.TOGGLE_HELP))
			print(ARG:format(_S.CMD_VIEW, _S.VIEW_HELP))
		end
	end
end

xrpCmds.edit = function(args)
	XRPEditor:Edit(args)
end

xrpCmds.bookmarks = function(args)
	XRPBookmarks:Toggle(1)
end

xrpCmds.export = function(args)
	local name = xrp:Name(args:match("^[^%s]+"))
	if not name then return end
	name = name:gsub("^%l", string.upper)
	XRPExport:Export(xrp:Ambiguate(name), tostring(xrp.characters.noRequest.byName[name].fields))
end

xrpCmds.profile = function(args)
	if args == "list" or args == _S.ARG_PROFILE_LIST then
		print(STAT_FORMAT:format(_S.PROFILES))
		for i, profile in ipairs(xrp.profiles:List()) do
			print(profile)
		end
	elseif type(args) == "string" then
		if xrp.profiles[args] and xrp.profiles[args]:Activate() then
			print(_S.SET_PROFILE::format(args))
		else
			print(_S.SET_PROFILE_FAIL:format(args))
		end
	else
		xrpCmds.help("profile")
	end
end

xrpCmds.status = function(args)
	if args == "nil" or args == _S.ARG_STATUS_NIL then
		xrp.current.fields.FC = nil
	elseif args == "ooc" or args == _S.ARG_STATUS_IC then
		xrp.current.fields.FC = "1"
	elseif args == "ic" or args == _S.ARG_STATUS_OOC then
		xrp.current.fields.FC = "2"
	elseif args == "lfc" or args == _S.ARG_STATUS_LFC then
		xrp.current.fields.FC = "3"
	elseif args == "st" or args == _S.ARG_STATUS_ST then
		xrp.current.fields.FC = "4"
	else
		xrpCmds.help("status")
	end
end

xrpCmds.toggle = function(args)
	xrp:Status()
end

xrpCmds.view = function(args)
	if not args and UnitIsPlayer("target") then
		args = "target"
	elseif not args and UnitIsPlayer("mouseover") then
		args = "mouseover"
	end
	XRPViewer:View(args)
end

-- This allows /xrp show to match /mrp show. This is not localized by MRP,
-- so there is no localization for it here.
xrpCmds.show = xrpCmds.view

-- Localized aliases.
if _S.CMD_ABOUT ~= "about" then
	xrpCmds[_S.CMD_ABOUT] = xrpCmds.about
end
if _S.CMD_BOOKMARKS ~= "bookmarks" then
	xrpCmds[_S.CMD_BOOKMARKS] = xrpCmds.bookmarks
end
if _S.CMD_EDIT ~= "edit" then
	xrpCmds[_S.CMD_EDIT] = xrpCmds.edit
end
if _S.CMD_EXPORT ~= "export" then
	xrpCmds[_S.CMD_EXPORT] = xrpCmds.export
end
if _S.CMD_HELP ~= "help" then
	xrpCmds[_S.CMD_HELP] = xrpCmds.help
end
if _S.CMD_PROFILE ~= "profile" then
	xrpCmds[_S.CMD_PROFILE] = xrpCmds.profile
end
if _S.CMD_STATUS ~= "status" then
	xrpCmds[_S.CMD_STATUS] = xrpCmds.status
end
if _S.CMD_TOGGLE ~= "toggle" then
	xrpCmds[_S.CMD_TOGGLE] = xrpCmds.toggle
end
if _S.CMD_VIEW ~= "view" then
	xrpCmds[_S.CMD_VIEW] = xrpCmds.view
end

SLASH_XRP1 = "/xrp"
if SLASH_XRP ~= "/xrp" then
	SLASH_XRP2 = SLASH_XRP
end

SlashCmdList["XRP"] = function(input, editBox)
	local command, args = input:match("^([^%s]+)%s*(.*)$")
	if command and xrpCmds[command:lower()] then
		xrpCmds[command:lower()](args ~= "" and args or nil)
	else
		xrpCmds["help"](args ~= "" and args or nil)
	end
end
