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
local INFO = STAT_FORMAT:format("|cff99b3e6%s") .. "|r %s"
-- Also used in ui/options.xml.
XRP_AUTHOR = INFO:format(_xrp.L.AUTHOR, GetAddOnMetadata(addonName, "Author"))
XRP_VERSION = INFO:format(GAME_VERSION_LABEL, _xrp.version)
local XRP_HEADER = ("|cffffd100<|r|cffabd473%s|r|cffffd100>:|r %%s"):format(GetAddOnMetadata(addonName, "Title"))

local xrpCmds = {}

xrpCmds.about = function(args)
	print(XRP_HEADER:format(""))
	print(XRP_AUTHOR)
	print(XRP_VERSION)
	for line in _xrp.L.GPL_SHORT:gmatch("[^\n]+") do
		print(line)
	end
end

xrpCmds.bookmarks = function(args)
	XRPBookmarks:Toggle(1)
end

xrpCmds.currently = function(args)
	if args == _xrp.L.ARG_CURRENTLY_NIL then
		xrp.current.CU = nil
		local CU = xrp.current.CU
		if CU then
			print(XRP_HEADER:format(_xrp.L.SET_CURRENTLY_PROFILE:format(args)))
		else
			print(XRP_HEADER:format(_xrp.L.SET_CURRENTLY_BLANK_PROFILE))
		end
	elseif type(args) == "string" then
		xrp.current.CU = args
		print(XRP_HEADER:format(_xrp.L.SET_CURRENTLY:format(args)))
	else
		xrp.current.CU = ""
		print(XRP_HEADER:format(_xrp.L.SET_CURRENTLY_BLANK))
	end
end

xrpCmds.edit = function(args)
	XRPEditor:Edit(args)
end

xrpCmds.export = function(args)
	local name = xrp.FullName(args:match("^[^%s]+"))
	if not name then return end
	name = name:gsub("^%l", string.upper)
	XRPExport:Export(xrp.ShortName(name), tostring(xrp.characters.noRequest.byName[name].fields))
end

local USAGE = XRP_HEADER:format(("|cff9482c9%s|r %%s"):format(STAT_FORMAT:format(_xrp.L.USAGE)))
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
	elseif args == "currently" or args and args == _xrp.L.CMD_CURRENTLY then
		print(USAGE:format(HAS_ARGS:format(_xrp.L.CMD_CURRENTLY, _xrp.L.CURRENTLY_ARGS)))
		print(ARG:format(_xrp.L.CURRENTLY_ARG1, _xrp.L.CURRENTLY_ARG1_HELP))
		print(ARG:format(_xrp.L.CURRENTLY_ARG2, _xrp.L.CURRENTLY_ARG2_HELP))
		print(ARG:format(_xrp.L.ARG_CURRENTLY_NIL, _xrp.L.CURRENTLY_ARG3_HELP))
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
	elseif args == "view" or args and args == _xrp.L.CMD_VIEW then
		print(USAGE:format(HAS_ARGS:format(_xrp.L.CMD_VIEW, _xrp.L.VIEW_ARGS)))
		print(ARG:format(_xrp.L.VIEW_ARG1, _xrp.L.VIEW_ARG1_HELP))
		print(ARG:format(_xrp.L.VIEW_ARG2, _xrp.L.VIEW_ARG2_HELP))
		print(ARG:format(_xrp.L.VIEW_ARG3, _xrp.L.VIEW_ARG3_HELP))
	else
		print(USAGE:format(HAS_ARGS:format(_xrp.L.COMMANDS, _xrp.L.ARGUMENTS)))
		print(_xrp.L.COMMANDS_HELP)
		print(ARG:format(_xrp.L.CMD_ABOUT, _xrp.L.ABOUT_HELP))
		print(ARG:format(_xrp.L.CMD_BOOKMARKS, _xrp.L.BOOKMARKS_HELP))
		print(ARG:format(_xrp.L.CMD_CURRENTLY, _xrp.L.CURRENTLY_HELP))
		print(ARG:format(_xrp.L.CMD_EDIT, _xrp.L.EDIT_HELP))
		print(ARG:format(_xrp.L.CMD_EXPORT, _xrp.L.EXPORT_HELP))
		print(ARG:format(_xrp.L.CMD_HELP, _xrp.L.HELP_HELP))
		print(ARG:format(_xrp.L.CMD_PROFILE, _xrp.L.PROFILE_HELP))
		print(ARG:format(_xrp.L.CMD_STATUS, _xrp.L.STATUS_HELP))
		print(ARG:format(_xrp.L.CMD_TOGGLE, _xrp.L.TOGGLE_HELP))
		print(ARG:format(_xrp.L.CMD_VIEW, _xrp.L.VIEW_HELP))
	end
end

xrpCmds.profile = function(args)
	if args == "list" or args == _xrp.L.ARG_PROFILE_LIST then
		print(XRP_HEADER:format(STAT_FORMAT:format(_xrp.L.PROFILES)))
		for i, profile in ipairs(xrp.profiles:List()) do
			print(profile)
		end
	elseif type(args) == "string" then
		if xrp.profiles[args] and xrp.profiles[args]:Activate() then
			print(XRP_HEADER:format(_xrp.L.SET_PROFILE:format(args)))
		else
			print(XRP_HEADER:format(_xrp.L.SET_PROFILE_FAIL:format(args)))
		end
	else
		xrpCmds.help("profile")
	end
end

xrpCmds.status = function(args)
	if args == "nil" or args == _xrp.L.ARG_STATUS_NIL then
		xrp.current.FC = nil
		local FC = xrp.current.FC
		print(XRP_HEADER:format(_xrp.L.SET_STATUS_PROFILE:format(xrp.L.VALUES.FC[FC] or FC or NONE)))
	elseif args == "ooc" or args == _xrp.L.ARG_STATUS_OOC then
		xrp.current.FC = "1"
		print(XRP_HEADER:format(_xrp.L.SET_STATUS:format(xrp.L.VALUES.FC["1"])))
	elseif args == "ic" or args == _xrp.L.ARG_STATUS_IC then
		xrp.current.FC = "2"
		print(XRP_HEADER:format(_xrp.L.SET_STATUS:format(xrp.L.VALUES.FC["2"])))
	elseif args == "lfc" or args == _xrp.L.ARG_STATUS_LFC then
		xrp.current.FC = "3"
		print(XRP_HEADER:format(_xrp.L.SET_STATUS:format(xrp.L.VALUES.FC["3"])))
	elseif args == "st" or args == _xrp.L.ARG_STATUS_ST then
		xrp.current.FC = "4"
		print(XRP_HEADER:format(_xrp.L.SET_STATUS:format(xrp.L.VALUES.FC["4"])))
	else
		xrpCmds.help("status")
	end
end

xrpCmds.toggle = function(args)
	xrp.Status()
	local FC = xrp.current.FC
	print(XRP_HEADER:format(_xrp.L.SET_STATUS:format(xrp.L.VALUES.FC[FC] or FC or NONE)))
end

xrpCmds.view = function(args)
	if not args and UnitIsPlayer("target") then
		args = "target"
	elseif not args and UnitIsPlayer("mouseover") then
		args = "mouseover"
	end
	XRPViewer:View(args)
end

-- Some aliases to match MRP's chat commands.
xrpCmds.version = xrpCmds.about
xrpCmds.c = xrpCmds.currently
xrpCmds.cu = xrpCmds.currently
xrpCmds.cur = xrpCmds.currently
xrpCmds.ooc = function() xrpCmds.status("ooc") end
xrpCmds.ic = function() xrpCmds.status("ic") end
xrpCmds.lfc = function() xrpCmds.status("lfc") end
xrpCmds.contact = xrpCmds.lfc
xrpCmds.st = function() xrpCmds.status("st") end
xrpCmds.storyteller = xrpCmds.st
xrpCmds.browse = xrpCmds.view
xrpCmds.browser = xrpCmds.view
xrpCmds.show = xrpCmds.view

-- Localized aliases.
if _xrp.L.CMD_ABOUT ~= "about" then
	xrpCmds[_xrp.L.CMD_ABOUT] = xrpCmds.about
end
if _xrp.L.CMD_BOOKMARKS ~= "bookmarks" then
	xrpCmds[_xrp.L.CMD_BOOKMARKS] = xrpCmds.bookmarks
end
if _xrp.L.CMD_CURRENTLY ~= "currently" then
	xrpCmds[_xrp.L.CMD_CURRENTLY] = xrpCmds.currently
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
	command = command and command:lower()
	if command and xrpCmds[command] then
		xrpCmds[command](args ~= "" and args)
	else
		xrpCmds["help"](args ~= "" and args)
	end
end
