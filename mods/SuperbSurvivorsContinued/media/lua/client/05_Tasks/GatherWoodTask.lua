GatherWoodTask = {}
GatherWoodTask.__index = GatherWoodTask

local isLocalLoggingEnabled = false;
local ClaimedCheckHours = 0.1

function GatherWoodTask:new(superSurvivor, BringHere)
	CreateLogLine("GatherWoodTask", isLocalLoggingEnabled, "function: GatherWoodTask:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.BringHereSquare = BringHere
	o.parent = superSurvivor
	o.Name = "Gather Wood"
	o.group = superSurvivor:getGroup()
	o.WoodStorageArea = nil
	if (o.group) then o.WoodStorageArea = o.group:getGroupArea("WoodStorageArea") end
	o.Target = nil
	o.CarryingToPoint = false
	o.Complete = false

	return o
end

function GatherWoodTask:isComplete()
	return self.Complete
end

function GatherWoodTask:isValid()
	return self.parent and self.BringHereSquare
end

function GatherWoodTask:update()
	CreateLogLine("GatherWoodTask", isLocalLoggingEnabled, "function: GatherWoodTask:update() called");
	if (not self:isValid()) then return false end

	local player = self.parent.player

	if self.parent:isInAction() then return false end

	-- Deliver to storage point
	local woodItem = player:getInventory():FindAndReturn("Plank") or player:getInventory():FindAndReturn("Log")
	if woodItem then
		if GetDistanceBetween(self.BringHereSquare, player) > 2 then
			self.parent:walkTo(self.BringHereSquare)
		else
			self.BringHereSquare:AddWorldInventoryItem(woodItem, ZombRand(10)/100, ZombRand(10)/100, 0)
			player:getInventory():DoRemoveItem(woodItem)
			self.Target = nil
		end
		return
	end

	-- Search for nearby wood
	if not self.Target then
		local range = 25
		local closest = range
		local gamehours = getGameTime():getWorldAgeHours()

		local minx = math.floor(player:getX() - range)
		local maxx = math.floor(player:getX() + range)
		local miny = math.floor(player:getY() - range)
		local maxy = math.floor(player:getY() + range)

		if self.group then
			local area = self.group:getGroupArea("TakeWoodArea")
			if area[1] ~= 0 then
				minx, maxx = area[1], area[2]
				miny, maxy = area[3], area[4]
			end
		end

		for x = minx, maxx do
			for y = miny, maxy do
				local sq = getCell():getGridSquare(x, y, 0)
				if sq and self.BringHereSquare ~= sq then
					local objs = sq:getWorldObjects()
					for i = 0, objs:size()-1 do
						local obj = objs:get(i)
						local item = obj:getItem()
						if item and (item:getType() == "Plank" or item:getType() == "Log") then
							local mod = obj:getModData()
							local isUnclaimed = not mod.isClaimed or (gamehours > (mod.isClaimed + ClaimedCheckHours))
							local dist = GetDistanceBetween(sq, player)

							if isUnclaimed and dist < closest then
								self.Target = obj
								closest = dist
							end
						end
					end
				end
			end
		end

		-- If nothing found on ground, try containers nearby
		if not self.Target then
			local spiral = SpiralSearch:new(player:getX(), player:getY(), 6)
			for i = 0, spiral:forMax() do
				local x, y = spiral:getX(), spiral:getY()
				local sq = getCell():getGridSquare(x, y, 0)
				if sq then
					local objs = sq:getObjects()
					for j = 0, objs:size()-1 do
						local c = objs:get(j):getContainer()
						if c then
							local item = c:FindAndReturn("Plank") or c:FindAndReturn("Log")
							if item then
								ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, c, player:getInventory(), 30))
								self.Target = nil
								return
							end
						end
					end
				end
				spiral:next()
			end
		end

		if not self.Target then
			self.parent:Speak(Get_SS_UIActionText("NoWoodHere"))
			self.Complete = true
			return
		end
	end

	-- Walk to target
	if self.Target and GetDistanceBetween(self.Target:getSquare(), player) > 2 then
		self.parent:walkTo(self.Target:getSquare())
	elseif self.Target then
		local item = self.Target:getItem()
		player:getInventory():AddItem(item)
		if self.Target:getWorldItem() then
			self.Target:getWorldItem():getSquare():removeWorldObject(self.Target:getWorldItem())
			self.Target:getWorldItem():removeFromSquare()
		end
		item:setWorldItem(nil)
		self.parent:RoleplaySpeak(Get_SS_UIActionText("TakesItemFromGround_Before") ..
			item:getDisplayName() .. Get_SS_UIActionText("TakesItemFromGround_After"))
		self.CarryingToPoint = true
		self.Target = nil
	end

	CreateLogLine("GatherWoodTask", isLocalLoggingEnabled, "--- function: GatherWoodTask:update() END ---");
end
