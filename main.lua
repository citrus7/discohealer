local addonName, discoVars = ...

local HealComm = LibStub("LibHealComm-4.0", true)
local LibCLHealth = LibStub("LibCombatLogHealth-1.0")
local HealEstimator = HealEstimator

local major = "DiscoHealer"
local minor = 1
local DiscoHealer = LibStub:NewLibrary(major, minor)

-- Constants
local DiscoQueueSize = 5

-- Cache Commonly Used Global Functions
local GetTime = GetTime;
local CheckInteractDistance = CheckInteractDistance;
local GetNumGroupMembers = GetNumGroupMembers;
local UnitInRange = UnitInRange;
local IsSpellInRange = IsSpellInRange;
local UnitDetailedThreatSituation = UnitDetailedThreatSituation;
local UnitIsCharmed = UnitIsCharmed;
local UnitCanAttack = UnitCanAttack;
local UnitClassification = UnitClassification;
local UnitName = UnitName;
local UnitGUID = UnitGUID;
local UnitIsEnemy = UnitIsEnemy;
local UnitIsTrivial = UnitIsTrivial;
local GetSpellCooldown = GetSpellCooldown;
local HasFullControl = HasFullControl;
local pairs = pairs;
local UnitThreatSituation = UnitThreatSituation;
local UnitHasIncomingResurrection = UnitHasIncomingResurrection;
local InCombatLockdown = InCombatLockdown;
local type = type;
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo;

local DISCO_atan2 = math.atan2;
local DISCO_PI, DISCO_2_PI = math.pi, math.pi * 2;

-- Default Settings
discoVars.defaultSettings = {
    frameSize=1,
    showNames=true,
    showPets=false,
    estimateHeals=true,
    castLookAhead=4,
    minimized=false,
    clickAction = "target",
    ctrlLMacro = "",
    ctrlRMacro = "",
    shiftLMacro = "",
    shiftRMacro = "",
    leftMacro = "",
    rightMacro = "",
    lowPrioRGB = {r=0.2, g=0.2, b=0.2},
    medPrioRGB = {r=0.9, g=0.45, b=0},
    highPrioRGB = {r=0.8, g=0, b=0},
    arrangeByGroup = false
}

-- Maintain priority queue
local function updatePriorityList(unitGUID, priorityList, newPriority)
    local queueSize = DiscoQueueSize
    local add, remove
    --local inRange = select(1, UnitInRange(unitID)) or UnitIsUnit(unitID, "player")
    local maxPriority = newPriority

    -- Check if already in priority list
    local addedFlag = false
    local unitIndex = nil
    for i=1, #priorityList do
        if priorityList[i].unitGUID == unitGUID then
            unitIndex = i
        else
            if priorityList[i].priority > maxPriority then
                maxPriority = priorityList[i].priority
            end
        end
    end

    local shouldAdd = not (newPriority<10 or newPriority>999 or (maxPriority > 150 and newPriority < 50) or (#priorityList == queueSize and (newPriority-priorityList[#priorityList].priority) < 50))

    -- Update existing entry
    if unitIndex then
        if shouldAdd then
            add = priorityList[unitIndex].unitGUID
            priorityList[unitIndex] = {priority=newPriority, unitGUID=unitGUID}
        else
            remove = priorityList[unitIndex].unitGUID
            priorityList[unitIndex] = nil
        end
    -- No existing entry, should add
    elseif shouldAdd then
        add = unitGUID
        priorityList[#priorityList+1] = {priority=newPriority, unitGUID=unitGUID}
    -- New entry ignored
    else
        return
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
            remove = priorityList[queueSize+1].unitGUID
            priorityList[queueSize+1] = nil
        end
    end
    
    return add, remove
end

-- Perform all health bar, texture color, alpha, and priority queue updates
local function updateHealthForUID(unitID, subframes, priorityList, playerTargetGUID, playerCastTime)
    if not unitID or subframes[UnitGUID(unitID)]==nil then
        --print("Error, updateSubframeHealth called on nonexistant unitID: ", unitID)
        return
    end

    local unitGUID = UnitGUID(unitID)
    local playerInfo = discoVars.playerMapping[unitGUID]
    if not playerInfo then
        print("unkown ", unitID)
        return
    end
    local fs = DiscoSettings.frameSize or 1
    local subframe = subframes[unitGUID]
    local unitIsDead = UnitIsDeadOrGhost(unitID)
    -- Update subframe health
    local currentTime = GetTime()
    playerInfo.lastUpdated = currentTime
    local healTimer = currentTime + 3
    local isActiveCastTarget = playerTargetGUID == unitGUID and currentTime < playerCastTime
    local unitHealth = LibCLHealth.UnitHealth(unitID)
    playerInfo.unitHealth = unitHealth
    local maxHealth = UnitHealthMax(unitID)
    local healthRatio = unitHealth/maxHealth
    local healModifier = HealComm:GetHealModifier(unitGUID)
    -- Use playerCastTime instead of lookahead if active target
    --[[
    if isActiveCastTarget then
        healTimer = playerCastTime + 0.1
        hotHealTimer = healTimer
    else
        if healthRatio > 0.7 then
            healTimer = currentTime + 2
        end
        playerCastTime = currentTime + 3
    end
    ]]
    local estimatedHealAmount, estimatedHealAccuracy = 0, 0
    if DiscoSettings.estimateHeals then estimatedHealAmount, estimatedHealAccuracy = HealEstimator:GetHealAmount(unitGUID, healTimer); end
    estimatedHealAmount = estimatedHealAmount * healModifier
    --local hcHealAmount = ((HealComm:GetOthersHealAmount(unitGUID, HealComm.CASTED_HEALS, healTimer) or 0) + (HealComm:GetOthersHealAmount(unitGUID, HealComm.HOT_HEALS, hotHealTimer) or 0)) * healModifier
    local hcHealAmount = (HealComm:GetOthersHealAmount(unitGUID, HealComm.ALL_HEALS, healTimer) or 0) * healModifier
    local healAmount = estimatedHealAmount + hcHealAmount
    local playerHealAmount, otherHealAmount = 0, 0
    if isActiveCastTarget then
        otherHealAmount = (HealComm:GetOthersHealAmount(unitGUID, HealComm.ALL_HEALS, playerCastTime) or 0) * healModifier
        playerHealAmount = otherHealAmount + (HealComm:GetHealAmount(unitGUID, HealComm.ALL_HEALS, playerCastTime, UnitGUID("player")) or 0) * healModifier
    end
    local inRange = select(1, UnitInRange(unitID)) or UnitIsUnit(unitID, "player")
    local newPriority = (1 - (hcHealAmount + unitHealth + (estimatedHealAmount * estimatedHealAccuracy)) / maxHealth) * 1000
    -- Full health or mind controlled
    if newPriority < 1 or UnitIsEnemy(unitID, "player") or not inRange then
        newPriority = 0
    end
    -- Don't display estimated heals for players below 70%
    if estimatedHealAccuracy < 0.7 then
        estimatedHealAmount = 0
    end
    local overhealAmount = unitHealth + playerHealAmount + healAmount - otherHealAmount - maxHealth
    if overhealAmount < 0 then overhealAmount = 0; end

    if maxHealth ~= playerInfo.maxHealth then
        playerInfo.maxHealth = maxHealth
        subframe.healthBar:SetMinMaxValues(0, maxHealth)
        subframe.healBar:SetMinMaxValues(0, maxHealth)
        subframe.playerHealBar:SetMinMaxValues(0, maxHealth)
        subframe.otherHealBar:SetMinMaxValues(0, maxHealth)
        subframe.overhealBar:SetMinMaxValues(0, maxHealth)
    end
    
    subframe.healthBar:SetValue(unitHealth)
    subframe.healBar:SetValue(healAmount + unitHealth)
    subframe.playerHealBar:SetValue(playerHealAmount + unitHealth)
    subframe.otherHealBar:SetValue(otherHealAmount + unitHealth)
    subframe.overhealBar:SetValue(overhealAmount)

    if newPriority < 400 then
        subframe.alpha = subframe.defaultAlpha
        subframe.texture:SetColorTexture(DiscoSettings.lowPrioRGB.r, DiscoSettings.lowPrioRGB.g, DiscoSettings.lowPrioRGB.b)
    elseif newPriority < 650 then
        subframe.alpha = subframe.defaultAlpha
        subframe.texture:SetColorTexture(DiscoSettings.medPrioRGB.r, DiscoSettings.medPrioRGB.g, DiscoSettings.medPrioRGB.b)
    elseif not UnitIsDeadOrGhost(unitID) then
        subframe.alpha = subframe.defaultAlpha
        subframe.texture:SetColorTexture(DiscoSettings.highPrioRGB.r, DiscoSettings.highPrioRGB.g, DiscoSettings.highPrioRGB.b)
    else
        -- Unit is dead
        subframe.texture:SetColorTexture(DiscoSettings.lowPrioRGB.r, DiscoSettings.lowPrioRGB.g, DiscoSettings.lowPrioRGB.b)
        subframe.alpha = 0.30
        subframe.healBar:SetValue(0)
        subframe.healthBar:SetValue(0)
        subframe.playerHealBar:SetValue(0)
        newPriority = 0
    end

    -- Unit death status changed
    if unitIsDead ~= playerInfo.unitIsDead then
        playerInfo.unitIsDead = unitIsDead
        if not unitIsDead then
            subframe.subtext:SetText("")
            subframe.text:SetPoint("BOTTOM", subframe, "TOP", 0, -17*fs)
        else
            subframe.subtext:SetText("(Dead)")
            subframe.text:SetPoint("BOTTOM", subframe, "TOP", 0, -14*fs)
        end
    end

    -- Player, Maintanks, and CastTarget always displayed if in range, and are separate from priority list
    if UnitIsUnit(unitID, "player") or GetNumGroupMembers() < 6 or isActiveCastTarget or playerInfo.isPriority then
        if healthRatio > 0.999 and not discoVars.playerMapping[unitGUID].isBossTarget or UnitIsEnemy(unitID, "player") then
            subframe.alpha = subframe.defaultAlpha
        elseif not UnitIsDeadOrGhost(unitID) and inRange then
            subframe.alpha = 1
        end
        subframe:SetHidden()
        return
    end

    -- Update priority list
    local _, remove = updatePriorityList(unitGUID, priorityList, newPriority)

    --[[
    local priorityLevel = 5
    if newPriority > 600 then
        priorityLevel = 1
    elseif newPriority > 300 then
        priorityLevel = 2
    elseif newPriority > 50 then
        priorityLevel = 3
    elseif newPriority > 1 then
        priorityLevel = 4
    end

    -- Priority changed
    if subframes.priorityLevel ~= priorityLevel then
        local pl = discoVars.priorityLevels[subframes.priorityLevel]
        if pl and pl[unitGUID] then
            pl[unitGUID] = nil
            pl["n"] = pl["n"] - 1
        end
    end
    -- Priority same or new entry
    if priorityLevel < 5 then
        if not discoVars.priorityLevels[priorityLevel][unitGUID] then
            discoVars.priorityLevels[priorityLevel][unitGUID] = true
            discoVars.priorityLevels[priorityLevel]["n"] = discoVars.priorityLevels[priorityLevel]["n"] + 1
        end
    else
        -- TODO: This check shouldn't be necessary
        for i=1, 4 do
            if discoVars.priorityLevels[i][unitGUID] then
                discoVars.priorityLevels[i][unitGUID] = nil
                discoVars.priorityLevels[i]["n"] = discoVars.priorityLevels[i]["n"] -1
            end
        end
    end
    subframes.priorityLevel = priorityLevel

    local raidPriorityLevel, total = 1, 0
    while raidPriorityLevel < 5 and total < 5 do
        total = total + discoVars.priorityLevels[raidPriorityLevel]["n"]
        raidPriorityLevel = raidPriorityLevel + 1
    end
    raidPriorityLevel = 4
    if priorityLevel < raidPriorityLevel then
        subframe.alpha = 1
    else
        subframe.alpha = subframe.defaultAlpha
    end

    -- Priority relaxed, display lower levels
    if raidPriorityLevel > discoVars.raidPriorityLevel then
        for i=discoVars.raidPriorityLevel, raidPriorityLevel+1, -1 do
            for guid, _ in pairs(discoVars.priorityLevels[i]) do
                if guid ~= "n" then
                    subframes[guid]:SetAlpha(1)
                end
            end
        end
    -- Priority increased, hide lower levels
    elseif raidPriorityLevel < discoVars.raidPriorityLevel then
        for i=raidPriorityLevel, discoVars.raidPriorityLevel-1 do
            for guid, _ in pairs(discoVars.priorityLevels[i]) do
                if guid ~= "n" then
                    subframes[guid]:SetAlpha(subframes[guid].defaultAlpha)
                end
            end
        end
    end
    
    discoVars.raidPriorityLevel = raidPriorityLevel
    ]]

    
    -- Hide any frames that were removed from priority list
    --[[
    if remove and UnitGUID(remove) ~= playerTargetGUID then
        subframes[UnitGUID(remove)].alpha = subframe.defaultAlpha
        subframes[UnitGUID(remove)]:SetHidden()
    end
    ]]
    
    -- See if unit in priorityList
    for i=1, #priorityList do
        if unitGUID == priorityList[i].unitGUID then
        --if UnitIsUnit(unitID, priorityList[i].unitID) then
            subframe.alpha = 1
        end
        --print(priorityList[i].unitID)
    end
    
    subframe:SetHidden()

end

-- Get a list of all party/raid unitIDs
-- Raid UnitIDs should be added before party UnitIDs or there may be a bug with MT identification
local function getAllPartyUnitIDs()
    local partySize = GetNumGroupMembers()
    local allGroupIDs = {"player"}
    for i=1, partySize do
        key = "raid" .. i
        pkey = "raidpet" .. i
        if UnitExists(key) then
            allGroupIDs[#allGroupIDs+1] = key
            local classFilename, _ = UnitClassBase(key)
            if classFilename == "PALADIN" or classFilename == "PRIEST" or classFilename == "DRUID" or classFilename == "SHAMAN" then
                HealEstimator:TrackHealer(UnitGUID(key))
            end
        end
        if UnitIsVisible(pkey) then
            allGroupIDs[#allGroupIDs+1] = pkey
        end
    end
    for i=1, min(5, partySize) do
        key = "party" .. i
        pkey = "partypet" .. i
        if UnitExists(key) then
            allGroupIDs[#allGroupIDs+1] = key
            local classFilename, _ = UnitClassBase(key)
            if classFilename == "PALADIN" or classFilename == "PRIEST" or classFilename == "DRUID" or classFilename == "SHAMAN" then
                HealEstimator:TrackHealer(UnitGUID(key))
            end
        end
        if UnitIsVisible(pkey) then
            allGroupIDs[#allGroupIDs+1] = pkey
        end
    end
    if UnitIsVisible("pet") then
        allGroupIDs[#allGroupIDs+1] = "pet"
    end
    return allGroupIDs
end

-- Sweep through all party members and update health
-- Called every 10s to clean up
local function updateHealthFull(allPartyMembers, subframes, overlayFrames, mainFrame, priorityList, playerTargetGUID, playerCastTime)
    for i=1, #allPartyMembers do
        if not string.find(allPartyMembers[i], "pet") or DiscoSettings.showPets then
            --if not subframes[UnitGUID(allPartyMembers[i])] then
            if not discoVars.playerMapping[UnitGUID(allPartyMembers[i])] then
                framesNeedUpdate = true
            elseif not discoVars.playerMapping[UnitGUID(allPartyMembers[i])].lastUpdated or GetTime() - discoVars.playerMapping[UnitGUID(allPartyMembers[i])].lastUpdated > 1 then
                updateHealthForUID(allPartyMembers[i], subframes, priorityList, playerTargetGUID, playerCastTime)
            end
        end
    end
    if framesNeedUpdate and not InCombatLockdown() then
        discoVars.allPartyMembers = getAllPartyUnitIDs()
        recreateAllSubFrames(subframes, overlayFrames, mainFrame, allPartyMembers)
    end
end

-- startCastBar plays a castbar animation
--[[
local function UpdateCastBar(castbar)
    currentTime  = GetTime()
    if currentTime > discoVars.playerCastTimer or discoVars.castPercent > 99 then
        castbar:SetValue(0)
        discoVars.castPercent = 0
        discoVars.castTicker:Cancel()
    else
        local nextPercent = discoVars.castPercent + (100 - discoVars.castPercent) / ((discoVars.playerCastTimer - currentTime) / 0.01)
        discoVars.castPercent = nextPercent
        castbar:SetValue(nextPercent)
    end
end
]]

-- startCastBar plays a castbar animation
local function UpdateCastBar(castBarFrame, currentPercent, remainingCastTime)
    local fs = DiscoSettings.frameSize or 1
    castBarFrame.castAnimationGroup.castbar:SetSize(currentPercent * castBarFrame.size * fs, 25*fs)
    castBarFrame.castAnimationGroup.castbar:SetPoint("CENTER", castBarFrame, "LEFT", currentPercent * castBarFrame.size * 0.5 * fs, 0)
    castBarFrame.castAnimation:SetDuration(remainingCastTime)
    castBarFrame.castAnimation:SetScale(1/currentPercent,1)
    castBarFrame.castAnimationGroup:Play()
end

-- Hide/Show players depending on range
--[[
local function updatePartyMemberRange(allPartyMembers, subframes)
    for i=1, #allPartyMembers do
        local unitID = allPartyMembers[i]
        if subframes[unitID] then
            if select(1, UnitInRange(unitID)) or UnitIsUnit(unitID, "player") then
                subframes[unitID]:SetHidden()
            else
                subframes[unitID]:SetAlpha(subframes[unitID].defaultAlpha)
            end
        end
    end
end
]]

-- Remove threat older than 3 seconds
local function removeExpiredThreat(overlayFrames, unitThreatList)
    for guid, val in pairs(unitThreatList) do
        if (GetTime() - val.timestamp) > 3 then
            removeThreat(guid, overlayFrames, unitThreatList)
        end
    end
end

-- Track targets to see if friendly units are targeted
local function updateTargetedList(enemyID, overlayFrames, unitThreatList)
    -- make sure targeted unit exists and is an enemy
    if not (UnitExists(enemyID) and UnitIsEnemy("player", enemyID)) then
        return
    end
    local enemyGUID = UnitGUID(enemyID)
    local targetedFriendlyGUID = UnitGUID(enemyID .. "target")

    -- Enemy target has changed
    if unitThreatList[enemyGUID] and unitThreatList[enemyGUID].threatGuid ~= targetedFriendlyGUID then
        overlayFrames[unitThreatList[enemyGUID].threatGuid].threatFrame:SetAlpha(0)
        overlayFrames[unitThreatList[enemyGUID].threatGuid].bossThreatFrame:SetAlpha(0)
        discoVars.playerMapping[unitThreatList[enemyGUID].threatGuid].isBossTarget = false
    end

    --if targetedFriendlyGUID and overlayFrames[targetedFriendlyGUID] then
    if targetedFriendlyGUID and discoVars.playerMapping[targetedFriendlyGUID] then
        unitThreatList[enemyGUID] = {enemyName=UnitName(enemyID), friendlyName=UnitName(enemyID.."target"), threatGuid=targetedFriendlyGUID, timestamp=GetTime()}
        if UnitClassification(enemyID) ~= "worldboss" then
            overlayFrames[targetedFriendlyGUID].threatFrame:SetAlpha(0.75)
        else
            overlayFrames[targetedFriendlyGUID].bossThreatFrame:SetAlpha(0.75)
            discoVars.playerMapping[targetedFriendlyGUID].isBossTarget = true
        end
    else
        unitThreatList[enemyGUID] = nil
    end
end

-- Checks called on all party members at a regular interval (0.2s)
local function updatePartyMembersFrequent(allPartyMembers, subframes, overlayFrames, unitThreatList)
    for i=1, #allPartyMembers do
        local unitID = allPartyMembers[i]

        if subframes[unitID] then

            -- Unit is Mind Controlled
            if UnitIsEnemy(unitID, "player") then
                subframes[unitID]:SetAlpha(subframes[unitID].defaultAlpha)
            -- Check player in range
            elseif select(1, UnitInRange(unitID)) or UnitIsUnit(unitID, "player") then
                subframes[unitID]:SetHidden()
            else
                subframes[unitID]:SetAlpha(subframes[unitID].defaultAlpha)
            end

            if UnitIsEnemy(unitID, "player") then
                overlayFrames[unitID].mindControl:SetAlpha(0.65)
            else
                overlayFrames[unitID].mindControl:SetAlpha(0)
            end

             -- Check player resurrection pending
            if UnitHasIncomingResurrection(unitID) then
                overlayFrames[unitID].resurrect:SetAlpha(0.65)
            else
                overlayFrames[unitID].resurrect:SetAlpha(0)
            end
        end

        -- Update targeted friendly party ranges
        updateTargetedList(unitID.."target", overlayFrames, unitThreatList)
    end
end

-- Check Timer for Frequent Updates
local function checkResetTimer(timerName, nextTick, resetTime)
	if discoVars.allTimers[timerName] > 0 then
		discoVars.allTimers[timerName] = discoVars.allTimers[timerName] - nextTick
		if discoVars.allTimers[timerName] <= 0 then
			discoVars.allTimers[timerName] = resetTime;
			return true;
		end
	end
	return false;
end

local function getMapPositionForUnit(mapID, unitID)
    vector = C_Map.GetPlayerMapPosition(mapID, unitID);
    if not vector then return; end

    return vector:GetXY();
end

local function updateArrow()
    local target = discoVars.mouseOverTarget
    if not target then return; end
    local mapID = C_Map.GetBestMapForUnit(target) 
    local pMapID = C_Map.GetBestMapForUnit("player");
    if not mapID or not pMapID or mapID ~= pMapID then return; end

    local inRange = select(1, UnitInRange(target)) or UnitIsUnit(target, "player")
    if not inRange then
        --local orientation = GetPlayerMapPosition(target)
        local x, y = getMapPositionForUnit(mapID, target)
        local pX, pY = getMapPositionForUnit(mapID, "player")
        if (x or 0) + (y or 0) <= 0 or (pX or 0) + (pY or 0) <= 0 then return; end
        local tFacing = GetPlayerFacing();
        tFacing = tFacing < 0 and tFacing + DISCO_2_PI or tFacing

        local direction = 4 * (DISCO_PI - DISCO_atan2(pX - x, y - pY) - tFacing) / DISCO_PI + 0.5
        direction = direction < 0 and direction + 8 or direction
        direction = direction > 7.99 and direction - 0.5 or direction
        --print(direction)

        discoVars.discoOverlaySubframes[target].arrow:SetAlpha(1)
        discoVars.discoOverlaySubframes[target].arrow:SetTexCoord(getArrowCoords(math.floor(direction) + 1))
    else
        discoVars.discoOverlaySubframes[target].arrow:SetAlpha(0)
    end

end

-- MAIN
local function main()
    discoVars.discoMainFrame = CreateFrame("FRAME", "DiscoMainFrame", UIParent)
    discoHealerLoaded = false
    discoVars.castTargetGUID = nil
    guidToUid = HealComm:GetGUIDUnitMapTable()
    discoVars.discoSubframes = {}
    discoVars.discoOverlaySubframes = {}
    discoVars.allPartyMembers = {}
    -- Player mapping is GUID to {key, unitName, unitIDs = {unitID}}
    discoVars.playerMapping = {}
    unitTargetList = {}
    unitTargetThrottle = 0
    priorityList = {}
    healcommCallbacks = {}
    playerTarget = "target"
    framesNeedUpdate = true
    discoVars.castTicker = nil
    discoVars.castPercent = 0
    discoVars.playerCastTimer = 0
    discoVars.mmouseOverTarget = nil
    rotatingUpdateTarget = 1

    --discoVars.raidPriorityLevel = 5
    --discoVars.priorityLevels = {[1]={n=0},[2]={n=0},[3]={n=0},[4]={n=0}}

    discoVars.allTimers = {
        --["UPDATE_VERY_FREQUENT"] = 0.1,
        ["UPDATE_FREQUENT"] = 0.2,
        ["UPDATE_SEMI_FREQUENT"] = 1,
        ["UPDATE_SLOW"] = 10,
    }

    local eventHandlers = {}

    -- INIT function for DiscoHealer
    function eventHandlers:ADDON_LOADED(addonName)
        if addonName == "DiscoHealer" then
            if DiscoSettings == nil then
                DiscoSettings = discoVars.defaultSettings
            else
                for key, val in pairs(discoVars.defaultSettings) do
                    if not DiscoSettings[key] then
                        DiscoSettings[key] = discoVars.defaultSettings[key]
                    end
                end
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
            discoVars.allPartyMembers = getAllPartyUnitIDs()
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers, playerTarget)
        end
    end

    -- Handler for leave combat
    function eventHandlers:PLAYER_REGEN_ENABLED()
        discoVars.discoMainFrame.texture:SetAlpha(0.3)
        if framesNeedUpdate then
            framesNeedUpdate = false
            discoVars.allPartyMembers = getAllPartyUnitIDs()
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
        end
    end

    -- Handler for enter combat
    function eventHandlers:PLAYER_REGEN_DISABLED()
        discoVars.discoMainFrame.texture:SetAlpha(0.4)
    end

    --[[
    function eventHandlers:UNIT_TARGET()
        print("unit target")
    end
    ]]

    -- Handler for player target changed
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
            discoVars.allPartyMembers = getAllPartyUnitIDs()
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
            clearThreat(discoVars.discoOverlaySubframes, unitTargetList)
        end
    end

    function eventHandlers:UNIT_PET()
        if DiscoSettings.showPets then
            discoVars.allPartyMembers = getAllPartyUnitIDs()
            if InCombatLockdown() or discoHealerLoaded == false then
                framesNeedUpdate = true
            else
                discoVars.allPartyMembers = getAllPartyUnitIDs()
                recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
                clearThreat(discoVars.discoOverlaySubframes, unitTargetList)
            end
        end
    end

    -- Combat Log
    function eventHandlers:COMBAT_LOG_EVENT_UNFILTERED()
        local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, _, spellName, _, healAmount, _, _, crit = CombatLogGetCurrentEventInfo()
        local estimatedTargetGUID = UnitGUID((sourceName or "") .. "-target") or sourceGUID
        local estimateHeals = DiscoSettings.estimateHeals

        local trackedHealer = HealEstimator:GetTrackedHealer(sourceGUID)

        if estimateHeals and subevent == "SPELL_CAST_START" and trackedHealer then
            --local estimatedTargetGUID = trackedHealer.targetGUID or sourceGUID
            --local estimatedQueueTargetGUID = trackedHealer.targetGUID3 or sourceGUID
            if HealEstimator:IsDirectHeal(spellName) then
                HealEstimator:RecordHeal(sourceGUID, estimatedTargetGUID, spellName, GetTime())
                updateHealthForUID(HealComm:GetGUIDUnitMapTable()[estimatedTargetGUID], discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
            end
        elseif estimateHeals and subevent == "SPELL_HEAL" then
            if trackedHealer and HealEstimator:IsDirectHeal(spellName) and discoVars.discoSubframes[destGUID] then
                HealEstimator:VerifyHeal(sourceGUID, destGUID, spellName, healAmount, crit, GetTime())
            end
        --[[
        elseif subevent == "SPELL_CAST_FAILED" then
            HealEstimator:CancelHeal(sourceGUID)
        ]]
        elseif subevent == "UNIT_DIED" then
            removeThreat(destGUID, discoVars.discoOverlaySubframes, unitTargetList)
        end
        
    end


    -- Healcomm incoming heal function
    function healcommCallbacks:HealStarted(event, casterGUID, spellID, spellType, endTime, ...)
        local castTime = endTime - GetTime()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            --local targetID = HealComm:GetGUIDUnitMapTable()[playerGUID]
            local _, _, _, _, _, targetID, _ = GetPlayerInfoByGUID(playerGUID)
            if not targetID then
                if discoVars.playerMapping[playerGUID] then
                    targetID = discoVars.playerMapping[playerGUID].unitName
                else
                    framesNeedUpdate = true
                end
            end
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                local casterID = guidToUid[casterGUID]
                if casterID and UnitIsUnit(casterID, "player") and spellType == HealComm.DIRECT_HEALS then
                    discoVars.castTargetGUID = playerGUID
                    discoVars.playerCastTimer = endTime
                    UpdateCastBar(discoVars.discoOverlaySubframes[playerGUID].castBarFrame, 0.01, castTime)
                end
                -- Update health bars
                updateHealthForUID(targetID, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
            end
        end

        HealEstimator:UntrackHealer(casterGUID)
    end

    local timeHealStopped = GetTime()
    -- Healcomm heal stopped function
    function healcommCallbacks:HealStopped(event, casterGUID, spellID, spellType, interrupted, ...)
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            --local targetID = guidToUid[playerGUID]
            local _, _, _, _, _, targetID, _ = GetPlayerInfoByGUID(playerGUID)
            if not targetID then
                if discoVars.playerMapping[playerGUID] then
                    targetID = discoVars.playerMapping[playerGUID].unitName
                else
                    framesNeedUpdate = true
                end
            end
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                local casterID = guidToUid[casterGUID]
                if casterID and UnitIsUnit(casterID, "player") then
                    discoVars.castTargetGUID = nil
                    discoVars.discoOverlaySubframes[playerGUID].castBarFrame.castAnimationGroup:Stop()
                end
                -- Update Healthbars
                updateHealthForUID(targetID, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
                if interrupted then
                    updateHealthForUID(targetID, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
                end
            end
        end
    end

    -- Healcomm heal delayed function
    function healcommCallbacks:HealDelayed(event, casterGUID, spellID, spellType, endTime, ...)
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            --local targetID = guidToUid[playerGUID]
            local _, _, _, _, _, targetID, _ = GetPlayerInfoByGUID(playerGUID)
            if not targetID then
                if discoVars.playerMapping[playerGUID] then
                    targetID = discoVars.playerMapping[playerGUID].unitName
                else
                    framesNeedUpdate = true
                end
            end
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                local casterID = guidToUid[casterGUID]
                if casterID and UnitIsUnit(casterID , "player") then
                    local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellID)
                    discoVars.castTargetGUID = playerGUID
                    discoVars.playerCastTimer = endTime
                    --discoVars.castTicker:Cancel()
                    --discoVars.castPercent = math.max(0.01, discoVars.castPercent - 50000 / castTime)
                    --discoVars.castTicker = C_Timer.NewTicker(0.01, function() UpdateCastBar(discoVars.discoOverlaySubframes[castTargetGUID].castbar); end, (endTime - GetTime()) / 0.01)
                    local remainingCast = endTime - GetTime()
                    local castPercent = math.max(0.01, (castTime * 0.001 - remainingCast) / (castTime * 0.001))
                    discoVars.discoOverlaySubframes[playerGUID].castBarFrame.castAnimationGroup:Stop()
                    UpdateCastBar(discoVars.discoOverlaySubframes[playerGUID].castBarFrame, castPercent, remainingCast)
                    
                end
                -- Update Healthbars
                updateHealthForUID(targetID, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
            end
        end
    end

    -- Update Frequent
    local function UpdateFrequent(self, timeDelta)
        --[[
        if checkResetTimer("UPDATE_VERY_FREQUENT", timeDelta, 0.1) then
            HealEstimator:UpdateTargets()
        end
        ]]
        if checkResetTimer("UPDATE_FREQUENT", timeDelta, 0.2) then
            updatePartyMembersFrequent(discoVars.allPartyMembers, discoVars.discoSubframes, discoVars.discoOverlaySubframes, unitTargetList)
            updateArrow()
        end
        if checkResetTimer("UPDATE_SEMI_FREQUENT", timeDelta, 1) then
            removeExpiredThreat(discoVars.discoOverlaySubframes, unitTargetList)
            if framesNeedUpdate and not InCombatLockdown() then
                framesNeedUpdate = false
                discoVars.allPartyMembers = getAllPartyUnitIDs()
                recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
            end
        end

        if checkResetTimer("UPDATE_SLOW", timeDelta, 10) then
            HealEstimator:ListTrackedHealers()
            if not InCombatLockdown() then
                updateHealthFull(discoVars.allPartyMembers, discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
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

    discoVars.discoMainFrame:SetScript("OnUpdate", UpdateFrequent)

    -- Initialize combat health
    LibCLHealth.RegisterCallback(discoVars.discoMainFrame, "COMBAT_LOG_HEALTH", function(event, unitID, eventType)
        --[[
        local unitName = (UnitName(unitID))
        if discoVars.discoSubframes[unitName] then
            updateHealthForUID(unitName, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
        else
            print(unitID, " ", unitName)
        end
        ]]
        if discoVars.discoSubframes[unitID] then
            updateHealthForUID(unitID, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
        else
            print(unitID)
        end
    end)

    -- Initialize Healcomm
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStarted", "HealStarted")
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStopped", "HealStopped")
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealDelayed", "HealDelayed")

end
main()