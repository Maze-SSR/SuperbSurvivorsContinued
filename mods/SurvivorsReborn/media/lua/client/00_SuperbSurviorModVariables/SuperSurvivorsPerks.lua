-- SuperSurvivorPerks.lua
-- Global list of Perks considered for survivor roles and behaviors

SurvivorPerks = {
    -- Combat Skills
    "Aiming",
    "Reloading",
    "Axe",
    "SmallBlade",
    "LongBlade",
    "SmallBlunt",
    "Blunt",
    "Spear",
    "Maintenance",

    -- Physical Skills
    "Strength",
    "Fitness",
    "Lightfoot",
    "Nimble",
    "Sneak",

    -- Survival & Scavenging
    "Foraging",             -- Renamed from PlantScavenging in B42
    "Trapping",
    "Fishing",
    "Survivalist",

    -- Crafting & Construction
    "Woodwork",             -- Carpentry
    "Cooking",
    "Tailoring",
    "MetalWelding",
    "Mechanics",
    "Electricity",

    -- Agriculture & Medical
    "Farming",
    "FirstAid",             -- B42-compatible version of "Doctor"
    "Doctor",               -- Keep legacy support if used elsewhere

    -- Social / Utility (for future dialogue or relationship systems)
    "Bartering",
    "Leadership"
}
