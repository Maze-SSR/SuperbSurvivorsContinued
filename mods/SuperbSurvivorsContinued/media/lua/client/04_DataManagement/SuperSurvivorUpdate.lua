local isLocalLoggingEnabled = false

-- Handles survivor death event
function SuperSurvivorOnDeath(player)
	if not player then return end
	local id = player:getModData().ID
	if id then
		local SS = SSM:Get(id)
		if SS then
			SS:OnDeath()
		end
	end
end

-- Per-frame player update for active survivors
function SuperSurvivorGlobalUpdate(player)
	CreateLogLine("SuperSurvivorUpdate", isLocalLoggingEnabled, "function: SuperSurvivorGlobalUpdate() called")
	if not player then return end
	local id = player:getModData().ID
	if id then
		local SS = SSM:Get(id)
		if SS then SS:PlayerUpdate() end
	end
end

-- Returns a wounded body part to apply damage
local function getGunShotWoundBP(player)
	if not instanceof(player, "IsoPlayer") then return nil end

	local bps = player:getBodyDamage():getBodyParts()
	local list = {}
	for i = 0, bps:size() - 1 do
		local bp = bps:get(i)
		if bp and bp:HasInjury() and bp:getHealth() > 0 then
			table.insert(list, i)
		end
	end

	if #list == 0 then return nil end
	local index = list[ZombRand(1, #list)]
	return bps:get(index)
end

-- Handles PvP or friendly-fire damage to survivors
function SuperSurvivorPVPHandle(wielder, victim, weapon, damage)
	if not wielder or not victim then return end

	local idW, idV = wielder:getModData().ID, victim:getModData().ID
	if not idW or not idV then return end

	local SSW, SSV = SSM:Get(idW), SSM:Get(idV)
	if not SSW or not SSV then return end

	local fakehit = false

	-- Prevent friendly fire
	if victim.setAvoidDamage and SSW:isInGroup(victim) then
		victim:setAvoidDamage(true)
		fakehit = true
	elseif victim.setNoDamage then
		if SSW:isInGroup(victim) then
			victim:setNoDamage(true)
			fakehit = true
		else
			victim:setNoDamage(false)
		end
	end

	if fakehit then return false end

	-- Extra damage logic
	local bodyPart = getGunShotWoundBP(victim)
	if bodyPart and SSV:getID() ~= 0 then
		bodyPart:AddDamage(100)
		bodyPart:DamageUpdate()
		victim:getBodyDamage():DamageFromWeapon(weapon)
		victim:update()
	end

	-- Handle group reaction
	if instanceof(victim, "IsoPlayer") then
		local groupID = SSV:getGroupID()
		if groupID then
			local group = SSGM:GetGroupById(groupID)
			if group then
				group:PVPAlert(wielder)
			end
		else
			victim:getModData().hitByCharacter = true
		end

		-- Handle melee animation hitback
		if weapon and not weapon:isAimedFirearm() and weapon:getPushBackMod() > 0.3 then
			victim:StopAllActionQueue()
			local dot = victim:getDotWithForwardDirection(wielder:getX(), wielder:getY())
			if dot < 0 then
				ISTimedActionQueue.add(ISGetHitFromBehindAction:new(victim, wielder))
			elseif dot > 0 then
				ISTimedActionQueue.add(ISGetHitFromFrontAction:new(victim, wielder))
			end
		end

		-- Flag attacker as semi-hostile
		wielder:getModData().semiHostile = true

		-- If victim surrendered and attacker used firearm — instant execution
		if victim:getModData().surender and weapon and weapon:isRanged() then
			for _, part in ipairs({ BodyPartType.Head, BodyPartType.Torso_Upper, BodyPartType.Hand_L, BodyPartType.UpperLeg_R }) do
				victim:getBodyDamage():getBodyPart(part):AddDamage(500)
			end
			victim:getBodyDamage():Update()
			SSM:PublicExecution(SSW, SSV)
		end

		-- Apply random wounds to NPC victim
		if instanceof(wielder, "IsoPlayer") and not victim:isLocalPlayer() then
			if weapon:getType() == "BareHands" then return end

			local bindex = ZombRand(BodyPartType.Hand_L:index(), BodyPartType.MAX:index())
			local bodydamage = victim:getBodyDamage()
			local bodypart = bodydamage:getBodyPart(BodyPartType.FromIndex(bindex))
			local stats = victim:getStats()

			local isBlunt = weapon:getCategories():contains("Blunt") or weapon:getCategories():contains("SmallBlunt")
			local isSharp = not weapon:isAimedFirearm()
			local isBullet = weapon:isAimedFirearm()

			local blocked = ZombRand(0, 100) < victim:getBodyPartClothingDefense(bindex, isSharp, isBullet)
			if blocked then return end

			victim:addHole(BloodBodyPartType.FromIndex(bindex))

			if isSharp then
				local roll = ZombRand(0, 6)
				if roll == 6 then
					bodypart:generateDeepWound()
				elseif roll == 3 then
					bodypart:setCut(true)
				else
					bodypart:setScratched(true, true)
				end
			elseif isBlunt then
				local roll = ZombRand(0, 4)
				if roll == 4 then
					bodypart:setCut(true)
				else
					bodypart:setScratched(true, true)
				end
			elseif isBullet then
				bodypart:setHaveBullet(true, 0)
			end

			-- Apply scaled damage
			local baseDamage = ZombRand(weapon:getMinDamage(), weapon:getMaxDamage()) * 15.0
			if bindex == BodyPartType.Head:index() or bindex == BodyPartType.Neck:index() then
				baseDamage = baseDamage * 4.0
			elseif bindex == BodyPartType.Torso_Upper:index() then
				baseDamage = baseDamage * 2.0
			end
			bodydamage:AddDamage(bindex, baseDamage)

			-- Add pain
			local painType = 1 -- Default: scratch
			if isBlunt then painType = 0 elseif isBullet then painType = 2 end
			local modifier = BodyPartType.getPainModifyer(bindex)
			local painAmount = 0

			if painType == 0 then
				painAmount = bodydamage:getInitialThumpPain()
			elseif painType == 1 then
				painAmount = bodydamage:getInitialScratchPain()
			elseif painType == 2 then
				painAmount = bodydamage:getInitialBitePain()
			end

			stats:setPain(math.min(stats:getPain() + (painAmount * modifier), 100))
			SSV:NPCcalculateWalkSpeed()
		end
	end
end

-- Event bindings
Events.OnWeaponHitCharacter.Add(SuperSurvivorPVPHandle)
Events.OnPlayerUpdate.Add(SuperSurvivorGlobalUpdate)
Events.OnCharacterDeath.Add(SuperSurvivorOnDeath)
