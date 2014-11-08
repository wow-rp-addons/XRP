--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

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

	This provides a compatibility layer for replacing ChatThrottleLib with
	libbw.
]]

local CTL_VERSION = 23

if not libbw or (ChatThrottleLib and ChatThrottleLib.libbw and ChatThrottleLib.version >= CTL_VERSION) then return end

if type(ChatThrottleLib) ~= "table" then
	ChatThrottleLib = {}
else
	-- CTL uses a local ChatThrottleLib table, making overwriting an
	-- incomplete solution.
	wipe(ChatThrottleLib)
end

ChatThrottleLib.version = CTL_VERSION
ChatThrottleLib.libbw = true

function ChatThrottleLib:SendAddonMessage(priorityName, prefix, text, kind, target, queueName, callbackFn, callbackArg)
	-- TODO: CTL error messages.
	return libbw:SendAddonMessage(prefix, text, kind, target, priorityName, queueName, callbackFn, callbackArg)
end

function ChatThrottleLib:SendChatMessage(priorityName, prefix, text, kind, language, target, queueName, callbackFn, callbackArg)
	-- TODO: CTL error messages.
	return libbw:SendChatMessage(text, kind, language, target, priorityName, queueName or prefix, callbackFn, callbackArg)
end

function ChatThrottleLib.Hook_SendChatMessage()
end
ChatThrottleLib.Hook_SendAddonMessage = ChatThrottleLib.Hook_SendChatMessage

_G.ChatThrottleLib = ChatThrottleLib
libbw.GAME.ctlcompat = true
