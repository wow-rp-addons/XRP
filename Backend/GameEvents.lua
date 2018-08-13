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

local GameEventCallbacks = {}

local frame = CreateFrame("Frame")
frame:Hide()

function AddOn.RegisterGameEventCallback(event, callback, unit)
	if type(callback) ~= "function" then
		error("XRP: AddOn.RegisterGameEventCallback(): callback: expected function, got " .. type(callback), 2)
	elseif not GameEventCallbacks[event] then
		if not unit then
			frame:RegisterEvent(event)
		else
			frame:RegisterUnitEvent(event, unit)
		end
		GameEventCallbacks[event] = {}
	else
		for i, regCallback in ipairs(GameEventCallbacks[event]) do
			if callback == regCallback then
				error("XRP: AddOn.RegisterGameEventCallback(): callback: already registered for event " .. event, 2)
			end
		end
	end
	local i = #GameEventCallbacks[event] + 1
	GameEventCallbacks[event][i] = callback
end

function AddOn.UnregisterGameEventCallback(event, callback)
	if not GameEventCallbacks[event] then
		error("XRP: AddOn.UnregisterGameEventCallback(): no callbacks registered for " .. event, 2)
	end
	for i, regCallback in ipairs(GameEventCallbacks[event]) do
		if callback == regCallback then
			if #GameEventCallbacks[event] == 1 then
				GameEventCallbacks[event] = nil
				frame:UnregisterEvent(event)
			else
				table.remove(GameEventCallbacks[event], i)
			end
			return
		end
	end
	error("XRP: AddOn.UnregisterGameEventCallback(): callback: not registered for " .. event, 2)
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and ... ~= FOLDER_NAME then return end
	for i, callback in ipairs(GameEventCallbacks[event]) do
		xpcall(callback, geterrorhandler(), event, ...)
	end
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		GameEventCallbacks[event] = nil
		self:UnregisterEvent(event)
	end
end)
