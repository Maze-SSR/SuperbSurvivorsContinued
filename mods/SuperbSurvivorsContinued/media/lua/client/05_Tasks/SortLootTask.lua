SortLootTask = {}
SortLootTask.__index = SortLootTask

local isLocalLoggingEnabled = false;

function SortLootTask:new(superSurvivor, incldHandItems)
	CreateLogLine("SortLootTask", isLocalLoggingEnabled, "function: SortLootTask:new() called")
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.parent = superSurvivor
	o.Name = "Sort Inventory"
	o.OnGoing = false
	o.incldHandItems = incldHandItems or false
	o.Complete = false
	o.Group = superSurvivor:getGroup()
	o.TheDropContainer = nil
	o.TheDropSquare = superSurvivor.player:getCurrentSquare()

	if not o.Group then o.Complete = true end
	superSurvivor:StopWalk()
	return o
end

function SortLootTask:isComplete()
	if self.Complete then
		triggerEvent("OnClothingUpdated", self.parent.player)
	end
	return self.Complete
end

function SortLootTask:isValid()
	return self.parent ~= nil and (self.TheDropSquare or self.TheDropContainer)
end

local function TryDropItem(task, item, sourceContainer)
	if not item then return false end

	local dropSquare = task.Group:getBestGroupAreaContainerForItem(item)
	if instanceof(dropSquare, "IsoObject") then
		task.TheDropContainer = dropSquare
		task.TheDropSquare = dropSquare:getSquare()
	else
		task.TheDropSquare = dropSquare
	end

	if not task.TheDropSquare then return false end

	local distance = GetDistanceBetween(task.parent.player, task.TheDropSquare)
	if distance > 2.0 then
		task.parent:walkTo(task.TheDropSquare)
		return true
	end

	local p = task.parent.player
	local container = nil

	if task.TheDropContainer and task.TheDropContainer.getContainer then
		container = task.TheDropContainer:getContainer()
	end

	if not container then
		local spiral = SpiralSearch:new(p:getX(), p:getY(), 2)
		for i = spiral:forMax(), 0, -1 do
			local x, y = spiral:getX(), spiral:getY()
			local sq = getCell():getGridSquare(x, y, p:getZ())
			if sq then
				local objs = sq:getObjects()
				for j = 0, objs:size() - 1 do
					local c = objs:get(j):getContainer()
					if c then
						container = c
						break
					end
				end
			end
			if container then break end
			spiral:next()
		end
	end

	if container and container:hasRoomFor(p, item) then
		ISTimedActionQueue.add(ISInventoryTransferAction:new(p, item, sourceContainer, container, nil))
	else
		ISTimedActionQueue.add(ISDropItemAction:new(p, item, 30))
	end

	if item:getBodyLocation() ~= "" and p:isEquipped(item) then
		p:removeFromHands(nil)
		p:setWornItem(item:getBodyLocation(), nil)
	end

	triggerEvent("OnClothingUpdated", p)
	return true
end

function SortLootTask:update()
	if not self:isValid() then
		self.Complete = true
		return false
	end

	if self.parent:isInAction() then return false end

	if self.incldHandItems then
		self.parent.player:setPrimaryHandItem(nil)
		self.parent.player:setSecondaryHandItem(nil)
		self.parent.player:setClothingItem_Back(nil)
	end

	self.parent:StopWalk()
	local droppedSomething = false
	local inv = self.parent.player:getInventory()
	local bag = self.parent:getBag()
	local pweapon = self.parent.player:getPrimaryHandItem()
	local sweapon = self.parent.player:getSecondaryHandItem()

	local function ShouldDrop(item)
		return item ~= nil
			and (item:isBroken()
			or (
				(not item:isEquipped())
				and (not self.incldHandItems and (item ~= self.parent.LastGunUsed and item ~= self.parent.LastMeleUsed))
				and (self.parent:isAmmoForMe(item:getType()) == false)
				and (item ~= pweapon)
				and (item ~= sweapon)))
	end

	-- Drop from player inventory
	local invItems = inv:getItems()
	for i = 0, invItems:size() - 1 do
		local item = invItems:get(i)
		if ShouldDrop(item) then
			if TryDropItem(self, item, inv) then
				droppedSomething = true
				break
			end
		end
	end

	-- Drop from bag
	if not droppedSomething and inv ~= bag then
		local bagItems = bag:getItems()
		for i = 0, bagItems:size() - 1 do
			local item = bagItems:get(i)
			if ShouldDrop(item) then
				if TryDropItem(self, item, bag) then
					droppedSomething = true
					break
				end
			end
		end
	end

	if not droppedSomething then
		self.Complete = true
	end
end
