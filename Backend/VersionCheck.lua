--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local VERSION = GetAddOnMetadata(FOLDER_NAME, "Version")

local VERSION_MATCH = "^(%d+)%.(%d+)%.(%d+)%-?(%l*)(%d*)"
local function CompareVersion(newVersion, oldVersion)
	if newVersion:find("-dev", nil, true) or oldVersion:find("-dev", nil, true) then
		-- Never issue updates for git -dev versions.
		return -1
	end

	local newMajor, newMinor, newPatch, newType, newRevision = newVersion:match(VERSION_MATCH)

	if not newMajor or not newMinor or not newPatch then
		return -1
	end

	local oldMajor, oldMinor, oldPatch, oldType, oldRevision = oldVersion:match(VERSION_MATCH)

	newType = newType == "alpha" and 1 or newType == "beta" and 2 or newType == "rc" and 3 or 4
	oldType = oldType == "alpha" and 1 or oldType == "beta" and 2 or oldType == "rc" and 3 or 4

	local new = (tonumber(newMajor) * 1000000) + (tonumber(newMinor) * 10000) + (tonumber(newPatch) * 100) + (tonumber(newRevision) or 0)
	local old = (tonumber(oldMajor) * 1000000) + (tonumber(oldMinor) * 10000) + (tonumber(oldPatch) * 100) + (tonumber(oldRevision) or 0)

	if new <= old then
		return -1
	elseif newType < oldType then
		return 0
	end
	return 1
end

function AddOn.CheckVersionUpdate(characterID, version)
	if not version or version == VERSION or version == xrpAccountSaved.update.xrpVersionUpdate then return end
	if CompareVersion(version, xrpAccountSaved.update.xrpVersionUpdate or VERSION) >= 0 then
		xrpAccountSaved.update.xrpVersionUpdate = version
		AddOn.QueueRequest(characterID, "VW")
	end
end

function AddOn.UpdateWoWVersion(remoteVersion, remoteBuild, remoteInterface)
	if not remoteVersion or not remoteVersion:find("^%d+.%d+.%d+") or not remoteBuild or not remoteBuild:find("^%d+$") or not remoteInterface or not remoteInterface:find("^%d+$") then
		return
	end
	remoteBuild = tonumber(remoteBuild)
	remoteInterface = tonumber(remoteInterface)
	local activeVersion, activeBuild, activeDate, activeInterface = GetBuildInfo()
	activeBuild = tonumber(activeBuild)
	local localVersion = GetAddOnMetadata(FOLDER_NAME, "X-WoW-Version")
	local localBuild = tonumber(GetAddOnMetadata(FOLDER_NAME, "X-WoW-Build"))
	local localInterface = tonumber(GetAddOnMetadata(FOLDER_NAME, "X-Interface"))
	if CompareVersion(activeVersion, localVersion) > 0 and activeVersion == remoteVersion then
		xrpAccountSaved.update.wowVersionUpdate = remoteVersion
	end
	if localBuild < activeBuild and activeBuild == remoteBuild then
		xrpAccountSaved.update.wowBuildUpdate = remoteBuild
	end
	if localInterface < activeInterface and activeInterface == remoteInterface then
		xrpAccountSaved.update.wowInterfaceUpdate = remoteInterface
	end
end

AddOn.RegisterGameEventCallback("PLAYER_LOGIN", function(event)
	if xrpAccountSaved.update.xrpVersionUpdate then
		local update = CompareVersion(xrpAccountSaved.update.xrpVersionUpdate, VERSION)
		if update == 1 then
			local now = time()
			local warningFunction
			if not xrpAccountSaved.update.lastNotice or xrpAccountSaved.update.lastNotice < now - 21600 then
				if xrpAccountSaved.update.wowInterfaceUpdate then
					-- Biggest warning, interface is outdated.
					warningFunction = function()
						StaticPopup_Show("XRP_ERROR", L"|cffdd380fXRP Version Update:|r There is a new version of XRP (%s) available.\n\nIt is |cffdd380fSTRONGLY RECOMMENDED|r that you update as soon as possible, as it is likely to contain fixes for the latest World of Warcraft client release.":format(xrpAccountSaved.update.xrpVersionUpdate))
					end
				elseif xrpAccountSaved.update.wowVersionUpdate then
					-- Medium warning, client version is oudated.
					warningFunction = function()
						StaticPopup_Show("XRP_NOTIFICATION", L"|cffdd380fXRP Version Update:|r There is a new version of XRP (%s) available.\n\nThis version may fix compatibility issues with the latest World of Warcraft client release.":format(xrpAccountSaved.update.xrpVersionUpdate))
					end
				else
					-- Small warning, only XRP (and maybe WoW build) is oudated.
					warningFunction = function()
						print(L"|cffdd380fXRP Version Update:|r There is a new version of XRP (%s) available.":format(xrpAccountSaved.update.xrpVersionUpdate))
					end
				end
				xrpAccountSaved.update.lastNotice = now
			end
			if warningFunction then
				C_Timer.After(5, warningFunction)
			end
		elseif update == -1 then
			xrpAccountSaved.update.xrpVersionUpdate = nil
			xrpAccountSaved.update.lastNotice = nil
			xrpAccountSaved.update.wowVersionUpdate = nil
			xrpAccountSaved.update.wowBuildUpdate = nil
			xrpAccountSaved.update.wowInterfaceUpdate = nil
		end
	end
end)
