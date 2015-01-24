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

	This small library fakes framedraws (OnUpdate scripts) for when the user is
	tabbed out in fullscreen mode. The requirements to make proper use of this
	library are:

		- A frame with an OnUpdate script set. If it's not set, it (obviously)
		  won't be run.

		- An OnUpdate script which does not rely on the elapsed time for
		  accurate time-telling, only as a delay timer. If you need accurate time
		  tracking, use GetTime().

	A frame is registered for fakedraws simply by running:

		libfakedraw:RegisterFrame(frame)
]]

local LIBFAKEDRAW_VERSION = 1

if libfakedraw and libfakedraw.version >= LIBFAKEDRAW_VERSION then return end

if not libfakedraw then
	libfakedraw = {
		frame = CreateFrame("Frame"),
		frames = {},
		hooks = {},
	}
	libfakedraw.frame:Hide()
end

libfakedraw.version = LIBFAKEDRAW_VERSION

local function OnShow_Hook(...)
	libfakedraw.hooks.Frame_OnShow(...)
end

function libfakedraw:RegisterFrame(frame)
	if self.frames[frame] then return end
	self.frames[frame] = {
		lastRun = frame:IsVisible() and GetTime() or 0,
	}
	frame:HookScript("OnShow", OnShow_Hook)
end

function libfakedraw.hooks.Frame_OnShow(frame)
	libfakedraw.frames[frame].lastRun = GetTime()
end

function libfakedraw.hooks.RestartGx()
	local self = libfakedraw.frame
	if GetCVar("gxWindow") == "0" then -- Is true fullscreen.
		self:Show()
		-- These events are relatively common while idling, so are used to fake
		-- OnUpdate when tabbed out.
		self:RegisterEvent("CHAT_MSG_ADDON")
		self:RegisterEvent("CHAT_MSG_CHANNEL")
		self:RegisterEvent("CHAT_MSG_GUILD")
		self:RegisterEvent("CHAT_MSG_SAY")
		self:RegisterEvent("CHAT_MSG_YELL")
		self:RegisterEvent("CHAT_MSG_EMOTE")
		self:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
		self:RegisterEvent("GUILD_ROSTER_UPDATE")
		self:RegisterEvent("GUILD_TRADESKILL_UPDATE")
		self:RegisterEvent("GUILD_RANKS_UPDATE")
		self:RegisterEvent("PLAYER_GUILD_UPDATE")
		self:RegisterEvent("COMPANION_UPDATE")
		-- This would be nice to use, but actually having it happening
		-- in-combat would be huge overhead.
		--self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else -- Is not true fullscreen.
		self:Hide()
		self:UnregisterAllEvents()
	end
end

libfakedraw.frame:SetScript("OnShow", function(self)
	self.lastDraw = GetTime()
end)

libfakedraw.frame:SetScript("OnUpdate", function(self, elapsed)
	self.lastDraw = self.lastDraw + elapsed
end)

libfakedraw.frame:SetScript("OnEvent", function(self, event, ...)
	local now = GetTime()
	if self.lastDraw < now - 5 then
		-- No framedraw for 5+ seconds.
		--print(now, "No draw in 5 seconds.")
		for frame, info in pairs(libfakedraw.frames) do
			if frame:IsVisible() then
				local elapsed = now - math.max(self.lastDraw, info.lastRun)
				if elapsed > 0 then
					--print(now, "Running frame script with delay:", elapsed)
					frame:GetScript("OnUpdate")(frame, elapsed)
					info.lastRun = now
				end
			end
		end
	end
end)

if not libfakedraw.hooked then
	hooksecurefunc("RestartGx", function(...)
		libfakedraw.hooks.RestartGx()
	end)
	libfakedraw.hooked = true
end

libfakedraw.hooks.RestartGx()
