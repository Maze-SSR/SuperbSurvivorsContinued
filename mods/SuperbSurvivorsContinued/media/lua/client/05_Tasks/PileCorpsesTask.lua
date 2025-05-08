PileCorpsesTask = {}
PileCorpsesTask.__index = PileCorpsesTask

local isLocalLoggingEnabled = false;

function PileCorpsesTask:new(superSurvivor, BringHere)
	CreateLogLine("PileCorpsesTask", isLocalLoggingEnabled, "PileCorpsesTask:new() called");
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.BringHereSquare = BringHere
	o.parent = superSurvivor
	o.group = superSurvivor:getGroup()
	o.Name = "Pile Corpses"

	o.Target = nil
	o.TargetSquare = nil
	o.Complete = false

	o.parent:setLastWeapon()
	return o
end

function PileCorpsesTask:ForceFinish()
	self.parent:reEquipLastWeapon()
	self.Complete = true
end

function PileCorpsesTask:isComplete()
	return self.Complete
end

function PileCorpsesTask:isValid()
	return self.parent ~= nil
end

function PileCorpsesTask:update()
	CreateLogLine("PileCorpsesTask", isLocalLoggingEnabled, "PileCorpsesTask:update() called");
	if not self:isValid() then return false end

	local player = self.parent.player

	if not self.parent:isInAction() then
		local heldCorpse = player:getInventory():FindAndReturn("CorpseMale") or player:getInventory():FindAndReturn("CorpseFemale")

		if heldCorpse then
			local distance = GetDistanceBetween(self.BringHereSquare, player)
			if distance > 2.0 then
				self.parent:walkToDirect(self.BringHereSquare)
			else
				self.parent:StopWalk()
				ISTimedActionQueue.add(ISDropItemAction:new(player, heldCorpse, 30))
				player:setPrimaryHandItem(nil)
				player:setSecondaryHandItem(nil)
				self.Target = nil
			end

		elseif not self.Target then
			local range = 30
			local minx, maxx = math.floor(player:getX() - range), math.floor(player:getX() + range)
			local miny, maxy = math.floor(player:getY() - range), math.floor(player:getY() + range)
			local z = 0

			if self.group then
				local area = self.group:getGroupArea("TakeCorpseArea")
				if area and area[1] ~= 0 then
					minx, maxx = area[1], area[2]
					miny, maxy = area[3], area[4]
					z = area[5]
				end
			end

			local closestSoFar = range + 1
			local gamehours = getGameTime():getWorldAgeHours()

			for x = minx, maxx do
				for y = miny, maxy do
					local square = getCell():getGridSquare(x, y, z)
					if square and square:getDeadBody() and GetDistanceBetween(square, self.BringHereSquare) > 2 then
						local distance = GetDistanceBetween(square, player)
						if distance < closestSoFar then
							self.Target = square:getDeadBody()
							self.TargetSquare = square
							closestSoFar = distance
						end
					end
				end
			end

			if self.Target then
				self.Target:getModData().isClaimed = gamehours
				self.parent:walkTo(self.TargetSquare)
			else
				self.Complete = true
			end

		elseif self.Target and self.TargetSquare then
			if self.TargetSquare:getDeadBody() then
				local distance = GetDistanceBetween(self.TargetSquare, player)
				if distance > 2.0 then
					self.parent:walkTo(self.TargetSquare)
				else
					ISTimedActionQueue.add(ISGrabCorpseAction:new(player, self.Target, 30))
					self.parent:RoleplaySpeak(Get_SS_UIActionText("PickUpCorpse"))
					self.Target = nil
				end
			else
				self.Target = nil
			end
		end
	end

	CreateLogLine("PileCorpsesTask", isLocalLoggingEnabled, "--- PileCorpsesTask:update() End ---");
end
