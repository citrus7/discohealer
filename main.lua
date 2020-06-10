HealComm = LibStub("LibHealComm-4.0", true)
LibCLHealth = LibStub("LibCombatLogHealth-1.0")
ThreatLib = LibStub:GetLibrary("LibThreatClassic2")

local function main()
    discoMainFrame = generateMainDiscoFrame()

    guidToUid = HealComm:GetGUIDUnitMapTable()
    discoSubframes = {}
    discoOverlaySubframes = {}
    unitThreatList = {}
    priorityList = {}
    healcommCallbacks = {}
    playerTarget = "target"
    framesNeedUpdate = true

    generateDiscoSubframes(discoSubframes, discoOverlaySubframes, discoMainFrame)

    local eventHandlers = {}

    -- Handler for Unit Health changes
    function eventHandlers:UNIT_HEALTH(unitId)
        refreshThreat(discoOverlaySubframes, unitThreatList)
        removeExpiredThreat(discoOverlaySubframes, unitThreatList)
    end

    -- Handler for party changes
    function eventHandlers:GROUP_ROSTER_UPDATE()
        if InCombatLockdown() then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame)
        end
    end

    -- Handler for leave combat
    function eventHandlers:PLAYER_REGEN_ENABLED()
        discoMainFrame.texture:SetAlpha(0.1)
        if framesNeedUpdate then
            framesNeedUpdate = false
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame)
        end
        -- Todo
        --clearThreat(discoOverlaySubframes, unitThreatList)
    end

    -- Handler for enter combat
    function eventHandlers:PLAYER_REGEN_DISABLED()
        --updateThreatListFull(discoOverlaySubframes, unitThreatList)
        discoMainFrame.texture:SetAlpha(0.2)
    end

    -- Raid group updated
    function eventHandlers:RAID_TARGET_UPDATE()
        if InCombatLockdown() then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame)
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
        if InCombatLockdown() then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoSubframes, discoOverlaySubframes, discoMainFrame)
        end
        clearThreat(discoOverlaySubframes, unitThreatList)
    end

    -- Combat log event for threat
    function eventHandlers:COMBAT_LOG_EVENT_UNFILTERED()
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

        if subevent == "UNIT_DIED" then
            removeThreat(destGUID, discoOverlaySubframes, unitThreatList)
        else
            if (strsplit("-",destGUID)) == "Creature" then
                updateThreatListCombat(destGUID, discoOverlaySubframes, unitThreatList)
            elseif (strsplit("-",sourceGUID)) == "Creature" then
                updateThreatListCombat(sourceGUID, discoOverlaySubframes, unitThreatList)
            end
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
            unitId = guidToUid[playerGuid]
            if unitId and discoSubframes[unitId] then
                updateHealthForUid(unitId, discoSubframes, priorityList)
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

    raidIndex = string.match (unitId, "%d+")

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
        if remove then
            subframes[remove]:setHidden()
        end
        local found = false
        for _, v in pairs(priorityList) do
            if unitId == v.unitId then
                subframes[unitId]:SetAlpha(1)
                found = true
            end
        end
        if not found then
            subframes[unitId]:setHidden()
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

    if ratio < 0.01 then
        -- Unit dead
        subframes[unitId].texture:SetColorTexture(0.4, 0.4, 0.4)
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    elseif healthRatio < 0.25 then
        subframes[unitId].texture:SetColorTexture(1, 0, 0)
        subframes[unitId].alpha = 0.3
    elseif healthRatio < 0.5 then
        subframes[unitId].texture:SetColorTexture(1, 0.5, 0)
        subframes[unitId].alpha = 0.2
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

-- Redraw all the subframes when the party changes
function recreateAllSubFrames(subframes, overlayFrames, mainframe)
    local partySize = GetNumGroupMembers()
    -- guid to {key, unitIDs}
    local playerMapping = {[UnitGUID("player")]={key="large1", unitName=UnitName("player"), unitIDs={player=""}}}

    local allKeys = {}
    for i=1, partySize do
        allKeys[#allKeys+1] = "raid" .. i
    end
    for i=1, min(6, partySize) do
        allKeys[#allKeys+1] = "party" .. i
    end

    -- Create player mapping
    local j,k= 2,1
    for _, key in pairs(allKeys) do
        if UnitExists(key) then
            if playerMapping[UnitGUID(key)] then
                playerMapping[UnitGUID(key)].unitIDs[key] = ""
            else
                local frameKey
                local index = string.match (key, "%d+")
                local isRaidMember = string.find(key, "raid")==1
                local isTank = index and isRaidMember and ((select(10, GetRaidRosterInfo(index))) == "MAINTANK")
                
                if j < 6 and (partySize < 6 or isTank) then
                    frameKey = "large" .. j
                    j=j+1
                else
                    frameKey = k
                    k=k+1
                end
                playerMapping[UnitGUID(key)] = {key=frameKey, unitName=UnitName(key), unitIDs={[key]=""}}
            end
        end
    end

    -- Update frames for playerMapping
    for unitGuid, v in pairs(playerMapping) do
        -- subframes
        subframes[unitGuid] = subframes[v.key]
        subframes[v.unitName] = subframes[unitGuid]
        for unitId, _ in pairs(v.unitIDs) do
            subframes[unitId] = subframes[unitGuid]
            subframes[v.key]:SetAttribute("unit", unitId)
        end
        --subframes[v.key]:SetAttribute("unit", v.unitName)
        subframes[v.key].text:SetText(v.unitName)
        subframes[v.key]:Show()
        subframes[v.key]:setHidden()
        --overlayFrames
        overlayFrames[unitGuid] = overlayFrames[v.key]
        overlayFrames[v.unitName] = overlayFrames[unitGuid]
        for unitId, _ in pairs(v.unitIDs) do
            overlayFrames[unitId] = overlayFrames[unitGuid]
        end
        overlayFrames[v.key]:Show()
    end

    -- Hide unused subframes
    for i=k, 40 do
        subframes[i]:Hide()
        overlayFrames[i]:Hide()
    end
    for i=j, 5 do
        subframes["large" .. i]:Hide()
        overlayFrames["large" .. i]:Hide()
    end

    resizeMainFrame(k, mainframe)
end

-- Resize the main disco healer frame
-- This function can only be called out of combat
function resizeMainFrame(nextFrame, mainframe)
    if nextFrame == 1 then
        discoMainFrame:SetSize(500, 30)
    elseif nextFrame <12 then
        discoMainFrame:SetSize(500, 52)
    elseif nextFrame < 22 then
        discoMainFrame:SetSize(500, 78)
    elseif nextFrame < 32 then
        discoMainFrame:SetSize(500, 104)
    else
        discoMainFrame:SetSize(500, 130)
    end
end

main()