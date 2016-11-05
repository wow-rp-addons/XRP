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
	(often inaccurately identified as UIDROPDOWNMENU_MENU_LEVEL taint),
	primarily to do with the UIDropDownMenu_Refresh() function.

	Second, it fixes the issue of tainting the Interface Options panel when an
	addon uses InterfaceOptions_AddCategory(). The issue is that
	InterfaceOptionsFrameCategories.selection sometimes becomes tainted and
	proceeds to taint the next full panel refresh.

	The fixes for these take advantage of a quirk of the secure variable system
	in the Lua API. Any variable in a table other than _G will become secure if
	it is set to nil, regardless of if it is set to nil from insecure code.
	This means that problematic insecure keys, which are the source of every
	taint issue this code addresses, can be "secured" by simply wiping them
	out.
]]

local DROPFIX_VERSION = 4

if dropfix and dropfix.version >= DROPFIX_VERSION then return end

if not dropfix then
	dropfix = {
		hooks = {},
		hooked = {},
		version = 0,
	}
end

function dropfix.hooks.UIDropDownMenu_InitializeHelper(frame)
	if UIDROPDOWNMENU_MENU_LEVEL > 1 then return end
	-- pcall() to catch non-frames masquerading as frames.
	local success, menuName = pcall(UIDROPDOWNMENU_INIT_MENU.GetName, UIDROPDOWNMENU_INIT_MENU)
	if success and menuName and issecurevariable(menuName) then
		-- Some non-default components of the dropdown buttons which were not
		-- securely set could cause taint to spread rapidly. This usually
		-- happens through leftover 'value' keys and UIDropDownMenu_Refresh()
		-- iterating through buttons while checking that key.
		for i = 1, UIDROPDOWNMENU_MAXLEVELS do
			for j = 1, UIDROPDOWNMENU_MAXBUTTONS do
				local button = _G[("DropDownList%dButton%d"):format(i, j)]
				for k, v in pairs(button) do
					-- 0 and invisibleButton are default elements.
					if k ~= 0 and k ~= "invisibleButton" and not issecurevariable(button, k) then
						button[k] = nil
					end
				end
			end
		end
	end
end

-- This fixes the tainting related to addons having interface options panels.
-- This value can become tainted, which then taints the execution path of the
-- entire interface options refreshing when next opened.
function dropfix.hooks.InterfaceOptionsFrame_OnHide(self)
	if not issecurevariable(InterfaceOptionsFrameCategories, "selection") then
		InterfaceOptionsFrameCategories.selection = nil
	end
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
