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
local xrpCmds = {}

do
	xrpCmds.about = function(args)
		print("|cffabd473XRP|r")
		print(("|cff99b3e6Author:|r %s"):format(GetAddOnMetadata(addonName, "Author")))
		print(("|cff99b3e6Version:|r %s"):format(xrpPrivate.version))
		print("License: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>")
		print("This is free software: you are free to change and redistribute it.")
		print("There is NO WARRANTY, to the extent permitted by law.")
	end

	local usage = "|cffabd473Usage:|r %s"
	local command = " - |cfffff569%s:|r %s"
	xrpCmds.help = function(args)
		if args == "about" then
			print(usage:format("/xrp about"))
			print("Show basic information about XRP.")
		elseif args == "edit" then
			print(usage:format("/xrp edit [<Profile>]"))
			print(command:format("<none>", "Toggle the editor open/closed."))
			print(command:format("<Profile>", "Open a profile for editing."))
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
		elseif args == "toggle" then
			print(usage:format("/xrp toggle"))
			print("Toggle IC/OOC status.")
		elseif args == "view" or args == "show" then
			print(usage:format("/xrp view [target|mouseover|<Character>]"))
			print(command:format("<none>", "View your target or mouseover's profile, as available."))
			print(command:format("target", "View your target's profile."))
			print(command:format("mouseover", "View your mouseover's profile."))
			print(command:format("<Character>", "View the profile of the named character."))
		else
			print(usage:format("/xrp <command> [argument]"))
			print("Use /xrp help [command] for more usage information.")
			print(command:format("about", "Display basic information about XRP."))
			print(command:format("edit", "Access the editor."))
			print(command:format("help", "Display this help message."))
			print(command:format("profile", "Set your current profile."))
			print(command:format("status", "Set your character status."))
			print(command:format("toggle", "Toggle IC/OOC status."))
			print(command:format("view", "View a character's profile."))
		end
	end
end

xrpCmds.edit = function(args)
	xrp:Edit(args)
end

xrpCmds.profile = function(args)
	if args == "list" then
		print("Profiles:")
		for i, profile in ipairs(xrpPrivate.profiles:List()) do
			print(profile)
		end
	elseif type(args) == "string" then
		if xrpPrivate.profiles[args] and xrpPrivate.profiles[args]:Activate() then
			print(("Set profile to \"%s\"."):format(args))
		else
			print(("Failed to set profile to \"%s\"."):format(args))
		end
	else
		xrpCmds.help("profile")
	end
end

xrpCmds.status = function(args)
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
	xrp:View(args)
end

-- Aliases.
xrpCmds.show = xrpCmds.view

SLASH_XRP1 = "/xrp"

SlashCmdList["XRP"] = function(input, editBox)
	local command, args = input:match("^([^%s]+)%s*(.*)$")
	if command and xrpCmds[command:lower()] then
		xrpCmds[command:lower()](args ~= "" and args or nil)
	else
		xrpCmds["help"](args ~= "" and args or nil)
	end
end
