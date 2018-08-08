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
local L = AddOn.GetText

local events = {}
function AddOn.FireEvent(event, ...)
	if not events[event] then
		return false
	end
	for func, isFunc in pairs(events[event]) do
		xpcall(func, geterrorhandler(), event, ...)
	end
	return true
end
function xrp.HookEvent(event, func)
	if type(func) ~= "function" then
		return false
	elseif type(events[event]) ~= "table" then
		events[event] = {}
	elseif events[event][func] then
		return false
	end
	events[event][func] = true
	return true
end
function xrp.UnhookEvent(event, func)
	if not events[event] or not events[event][func] then
		return false
	end
	events[event][func] = nil
	return true
end
