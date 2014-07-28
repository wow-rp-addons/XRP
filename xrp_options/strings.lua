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

local L = xrp.L

XRP_OPTIONS_CORE_TITLE = L["XRP: Core Options"]
XRP_OPTIONS_CORE_DEFAULTS = L["For new profiles, copy from \"Default\" for:"]
XRP_OPTIONS_CORE_CACHE = L["Character profile cache expiry:"]
XRP_OPTIONS_CORE_CACHEAUTO = L["Prune cache on login"]
XRP_OPTIONS_CORE_MINIMAP = L["Minimap icon:"]
XRP_OPTIONS_CORE_HIDEMINIMAPTT = L["Hide help tooltip on minimap icon"]
XRP_OPTIONS_CORE_MINIMAPDETACHED = L["Detach minimap icon from minimap"]

if (select(4, GetAddOnInfo("xrp_chatnames"))) then
	XRP_OPTIONS_CHAT_TITLE = L["XRP: Chat Names Options"]
	XRP_OPTIONS_CHAT_LABEL = L["Use roleplay names in the following:"]
	XRP_OPTIONS_CHAT_MISC = L["Miscellaneous:"]
	XRP_OPTIONS_CHAT_EMOTEBRACED = L["Add square brackets around character names in emotes"]
end

if (select(4, GetAddOnInfo("xrp_tooltip"))) then
	XRP_OPTIONS_TOOLTIP_TITLE = L["XRP: Tooltip Options"]
	XRP_OPTIONS_TOOLTIP_FACTION = L["Color RP names by faction"]
	XRP_OPTIONS_TOOLTIP_WATCHING = L["Show indicator if player is targeting me"]
	XRP_OPTIONS_TOOLTIP_GUILDRANK = L["Show guild rank"]
	XRP_OPTIONS_TOOLTIP_NORPRACE = L["Hide roleplaying race"]
	XRP_OPTIONS_TOOLTIP_NOOPFACTION = L["Hide (cached) roleplaying information for opposite faction"]
	XRP_OPTIONS_TOOLTIP_NOHOSTILE = L["Hide roleplaying information for hostile PvP targets"]
	XRP_OPTIONS_TOOLTIP_EXTRASPACE = L["Add extra spacing lines"]
end
