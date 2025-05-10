LMSConditions = {}
LMSConditions.MoodleTable = {}
LMSConditions.LowerMoodleTable = {}
LMSConditions.TimeOfRegister = nil

-- 🧠 In-game dialogue tables for boredom, stress, pain, etc.
LMSConditions.SlightlyBored = { "", "" }
LMSConditions.Bored = { "", "", "", "" }
LMSConditions.VeryBored = { "", "", "", "" }
LMSConditions.ExtremelyBored = { "", "", "", "" }
LMSConditions.SlightlyStressed = { "" }
LMSConditions.Stressed = { "" }
LMSConditions.VeryStressed = { "" }
LMSConditions.ExtremelyStressed = { "" }
LMSConditions.Zombie = { "", "" }

-- 💬 Pulls from shared SurvivorSpeechTable (assumed global)
LMSConditions.SlightlyPanicked = SurvivorSpeechTable and SurvivorSpeechTable["Panic"] or {}
LMSConditions.Panicked = SurvivorSpeechTable and SurvivorSpeechTable["Scared"] or {}
LMSConditions.VeryPanicked = SurvivorSpeechTable and SurvivorSpeechTable["Scared"] or {}
LMSConditions.ExtremelyPanicked = SurvivorSpeechTable and SurvivorSpeechTable["Scream"] or {}
LMSConditions.SlightlyPainful = SurvivorSpeechTable and SurvivorSpeechTable["Hurt"] or {}
LMSConditions.Painful = SurvivorSpeechTable and SurvivorSpeechTable["Injured"] or {}
LMSConditions.VeryPainful = SurvivorSpeechTable and SurvivorSpeechTable["Injured"] or {}
LMSConditions.ExtremelyPainful = SurvivorSpeechTable and SurvivorSpeechTable["BadInjured"] or {}

-- Campfire dialogue for immersion
LMSConditions.Campfire = {
	"*sings* Irene goodnight, Irene goodnight...",
	"*sings* Val-der-ri, val-der-ra...",
	"*sings* One bright day in the middle of the night...",
	"Drew their swords and shot each other...",
	"If you don’t believe this lie is true, Ask the blind man he saw too.",
	"*sings* Swing low, sweet chariot..."
}

-- All moodle keys supported
LMSConditions.LMSMoodles = {
	"Endurance", "Tired", "Hungry", "Panic", "Sick", "Bored",
	"Unhappy", "Bleeding", "Wet", "HasACold", "Angry", "Stress",
	"Thirst", "Injured", "Pain", "HeavyLoad", "Drunk", "Zombie",
	"Hyperthermia", "Hypothermia", "FoodEaten"
}

-- 🧠 Utility wrapper for SP player (TODO: MP player support)
local function getPlayer()
	return getSpecificPlayer(0)
end

-- 🛑 B42 fix: Replace unsafe loadstring with direct assignment
function LMSConditions.retrieveMoodles()
	local player = getPlayer()
	if not player then return end

	for i = 1, #LMSConditions.LMSMoodles do
		local moodleName = LMSConditions.LMSMoodles[i]
		if MoodleType[moodleName] then
			LMSConditions.MoodleTable[i] = player:getMoodles():getMoodleLevel(MoodleType[moodleName])
		end
	end
end

-- Called once at load
function LMSConditions.checkIfLoaded()
	local player = getPlayer()
	if not player then return end
	player:getMoodles():Update()
	LMSConditions.retrieveMoodles()
	Events.OnPlayerUpdate.Add(LMSConditions.checkForConditions)
end

-- Triggered on empty gun, etc.
function LMSConditions.checkIfAttacking(player, item)
	if not player or player:isLocalPlayer() then return end
	local weapon = player:getPrimaryHandItem()
	if weapon and weapon:isRanged() and weapon:getModData().currentCapacity == 0 then
		LMSConditions.generateRandomNumber(player, SurvivorSpeechTable["OutOfAmmo"])
	end
end

-- Picks and triggers a line of speech
function LMSConditions.generateRandomNumber(player, conditionTable, optionalNumber)
	if not conditionTable then return end
	local randIndex = ZombRand(#conditionTable) + 1
	local name = player:getModData().Name or ""
	local ID = player:getModData().ID
	local SS = SSM:Get(ID)
	if SS then
		SS:Speak(conditionTable[randIndex])
	end
end

-- Stores spoken levels to avoid repeating moodle chatter
Speech = {}
SpeechLevel = {}

function LMSConditions.doMoodleCheck(player, LMSMoodleLevel, LMSMoodleType, conditionTable, indexNumber)
	if not player then return end
	local SID = player:getModData().ID
	if not SID then return end
	local SS = SSM:Get(SID)
	if not SS or SS:isSpeaking() then return end

	if MoodleType.Panic == LMSMoodleType and player:getVehicle() then return end

	Speech[SID] = Speech[SID] or {}
	SpeechLevel[SID] = SpeechLevel[SID] or {}

	local currentLevel = player:getMoodles():getMoodleLevel(LMSMoodleType)

	if Speech[SID][LMSMoodleType] ~= LMSMoodleType or SpeechLevel[SID][LMSMoodleType] ~= currentLevel then
		if not SpeechLevel[SID][LMSMoodleType] or currentLevel > SpeechLevel[SID][LMSMoodleType] then
			LMSConditions.generateRandomNumber(player, conditionTable)
		end
		Speech[SID][LMSMoodleType] = LMSMoodleType
		SpeechLevel[SID][LMSMoodleType] = currentLevel
	end
end

-- Core condition checker
function LMSConditions.checkForConditions(player)
	if not player or player:isLocalPlayer() then return end

	-- Sick
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Sick, SurvivorSpeechTable["Sick"], 3)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Sick, SurvivorSpeechTable["VSick"], 3)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Sick, SurvivorSpeechTable["SSick"], 3)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Sick, SurvivorSpeechTable["SSick"], 3)

	-- Hunger
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Hungry, SurvivorSpeechTable["Hungry"], 3)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Hungry, SurvivorSpeechTable["VHungry"], 3)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Hungry, SurvivorSpeechTable["Starving"], 3)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Hungry, SurvivorSpeechTable["Starving"], 3)

	-- Thirst
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Thirst, SurvivorSpeechTable["Thirsty"], 13)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Thirst, SurvivorSpeechTable["Thirsty"], 13)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Thirst, SurvivorSpeechTable["VThirsty"], 13)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Thirst, SurvivorSpeechTable["SThirsty"], 13)

	-- Tired
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Tired, SurvivorSpeechTable["Tired"], 2)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Tired, SurvivorSpeechTable["Tired"], 2)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Tired, SurvivorSpeechTable["VTired"], 2)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Tired, SurvivorSpeechTable["STired"], 2)

	-- Boredom
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Bored, LMSConditions.SlightlyBored, 6)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Bored, LMSConditions.Bored, 6)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Bored, LMSConditions.VeryBored, 6)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Bored, LMSConditions.ExtremelyBored, 6)

	-- Stress
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Stress, LMSConditions.SlightlyStressed, 12)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Stress, LMSConditions.Stressed, 12)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Stress, LMSConditions.VeryStressed, 12)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Stress, LMSConditions.ExtremelyStressed, 12)

	-- Panic
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Panic, LMSConditions.SlightlyPanicked, 4)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Panic, LMSConditions.Panicked, 4)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Panic, LMSConditions.VeryPanicked, 4)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Panic, LMSConditions.ExtremelyPanicked, 4)

	-- Zombification
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Zombie, LMSConditions.Zombie, 18)

	-- Pain
	LMSConditions.doMoodleCheck(player, 1, MoodleType.Pain, LMSConditions.SlightlyPainful, 15)
	LMSConditions.doMoodleCheck(player, 2, MoodleType.Pain, LMSConditions.Painful, 15)
	LMSConditions.doMoodleCheck(player, 3, MoodleType.Pain, LMSConditions.VeryPainful, 15)
	LMSConditions.doMoodleCheck(player, 4, MoodleType.Pain, LMSConditions.ExtremelyPainful, 15)
end

Events.OnLoad.Add(LMSConditions.checkIfLoaded)
-- Events.OnWeaponSwing.Add(LMSConditions.checkIfAttacking) -- Optional: for empty gun feedback
