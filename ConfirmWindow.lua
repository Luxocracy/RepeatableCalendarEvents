
local log = FH3095Debug.log
local RCE = RepeatableCalendarEvents

function RCE:openConfirmWindow()
	local frame = self.gui:Create("Window")
	frame:SetCallback("OnClose",function(widget) CalendarAddEvent(); RCE:scheduleRepeatCheck(); frame:Release() end)
	frame:SetLayout("Fill")
	frame:EnableResize(false)
	frame:SetTitle(self.l.ConfirmWindowName)
	frame:SetWidth(250)
	frame:SetHeight(75)

	local button = self.gui:Create("Button")
	button:SetText(self.l.ConfirmButton)
	button:SetCallback("OnClick", function()
		CalendarAddEvent()
		RCE:scheduleRepeatCheck()
		frame:Release()
	end)
	frame:AddChild(button)

	PlaySound("ReadyCheck")
end
