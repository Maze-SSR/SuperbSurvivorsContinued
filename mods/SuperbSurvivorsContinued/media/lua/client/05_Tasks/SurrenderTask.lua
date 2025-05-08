SurrenderTask = {}
SurrenderTask.__index = SurrenderTask

local isLocalLoggingEnabled = false;

function SurrenderTask:new(superSurvivor, enemy)
    CreateLogLine("SurrenderTask", isLocalLoggingEnabled, "function: SurrenderTask:new() called")
    
    local o = setmetatable({}, self)

    superSurvivor:StopWalk()

    o.parent = superSurvivor
    o.Name = "Surrender"
    o.OnGoing = true
    o.HasDroppedItems = false
    o.enemy = enemy
    o.DangerTicks = 0
    o.NowSafeTicks = 0
    o.TaskTicks = 0

    return o
end

function SurrenderTask:isComplete()
    -- Ensure surrender animation visibly starts (TaskTicks > 3)
    if self.TaskTicks < 3 then
        return false
    end

    if not self.enemy or not self.enemy.player or self.enemy.player:isDead() then
        return true -- End surrender if enemy is invalid or dead
    end

    local survivorPlayer = self.parent.player
    local enemyPlayer = self.enemy.player

    if not survivorPlayer or survivorPlayer:isDead() then
        return true -- Task ends if surrendering survivor is invalid or dead
    end

    local enemyFacingResult = enemyPlayer:getDotWithForwardDirection(survivorPlayer:getX(), survivorPlayer:getY())
    local enemyHasWeaponThreat = self.enemy.player:isAiming() and self.enemy:usingGun()
    local enemyVisible = enemyPlayer:CanSee(survivorPlayer)
    local survivorCanSeeEnemy = self.parent:RealCanSee(self.enemy)
    local distance = GetDistanceBetween(survivorPlayer, enemyPlayer)

    -- Evaluate if survivor should continue surrendering
    local shouldContinueSurrendering = enemyHasWeaponThreat
        and enemyVisible
        and enemyFacingResult > 0.95
        and (distance < 6 or (not survivorCanSeeEnemy and distance <= 3))
        and (self.parent:isEnemy(enemyPlayer)
            or (not self.parent:isInGroup(enemyPlayer)
                and enemyPlayer:isLocalPlayer()
                and IsoPlayer.getCoopPVP()))
        and (self.NowSafeTicks < 12)

    -- If no longer threatened, surrender is complete
    return not shouldContinueSurrendering
end

function SurrenderTask:isValid()
    return self.parent ~= nil and not self.parent:isDead()
end

function SurrenderTask:update()
    if not self:isValid() then return end

    self.TaskTicks = self.TaskTicks + 1

    local survivorPlayer = self.parent.player
    local enemyPlayer = self.enemy and self.enemy.player

    if enemyPlayer and enemyPlayer:isAiming() and self.enemy:usingGun()
       and (self.parent:isEnemy(enemyPlayer)
            or (enemyPlayer:isLocalPlayer() and IsoPlayer.getCoopPVP()))
       and GetDistanceBetween(survivorPlayer, enemyPlayer) < 6
    then
        self.DangerTicks = self.DangerTicks + 1
        self.NowSafeTicks = 0
    else
        self.NowSafeTicks = self.NowSafeTicks + 1
        self.DangerTicks = 0
    end

    if not self.HasDroppedItems then
        self:DropItems()
    end

    if not self.parent:isInAction() then
        local surrenderAction = ISSurenderAction:new(survivorPlayer, enemyPlayer)
        ISTimedActionQueue.add(surrenderAction)
    end
end

function SurrenderTask:DropItems()
    local survivorInventory = self.parent.player:getInventory()

    -- Drop equipped items in both hands
    survivorInventory:dropHandItems()

    self.HasDroppedItems = true
    CreateLogLine("SurrenderTask", isLocalLoggingEnabled, "Survivor dropped equipped items due to surrender")
end
