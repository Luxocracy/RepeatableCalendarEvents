
local log = FH3095Debug.log
local RCE = RepeatableCalendarEvents

local function splitArray(array)
	local ret = {}
	for m in array:gmatch("%S+") do
		if m:trim() ~= "" then
			tinsert(ret, m)
		end
	end

	return ret
end

function RCE:checkAutoMod()
	local chars = splitArray(self.db.profile.autoModNames)
	log("CheckAutoMod", chars)

	local dateTable = date("*t")
	local events = {}
	local realmName = GetRealmName()
	local currentEvent = nil

	for futureDays=1,self.db.profile.eventsInFuture do
		self:setCalendarMonthToDate(dateTable)
		local numEvents = CalendarGetNumDayEvents(0, dateTable.day)
		for eventIndex=1,numEvents do
			local _, _,_, calendarType, _, _, _, modStatus = CalendarGetDayEvent(0, dateTable.day, eventIndex)
			if modStatus == "CREATOR" and (calendarType == "GUILD_EVENT" or calendarType == "PLAYER") then
				local event = {day = dateTable.day, month = dateTable.month, year = dateTable.year, index = eventIndex}
				tinsert(events, event)
			end
		end
		dateTable.day = dateTable.day + 1
		dateTable = self:normalizeDateTable(dateTable)
	end

	-- enqueue has to handle SetModerator: Cant do this while "CALENDAR_OPEN_EVENT" is running
	local function enqueueNextEvent(toMod)
		if toMod ~= nil then
			for _,inviteeIndex in pairs(toMod) do
				CalendarEventSetModerator(inviteeIndex)
			end
		end

		-- Also cant call CalendarCloseEvent while "CALENDAR_OPEN_EVENT" is running
		CalendarCloseEvent()

		currentEvent = tremove(events)
		if currentEvent == nil then
			self:UnregisterEvent("CALENDAR_OPEN_EVENT")
			self.console:Printf("%s: %s", self.consts.ADDON_NAME_COLORED, self.l.CalendarUpdateFinished)
			return
		end
		CalendarSetAbsMonth(currentEvent.month, currentEvent.year)
		log("CheckAutoMod: Enqueue Event", currentEvent.day, currentEvent.index)
		-- Dont even expect to be able to run CalendarOpenEvent while "CALENDAR_OPEN_EVENT" is running
		CalendarOpenEvent(0, currentEvent.day, currentEvent.index)
	end

	local function parseEvent()
		if currentEvent == nil then
			return
		end
		log("CALENDAR_OPEN_EVENT")
		currentEvent = nil -- Have to reset currentEvent, because CALENDAR_OPEN_EVENT sometimes fires twice...
		local toMod = {}
		if CalendarEventCanEdit() then
			local title, _, _, _, _, _, _, _, month, day, year, hour, minute = CalendarGetEventInfo()
			log("CheckAutoMod: CheckModStatus for event", title, day, month, year, hour, minute)
			local numInvitees = CalendarEventGetNumInvites()
			for inviteeIndex=1,numInvitees do
				local charName, _, _, _, _, modStatus = CalendarEventGetInvite(inviteeIndex)
				if not charName:find("-", 1, true) then
					charName = charName .. "-" .. realmName
				end
				if modStatus == "" and tContains(chars, charName) then
					log("CheckAutoMod: Set Mod", charName, inviteeIndex)
					tinsert(toMod, inviteeIndex)
				end
			end
		end

		self.timers:ScheduleTimer(function() enqueueNextEvent(toMod) end, 1)
	end

	self:RegisterEvent("CALENDAR_OPEN_EVENT", parseEvent)
	enqueueNextEvent()
end

function RCE:scheduleAutoModCheck()
	if self.vars.autoModCheckTimer ~= nil and self.timers:TimeLeft(self.vars.autoModCheckTimer) > 0 then
		return
	end

	self.vars.autoModCheckTimer = self.timers:ScheduleTimer(function() RCE:checkAutoMod() end, 10)
end
