
local log = RepeatableCalendarEventsDebug.log
local RCE = RepeatableCalendarEvents

function RCE:createOptions()
	local optionsTable = {
		name = self.consts.ADDON_NAME,
		type = "group",
		args = {
			basic = {
				handler = self,
				name = "Basic",
				type = "group",
				set = "SetBasicOption",
				get = "GetBasicOption",
				args = {
					eventsInFuture = {
						type	= "range",
						name	= self.l.EventsInFutureName,
						desc	= self.l.eventsInFutureDesc,
						min		= 1,
						max		= 365,
						softMax	= 32,
						step	= 1,
					},
				}
			},
			profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db),
		}
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable(self.consts.ADDON_NAME, optionsTable)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.consts.ADDON_NAME)
end


function RCE:SetBasicOption(info, value)
	log("Set option", info[#info], value)
	self.db.profile[info[#info]] = value
end

function RCE:GetBasicOption(info)
	return self.db.profile[info[#info]]
end
