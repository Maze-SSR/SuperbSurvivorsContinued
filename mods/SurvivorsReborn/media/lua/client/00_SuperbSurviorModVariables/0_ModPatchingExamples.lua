-- Cows: Thanks to albion#0123 for sharing this function.
-- This retrieves a list of ALL active mods the user currently has.
local activatedMods = getActivatedMods()

-- Cows: Check if active mod list includes a given ModID 
function CheckForMod(modID)
    return activatedMods:contains(modID)
end
