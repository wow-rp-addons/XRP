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

local API = 2
local FEATURE = 1

function AddOn_XRP.GetAPIVersion()
	return API, FEATURE
end

local GUARANEED_FIELDS = {
	"VP", "VA", "NA", "NH", "NI", "NT", "RA", "CU", "FR", "FC", "RC",-- "CO",
	"AH", "AW", "HH", "HB", "MO", "DE", "HI", "GC", "GF", "GR", "GS", "GU",
	"TT", "VW",
}

local SPECIAL_TYPES = {
	TT = "nil",
	VW = "nil",
}

local SPECIAL_DOCUMENTATION = {
	["nil"] = "This field is used internally. It is never returned to, and may not be set by, API consumers.",
}

local XRPCharacterTable = {
	Name = "XRPCharacterTable",
	Type = "Structure",
	Documentation = { "Fields that can be set are noted in their documentation. Many fields cannot be set and will raise an error() if it is attempted." },
	Fields = {
		{ Name = "id", Type = "string", Nilable = false, Documentation = { "characterID for the table's subject." } },
		{ Name = "name", Type = "string", Nilable = false, Documentation = { "Character name (in-game name)." } },
		{ Name = "realm", Type = "string", Nilable = false, Documentation = { "Character realm. May or may not contain spaces or dashes (subject to final decision later)." } },
		{ Name = "inCharacter", Type = "bool", Nilable = false, Documentation = { "true if the table's subject has any in-character status set." } },
		{ Name = "notes", Type = "string", Nilable = true, Documentation = { "Can be set as well as read." } },
		{ Name = "bookmark", Type = "number", Nilable = true, Documentation = { "Can be set via boolean assignment.", "Returns time() timestamp of when the bookmark was added, or nil." } },
		{ Name = "hidden", Type = "bool", Nilable = false, Documentation = { "Can be set via boolean assignment.", "Hint on whether profile contents should be shown to the user, no mandatory effects." } },
	},
}

local XRPProfileFieldTable = {
	Name = "XRPProfileFieldTable",
	Type = "Structure",
	Fields = {},
}

local XRPProfileInheritTable = {
	Name = "XRPProfileInheritTable",
	Type = "Structure",
	Fields = {},
}

for i, field in ipairs(GUARANEED_FIELDS) do
	local fieldTable = { Name = field, Type = SPECIAL_TYPES[field] or "string", Nilable = true, Documentation = { ("MSP field with localized name \"%s\"."):format(AddOn_XRP.Strings.Names[field] or UNKNOWN), SPECIAL_DOCUMENTATION[SPECIAL_TYPES[field]] } }
	XRPCharacterTable.Fields[#XRPCharacterTable.Fields + 1] = fieldTable
	XRPProfileFieldTable.Fields[#XRPProfileFieldTable.Fields + 1] = fieldTable
	XRPProfileInheritTable.Fields[#XRPProfileInheritTable.Fields + 1] = { Name = field, Type = "bool", Nilable = false }
end

local OtherMSP = { Name = "<otherMSPField>", Type = "string", Nilable = true, Documentation = { "MSP fields not documented above are usable, but do not have type guarantees." } }
XRPCharacterTable.Fields[#XRPCharacterTable.Fields + 1] = OtherMSP
XRPProfileFieldTable.Fields[#XRPProfileFieldTable.Fields + 1] = OtherMSP
XRPProfileInheritTable.Fields[#XRPProfileInheritTable.Fields + 1] = { Name = "<otherMSPField>", Type = "bool", Nilable = false }

local XRPAPI = {
	Name = "XRP",
	Type = "System",
	Namespace = "AddOn_XRP",
	Functions = {
		{
			Name = "RegisterEventCallback",
			Type = "Function",
			Arguments = {
				{ Name = "event", Type = "string", Nilable = false, Documentation = { "Literal name of any XRP system event." } },
				{ Name = "callback", Type = "function", Nilable = false },
			},
		},
		{
			Name = "UnregisterEventCallback",
			Type = "Function",
			Arguments = {
				{ Name = "event", Type = "string", Nilable = false, Documentation = { "Literal name of any XRP system event." } },
				{ Name = "callback", Type = "function", Nilable = false },
			},
		},
		{
			Name = "SetField",
			Type = "Function",
			Arguments = {
				{ Name = "field", Type = "string", Nilable = false },
				{ Name = "contents", Type = "string", Nilable = true },
			},
		},
		{
			Name = "SetStatus",
			Type = "Function",
			Arguments = {
				{ Name = "status", Type = "string or number", Nilable = false, Documentation = { "Accepts values of \"ic\", \"ooc\", or numbers 1-4." } },
			},
		},
		{
			Name = "ToggleStatus",
			Type = "Function",
		},
		{
			Name = "RemoveTextFormats",
			Type = "Function",
			Arguments = {
				{ Name = "text", Type = "string", Nilable = true },
				{ Name = "permitIndent", Type = "boolean", Nilable = true },
			},
			Returns = {
				{ Name = "text", Type = "string", Nilable = true, Documentation = { "Returns the input string with all pipe escapes either removed or disarmed. Returns nil if the input was empty or if the string consisted of nothing but known pipe escapes." } },
			},
		},
		{
			Name = "GetProfileList",
			Type = "Function",
			Returns = {
				{ Name = "profileList", Type = "table", InnerType = "string", Nilable = false, Documentation = { "Array of strings containing names of existing profiles." } },
			},
		},
		{
			Name = "AddProfile",
			Type = "Function",
			Arguments = {
				{ Name = "name", Type = "string", Nilable = false, Documentation = { "Profile must not not be named \"SELECTED\" and must not already exist." } },
			},
		},
		{
			Name = "SetProfile",
			Type = "Function",
			Arguments = {
				{ Name = "name", Type = "string", Nilable = false },
				{ Name = "isAutomated", Type = "boolean", Nilable = true, Documentation = { "This should be set to true if the user did not explicitly request a profile change.", "Overriden fields are not reset if a profile swap is performed automatically, but are reset if the user explicitly changed their profile." } },
			},
		},
		--[[{
			Name = "SearchCharacters",
			Type = "Function",
			Arguments = {
				{ Name = "query", Type = "XRPSearchQuery", Nilable = false },
			},
			Returns = {
				{ Name = "results", Type = "table", InnerType = "string", Nilable = false, Documentation = { "Array containing characterIDs of matching characters." } },
			},
		},]]
		{
			Name = "GetAPIVersion",
			Type = "Function",
			Returns = {
				{ Name = "apiVersion", Type = "number", Nilable = false, Documentation = { "Version of active XRP API.", "Different API versions are not guaranteed to be compatible with each other." } },
				{ Name = "apiFeatureLevel", Type = "number", Nilable = false, Documentation = { "Feature level of active XRP API.", "This can be used to check for the presence of a required feature stabilized at a specific feature level." } },
			},
		},
	},
	Events = {
		{
			Name = "XRPFieldReceived",
			Type = "Event",
			LiteralName = "ADDON_XRP_FIELD_RECEIVED",
			Documentation = { "Must be registered using AddOn_XRP.RegisterEventCallback().", "Runs whenever a full field is completed, during the reception of a full sequence of MSP packets, regardless of remaining content." },
			Payload =
			{
				{ Name = "characterID", Type = "string", Nilable = false },
				{ Name = "field", Type = "string", Nilable = false },
			},
		},
		{
			Name = "XRPProfileReceived",
			Type = "Event",
			LiteralName = "ADDON_XRP_PROFILE_RECEIVED",
			Documentation = { "Must be registered using AddOn_XRP.RegisterEventCallback().", "Runs when a full sequence of MSP packets have been received." },
			Payload =
			{
				{ Name = "characterID", Type = "string", Nilable = false },
			},
		},
		{
			Name = "XRPProgressUpdated",
			Type = "Event",
			LiteralName = "ADDON_XRP_PROGRESS_UPDATED",
			Documentation = { "Must be registered using AddOn_XRP.RegisterEventCallback().", "Runs whenever a MSP packet is received, allowing a progress indicator to be updated." },
			Payload =
			{
				{ Name = "characterID", Type = "string", Nilable = false },
				{ Name = "msgID", Type = "number", Nilable = false },
				{ Name = "msgTotal", Type = "number", Nilable = false },
			},
		},
		{
			Name = "XRPQueryFailed",
			Type = "Event",
			LiteralName = "ADDON_XRP_QUERY_FAILED",
			Documentation = { "Must be registered using AddOn_XRP.RegisterEventCallback().", "Runs whenever an error sending a MSP query is caught. Does not indicate addon support." },
			Payload =
			{
				{ Name = "characterID", Type = "string", Nilable = false },
				{ Name = "reason", Type = "string", Nilable = false, Documentation = { "The reason is a guess, one of either \"faction\" or \"offline\"." } },
			},
		},
		{
			Name = "XRPCacheDropped",
			Type = "Event",
			LiteralName = "ADDON_XRP_CACHE_DROPPED",
			Documentation = { "Must be registered using AddOn_XRP.RegisterEventCallback().", "Fires whenever one or more profiles are dropped from the cache, permitting automatic closure of viewing frames.", "Not a common event to be run." },
			Payload =
			{
				{ Name = "characterID", Type = "string", Nilable = true, Documentation = { "If nil, all profiles have been dropped during a full cache clear. This should be treated as if characterID matches the currently-viewed characterID." } },
			},
		},
	},
	Tables = {
		{
			Name = "XRPCharacters",
			Type = "Structure",
			Documentation = { "Accessed via AddOn_XRP.Characters." },
			Fields = {
				{ Name = "byName", Type = "XRPCharactersByName", Nilable = false },
				{ Name = "byNameOffline", Type = "XRPCharactersByNameOffline", Nilable = false },
				{ Name = "byGUID", Type = "XRPCharactersByGUID", Nilable = false },
				{ Name = "byUnit", Type = "XRPCharactersByUnit", Nilable = false },
			},
		},
		{
			Name = "XRPCharactersByName",
			Type = "Structure",
			Fields = {
				{ Name = "<characterName>", Type = "XRPCharacterTable", Nilable = true, Documentation = { "May be nil if the name is invalid." } },
				{ Name = "<characterID>", Type = "XRPCharacterTable", Nilable = true, Documentation = { "May be nil if the characterID is invalid." } },
			},
		},
		{
			Name = "XRPCharactersByNameOffline",
			Type = "Structure",
			Documentation = { "Unlike byName, this does *NOT* make automatic requests, and should only be used where cached data is explicitly desired." },
			Fields = {
				{ Name = "<characterName>", Type = "XRPCharacterTable", Nilable = true, Documentation = { "May be nil if the name is invalid.", "Name alone will only work for same home realm characters, use characterID (Name-RealmName) for crossrealm." } },
				{ Name = "<characterID>", Type = "XRPCharacterTable", Nilable = true, Documentation = { "May be nil if the characterID is invalid." } },
			},
		},
		{
			Name = "XRPCharactersByGUID",
			Type = "Structure",
			Fields = {
				{ Name = "<playerGUID>", Type = "XRPCharacterTable", Nilable = true, Documentation = { "May be nil if the GUID is invalid or the game client has no information on it." } },
			},
		},
		{
			Name = "XRPCharactersByUnit",
			Type = "Structure",
			Fields = {
				{ Name = "<unitID>", Type = "XRPCharacterTable", Nilable = true, Documentation = { "May be nil if the referenced unit does not exist, is not a player, or the game client has no information on them." } },
			},
		},
		XRPCharacterTable,
		{
			Name = "XRPProfiles",
			Type = "Structure",
			Documentation = { "Accessed via AddOn_XRP.Profiles." },
			Fields = {
				{ Name = "<profileName>", Type = "XRPProfileTable", Nilable = true, Documentation = { "May be nil if the named profile does not exist." } },
			},
		},
		{
			Name = "XRPProfileTable",
			Type = "Structure",
			Fields = {
				{ Name = "Field", Type = "XRPProfileFieldTable", Nilable = false, Documentation = { "Read-write table for the current profile's fields only." } },
				{ Name = "Full", Type = "XRPProfileFieldTable", Nilable = false, Documentation = { "Read-only table for the profile's fields and all inherited fields." } },
				{ Name = "Inherit", Type = "XRPProfileInheritTable", Nilable = false },
				{ Name = "parent", Type = "string", Nilable = false, Documentation = { "Parent profile, if any, where fields marked for inheritance are inherited from.", "Raises an error() if the parent is invalid (i.e., creating a loop)." } },
--				{ Name = "IsInUse", Type = "function", Nilable = false, Documentation = { "Method (use object-style call) used to determine if the profile is in-use.", "Returns bool isInUse." } },
				{ Name = "Delete", Type = "function", Nilable = false, Documentation = { "Method (use object-style call) used to delete a profile. Will raise an error() if the profile is in-use." } },
				{ Name = "Rename", Type = "function", Nilable = false, Documentation = { "Method (use object-style call) used to rename the current profile. Will raise an error() if the name is already used.", "Arguments string newName." } },
				{ Name = "Copy", Type = "function", Nilable = false, Documentation = { "Method (use object-style call) used to copy the current profile. Will raise an error() if the name is already used.", "Arguments string newName." } },
				{ Name = "IsParentValid", Type = "function", Nilable = false, Documentation = { "Method (use object-style call) used to check if the named profile is a valid parent.", "Arguments string newParent." } },
			},
		},
		XRPProfileFieldTable,
		XRPProfileInheritTable,
	},
}

if IsAddOnLoaded("Blizzard_APIDocumentation") then
	APIDocumentation:AddDocumentationTable(XRPAPI)
else
	local loaded = false
	hooksecurefunc("APIDocumentation_LoadUI", function()
		if not loaded then
			loaded = true
			APIDocumentation:AddDocumentationTable(XRPAPI)
		end
	end)
end
