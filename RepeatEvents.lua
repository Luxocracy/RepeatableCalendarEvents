
local log = RepeatableCalendarEventsDebug.log
local RCE = RepeatableCalendarEvents

function RCE:increaseDate(repeatType, dateTable)
	if repeatType == self.consts.REPEAT_TYPES.WEEKLY then
		dateTable.day = dateTable.day + 7
	elseif repeatType == self.consts.REPEAT_TYPES.MONTHLY then
		dateTable.month = dateTable.month + 1
	elseif repeatType == self.consts.REPEAT_TYPES.YEARLY then
		dateTable.year = dateTable.year + 1
	else
		error("Unknown repeattype " .. repeatType)
	end
end

local function dateTableToEvent(dateTable, event)
	dateTable = date("*t", time(dateTable))
	event.year = dateTable.year
	event.month = dateTable.month
	event.day = dateTable.day
	event.hour = dateTable.hour
	event.minute = dateTable.min
end

local function normalizeDateTable(dateTable)
	dateTable = date("*t", time(dateTable))
	local ret = {}
	ret.year = dateTable.year
	ret.month = dateTable.month
	ret.day = dateTable.day
	ret.hour = dateTable.hour
	ret.min = dateTable.min

	return ret
end

function RCE:createWoWEvent(event)
	if event.guildEvent and IsInGuild() then
		CalendarNewGuildEvent()
	else
		CalendarNewEvent()
	end
	CalendarEventSetTitle(event.title)
	CalendarEventSetDescription(event.desc)
	CalendarEventSetType(event.type)
	CalendarEventSetTime(event.hour, event.minute)
	CalendarEventSetDate(event.month, event.day, event.year)
	if event.locked then
		CalendarEventSetLocked()
	end
	if not event.guildEvent and event.customGuildInvite and IsInGuild() then
		CalendarMassInviteGuild(event.guildInvMinLevel, event.guildInvMaxLevel, event.guildInvRank)
	end

	local cache = self:getCacheForEventType(event.type)
	local textureId = cache[event.raidOrDungeon].difficulties[event.difficulty].index
	CalendarEventSetTextureID(textureId)
end

function RCE:repeatEvent()
	log("RepeatEvent")

	local currentTime = time()
	local maxCreateTime = time() + self.db.profile.eventsInFuture * 86400
	local currentMonth, currentYear = CalendarGetMonth(0)
	for key,event in pairs(self.db.profile.events) do
		local dateTable = self:timeTableFromEvent(event)
		local eventTime = time(dateTable)
		log("RepeatEvent Check", event.name, date("%c", eventTime), event)

		while eventTime < currentTime do
			-- increase eventTime until it reaches today
			self:increaseDate(event.repeatType, dateTable)
			eventTime = time(dateTable)
		end

		while eventTime < maxCreateTime do
			log("RepeatEvent CheckFor", event.name, date("%c", eventTime))
			dateTable = normalizeDateTable(dateTable)
			local monthOffset = dateTable.month - currentMonth + (dateTable.year - currentYear) * 12
			assert(monthOffset >= 0, "MonthOffset " .. monthOffset)
			CalendarSetMonth(monthOffset)

			-- Loop through events of that day to see if event already exists
			local numEvents = CalendarGetNumDayEvents(monthOffset, dateTable.day)
			local foundEvent = false
			for i=1,numEvents do
				local title,_,_,calendarType = CalendarGetDayEvent(monthOffset, dateTable.day, i)
				if (calendarType == "GUILD_EVENT" or calendarType == "PLAYER") and title == event.title then
					log("RepeatEvent Found", event.name, date("%c", eventTime))
					foundEvent = true
					break
				end
			end

			-- Create event if not found
			if not foundEvent then
				-- First write date from DateTable to the event
				dateTableToEvent(dateTable, event)
				log("RepeatEvent Create", event.name, date("%c", eventTime), event)
				self:createWoWEvent(event)
				self:openConfirmWindow()
				return
			end

			-- increase date for next check round
			self:increaseDate(event.repeatType, dateTable)
			eventTime = time(dateTable)
		end
		-- Finally save the dateTable to the event, so that the next checks ignore already created events
		dateTableToEvent(dateTable, event)
		log("RepeatEvent NextDate", event.name, date("%c", eventTime), event)
	end
	CalendarSetMonth(0)
	self.console:Printf("%s: %s", self.consts.ADDON_NAME_COLORED, self.l.CalendarUpdateFinished)
end
