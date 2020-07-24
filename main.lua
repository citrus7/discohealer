local addonName, discoVars = ...

HealComm = LibStub("LibHealComm-4.0", true)
LibCLHealth = LibStub("LibCombatLogHealth-1.0")

local major = "DiscoHealer"
local minor = 1
local DiscoHealer = LibStub:NewLibrary(major, minor)

local function main()
    discoVars.discoMainFrame = CreateFrame("FRAME", "DiscoMainFrame", UIParent)
    discoHealerLoaded = false
    castTargetGUID = nil
    guidToUid = HealComm:GetGUIDUnitMapTable()
    discoVars.discoSubframes = {}
    discoVars.discoOverlaySubframes = {}
    discoVars.allPartyMembers = {}
    unitTargetList = {}
    unitTargetThrottle = GetTime()
    priorityList = {}
    healcommCallbacks = {}
    playerTarget = "target"
    framesNeedUpdate = true
    discoVars.castTicker = nil
    discoVars.castPercent = 0
    discoVars.playerCastTimer = GetTime()

    local eventHandlers = {}

    -- INIT function for DiscoHealer
    function eventHandlers:ADDON_LOADED(addonName)
        if addonName == "DiscoHealer" then
            if DiscoSettings == nil then
                DiscoSettings = {
                    frameSize=1,
                    showNames=true,
                    castLookAhead=2,
                    minimized=false,
                    clickAction = "target",
                    ctrlLMacro = "",
                    ctrlRMacro = "",
                    shiftLMacro = "",
                    shiftRMacro = "",
                    leftMacro = "",
                    rightMacro = "",
                }
            end
            generateMainDiscoFrame(discoVars.discoMainFrame)
            generateDiscoSubframes(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame)
            DiscoHealerOptionsPanel.tempSettings = DiscoSettings
            generateOptionsPanel()
            discoHealerLoaded = true
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
            if DiscoSettings.minimized then
                minimizeFrames(discoVars.discoMainFrame, discoVars.discoSubframes, discoVars.discoOverlaySubframes)
            end
        end
    end


    -- Handler for party changes
    function eventHandlers:GROUP_ROSTER_UPDATE()
        discoVars.allPartyMembers = getAllPartyUnitIDs()
        if InCombatLockdown() or discoHealerLoaded == false then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
        end
    end

    -- Handler for leave combat
    function eventHandlers:PLAYER_REGEN_ENABLED()
        discoVars.discoMainFrame.texture:SetAlpha(0.3)
        if framesNeedUpdate then
            framesNeedUpdate = false
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
        end
    end

    -- Handler for enter combat
    function eventHandlers:PLAYER_REGEN_DISABLED()
        discoVars.discoMainFrame.texture:SetAlpha(0.4)
    end

    -- Raid group updated
    function eventHandlers:RAID_TARGET_UPDATE()
        discoVars.allPartyMembers = getAllPartyUnitIDs()
        if InCombatLockdown() or discoHealerLoaded == false then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
        end
    end

    function eventHandlers:PLAYER_TARGET_CHANGED()
        -- untarget current target
        if discoVars.discoSubframes[playerTarget] then
            discoVars.discoOverlaySubframes[playerTarget]:untarget()
        end
        -- new target
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        targetUid = guidToUid[UnitGUID("target")]
        playerTarget = targetUid
        if discoVars.discoSubframes[targetUid] then
            discoVars.discoOverlaySubframes[targetUid]:target()
        end
    end

    function eventHandlers:PLAYER_ENTERING_WORLD()
        discoVars.allPartyMembers = getAllPartyUnitIDs()
        if InCombatLockdown() or discoHealerLoaded == false then
            framesNeedUpdate = true
        else
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
            clearThreat(discoVars.discoOverlaySubframes, unitTargetList)
        end
    end

    -- Combat log event for threat
    function eventHandlers:COMBAT_LOG_EVENT_UNFILTERED()
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

        local currentTime = GetTime()
        if currentTime - unitTargetThrottle > 0.2 then
            updateTargetListFull(discoVars.allPartyMembers, discoVars.discoOverlaySubframes, unitTargetList)
            removeExpiredThreat(discoVars.discoOverlaySubframes, unitTargetList)
            unitTargetThrottle = currentTime
        end

        if subevent == "UNIT_DIED" then
            removeThreat(destGUID, discoVars.discoOverlaySubframes, unitTargetList)
        end
    end

    -- Healcomm incoming heal function
    function healcommCallbacks:HealStarted(event, casterGUID, spellID, spellType, endTime, ...)
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            targetID = guidToUid[playerGUID]
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                casterId = guidToUid[casterGUID]
                if casterId and UnitIsUnit(casterId, "player") then
                    local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellID)
                    castTargetGUID = playerGUID
                    discoVars.playerCastTimer = endTime
                    discoVars.castTicker = C_Timer.NewTicker(0.01, function() UpdateCastBar(discoVars.discoOverlaySubframes[targetID].castbar); end, castTime*0.1)
                end
                -- Update health bars
                updateHealthForUid(targetID, discoVars.discoSubframes, priorityList, castTargetGUID, discoVars.playerCastTimer)
            end
        end
    end

    -- Healcomm heal stopped function
    function healcommCallbacks:HealStopped(event, casterGUID, spellID, spellType, endTime, ...)
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            targetID = guidToUid[playerGUID]
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                casterId = guidToUid[casterGUID]
                if casterId and UnitIsUnit(casterId, "player") then
                    discoVars.castTicker:Cancel()
                    discoVars.castPercent = 0
                    discoVars.discoOverlaySubframes[targetID].castbar:SetValue(0)
                    castTargetGUID = nil
                end
                -- Update Healthbars
                updateHealthForUid(targetID, discoVars.discoSubframes, priorityList, castTargetGUID, discoVars.playerCastTimer)
            end
        end
    end

    -- Healcomm heal delayed function
    function healcommCallbacks:HealDelayed(event, casterGUID, spellID, spellType, endTime, ...)
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            targetID = guidToUid[playerGUID]
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                casterId = guidToUid[casterGUID]
                if casterId and UnitIsUnit(casterId, "player") then
                    local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellID)
                    castTargetGUID = playerGUID
                    discoVars.playerCastTimer = endTime
                    discoVars.castTicker:Cancel()
                    discoVars.castPercent = math.max(0, discoVars.castPercent - 50000 / castTime)
                    --discoVars.discoOverlaySubframes[targetID].castbar:SetValue(math.max(0, discoVars.castPercent - 50000 / castTime))
                    discoVars.castTicker = C_Timer.NewTicker(0.01, function() UpdateCastBar(discoVars.discoOverlaySubframes[targetID].castbar); end, (endTime - GetTime()) / 0.01)
                end
                -- Update Healthbars
                updateHealthForUid(targetID, discoVars.discoSubframes, priorityList, castTargetGUID, discoVars.playerCastTimer)
            end
        end
    end

    -- Attach all handlers to discoMainFrame
    discoVars.discoMainFrame:SetScript("OnEvent", function(self, event, ...)
        eventHandlers[event](self, ...); -- call one of the functions above
    end)
    for k, v in pairs(eventHandlers) do
        discoVars.discoMainFrame:RegisterEvent(k); -- Register all events for which handlers have been defined
    end

    -- Initialize combat health
    LibCLHealth.RegisterCallback(discoVars.discoMainFrame, "COMBAT_LOG_HEALTH", function(event, unitId, eventType)
        if discoVars.discoSubframes[unitId] then
            updateHealthForUid(unitId, discoVars.discoSubframes, priorityList, castTargetGUID, discoVars.playerCastTimer)
        end
    end)

    -- Initialize Healcomm
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStarted", "HealStarted")
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStopped", "HealStopped")
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealDelayed", "HealDelayed")

    -- Timers called every 10s
    local function cleanup()
        updateHealthFull(discoVars.allPartyMembers, discoVars.discoSubframes, priorityList, castTargetGUID, discoVars.playerCastTimer)
        updateTargetListFull(discoVars.allPartyMembers, discoVars.discoOverlaySubframes, unitTargetList)
        removeExpiredThreat(discoVars.discoOverlaySubframes, unitTargetList)
        C_Timer.After(10, cleanup)
    end
    cleanup()
    
end

-- Helper function to calculater priority
function calculatePriority(unitID, playerTargetGUID, playerCastTime)
    unitGUID = UnitGUID(unitID)
    local unitHealth = LibCLHealth.UnitHealth(unitID)
    if unitHealth == 0 then
        return 0
    end
    local healTimer = GetTime() + DiscoSettings.castLookAhead
    -- Calculate which cast timer to use
    if unitGUID == playerTargetGUID and playerCastTime > GetTime() then
        if playerCastTime > GetTime() then
            healTimer = playerCastTime
        end
    end
    local healAmount = (HealComm:GetOthersHealAmount(unitGUID, HealComm.ALL_HEALS, healTimer) or 0) * HealComm:GetHealModifier(unitGUID)
    local percentage = (unitHealth + healAmount)/UnitHealthMax(unitID)
    priority = (1-percentage) * 1000
    if priority < 0 then
        return 0
    end
    return priority
end

-- Maintain priority queue
function updatePriorityList(unitId, priorityList, playerTargetGUID, playerCastTime)
    local queueSize = 5
    local newPriority = calculatePriority(unitId, playerTargetGUID, playerCastTime)
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
function updateHealthForUid(unitId, subframes, priorityList, playerTargetGUID, playerCastTime)
    updateSubframeHealth(unitId, subframes, playerTargetGUID, playerCastTime)
    local index = string.match (unitId, "%d+")
    local currentCastTarget = playerTargetGUID == UnitGUID(unitId) and GetTime() < playerCastTime
    -- Player and maintanks always updated
    if (UnitIsUnit(unitId, "player") or currentCastTarget or select(10, GetRaidRosterInfo(index)) == "MAINTANK") and UnitInRange(unitId)then
        local priority = calculatePriority(unitId, playerTargetGUID, playerCastTime)
        if priority > 1 and priority < 999 then
            updateRaidSubframes(unitId, nil, subframes)
        else
            updateRaidSubframes(nil, unitId, subframes)
        end
    else
        local _, remove = updatePriorityList(unitId, priorityList, playerTargetGUID, playerCastTime)
        local found = false
        -- See if unit in priorityList
        for _, v in pairs(priorityList) do
            if unitId == v.unitId then
                -- Todo: remove alpha
                --subframes[unitId]:SetAlpha(1)
                subframes[unitId].alpha = 1
                subframes[unitId]:SetHidden()
                found = true
            end
        end
        if not found then
            subframes[unitId]:SetHidden()
        end
        -- Hide any frames that were removed from priority list
        if remove then
            subframes[remove]:SetHidden()
        end
    end
end

-- Update subframe health
function updateSubframeHealth(unitId, subframes, playerTargetGUID, playerCastTime)

    local healTimer = GetTime() + DiscoSettings.castLookAhead
    -- Calculate which cast timer to use
    if unitGUID == playerTargetGUID and playerCastTime > GetTime() then
        if playerCastTime > GetTime() then
            healTimer = playerCastTime
        end
    end

    local healAmount = HealComm:GetHealAmount(UnitGUID(unitId), HealComm.ALL_HEALS, healTimer) or 0
    local unitHealth = LibCLHealth.UnitHealth(unitId)
    local ratio = (unitHealth + healAmount)/UnitHealthMax(unitId)
    local healthRatio = unitHealth/UnitHealthMax(unitId)
    local inrange = select(1, UnitInRange(unitId)) or unitId == "player"

    if subframes[unitId]==nil then
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
    elseif healthRatio < 0.33 then
        subframes[unitId].texture:SetColorTexture(0.8, 0, 0)
        subframes[unitId].alpha = 0.7
    elseif healthRatio < 0.66 then
        subframes[unitId].texture:SetColorTexture(0.8, 0.4, 0)
        subframes[unitId].alpha = 0.4
    else
        subframes[unitId].texture:SetColorTexture(0.2, 0.2, 0.2)
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    end

    if not inrange then
        subframes[unitId].alpha = subframes[unitId].defaultAlpha
    end
end

-- Sweep through all party members and update health
-- Should only be called every 10s or so to clean up
function updateHealthFull(allPartyMembers, subframes, priorityList, playerTargetGUID, playerCastTime)
    for _, unitID in pairs(allPartyMembers) do
        if not string.find(unitID, "pet") then
            updateHealthForUid(unitID, subframes, priorityList, playerTargetGUID, playerCastTime)
        end
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
            allGroupIDs[#allGroupIDs+1] = pkey
        end
    end
    return allGroupIDs
end

-- Update raid subframes
-- add and remove are both unitIDs
function updateRaidSubframes(add, remove, subframes)
    if add ~= nil then
        subframes[add].alpha = 1
        subframes[add]:SetHidden()
    end

    if remove ~= nil then
        subframes[remove]:SetHidden()
    end
end

main()