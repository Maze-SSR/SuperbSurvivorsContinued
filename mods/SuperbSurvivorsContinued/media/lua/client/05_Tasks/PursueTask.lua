require "04_Group.SuperSurvivorManager"

PursueTask = {}
PursueTask.__index = PursueTask

local isLocalLoggingEnabled = false;

function PursueTask:new(superSurvivor, target)
	CreateLogLine("PursueTask", isLocalLoggingEnabled, "function: PursueTask:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.parent = superSurvivor
	o.Name = "Pursue"
	o.OnGoing = false
	o.Complete = false
	o.SwitchBackToMele = false

	o.Target = target or superSurvivor.LastEnemeySeen
	if not o.Target then
		o.Complete = true
		return nil
	end

	local ID = o.Target:getModData().ID
	o.TargetSS = SSM:Get(ID)
	if not o.TargetSS then
		o.Complete = true
		return nil
	end

	o.LastSquareSeen = o.Target:getCurrentSquare()
	if o.TargetSS:getBuilding() then
		o.parent.TargetBuilding = o.TargetSS:getBuilding()
	end

	if superSurvivor.LastGunUsed and (superSurvivor:Get():getPrimaryHandItem() ~= superSurvivor.LastGunUsed) then
		o.SwitchBackToMele = true
		o.parent:reEquipGun()
	end

	return o
end

function PursueTask:OnComplete()
	if self.SwitchBackToMele then
		self.parent:reEquipMele()
	end
end

function PursueTask:isComplete()
	if (not self.Target) or self.Target:isDead() or self.parent:HasInjury() or not self.parent:isEnemy(self.Target) then
		return true
	end
	return self.Complete
end

function PursueTask:isValid()
	return self.parent and self.Target ~= nil
end

function PursueTask:update()
	if not self:isValid() or self:isComplete() then return false end

	local player = self.parent.player
	local weapon = player:getPrimaryHandItem()

	-- Handle gun prep
	if self.parent:hasGun() and self.parent:needToReadyGun(weapon) then
		self.parent:setRunning(false)
		self.parent:ReadyGun(weapon)
		self.parent:Wait(3)
		return false
	end

	-- If can't see target
	if not player:CanSee(self.Target) then
		local distToLastSeen = GetDistanceBetween(self.LastSquareSeen, player)
		if distToLastSeen > 1.5 then
			self.parent:setRunning(true)
			self.parent:walkTo(self.LastSquareSeen)
		elseif distToLastSeen <= 1.5 then
			self.parent:setRunning(false)
			self.Complete = true
			self.parent:Speak(Get_SS_Dialogue("WhereHeGo"))
		end
		return
	end

	-- Update if target is visible
	self.LastSquareSeen = self.Target:getCurrentSquare()

	if self.TargetSS and self.TargetSS:getBuilding() then
		self.parent.TargetBuilding = self.TargetSS:getBuilding()
	end

	local distance = GetDistanceBetween(self.Target, player)
	if distance > 1.5 then
		self.parent:setRunning(true)
	else
		self.parent:setRunning(false)
	end

	-- Safely walk to target
	if self.Target:getCurrentSquare() then
		self.parent:walkTo(self.Target:getCurrentSquare())
	end

	self.parent:NPC_EnforceWalkNearMainPlayer()
end
