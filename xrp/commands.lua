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

local L = xrp.L

-- Add a localized version, if applicable.
SLASH_XRP1, SLASH_XRP2 = "/xrp", L["/xrp"] ~= "/xrp" and L["/xrp"] or nil

-- Cannot define commands in static table, as they make use of each other.
local xrpcmds = {}

xrpcmds.about = function(args)
	print("|cffabd473"..XRP.."|r ("..xrp.version..")")
	print(XRP_AUTHOR)
	print(XRP_COPYRIGHT)
	-- Chat frame printing indents newlines in strings, so split lines.
	for line in XRP_LICENSE_SHORT:gmatch("([^\n]+)") do
		print(line)
	end
	print(" ")
end

local usage = L["|cffabd473Usage:|r %s"]
local command = L[" - |cfffff569%s:|r %s"]

xrpcmds.help = function(args)
	if args == "about" or args == L["about"] then
		print(usage:format(L["/xrp about"]))
		print(L["Show basic information about XRP."])
		print(" ")
	elseif args == "editor" or args == L["editor"] then
		print(usage:format(L["/xrp editor"]))
		print(L["Toggle the editor open/closed."])
		print(" ")
	elseif args == "profile" or args == L["profile"] then
		print(usage:format(L["/xrp profile [list|<Profile>]"]))
		print(command:format(L["list"], L["List all profiles."]))
		print(command:format(L["<Profile>"], L["Set current profile to the named profile."]))
		print(" ")
	elseif args == "status" or args == L["status"] then
		print(usage:format(L["/xrp status [nil|ooc|ic|lfc|st]"]))
		print(command:format(L["nil"], L["Reset to profile default."]))
		print(command:format(L["ic"], L["Set to out-of-character."]))
		print(command:format(L["ooc"], L["Set to in-character."]))
		print(command:format(L["lfc"], L["Set to looking for contact."]))
		print(command:format(L["st"], L["Set to storyteller."]))
		print(" ")
	elseif args == "view" or args == "show" or args == L["view"] or args == L["show"] then
		print(usage:format(L["/xrp view [target|mouseover|<Character>]"]))
		print(command:format(L["target"], L["View your target's profile."]))
		print(command:format(L["mouseover"], L["View your mouseover's profile."]))
		print(command:format(L["<Character>"], L["View the profile of the named character."]))
		print(" ")
	elseif args == "viewer" or args == L["viewer"] then
		print(usage:format(L["/xrp viewer"]))
		print(L["Toggle the viewer open/closed."])
		print(" ")
	else
		print(usage:format(L["/xrp <command> [argument]"]))
		print(L["Use /xrp help [command] for more usage information."])
		print(command:format(L["about"], L["Display basic information about XRP."]))
		print(command:format(L["editor"], L["Toggle the editor."]))
		print(command:format(L["help"], L["Display this help message."]))
		print(command:format(L["profile"], L["Set your current profile."]))
		print(command:format(L["status"], L["Set your character status."]))
		print(command:format(L["view"], L["View a character's profile."]))
		print(command:format(L["viewer"], L["Toggle the viewer."]))
		if L["/xrp"] ~= "/xrp" then
			print(L["You may also use the English forms of /xrp commands."])
		end
		print(" ")
	end
end

xrpcmds.editor = function(args)
	xrp:ToggleEditor()
end

xrpcmds.profile = function(args)
	if args == "list" or args == L["list"] then
		print("Profiles:")
		for _, profile in ipairs(xrp.profiles()) do
			print(profile)
		end
		print(" ")
	elseif type(args) == "string" then
		if xrp.profiles(args) then
			print(L["Set profile to \"%s\"."]:format(args))
		else
			print(L["Failed to set profile (does \"%s\" exist?)."]:format(args))
		end
	else
		xrpcmds.help("profile")
	end
end

xrpcmds.status = function(args)
	if args == "nil" or args == L["nil"] then
		xrp.profile.FC = nil
	elseif args == "ooc" or args == L["ooc"] then
		xrp.profile.FC = "1"
	elseif args == "ic" or args == L["ic"] then
		xrp.profile.FC = "2"
	elseif args == "lfc" or args == L["lfc"] then
		xrp.profile.FC = "3"
	elseif args == "st" or args == L["st"] then
		xrp.profile.FC = "4"
	else
		xrpcmds.help("status")
	end
end

xrpcmds.view = function(args)
	if (not args and UnitIsPlayer("target")) or args == "target" or args == L["target"] then
		xrp:ShowViewerUnit("target")
	elseif (not args and UnitIsPlayer("mouseover")) or args == "mouseover" or args == L["mouseover"] then
		xrp:ShowViewerUnit("mouseover")
	elseif type(args) == "string" then
		xrp:ShowViewerCharacter(args)
	else
		xrpcmds.help("view")
	end
end

xrpcmds.viewer = function(args)
	xrp:ToggleViewer()
end

xrpcmds.show = xrpcmds.view
xrpcmds[L["about"]] = xrpcmds.about
xrpcmds[L["help"]] = xrpcmds.help
xrpcmds[L["editor"]] = xrpcmds.editor
xrpcmds[L["profile"]] = xrpcmds.profile
xrpcmds[L["show"]] = xrpcmds.view
xrpcmds[L["view"]] = xrpcmds.view
xrpcmds[L["viewer"]] = xrpcmds.viewer

local xrphandler = function(input, editBox)
	local command, args = input:match("^([^%s]+)%s*(.*)$")
	if xrpcmds[command] then
		xrpcmds[command](args ~= "" and args or nil)
	else
		xrpcmds["help"](args ~= "" and args or nil)
	end
end

SlashCmdList["XRP"] = xrphandler
