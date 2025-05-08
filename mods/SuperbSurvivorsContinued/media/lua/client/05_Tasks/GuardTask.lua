GuardTask = {}
GuardTask.__index = GuardTask

local isLocalLoggingEnabled = false

function GuardTask:new(superSurvivor, square)
	CreateLogLine("GuardTask", isLocalLoggingEnabled, "function: GuardTask:new() called")
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.Square = square
	o.parent = superSurvivor
	o.Name = "Guard"
	o.OnGoing = true
	o.Ticks = 0
	o.LastDistance = 0
	o.LeashDistance = 2.5 -- maximum allowed distance from post before returning

	return o
end

function GuardTask:isComplete()
	return false -- guard tasks are considered ongoing unless cancelled externally
end

function GuardTask:isValid()
	return self.parent ~= nil and self.Square ~= nil
end

function GuardTask:update()
	if not self:isValid() then return false end

	local player = self.parent.player
	if self.parent:isInAction() then return end

	local distance = GetDistanceBetween(player, self.Square)

	-- Only return to post if outside leash range
	if distance > self.LeashDistance then
		CreateLogLine("GuardTask", isLocalLoggingEnabled, "Returning to guard post (wandered too far)")
		self.parent:walkToDirect(self.Square)
		self.parent:RoleplaySpeak(Get_SS_UIActionText("ReturningToPost"))
	else
		-- Idle re-enforcement every X ticks to reset walk animation or stop wander
		self.Ticks = self.Ticks + 1
		if self.Ticks > 300 then -- roughly 5 seconds if 60 ticks/sec
			self.Ticks = 0
			if player:getCurrentSquare() ~= self.Square then
				CreateLogLine("GuardTask", isLocalLoggingEnabled, "Re-centering to guard square")
				self.parent:walkToDirect(self.Square)
			end
		end
	end
end
