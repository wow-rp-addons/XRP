--[[
	© Justin Snelgrove

	Permission to use, copy, modify, and/or distribute this software for any
	purpose with or without fee is hereby granted, provided that the above
	copyright notice and this permission notice appear in all copies.

	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
	WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
	SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
	WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
	ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
	IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

	This code, somewhat-inaccurately entitled "dropfix", fixes some infamous
	instances of tainting in the World of Warcraft Lua API. It is embeddable
	and should be included as a standalone file if you wish to use it.

	First, it fixes the tainting issues with the UIDropDownMenu subsystem
	(often inaccurately identified as UIDROPDOWNMENU_MENU_LEVEL taint,
	including initially by myself), one to do with the
	UIDropDownMenu_GetSelectedX() functions, and the other to do with
	UIDropDownMenu_Initialize() and the last opened menu (via
	ToggleDropDownMenu()) having an insecure displayMode key.

	Second, it fixes the issue of tainting the Interface Options panel when an
	addon makes use of InterfaceOptions_AddCategory() (which was designed for
	addons to use). The issue is that InterfaceOptionsFrameCategories.selection
	sometimes becomes tainted and proceeds to taint the full panel refresh.

	The two of these are both most famous for tainting the built-in raid
	frames, and for having that taint easily spread to other secure UI
	elements.

	The fixes for these take advantage of a quirk, likely intentional, of the
	secure variable system in the Lua API. Any variable in a table other than
	_G will become secure if it is set to nil, regardless of if it is set to
	nil from insecure code. This means that problematic insecure keys, which
	are the source of every taint issue this code addresses, can be "secured"
	by simply wiping them out.
]]

local DROPFIX_VERSION = 1

if dropfix and dropfix.version >= DROPFIX_VERSION then return end

if not dropfix then
	dropfix = {
		hooks = {},
		hooked = {},
		lastSecure = false,
		version = 0,
	}
end

local safe = {
	[0] = true,
	invisibleButton = true,
}
function dropfix.hooks.UIDropDownMenu_InitializeHelper(frame)
	local menuName = UIDROPDOWNMENU_INIT_MENU.GetName and UIDROPDOWNMENU_INIT_MENU:GetName()
	local isSecure = menuName and issecurevariable(menuName)
	if isSecure and not dropfix.lastSecure then
		-- Any non-default component of the dropdown buttons could be tainted
		-- and could cause taint to spread (especially with the GetSelectedX
		-- functions). It would be more 'proper' to check issecurevariable(),
		-- but that'd be a waste of cycles when this is perfectly safe to do
		-- during initialization.
		for i = 1, UIDROPDOWNMENU_MAXLEVELS do
			for j = 1, UIDROPDOWNMENU_MAXBUTTONS do
				local button = _G[("DropDownList%dButton%d"):format(i, j)]
				for k, v in pairs(button) do
					if not safe[k] then
						button[k] = nil
					end
				end
			end
		end
	end
	if isSecure and UIDROPDOWNMENU_OPEN_MENU and not issecurevariable(UIDROPDOWNMENU_OPEN_MENU, "displayMode") then
		-- Insecure displayMode on UIDROPDOWNMENU_OPEN_MENU causes taint when
		-- UIDropDownMenu_Initialize() reads it. This temporarily removes the
		-- displayMode key from the offending frame, followed by re-adding it
		-- as soon as possible (before the next framedraw, but after the
		-- current execution completes). I'm not fond of the closure, but it
		-- shouldn't be run enough to *really* matter.
		local fixMenu, fixDisplayMode = UIDROPDOWNMENU_OPEN_MENU, UIDROPDOWNMENU_OPEN_MENU.displayMode
		UIDROPDOWNMENU_OPEN_MENU.displayMode = nil
		C_Timer.After(0, function()
			fixMenu.displayMode = fixDisplayMode
		end)
	end

	dropfix.lastSecure = isSecure
end

-- This is not a UIDropDownMenu fix, it fixes the tainting related to addons
-- having interface options panels. This value can become tainted somehow, and
-- then taints the execution path of the entire interface options refreshing
-- when opened the next time.
function dropfix.hooks.InterfaceOptionsFrame_OnHide(self)
	InterfaceOptionsFrameCategories.selection = nil
end

if not dropfix.hooked["UIDropDownMenu_InitializeHelper"] then
	hooksecurefunc("UIDropDownMenu_InitializeHelper", function(...)
		dropfix.hooks.UIDropDownMenu_InitializeHelper(...)
	end)
	dropfix.hooked["UIDropDownMenu_InitializeHelper"] = true
end
if not dropfix.hooked["InterfaceOptionsFrame_OnHide"] then
	InterfaceOptionsFrame:HookScript("OnHide", function(...)
		dropfix.hooks.InterfaceOptionsFrame_OnHide(...)
	end)
	dropfix.hooked["InterfaceOptionsFrame_OnHide"] = true
end

dropfix.version = DROPFIX_VERSION
