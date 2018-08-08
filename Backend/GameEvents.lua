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

local frame = CreateFrame("Frame")
frame:Hide()

local gameEvents = {}
function AddOn.HookGameEvent(event, func, unit)
	if type(func) ~= "function" then
		return false
	elseif not gameEvents[event] then
		gameEvents[event] = {}
	elseif gameEvents[event][func] then
		return false
	end
	gameEvents[event][func] = true
	if not unit then
		frame:RegisterEvent(event)
	else
		frame:RegisterUnitEvent(event, unit)
	end
	return true
end
function AddOn.UnhookGameEvent(event, func)
	if not gameEvents[event] or not gameEvents[event][func] then
		return false
	end
	gameEvents[event][func] = nil
	if not next(gameEvents[event]) then
		gameEvents[event] = nil
		frame:UnregisterEvent(event)
	end
	return true
end
frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and ... ~= FOLDER_NAME then return end
	for func, isFunc in pairs(gameEvents[event]) do
		xpcall(func, geterrorhandler(), event, ...)
	end
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		gameEvents[event] = nil
		self:UnregisterEvent(event)
	end
end)
