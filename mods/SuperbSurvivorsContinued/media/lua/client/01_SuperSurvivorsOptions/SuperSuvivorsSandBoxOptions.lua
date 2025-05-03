-- SSConfig holds sandbox options safely to avoid global pollution
SSConfig = {}

-- Default fallback values in case SandboxVars are missing or incomplete
local defaultOptions = {
    Max_Group_Size = 4,
    Limit_Npc_Groups = 8,
    Limit_Npcs_Spawn = 22,
    Perk_Level = 0,
    IsWifeSpawn = true,
    WifeCount = 1,
    WifeIsFemale = true,
    NpcGroupsSpawnsSize = 4,
    NpcSpawnChance = 50,
    HostileSpawnRateBase = 1,
    HostileSpawnRateMax = 10,
    RaidersSpawnChance = 50,
    RaidersStartAfterHours = 0,
    CanIdleChat = false,
    CanNpcsCreateBase = false,
    IsInfiniteAmmoEnabled = true,
    IsRoleplayEnabled = false,
    IsSpeakEnabled = true,
    SurvivorCanFindWork = true,
    SurvivorNeedsFoodWater = false,
    SurvivorBravery = 6,
    SurvivorFriendliness = 10,
    SleepGeneralHealRate = 5,
    GFollowDistance = 5,
    PanicDistance = 21,
    WepSpawnRateGun = 50,
    WepSpawnRateMelee = 100,
    IsPlayerBaseSafe = true,
    IsPVPEnabled = true,
    IsDisplayingNpcName = true,
    IsDisplayingHostileColor = true,
}

local function Load_SandboxOptions()
    local vars = SandboxVars and SandboxVars.SuperbSurvivorsContinued
    if not vars then
        print("[SuperbSurvivors] Warning: SandboxVars.SuperbSurvivorsContinued not found. Using default options.")
        vars = {}
    end

    for key, default in pairs(defaultOptions) do
        SSConfig[key] = vars[key] ~= nil and vars[key] or default
    end

    print("[SuperbSurvivors] Sandbox options loaded successfully.")
end

-- B42+ correct event hook
Events.OnSandboxOptionsLoaded.Add(Load_SandboxOptions)