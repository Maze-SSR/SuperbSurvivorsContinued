-- SuperSurvivorSpiralSearchUtilities.lua
-- Spiral search utility for square-based proximity scans (e.g., looting, spotting)

---@class SpiralSearch
---@field x integer
---@field y integer
---@field ix integer
---@field iy integer
---@field deltax integer
---@field deltay integer
---@field width integer
---@field height integer
SpiralSearch = {}
SpiralSearch.__index = SpiralSearch

---Create a new spiral search iterator centered at (x, y)
---@param x number
---@param y number
---@param range number
---@return SpiralSearch
function SpiralSearch:new(x, y, range)
    local o = setmetatable({}, self)

    o.x = math.floor(x)
    o.y = math.floor(y)
    o.ix = 0
    o.iy = 0
    o.deltax = 0
    o.deltay = -1
    o.width = range * 2
    o.height = range * 2

    return o
end

---Returns the current X coordinate of the spiral
---@return integer
function SpiralSearch:getX()
    return self.x + self.ix
end

---Returns the current Y coordinate of the spiral
---@return integer
function SpiralSearch:getY()
    return self.y + self.iy
end

---Returns the maximum number of iterations for the spiral
---@return integer
function SpiralSearch:forMax()
    return (math.max(self.width, self.height)) ^ 2
end

---Advances the spiral to the next coordinate
function SpiralSearch:next()
    -- Check if direction needs to change (based on diagonal/mirroring rule)
    if self.ix == self.iy or
       (self.ix < 0 and self.ix == -self.iy) or
       (self.ix > 0 and self.ix == 1 - self.iy) then

        -- Rotate direction clockwise
        local dx = -self.deltay
        local dy = self.deltax
        self.deltax = dx
        self.deltay = dy
    end

    -- Step to the next tile
    self.ix = self.ix + self.deltax
    self.iy = self.iy + self.deltay
end

