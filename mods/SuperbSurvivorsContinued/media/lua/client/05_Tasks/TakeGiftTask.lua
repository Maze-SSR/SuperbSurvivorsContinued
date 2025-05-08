TakeGiftTask = {}
TakeGiftTask.__index = TakeGiftTask

local isLocalLoggingEnabled = false
local TRANSFER_SPEED = 20
local MAX_TASK_TICKS = 30 -- Adjusted to provide ample timeout

function TakeGiftTask:new(superSurvivor, gift)
    CreateLogLine("TakeGiftTask", isLocalLoggingEnabled, "function: TakeGiftTask:new() called")
    local o = setmetatable({}, self)

    o.parent = superSurvivor
    o.Name = "Take Gift"
    o.TheGift = gift
    o.DestContainer = superSurvivor:getBag() or superSurvivor:Get():getInventory()

    if IsItemWater(gift) then
        o.DestContainer = superSurvivor:Get():getInventory()
    end

    o.SrcContainer = nil
    o.Ticks = 0
    o.Complete = false

    return o
end

function TakeGiftTask:isComplete()
    if self.Complete and self.DestContainer then
        local weapon = self.DestContainer:FindAndReturnCategory("Weapon")
        if weapon and not self.parent:Get():getPrimaryHandItem() then
            self.parent:giveWeapon(weapon, true)
        end
    end
    return self.Complete
end

function TakeGiftTask:isValid()
    return self.parent and self.TheGift
end

function TakeGiftTask:update()
    if not self:isValid() or self.Complete then
        self.Complete = true
        return
    end

    if not self.parent:isInAction() then
        local giftItem = self.TheGift
        local giftWorldItem = giftItem:getWorldItem()
        local x, y, z, sq

        if giftWorldItem then
            x, y, z = giftWorldItem:getX(), giftWorldItem:getY(), giftWorldItem:getZ()
            self.SrcContainer = "Ground"
        elseif giftItem:getContainer() and giftItem:getContainer():getSourceGrid() then
            local sourceGrid = giftItem:getContainer():getSourceGrid()
            x, y, z = sourceGrid:getX(), sourceGrid:getY(), sourceGrid:getZ()
            self.SrcContainer = giftItem:getContainer()
        else
            CreateLogLine("TakeGiftTask", isLocalLoggingEnabled, "Gift source unknown, aborting.")
            self.Complete = true
            return
        end

        if x then
            sq = self.parent:Get():getCell():getGridSquare(math.floor(x), math.floor(y), math.floor(z))
        else
            self.Complete = true
            return
        end

        local distance = GetDistanceBetween(self.parent:Get(), sq)

        if not self.DestContainer:contains(giftItem) and distance < 2.0 then
            self.parent:RoleplaySpeak(Get_SS_UIActionText("Takes_Before") .. giftItem:getDisplayName() .. Get_SS_UIActionText("Takes_After"))

            if self.SrcContainer == "Ground" and giftWorldItem then
                self.DestContainer:AddItem(giftItem)
                local square = giftWorldItem:getSquare()
                if square then square:removeWorldObject(giftWorldItem) end
                giftWorldItem:removeFromSquare()
                giftItem:setWorldItem(nil)

                self.parent:Speak(Get_SS_DialogueSpeech("Thanks"))
                self.Complete = true

                self:HandleSpecialItem(giftItem)
            elseif self.SrcContainer ~= "Ground" then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.parent.player, giftItem, self.SrcContainer, self.DestContainer, TRANSFER_SPEED))
                -- Mark complete after transfer is queued to avoid endless looping
                self.Complete = true
            end
        elseif self.DestContainer:contains(giftItem) then
            self.parent:Speak(Get_SS_DialogueSpeech("Thanks"))
            self.Complete = true
            self:HandleSpecialItem(giftItem)
        else
            if sq then self.parent:walkTo(sq) end
        end

        self.Ticks = self.Ticks + 1
        if self.Ticks > MAX_TASK_TICKS then
            CreateLogLine("TakeGiftTask", isLocalLoggingEnabled, "Timed out while trying to take gift.")
            self.Complete = true
        end
    end
end

function TakeGiftTask:HandleSpecialItem(item)
    if item:isClothing() then
        self.DestContainer:Remove(item)
        local inv = self.parent:Get():getInventory()
        inv:AddItem(item)
        self.parent:RoleplaySpeak(Get_SS_UIActionText("EquipsArmor"))
        self.parent:WearThis(item)
    elseif item:getCategory() == "Container" then
        self.DestContainer:Remove(item)
        local inv = self.parent:Get():getInventory()
        inv:AddItem(item)
        self.parent:RoleplaySpeak(Get_SS_UIActionText("SD_EquipsArmor"))
        self.parent.player:setClothingItem_Back(item)
    end
end
