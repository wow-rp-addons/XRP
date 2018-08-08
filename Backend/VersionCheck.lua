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

local FOLDER_NAME, AddOn = ...
local VERSION = GetAddOnMetadata(FOLDER_NAME, "Version")
local L = AddOn.GetText

local VERSION_MATCH = "^(%d+)%.(%d+)%.(%d+)[%-]?(%l*)(%d*)"
local function CompareVersion(newVersion, oldVersion)
	if newVersion:find("dev", nil, true) or oldVersion:find("dev", nil, true) then
		-- Never issue updates for git -dev versions.
		return -1
	end
	local newMajor, newMinor, newPatch, newType, newRevision = newVersion:match(VERSION_MATCH)
	local oldMajor, oldMinor, oldPatch, oldType, oldRevision = oldVersion:match(VERSION_MATCH)

	newType = newType == "alpha" and 1 or newType == "beta" and 2 or newType == "rc" and 3 or 4
	oldType = oldType == "alpha" and 1 or oldType == "beta" and 2 or oldType == "rc" and 3 or 4

	-- Account for pre-8.0 version scheme. Remove this sometime before hitting
	-- a 'real' 5.0 release.
	if tonumber(newMajor) > 4 then
		newPatch = newMinor
		newMinor = newMajor
		newMajor = "1"
	end

	local new = (tonumber(newMajor) * 1000000) + (tonumber(newMinor) * 10000) + (tonumber(newPatch) * 100) + (tonumber(newRevision) or 0)
	local old = (tonumber(oldMajor) * 1000000) + (tonumber(oldMinor) * 10000) + (tonumber(oldPatch) * 100) + (tonumber(oldRevision) or 0)

	if new <= old then
		return -1
	elseif newType < oldType then
		return 0
	end
	return 1
end

function AddOn.CheckVersionUpdate(version)
	if not version or version == VERSION or version == AddOn.Settings.newversion then return end
	if CompareVersion(version, AddOn.Settings.newversion or VERSION) >= 0 then
		AddOn.Settings.newversion = version
	end
end

AddOn.HookGameEvent("PLAYER_LOGIN", function(event)
	if AddOn.Settings.newversion then
		local update = CompareVersion(AddOn.Settings.newversion, VERSION)
		local now = time()
		if update == 1 and (not AddOn.Settings.versionwarning or AddOn.Settings.versionwarning < now - 21600) then
			C_Timer.After(8, function()
				print(L"There is a new version of |cffabd473XRP|r available. You should update to %s as soon as possible.":format(AddOn.Settings.newversion))
				AddOn.Settings.versionwarning = now
			end)
		elseif update == -1 then
			AddOn.Settings.newversion = nil
			AddOn.Settings.versionwarning = nil
		end
	end
end)
