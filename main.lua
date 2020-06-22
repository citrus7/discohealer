HealComm = LibStub("LibHealComm-4.0", true)
LibCLHealth = LibStub("LibCombatLogHealth-1.0")
ThreatLib = LibStub:GetLibrary("LibThreatClassic2")

local function main()
    local discoSettings = {
        frameSize=1,
        leftClickAction = "cast"
    }

    discoMainFrame = generateMainDiscoFrame(discoSettings)
    guidToUid = HealComm:GetGUIDUnitMapTable()
    discoSubframes = {}
    discoOverlaySubframes = {}
    allPartyMembers = {}
    unitTargetList = {}
    unitTargetThrottle = GetTime()
    priorityList = {}
    healcommCallbacks = {}
    playerTarget = "target"
    framesNeedUpdate = true

    generateDiscoSubframes(discoSubframes, discoOverlaySubframes, discoMainFrame, discoSettings)

    local eventHandlers = {}

    -- Handler for Unit Health changes
    --[[
    function eventHandlers:UNIT_HEALTH(unitId)
        updateTargetListFull(discoOverlaySubframes, unitTargetList)
        removeExpiredThreat(discoOverlaySubframes, unitTargetList)
    end
    ]]

    -- Handler for party changes
    function eventHandlers:GROUP_ROSTER_UPDATE()
        allPartyMembers = getAllPartyUnitIDs()
        if InCombatLockdown() then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame, discoSettings, allPartyMembers)
        end
    end

    -- Handler for leave combat
    function eventHandlers:PLAYER_REGEN_ENABLED()
        discoMainFrame.texture:SetAlpha(0.1)
        if framesNeedUpdate then
            framesNeedUpdate = false
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame, discoSettings, allPartyMembers)
        end
    end

    -- Handler for enter combat
    function eventHandlers:PLAYER_REGEN_DISABLED()
        discoMainFrame.texture:SetAlpha(0.2)
    end

    -- Raid group updated
    function eventHandlers:RAID_TARGET_UPDATE()
        allPartyMembers = getAllPartyUnitIDs()
        if InCombatLockdown() then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame, discoSettings, allPartyMembers)
        end
    end

    function eventHandlers:PLAYER_TARGET_CHANGED()
        -- untarget current target
        if discoSubframes[playerTarget] then
            discoOverlaySubframes[playerTarget]:untarget()
        end
        -- new target
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        targetUid = guidToUid[UnitGUID("target")]
        playerTarget = targetUid
        if discoSubframes[targetUid] then
            discoOverlaySubframes[targetUid]:target()
        end
    end

    function eventHandlers:PLAYER_ENTERING_WORLD()
        allPartyMembers = getAllPartyUnitIDs()
        if InCombatLockdown() then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame, discoSettings, allPartyMembers)
        end
        clearThreat(discoOverlaySubframes, unitTargetList)
    end

    -- Combat log event for threat
    function eventHandlers:COMBAT_LOG_EVENT_UNFILTERED()
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

        local currentTime = GetTime()
        if currentTime - unitTargetThrottle > 0.2 then
            updateTargetListFull(allPartyMembers, discoOverlaySubframes, unitTargetList)
            removeExpiredThreat(discoOverlaySubframes, unitTargetList)
            unitTargetThrottle = currentTime
        end

        --[[
        if sourceName == "Treenewbank" then
            print(subevent)
            discoOverlaySubframes["player"].castAnimation:SetDuration(1.5)
            discoOverlaySubframes["player"].castAnimationGroup:Play()
        end
        ]]

        if subevent == "UNIT_DIED" then
            removeThreat(destGUID, discoOverlaySubframes, unitTargetList)
        end
    end

    -- Attach all handlers to discoMainFrame
    discoMainFrame:SetScript("OnEvent", function(self, event, ...)
        eventHandlers[event](self, ...); -- call one of the functions above
    end)
    for k, v in pairs(eventHandlers) do
        discoMainFrame:RegisterEvent(k); -- Register all events for which handlers have been defined
    end

    -- Healcomm incoming heal function
    function healcommCallbacks:HealStarted(event, casterGUID, spellID, spellType, endTime, ...)
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGuid = select(i, ...)
            targetID = guidToUid[playerGuid]
            if targetID and discoSubframes[targetID] then
                updateHealthForUid(targetID, discoSubframes, priorityList)

                -- Update cast bar
                casterId = guidToUid[casterGUID]
                if casterId and UnitIsPlayer(casterId) then
                    local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellID)
                    discoOverlaySubframes[targetID].castAnimation:SetDuration(castTime/1000)
                    discoOverlaySubframes[targetID].castAnimationGroup:Play()
                end
            end
        end
    end

    -- Healcomm incoming heal function
        function healcommCallbacks:HealStopped(event, casterGUID, spellID, spellType, endTime, ...)
            local guidToUid = HealComm:GetGUIDUnitMapTable()
            for i=1, select("#", ...) do
                local playerGuid = select(i, ...)
                targetID = guidToUid[playerGuid]
                if targetID and discoSubframes[targetID] then
                    updateHealthForUid(targetID, discoSubframes, priorityList)
    
                    -- Update cast bar
                    casterId = guidToUid[casterGUID]
                    if casterId and UnitIsPlayer(casterId) then
                        discoOverlaySubframes[targetID].castAnimationGroup:Stop()
                    end
                end
            end
        end

    -- Initialize combat health
    LibCLHealth.RegisterCallback(discoMainFrame, "COMBAT_LOG_HEALTH", function(event, unitId, eventType)
        if discoSubframes[unitId] then
            updateHealthForUid(unitId, discoSubframes, priorityList)
        end
    end)

    -- Initialize Healcomm
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStarted", "HealStarted")
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStopped", "HealStopped")
    
end

-- Helper function to calculater priority
function calculatePriority(unitId)
    local unitHealth = LibCLHealth.UnitHealth(unitId)
    if unitHealth == 0 then
        return 0
    end
    local healAmount = HealComm:GetHealAmount(UnitGUID(unitId), HealComm.ALL_HEALS, GetTime() + 2) or 0
    local percentage = (unitHealth + healAmount)/UnitHealthMax(unitId)
    priority = (1-percentage) * 1000
    if priority < 0 then
        return 0
    end
    return priority
end

-- Maintain priority queue
function updatePriorityList(unitId, priorityList)
    local queueSize = 5
    local newPriority = calculatePriority(unitId)
    local add, remove
    local inRange = select(1, UnitInRange(unitId)) or unitId == "player"

    -- Check if already in priority list
    local addedFlag = false
    for i=1, #priorityList do
        if priorityList[i].unitId == unitId then
            if newPriority<1 or newPriority>999 or not inRange then
                remove = priorityList[i].unitId
                priorityList[i] = nil
            else
                add = priorityList[i].unitId
                priorityList[i] = {priority=priority, unitId=unitId}
            end
            addedFlag = true
        end
    end

    -- New entries of 0 or 1000 aren't added as new entries
    if addedFlag == false and (newPriority < 1 or newPriority>999 or not inRange or (#priorityList == queueSize and newPriority < priorityList[#priorityList].priority)) then
        return
    end

    if addedFlag == false and inRange then
        add = unitId
        priorityList[#priorityList+1] = {priority=priority, unitId=unitId}
    end

    if #priorityList > 1 then
        table.sort(priorityList, function(a,b)
            if a == nil then
                return false
            elseif b == nil then
                return true
            end
            return a.priority > b.priority
        end)
        if #priorityList == queueSize+1 then
            remove = priorityList[queueSize+1].unitId
            priorityList[queueSize+1] = nil
        end
    end
    
    return add, remove
end

-- Perform all health bar, texture color, alpha, and priority queue updates
function updateHealthForUid(unitId, subframes, priorityList)
    updateSubframeHealth(unitId, subframes)
    local index = string.match (unitId, "%d+")
    -- Player and maintanks always updated
    if (UnitIsUnit(unitId, "player") or select(10, GetRaidRosterInfo(index)) == "MAINTANK") and UnitInRange(unitId) then
        local priority = calculatePriority(unitId)
        if priority > 1 and priority < 999 then
            updateRaidSubframes(unitId, nil, subframes)
        else
            updateRaidSubframes(nil, unitId, subframes)
        end
    else
        local _, remove = updatePriorityList(unitId, priorityList)
        local found = false
        -- See if unit in priorityList
        for _, v in pairs(priorityList) do
            if unitId == v.unitId then
                subframes[unitId]:SetAlpha(1)
                found = true
            end
        end
        if not found then
            subframes[unitId]:setHidden()
        end
        -- Hide any frames that were removed from priority list
        if remove then
            subframes[remove]:setHidden()
        end
    end
end

-- Update subframe health
function updateSubframeHealth(unitId, subframes)
    local healAmount = HealComm:GetHealAmount(UnitGUID(unitId), HealComm.ALL_HEALS, GetTime() + 2) or 0
    local unitHealth = LibCLHealth.UnitHealth(unitId)
    local ratio = (unitHealth + healAmount)/UnitHealthMax(unitId)
    local healthRatio = unitHealth/UnitHealthMax(unitId)
    local inrange = select(1, UnitInRange(unitId)) or unitId == "player"

    if discoSubframes[unitId]==nil then
        print("Error, updateSubframeHealth called on nonexistant unitID: ", unitId)
    end
    subframes[unitId].healthBar:SetMinMaxValues(0,UnitHealthMax(unitId))
    subframes[unitId].healthBar:SetValue(unitHealth)
    subframes[unitId].healBar:SetMinMaxValues(0,UnitHealthMax(unitId))
    subframes[unitId].healBar:SetValue(healAmount + unitHealth)

    if healthRatio < 0.01 then
        -- Unit dead
        subframes[unitId].texture:SetColorTexture(0.4, 0.4, 0.4)
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    elseif healthRatio < 0.25 then
        subframes[unitId].texture:SetColorTexture(1, 0, 0)
        subframes[unitId].alpha = 0.7
    elseif healthRatio < 0.5 then
        subframes[unitId].texture:SetColorTexture(1, 0.5, 0)
        subframes[unitId].alpha = 0.4
    elseif healthRatio < 0.75 then
        subframes[unitId].texture:SetColorTexture(1, 1, 0)
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    elseif ratio > 0.99 then
        -- health + healing over max
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    else
        subframes[unitId].texture:SetColorTexture(0.3, 1, 0.3)
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    end

    if not inrange then
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    end
end

-- Get a list of all party/raid unitIDs
function getAllPartyUnitIDs()
    local partySize = GetNumGroupMembers()
    local allGroupIDs = {"player"}
    for i=1, partySize do
        key = "raid" .. i
        pkey = "raidpet" .. i
        if UnitExists(key) then
            allGroupIDs[#allGroupIDs+1] = key
        end
        if UnitExists(pkey) then
            allGroupIDs[#allGroupIDs+1] = pkey
        end
    end
    for i=1, min(5, partySize) do
        key = "party" .. i
        pkey = "partypet" .. i
        if UnitExists(key) then
            allGroupIDs[#allGroupIDs+1] = key
        end
        if UnitExists(pkey) then
            allGroupIDs[#allGroupIDs+1] = key
        end
    end
    return allGroupIDs
end

-- Update raid subframes
-- add and remove are both unitIDs
function updateRaidSubframes(add, remove, subframes)
    if add ~= nil then
        subframes[add]:SetAlpha(1)
    end

    if remove ~= nil then
        subframes[remove]:setHidden()
    end
end

main()