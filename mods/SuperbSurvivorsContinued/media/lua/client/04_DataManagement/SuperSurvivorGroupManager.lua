SuperSurvivorGroupManager = {}
SuperSurvivorGroupManager.__index = SuperSurvivorGroupManager

function SuperSurvivorGroupManager:new()
	local o = setmetatable({}, self)
	o.Groups = {}
	o.GroupCount = 0
	o.NextGroupID = 1
	return o
end

function SuperSurvivorGroupManager:GetGroupById(thisID)
	return self.Groups[thisID]
end

function SuperSurvivorGroupManager:GetGroupIdFromSquare(square)
	for id, group in pairs(self.Groups) do
		if group and group:IsInBounds(square) then
			return group:getID()
		end
	end
	return -1
end

function SuperSurvivorGroupManager:getCount()
	return self.GroupCount
end

function SuperSurvivorGroupManager:newGroup()
	local groupID = self.NextGroupID
	local newGroup = SuperSurvivorGroup:new(groupID)

	self.Groups[groupID] = newGroup
	self.GroupCount = self.GroupCount + 1
	self.NextGroupID = self.NextGroupID + 1

	return newGroup
end

function SuperSurvivorGroupManager:Save()
	for id, group in pairs(self.Groups) do
		if group then
			group:Save()
		end
	end
end

function SuperSurvivorGroupManager:Load()
	if DoesFileExist("SurvivorGroup0.lua") then
		local groupIndex = 0
		while DoesFileExist("SurvivorGroup" .. tostring(groupIndex) .. ".lua") do
			local newGroup = self:newGroup()
			newGroup:Load()
			groupIndex = groupIndex + 1
		end
	end
end

SSGM = SuperSurvivorGroupManager:new()