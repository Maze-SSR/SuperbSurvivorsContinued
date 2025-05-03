-- Updated for Build 42 compatibility
-- SuperSurvivorContextUtilities.lua

local isLocalLoggingEnabled = false

---@alias direction
---| '"N"' # North
---| '"S"' # South
---| '"E"' # East
---| '"W"' # West

---@param square IsoGridSquare
---@param dir direction
---@return IsoGridSquare
function GetAdjSquare(square, dir)
    if not square then return nil end
    local x, y, z = square:getX(), square:getY(), square:getZ()
    if dir == "N" then y = y - 1
    elseif dir == "E" then x = x + 1
    elseif dir == "S" then y = y + 1
    elseif dir == "W" then x = x - 1 end
    return getCell():getGridSquare(x, y, z)
end

function GetOutsideSquare(square, building)
    if not building or not square then return nil end
    if square:isOutside() then return square end
    for _, dir in ipairs({"N", "E", "S", "W"}) do
        local adj = GetAdjSquare(square, dir)
        if adj and adj:isOutside() then
            return adj
        end
    end
    return square
end

---@param fleeGuy IsoMovingObject
---@param attackGuy IsoMovingObject
---@param distanceToFlee number
---@return IsoGridSquare
function GetFleeSquare(fleeGuy, attackGuy, distanceToFlee)
    local distance = distanceToFlee or 7
    local xOffset = (fleeGuy:getX() > attackGuy:getX()) and distance or -distance
    local yOffset = (fleeGuy:getY() > attackGuy:getY()) and distance or -distance
    local x = fleeGuy:getX() + xOffset + ZombRand(-5, 5)
    local y = fleeGuy:getY() + yOffset + ZombRand(-5, 5)
    return fleeGuy:getCell():getGridSquare(x, y, fleeGuy:getZ())
end

function GetTowardsSquare(moveguy, x, y, z)
    local dx = x - moveguy:getX()
    local dy = y - moveguy:getY()
    dx = math.min(math.max(dx, -15), 15)
    dy = math.min(math.max(dy, -15), 15)
    local movex = moveguy:getX() + dx + ZombRand(-2, 2)
    local movey = moveguy:getY() + dy + ZombRand(-2, 2)
    return moveguy:getCell():getGridSquare(movex, movey, z)
end

function GetCoordsFromID(id)
    for k, v in pairs(SurvivorMap or {}) do
        for i = 1, #v do
            if v[i] == id then
                return k
            end
        end
    end
    return 0
end

function GetDistanceBetween(z1, z2)
    if not z1 or not z2 then return 1 end
    local dx = z1:getX() - z2:getX()
    local dy = z1:getY() - z2:getY()
    local dz = (z1:getZ() - z2:getZ()) * 2
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function GetDistanceBetweenPoints(Ax, Ay, Bx, By)
    if not Ax or not Bx then return -1 end
    local dx = Ax - Bx
    local dy = Ay - By
    return math.sqrt(dx * dx + dy * dy)
end

function IsSquareInArea(sq, area)
    if not sq or not area then return false end
    return sq:getX() > area[1] and sq:getX() <= area[2] and
           sq:getY() > area[3] and sq:getY() <= area[4] and
           sq:getZ() == area[5]
end

function GetCenterSquareFromArea(x1, x2, y1, y2, z)
    local x = x1 + math.floor((x2 - x1) / 2)
    local y = y1 + math.floor((y2 - y1) / 2)
    return getCell():getGridSquare(x, y, z)
end

function GetRandomAreaSquare(area)
    if not area then return nil end
    local x = ZombRand(area[1], area[2])
    local y = ZombRand(area[3], area[4])
    return getCell():getGridSquare(x, y, area[5])
end

local function getSquaresWindow(cs)
    if not cs then return nil end
    for i = 1, cs:getObjects():size() do
        local obj = cs:getObjects():get(i-1)
        if instanceof(obj, "IsoWindow") then
            return obj
        end
    end
    return nil
end

function GetSquaresNearWindow(cs)
    for _, dir in ipairs({"N", "E", "S", "W"}) do
        local square = GetAdjSquare(cs, dir)
        if square then
            local window = getSquaresWindow(square)
            if window then return window end
        end
    end
    return nil
end

function GetDoorsInsideSquare(door, player)
    if not door or not instanceof(door, "IsoDoor") then return nil end
    return door:getOtherSideOfDoor(player)
end
