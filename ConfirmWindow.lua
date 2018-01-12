
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
		RCE.vars.creatingEvent = false
		CalendarAddEvent()
		RCE:scheduleRepeatCheck()
		frame:Release()
	end)
	frame:AddChild(button)

	PlaySound(SOUNDKIT.READY_CHECK)
end

function RCE:openCGIConfirmWindow()
	local frame = self.gui:Create("Window")
	frame:SetCallback("OnClose",function(widget)
		RCE.vars.creatingEvent = false
		frame:Release()
	end)
	frame:SetLayout("List")
	frame:EnableResize(false)
	frame:SetTitle("CGI Confirm Window")
	frame:SetWidth(250)
	frame:SetHeight(150)

	local info = self.gui:Create("MultiLineEditBox")
	info:SetLabel("Inviting Players")
	info:SetHeight(250)
	info:SetWidth(230)
	info:SetDisabled(true)
	info:DisableButton(true)
	frame:AddChild(info)

	local button = self.gui:Create("Button")
	button:SetText(self.l.ConfirmButton)
	button:SetCallback("OnClick", function()
		RCE.vars.creatingEvent = false
		CalendarAddEvent()
		RCE:scheduleRepeatCheck()
		frame:Release()
	end)
	button:SetDisabled(true)
	frame:AddChild(button)

	PlaySound(SOUNDKIT.READY_CHECK)

	return info, button
end
