
local log = FH3095Debug.log
local RCE = RepeatableCalendarEvents

function RCE:increaseDate(repeatType, dateTable)
	if repeatType == self.consts.REPEAT_TYPES.WEEKLY then
		dateTable.day = dateTable.day + 7
	elseif repeatType == self.consts.REPEAT_TYPES.WEEKLY2 then
		dateTable.day = dateTable.day + 14
	elseif repeatType == self.consts.REPEAT_TYPES.WEEKLY3 then
		dateTable.day = dateTable.day + 21
	elseif repeatType == self.consts.REPEAT_TYPES.WEEKLY4 then
		dateTable.day = dateTable.day + 28
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

function RCE:createWoWEvent(event)
	self.vars.creatingEvent = true
	CalendarCloseEvent()
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
		-- CalendarMassInviteGuild(event.guildInvMinLevel, event.guildInvMaxLevel, event.guildInvRank)
		local info, button = RCE:openCGIConfirmWindow()
		local invIndex = 1
		RCE:RegisterEvent("CALENDAR_UPDATE_INVITE_LIST", function()
			invIndex = invIndex+1
			if event.guildInvList[invIndex] then
				C_Timer.After(2, function()
					if not RCE.vars.creatingEvent then
						CalendarCloseEvent()
						return
					end
					
					local name = tostring(event.guildInvList[invIndex])
					local currentText = info:GetText()
					info:SetText(name.."\n"..currentText)
					CalendarEventInvite(name)
				end)
			else
				RCE:UnregisterEvent("CALENDAR_UPDATE_INVITE_LIST")
				RCE:UnregisterEvent("CALENDAR_UPDATE_ERROR")
				button:SetDisabled(false)
				-- RCE:openConfirmWindow()
			end
		end)
		RCE:RegisterEvent("CALENDAR_UPDATE_ERROR", function()
			if event.guildInvList[invIndex] then
				RCE:printError("Error when inviting player")
				-- CalendarEventInvite(tostring(event.guildInvList[invIndex]))
			end
		end)
		CalendarEventInvite(tostring(event.guildInvList[invIndex]))
	end

	local cache = self:getCacheForEventType(event.type)
	if cache ~= nil then
		local textureId = cache[event.raidOrDungeon].difficulties[event.difficulty].index
		CalendarEventSetTextureID(textureId)
	end
	if not event.customGuildInvite then
		RCE:openConfirmWindow()
	end
end

function RCE:repeatEvent()
	log("RepeatEvent")

	if self.vars.creatingEvent then
		-- RCE:printError("Currently creating an event, aborting")
		return
	end

	local currentTime = time()
	local maxCreateTime = time() + self.db.profile.eventsInFuture * 86400
	for key,event in pairs(self.db.profile.events) do
		local dateTable = self:timeTableFromEvent(event)
		local eventTime = time(dateTable)
		log("RepeatEvent Check", event.name, date("%c", eventTime))

		while eventTime < currentTime do
			-- increase eventTime until it reaches today
			self:increaseDate(event.repeatType, dateTable)
			eventTime = time(dateTable)
		end

		while eventTime < maxCreateTime do
			log("RepeatEvent CheckFor", event.name, date("%c", eventTime))
			dateTable = self:normalizeDateTable(dateTable)
			self:setCalendarMonthToDate(dateTable)

			-- Loop through events of that day to see if event already exists
			local numEvents = CalendarGetNumDayEvents(0, dateTable.day)
			local foundEvent = false
			for i=1,numEvents do
				local title,_,_,calendarType = CalendarGetDayEvent(0, dateTable.day, i)
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
				-- self:openConfirmWindow()
				return
			end

			-- increase date for next check round
			self:increaseDate(event.repeatType, dateTable)
			eventTime = time(dateTable)
		end
		-- Finally save the dateTable to the event, so that the next checks ignore already created events
		dateTableToEvent(dateTable, event)
		log("RepeatEvent NextDate", event.name, date("%c", eventTime))
	end
	self:scheduleAutoModCheck()
end
