FleeTask = {}
FleeTask.__index = FleeTask

local isLocalLoggingEnabled = false;

function FleeTask:new(superSurvivor)
    CreateLogLine("FleeTask", isLocalLoggingEnabled, "function: FleeTask:new() called");
    local o = {}
    setmetatable(o, self)
    self.__index = self

    superSurvivor:setRunning(true)
    o.parent = superSurvivor
    o.Name = "Flee"
    o.OnGoing = false

    if o.parent.TargetBuilding ~= nil then
        o.parent:MarkAttemptedBuildingExplored(o.parent.TargetBuilding)
    end

    return o
end

function FleeTask:isComplete()
    if (self.parent:getDangerSeenCount() == 0) or self.parent:needToFollow() then
        self.parent:StopWalk()
        self.parent:setRunning(false)
        return true
    else
        return false
    end
end

function FleeTask:isValid()
    if not self.parent or self:isComplete() then
        return false
    end
    return true
end

function FleeTask:update()
    if not self:isValid() then return false end

    self.parent:setRunning(true)
    self.parent:setSneaking(false)

    local player = self.parent.player
    local threat = self.parent.LastEnemeySeen

    local fleeSquare
    if threat then
        fleeSquare = GetFleeSquare(player, threat, 7)
    else
        -- fallback to fleeing from current square if threat is nil
        fleeSquare = GetFleeSquare(player, player:getCurrentSquare(), 7)
    end

    if fleeSquare ~= nil then
        self.parent:walkTo(fleeSquare)
        self.parent:NPC_EnforceWalkNearMainPlayer()
    else
        CreateLogLine("FleeTask", isLocalLoggingEnabled, "No flee square found. Resetting survivor.")
        self.parent:StopWalk()
        self.parent:setRunning(false)
        self.parent:getTaskManager():clear()
        self.parent:getTaskManager():AddToTop(FollowTask:new(self.parent, getSpecificPlayer(0))) -- fallback: follow player
        return false
    end
end
