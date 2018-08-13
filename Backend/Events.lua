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

local EventCallbacks = {
	ADDON_XRP_CACHE_DROPPED = {},
	ADDON_XRP_FIELD_RECEIVED = {},
	ADDON_XRP_PROFILE_RECEIVED = {},
	ADDON_XRP_PROGRESS_UPDATED = {},
	ADDON_XRP_QUERY_FAILED = {},
}

function AddOn.RunEvent(event, ...)
	if not EventCallbacks[event] then
		error("XRP: AddOn.RunEvent(): event: invalid event " .. event, 2)
	end
	for i, callback in ipairs(EventCallbacks[event]) do
		xpcall(callback, geterrorhandler(), event, ...)
	end
end

function AddOn_XRP.RegisterEventCallback(event, callback)
	if type(event) ~= "string" then
		error("AddOn_XRP.RegisterEventCallback(): event: expected string, got " .. type(event), 2)
	elseif not EventCallbacks[event] then
		error("AddOn_XRP.RegisterEventCallback(): event: invalid event " .. event, 2)
	elseif type(callback) ~= "function" then
		error("AddOn_XRP.RegisterEventCallback(): callback: expected function, got " .. type(callback), 2)
	end
	for i, regCallback in ipairs(EventCallbacks[event]) do
		if callback == regCallback then
			error("AddOn_XRP.RegisterEventCallback(): callback: already registered for event " .. event, 2)
		end
	end
	local i = #EventCallbacks[event] + 1
	EventCallbacks[event][i] = callback
end

function AddOn_XRP.UnregisterEventCallback(event, callback)
	if type(event) ~= "string" then
		error("AddOn_XRP.UnregisterEventCallback(): event: expected string, got " .. type(event), 2)
	elseif not EventCallbacks[event] then
		error("AddOn_XRP.UnregisterEventCallback(): event: invalid event: " .. event, 2)
	elseif type(callback) ~= "function" then
		error("AddOn_XRP.UnregisterEventCallback(): callback: expected function, got " .. type(callback), 2)
	end
	for i, regCallback in ipairs(EventCallbacks[event]) do
		if callback == regCallback then
			table.remove(EventCallbacks[event], i)
			return
		end
	end
	error("AddOn_XRP.UnregisterEventCallback(): callback: not registered for event " .. event, 2)
end
