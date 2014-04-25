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

local function loadifneeded(addon)
	local isloaded = IsAddOnLoaded(addon)
	if not isloaded and IsAddOnLoadOnDemand(addon) then
		local loaded, reason = LoadAddOn(addon)
		if not loaded then
			return false
		else
			return true
		end
	end
	return isloaded
end

function xrp:ToggleEditor()
	if not loadifneeded("xrp_editor") then
		return
	end
	ToggleFrame(xrp.editor)
end

function xrp:ToggleViewer()
	if not loadifneeded("xrp_viewer") then
		return
	end
	ToggleFrame(xrp.viewer)
end

function xrp:ShowViewerCharacter(character)
	if not loadifneeded("xrp_viewer") then
		return
	end
	xrp.viewer:ViewCharacter(character)
end

function xrp:ShowViewerUnit(unit)
	if not loadifneeded("xrp_viewer") then
		return
	end
	xrp.viewer:ViewUnit(unit)
end
