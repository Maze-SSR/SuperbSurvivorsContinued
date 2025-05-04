SuperSurvivorManager = {}
SuperSurvivorManager.__index = SuperSurvivorManager

local isLocalLoggingEnabled = false

function SuperSurvivorManager:new()
    CreateLogLine("SuperSurvivorManager", isLocalLoggingEnabled, "SuperSurvivorManager:new() called")
    local o = setmetatable({
        SuperSurvivors = {},
        SurvivorCount = 3,
        MainPlayer = 0
    }, self)
    return o
end

function SuperSurvivorManager:getRealPlayerID()
    return self.MainPlayer
end

function SuperSurvivorManager:init()
    self.SuperSurvivors[0] = SuperSurvivor:newSet(getSpecificPlayer(0))
    self.SuperSurvivors[0]:setID(0)
end

function SuperSurvivorManager:setPlayer(player, ID)
    self.SuperSurvivors[ID] = SuperSurvivor:newSet(player)
    self.SuperSurvivors[ID]:setID(ID)
    self.SuperSurvivors[ID]:setName("Player " .. tostring(ID))
    return self.SuperSurvivors[ID]
end

function SuperSurvivorManager:LoadSurvivor(ID, square)
    if not ID or not square or not checkSaveFileExists("Survivor" .. tostring(ID)) then return false end

    if self.SuperSurvivors[ID] and self.SuperSurvivors[ID].player then
        if self.SuperSurvivors[ID]:isInCell() then return false end
        self.SuperSurvivors[ID]:deleteSurvivor()
    end

    local survivor = SuperSurvivor:newLoad(ID, square)
    self.SuperSurvivors[ID] = survivor

    local player = survivor:Get()
    if not player:getPrimaryHandItem() and survivor:getWeapon() then
        player:setPrimaryHandItem(survivor:getWeapon())
    end

    survivor:refreshName()
    survivor:setHostile(player:getModData().isHostile == true)

    self.SurvivorCount = math.max(self.SurvivorCount or 1, ID)

    player:getModData().LastSquareSaveX = nil
    survivor:SaveSurvivor()

    survivor.LastMeleUsed = survivor.player:getInventory():FindAndReturn(survivor.player:getModData().meleWeapon)
        or survivor:getBag():FindAndReturn(survivor.player:getModData().meleWeapon)

    survivor.LastGunUsed = survivor.player:getInventory():FindAndReturn(survivor.player:getModData().gunWeapon)
        or survivor:getBag():FindAndReturn(survivor.player:getModData().gunWeapon)

    local aiMode = survivor:getAIMode()
    local tm = survivor:getTaskManager()

    if aiMode == "Follow" then
        tm:AddToTop(FollowTask:new(survivor, nil))
    elseif aiMode == "Guard" then
        local group = survivor:getGroup()
        local area = group and group:getGroupArea("GuardArea")
        if area then
            tm:AddToTop(WanderInAreaTask:new(survivor, area))
            tm:setTaskUpdateLimit(10)
        else
            tm:AddToTop(GuardTask:new(survivor, player:getCurrentSquare()))
        end
    elseif aiMode == "Patrol" then
        tm:AddToTop(PatrolTask:new(survivor, nil, nil))
    elseif aiMode == "Wander" then
        tm:AddToTop(WanderTask:new(survivor))
    elseif aiMode == "Stand Ground" then
        tm:AddToTop(GuardTask:new(survivor, player:getCurrentSquare()))
        survivor:setWalkingPermitted(false)
    elseif aiMode == "Doctor" then
        tm:AddToTop(DoctorTask:new(survivor))
    end

    -- Trigger onEquipPrimary
    player:setPrimaryHandItem(nil)
    player:setPrimaryHandItem(survivor:Get():getPrimaryHandItem())
end

function SuperSurvivorManager:spawnSurvivor(isFemale, square)
    if not square then return nil end

    local newSurvivor = SuperSurvivor:newSurvivor(isFemale, square)
    if not newSurvivor then return nil end

    self.SurvivorCount = self.SurvivorCount + 1
    self.SuperSurvivors[self.SurvivorCount] = newSurvivor
    newSurvivor:setID(self.SurvivorCount)
    return newSurvivor
end

function SuperSurvivorManager:Get(thisID)
    return self.SuperSurvivors[thisID] or nil
end

function SuperSurvivorManager:OnDeath(ID)
    self.SuperSurvivors[ID] = nil
end

function SuperSurvivorManager:UpdateSurvivorsRoutine()
    for i = 1, self.SurvivorCount do
        local s = self.SuperSurvivors[i]
        if s and self.MainPlayer ~= i then
            if s:updateTime() and not s.player:isAsleep() and s:isInCell() then
                s:updateSurvivorStatus()
            end
            if s:getCurrentTask() == "None" and not SurvivorRoles[s:getGroupRole()] then
                s:NPCTask_DoWander()
            end
        end
    end
end

function SuperSurvivorManager:AsleepHealAll()
    for i = 1, self.SurvivorCount do
        local s = self.SuperSurvivors[i]
        if s and self.MainPlayer ~= i and s.player then
            s.player:getBodyDamage():AddGeneralHealth(SleepGeneralHealRate)
        end
    end
end

function SuperSurvivorManager:PublicExecution(SSW, SSV)
    local maxdistance = 20
    for i = 1, self.SurvivorCount do
        local s = self.SuperSurvivors[i]
        if s and s:isInCell() then
            local distance = GetDistanceBetween(s:Get(), getSpecificPlayer(0))
            if distance < maxdistance and s:Get():CanSee(SSV:Get()) then
                if not s:isInGroup(SSW:Get()) and not s:isInGroup(SSV:Get()) then
                    if s:usingGun() and ZombRand(2) == 1 then
                        s:Get():getModData().hitByCharacter = true
                    else
                        s:getTaskManager():AddToTop(FleeFromHereTask:new(s, SSW:Get():getCurrentSquare()))
                    end
                    s:SpokeTo(SSW:Get():getModData().ID)
                    s:SpokeTo(SSV:Get():getModData().ID)
                end
            end
        end
    end
end

function SuperSurvivorManager:GunShotHandle(SSW)
    local maxdistance = 20
    local weapon = getSpecificPlayer(0):getPrimaryHandItem()
    if not weapon then return false end

    local range = weapon:getSoundRadius()
    for i = 1, self.SurvivorCount do
        local s = self.SuperSurvivors[i]
        if s and s:isInCell() then
            local distance = GetDistanceBetween(s:Get(), getSpecificPlayer(0))
            if s.player:getModData().surender and distance < maxdistance and s:Get():CanSee(SSW:Get()) then
                -- handle gunshot logic here if needed
            end
        end
    end
end
