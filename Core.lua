
-- TODO:
-- - AutoMod für Events
-- - Custom-Einlade-Listen für Events (Gilde und nicht-Gilde)

local ADDON_NAME = "RepeatableCalendarEvents"
local VERSION = "@project-version@"
local log = FH3095Debug.log
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
	WEEKLY2 = 2,
	WEEKLY3 = 3,
	WEEKLY4 = 4,
	MONTHLY = 5,
	YEARLY = 6,
}
RCE.consts.WAIT_FOR_PLAYER_ALIVE = 60
RCE.consts.REPEAT_CHECK_INTERVAL = 11
RCE.consts.ADDON_NAME_COLORED = RCE.consts.COLORS.HIGHLIGHT .. RCE.consts.ADDON_NAME .. "|r"

local function buildCache(...)
	local sortDifficulties = function(a,b)
		return a.difficulty < b.difficulty
	end
	local sortEntries = function(a,b)
		if a.expansion ~= b.expansion then
			return a.expansion > b.expansion
		end
		return a.texture > b.texture
	end
	local LIST_ELEMENTS_PER_ENTRY = 6
	local result = {}
	local listSize = select("#", ...)
	if mod(listSize, LIST_ELEMENTS_PER_ENTRY) ~= 0 then
		error("List is not dividiable by 6. Code must be changed " .. listSize)
	end

	for i=1,listSize/LIST_ELEMENTS_PER_ENTRY do
		local title, texture, expansion, difficultyId, mapId, isLFR = select((i - 1) * LIST_ELEMENTS_PER_ENTRY + 1, ...)

		local difficultyName, _, _, _, isHeroic, isMythic = GetDifficultyInfo(difficultyId)
		if result[mapId] == nil or
			(result[mapId].isLFR and not isLFR) or
			((result[mapId].isHeroic or result[mapId].isMythic) and not (isHeroic or isMythic)) then
			local difficulties = {}
			if result[mapId] ~= nil then
				difficulties = result[mapId].difficulties
			end
			difficulties[difficultyId] = { difficulty = difficultyId, index = i, name = difficultyName}

			result[mapId] = {
				title = title,
				expansion = expansion,
				expansionName = _G["EXPANSION_NAME" .. expansion],
				isLFR = isLFR,
				isHeroic = isHeroic,
				isMythic = isMythic,
				texture = texture,
				difficulties = difficulties,
			}
		else
			result[mapId].difficulties[difficultyId] = { difficulty = difficultyId, index = i, name = difficultyName }
		end
	end

	local sortedResult = {}
	-- By purpose we drop the mapid-information and difficulty-id-key here. We dont need them any longer and they prevent sorting
	for _,v in pairs(result) do
		local difficulties = v.difficulties
		v.difficulties = {}
		for _,v2 in pairs(difficulties) do
			tinsert(v.difficulties, v2)
		end
		sort(v.difficulties, sortDifficulties)
		tinsert(sortedResult, v)
	end
	sort(sortedResult, sortEntries)
	return sortedResult
end

function RCE:buildCaches()
	if self.vars.raidCache == nil then
		self.vars.raidCache = buildCache(CalendarEventGetTextures(self.consts.EVENT_TYPES.RAID))
	end
	if self.vars.dungeonCache == nil then
		self.vars.dungeonCache = buildCache(CalendarEventGetTextures(self.consts.EVENT_TYPES.DUNGEON))
	end
end

function RCE:OnInitialize()
	self.vars = {}
	--FH3095Debug.onInit()
	self.l = LibStub("AceLocale-3.0"):GetLocale("RepeatableCalendarEvents", false)
	self.gui = LibStub("AceGUI-3.0")
	self.timers = LibStub("AceTimer-3.0")

	local defaultDb = { profile = { events = {}, eventsInFuture = 30, autoModNames = "", }}
	self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", defaultDb)
	self:createOptions()

	LibStub("AceEvent-3.0"):Embed(self) -- Have to embed, UnregisterEvent doesnt work otherwise
	-- On login, ask for calendar at PlayerAlive
	self:RegisterEvent("PLAYER_ALIVE", function()
		log("PLAYER_ALIVE")
		OpenCalendar()
		RCE:UnregisterEvent("PLAYER_ALIVE")
	end)
	self.timers:ScheduleTimer(function()
		log("Wait for PLAYER_ALIVE expired, unregister events")
		RCE:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		RCE:UnregisterEvent("PLAYER_ALIVE")
	end, self.consts.WAIT_FOR_PLAYER_ALIVE)
	self:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST", function()
		log("CALENDAR_UPDATE_EVENT_LIST")
		RCE:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		RCE:scheduleRepeatCheck()
	end)


	self.console = LibStub("AceConsole-3.0")
	local consoleCommandFunc = function(msg, editbox)
		RCE:consoleParseCommand(msg, editbox)
	end
	self.console:RegisterChatCommand("RCE", consoleCommandFunc, true)
	self.console:RegisterChatCommand("RepeatableCalendarEvents", consoleCommandFunc, true)

end

function RCE:OnEnable()
	FH3095Debug.onEnable()
end

function RCE:consoleParseCommand(msg, editbox)
	log("ConsoleParseCommand", msg)
	local cmd, nextpos = self.console:GetArgs(msg)

	if cmd ~= nil then
		if cmd == "check" then
			OpenCalendar() -- Normaly we have to wait for the event to return. But this command is a test-only command anyway
			self:scheduleRepeatCheck(1)
		elseif cmd == "new" then
			self:openEventWindow()
		else
			self:openEventsListWindow()
		end
	else
		self:openEventsListWindow()
	end
end

function RCE:printError(str, ...)
	str = self.consts.ADDON_NAME_COLORED .. " |cFFFF0000Error:|r " .. str
	print(str:format(...))
end

function RCE:getCacheForEventType(eventType)
	self:buildCaches()
	if eventType == 1 then
		return self.vars.raidCache
	elseif eventType == 2 then
		return self.vars.dungeonCache
	else
		return nil
	end
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
		local cache = self:getCacheForEventType(event.type)
		if empty(event.raidOrDungeon) or event.raidOrDungeon <= 0 or event.raidOrDungeon > #cache then
			self:printError(L.ErrorNoRaidOrDungeonChoosen)
			return false
		end
		if empty(event.difficulty) or event.difficulty <= 0 or event.difficulty > #cache[event.raidOrDungeon].difficulties then
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

function RCE:setCalendarMonthToDate(dateTable)
	CalendarSetAbsMonth(dateTable.month, dateTable.year)
	-- assert that CalendarSetMonth worked
	currentCalendarMonth, currentCalendarYear = CalendarGetMonth(0)
	assert(currentCalendarMonth == dateTable.month, "Month mismatch " .. currentCalendarMonth .. " <> " .. dateTable.month)
	assert(currentCalendarYear == dateTable.year, "Year mismatch " .. currentCalendarYear .. " <> " .. dateTable.year)
end

function RCE:normalizeDateTable(dateTable)
	dateTable = date("*t", time(dateTable))
	local ret = {}
	ret.year = dateTable.year
	ret.month = dateTable.month
	ret.day = dateTable.day
	ret.hour = dateTable.hour
	ret.min = dateTable.min

	return ret
end
