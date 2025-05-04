require "04_Group.SuperSurvivorManager" -- TODO: Eventually remove dependency on global SSM

SuperSurvivorGroup = {}
SuperSurvivorGroup.__index = SuperSurvivorGroup

local isLocalLoggingEnabled = false

function SuperSurvivorGroup:new(GID)
	local o = setmetatable({}, self)

	o.ROE = 3 -- Rules of Engagement
	o.YouBeenWarned = {}
	o.ID = GID
	o.Leader = -1
	o.Members = {}
	o.Bounds = { 0, 0, 0, 0, 0 }

	o.GroupAreas = {
		ChopTreeArea = { 0, 0, 0, 0, 0 },
		TakeCorpseArea = { 0, 0, 0, 0, 0 },
		TakeWoodArea = { 0, 0, 0, 0, 0 },
		FarmingArea = { 0, 0, 0, 0, 0 },
		ForageArea = { 0, 0, 0, 0, 0 },
		CorpseStorageArea = { 0, 0, 0, 0, 0 },
		FoodStorageArea = { 0, 0, 0, 0, 0 },
		WoodStorageArea = { 0, 0, 0, 0, 0 },
		ToolStorageArea = { 0, 0, 0, 0, 0 },
		WeaponStorageArea = { 0, 0, 0, 0, 0 },
		MedicalStorageArea = { 0, 0, 0, 0, 0 },
		GuardArea = { 0, 0, 0, 0, 0 },
	}

	return o
end

function SuperSurvivorGroup:setROE(value)
	self.ROE = value
end

function SuperSurvivorGroup:getFollowCount()
	local count = 0
	for _, memberID in ipairs(self.Members) do
		local member = SSM:Get(memberID)
		if member and member.getCurrentTask and member:getCurrentTask() == "Follow" then
			count = count + 1
		end
	end
	return count
end

function SuperSurvivorGroup:isEnemy(SS, character)
	if character:isZombie() then return true end
	if SS:isInGroup(character) then return false end
	if not SS.player:getModData().isHostile and character:getModData().surender then return false end
	if SS.player:getModData().hitByCharacter and character:getModData().semiHostile then return true end
	if character:getModData().isHostile ~= SS.player:getModData().isHostile then return true end
	if self.ROE == 4 then return true end
	return false
end

function SuperSurvivorGroup:UseWeaponType(weaponType)
	for _, memberID in ipairs(self.Members) do
		local member = SSM:Get(memberID)
		if member then
			if weaponType == "gun" and member.reEquipGun then
				member:reEquipGun()
			elseif member.reEquipMele then
				member:reEquipMele()
			end
		end
	end
end

function SuperSurvivorGroup:getGroupArea(areaName)
	return self.GroupAreas[areaName]
end

function SuperSurvivorGroup:getGroupAreaCenterSquare(areaName)
	local area = self.GroupAreas[areaName]
	if area[1] ~= 0 then
		return GetCenterSquareFromArea(area[1], area[2], area[3], area[4], area[5])
	end
	return nil
end

function SuperSurvivorGroup:isGroupAreaSet(areaName)
	return self.GroupAreas[areaName][1] ~= 0
end

function SuperSurvivorGroup:getClosestIdleMember(ofThisRole, referencePoint)
    CreateLogLine("SuperSurvivorGroup", isLocalLoggingEnabled, "function: getClosestIdleMember() called")
    local closestSoFar = 999
    local closestID = -1

    for _, workingID in ipairs(self.Members) do
        local survivor = SSM:Get(workingID)
        if survivor then
            local distance = GetDistanceBetween(survivor:Get(), referencePoint)
            local isIdle = not survivor:isInAction()
            local matchesRole = (ofThisRole == "Any" or ofThisRole == nil or survivor:getGroupRole() == ofThisRole)

            if isIdle and distance > 0 and distance < closestSoFar and matchesRole then
                closestID = workingID
                closestSoFar = distance
            end
        end
    end

    return closestID
end

function SuperSurvivorGroup:addMember(memberID)
    if not self:hasMember(memberID) then
        table.insert(self.Members, memberID)
        local survivor = SSM:Get(memberID)
        if survivor then
            survivor:setGroupID(self.ID)
            survivor:setGroupRole(Get_SS_UIActionText("Job_Worker"))
        end
    end
end

function SuperSurvivorGroup:removeMember(memberID)
    for index, id in ipairs(self.Members) do
        if id == memberID then
            table.remove(self.Members, index)
            local survivor = SSM:Get(memberID)
            if survivor then
                survivor:setGroupID(-1)
                survivor:setGroupRole(Get_SS_UIActionText("Job_None"))
            end
            break
        end
    end
end

function SuperSurvivorGroup:hasMember(memberID)
    for _, id in ipairs(self.Members) do
        if id == memberID then return true end
    end
    return false
end

function SuperSurvivorGroup:getMembers()
    return self.Members
end

function SuperSurvivorGroup:clearMembers()
    for _, id in ipairs(self.Members) do
        local survivor = SSM:Get(id)
        if survivor then
            survivor:setGroupID(-1)
            survivor:setGroupRole(Get_SS_UIActionText("Job_None"))
        end
    end
    self.Members = {}
end

function SuperSurvivorGroup:countRole(role)
    local count = 0
    for _, id in ipairs(self.Members) do
        local survivor = SSM:Get(id)
        if survivor and survivor:getGroupRole() == role then
            count = count + 1
        end
    end
    return count
end

function SuperSurvivorGroup:getRandomMember()
    if #self.Members == 0 then return nil end
    local randomIndex = ZombRand(1, #self.Members + 1)
    return self.Members[randomIndex]
end

function SuperSurvivorGroup:findMemberWithTag(tag)
	for i = 1, #self.Members do
		local member = self.Members[i]
		if member:getCurrentTask() == tag then
			return member
		end
	end
	return nil
end

function SuperSurvivorGroup:findMemberWithTask(taskName)
	for i = 1, #self.Members do
		local member = self.Members[i]
		if member:getCurrentTask() == taskName then
			return member
		end
	end
	return nil
end

function SuperSurvivorGroup:findRandomMember()
	if #self.Members == 0 then return nil end
	return self.Members[ZombRand(1, #self.Members + 1)]
end

function SuperSurvivorGroup:findClosestMemberToPlayer()
	local closestMember = nil
	local closestDistance = math.huge
	local player = getSpecificPlayer(self.playerID)
	if not player then return nil end

	for i = 1, #self.Members do
		local member = self.Members[i]
		if member:IsInAction() == false then
			local dist = getDistanceBetween(member:Get(), player)
			if dist < closestDistance then
				closestDistance = dist
				closestMember = member
			end
		end
	end

	return closestMember
end

function SuperSurvivorGroup:setLeader(newLeader)
	if not newLeader then return end
	self.Leader = newLeader
end

function SuperSurvivorGroup:getLeader()
	return self.Leader
end

function SuperSurvivorGroup:hasLeader()
	return self.Leader ~= nil
end

function SuperSurvivorGroup:setGroupRole(member, role)
	if not member or not role then return end
	member:setGroupRole(role)
end

function SuperSurvivorGroup:getGroupRoleCount(role)
	local count = 0
	for i = 1, #self.Members do
		if self.Members[i]:getGroupRole() == role then
			count = count + 1
		end
	end
	return count
end

function SuperSurvivorGroup:getMemberWithRole(role)
	for i = 1, #self.Members do
		if self.Members[i]:getGroupRole() == role then
			return self.Members[i]
		end
	end
	return nil
end

function SuperSurvivorGroup:hasMemberWithRole(role)
	return self:getMemberWithRole(role) ~= nil
end

function SuperSurvivorGroup:setGroupID(id)
	self.GroupID = id
end

function SuperSurvivorGroup:getGroupID()
	return self.GroupID
end

function SuperSurvivorGroup:setGroupName(name)
	self.GroupName = name
end

function SuperSurvivorGroup:getGroupName()
	return self.GroupName
end

function SuperSurvivorGroup:addEnemy(enemy)
	if not enemy or self:IsMember(enemy) then return false end

	local enemyID = enemy:getID()
	if not self.Enemies[enemyID] then
		self.Enemies[enemyID] = enemy
		return true
	end
	return false
end

function SuperSurvivorGroup:removeEnemy(enemy)
	if not enemy then return false end
	local enemyID = enemy:getID()
	if self.Enemies[enemyID] then
		self.Enemies[enemyID] = nil
		return true
	end
	return false
end

function SuperSurvivorGroup:getEnemies()
	return self.Enemies
end

function SuperSurvivorGroup:clearEnemies()
	self.Enemies = {}
end

function SuperSurvivorGroup:hasEnemy(enemy)
	if not enemy then return false end
	local enemyID = enemy:getID()
	return self.Enemies[enemyID] ~= nil
end

function SuperSurvivorGroup:getClosestEnemyToMember(member)
	if not member then return nil end

	local closestEnemy = nil
	local closestDist = math.huge
	for _, enemy in pairs(self.Enemies) do
		local dist = getDistanceBetween(member:Get(), enemy)
		if dist < closestDist then
			closestDist = dist
			closestEnemy = enemy
		end
	end

	return closestEnemy
end

function SuperSurvivorGroup:addDangerArea(square, threatLevel)
	if not square then return end
	local key = square:getX() .. "," .. square:getY() .. "," .. square:getZ()
	self.DangerZones[key] = {
		square = square,
		level = threatLevel or 1,
		timestamp = getTimestamp()
	}
end

function SuperSurvivorGroup:getDangerAtSquare(square)
	if not square then return 0 end
	local key = square:getX() .. "," .. square:getY() .. "," .. square:getZ()
	local danger = self.DangerZones[key]
	if danger then return danger.level or 1 else return 0 end
end

function SuperSurvivorGroup:clearDangerZones()
	self.DangerZones = {}
end

function SuperSurvivorGroup:addLootingZone(name, zoneData)
	if not name or not zoneData then return end
	self.LootingZones[name] = zoneData
end

function SuperSurvivorGroup:getLootingZone(name)
	return self.LootingZones[name]
end

function SuperSurvivorGroup:removeLootingZone(name)
	self.LootingZones[name] = nil
end

function SuperSurvivorGroup:getAllLootingZones()
	return self.LootingZones
end

function SuperSurvivorGroup:clearLootingZones()
	self.LootingZones = {}
end

function SuperSurvivorGroup:setGroupTarget(square)
	if not square then return end
	self.TargetSquare = square
end

function SuperSurvivorGroup:getGroupTarget()
	return self.TargetSquare
end

function SuperSurvivorGroup:clearGroupTarget()
	self.TargetSquare = nil
end

function SuperSurvivorGroup:setGroupTargetBuilding(building)
	if building then
		self.TargetBuilding = building
	end
end

function SuperSurvivorGroup:getGroupTargetBuilding()
	return self.TargetBuilding
end

function SuperSurvivorGroup:clearGroupTargetBuilding()
	self.TargetBuilding = nil
end

function SuperSurvivorGroup:setGroupTargetRoom(room)
	if room then
		self.TargetRoom = room
	end
end

function SuperSurvivorGroup:getGroupTargetRoom()
	return self.TargetRoom
end

function SuperSurvivorGroup:clearGroupTargetRoom()
	self.TargetRoom = nil
end

function SuperSurvivorGroup:setLeaderTargetSquare(square)
	if not square then return end
	local leader = self:getLeader()
	if leader then
		leader:SetAIMode("Goto")
		leader.TargetSquare = square
	end
end

function SuperSurvivorGroup:leaderHasTarget()
	local leader = self:getLeader()
	return leader and leader.TargetSquare ~= nil
end

function SuperSurvivorGroup:setLeaderAIMode(mode)
	local leader = self:getLeader()
	if leader and mode then
		leader:SetAIMode(mode)
	end
end

function SuperSurvivorGroup:getFollowers()
	local followers = {}
	for id, member in pairs(self.Members) do
		if not member:IsLeader() then
			table.insert(followers, member)
		end
	end
	return followers
end

function SuperSurvivorGroup:sendFollowersToSquare(square)
	if not square then return end
	for _, follower in pairs(self:getFollowers()) do
		follower:SetAIMode("Goto")
		follower.TargetSquare = square
	end
end

function SuperSurvivorGroup:sendFollowersToBuilding(building)
	if not building then return end
	for _, follower in pairs(self:getFollowers()) do
		follower:MarkBuildingExplored(building, false)
		follower:GoToBuilding(building)
	end
end

function SuperSurvivorGroup:sendFollowersToRoom(room)
	if not room then return end
	for _, follower in pairs(self:getFollowers()) do
		follower:GoToRoom(room)
	end
end

-- ========== Group Memory and Known Buildings ==========

function SuperSurvivorGroup:addKnownBuilding(building)
	if not building or not building:getID() then return end
	local id = building:getID()
	self.KnownBuildings = self.KnownBuildings or {}
	self.KnownBuildings[id] = building
end

function SuperSurvivorGroup:hasSeenBuilding(building)
	if not building or not building:getID() then return false end
	return self.KnownBuildings and self.KnownBuildings[building:getID()] ~= nil
end

function SuperSurvivorGroup:getKnownBuildings()
	return self.KnownBuildings or {}
end

function SuperSurvivorGroup:clearKnownBuildings()
	self.KnownBuildings = {}
end

-- ========== Area Safety and Visited Tracking ==========

function SuperSurvivorGroup:setAreaSafe(square)
	if not square then return end
	local key = tostring(square:getX()) .. "_" .. tostring(square:getY())
	self.SafeAreas = self.SafeAreas or {}
	self.SafeAreas[key] = true
end

function SuperSurvivorGroup:isAreaSafe(square)
	if not square then return false end
	local key = tostring(square:getX()) .. "_" .. tostring(square:getY())
	return self.SafeAreas and self.SafeAreas[key] == true
end

function SuperSurvivorGroup:setRoomVisited(roomDef)
	if not roomDef then return end
	local key = roomDef:getName() .. "_" .. roomDef:getBuilding():getID()
	self.VisitedRooms = self.VisitedRooms or {}
	self.VisitedRooms[key] = true
end

function SuperSurvivorGroup:hasVisitedRoom(roomDef)
	if not roomDef then return false end
	local key = roomDef:getName() .. "_" .. roomDef:getBuilding():getID()
	return self.VisitedRooms and self.VisitedRooms[key] == true
end

-- ========== Shared Group Tasks ==========

function SuperSurvivorGroup:broadcastTask(taskName, taskData)
	for _, member in pairs(self.Members) do
		if member and member:IsInGroup() then
			member:AssignSharedTask(taskName, taskData)
		end
	end
end

function SuperSurvivorGroup:cancelAllTasks()
	for _, member in pairs(self.Members) do
		if member and member:IsInGroup() then
			member:ClearTaskQueue()
		end
	end
end

function SuperSurvivorGroup:everyoneGoTo(square)
	if not square then return end
	for _, member in pairs(self.Members) do
		if member and member:IsInGroup() then
			member:SetAIMode("Goto")
			member.TargetSquare = square
		end
	end
end

-- ========== Raider and Hostile Group Handling ==========

function SuperSurvivorGroup:isHostileTo(otherGroup)
	if not otherGroup or not otherGroup.GroupID then return false end
	return self.Enemies and self.Enemies[otherGroup.GroupID] == true
end

function SuperSurvivorGroup:addEnemyGroup(otherGroup)
	if not otherGroup or not otherGroup.GroupID then return end
	self.Enemies = self.Enemies or {}
	self.Enemies[otherGroup.GroupID] = true
end

function SuperSurvivorGroup:removeEnemyGroup(otherGroup)
	if not otherGroup or not otherGroup.GroupID then return end
	if self.Enemies then
		self.Enemies[otherGroup.GroupID] = nil
	end
end

function SuperSurvivorGroup:getEnemyGroups()
	return self.Enemies or {}
end

-- ========== Leadership and Authority ==========

function SuperSurvivorGroup:setLeader(survivor)
	if not survivor then return end
	self.Leader = survivor
	survivor:setAsGroupLeader(true)
end

function SuperSurvivorGroup:getLeader()
	return self.Leader
end

function SuperSurvivorGroup:isLeader(survivor)
	return self.Leader == survivor
end

function SuperSurvivorGroup:getLeaderName()
	if self.Leader then
		return self.Leader:getName()
	end
	return "Unknown"
end

-- ========== Persistence (Saving / Loading) ==========

function SuperSurvivorGroup:serialize()
	local data = {
		GroupID = self.GroupID,
		LeaderID = self.Leader and self.Leader:getID() or nil,
		Members = {},
		KnownBuildings = {},
		Enemies = self.Enemies or {},
	}

	for id, member in pairs(self.Members) do
		table.insert(data.Members, id)
	end

	for id, bld in pairs(self.KnownBuildings or {}) do
		table.insert(data.KnownBuildings, id)
	end

	return data
end

function SuperSurvivorGroup:loadFromData(data)
	if not data then return end

	self.GroupID = data.GroupID
	self.Enemies = data.Enemies or {}

	for _, memberID in pairs(data.Members or {}) do
		local member = SuperSurvivorManager:getSurvivorByID(memberID)
		if member then
			self:addMember(member)
		end
	end

	for _, buildingID in pairs(data.KnownBuildings or {}) do
		local building = getBuildingByID(buildingID)
		if building then
			self:addKnownBuilding(building)
		end
	end

	if data.LeaderID then
		local leader = SuperSurvivorManager:getSurvivorByID(data.LeaderID)
		if leader then
			self:setLeader(leader)
		end
	end
end