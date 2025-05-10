SuperSurvivorSelectArea = {}

-- Flag to trigger area selection
SuperSurvivorSelectAnArea = false
SuperSurvivorMouseDownTicks = 0

-- Utility: Get local player (for future MP safety)
local function getPlayer()
    return getSpecificPlayer(0) -- TODO: Update for MP later
end

-- Highlight selection logic
local function selectBaseArea()
    if not SuperSurvivorSelectAnArea then return end

    if Mouse.isLeftDown() then
        SuperSurvivorMouseDownTicks = SuperSurvivorMouseDownTicks + 1
    else
        SuperSurvivorMouseDownTicks = 0
        SuperSurvivorSelectingArea = false
    end

    if SuperSurvivorMouseDownTicks > 15 then
        if not Highlightcenter or not SuperSurvivorSelectingArea then
            local sq = GetMouseSquare()
            Highlightcenter = sq
            HighlightX1 = sq:getX()
            HighlightX2 = sq:getX()
            HighlightY1 = sq:getY()
            HighlightY2 = sq:getY()
        end

        SuperSurvivorSelectingArea = true

        local mouseX, mouseY = GetMouseSquareX(), GetMouseSquareY()

        if not HighlightX1 or HighlightX1 > mouseX then HighlightX1 = mouseX end
        if not HighlightX2 or HighlightX2 <= mouseX then HighlightX2 = mouseX end
        if not HighlightY1 or HighlightY1 > mouseY then HighlightY1 = mouseY end
        if not HighlightY2 or HighlightY2 <= mouseY then HighlightY2 = mouseY end

    elseif SuperSurvivorSelectingArea then
        SuperSurvivorSelectingArea = false
    end

    if Mouse.isLeftPressed() then
        SuperSurvivorSelectingArea = false
    end

    -- Visual highlighting
    if HighlightX1 and HighlightX2 then
        local player = getPlayer()
        local z = player and player:getZ() or 0

        for xx = HighlightX1, HighlightX2 do
            for yy = HighlightY1, HighlightY2 do
                local sq = getCell():getGridSquare(xx, yy, z)
                if sq and sq:getFloor() then
                    sq:getFloor():setHighlighted(true)
                end
            end
        end
    end
end

-- Start selection mode
function StartSelectingArea(test, area)
    local isLocalFunctionLoggingEnabled = false

    -- Reset area selection flags
    for k in pairs(SuperSurvivorSelectArea) do
        SuperSurvivorSelectArea[k] = false
    end

    CreateLogLine("SuperSurvivorsBaseManagement", isLocalFunctionLoggingEnabled, "starting selectBaseArea()...")

    SuperSurvivorSelectArea[area] = true
    SuperSurvivorSelectAnArea = true
    Events.OnRenderTick.Add(selectBaseArea)

    local mySS = SSM:Get(0)
    if not mySS then return false end

    local gid = mySS:getGroupID()
    if not gid then return false end

    local group = SSGM:GetGroupById(gid)
    if not group then return false end

    local bounds = (area == "BaseArea") and group:getBounds() or group:getGroupArea(area)
    if bounds then
        HighlightX1, HighlightX2 = bounds[1], bounds[2]
        HighlightY1, HighlightY2 = bounds[3], bounds[4]
        HighlightZ = bounds[5]
    end
end

-- Finalize or cancel selection
function SelectingArea(test, area, value)
    local isLocalFunctionLoggingEnabled = false
    CreateLogLine("SuperSurvivorsBaseManagement", isLocalFunctionLoggingEnabled, "function: SelectingArea() called")

    if value ~= 0 then
        if value == -1 then
            HighlightX1, HighlightX2 = 0, 0
            HighlightY1, HighlightY2 = 0, 0
        end

        local mySS = SSM:Get(0)
        if not mySS then return false end

        local gid = mySS:getGroupID()
        if not gid then return false end

        local group = SSGM:GetGroupById(gid)
        if not group then return false end

        local z = getPlayer() and getPlayer():getZ() or 0

        if area == "BaseArea" then
            local baseBounds = {
                math.floor(HighlightX1 or 0),
                math.floor(HighlightX2 or 0),
                math.floor(HighlightY1 or 0),
                math.floor(HighlightY2 or 0),
                math.floor(z)
            }
            group:setBounds(baseBounds)

            CreateLogLine("SuperSurvivorsBaseManagement", isLocalFunctionLoggingEnabled,
                "set base bounds: " .. tostring(HighlightX1) .. "," .. tostring(HighlightX2) ..
                " : " .. tostring(HighlightY1) .. "," .. tostring(HighlightY2))
        else
            group:setGroupArea(area,
                math.floor(HighlightX1 or 0),
                math.floor(HighlightX2 or 0),
                math.floor(HighlightY1 or 0),
                math.floor(HighlightY2 or 0),
                math.floor(z)
            )
        end
    end

    -- Clean up
    CreateLogLine("SuperSurvivorsBaseManagement", isLocalFunctionLoggingEnabled, "stopping SelectBaseArea()...")
    SuperSurvivorSelectArea[area] = false
    SuperSurvivorSelectAnArea = false
    Events.OnRenderTick.Remove(selectBaseArea)
    CreateLogLine("SuperSurvivorsBaseManagement", isLocalFunctionLoggingEnabled, "--- function: SelectingArea() end ---")
end
