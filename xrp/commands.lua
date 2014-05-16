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

local xrpcmds = {}

xrpcmds.help = function(args)
	if args == "about" then
		print("|cffabd473Usage:|r /xrp about")
		print("Shows basic information about XRP.")
		print(" ")
	elseif args == "view" then
		print("|cffabd473Usage:|r /xrp view [target|mouseover|Name]")
		print(" - |cfffff569target:|r View your target's profile.")
		print(" - |cfffff569target:|r View your mouseover's profile.")
		print(" - |cfffff569Name:|r View the CACHED copy of the named character. (Will not request any updates).")
		print(" ")
	elseif args == "editor" then
		print("|cffabd473Usage:|r /xrp editor")
		print("Toggles the editor open/closed.")
		print(" ")
	elseif args == "viewer" then
		print("|cffabd473Usage:|r /xrp viewer")
		print("Toggles the viewer open/closed.")
		print(" ")
	elseif args == "status" then
		print("|cffabd473Usage:|r /xrp status [nil|ooc|ic|lfc|st]")
		print(" - |cfffff569nil:|r Reset to profile default.")
		print(" - |cfffff569ooc:|r Set to out-of-character.")
		print(" - |cfffff569ic:|r Set to in-character.")
		print(" - |cfffff569lfc:|r Set to looking for contact.")
		print(" - |cfffff569st:|r Set to storyteller.")
		print(" ")
	else
		print("|cffabd473Usage:|r /xrp command [argument]")
		print("Use /xrp help [command] for more usage information.")
		print(" - |cfffff569about:|r Display basic information about XRP.")
		print(" - |cfffff569editor:|r Toggle the editor.")
		print(" - |cfffff569help:|r Display this help message.")
		print(" - |cfffff569status:|r Set your character status.")
		print(" - |cfffff569view:|r View a character's profile.")
		print(" - |cfffff569viewer:|r Toggle the viewer.")
		print(" ")
	end
end

xrpcmds.about = function(args)
	print("|cffabd473"..XRP.."|r ("..xrp.version..")")
	print(XRP_AUTHOR)
	print(XRP_COPYRIGHT)
	print(XRP_LICENSE_SHORT)
	print(" ")
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

xrpcmds.editor = function(args)
	xrp:ToggleEditor()
end

xrpcmds.viewer = function(args)
	xrp:ToggleViewer()
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

xrpcmds.show = xrpcmds.view
xrpcmds[L["help"]] = xrpcmds.help
xrpcmds[L["about"]] = xrpcmds.about
xrpcmds[L["view"]] = xrpcmds.view
xrpcmds[L["show"]] = xrpcmds.view
xrpcmds[L["editor"]] = xrpcmds.editor
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
