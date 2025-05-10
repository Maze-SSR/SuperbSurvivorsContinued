ReturnToBaseTask = {}
ReturnToBaseTask.__index = ReturnToBaseTask

local isLocalLoggingEnabled = false

function ReturnToBaseTask:new(superSurvivor)
    CreateLogLine("ReturnToBase", isLocalLoggingEnabled, "ReturnToBaseTask:new() called")
    
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.parent = superSurvivor
    o.Name = "Return To Base"
    o.OnGoing = false
    o.GroupID = superSurvivor:getGroupID()

    if (not o.GroupID) then
        CreateLogLine("ReturnToBase", isLocalLoggingEnabled, "No group ID")
        return nil
    end

    o.Group = SSGM:GetGroupById(o.GroupID)
    if o.Group then
        o.BaseCoords = o.Group:getBaseCenterCoords()
    else
        CreateLogLine("ReturnToBase", isLocalLoggingEnabled, "Group not found for ID: " .. tostring(o.GroupID))
    end

    return o
end

function ReturnToBaseTask:isComplete()
    if (not self:isValid()) then return true end

    if (self.parent:isInBase()) then return true end

    if (not self.BaseCoords or not self.BaseCoords[1] or not self.BaseCoords[2] or not self.BaseCoords[3]) then
        CreateLogLine("ReturnToBase", isLocalLoggingEnabled, "Base coordinates missing or incomplete")
        return true
    end

    return false
end

function ReturnToBaseTask:isValid()
    return self.parent ~= nil and self.parent:getGroupID() ~= nil and self.BaseCoords ~= nil
end

function ReturnToBaseTask:update()
    if (not self:isValid()) then return false end
    if (self.parent:isInAction()) then return false end

    local x, y, z = self.BaseCoords[1], self.BaseCoords[2], self.BaseCoords[3]
    local baseSquare = getCell():getGridSquare(x, y, z)

    if baseSquare then
        self.parent:walkTo(baseSquare)
    else
        local cs = self.parent:Get():getCurrentSquare()
        if (not cs or not cs:IsOnScreen()) then
            CreateLogLine("ReturnToBase", isLocalLoggingEnabled, "Teleport fallback to base")
            self.parent.player:setX(x)
            self.parent.player:setY(y)
            self.parent.player:setZ(z)
        else
            self.parent:walkTowards(x, y, z)
        end
    end
end
