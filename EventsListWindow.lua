
local log = RepeatableCalendarEventsDebug.log
local RCE = RepeatableCalendarEvents

function RCE:openEventsListWindow()
	log("openEventsListWindow")
	local L = self.l

	local frame = self.gui:Create("Window")
	frame:SetCallback("OnClose",function(widget) frame:Release() end)
	frame:SetLayout("Fill")
	frame:EnableResize(true)
	frame:SetTitle(L.EventListWindowName)

	local scroll = self.gui:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	frame:AddChild(scroll)
	scroll:PauseLayout()


	local events = self.db.profile.events;
	for key,event in pairs(events) do
		local editButton = self.gui:Create("Button")
		editButton:SetText(event.name)
		editButton:SetRelativeWidth(0.8)
		editButton:SetCallback("OnClick", function() RCE:openEventWindow(key); frame:Release() end)
		scroll:AddChild(editButton)
		local deleteButton = self.gui:Create("Button")
		deleteButton:SetRelativeWidth(0.199)
		deleteButton:SetText(L.DeleteButtonText)
		deleteButton:SetCallback("OnClick", function() RCE.db.profile.events[key] = nil; frame:Release(); RCE:openEventsListWindow() end)
		scroll:AddChild(deleteButton)
	end

	local newButton = self.gui:Create("Button")
	newButton:SetText(L.NewEventButton)
	newButton:SetFullWidth(true)
	newButton:SetCallback("OnClick", function() RCE:openEventWindow(nil); frame:Release() end)
	scroll:AddChild(newButton)

	scroll:ResumeLayout()
	scroll:DoLayout()
end
