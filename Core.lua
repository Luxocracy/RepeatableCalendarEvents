
-- TODO:
-- - Raid/Dungeon and Difficulty
-- - AutoMod für Events
-- - Custom-Einlade-Listen für Events (Gilde und nicht-Gilde)

local ADDON_NAME = "RepeatableCalendarEvents"
local VERSION = "@project-version@"
local log = RepeatableCalendarEventsDebug.log
local RCE = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
RepeatableCalendarEvents = RCE

RCE.consts = {}
RCE.consts.ADDON_NAME = ADDON_NAME
RCE.consts.VERSION = VERSION
RCE.consts.CHAR_MAX_LEVEL = 110
RCE.consts.COLORS = {
	HIGHLIGHT = "|cFF00FFFF",
}
RCE.consts.EVENT_TYPES = {
	RAID = 1,
	DUNGEON = 2,
	PVP = 3,
	MEETING = 4,
	OTHER = 5,
}
RCE.consts.REPEAT_TYPES = {
	WEEKLY = 1,
	MONTHLY = 2,
	YEARLY = 3,
}
RCE.consts.ADDON_NAME_COLORED = RCE.consts.COLORS.HIGHLIGHT .. RCE.consts.ADDON_NAME .. "|r"
RCE.consts.REPEAT_CHECK_INTERVAL = 60


function RCE:OnInitialize()
	self.vars = {}
	self.l = LibStub("AceLocale-3.0"):GetLocale("RepeatableCalendarEvents", false)
	self.gui = LibStub("AceGUI-3.0")
	self.timers = LibStub("AceTimer-3.0")

	local defaultDb = { profile = { events = {}, eventsInFuture = 15, }}
	self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", defaultDb)
	local optionsTable = { name = self.consts.ADDON_NAME, type = "group", args = { profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }}
	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, optionsTable)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)

	LibStub("AceEvent-3.0"):Embed(self) -- Have to embed, UnregisterEvent doesnt work otherwise
	self:RegisterEvent("PLAYER_ALIVE", function()
		log("PLAYER_ALIVE")
		RCE:UnregisterEvent("PLAYER_ALIVE")
		RCE:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST", function()
			log("CALENDAR_UPDATE_EVENT_LIST")
			RCE:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
			RCE:scheduleRepeatCheck()
		end)
		OpenCalendar()
	end)

	self.console = LibStub("AceConsole-3.0")
	local consoleCommandFunc = function(msg, editbox)
		RCE:consoleParseCommand(msg, editbox)
	end
	self.console:RegisterChatCommand("RCE", consoleCommandFunc, true)
	self.console:RegisterChatCommand("RepeatableCalendarEvents", consoleCommandFunc, true)

end

function RCE:consoleParseCommand(msg, editbox)
	log("ConsoleParseCommand", msg)
	local cmd, nextpos = self.console:GetArgs(msg)

	if cmd ~= nil then
		if cmd == "list" then
			self:openEventsListWindow()
		elseif cmd == "confirm" then
			self:openConfirmWindow()
		elseif cmd == "check" then
			self:scheduleRepeatCheck(1)
		else
			self:openEventWindow(tonumber(cmd))
		end
	else
		self:openEventWindow(nil)
	end
end

function RCE:printError(str, ...)
	str = self.consts.ADDON_NAME_COLORED .. " |cFFFF0000Error:|r " .. str
	print(str:format(...))
end

function RCE:validateEvent(event)
	log("ValidateEvent", event)
	local empty = function(param)
		if param == nil or strtrim(param) == "" then
			return true
		else
			return false
		end
	end
	local L = self.l

	if empty(event.name) then
		self:printError(L.ErrorNameEmpty)
		return false
	end
	if empty(event.title) then
		self:printError(L.ErrorTitleEmpty)
		return false
	end
	if (event.type==self.consts.EVENT_TYPES.RAID or event.type==self.consts.EVENT_TYPES.DUNGEON) then
		if empty(event.raidOrDungeon) then
			self:printError(L.ErrorNoRaidOrDungeonChoosen)
			return false
		end
		if empty(event.difficulty) then
			self:printError(L.ErrorNoDifficultyChoosen)
			return false
		end
	end

	local currentTime = time()
	local eventTime = self:timeFromEvent(event, false)
	if not eventTime then
		self:printError(L.ErrorEventInvalidDate)
		return false
	end
	log("ValidateEvent Times: ", date(L.DateFormat, eventTime), date(L.DateFormat, currentTime))
	if currentTime >= eventTime then
		self:printError(L.ErrorEventIsInPast)
		return false
	end
	return true
end

function RCE:timeFromEvent(event, errorIfInvalid)
	local dateTable = self:timeTableFromEvent(event)
	local status, eventTime = xpcall(function() return time(dateTable) end, function() end)
	if not status then
		if errorIfInvalid then
			error("Date/Time for event " .. event.name .. " is invalid! Delete this event.")
		else
			return nil
		end
	end

	return tonumber(eventTime)
end

function RCE:timeTableFromEvent(event)
	local dateTable = {
		year = event.year,
		month = event.month,
		day = event.day,
		hour = event.hour,
		min = event.minute,
	}
	return dateTable
end

function RCE:scheduleRepeatCheck(secondsToCheck)
	if self.vars.repeatCheckTimer ~= nil and self.timers:TimeLeft(self.vars.repeatCheckTimer) > 0 then
		return -- Timer already running
	end

	local seconds = secondsToCheck
	if seconds == nil then
		seconds = self.consts.REPEAT_CHECK_INTERVAL
	end
	log("ScheduleRepeatCheck", seconds)

	self.vars.repeatCheckTimer = self.timers:ScheduleTimer(function() RCE:repeatEvent() end, seconds)
end
