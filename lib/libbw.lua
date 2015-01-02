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
	to do its job.

	libbw provides throttling for outgoing communication, in order to avoid
	situations where communications either trigger disconnects (with in-game
	channels) or silent failures (with BattleTag/RealID).

	The public functions provided are:
		- libbw:BNSendGameData(presenceID, prefix, message)
		- libbw:SendAddonMessage(prefix, message, type[, target])
		- libbw:SendChatMessage(message, type, languageID[, target])

	The minimal arguments are identical to the global methods provided by
	Blizzard. In addition, each function takes up to four additional arguments:
		- priority: ALERT, NORMAL, BULK (defaults to NORMAL)
		- queue: Aribtrary value. Messages in the same queue are sent
		  in-order regardless of prefix, others are not guaranteed to be so.
		- callbackFunction: A function to call when message is removed from
		  queue (either due to being sent or dropped). This is called via
		  pcall() so ANY errors will NOT be displayed.
		- callbackArgument: The first argument provided to callbackFunction
		  (the second is whether the message was sent or dropped).

	Please keep in mind that empty arguments should be filled with nil if you
	intend to provide later arguments. For instance, a SendAddonMessage to
	GUILD with an ALERT priority should be called like:
		- libbw:SendAddonMessage(prefix, message, "GUILD", nil, "ALERT")

	There are some tunable settings (libbw.{BN,GAME}.{BPS,BURST}), but
	modifying these are not recommended. The default values have been tested
	and are close to the maximum which is reliably safe.
]]

local LIBBW_VERSION = 1

if libbw and libbw.version >= LIBBW_VERSION then return end

if not libbw then
	libbw = {
		BN = CreateFrame("Frame"), -- Handles BNSendGameData/etc.
		GAME = CreateFrame("Frame"), -- Handles SendAddonMessage/etc.
		hooked = false,
	}
end

libbw.version = LIBBW_VERSION

-- libbw does not guess protocol overhead -- while some values appear smaller
-- than ChatThrottleLib defaults, they're effectively on-par or higher. BURST
-- should never be less than twice the maximum message length (no less than
-- 8156 for BN and 510 for GAME), or else messages may get severely delayed or
-- just never sent (blocking all messages) when in-combat.
libbw.BN.BPS = 4078
libbw.BN.BURST = 8156
libbw.GAME.BPS = 1100
libbw.GAME.BURST = 3600

-- The above defaults are tuned for safe speed. The absolute maximum without
-- immediate issues are higher. DO NOT use these values in production, they
-- will not reliably be safe and are subject to serious issues if there's any
-- sort of traffic (including normal game traffic) not being handled by libbw.
--
--libbw.BN.BPS = 6000
--libbw.BN.BURST = 10000
--libbw.GAME.BPS = 1800
--libbw.GAME.BURST = 5000

function libbw:BNSendGameData(presenceID, prefix, text, priorityName, queueName, callbackFn, callbackArg)
	self = self.BN
	if type(presenceID) ~= "number" or not prefix or not text then
		error("Usage: libbw:BNSendGameData(presenceID, \"prefix\", \"text\")", 2)
	end
	if callbackFn and type(callbackFn) ~= "function" then
		error("libbw:BNSendGameData(): callbackFn: expected function, got " .. type(callbackFn), 2)
	end

	local length = #text

	if length > 4078 then
		error("libbw:BNSendGameData(): message length cannot exceed 4078 bytes", 2)
	end

	if not self.queueing and length <= self:UpdateAvail() then
		self.avail = self.avail - length
		self.sending = true
		local didSend = BNSendGameData(presenceID, prefix, text)
		self.sending = false
		if callbackFn then
			pcall(callbackFn, callbackArg, didSend)
		end
		return didSend
	end

	local message = {
		f = BNSendGameData,
		[1] = presenceID,
		[2] = prefix,
		[3] = text,
		length = length,
		callbackFn = callbackFn,
		callbackArg = callbackArg,
	}

	self:Enqueue(priorityName, queueName or ("%s%u"):format(prefix, presenceID), message)
end

function libbw:SendAddonMessage(prefix, text, kind, target, priorityName, queueName, callbackFn, callbackArg)
	self = self.GAME
	if not prefix or not text or not kind or not target and (kind == "WHISPER" or kind == "CHANNEL") then
		error("Usage: libbw:SendAddonMessage(\"prefix\", \"text\", \"type\"[, \"target\"])", 2)
	end
	if callbackFn and type(callbackFn) ~= "function" then
		error("libbw:SendAddonMessage(): callbackFn: expected function, got " .. type(callbackFn), 2)
	end

	local length = #text

	if length > 255 then
		error("libbw:SendAddonMessage(): message length cannot exceed 255 bytes", 2)
	end

	kind = kind:upper()

	if self.ctl and not ChatThrottleLib.libbw then
		-- CTL likes to drop RAID messages, despite the game falling back
		-- automatically to PARTY.
		if kind == "RAID" and not IsInRaid() then
			kind = "PARTY"
		end
		if priorityName ~= "NORMAL" and priorityName ~= "ALERT" and priorityName ~= "BULK" then
			priorityName = "NORMAL"
		end
		ChatThrottleLib:SendAddonMessage(priorityName, prefix, text, kind, target, queueName, callbackFn, callbackArg)
		return
	end

	if not self.queueing and length <= self:UpdateAvail() then
		self.avail = self.avail - length
		self.sending = true
		SendAddonMessage(prefix, text, kind, target)
		self.sending = false
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
		length = length,
		callbackFn = callbackFn,
		callbackArg = callbackArg,
	}

	self:Enqueue(priorityName, queueName or prefix .. kind .. (target or ""), message)
end

function libbw:SendChatMessage(text, kind, languageID, target, priorityName, queueName, callbackFn, callbackArg)
	self = self.GAME
	if not text or not target and (kind == "WHISPER" or kind == "CHANNEL") or languageID and type(languageID) ~= "number" then
		error("Usage: libbw:SendChatMessage(\"text\"[, \"type\"[, languageID [, \"target\"]]])", 2)
	end
	if callbackFn and type(callbackFn) ~= "function" then
		error("libbw:SendChatMessage(): callbackFn: expected function, got " .. type(callbackFn), 2)
	end

	local length = #text

	if length > 255 then
		error("libbw:SendChatMessage(): message length cannot exceed 255 bytes", 2)
	end

	kind = kind:upper()

	if self.ctl and not ChatThrottleLib.libbw then
		-- CTL likes to drop RAID messages, despite the game falling back
		-- automatically to PARTY.
		if kind == "RAID" and not IsInRaid() then
			kind = "PARTY"
		end
		if priorityName ~= "NORMAL" and priorityName ~= "ALERT" and priorityName ~= "BULK" then
			priorityName = "NORMAL"
		end
		ChatThrottleLib:SendChatMessage(priorityName, "libbw", text, kind, languageID, target, queueName, callbackFn, callbackArg)
		return
	end

	if not self.queueing and length <= self:UpdateAvail() then
		self.avail = self.avail - length
		self.sending = true
		SendChatMessage(text, kind, languageID, target)
		self.sending = false
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
		length = length,
		callbackFn = callbackFn,
		callbackArg = callbackArg,
	}

	self:Enqueue(priorityName, queueName or kind .. (target or ""), message)
end

-- Hooks won't be run if function calls error (improper arguments).
function libbw.Hook_BNSendGameData(presenceID, prefix, text)
	local self = libbw.BN
	if self.sending then return end
	self.avail = self.avail - #text
end
function libbw.Hook_SendAddonMessage(prefix, text, kind, target)
	local self = libbw.GAME
	if self.sending then return end
	self.avail = self.avail - #text
end
function libbw.Hook_SendChatMessage(text, kind, languageID, target)
	local self = libbw.GAME
	if self.sending then return end
	self.avail = self.avail - #text
end

if not libbw.hooked then
	hooksecurefunc("BNSendGameData", function(...)
		return libbw.Hook_BNSendGameData(...)
	end)
	hooksecurefunc("SendAddonMessage", function(...)
		return libbw.Hook_SendAddonMessage(...)
	end)
	hooksecurefunc("SendChatMessage", function(...)
		return libbw.Hook_SendChatMessage(...)
	end)
	libbw.hooked = true
end

local function libbw_UpdateAvail(self)
	local now = GetTime()
	local BPS, BURST = self.BPS, self.BURST
	if InCombatLockdown() then
		-- Cut traffic by half in-combat.
		BPS = BPS * 0.50
		BURST = BURST * 0.50
	end
	local newavail = BPS * (now - self.LastAvailUpdate)
	local avail = self.avail

	avail = math.min(BURST, avail + newavail)

	avail = math.max(avail, 0 - (BPS * 2))

	self.avail = avail
	self.LastAvailUpdate = now

	return avail
end

local function libbw_Enqueue(self, priorityName, queueName, message)
	local priority = self.priorities[priorityName] or self.priorities["NORMAL"]
	local queue = priority.byQueueName[queueName]
	if not queue then
		self:Show()
		queue = {}
		queue.name = queueName
		priority.byQueueName[queueName] = queue
		priority.queues:Add(queue)
	end
	queue[#queue + 1] = message
	self.queueing = true
end

local libbw_Despool
do
	local fnKindMap = {
		[SendChatMessage] = 2,
		[SendAddonMessage] = 3,
	}

	function libbw_Despool(self, priority)
		local ring = priority.queues
		while ring.queue and priority.avail >= ring.queue[1].length do
			local message = table.remove(ring.queue, 1)
			if not ring.queue[1] then  -- did we remove last message in this queue?
				local queue = ring.queue
				ring:Remove(queue)
				priority.byQueueName[queue.name] = nil
			else
				ring.queue = ring.queue.next
			end
			local doSend, kind = true, message[fnKindMap[message.f]]
			if kind and ((kind == "RAID" or kind == "PARTY") and not IsInGroup() or kind == "INSTANCE_CHAT" and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
				doSend = false
			end
			local didSend = false
			if doSend then
				priority.avail = priority.avail - message.length
				self.sending = true
				didSend = message.f(unpack(message, 1, 4)) ~= false
				self.sending = false
			end
			-- notify caller of delivery (even if we didn't send it)
			if message.callbackFn then
				pcall(message.callbackFn, message.callbackArg, didSend)
			end
		end
	end
end

local function libbw_OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 0.08 then return end
	self.timer = 0

	self:UpdateAvail()

	if self.avail <= 0 then return end

	local n = 0
	for name, priority in pairs(self.priorities) do
		if priority.queues.queue or priority.avail < 0 then
			n = n + 1
		end
	end

	if n == 0 then
		for name, priority in pairs(self.priorities) do
			self.avail = self.avail + priority.avail
			priority.avail = 0
		end
		self.queueing = false
		self:Hide()
		return
	end

	local avail = self.avail / n
	self.avail = 0
	for name, priority in pairs(self.priorities) do
		if priority.queues.queue or priority.avail < 0 then
			priority.avail = priority.avail + avail
			if priority.queues.queue and priority.avail >= priority.queues.queue[1].length then
				self:Despool(priority)
			end
		end
	end
end

local function libbw_OnEvent(self, event)
	-- Reset the availability counter.
	self.LastAvailUpdate = GetTime()
	if self.avail > 0 then
		self.avail = 0
	end
end

do
	local queuesMeta = {
		__index = {
			Add = function(self, newQueue)
				if self.queue then
					-- Append new at the end of the chain.
					newQueue.prev = self.queue.prev
					newQueue.prev.next = newQueue
					newQueue.next = self.queue
					newQueue.next.prev = newQueue
				else
					-- New is only.
					newQueue.next = newQueue
					newQueue.prev = newQueue
					self.queue = newQueue
				end
			end,
			Remove = function (self, delQueue)
				-- Remove it from the chain.
				delQueue.next.prev = delQueue.prev
				delQueue.prev.next = delQueue.next
				if self.queue == delQueue then
					-- Removed is current.
					self.queue = delQueue.next
					if self.queue == delQueue then
						-- Removed is current and only.
						self.queue = nil
					end
				end
			end,
		},
	}

	libbw.BN.priorities = {
		ALERT = { byQueueName = {}, queues = setmetatable({}, queuesMeta), avail = 0 },
		NORMAL = { byQueueName = {}, queues = setmetatable({}, queuesMeta), avail = 0 },
		BULK = { byQueueName = {}, queues = setmetatable({}, queuesMeta), avail = 0 },
	}

	libbw.GAME.priorities = {
		ALERT = { byQueueName = {}, queues = setmetatable({}, queuesMeta), avail = 0 },
		NORMAL = { byQueueName = {}, queues = setmetatable({}, queuesMeta), avail = 0 },
		BULK = { byQueueName = {}, queues = setmetatable({}, queuesMeta), avail = 0 },
	}
end

libbw.BN.avail = 0
libbw.GAME.avail = 0
do
	local now = GetTime()
	libbw.BN.LastAvailUpdate = now
	libbw.GAME.LastAvailUpdate = now
end

libbw.BN.Enqueue = libbw_Enqueue
libbw.BN.Despool = libbw_Despool
libbw.BN.UpdateAvail = libbw_UpdateAvail
libbw.BN.OnUpdate = libbw_OnUpdate -- Allows for running without framedraws.
libbw.BN:SetScript("OnUpdate", libbw_OnUpdate)
libbw.BN:SetScript("OnEvent", libbw_OnEvent)
libbw.BN:RegisterEvent("PLAYER_ENTERING_WORLD")

libbw.GAME.Enqueue = libbw_Enqueue
libbw.GAME.Despool = libbw_Despool
libbw.GAME.UpdateAvail = libbw_UpdateAvail
libbw.GAME.OnUpdate = libbw_OnUpdate -- Allows for running without framedraws.
libbw.GAME:SetScript("OnUpdate", libbw_OnUpdate)
libbw.GAME:SetScript("OnEvent", libbw_OnEvent)
libbw.GAME:RegisterEvent("PLAYER_ENTERING_WORLD")

-- The following code provides a compatibility layer for addons using
-- ChatThrottleLib. It won't load (and libbw will feed messages into CTL) if
-- there's a newer version of CTL around than this layer is compatible with.
local CTL_VERSION = 23

if ChatThrottleLib and not ChatThrottleLib.libbw and ChatThrottleLib.version > CTL_VERSION then
	-- Newer CTL already loaded, route through it.
	libbw.GAME.ctl = true
	return
end

if type(ChatThrottleLib) ~= "table" then
	ChatThrottleLib = {}
else
	-- Remove any old libbw metatable, if present, before (re-)building the
	-- compatibility layer.
	setmetatable(ChatThrottleLib, nil)
end
ChatThrottleLib.version = nil -- Handled in metatable.
ChatThrottleLib.libbw = true

function ChatThrottleLib:SendAddonMessage(priorityName, prefix, text, kind, target, queueName, callbackFn, callbackArg)
	if not priorityName or not prefix or not text or not kind or (priorityName ~= "ALERT" and priorityName ~= "NORMAL" and priorityName ~= "BULK") then
		error('Usage: ChatThrottleLib:SendAddonMessage("{BULK||NORMAL||ALERT}", "prefix", "text", "chattype"[, "target"])', 2)
	end
	if callbackFn and type(callbackFn) ~= "function" then
		error('ChatThrottleLib:SendAddonMessage(): callbackFn: expected function, got ' .. type(callbackFn), 2)
	end
	if #text > 255 then
		error("ChatThrottleLib:SendAddonMessage(): message length cannot exceed 255 bytes", 2)
	end
	return libbw:SendAddonMessage(prefix, text, kind, target, priorityName, queueName, callbackFn, callbackArg)
end

function ChatThrottleLib:SendChatMessage(priorityName, prefix, text, kind, language, target, queueName, callbackFn, callbackArg)
	if not priorityName or not prefix or not text or (priorityName ~= "ALERT" and priorityName ~= "NORMAL" and priorityName ~= "BULK") then
		error('Usage: ChatThrottleLib:SendChatMessage("{BULK||NORMAL||ALERT}", "prefix", "text"[, "chattype"[, "language"[, "destination"]]]', 2)
	end
	if callbackFn and type(callbackFn) ~= "function" then
		error('ChatThrottleLib:SendChatMessage(): callbackFn: expected function, got ' .. type(callbackFn), 2)
	end
	if #text > 255 then
		error("ChatThrottleLib:SendChatMessage(): message length cannot exceed 255 bytes", 2)
	end
	return libbw:SendChatMessage(text, kind, language, target, priorityName, queueName or prefix .. (kind or "SAY") .. (target or ""), callbackFn, callbackArg)
end

function ChatThrottleLib.Hook_SendChatMessage()
end
ChatThrottleLib.Hook_SendAddonMessage = ChatThrottleLib.Hook_SendChatMessage

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
		if key == "version" and value > CTL_VERSION then
			self.libbw = nil
			libbw.GAME.ctl = true
			setmetatable(self, nil)
		end
		rawset(self, key, value)
	end,
})

libbw.GAME.ctl = nil
