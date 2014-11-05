--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

local addonName, private = ...

local function LoadIfNeeded(addon)
	local isloaded = IsAddOnLoaded(addon)
	if not isloaded and IsAddOnLoadOnDemand(addon) then
		return LoadAddOn(addon) == true
	end
	return isloaded
end

function xrp:Edit(profile)
	if not LoadIfNeeded("xrp_editor") then
		return false
	end
	return self:Edit(profile)
end

function xrp:Auto(form)
	if not LoadIfNeeded("xrp_editor") then
		return false
	end
	return self:Auto(form)
end

function xrp:View(player)
	if not LoadIfNeeded("xrp_viewer") then
		return false
	end
	return self:View(player)
end

function xrp:Options(pane)
	if not LoadIfNeeded("xrp_options") then
		return false
	end
	private.about:SetScript("OnShow", nil)
	-- Twice in a row since it won't always open to the requested pane first
	-- try.
	self:Options(pane)
	return self:Options(pane)
end
