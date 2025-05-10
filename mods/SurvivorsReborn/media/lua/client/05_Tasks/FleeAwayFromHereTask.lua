FleeFromHereTask = {}
FleeFromHereTask.__index = FleeFromHereTask

local isLocalLoggingEnabled = false;

function FleeFromHereTask:new(superSurvivor, fleeFromHere)
	CreateLogLine("FleeFromHereTask", isLocalLoggingEnabled, "function: FleeFromHereTask:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	superSurvivor:setRunning(true)
	o.parent = superSurvivor
	o.Name = "Flee From Spot"
	o.OnGoing = false
	o.fleeFromHere = fleeFromHere
	o.FleeTicks = 0
	o.MaxFleeTicks = 300 -- safety limit (~5 seconds)

	if o.parent.TargetBuilding ~= nil then
		o.parent:MarkAttemptedBuildingExplored(o.parent.TargetBuilding)
	end

	-- Status update for UI/debug
	o.parent.player:getModData().Status = "Fleeing"

	return o
end

function FleeFromHereTask:isComplete()
	if GetDistanceBetween(self.parent.player, self.fleeFromHere) > PanicDistance then
		self.parent:StopWalk()
		self.parent:setRunning(false)
		self.parent.player:getModData().Status = "Idle"
		return true
	end
	return false
end

function FleeFromHereTask:isValid()
	if not self.parent or self:isComplete() then
		return false
	else
		return true
	end
end

function FleeFromHereTask:update()
	if (not self:isValid()) then return false end

	self.parent:setSneaking(false)
	self.parent:setRunning(true)

	self.FleeTicks = self.FleeTicks + 1
	if (self.FleeTicks > self.MaxFleeTicks) then
		CreateLogLine("FleeFromHereTask", isLocalLoggingEnabled, "Flee timeout reached, aborting...");
		self.parent:Speak("I can't flee any further!")
		self.parent:setRunning(false)
		self.Complete = true
		self.parent.player:getModData().Status = "Idle"
		return false
	end

	local fleeSquare = GetFleeSquare(self.parent.player, self.fleeFromHere, 7)
	if fleeSquare then
		self.parent:walkTo(fleeSquare)
	else
		CreateLogLine("FleeFromHereTask", isLocalLoggingEnabled, "No valid flee square found.");
		self.parent:Speak("Nowhere to run!")
		self.Complete = true
		self.parent.player:getModData().Status = "Idle"
	end

	self.parent:NPC_EnforceWalkNearMainPlayer()
end
