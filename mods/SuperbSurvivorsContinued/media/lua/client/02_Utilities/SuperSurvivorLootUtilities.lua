-- SuperSurvivorLootUtilities.lua
-- Handles looting-related utility functions

local isLocalLoggingEnabled = false

-- Categories supported
---@alias itemCategory
---| "Food"
---| "Water"
---| "Weapon"

-- Excluded food items (Cigarettes removed for smoker logic)
local FoodsToExclude = {
    Bleach = true,
    HCCigar = true,
    Antibiotics = true,
    Teabag2 = true,
    Salt = true,
    Pepper = true,
    EggCarton = true,
}

-- === CATEGORY FUNCTIONS ===

---@param container ItemContainer
---@param category itemCategory
---@param survivor any
---@return InventoryItem|nil
function FindItemByCategory(container, category, survivor)
    CreateLogLine("SuperSurvivorLootUtilities", isLocalLoggingEnabled, "FindItemByCategory called")

    if not container then return nil end

    if category == "Food" then
        return FindAndReturnBestFood(container, survivor)
    elseif category == "Water" then
        return FindAndReturnWater(container)
    elseif category == "Weapon" then
        return FindAndReturnWeapon(container)
    else
        return container:FindAndReturnCategory(category)
    end
end

---@param item InventoryItem
---@param category itemCategory
---@return boolean
function HasCategory(item, category)
    if not item then return false end

    if category == "Water" then
        return IsItemWater(item)
    elseif category == "Weapon" then
        return (item:getCategory() == "Weapon") and (item:getMaxDamage() > 0.1)
    else
        return item:getCategory() == category
    end
end

-- === WEAPONS ===

---@param container ItemContainer
---@return InventoryItem|nil
function FindAndReturnWeapon(container)
    CreateLogLine("SuperSurvivorLootUtilities", isLocalLoggingEnabled, "FindAndReturnWeapon called")
    if not container then return nil end

    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getCategory() == "Weapon" and item:getMaxDamage() > 0.1 then
            return item
        end
    end

    return nil
end

---@param container ItemContainer
---@return InventoryItem|nil
function FindAndReturnBestWeapon(container)
    CreateLogLine("SuperSurvivorLootUtilities", isLocalLoggingEnabled, "FindAndReturnBestWeapon called")
    if not container then return nil end

    local bestItem = nil
    local items = container:getItems()

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getCategory() == "Weapon" and item:getMaxDamage() > 0.1 then
            if not bestItem or item:getMaxDamage() > bestItem:getMaxDamage() then
                bestItem = item
            end
        end
    end

    return bestItem
end

-- === FOOD ===

---@param container ItemContainer
---@return InventoryItem|nil
function FindAndReturnFood(container)
    if not container then return nil end

    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getCategory() == "Food" and item:getPoisonPower() <= 1 and not FoodsToExclude[item:getType()] then
            return item
        end
    end

    return nil
end

---@param item InventoryItem
---@return number
function GetFoodScore(item)
    if not item then return -9999 end

    local score = 1.0
    local hunger = item:getHungerChange() or 0

    if item:getUnhappyChange() > 0 then
        score = score - math.floor(item:getUnhappyChange() / (hunger * -10.0))
    elseif item:getUnhappyChange() < 0 then
        score = score + 1
    end

    if item:getBoredomChange() > 0 then
        score = score - math.floor(item:getBoredomChange() / (hunger * -10.0) / 2.0)
    elseif item:getBoredomChange() < 0 then
        score = score + 1
    end

    if item:isFresh() then
        score = score + 2
    elseif item:IsRotten() then
        score = score - 10
    end

    if item:isAlcoholic() or item:isSpice() then
        score = score - 5
    end

    if item:isbDangerousUncooked() and not item:isCooked() then
        score = score - 10
    end

    local foodType = item:getFoodType()
    if not foodType or foodType == "NoExplicit" then
        local name = item:getDisplayName()
        if name:find("Open") then
            score = score + 3
        elseif name:find("Canned") then
            score = score - 5
        elseif name == "Dog Food" then
            score = score - 10
        elseif hunger == 0 then
            score = -9999
        end

        if item:isCooked() then
            score = score + 5
        end
    elseif foodType == "Fruits" or foodType == "Vegetables" then
        score = score + 1
    elseif foodType == "Pasta" or foodType == "Rice" then
        score = score - 2
    elseif foodType == "Egg" or foodType == "Meat" or item:isIsCookable() then
        if item:isCooked() then
            score = score + 2
        end
    elseif foodType == "Coffee" then
        score = score - 5
    end

    return score
end

---@param container ItemContainer
---@param survivor any
---@return InventoryItem|nil
function FindAndReturnBestFood(container, survivor)
    if not container then return nil end

    local items = container:getItems()
    local bestItem = nil
    local bestScore = survivor and (survivor:isStarving() and -999 or (survivor:isVHungry() and -10 or 1)) or 1

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local itemType = item and item:getType()

        if item and item:getCategory() == "Food" and item:getPoisonPower() <= 1 then
            local isSmoker = survivor and survivor.player and survivor.player:HasTrait("Smoker")
            if itemType == "Cigarettes" and isSmoker then
                return item -- smokers prioritize cigarettes
            elseif not FoodsToExclude[itemType] and itemType ~= "Cigarettes" then
                local score = GetFoodScore(item)
                if score > bestScore then
                    bestItem = item
                    bestScore = score
                end
            end
        end
    end

    return bestItem
end

---@param sq IsoGridSquare
---@param survivor any
---@return InventoryItem|nil
function FindAndReturnBestFoodOnFloor(sq, survivor)
    if not sq then return nil end

    local bestItem = nil
    local bestScore = survivor and (survivor:isStarving() and -999 or (survivor:isVHungry() and -10 or 1)) or 1
    local items = sq:getWorldObjects()

    for i = 0, items:size() - 1 do
        local item = items:get(i):getItem()
        if item and item:getCategory() == "Food" and item:getPoisonPower() <= 1 and not FoodsToExclude[item:getType()] then
            local score = GetFoodScore(item)
            if score > bestScore then
                bestItem = item
                bestScore = score
            end
        end
    end

    return bestItem
end

-- === WATER ===

---@param container ItemContainer
---@return InventoryItem|nil
function FindAndReturnWater(container)
    if not container then return nil end

    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and IsItemWater(item) then
            return item
        end
    end

    return nil
end

---@param item InventoryItem
---@return boolean
function IsItemWater(item)
    return item and item:isWaterSource() and item:getType() ~= "Bleach"
end

