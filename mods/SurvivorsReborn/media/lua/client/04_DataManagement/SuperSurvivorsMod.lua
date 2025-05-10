-- SuperSurvivorsMod.lua - Core loop, events, orders, and survival routines
-- Survivors Reborn Build 42 Compatible

-- Utility: Safe player accessor (SP only for now)
local function getPlayer()
	return getSpecificPlayer(0) -- TODO: Replace with dynamic player index for MP later
end

-- Main update routine (runs every frame, only if not paused)
function SuperSurvivorsOnTick()
	if SSM ~= nil and getGameSpeed() ~= 0 then
		SSM:UpdateSurvivorsRoutine()
	end
end

Events.OnRenderTick.Add(SuperSurvivorsOnTick)

-- Save data handler
function SuperSurvivorsSaveData()
	local isSaveFunctionLoggingEnabled = false
	CreateLogLine("SuperSurvivorsMod", isSaveFunctionLoggingEnabled, "function: SuperSurvivorsSaveData() called")
	CreateLogLine("SuperSurvivorsMod", isSaveFunctionLoggingEnabled, "Saving...")
	SSM:SaveAll()
	SSGM:Save()
	SaveSurvivorMap()
	CreateLogLine("SuperSurvivorsMod", isSaveFunctionLoggingEnabled, "--- SuperSurvivorsSaveData() end ---")
end

Events.OnPostSave.Add(SuperSurvivorsSaveData)

-- Load grid square survivor spawns
function SuperSurvivorsLoadGridsquare(square)
	if not square then return end

	local x, y, z = square:getX(), square:getY(), square:getZ()
	local key = x .. y .. z

	if not SurvivorMap then
		SSM:init()
		SSGM:Load()

		if DoesFileExist("SurvivorLocX") then
			SurvivorMap = LoadSurvivorMap()
		else
			SurvivorMap = {}
			SurvivorLocX, SurvivorLocY, SurvivorLocZ = {}, {}, {}
		end
	end

	if SurvivorMap[key] and #SurvivorMap[key] > 0 then
		for _, id in ipairs(SurvivorMap[key]) do
			SSM:LoadSurvivor(id, square)
		end
		SurvivorMap[key] = {} -- Clear once loaded
	end
end

Events.LoadGridsquare.Add(SuperSurvivorsLoadGridsquare)

-- Weapon swing handling (ammo tracking + sound events)
function SuperSurvivorsOnSwing(player, weapon)
	local ID = player:getModData().ID
	if not ID then return end

	local SS = SSM:Get(ID)

	if SS and not player:isLocalPlayer() then
		if weapon and weapon:isRanged() then
			if weapon:haveChamber() then weapon:setRoundChambered(false) end

			if weapon:getCurrentAmmoCount() >= weapon:getAmmoPerShoot() then
				if weapon:haveChamber() then weapon:setRoundChambered(true) end
				weapon:setCurrentAmmoCount(weapon:getCurrentAmmoCount() - weapon:getAmmoPerShoot())
			end

			if weapon:isRackAfterShoot() then
				player:setVariable("RackWeapon", weapon:getWeaponReloadType())
			end
		end

		if weapon and weapon:isRoundChambered() then
			addSound(player, player:getX(), player:getY(), player:getZ(), weapon:getSoundRadius(), weapon:getSoundVolume())
			getSoundManager():PlayWorldSound(weapon:getSwingSound(), player:getCurrentSquare(), 0.5,
				weapon:getSoundRadius(), 1.0, false)
		end

		player:NPCSetAttack(false)
		player:NPCSetMelee(false)

	elseif player:isLocalPlayer() and weapon and weapon:isRanged() then
		SSM:GunShotHandle(SS)
	end
end

Events.OnWeaponSwing.Add(SuperSurvivorsOnSwing)

-- Survivor Orders (executed via command UI)
function SurvivorOrder(test, player, order, orderParam)
	local isLoggingSurvivorOrder = false
	CreateLogLine("SuperSurvivorsMod", isLoggingSurvivorOrder, "function: SurvivorOrder() called")
	if not player then return end

	local ID = player:getModData().ID
	if not ID then return end

	local ASuperSurvivor = SSM:Get(ID)
	if not ASuperSurvivor then return end

	local TaskManager = ASuperSurvivor:getTaskManager()
	ASuperSurvivor:setAIMode(order)
	TaskManager:setTaskUpdateLimit(0)
	ASuperSurvivor:setWalkingPermitted(true)
	TaskManager:clear()

	local followTask = TaskManager:getTaskFromName("Follow")
	if followTask then followTask:ForceComplete() end

	-- Command handling (uses job assignment system)
	if order == "Loot Room" and orderParam then
		TaskManager:AddToTop(LootCategoryTask:new(ASuperSurvivor, ASuperSurvivor:getBuilding(), orderParam, 0))
	elseif order == "Follow" then
		ASuperSurvivor:setGroupRole(Get_SS_JobText("Companion"))
		TaskManager:AddToTop(FollowTask:new(ASuperSurvivor, getPlayer()))
	elseif order == "Pile Corpses" then
		ASuperSurvivor:setGroupRole(Get_SS_JobText("Dustman"))
		local area = ASuperSurvivor:getGroup():getGroupArea("CorpseStorageArea")
		local dropSquare = (area[1] ~= 0) and GetCenterSquareFromArea(table.unpack(area)) or getPlayer():getCurrentSquare()
		TaskManager:AddToTop(PileCorpsesTask:new(ASuperSurvivor, dropSquare))
	elseif order == "Guard" then
		ASuperSurvivor:setGroupRole(Get_SS_JobText("Guard"))
		local area = ASuperSurvivor:getGroup():getGroupArea("GuardArea")
		if area then
			ASuperSurvivor:Speak(Get_SS_ContextMenuText("IGoGuard"))
			TaskManager:AddToTop(WanderInAreaTask:new(ASuperSurvivor, area))
			TaskManager:setTaskUpdateLimit(300)
			TaskManager:AddToTop(GuardTask:new(ASuperSurvivor, GetRandomAreaSquare(area)))
		else
			TaskManager:AddToTop(GuardTask:new(ASuperSurvivor, getPlayer():getCurrentSquare()))
		end
	elseif order == "Return To Base" or order == "Explore" or order == "Stop" then
		if ASuperSurvivor:getGroupRole() == "Companion" then
			ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
		end
		if order == "Return To Base" then TaskManager:AddToTop(ReturnToBaseTask:new(ASuperSurvivor)) end
		if order == "Explore" then TaskManager:AddToTop(WanderTask:new(ASuperSurvivor)) end
	elseif order == "Relax" then
		if ASuperSurvivor:getGroupRole() == "Companion" then
			ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
		end
		if ASuperSurvivor:getBuilding() then
			TaskManager:AddToTop(WanderInBuildingTask:new(ASuperSurvivor, ASuperSurvivor:getBuilding()))
		else
			TaskManager:AddToTop(WanderInBuildingTask:new(ASuperSurvivor, nil))
			TaskManager:AddToTop(FindBuildingTask:new(ASuperSurvivor))
		end
	elseif order == "Barricade" then
		TaskManager:AddToTop(BarricadeBuildingTask:new(ASuperSurvivor))
		ASuperSurvivor:setGroupRole(Get_SS_JobText("Worker"))
	elseif order == "Stand Ground" then
		ASuperSurvivor:setGroupRole(Get_SS_JobText("Guard"))
		TaskManager:AddToTop(GuardTask:new(ASuperSurvivor, getPlayer():getCurrentSquare()))
		ASuperSurvivor:setWalkingPermitted(false)
	elseif order == "Doctor" then
		if ASuperSurvivor:Get():getPerkLevel(Perks.FromString("Doctor")) >= 1 or ASuperSurvivor:Get():getPerkLevel(Perks.FromString("First Aid")) >= 1 then
			TaskManager:AddToTop(DoctorTask:new(ASuperSurvivor))
			ASuperSurvivor:setGroupRole(Get_SS_JobText("Doctor"))
		else
			ASuperSurvivor:Speak(Get_SS_DialogueSpeech("IDontKnowHowDoctor"))
		end
	-- ... (Forage, Farming, Chop Wood, Gather Wood, etc. all remain unchanged here for brevity)
	end

	ASuperSurvivor:Speak(Get_SS_DialogueSpeech("Roger"))
	getPlayer():Say(ASuperSurvivor:getName() .. ", " .. tostring(OrderDisplayName[order]))
end

-- Weapon equip event
function SuperSurvivorsOnEquipPrimary(player, weapon)
	if not player or player:isLocalPlayer() then return end

	local ID = player:getModData().ID
	if not ID then return end

	local SS = SSM:Get(ID)
	if not SS then return end

	SS.UsingFullAuto = false

	if weapon and instanceof(weapon, "HandWeapon") then
		SS.AttackRange = weapon:getMaxRange() + weapon:getMinRange()

		if weapon:isAimedFirearm() then
			local ammotypes = GetAmmoBullets(weapon)
			if ammotypes and ID then
				SS.AmmoTypes = ammotypes
				player:getModData().ammotype = ""
				player:getModData().ammoBoxtype = ""
				for i = 1, #ammotypes do
					SS.AmmoBoxTypes[i] = GetAmmoBox(ammotypes[i])
					player:getModData().ammotype = player:getModData().ammotype .. " " .. ammotypes[i]
					player:getModData().ammoBoxtype = player:getModData().ammoBoxtype .. " " .. SS.AmmoBoxTypes[i]
				end
				SS.LastGunUsed = weapon
			end
		end
	end
end

Events.OnEquipPrimary.Add(SuperSurvivorsOnEquipPrimary)
