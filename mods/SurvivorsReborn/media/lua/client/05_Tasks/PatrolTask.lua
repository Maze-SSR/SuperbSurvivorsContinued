PatrolTask = {}
PatrolTask.__index = PatrolTask

local isLocalLoggingEnabled = false;

function PatrolTask:new(superSurvivor, square1, square2)
	CreateLogLine("PatrolTask", isLocalLoggingEnabled, "function: PatrolTask:new() called");

	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.parent = superSurvivor
	o.Name = "Patrol"
	o.OnGoing = true
	o.Complete = false
	o.Ticks = 0
	o.CurrentTarget = 1 -- 1 for square1, 2 for square2

	-- Fallback to last saved patrol coords or current square
	o.Square1 = square1 or getCell():getGridSquare(
		superSurvivor.player:getModData().PX or superSurvivor.player:getX(),
		superSurvivor.player:getModData().PY or superSurvivor.player:getY(),
		superSurvivor.player:getModData().PZ or superSurvivor.player:getZ()
	)

	o.Square2 = square2 or getCell():getGridSquare(
		superSurvivor.player:getModData().P2X or superSurvivor.player:getX() + 5,
		superSurvivor.player:getModData().P2Y or superSurvivor.player:getY() + 5,
		superSurvivor.player:getModData().P2Z or superSurvivor.player:getZ()
	)

	if (not o.Square1 or not o.Square2) then
		CreateLogLine("PatrolTask", isLocalLoggingEnabled, "Invalid patrol squares. Cancelling task.")
		o.Complete = true
	end

	-- Save to modData
	superSurvivor.player:getModData().PX = o.Square1:getX()
	superSurvivor.player:getModData().PY = o.Square1:getY()
	superSurvivor.player:getModData().PZ = o.Square1:getZ()
	superSurvivor.player:getModData().P2X = o.Square2:getX()
	superSurvivor.player:getModData().P2Y = o.Square2:getY()
	superSurvivor.player:getModData().P2Z = o.Square2:getZ()

	return o
end

function PatrolTask:isComplete()
	return self.Complete
end

function PatrolTask:isValid()
	return self.parent and self.Square1 and self.Square2
end

function PatrolTask:getNextTargetSquare()
	if self.CurrentTarget == 1 then
		return self.Square1
	else
		return self.Square2
	end
end

function PatrolTask:update()
	if not self:isValid() then return false end
	if self.parent:isInAction() then return false end
	if self.parent:getDangerSeenCount() > 0 then return false end

	local targetSquare = self:getNextTargetSquare()
	local distance = GetDistanceBetween(self.parent:Get(), targetSquare)

	if distance > 2.0 then
		self.parent:walkToDirect(targetSquare)
	else
		-- Switch to the other square after reaching
		self.CurrentTarget = (self.CurrentTarget == 1) and 2 or 1
	end

	self.Ticks = self.Ticks + 1
	if self.Ticks >= 100 then
		-- Reaffirm patrol behavior every 100 ticks
		if self.parent:isSpeaking() == false then
			self.parent:RoleplaySpeak(Get_SS_Dialogue("HeadingBackToPost"))
		end
		self.Ticks = 0
	end
end
