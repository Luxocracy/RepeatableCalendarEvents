
local log = RepeatableCalendarEventsDebug.log
local RCE = RepeatableCalendarEvents

local function buildRaidOrDungeonDropdownList(cache)
	local ret = {}
	for i=1,#cache do
		ret[i] = cache[i].expansionName .. " - " .. cache[i].title
	end

	return ret
end

local function builDifficultyDropdownList(cache, index)
	local ret = {}
	local difficulties = cache[index].difficulties

	for i=1,#difficulties do
		ret[i] = difficulties[i].name
	end

	return ret
end

local function constructDefaultEvent()
	local ret = {
		name = "",
		title = "",
		desc = "",
		type = 1,
		raidOrDungeon = 1,
		difficulty = 1,
		hour = 0,
		minute = 0,
		day = 1,
		month = 1,
		year = 1999,
		repeatType = 1,
		locked = false,
		guildEvent = false,
		customGuildInvite = false,
		guildInvMinLevel = 1,
		guildInvMaxLevel = RCE.consts.CHAR_MAX_LEVEL,
		guildInvRank = 1,
	}

	return ret
end

function RCE:openEventWindow(eventId)
	local event = nil
	if eventId and self.db.profile.events[eventId] ~= nil then
		event = self.db.profile.events[eventId]
	else
		event = constructDefaultEvent()
	end
	log("OpenEventWindow", eventId, event)

	local frame = self.gui:Create("Window")
	frame:SetCallback("OnClose",function(widget) frame:Release() end)
	frame:SetLayout("Flow")
	frame:EnableResize(true)
	frame:SetTitle(self.l.EventWindowName)
	frame:SetAutoAdjustHeight(true)
	frame:PauseLayout()

	local name = self:evtWndCreateElement(frame, "EditBox", "EventName", event.name)
	name:SetFullWidth(true)
	name:DisableButton(true)

	local title = self:evtWndCreateElement(frame, "EditBox", "EventTitle", event.title)
	title:SetRelativeWidth(0.5)
	title:DisableButton(true)

	local type = self:evtWndCreateElement(frame, "Dropdown", "EventType")
	local types = {
		[1]=self.l["EventTypeRaid"],
		[2]=self.l["EventTypeDungeon"],
		[3]=self.l["EventTypePvP"],
		[4]=self.l["EventTypeMeeting"],
		[5]=self.l["EventTypeOther"],
	}
	type:SetList(types)
	type:SetRelativeWidth(0.5)
	type:SetValue(event.type)

	local raidOrDungeon = self:evtWndCreateElement(frame, "Dropdown", "EventRaidOrDungeon")
	raidOrDungeon:SetRelativeWidth(0.5)
	raidOrDungeon:SetValue(event.raidOrDungeon)

	local difficulty = self:evtWndCreateElement(frame, "Dropdown", "EventDifficulty")
	local difficulties = { "Normal", "Heroic", "Mythic" }
	difficulty:SetList(difficulties)
	difficulty:SetRelativeWidth(0.5)
	difficulty:SetValue(event.difficulty)

	local desc = self:evtWndCreateElement(frame, "MultiLineEditBox", "EventDesc", event.desc)
	desc:SetFullWidth(true)
	desc:DisableButton(true)

	local hour = self:evtWndCreateElement(frame, "Dropdown", "EventHour")
	local hours = {}
	for i=0,23 do
		hours[i] = format("%02u", i)
	end
	hour:SetList(hours)
	hour:SetWidth(100)
	hour:SetValue(event.hour)

	local minute = self:evtWndCreateElement(frame, "Dropdown", "EventMinute")
	local minutes = {}
	for i=0,55,5 do
		minutes[i] = format("%02u", i)
	end
	minute:SetList(minutes)
	minute:SetWidth(100)
	minute:SetValue(event.minute)

	local day = self:evtWndCreateElement(frame, "EditBox", "EventDay", event.day)
	day:SetWidth(100)
	day:DisableButton(true)

	local month = self:evtWndCreateElement(frame, "EditBox", "EventMonth", event.month)
	month:SetWidth(100)
	month:DisableButton(true)

	local year = self:evtWndCreateElement(frame, "EditBox", "EventYear", event.year)
	year:SetWidth(100)
	year:DisableButton(true)

	local repeatType = self:evtWndCreateElement(frame, "Dropdown", "EventRepeatType")
	local repeatTypes = {
		[self.consts.REPEAT_TYPES.WEEKLY] = self.l.EventRepeatWeekly,
		[self.consts.REPEAT_TYPES.MONTHLY] = self.l.EventRepeatMonthly,
		[self.consts.REPEAT_TYPES.YEARLY] = self.l.EventRepeatYearly,
	}
	repeatType:SetList(repeatTypes)
	repeatType:SetWidth(100)
	repeatType:SetValue(event.repeatType)

	local locked = self:evtWndCreateElement(frame, "CheckBox", "EventLocked", event.locked)

	local guildEvent = self:evtWndCreateElement(frame, "CheckBox", "EventTypeGuild", event.guildEvent)

	local customGuildInvite = self:evtWndCreateElement(frame, "CheckBox", "EventCustomGuildInvite", event.customGuildInvite)

	local guildInvMinLevel = self:evtWndCreateElement(frame, "Slider", "EventGuildInvMinLevel", event.guildInvMinLevel)
	guildInvMinLevel:SetSliderValues(1, self.consts.CHAR_MAX_LEVEL, 1)

	local guildInvMaxLevel = self:evtWndCreateElement(frame, "Slider", "EventGuildInvMaxLevel", event.guildInvMaxLevel)
	guildInvMaxLevel:SetSliderValues(1, self.consts.CHAR_MAX_LEVEL, 1)

	local guildInvRank = self:evtWndCreateElement(frame, "Slider", "EventGuildInvRank", event.guildInvRank)
	guildInvRank:SetSliderValues(1, IsInGuild() and GuildControlGetNumRanks() or 1, 1)

	local saveButton = self:evtWndCreateElement(frame, "Button", "SaveEventButton")
	saveButton:SetFullWidth(true)
	saveButton:SetCallback("OnClick", function()
		if RCE:evtWndSave(frame, eventId) then
			frame:Release()
			RCE:openEventsListWindow()
		end
	end)

	frame:ResumeLayout()
	frame:DoLayout()

	self:evtWndRegisterForChangeToCheckOtherFields(frame, type, "Dropdown")
	self:evtWndRegisterForChangeToCheckOtherFields(frame, raidOrDungeon, "Dropdown")
	self:evtWndRegisterForChangeToCheckOtherFields(frame, guildEvent, "CheckBox")
	self:evtWndRegisterForChangeToCheckOtherFields(frame, customGuildInvite, "CheckBox")
	self:evtWndCheckFields(frame)
end

function RCE:evtWndCreateElement(frame, type, name, value)
	local checkValue = function()
		if value == nil then
			error("Value for element " .. name .. " of type " .. type .. " must not be nil")
		end
	end

	local element = self.gui:Create(type)
	if element.SetLabel ~= nil then
		element:SetLabel(self.l[name])
	elseif type == "Button" then
		element:SetText(self.l[name])
	else
		error("Unknown SetLabel method for window element " .. name .. " of type " .. type)
	end

	if type == "EditBox" or type == "MultiLineEditBox" then
		checkValue()
		element:SetText(value)
	elseif type == "CheckBox" or type =="Slider" then
		checkValue()
		element:SetValue(value)
	elseif type == "Button" or type == "Dropdown" then
	-- Do nothing for buttons and cant set for dropdowns before options are set
	else
		error("Cant handle value for element " .. name .. " of type " .. type)
	end

	frame:AddChild(element)

	local childs = frame:GetUserData("Childs")
	if childs == nil then
		frame:SetUserData("Childs", {})
		childs = frame:GetUserData("Childs")
	end
	childs[name] = element

	return element
end

function RCE:evtWndCheckFields(frame)
	local childs = frame:GetUserData("Childs")
	if childs.EventType:GetValue() == self.consts.EVENT_TYPES.RAID or childs.EventType:GetValue() == self.consts.EVENT_TYPES.DUNGEON then
		childs.EventRaidOrDungeon:SetDisabled(false)
		childs.EventDifficulty:SetDisabled(false)

		local cache = self:getCacheForEventType(childs.EventType:GetValue())
		local oldValue = childs.EventRaidOrDungeon:GetValue()
		childs.EventRaidOrDungeon:SetList(buildRaidOrDungeonDropdownList(cache))
		childs.EventRaidOrDungeon:SetValue(oldValue)
		oldValue = childs.EventDifficulty:GetValue()
		childs.EventDifficulty:SetList(builDifficultyDropdownList(cache, childs.EventRaidOrDungeon:GetValue()))
		childs.EventDifficulty:SetValue(oldValue)
	else
		childs.EventRaidOrDungeon:SetDisabled(true)
		childs.EventDifficulty:SetDisabled(true)
	end

	if IsInGuild() then
		childs.EventTypeGuild:SetDisabled(false)
	else
		childs.EventTypeGuild:SetDisabled(true)
	end

	if not childs.EventTypeGuild:GetValue() and IsInGuild() then
		childs.EventCustomGuildInvite:SetDisabled(false)
	else
		childs.EventCustomGuildInvite:SetDisabled(true)
	end

	if childs.EventCustomGuildInvite:GetValue() and not childs.EventTypeGuild:GetValue() and IsInGuild() then
		childs.EventGuildInvMinLevel:SetDisabled(false)
		childs.EventGuildInvMaxLevel:SetDisabled(false)
		childs.EventGuildInvRank:SetDisabled(false)
	else
		childs.EventGuildInvMinLevel:SetDisabled(true)
		childs.EventGuildInvMaxLevel:SetDisabled(true)
		childs.EventGuildInvRank:SetDisabled(true)
	end

	frame:DoLayout()
end

function RCE:evtWndRegisterForChangeToCheckOtherFields(frame, element, type)
	local callCheckFunction = function()
		RCE:evtWndCheckFields(frame)
	end

	if type == "CheckBox" or type == "Dropdown" then
		element:SetCallback("OnValueChanged", callCheckFunction)
	else
		error("Unknown type to check for changes: " .. type)
	end
end

function RCE:evtWndSave(frame, eventId)
	log("EvtWndSave", eventId)
	local childs = frame:GetUserData("Childs")
	local event = {}

	event.name = childs.EventName:GetText()
	event.title = childs.EventTitle:GetText()
	event.desc = childs.EventDesc:GetText()
	event.type = childs.EventType:GetValue()
	event.raidOrDungeon = childs.EventRaidOrDungeon:GetValue()
	event.difficulty = childs.EventDifficulty:GetValue()
	event.hour = tonumber(childs.EventHour:GetValue())
	event.minute = tonumber(childs.EventMinute:GetValue())
	event.day = tonumber(childs.EventDay:GetText())
	event.month = tonumber(childs.EventMonth:GetText())
	event.year = tonumber(childs.EventYear:GetText())
	event.repeatType = tonumber(childs.EventRepeatType:GetValue())
	event.locked = childs.EventLocked:GetValue() and true or false
	event.guildEvent = childs.EventTypeGuild:GetValue() and true or false
	event.customGuildInvite = childs.EventCustomGuildInvite:GetValue() and true or false
	event.guildInvMinLevel = tonumber(childs.EventGuildInvMinLevel:GetValue())
	event.guildInvMaxLevel = tonumber(childs.EventGuildInvMaxLevel:GetValue())
	event.guildInvRank = tonumber(childs.EventGuildInvRank:GetValue())

	if not self:validateEvent(event) then
		return false
	end

	log("EvtWndSave Saving: ", eventId, event)
	if eventId and self.db.profile.events[eventId] ~= nil then
		self.db.profile.events[eventId] = event
	else
		tinsert(self.db.profile.events, event)
	end

	local sortFunc = function(evt1, evt2)
		if evt1 == nil then
			return false
		elseif evt2 == nil then
			return true
		else
			return strcmputf8i(tostring(evt1.name),tostring(evt2.name)) < 0
		end
	end
	sort(self.db.profile.events, sortFunc)
	self:scheduleRepeatCheck(1)
	return true
end
