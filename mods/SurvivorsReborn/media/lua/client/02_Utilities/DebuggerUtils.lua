local function log_SS_SandboxOptions()
    local isLoggingDebugInfo = true
    for key, value in pairs(SSConfig) do
        CreateLogLine("SS_OptionsValues", isLoggingDebugInfo, key .. ": " .. tostring(value))
    end
end

local function log_SS_PlayerInfo()
    local isLoggingDebugInfo = true
    local mySS = SSM:Get(0)
    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Begin Player Data")
    if mySS then
        local square = mySS:getCurrentSquare()
        if square then
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "SurvivorName: " .. tostring(mySS:getName()))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Group ID: " .. tostring(mySS:getGroupID()))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Group Role: " .. tostring(mySS:getGroupRole()))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo,
                "Survivor Square: locationX: " .. square:getX() ..
                " | locationY: " .. square:getY() .. " | locationZ: " .. square:getZ())
        else
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Survivor Square: nil")
        end
    else
        CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Failed to get player data...")
    end
    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "--- LINE BREAK ---")
end

local function log_SS_GroupsInfo()
    local isLoggingDebugInfo = true
    local groupsWithActualMembers = 0
    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Begin Groups Data")

    for i = 0, SSGM.GroupCount + 1 do
        local group = SSGM.Groups[i]
        if group then
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Group ID: " .. tostring(i))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Leader ID: " .. tostring(group:getLeader()))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Total Members: " .. tostring(group:getMemberCount()))
            if group:getMemberCount() > 0 then
                groupsWithActualMembers = groupsWithActualMembers + 1
            end
        end
    end

    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Total Survivor Groups: " .. tostring(SSGM.GroupCount))
    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Actual Active Groups: " .. tostring(groupsWithActualMembers))
    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "--- LINE BREAK ---")
end

local function log_SS_SurvivorsInfo()
    local isLoggingDebugInfo = true
    local actualLivingSurvivors = 0

    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Begin Survivors Data")

    for i = 0, SSM.SurvivorCount + 1 do
        local survivor = SSM.SuperSurvivors[i]
        if survivor then
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Survivor ID: " .. tostring(i))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Survivor Name: " .. tostring(survivor:getName()))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Is Dead? " .. tostring(survivor:isDead()))
            local square = survivor:getCurrentSquare()
            if square then
                CreateLogLine("SS_Debugger", isLoggingDebugInfo,
                    "Survivor Square: locationX: " .. square:getX() ..
                    " | locationY: " .. square:getY() ..
                    " | locationZ: " .. square:getZ())
            else
                CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Survivor Square: nil")
            end
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Survivor in Group ID: " .. tostring(survivor:getGroupID()))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Group Role: " .. tostring(survivor:getGroupRole()))
            CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Current Task: " .. tostring(survivor:getCurrentTask()))
            if not survivor:isDead() then
                actualLivingSurvivors = actualLivingSurvivors + 1
            end
        end
    end

    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Total Survivors: " .. tostring(SSM.SurvivorCount))
    CreateLogLine("SS_Debugger", isLoggingDebugInfo, "Actual Living NPCs: " .. tostring(actualLivingSurvivors))
end

local function logActiveMods()
    local isLoggingDebugInfo = true
    local activatedMods = getActivatedMods()
    CreateLogLine("SS_ActiveModsFound", isLoggingDebugInfo, tostring(activatedMods))
end

function LogSSDebugInfo()
    local playerSurvivor = getSpecificPlayer(0)
    if playerSurvivor then
        playerSurvivor:Say("Logging Debug info...")
    end
    logActiveMods()
    log_SS_PlayerInfo()
    log_SS_GroupsInfo()
    log_SS_SurvivorsInfo()
    log_SS_SandboxOptions()
    if playerSurvivor then
        playerSurvivor:Say("Logging Debug info complete...")
    end
end
