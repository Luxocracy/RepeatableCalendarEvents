
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
RCE.consts.ADDON_NAME_COLORED = RCE.consts.COLORS.HIGHLIGHT .. RCE.consts.ADDON_NAME .. "|r"


function RCE:OnInitialize()
	self.vars = {}
	self.l = LibStub("AceLocale-3.0"):GetLocale("RepeatableCalendarEvents", false)
	self.timers = LibStub("AceTimer-3.0")
	self.gui = LibStub("AceGUI-3.0")

	local defaultDb = { profile = { events = {}}}
	self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", defaultDb, true)
	local optionsTable = { name = self.consts.ADDON_NAME, type = "group", args = { profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }}
	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, optionsTable)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)

	self.events = LibStub("AceEvent-3.0")

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
	return true
end
