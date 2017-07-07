
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
	frame:PauseLayout()

	local scroll = self.gui:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	frame:AddChild(scroll)


	local events = self.db.profile.events;
	for key,event in pairs(events) do
		local label = self.gui:Create("Label")
		label:SetRelativeWidth(0.9)
		label:SetText(event.name)
		scroll:AddChild(label)
		local button = self.gui:Create("Button")
		button:SetText(L.EditButtonText)
		button:SetRelativeWidth(0.1)
		button:SetCallback("OnClick", function() RCE:openEventWindow(key); frame:Release() end)
		scroll:AddChild(button)
	end

	local newButton = self.gui:Create("Button")
	newButton:SetText(L.NewEventButton)
	newButton:SetFullWidth(true)
	newButton:SetCallback("OnClick", function() RCE:openEventWindow(nil); frame:Release() end)
	scroll:AddChild(newButton)

	frame:ResumeLayout()
	frame:DoLayout()
end
