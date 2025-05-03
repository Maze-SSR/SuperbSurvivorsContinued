-- OutfitManager.lua
-- Replaces SuperSurvivorSuits.lua with a modular, randomized outfit system

OutfitManager = {}

-- Utility: random element from a list
function ZombRandElement(list)
    if #list == 0 then return nil end
    return list[ZombRand(1, #list)]
end

-- Main outfit generator
function OutfitManager.getOutfit(outfitType)
    -- CIVILIAN
    if outfitType == "Civilian" then
        local outfit = {
            tops = { "Base.Tshirt_WhiteTINT", "Base.Shirt_Blue", "Base.Shirt_Red" },
            bottoms = { "Base.Trousers_DefaultTEXTURE_TINT", "Base.Shorts_LongSport" },
            footwear = { "Base.Shoes_Black", "Base.Sneakers_White" },
            jackets = { "Base.Jacket_Black", "Base.Jacket_ArmyCamo", "Base.JacketLong_Random" },
            weapons = { "Base.Pistol", "Base.DoubleBarrelShotgun" },
            ammo = { "Base.Bullets9mmBox", "Base.ShotgunShellsBox" },
        }
        return {
            top = ZombRandElement(outfit.tops),
            bottom = ZombRandElement(outfit.bottoms),
            shoes = ZombRandElement(outfit.footwear),
            jacket = ZombRandElement(outfit.jackets),
            weapon = ZombRandElement(outfit.weapons),
            ammo = ZombRandElement(outfit.ammo),
        }
    end

    -- VETERAN
    if outfitType == "Veteran" then
        return {
            top = "Base.Shirt_CamoGreen",
            bottom = "Base.Trousers_CamoGreen",
            shoes = "Base.Boots_Army",
            jacket = "Base.Jacket_ArmyCamo",
            weapon = "Base.AssaultRifle",
            ammo = "Base.556Box",
        }
    end

    -- DOCTOR
    if outfitType == "Doctor" then
        return {
            top = "Base.Shirt_White",
            bottom = "Base.Trousers_WhiteTINT",
            shoes = "Base.Shoes_Black",
            hat = "Base.Hat_SurgicalCap_Blue",
            mask = "Base.Hat_SurgicalMask_Blue",
            gloves = "Base.Gloves_Surgical",
            items = {
                "Base.Bandage", "Base.AlcoholWipes", "Base.Tweezers",
                "Base.SutureNeedle", "Base.Splint", "Base.CottonBalls"
            },
        }
    end

    -- NURSE
    if outfitType == "Nurse" then
        return {
            top = "Base.Shirt_White",
            bottom = "Base.Skirt_Long",
            shoes = "Base.Shoes_White",
            hat = "Base.Hat_SurgicalCap_Blue",
            mask = "Base.Hat_SurgicalMask_Blue",
            gloves = "Base.Gloves_Surgical",
            items = {
                "Base.Bandaid", "Base.AlcoholWipes", "Base.Tweezers",
                "Base.SutureNeedle", "Base.CottonBalls"
            },
        }
    end

    -- RAIDER
    if outfitType == "Raider" then
        local outfit = {
            tops = { "Base.Shirt_Black", "Base.Shirt_Rock", "Base.Tshirt_BandTINT" },
            bottoms = { "Base.Trousers_Denim", "Base.Trousers_Jeans" },
            footwear = { "Base.Boots_Riding", "Base.Shoes_BlackBoots" },
            jackets = { "Base.Jacket_LeatherIron", "Base.Jacket_Denim", "Base.Jacket_Black" },
            weapons = { "Base.Axe", "Base.Machete", "Base.ShotgunSawnoff", "Base.Pistol" },
            ammo = { "Base.ShotgunShellsBox", "Base.Bullets9mmBox" },
        }
        return {
            top = ZombRandElement(outfit.tops),
            bottom = ZombRandElement(outfit.bottoms),
            shoes = ZombRandElement(outfit.footwear),
            jacket = ZombRandElement(outfit.jackets),
            weapon = ZombRandElement(outfit.weapons),
            ammo = ZombRandElement(outfit.ammo),
        }
    end

    -- Fallback empty outfit
    return {}
end