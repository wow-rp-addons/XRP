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

	libbw is partly based upon ChatThrottleLib, written by Mikk. This
	fork/rewrite adds support for Battle.net (BattleTag/RealID) communications,
	doesn't handle ancient WoW versions, and trusts the Lua garbage collector
	to do its job. As of version 4, it also takes advantage of newer features
	in the WoW API, such as C_Timer.NewTicker().

	libbw provides throttling for outgoing communication in order to avoid
	situations where communications either trigger disconnects (with in-game
	channels) or silent failures (with BattleTag/RealID).

	The public functions provided are:
		- libbw:SendAddonMessage(prefix, message, type[, target])
		- libbw:BNSendGameData(bnetIDGameAccount, prefix, message)
		- (*)libbw:SendChatMessage(message, type, languageID[, target])
		- (*)libbw:BNSendWhisper(bnetIDAccount, message)

	(*) These functions may be subject to extra spam filtering, which is not
		handled by libbw.

	The minimal arguments are identical to the global methods provided by
	Blizzard. In addition, each function takes up to four additional arguments:
		- priority: ALERT, NORMAL, BULK (defaults to NORMAL).
		- queue: Aribtrary value. Messages in the same queue and priority are
		  guaranteed to be sent in-order for most data. SendChatMessage() with
		  types of SAY, YELL, and EMOTE are not guaranteed to be in-order when
		  combined with other types of messages.
		- callbackFunction: A function to call when message is sent or dropped.
		  This is called in protected mode so ANY errors will NOT be displayed.
		- callbackArgument: The first argument provided to callbackFunction
		  (the second is whether the message was sent or dropped; this will
		  usually be true).

	Please keep in mind that empty arguments should be filled with nil if you
	intend to provide later arguments. For instance, a SendAddonMessage to
	GUILD with an ALERT priority and a callback should be called like:
		- libbw:SendAddonMessage(prefix, message, "GUILD", nil, "ALERT")
]]

local LIBBW_VERSION = 9

if libbw and libbw.version >= LIBBW_VERSION then return end

if not libbw or libbw.version < 4 then
	local now = GetTime()
	libbw = {
		[1] = {
			[1] = {
				avail = 0,
				byName = {},
			},
			[2] = {
				avail = 0,
				byName = {},
			},
			[3] = {
				avail = 0,
				byName = {},
			},
			avail = 0,
			lastAvailUpdate = now,
			BPS = 1280,
			BURST = 4096,
		},
		[2] = {
			[1] = {
				avail = 0,
				byName = {},
			},
			[2] = {
				avail = 0,
				byName = {},
			},
			[3] = {
				avail = 0,
				byName = {},
			},
			avail = 0,
			lastAvailUpdate = now,
			BPS = 4096,
			BURST = 8192,
		},
		hooks = {},
		isHooked = {},
		bundled = ...,
		version = LIBBW_VERSION,
	}
else
	libbw.bundled = ...
	libbw.version = LIBBW_VERSION
end

local function UpdateAvail(pool)
	local BPS, BURST = pool.BPS, pool.BURST
	if InCombatLockdown() then
		BPS = BPS * 0.50
		BURST = BURST * 0.50
	end

	local now = GetTime()
	local newAvail = (now - pool.lastAvailUpdate) * BPS
	local avail = math.min(BURST, pool.avail + newAvail)
	avail = math.max(avail, -BPS) -- Probably going to disconnect anyway.
	pool.avail = avail
	pool.lastAvailUpdate = now

	return avail
end

local isSending = false

local function RunQueue()
	local hasQueue = false
	for i, pool in ipairs(libbw) do
		if pool.queueing then
			local active = 0
			for i, priority in ipairs(pool) do
				if priority[1] then -- Priority has queues.
					active = active + 1
				elseif priority.avail > 0 then
					-- Reclaim unused bandwidth.
					pool.avail = pool.avail + priority.avail
					priority.avail = 0
				end
			end
			if active > 0 then
				hasQueue = true
				if UpdateAvail(pool) > 0 then
					local avail = pool.avail / active
					pool.avail = 0
					for i, priority in ipairs(pool) do
						if priority[1] then
							priority.avail = priority.avail + avail
							while priority[1] and priority.avail >= priority[1][1].length do
								local queue = table.remove(priority, 1)
								local message = table.remove(queue, 1)
								if queue[1] then -- More messages in this queue.
									priority[#priority + 1] = queue
								else -- No more messages in this queue.
									priority.byName[queue.name] = nil
								end
								local didSend = false
								if (message.kind ~= "RAID" and message.kind ~= "PARTY" or IsInGroup(LE_PARTY_CATEGORY_HOME)) and (message.kind ~= "INSTANCE_CHAT" or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
									priority.avail = priority.avail - message.length
									isSending = true
									didSend = message.f(unpack(message, 1, 4)) ~= false
									isSending = false
								end
								if message.callbackFn then
									pcall(message.callbackFn, message.callbackArg, didSend)
								end
							end
						end
					end
				end
			else
				pool.queueing = nil
			end
		end
	end
	if not hasQueue then
		libbw.ticker:Cancel()
		libbw.ticker = nil
	end
end

local PRIORITIES = {
	ALERT = 1,
	NORMAL = 2,
	BULK = 3,
}
local function Enqueue(pool, priorityName, queueName, message)
	local priority = pool[PRIORITIES[priorityName] or 2]
	local queue = priority.byName[queueName]
	if not queue then
		queue = {}
		queue.name = queueName
		priority.byName[queueName] = queue
		priority[#priority + 1] = queue
		if not libbw.ticker then
			libbw.ticker = C_Timer.NewTicker(0.1, RunQueue)
		end
	end
	queue[#queue + 1] = message
	pool.queueing = true
end

function libbw:SendAddonMessage(prefix, text, kind, target, priorityName, queueName, callbackFn, callbackArg)
	local pool = self[1]
	if type(prefix) ~= "string" or type(text) ~= "string" or type(kind) ~= "string" or (kind == "WHISPER" or kind == "CHANNEL") and not target then
		error("Usage: libbw:SendAddonMessage(\"prefix\", \"text\", \"type\"[, \"target\"])", 2)
	elseif callbackFn and type(callbackFn) ~= "function" then
		error("libbw:SendAddonMessage(): callbackFn: expected function, got " .. type(callbackFn), 2)
	end

	local length = #text
	if length > 255 then
		error("libbw:SendAddonMessage(): message length cannot exceed 255 bytes", 2)
	elseif target then
		length = length + #tostring(target)
	end
	length = length + 16 + #kind

	kind = kind:upper()

	if self.ctl and not ChatThrottleLib.libbw then
		-- CTL likes to drop RAID messages, despite the game falling back
		-- automatically to PARTY.
		if kind == "RAID" and not IsInRaid() then
			kind = "PARTY"
		end
		if not PRIORITIES[priorityName] then
			priorityName = "NORMAL"
		end
		ChatThrottleLib:SendAddonMessage(priorityName, prefix, text, kind, target, queueName or ("%s%s%s"):format(prefix, kind, tostring(target) or ""), callbackFn, callbackArg)
		return
	end

	if not pool.queueing and length <= UpdateAvail(pool) then
		pool.avail = pool.avail - length
		isSending = true
		SendAddonMessage(prefix, text, kind, target)
		isSending = false
		if callbackFn then
			pcall(callbackFn, callbackArg, true)
		end
		return
	end

	local message = {
		f = SendAddonMessage,
		[1] = prefix,
		[2] = text,
		[3] = kind,
		[4] = target,
		kind = kind,
		length = length,
		callbackFn = callbackFn,
		callbackArg = callbackArg,
	}

	Enqueue(pool, priorityName, queueName or ("%s%s%s"):format(prefix, kind, (tostring(target) or "")), message)
end

function libbw:SendChatMessage(text, kind, languageID, target, priorityName, queueName, callbackFn, callbackArg)
	local pool = self[1]
	if type(text) ~= "string" or (kind == "WHISPER" or kind == "CHANNEL") and not target or languageID and type(languageID) ~= "number" then
		error("Usage: libbw:SendChatMessage(\"text\"[, \"type\"[, languageID [, \"target\"]]])", 2)
	elseif callbackFn and type(callbackFn) ~= "function" then
		error("libbw:SendChatMessage(): callbackFn: expected function, got " .. type(callbackFn), 2)
	end

	local length = #text
	if length > 255 then
		error("libbw:SendChatMessage(): message length cannot exceed 255 bytes", 2)
	elseif target then
		length = length + #tostring(target)
	end
	if kind then
		length = length + #kind
		kind = kind:upper()
	end

	if self.ctl and not ChatThrottleLib.libbw then
		-- CTL likes to drop RAID messages, despite the game falling back
		-- automatically to PARTY.
		if kind == "RAID" and not IsInRaid() then
			kind = "PARTY"
		end
		if not PRIORITIES[priorityName] then
			priorityName = "NORMAL"
		end
		ChatThrottleLib:SendChatMessage(priorityName, "libbw", text, kind, languageID, target, queueName or kind .. (target or ""), callbackFn, callbackArg)
		return
	end

	if not pool.queueing and length <= UpdateAvail(pool) then
		pool.avail = pool.avail - length
		isSending = true
		SendChatMessage(text, kind, languageID, target)
		isSending = false
		if callbackFn then
			pcall(callbackFn, callbackArg, true)
		end
		return
	end

	local message = {
		f = SendChatMessage,
		[1] = text,
		[2] = kind,
		[3] = languageID,
		[4] = target,
		kind = kind,
		length = length,
		callbackFn = callbackFn,
		callbackArg = callbackArg,
	}

	Enqueue(pool, priorityName, queueName or kind .. (target or ""), message)
end

function libbw:BNSendGameData(bnetIDGameAccount, prefix, text, priorityName, queueName, callbackFn, callbackArg)
	local pool = self[2]
	if type(bnetIDGameAccount) ~= "number" or type(prefix) ~= "string" or type(text) ~= "string" then
		error("Usage: libbw:BNSendGameData(bnetIDGameAccount, \"prefix\", \"text\")", 2)
	elseif callbackFn and type(callbackFn) ~= "function" then
		error("libbw:BNSendGameData(): callbackFn: expected function, got " .. type(callbackFn), 2)
	end

	local length = #text
	if length > 4078 then
		error("libbw:BNSendGameData(): message length cannot exceed 4078 bytes", 2)
	end
	length = length + 18 -- Max 4096 per message.

	if not pool.queueing and length <= UpdateAvail(pool) then
		pool.avail = pool.avail - length
		isSending = true
		BNSendGameData(bnetIDGameAccount, prefix, text)
		isSending = false
		if callbackFn then
			pcall(callbackFn, callbackArg, didSend)
		end
		return
	end

	local message = {
		f = BNSendGameData,
		[1] = bnetIDGameAccount,
		[2] = prefix,
		[3] = text,
		length = length,
		callbackFn = callbackFn,
		callbackArg = callbackArg,
	}

	Enqueue(pool, priorityName, queueName or ("%s%d"):format(prefix, bnetIDGameAccount), message)
end

function libbw:BNSendWhisper(bnetIDAccount, text, priorityName, queueName, callbackFn, callbackArg)
	local pool = self[2]
	if type(bnetIDAccount) ~= "number" or type(text) ~= "string" then
		error("Usage: libbw:BNSendWhisper(bnetIDAccount, \"text\")", 2)
	elseif callbackFn and type(callbackFn) ~= "function" then
		error("libbw:BNSendWhisper(): callbackFn: expected function, got " .. type(callbackFn), 2)
	end

	local length = #text
	if length > 255 then
		error("libbw:BNSendWhisper(): message length cannot exceed 255 bytes", 2)
	end
	length = length + 2

	if not pool.queueing and length <= UpdateAvail(pool) then
		pool.avail = pool.avail - length
		isSending = true
		BNSendWhisper(bnetIDAccount, text)
		isSending = false
		if callbackFn then
			pcall(callbackFn, callbackArg, didSend)
		end
		return
	end

	local message = {
		f = BNSendWhisper,
		[1] = bnetIDAccount,
		[2] = text,
		length = length,
		callbackFn = callbackFn,
		callbackArg = callbackArg,
	}

	Enqueue(pool, priorityName, queueName or tostring(bnetIDAccount), message)
end

-- Hooks won't be run if function calls error (improper arguments).
function libbw.hooks.SendAddonMessage(prefix, text, kind, target)
	if isSending then return end
	libbw[1].avail = libbw[1].avail - (#tostring(text) + #kind + 16 + (target and #tostring(target) or 0))
end
function libbw.hooks.SendChatMessage(text, kind, languageID, target)
	if isSending then return end
	libbw[1].avail = libbw[1].avail - (#tostring(text) + (kind and #kind or 0) + (target and #tostring(target) or 0))
end
function libbw.hooks.BNSendGameData(bnetIDGameAccount, prefix, text)
	if isSending then return end
	libbw[2].avail = libbw[2].avail - (#tostring(text) + 18)
end
function libbw.hooks.BNSendWhisper(bnetIDAccount, text)
	if isSending then return end
	libbw[2].avail = libbw[2].avail - (#tostring(text) + 2)
end
do
	local function fake_OnUpdate(self, elapsed)
		self.lastDraw = self.lastDraw + elapsed
	end
	local function fake_OnEvent(self, event, ...)
		if self.lastDraw < GetTime() - 5 then
			if libbw.ticker then
				libbw.ticker._callback()
			end
			if libbw.ctl and ChatThrottleLib.Frame:IsVisible() then
				ChatThrottleLib.Frame:GetScript("OnUpdate")(ChatThrottleLib.Frame, 0.10)
			end
		end
	end
	function libbw.hooks.RestartGx()
		if GetCVar("gxWindow") == "0" then
			if not libbw.frame then
				libbw.frame = CreateFrame("Frame")
				libbw.frame:SetScript("OnUpdate", fake_OnUpdate)
				libbw.frame:SetScript("OnEvent", fake_OnEvent)
			end
			-- These events are somewhat regular while idling tabbed out.
			libbw.frame:RegisterEvent("CHAT_MSG_ADDON")
			libbw.frame:RegisterEvent("CHAT_MSG_CHANNEL")
			libbw.frame:RegisterEvent("CHAT_MSG_GUILD")
			libbw.frame:RegisterEvent("CHAT_MSG_SAY")
			libbw.frame:RegisterEvent("CHAT_MSG_YELL")
			libbw.frame:RegisterEvent("CHAT_MSG_EMOTE")
			libbw.frame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
			libbw.frame:RegisterEvent("GUILD_ROSTER_UPDATE")
			libbw.frame:RegisterEvent("GUILD_TRADESKILL_UPDATE")
			libbw.frame:RegisterEvent("GUILD_RANKS_UPDATE")
			libbw.frame:RegisterEvent("PLAYER_GUILD_UPDATE")
			libbw.frame:RegisterEvent("COMPANION_UPDATE")
			libbw.frame.lastDraw = GetTime()
			libbw.frame:Show()
		elseif libbw.frame then
			libbw.frame:UnregisterAllEvents()
			libbw.frame:Hide()
		end
	end
	if libbw.frame then
		libbw.frame:SetScript("OnUpdate", fake_OnUpdate)
		libbw.frame:SetScript("OnEvent", fake_OnEvent)
	end
	libbw.hooks.RestartGx()
end

for name, func in pairs(libbw.hooks) do
	if not libbw.isHooked[name] then
		hooksecurefunc(name, function(...)
			return libbw.hooks[name](...)
		end)
		libbw.isHooked[name] = true
	end
end

if libbw.ticker then
	libbw.ticker:Cancel()
	libbw.ticker = C_Timer.NewTicker(0.1, RunQueue)
end

-- The following code provides a compatibility layer for addons using
-- ChatThrottleLib. It won't load (and libbw will feed messages into CTL) if
-- there's a newer version of CTL around than this layer is compatible with.
local CTL_VERSION = 23

if ChatThrottleLib and not ChatThrottleLib.libbw and ChatThrottleLib.version > CTL_VERSION then
	libbw.ctl = true
	return
end

if type(ChatThrottleLib) ~= "table" then
	ChatThrottleLib = {}
else
	setmetatable(ChatThrottleLib, nil)
end
ChatThrottleLib.version = nil -- Handled in metatable.
ChatThrottleLib.libbw = true

function ChatThrottleLib:SendAddonMessage(priorityName, prefix, text, kind, target, queueName, callbackFn, callbackArg)
	if not priorityName or not prefix or not text or not kind or not PRIORITIES[priorityName] then
		error("Usage: ChatThrottleLib:SendAddonMessage(\"{BULK||NORMAL||ALERT}\", \"prefix\", \"text\", \"chattype\"[, \"target\"])", 2)
	elseif callbackFn and type(callbackFn) ~= "function" then
		error("ChatThrottleLib:SendAddonMessage(): callbackFn: expected function, got " .. type(callbackFn), 2)
	elseif #text > 255 then
		error("ChatThrottleLib:SendAddonMessage(): message length cannot exceed 255 bytes", 2)
	end
	libbw:SendAddonMessage(prefix, text, kind, target, priorityName, queueName or ("%s%s%s"):format(prefix, kind, (tostring(target) or "")), callbackFn, callbackArg)
end

function ChatThrottleLib:SendChatMessage(priorityName, prefix, text, kind, language, target, queueName, callbackFn, callbackArg)
	if not priorityName or not prefix or not text or not PRIORITIES[priorityName] then
		error("Usage: ChatThrottleLib:SendChatMessage(\"{BULK||NORMAL||ALERT}\", \"prefix\", \"text\"[, \"chattype\"[, \"language\"[, \"destination\"]]]", 2)
	elseif callbackFn and type(callbackFn) ~= "function" then
		error("ChatThrottleLib:SendChatMessage(): callbackFn: expected function, got " .. type(callbackFn), 2)
	elseif #text > 255 then
		error("ChatThrottleLib:SendChatMessage(): message length cannot exceed 255 bytes", 2)
	end
	libbw:SendChatMessage(text, kind, language, target, priorityName, queueName or ("%s%s%s"):format(prefix, (kind or "SAY"), (tostring(target) or "")), callbackFn, callbackArg)
end

function ChatThrottleLib.Hook_SendAddonMessage()
end
ChatThrottleLib.Hook_SendChatMessage = ChatThrottleLib.Hook_SendAddonMessage

-- This metatable catches changes to the CTL version, in case of a newer
-- version of CTL replacing this compatibility layer.
setmetatable(ChatThrottleLib, {
	__index = function(self, key)
		if key == "version" then
			return CTL_VERSION
		elseif key == "securelyHooked" then
			return true
		end
	end,
	__newindex = function(self, key, value)
		if key == "version" then
			self.libbw = nil
			libbw.ctl = true
			setmetatable(self, nil)
		end
		rawset(self, key, value)
	end,
})

libbw.ctl = nil
