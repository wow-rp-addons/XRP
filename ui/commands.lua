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

local SLASH_XRP = _xrp.L.SLASH_XRP or "/xrp"
do
	local INFO = STAT_FORMAT:format("|cff99b3e6%s") .. "|r %s"
	-- Also used in ui/options.xml.
	XRP_AUTHOR = INFO:format(_xrp.L.AUTHOR, GetAddOnMetadata(addonName, "Author"))
	XRP_VERSION = INFO:format(GAME_VERSION_LABEL, _xrp.version)
end

-- Cannot define commands in static table, as they make use of each other.
local xrpCmds = {}

xrpCmds.about = function(args)
	print(("|cffabd473%s|r"):format(GetAddOnMetadata(addonName, "Title")))
	print(XRP_AUTHOR)
	print(XRP_VERSION)
	for line in _xrp.L.GPL_SHORT:gmatch("[^\n]+") do
		print(line)
	end
end

do
	local USAGE = ("|cffabd473%s|r %%s"):format(STAT_FORMAT:format(_xrp.L.USAGE))
	local ARG = (" - |cfffff569%s|r %%s"):format(STAT_FORMAT:format("%s"))
	local NO_ARGS = SLASH_XRP .. " %s"
	local HAS_ARGS = SLASH_XRP .. " %s %s"
	xrpCmds.help = function(args)
		if args == "about" or args and args == _xrp.L.CMD_ABOUT then
			print(USAGE:format(NO_ARGS:format(_xrp.L.CMD_ABOUT)))
			print(_xrp.L.ABOUT_HELP)
		elseif args == "bookmarks" or args and args == _xrp.L.CMD_BOOKMARKS then
			print(USAGE:format(NO_ARGS:format(_xrp.L.CMD_BOOKMARKS)))
			print(_xrp.L.BOOKMARKS_HELP)
		elseif args == "edit" or args and args == _xrp.L.CMD_EDIT then
			print(USAGE:format(HAS_ARGS:format(_xrp.L.CMD_EDIT, _xrp.L.EDIT_ARGS)))
			print(ARG:format(_xrp.L.EDIT_ARG1, _xrp.L.EDIT_ARG1_HELP))
			print(ARG:format(_xrp.L.EDIT_ARG2, _xrp.L.EDIT_ARG2_HELP))
		elseif args == "export" or args and args == _xrp.L.CMD_EXPORT then
			print(USAGE:format(HAS_ARGS:format(_xrp.L.CMD_EXPORT, _xrp.L.EXPORT_ARG1)))
			print(ARG:format(_xrp.L.EXPORT_ARG1, _xrp.L.EXPORT_ARG1_HELP))
		elseif args == "profile" or args and args == _xrp.L.CMD_PROFILE then
			print(USAGE:format(HAS_ARGS:format(_xrp.L.CMD_PROFILE, _xrp.L.PROFILE_ARGS)))
			print(ARG:format(_xrp.L.ARG_PROFILE_LIST, _xrp.L.PROFILE_ARG1_HELP))
			print(ARG:format(_xrp.L.PROFILE_ARG2, _xrp.L.PROFILE_ARG2_HELP))
		elseif args == "status" or args and args == _xrp.L.CMD_STATUS then
			print(USAGE:format(HAS_ARGS:format(_xrp.L.CMD_STATUS, _xrp.L.STATUS_ARGS)))
			print(ARG:format(_xrp.L.ARG_STATUS_NIL, _xrp.L.STATUS_ARG1_HELP))
			print(ARG:format(_xrp.L.ARG_STATUS_IC, _xrp.L.STATUS_ARG2_HELP))
			print(ARG:format(_xrp.L.ARG_STATUS_OOC, _xrp.L.STATUS_ARG3_HELP))
			print(ARG:format(_xrp.L.ARG_STATUS_LFC, _xrp.L.STATUS_ARG4_HELP))
			print(ARG:format(_xrp.L.ARG_STATUS_ST, _xrp.L.STATUS_ARG5_HELP))
		elseif args == "toggle" or args and args == _xrp.L.CMD_TOGGLE then
			print(USAGE:format(NO_ARGS:format(_xrp.L.CMD_TOGGLE)))
			print(_xrp.L.TOGGLE_HELP)
		elseif args == "view" or args == "show" or args and args == _xrp.L.CMD_VIEW then
			print(USAGE:format(HAS_ARGS:format(_xrp.L.CMD_VIEW, _xrp.L.VIEW_ARGS)))
			print(ARG:format(_xrp.L.VIEW_ARG1, _xrp.L.VIEW_ARG1_HELP))
			print(ARG:format(_xrp.L.VIEW_ARG2, _xrp.L.VIEW_ARG2_HELP))
			print(ARG:format(_xrp.L.VIEW_ARG3, _xrp.L.VIEW_ARG3_HELP))
		else
			print(USAGE:format(HAS_ARGS:format(_xrp.L.COMMANDS, _xrp.L.ARGUMENTS)))
			print(_xrp.L.COMMANDS_HELP)
			print(ARG:format(_xrp.L.CMD_ABOUT, _xrp.L.ABOUT_HELP))
			print(ARG:format(_xrp.L.CMD_BOOKMARKS, _xrp.L.BOOKMARKS_HELP))
			print(ARG:format(_xrp.L.CMD_EDIT, _xrp.L.EDIT_HELP))
			print(ARG:format(_xrp.L.CMD_EXPORT, _xrp.L.EXPORT_HELP))
			print(ARG:format(_xrp.L.CMD_HELP, _xrp.L.HELP_HELP))
			print(ARG:format(_xrp.L.CMD_PROFILE, _xrp.L.PROFILE_HELP))
			print(ARG:format(_xrp.L.CMD_STATUS, _xrp.L.STATUS_HELP))
			print(ARG:format(_xrp.L.CMD_TOGGLE, _xrp.L.TOGGLE_HELP))
			print(ARG:format(_xrp.L.CMD_VIEW, _xrp.L.VIEW_HELP))
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
	local name = xrp.FullName(args:match("^[^%s]+"))
	if not name then return end
	name = name:gsub("^%l", string.upper)
	XRPExport:Export(xrp.ShortName(name), tostring(xrp.characters.noRequest.byName[name].fields))
end

xrpCmds.profile = function(args)
	if args == "list" or args == _xrp.L.ARG_PROFILE_LIST then
		print(STAT_FORMAT:format(_xrp.L.PROFILES))
		for i, profile in ipairs(xrp.profiles:List()) do
			print(profile)
		end
	elseif type(args) == "string" then
		if xrp.profiles[args] and xrp.profiles[args]:Activate() then
			print(_xrp.L.SET_PROFILE:format(args))
		else
			print(_xrp.L.SET_PROFILE_FAIL:format(args))
		end
	else
		xrpCmds.help("profile")
	end
end

xrpCmds.status = function(args)
	if args == "nil" or args == _xrp.L.ARG_STATUS_NIL then
		xrp.current.fields.FC = nil
	elseif args == "ooc" or args == _xrp.L.ARG_STATUS_IC then
		xrp.current.fields.FC = "1"
	elseif args == "ic" or args == _xrp.L.ARG_STATUS_OOC then
		xrp.current.fields.FC = "2"
	elseif args == "lfc" or args == _xrp.L.ARG_STATUS_LFC then
		xrp.current.fields.FC = "3"
	elseif args == "st" or args == _xrp.L.ARG_STATUS_ST then
		xrp.current.fields.FC = "4"
	else
		xrpCmds.help("status")
	end
end

xrpCmds.toggle = function(args)
	xrp.Status()
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
if _xrp.L.CMD_ABOUT ~= "about" then
	xrpCmds[_xrp.L.CMD_ABOUT] = xrpCmds.about
end
if _xrp.L.CMD_BOOKMARKS ~= "bookmarks" then
	xrpCmds[_xrp.L.CMD_BOOKMARKS] = xrpCmds.bookmarks
end
if _xrp.L.CMD_EDIT ~= "edit" then
	xrpCmds[_xrp.L.CMD_EDIT] = xrpCmds.edit
end
if _xrp.L.CMD_EXPORT ~= "export" then
	xrpCmds[_xrp.L.CMD_EXPORT] = xrpCmds.export
end
if _xrp.L.CMD_HELP ~= "help" then
	xrpCmds[_xrp.L.CMD_HELP] = xrpCmds.help
end
if _xrp.L.CMD_PROFILE ~= "profile" then
	xrpCmds[_xrp.L.CMD_PROFILE] = xrpCmds.profile
end
if _xrp.L.CMD_STATUS ~= "status" then
	xrpCmds[_xrp.L.CMD_STATUS] = xrpCmds.status
end
if _xrp.L.CMD_TOGGLE ~= "toggle" then
	xrpCmds[_xrp.L.CMD_TOGGLE] = xrpCmds.toggle
end
if _xrp.L.CMD_VIEW ~= "view" then
	xrpCmds[_xrp.L.CMD_VIEW] = xrpCmds.view
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
