--//////////////////////////////////////////////////////////--
-- INIT & GLOBALS --
--//////////////////////////////////////////////////////////--

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISLabel"

require "NPCs/Type/SuperSurvivor"
require "NPCs/Type/TaskManager"
require "NPCs/Type/SuperSurvivorPreset"
require "NPCs/Type/Group"

-- Utilities
require "SuperSurvivorUtilities"
require "SuperSurvivorTablesUtilities"
require "SuperSurvivorContextUtilities"
require "SuperSurvivorOrderUtility"

-- Logging toggle (default true, can make optional via settings later)
SuperSurvivorDebugMode = true

function printDebug(message)
    if SuperSurvivorDebugMode then
        print("[SuperSurvivorDebug] " .. tostring(message))
    end
end

--//////////////////////////////////////////////////////////--
-- CONFIGURATION --
--//////////////////////////////////////////////////////////--

SurvivorFollowDistance = 2
SurvivorBravery = 3
SurvivorVisionRange = 10

SurvivorOrderPriority = {
    NONE = 0,
    FOLLOW = 1,
    GUARD = 2,
    WANDER = 3,
    PATROL = 4,
    SCAVENGE = 5,
    ATTACK = 6,
    MEDIC = 7
}

-- Group bravery shared values (optional, not currently used)
-- GroupBraveryBonus = 0
-- GroupBraveryUpdatedTicks = 0

-- Survivor prefab list
SurvivorPresets = {}

--//////////////////////////////////////////////////////////--
-- MAIN SURVIVOR CLASS INIT --
--//////////////////////////////////////////////////////////--

function CreateNewSurvivor(name, position, isFemale, profession, groupID)
    local character = IsoPlayer.new(getWorld():getCell(), nil, position:getX(), position:getY(), position:getZ())
    character:setFemale(isFemale)
    character:setForname(name)
    character:setProfession(profession)

    local survivor = SuperSurvivor:new(character, groupID)
    survivor:setName(name)
    survivor:setProfession(profession)
    survivor:assignGroup(groupID)
    
    if isFemale then
        survivor:setGender("female")
    else
        survivor:setGender("male")
    end

    survivor:initInventory()
    survivor:initTasks()
    survivor:initStats()

    printDebug("Created new survivor: " .. name)
    return survivor
end

-- Legacy alias
function newSurvivor(name, isFemale, position, profession, groupID)
    return CreateNewSurvivor(name, position, isFemale, profession, groupID)
end

--//////////////////////////////////////////////////////////--
-- SURVIVOR METHODS --
--//////////////////////////////////////////////////////////--

SuperSurvivor = {}
SuperSurvivor.__index = SuperSurvivor

function SuperSurvivor:new(character, groupID)
    local self = setmetatable({}, SuperSurvivor)

    self.character = character
    self.groupID = groupID or 0
    self.inventory = character:getInventory()
    self.isDead = false
    self.tasks = TaskManager:new(self)

    self.name = character:getDescriptor():getForename()
    self.gender = character:isFemale() and "female" or "male"
    self.profession = character:getDescriptor():getProfession()

    self.stats = {
        health = 100,
        hunger = 0,
        thirst = 0,
        fatigue = 0
    }

    self.position = {
        x = character:getX(),
        y = character:getY(),
        z = character:getZ()
    }

    return self
end

function SuperSurvivor:setName(name)
    self.name = name
    if self.character then
        self.character:getDescriptor():setForename(name)
    end
end

function SuperSurvivor:getName()
    return self.name
end

function SuperSurvivor:setGender(gender)
    self.gender = gender
end

function SuperSurvivor:getGender()
    return self.gender
end

function SuperSurvivor:setProfession(prof)
    self.profession = prof
    if self.character then
        self.character:getDescriptor():setProfession(prof)
    end
end

function SuperSurvivor:getProfession()
    return self.profession
end

function SuperSurvivor:assignGroup(groupID)
    self.groupID = groupID or 0
end

function SuperSurvivor:getGroupID()
    return self.groupID
end

--//////////////////////////////////////////////////////////--
-- INIT HELPERS --
--//////////////////////////////////////////////////////////--

function SuperSurvivor:initInventory()
    -- Fill inventory with basic items or based on profession
    printDebug(self.name .. " initializing inventory")
end

function SuperSurvivor:initTasks()
    self.tasks:clear()
    printDebug(self.name .. " initializing tasks")
end

function SuperSurvivor:initStats()
    self.stats.health = self.character:getBodyDamage():getHealth()
    -- Can be extended for hunger, thirst, etc.
end

--//////////////////////////////////////////////////////////--
-- POSITION TRACKING --
--//////////////////////////////////////////////////////////--

function SuperSurvivor:updatePosition()
    if not self.character then return end
    self.position.x = self.character:getX()
    self.position.y = self.character:getY()
    self.position.z = self.character:getZ()
end

function SuperSurvivor:getPosition()
    return self.position
end

--//////////////////////////////////////////////////////////--
-- LOGIC & UPDATE LOOP --
--//////////////////////////////////////////////////////////--

function SuperSurvivor:update()
    if self.isDead then return end

    self:updatePosition()
    self:updateStats()
    self.tasks:update()

    printDebug(self.name .. " update cycle completed")
end

function SuperSurvivor:updateStats()
    -- Sync current health
    self.stats.health = self.character:getBodyDamage():getHealth()
end

--//////////////////////////////////////////////////////////--
-- TASK SYSTEM PLACEHOLDER (To Expand Later) --
--//////////////////////////////////////////////////////////--

TaskManager = {}
TaskManager.__index = TaskManager

function TaskManager:new(owner)
    local self = setmetatable({}, TaskManager)
    self.owner = owner
    self.taskQueue = {}
    return self
end

function TaskManager:clear()
    self.taskQueue = {}
end

function TaskManager:update()
    -- Placeholder for running task queue logic
end

-- Handles survivor behaviors, follower logic, combat response, and interaction
-- Continued cleanup for B42 compatibility and modular design

-- Follower behavior and command processing
function SuperSurvivor:Follow()
    local target = self:getFollowedPlayer()
    if not target or target:isDead() then return end

    if self:isTooFarFrom(target) then
        self:walkToObject(target)
    else
        self:faceThisObject(target)
    end
end

function SuperSurvivor:Stay()
    self:StopWalk()
    self:setRunning(false)
end

function SuperSurvivor:isTooFarFrom(target)
    local distance = getDistanceBetween(self:Get(), target)
    return distance > 2
end

function SuperSurvivor:walkToObject(target)
    if not target then return false end
    local tx, ty, tz = target:getX(), target:getY(), target:getZ()
    self:walkTo(tx, ty, tz)
end

function SuperSurvivor:faceThisObject(target)
    if not target then return false end
    self:Get():faceThisObject(target)
end

-- Dialogue and chatter system
function SuperSurvivor:Speak(message)
    if not message or message == "" then return end
    self.LastSpeech = message
    self:Get():Say(message)
end

function SuperSurvivor:SayRandom(messageList)
    if not messageList or #messageList == 0 then return end
    local message = messageList[ZombRand(#messageList) + 1]
    self:Speak(message)
end

-- Inventory interaction
function SuperSurvivor:HasItem(itemType)
    return self.player:getInventory():contains(itemType)
end

function SuperSurvivor:HasWeapon()
    local weapon = self.player:getPrimaryHandItem()
    return weapon and weapon:isWeapon()
end

function SuperSurvivor:FindAndEquipWeapon()
    local inv = self.player:getInventory()
    local weapon = inv:getBestWeapon()
    if weapon then
        self.player:setPrimaryHandItem(weapon)
        return true
    end
    return false
end

-- Behavior utility
function SuperSurvivor:IsInAction()
    return self:isWalking() or self:isRunning()
end

function SuperSurvivor:shouldRunFromZombies()
    return self:hasInjury() or self:getDangerSeenCount() > 1
end

-- Inventory and looting logic
function SuperSurvivor:HasRoomInBag()
    local bag = self.player:getInventory()
    return bag:getCapacityWeight() < bag:getMaxWeight()
end

function SuperSurvivor:TransferItemToBag(item)
    if not item then return false end
    local inv = self.player:getInventory()
    inv:AddItem(item)
    return true
end

function SuperSurvivor:CountItems(itemType)
    local inv = self.player:getInventory()
    return inv:getItemCount(itemType)
end

function SuperSurvivor:GetItemListByType(itemType)
    local inv = self.player:getInventory()
    return inv:FindAll(itemType)
end

function SuperSurvivor:RemoveItem(item)
    if item then
        self.player:getInventory():Remove(item)
        return true
    end
    return false
end

function SuperSurvivor:EquipItem(item)
    if item and item:IsWeapon() then
        self.player:setPrimaryHandItem(item)
    elseif item and item:IsClothing() then
        self.player:Wear(item)
    end
end

-- Handles dialogue during trades, interactions, and other scenarios
function SuperSurvivor:SpeakTo(player, text, mood)
    if not self:isInAction() and self.LastSpeech ~= text then
        local realtext = text
        if mood == "angry" then realtext = "*angrily* " .. text end
        if mood == "sad" then realtext = "*sadly* " .. text end
        if mood == "happy" then realtext = "*happily* " .. text end
        self.player:Say(realtext)
        self.LastSpeech = text
    end
end

function SuperSurvivor:WalkToLastKnownLocation()
    if not self.LastKnownLocation then return false end
    if getDistanceBetween(self:Get(), self.LastKnownLocation.x, self.LastKnownLocation.y) > 1.5 then
        self:walkTo(self.LastKnownLocation.x, self.LastKnownLocation.y, self.LastKnownLocation.z)
        return true
    end
    return false
end

-- Behavior when losing sight of enemy or target
function SuperSurvivor:OnLostVisual()
    if self.LastEnemySeen then
        self.LastKnownLocation = { x = self.LastEnemySeen:getX(), y = self.LastEnemySeen:getY(), z = self.LastEnemySeen:getZ() }
        self.LastSeenZombieTime = getGameTime():getWorldAgeHours()
    end
end

-- Reset pathfinding data
function SuperSurvivor:ResetPath()
    self.player:getPathFindBehavior2():reset()
    self.TargetBuilding = nil
    self.PathToTarget = nil
end

-- For escorting a player or following leader
function SuperSurvivor:EscortPlayer(playerObj)
    if not playerObj or not instanceof(playerObj, "IsoPlayer") then return false end
    self.FollowingTarget = playerObj
    self:setAIMode("Follow")
    self.TargetBuilding = nil
    return true
end

-- Inventory logic: Use item from bag
function SuperSurvivor:UseItemFromBag(itemType)
    local inv = self.player:getInventory()
    local item = inv:getFirstTypeRecurse(itemType)
    if item then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.player, item, item:getContainer(), self.player:getInventory(), nil))
        ISTimedActionQueue.add(ISUseItemAction:new(self.player, item, 50))
        return true
    end
    return false
end

-- Defensive logic
function SuperSurvivor:RunFromDanger()
    local threat = self:FindThreat()
    if not threat then return false end
    self:Speak(getText("UI_SSR_RunningFromDanger"), "angry")
    self:RunToPointAwayFrom(threat:getX(), threat:getY(), threat:getZ())
    return true
end

function SuperSurvivor:FindThreat()
    local threat = nil
    local closestDist = 20
    local zombies = getCell():getZombieList()
    for i = 0, zombies:size() - 1 do
        local z = zombies:get(i)
        if z and z:isAlive() then
            local dist = getDistanceBetween(self:Get(), z)
            if dist < closestDist then
                threat = z
                closestDist = dist
            end
        end
    end
    return threat
end

-- Behavior for speaking during idle
function SuperSurvivor:IdleChatter()
    if ZombRand(100) < 5 then
        local phrases = {
            "I miss TV...",
            "Is it safe here?",
            "At least I'm not alone...",
            "I hope this ends someday.",
            "Another day survived."
        }
        local text = phrases[ZombRand(#phrases) + 1]
        self:Speak(text)
    end
end

-- Toggle sneaking
function SuperSurvivor:SetSneaking(state)
    self.player:setSneaking(state)
    self.player:setRunning(not state)
end

-- Makes the survivor loot a container if nearby
function SuperSurvivor:LootNearbyContainer()
    local container = self:FindNearbyContainer()
    if not container then return false end
    local inv = container:getInventory()
    local loot = inv:getItems()
    for i = 0, loot:size() - 1 do
        local item = loot:get(i)
        if item and self:CanPickupItem(item) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.player, item, container, self.player:getInventory(), nil))
        end
    end
    return true
end

function SuperSurvivor:FindNearbyContainer()
    local sq = getCell():getGridSquare(self.player:getX(), self.player:getY(), self.player:getZ())
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if instanceof(obj, "IsoObject") and obj:getContainer() then
            return obj
        end
    end
    return nil
end

-- Checks if an item can be picked up
function SuperSurvivor:CanPickupItem(item)
    if not item then return false end
    if item:isFavorite() then return false end
    if item:getWeight() > 5 then return false end
    return true
end

-- Handle AI attacking a target
function SuperSurvivor:AttackTarget(target)
    if not target or not target:isAlive() then return false end
    if self:isInAction() then return false end

    local weapon = self.player:getPrimaryHandItem()
    if weapon and weapon:isAimedFirearm() then
        self:SetAiming(true)
    else
        self:SetAiming(false)
    end

    if getDistanceBetween(self:Get(), target) < 1.5 then
        self:Speak(getText("UI_SSR_AttackingEnemy"), "angry")
        self.player:faceThisObject(target)
        ISTimedActionQueue.add(ISAttackAction:new(self.player, target))
        return true
    else
        self:walkTo(target:getX(), target:getY(), target:getZ())
    end
    return false
end

-- Set aiming state
function SuperSurvivor:SetAiming(state)
    self.player:setAiming(state)
end

-- Return true if enemy is within attack range
function SuperSurvivor:IsEnemyInRange(enemy)
    if not enemy then return false end
    return getDistanceBetween(self:Get(), enemy) <= 1.5
end

-- Behavior for patrolling between two points
function SuperSurvivor:PatrolBetween(pointA, pointB)
    if not self.CurrentPatrolTarget then
        self.CurrentPatrolTarget = pointA
    end

    if getDistanceBetween(self:Get(), self.CurrentPatrolTarget.x, self.CurrentPatrolTarget.y) < 1 then
        if self.CurrentPatrolTarget == pointA then
            self.CurrentPatrolTarget = pointB
        else
            self.CurrentPatrolTarget = pointA
        end
    end

    self:walkTo(self.CurrentPatrolTarget.x, self.CurrentPatrolTarget.y, self.CurrentPatrolTarget.z)
end

-- Handle food search behavior
function SuperSurvivor:FindFoodAndEat()
    local food = self:FindBestFoodInInventory()
    if food then
        self:Speak(getText("UI_SSR_EatingFood"), "happy")
        ISTimedActionQueue.add(ISUseItemAction:new(self.player, food, 30))
        return true
    end
    return false
end

-- Select best food item in inventory
function SuperSurvivor:FindBestFoodInInventory()
    local bestFood = nil
    local bestScore = -1
    local inv = self.player:getInventory():getItems()
    for i = 0, inv:size() - 1 do
        local item = inv:get(i)
        if item and item:IsFood() and item:getHungerChange() < 0 then
            local score = math.abs(item:getHungerChange())
            if score > bestScore then
                bestFood = item
                bestScore = score
            end
        end
    end
    return bestFood
end

-- Checks if the survivor is idle
function SuperSurvivor:IsIdle()
    return not self:isInAction() and not self.player:isMoving()
end

-- Looks for loot in nearby buildings
function SuperSurvivor:SearchNearbyBuildings()
    local buildings = self:GetNearbyBuildings(10)
    for i = 1, #buildings do
        local bld = buildings[i]
        if bld and not self:HasVisitedBuilding(bld) then
            self:EnterBuilding(bld)
            return true
        end
    end
    return false
end

-- Collect nearby building references
function SuperSurvivor:GetNearbyBuildings(radius)
    local buildings = {}
    local cx, cy = self.player:getX(), self.player:getY()
    for x = cx - radius, cx + radius do
        for y = cy - radius, cy + radius do
            local sq = getCell():getGridSquare(x, y, self.player:getZ())
            if sq and sq:getBuilding() then
                local building = sq:getBuilding()
                if not buildings[building] then
                    table.insert(buildings, building)
                    buildings[building] = true
                end
            end
        end
    end
    return buildings
end

-- Enter building logic
function SuperSurvivor:EnterBuilding(building)
    if not building then return false end
    local sq = building:getRandomRoom():getRandomSquare()
    if sq then
        self:walkTo(sq:getX(), sq:getY(), sq:getZ())
        self.VisitedBuildings[building] = true
    end
end

-- Checks if building was already visited
function SuperSurvivor:HasVisitedBuilding(building)
    return self.VisitedBuildings[building] == true
end

-- Track visited buildings to avoid repeats
function SuperSurvivor:InitVisitedBuildings()
    self.VisitedBuildings = {}
end

-- Speak to nearby survivors in range
function SuperSurvivor:SpeakToNearbySurvivors()
    local others = self:GetNearbySurvivors(6)
    for _, other in ipairs(others) do
        if other and other.player and other.player:isAlive() and other ~= self then
            self:Speak(getText("UI_SSR_Greeting") .. " " .. other.player:getDisplayName(), "normal")
            return true
        end
    end
    return false
end

-- Get list of nearby survivors
function SuperSurvivor:GetNearbySurvivors(range)
    local result = {}
    for i = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(i)
        if p and p ~= self.player and getDistanceBetween(self:Get(), p) <= range then
            local survivor = SSManager:Get(p)
            if survivor then table.insert(result, survivor) end
        end
    end
    return result
end

-- Return true if this survivor has line of sight to another character
function SuperSurvivor:CanSeeTarget(target)
    if not target then return false end
    return self.player:CanSee(target)
end

-- Survivor behavior when resting
function SuperSurvivor:RestIfTired()
    if self.player:getStats():getFatigue() > 0.5 then
        self:Speak(getText("UI_SSR_Resting"), "calm")
        ISTimedActionQueue.add(ISRestAction:new(self.player, 600))
        return true
    end
    return false
end

-- Basic follow behavior
function SuperSurvivor:Follow(target)
    if not target or not target:isAlive() then return false end
    local dist = getDistanceBetween(self:Get(), target)
    if dist > 2 then
        self:walkTo(target:getX(), target:getY(), target:getZ())
    elseif dist < 1 then
        self:StopWalking()
    end
end

-- Stop movement
function SuperSurvivor:StopWalking()
    ISTimedActionQueue.clear(self.player)
    self.player:setPathFindIndex(0)
    self.player:setLastSquare(nil)
    self.player:setCurrentSquare(self.player:getCurrentSquare())
end

-- Say something (generic)
function SuperSurvivor:Speak(message, tone)
    if not message then return end
    tone = tone or "neutral"

    if self.LastSpokenMessage == message and (getTimestampMs() - self.LastSpeechTime < 8000) then
        return
    end

    self.LastSpokenMessage = message
    self.LastSpeechTime = getTimestampMs()

    local prefix = ""
    if tone == "angry" then
        prefix = "[!]"
    elseif tone == "happy" then
        prefix = "[:)]"
    elseif tone == "calm" then
        prefix = "[~]"
    elseif tone == "neutral" then
        prefix = "[-]"
    end

    self.player:Say(prefix .. " " .. message)
end

-- Helper for checking hunger and eating
function SuperSurvivor:CheckHunger()
    local hunger = self.player:getStats():getHunger()
    if hunger > 0.3 then
        return self:FindFoodAndEat()
    end
    return false
end

-- Heal if injured and medical supplies are available
function SuperSurvivor:SelfHeal()
    local body = self.player:getBodyDamage()
    if body:HasInjuries() then
        local inv = self.player:getInventory()
        local bandage = inv:FindAndReturn("Bandage") or inv:FindAndReturn("RippedSheets")
        if bandage then
            for i = BodyPartType.ToIndex(BodyPartType.Hand_L), BodyPartType.ToIndex(BodyPartType.Feet_R) do
                local part = body:getBodyPart(BodyPartType.FromIndex(i))
                if part:hasInjury() and not part:bandaged() then
                    ISTimedActionQueue.add(ISApplyBandage:new(self.player, self.player, part, bandage, false))
                    return true
                end
            end
        end
    end
    return false
end

-- Behavior for handling panic
function SuperSurvivor:HandlePanic()
    local stats = self.player:getStats()
    if stats:getPanic() > 50 then
        self:Speak(getText("UI_SSR_Panicking"), "angry")
        -- Temporary stop movement and rest
        self:StopWalking()
        ISTimedActionQueue.add(ISRestAction:new(self.player, 300))
        return true
    end
    return false
end

-- Behavior for handling infection or sickness (placeholder for expansion)
function SuperSurvivor:HandleSickness()
    local body = self.player:getBodyDamage()
    if body:IsInfected() or body:getOverallBodyHealth() < 30 then
        self:Speak(getText("UI_SSR_Sick"), "calm")
        -- Placeholder: maybe seek a doctor or meds
        return true
    end
    return false
end

-- Checks whether the survivor can reach a square
function SuperSurvivor:CanReachSquare(square)
    if not square then return false end
    return self.player:canMoveTo(square)
end

-- Teleports the survivor if stuck (basic recovery)
function SuperSurvivor:TeleportToSafeSpot()
    local safe = getCell():getGridSquare(self.player:getX() + 1, self.player:getY(), self.player:getZ())
    if safe then
        self.player:setX(safe:getX())
        self.player:setY(safe:getY())
        self.player:setZ(safe:getZ())
        self.player:setCurrentSquare(safe)
    end
end

-- General purpose loot function (placeholder for expansion)
function SuperSurvivor:LootNearby()
    local square = getCell():getGridSquare(self.player:getX(), self.player:getY(), self.player:getZ())
    if not square then return false end

    local container = square:getContainer()
    if container and not container:isEmpty() then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.player, container:getItemContainer(), self.player:getInventory(), container:getItemContainer():getFirst()))
        return true
    end
    return false
end

-- Scan for zombies within radius
function SuperSurvivor:ScanForZombies(radius)
    local count = 0
    local px, py, pz = self.player:getX(), self.player:getY(), self.player:getZ()

    for x = px - radius, px + radius do
        for y = py - radius, py + radius do
            local square = getCell():getGridSquare(x, y, pz)
            if square then
                local zombies = square:getMovingObjects()
                if zombies then
                    for i = 0, zombies:size() - 1 do
                        local obj = zombies:get(i)
                        if instanceof(obj, "IsoZombie") and obj:isAlive() then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    return count
end

-- Engage in melee combat with a target
function SuperSurvivor:AttackTarget(target)
    if not target or not target:isAlive() then return false end
    if getDistanceBetween(self:Get(), target) > 1.5 then
        self:walkTo(target:getX(), target:getY(), target:getZ())
    else
        self.player:faceThisObject(target)
        ISTimedActionQueue.add(ISAttackAction:new(self.player, target, 1))
    end
    return true
end

-- Decide whether to flee or fight based on courage trait
function SuperSurvivor:DecideCombatBehavior(zombieCount)
    if self.traits["Coward"] and zombieCount > 2 then
        self:Speak(getText("UI_SSR_Fleeing"), "angry")
        self:Flee()
    elseif self.traits["Brave"] or self.traits["Rambo"] then
        self:Speak(getText("UI_SSR_Fighting"), "happy")
        self:SeekAndDestroy()
    else
        if zombieCount >= 1 and zombieCount <= 3 then
            self:SeekAndDestroy()
        else
            self:Flee()
        end
    end
end

-- Flee logic (basic version)
function SuperSurvivor:Flee()
    local px, py = self.player:getX(), self.player:getY()
    local rx, ry = ZombRand(-5, 5), ZombRand(-5, 5)
    local tx, ty = px + rx, py + ry
    self:walkTo(tx, ty, self.player:getZ())
end

-- Seek and destroy nearby enemies
function SuperSurvivor:SeekAndDestroy()
    local zombies = self:GetNearbyZombies(8)
    if #zombies > 0 then
        self:AttackTarget(zombies[1])
    end
end

-- Get list of zombies near the player
function SuperSurvivor:GetNearbyZombies(radius)
    local found = {}
    local px, py, pz = self.player:getX(), self.player:getY(), self.player:getZ()

    for x = px - radius, px + radius do
        for y = py - radius, py + radius do
            local square = getCell():getGridSquare(x, y, pz)
            if square then
                local objs = square:getMovingObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    if instanceof(obj, "IsoZombie") and obj:isAlive() then
                        table.insert(found, obj)
                    end
                end
            end
        end
    end

    return found
end

-- Return a list of visible zombies (line-of-sight only)
function SuperSurvivor:GetVisibleZombies(radius)
    local visible = {}
    local all = self:GetNearbyZombies(radius)
    for _, z in ipairs(all) do
        if self:CanSeeTarget(z) then
            table.insert(visible, z)
        end
    end
    return visible
end

-- Give weapon to survivor
function SuperSurvivor:EquipWeapon(weapon)
    if not weapon then return false end
    local inv = self.player:getInventory()
    if not inv:contains(weapon) then
        inv:AddItem(weapon)
    end
    self.player:setPrimaryHandItem(weapon)
    return true
end

-- Check and equip best weapon
function SuperSurvivor:EquipBestWeapon()
    local inv = self.player:getInventory()
    local best = nil
    local highestDamage = 0

    for i = 0, inv:getItems():size() - 1 do
        local item = inv:getItems():get(i)
        if instanceof(item, "HandWeapon") then
            if item:getMaxDamage() > highestDamage then
                highestDamage = item:getMaxDamage()
                best = item
            end
        end
    end

    if best then
        self:EquipWeapon(best)
        return true
    end
    return false
end

-- Behavior loop handler (stub for future state machine)
function SuperSurvivor:Update()
    if not self.player or not self.player:isAlive() then return end

    if self:CheckHunger() then return end
    if self:SelfHeal() then return end
    if self:HandlePanic() then return end
    if self:HandleSickness() then return end

    local zombieCount = self:ScanForZombies(8)
    if zombieCount > 0 then
        self:DecideCombatBehavior(zombieCount)
    else
        self:SpeakToNearbySurvivors()
    end
end

-- Speak to nearby survivors
function SuperSurvivor:SpeakToNearbySurvivors()
    local survivors = self:GetNearbySurvivors(6)
    for _, survivor in ipairs(survivors) do
        if not self:IsInGroupWith(survivor) then
            self:Speak(getText("UI_SSR_FriendlyGreeting") .. " " .. survivor:getDescriptor():getForename())
        end
    end
end

-- Check if two survivors are in same group
function SuperSurvivor:IsInGroupWith(otherSurvivor)
    if not self.GroupID or not otherSurvivor.GroupID then return false end
    return self.GroupID == otherSurvivor.GroupID
end

-- Get nearby survivors
function SuperSurvivor:GetNearbySurvivors(radius)
    local found = {}
    local px, py, pz = self.player:getX(), self.player:getY(), self.player:getZ()

    for x = px - radius, px + radius do
        for y = py - radius, py + radius do
            local square = getCell():getGridSquare(x, y, pz)
            if square then
                local objs = square:getMovingObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    if instanceof(obj, "IsoPlayer") and obj ~= self.player and not obj:isDead() then
                        table.insert(found, obj)
                    end
                end
            end
        end
    end

    return found
end

-- Heal self if wounded
function SuperSurvivor:SelfHeal()
    local bodyDamage = self.player:getBodyDamage()
    if bodyDamage:HasInjuries() then
        self:Speak(getText("UI_SSR_Healing"), "info")
        -- Placeholder logic for healing with bandage
        local bandage = self.player:getInventory():FindAndReturn("Base.Bandage")
        if bandage then
            ISTimedActionQueue.add(ISApplyBandage:new(self.player, self.player, bodyDamage:getBodyPart(BodyPartType.Hand_L), bandage, false))
            return true
        end
    end
    return false
end

-- React to panic
function SuperSurvivor:HandlePanic()
    if self.player:getStats():getPanic() > 50 then
        self:Speak(getText("UI_SSR_Panic"), "shout")
        self:Flee()
        return true
    end
    return false
end

-- React to illness
function SuperSurvivor:HandleSickness()
    local stats = self.player:getStats()
    if stats:getFatigue() > 0.8 or stats:getEndurance() < 0.2 then
        self:Speak(getText("UI_SSR_Tired"), "whisper")
        self:Rest()
        return true
    end
    return false
end

-- Resting behavior (sit down or stay idle)
function SuperSurvivor:Rest()
    self.player:setSitOnGround(true)
    self.player:setIgnoreMovement(true)
end

-- Hunger check
function SuperSurvivor:CheckHunger()
    local hunger = self.player:getStats():getHunger()
    if hunger > 0.5 then
        self:Speak(getText("UI_SSR_Hungry"), "info")
        local food = self:GetBestFood()
        if food then
            ISTimedActionQueue.add(ISEatFoodAction:new(self.player, food, 1))
            return true
        end
    end
    return false
end

-- Get best food from inventory
function SuperSurvivor:GetBestFood()
    local inv = self.player:getInventory()
    local bestFood = nil
    local bestNutrition = 0

    for i = 0, inv:getItems():size() - 1 do
        local item = inv:getItems():get(i)
        if instanceof(item, "Food") then
            local hungerReduction = item:getHungerChange() * -1
            if hungerReduction > bestNutrition then
                bestNutrition = hungerReduction
                bestFood = item
            end
        end
    end

    return bestFood
end

-- Final cleanup
function SuperSurvivor:CleanUp()
    -- Future: drop items, clear queue, reset states, etc.
    self.player:setIgnoreMovement(false)
end

-- Utility to walk to a given tile
function SuperSurvivor:walkTo(x, y, z)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(self.player, getCell():getGridSquare(x, y, z)))
end

-- Wrapper to speak text with optional emotion
function SuperSurvivor:Speak(text, tone)
    if not text or text == "" then return end
    local color = (tone == "angry" and "red") or (tone == "happy" and "green") or (tone == "whisper" and "lightgray") or "white"
    local sayText = "[" .. self.player:getDescriptor():getForename() .. "]: " .. text
    HaloTextHelper.addTextWithArrow(self.player, sayText, true, color)
end
