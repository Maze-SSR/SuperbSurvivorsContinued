local isLocalLoggingEnabled = false

-- Utility for future MP support
local function getPlayer()
    return getSpecificPlayer(0) -- TODO: Dynamic player index in MP
end

-- Issues group-wide orders via arrow keys
local function superSurvivorsHotKeyOrder(index)
    local order, isListening

    if Orders and index <= #Orders then
        order = Orders[index]
        isListening = false
    elseif Orders then
        order = Orders[(index - #Orders)]
        isListening = true
    else
        return -- Orders table not initialized
    end

    local mySS = SSM:Get(0)
    if not mySS then return end

    local myGroup = mySS:getGroup()
    if myGroup then
        local members = myGroup:getMembersInRange(mySS:Get(), 25, isListening)
        for i = 1, #members do
            SurvivorOrder(nil, members[i].player, order, nil)
        end
    end
end

-- Key binding event handler
function SuperSurvivorKeyBindAction(keyNum)
    local isLocalFunctionLoggingEnabled = false
    CreateLogLine("SuperSurvivorsHotKeys", isLocalFunctionLoggingEnabled, "function: SuperSurvivorKeyBindAction called")

    local playerSurvivor = getPlayer()
    if not playerSurvivor or not playerSurvivor:isAlive() then return end

    if keyNum == 156 then -- Numpad Enter: Spawn test survivor
        if Get_SS_Alive_Count() < Limit_Npcs_Spawn then
            local ss = SuperSurvivorSpawnNpcAtSquare(playerSurvivor:getCurrentSquare())
            if ss then
                local name = ss:getName()
                ss.player:getModData().isRobber = false
                ss:setName("Spawned " .. name)
            end
        else
            playerSurvivor:Say("activeNpcs limit reached, no spawn.")
        end

    elseif keyNum == 78 then -- Numpad +: Increase follow distance
        if GFollowDistance < 50 then GFollowDistance = GFollowDistance + 1 end
        playerSurvivor:Say("Spread out more (" .. tostring(GFollowDistance) .. ")")

    elseif keyNum == 74 then -- Numpad -: Decrease follow distance
        if GFollowDistance > 0 then GFollowDistance = GFollowDistance - 1 end
        playerSurvivor:Say("Stay closer (" .. tostring(GFollowDistance) .. ")")

    elseif keyNum == 181 then -- Numpad /: "Hey you!" nearby non-party NPC
        local mySS = SSM:Get(0)
        local target = SSM:GetClosestNonParty()
        if mySS and target then
            mySS:Speak(Get_SS_Dialogue("HeyYou"))
            target:getTaskManager():AddToTop(ListenTask:new(target, mySS:Get(), false))
        end

    elseif keyNum == 201 then -- Page Up: Toggle survivor window
        window_super_survivors_visibility()

    elseif keyNum == 209 then -- Page Down: Closest member follow
        local mySS = SSM:Get(0)
        if mySS and mySS:getGroupID() then
            local group = SSGM:GetGroupById(mySS:getGroupID())
            if group then
                local member = group:getClosestMember(nil, mySS:Get())
                if member then
                    mySS:Get():Say(Get_SS_UIActionText("ComeWithMe_Before") ..
                        member:Get():getForname() .. Get_SS_UIActionText("ComeWithMe_After"))
                    local tm = member:getTaskManager()
                    tm:clear()
                    tm:AddToTop(FollowTask:new(member, mySS:Get()))
                else
                    playerSurvivor:Say("getClosestMember returned nil")
                end
            else
                playerSurvivor:Say("no group for player found")
            end
        end

    elseif keyNum == 55 then -- Numpad *: Closest member listen
        local mySS = SSM:Get(0)
        if mySS and mySS:getGroupID() then
            local group = SSGM:GetGroupById(mySS:getGroupID())
            if group then
                local member = group:getClosestMember(nil, mySS:Get())
                if member then
                    mySS:Get():Say(member:Get():getForname() .. ", come here.")
                    member:getTaskManager():AddToTop(ListenTask:new(member, mySS:Get(), false))
                else
                    playerSurvivor:Say("getClosestMember returned nil")
                end
            end
        end

    -- Quick command keys (arrow keys)
    elseif keyNum == 200 then -- Up arrow: Follow
        superSurvivorsHotKeyOrder(6)
    elseif keyNum == 208 then -- Down arrow: Stop
        superSurvivorsHotKeyOrder(19)
    elseif keyNum == 203 then -- Left arrow: Stand Ground
        superSurvivorsHotKeyOrder(18)
    elseif keyNum == 205 then -- Right arrow: Barricade
        superSurvivorsHotKeyOrder(1)

    elseif keyNum == 76 then -- Numpad 5: Debug info
        LogSSDebugInfo()
    end
end

-- Bind keys only after game starts
local function ss_HotKeyPress()
    Events.OnKeyPressed.Add(SuperSurvivorKeyBindAction)
end

Events.OnGameStart.Add(ss_HotKeyPress)

