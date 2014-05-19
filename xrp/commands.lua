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

xrpcmds.help = function(args)
	if args == "about" then
		print("|cffabd473Usage:|r /xrp about")
		print("Show basic information about XRP.")
		print(" ")
	elseif args == "editor" then
		print("|cffabd473Usage:|r /xrp editor")
		print("Toggle the editor open/closed.")
		print(" ")
	elseif args == "profile" then
		print("|cffabd473Usage:|r /xrp profile [list|<Profile>]")
		print(" - |cfffff569list:|r List all profiles.")
		print(" - |cfffff569<Profile>:|r Set current profile to the named profile.")
		print(" ")
	elseif args == "status" then
		print("|cffabd473Usage:|r /xrp status [nil|ooc|ic|lfc|st]")
		print(" - |cfffff569nil:|r Reset to profile default.")
		print(" - |cfffff569ooc:|r Set to out-of-character.")
		print(" - |cfffff569ic:|r Set to in-character.")
		print(" - |cfffff569lfc:|r Set to looking for contact.")
		print(" - |cfffff569st:|r Set to storyteller.")
		print(" ")
	elseif args == "view" then
		print("|cffabd473Usage:|r /xrp view [target|mouseover|<Character>]")
		print(" - |cfffff569target:|r View your target's profile.")
		print(" - |cfffff569target:|r View your mouseover's profile.")
		print(" - |cfffff569<Character>:|r View the profile of the named character.")
		print(" ")
	elseif args == "viewer" then
		print("|cffabd473Usage:|r /xrp viewer")
		print("Toggle the viewer open/closed.")
		print(" ")
	else
		print("|cffabd473Usage:|r /xrp command [argument]")
		print("Use /xrp help [command] for more usage information.")
		print(" - |cfffff569about:|r Display basic information about XRP.")
		print(" - |cfffff569editor:|r Toggle the editor.")
		print(" - |cfffff569help:|r Display this help message.")
		print(" - |cfffff569profile:|r Set your current profile.")
		print(" - |cfffff569status:|r Set your character status.")
		print(" - |cfffff569view:|r View a character's profile.")
		print(" - |cfffff569viewer:|r Toggle the viewer.")
		print(" ")
	end
end

xrpcmds.editor = function(args)
	xrp:ToggleEditor()
end

xrpcmds.profile = function(args)
	if args == "list" then
		for _, profile in ipairs(xrp.profiles()) do
			print(profile)
		end
	elseif type(args) == "string" then
		if xrp.profiles(args) then
			print("Set profile to \""..args.."\".")
		else
			print("Failed to set profile (does \""..args.."\" exist?).")
		end
	else
		xrpcmds.help("profile")
	end
end

xrpcmds.status = function(args)
	if args == "nil" then
		xrp.profile.FC = nil
	elseif args == "ooc" then
		xrp.profile.FC = "1"
	elseif args == "ic" then
		xrp.profile.FC = "2"
	elseif args == "lfc" then
		xrp.profile.FC = "3"
	elseif args == "st" then
		xrp.profile.FC = "4"
	else
		xrpcmds.help("status")
	end
end

xrpcmds.view = function(args)
	if (not args and UnitIsPlayer("target")) or args == "mouseover" then
		xrp:ShowViewerUnit("target")
	elseif (not args and UnitIsPlayer("mouseover")) or args == "mouseover" then
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
