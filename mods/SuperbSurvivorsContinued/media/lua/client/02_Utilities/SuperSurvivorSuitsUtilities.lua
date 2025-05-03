-- SuperSurvivorSuitsUtilities.lua
-- Handles random and specific outfit assignment to survivors

require "00_SuperbSurviorModVariables/SuperSurvivorsSuitsList"

local isLocalLoggingEnabled = false

---@alias SuitRarity "Common" | "Uncommon" | "Normal" | "Rare" | "VeryRare" | "Legendary" | "Preset"

--- Assigns a random outfit to a survivor based on rarity probability
---@param SS table Survivor object with :WearThis() and .player:isFemale()
function GetRandomSurvivorSuit(SS)
    CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "GetRandomSurvivorSuit() called")

    local roll = ZombRand(0, 101)
    local rarity
    local suitPool

    -- Determine suit rarity by roll
    if roll == 1 then
        rarity = "Legendary"
    elseif roll <= 5 then
        rarity = "VeryRare"
    elseif roll <= 15 then
        rarity = "Rare"
    elseif roll <= 25 then
        rarity = "Normal"
    elseif roll <= 40 then
        rarity = "Uncommon"
    else
        rarity = "Common"
    end

    CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Selected rarity: " .. rarity)
    suitPool = SurvivorRandomSuits[rarity]
    if not suitPool then return end

    -- Select a gender-appropriate suit name
    local suitName = table.randFrom(suitPool)
    while (string.sub(suitName, -1) == "F" and not SS.player:isFemale()) or
          (string.sub(suitName, -1) == "M" and SS.player:isFemale()) do
        suitName = table.randFrom(suitPool)
    end

    CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "Selected suit: " .. tostring(suitName))

    -- Wear all items from the selected suit table
    local suitItems = suitPool[suitName]
    if suitItems then
        for _, item in ipairs(suitItems) do
            if item then
                SS:WearThis(item)
            end
        end
    end

    CreateLogLine("SuperSurvivorSuitsUtilities", isLocalLoggingEnabled, "--- GetRandomSurvivorSuit() end ---")
end

--- Assigns a specific suit to a survivor if available
---@param SS table Survivor object
---@param rarity SuitRarity The rarity category table
---@param suitName string Specific name of the suit to assign
function SetRandomSurvivorSuit(SS, rarity, suitName)
    local suitPool = SurvivorRandomSuits[rarity]
    if not suitPool then return end

    local suitItems = suitPool[suitName]
    if suitItems then
        for _, item in ipairs(suitItems) do
            if item then
                SS:WearThis(item)
            end
        end
    end
end
