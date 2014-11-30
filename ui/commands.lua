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

-- Cannot define commands in static table, as they make use of each other.
local xrpcmds = {}

do
	local header = "|cffabd473%s|r %s"
	xrpcmds.about = function(args)
		print(header:format("XRP", "("..xrpPrivate.version..")"))
		print(("|cff99b3e6Author:|r %s"):format(GetAddOnMetadata(addonName, "Author")))
		print(("|cff99b3e6Version:|r %"):format(xrpPrivate.version))
		print("License: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>")
		print("This is free software: you are free to change and redistribute it.")
		print("There is NO WARRANTY, to the extent permitted by law.")
	end

	local usage = header:format("Usage:", "%s")
	local command = " - |cfffff569%s:|r %s"
	xrpcmds.help = function(args)
		if args == "about" then
			print(usage:format("/xrp about"))
			print("Show basic information about XRP.")
		elseif args == "editor" then
			print(usage:format("/xrp editor"))
			print("Toggle the editor open/closed.")
		elseif args == "profile" then
			print(usage:format("/xrp profile [list|<Profile>]"))
			print(command:format("list", "List all profiles."))
			print(command:format("<Profile>", "Set current profile to the named profile."))
		elseif args == "status" then
			print(usage:format("/xrp status [nil|ooc|ic|lfc|st]"))
			print(command:format("nil", "Reset to profile default."))
			print(command:format("ic", "Set to out-of-character."))
			print(command:format("ooc", "Set to in-character."))
			print(command:format("lfc", "Set to looking for contact."))
			print(command:format("st", "Set to storyteller."))
		elseif args == "view" or args == "show" then
			print(usage:format("/xrp view [target|mouseover|<Character>]"))
			print(command:format("target", "View your target's profile."))
			print(command:format("mouseover", "View your mouseover's profile."))
			print(command:format("<Character>", "View the profile of the named character."))
		elseif args == "viewer" then
			print(usage:format("/xrp viewer"))
			print("Toggle the viewer open/closed.")
		else
			print(usage:format("/xrp <command> [argument]"))
			print("Use /xrp help [command] for more usage information.")
			print(command:format("about", "Display basic information about XRP."))
			print(command:format("editor", "Toggle the editor."))
			print(command:format("help", "Display this help message."))
			print(command:format("profile", "Set your current profile."))
			print(command:format("status", "Set your character status."))
			print(command:format("view", "View a character's profile."))
			print(command:format("viewer", "Toggle the viewer."))
		end
	end
end

xrpcmds.editor = function(args)
	xrp:Edit()
end

xrpcmds.profile = function(args)
	if args == "list" then
		print("Profiles:")
		for _, profile in ipairs(xrp.profiles:List()) do
			print(profile)
		end
	elseif type(args) == "string" then
		if xrp.profiles[args] and xrp.profiles[args]:Activate() then
			print(("Set profile to \"%s\"."):format(args))
		else
			print(("Failed to set profile to \"%s\"."):format(args))
		end
	else
		xrpcmds.help("profile")
	end
end

xrpcmds.status = function(args)
	if args == "nil" then
		xrp.current.fields.FC = nil
	elseif args == "ooc" then
		xrp.current.fields.FC = "1"
	elseif args == "ic" then
		xrp.current.fields.FC = "2"
	elseif args == "lfc" then
		xrp.current.fields.FC = "3"
	elseif args == "st" then
		xrp.current.fields.FC = "4"
	else
		xrpcmds.help("status")
	end
end

xrpcmds.view = function(args)
	if not args and UnitIsPlayer("target") then
		args = "target"
	elseif not args and UnitIsPlayer("mouseover") then
		args = "mouseover"
	end
	if type(args) == "string" then
		xrp:View(args)
	else
		xrpcmds.help("view")
	end
end

xrpcmds.viewer = function(args)
	xrp:View()
end

-- Aliases.
xrpcmds.show = xrpcmds.view

-- Add a localized version, if applicable.
SLASH_XRP1 =  "/xrp"

SlashCmdList["XRP"] = function(input, editBox)
	local command, args = input:match("^([^%s]+)%s*(.*)$")
	if xrpcmds[command] then
		xrpcmds[command](args ~= "" and args or nil)
	else
		xrpcmds["help"](args ~= "" and args or nil)
	end
end
