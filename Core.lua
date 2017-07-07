
local ADDON_NAME = "RepeatableCalendarEvents"
local VERSION = "@project-version@"
local log = RepeatableCalendarEventsDebug.log
local RCE = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
RepeatableCalendarEvents = RCE

RCE.consts = {}
RCE.consts.ADDON_NAME = ADDON_NAME
RCE.consts.VERSION = VERSION

function RCE:OnInitialize()
	self.vars = {}
	self.l = LibStub("AceLocale-3.0"):GetLocale("RollBot", false)
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
end
