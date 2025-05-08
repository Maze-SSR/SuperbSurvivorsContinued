LootCategoryTask = {}
LootCategoryTask.__index = LootCategoryTask

local isLocalLoggingEnabled = false;

function LootCategoryTask:new(superSurvivor, building, category, thisQuantity)
	CreateLogLine("LootTask", isLocalLoggingEnabled, "function: LootCategoryTask:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	if (superSurvivor == nil) then return false end

	o.FoundCount = 0
	o.Quantity = thisQuantity or 9999
	o.parent = superSurvivor
	o.Name = "Loot Category"
	o.OnGoing = false
	o.Category = category or "Food"

	if (not superSurvivor.player:getCurrentSquare()) then
		o.Complete = true
		return nil
	end

	o.Building = building
	o.parent:MarkBuildingExplored(building)
	o.PlayerBag = superSurvivor.player:getInventory()
	o.Container = nil
	o.Complete = false
	o.Floor = 0

	return o
end

function LootCategoryTask:ForceFinish()
	self.parent:BuildingLooted()
	self.parent.TargetBuilding = nil
	self.Complete = true
	self.parent:resetContainerSquaresLooted()
	if (self.Category == "Weapon") then
		local weapon = FindAndReturnBestWeapon(self.PlayerBag)
		if weapon and (not self.parent:Get():getPrimaryHandItem() or weapon:getMaxDamage() > self.parent:Get():getPrimaryHandItem():getMaxDamage()) then
			self.parent:Get():setPrimaryHandItem(weapon)
			if weapon:isTwoHandWeapon() then
				self.parent:Get():setSecondaryHandItem(weapon)
			end
		end
	end
end

function LootCategoryTask:isComplete()
	if self.Complete then self:ForceFinish() end
	return self.Complete
end

function LootCategoryTask:isValid()
	return true
end

function LootCategoryTask:update()
	CreateLogLine("LootTask", isLocalLoggingEnabled, "function: LootCategoryTask:update() called");
	if not self:isValid() then self.Complete = true return false end
	if self.parent:isInAction() then return false end
	if self.Building and self.parent:isTargetBuildingClaimed(self.Building) then self.Complete = true return false end

	self.PlayerBag = self.parent:getBag()
	if not self.Building then
		self.Complete = true
		self.parent:Speak(Get_SS_UIActionText("NotInBuilding"))
		return
	end

	if not self.parent:hasRoomInBag() then
		self.Complete = true
		self.parent:Speak(Get_SS_UIActionText("CantCarryMore"))
		return
	end

	if not self.Container or (instanceof(self.Container, "ItemContainer") and self.parent:getContainerSquareLooted(self.Container:getSourceGrid(), self.Category) == 0) then
		self.Container = nil
		local bdef = self.Building:getDef()
		local closestSoFar = 999
		for z = 2, 0, -1 do
			for x = bdef:getX() - 2, bdef:getX() + bdef:getW() + 2 do
				for y = bdef:getY() - 2, bdef:getY() + bdef:getH() + 2 do
					local sq = getCell():getGridSquare(x, y, z)
					if sq and not sq:isOutside() then
						local items = sq:getObjects()
						for j = 0, items:size() - 1 do
							if items:get(j):getContainer() then
								local container = items:get(j):getContainer()
								local dist = GetDistanceBetween(sq, self.parent.player) + (sq:getZ() ~= self.parent.player:getZ() and 13 or 0)
								if self.parent:getWalkToAttempt(sq) <= 8 and dist < closestSoFar and self.parent:getContainerSquareLooted(sq, self.Category) == 0 then
									self.Container = container
									closestSoFar = dist
									self.Floor = z
								end
							end
						end
					end
				end
			end
		end
	end

	if not self.Container then self.Complete = true return end

	if instanceof(self.Container, "ItemContainer") then
		local dist = GetDistanceBetween(self.Container:getSourceGrid(), self.parent.player)
		if dist > 2.1 or self.parent.player:getZ() ~= self.Floor then
			self.parent:walkTo(self.Container:getSourceGrid())
			self.parent:WalkToAttempt(self.Container:getSourceGrid())
			if self.parent:getWalkToAttempt(self.Container:getSourceGrid()) > 8 then
				self.Container = nil
				self.Complete = true
			end
		else
			local item = FindItemByCategory(self.Container, self.Category, self.parent)
			if item then
				self.FoundCount = self.FoundCount + 1
				self.parent:RoleplaySpeak(Get_SS_UIActionText("TakesFromCont_Before") .. item:getDisplayName() .. Get_SS_UIActionText("TakesFromCont_After"))
				if self.parent:hasRoomInBagFor(item) then
					self.parent:StopWalk()
					ISTimedActionQueue.add(ISInventoryTransferAction:new(self.parent.player, item, self.Container, self.PlayerBag, nil))
				else
					self.parent.player:getInventory():AddItem(item)
					self.Container:DoRemoveItem(item)
				end
			else
				self.parent:ContainerSquareLooted(self.Container:getSourceGrid(), self.Category)
				self.Container = nil
			end
		end
	elseif instanceof(self.Container, "InventoryItem") then
		local item = self.Container
		local square = item:getWorldItem() and item:getWorldItem():getSquare()
		if not square then self.Container = nil return end
		local dist = GetDistanceBetween(square, self.parent.player)
		if dist > 2.0 or self.parent.player:getZ() ~= self.Floor then
			self.parent:walkTo(square)
		else
			self.FoundCount = self.FoundCount + 1
			self.parent:RoleplaySpeak(Get_SS_UIActionText("TakesFromGround_Before") .. item:getDisplayName() .. Get_SS_UIActionText("TakesFromGround_After"))
			self.PlayerBag:AddItem(item)
			if item:getWorldItem() then item:getWorldItem():removeFromSquare() end
			item:setWorldItem(nil)
			self.Container = nil
		end
	end

	if self.FoundCount >= self.Quantity then self.Complete = true end
	CreateLogLine("LootTask", isLocalLoggingEnabled, "--- function: LootCategoryTask:update() END ---");
end
