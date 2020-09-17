local addonName, discoVars = ...

local HealComm = LibStub("LibHealComm-4.0", true)
local LibCLHealth = LibStub("LibCombatLogHealth-1.0")
local HealEstimator = HealEstimator

local major = "DiscoHealer"
local minor = 1
local DiscoHealer = LibStub:NewLibrary(major, minor)

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

-- Helper function to calculater priority
--[[
local function calculatePriority(unitID, playerTargetGUID, playerCastTime)
    local unitGUID = UnitGUID(unitID)
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
    local priority = (1-percentage) * 1000
    if priority < 1 then
        return 0
    end
    return priority
end
]]

-- Maintain priority queue
local function updatePriorityList(unitID, priorityList, newPriority)
    local queueSize = 5
    local add, remove
    local inRange = select(1, UnitInRange(unitID)) or UnitIsUnit(unitID, "player")
    local maxPriority = newPriority

    -- Check if already in priority list
    local addedFlag = false
    local unitIndex = nil
    for i=1, #priorityList do
        if priorityList[i].unitID == unitID then
            unitIndex = i
            --[[
            -- Remove dead and full health units
            if newPriority<10 or newPriority>999 or not inRange then
                remove = priorityList[i].unitID
                priorityList[i] = nil
            -- Update priority
            else
                add = priorityList[i].unitID
                priorityList[i] = {priority=newPriority, unitID=unitID}
            end
            addedFlag = true
            ]]
        else
            if priorityList[i].priority > maxPriority then
                maxPriority = priorityList[i].priority
            end
        end
    end

    local shouldAdd = not (newPriority<10 or newPriority>999 or not inRange or (maxPriority > 150 and newPriority < 50) or (#priorityList == queueSize and (newPriority-priorityList[#priorityList].priority) < 50))

    -- Update existing entry
    if unitIndex then
        if shouldAdd then
            add = priorityList[unitIndex].unitID
            priorityList[unitIndex] = {priority=newPriority, unitID=unitID}
        else
            remove = priorityList[unitIndex].unitID
            priorityList[unitIndex] = nil
        end
    -- No existing entry, should add
    elseif shouldAdd then
        add = unitID
        priorityList[#priorityList+1] = {priority=newPriority, unitID=unitID}
    -- New entry ignored
    else
        return
    end

    -- Full health, dead, and out of range units are ignored
    --[[
    if addedFlag == false and (newPriority<10 or newPriority>999 or not inRange or (maxPriority > 150 and newPriority < 75) or (#priorityList == queueSize and (newPriority-priorityList[#priorityList].priority) < 50)) then
        return
    end

    if addedFlag == false and inRange then
        add = unitID
        priorityList[#priorityList+1] = {priority=newPriority, unitID=unitID}
    end
    ]]

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
            remove = priorityList[queueSize+1].unitID
            priorityList[queueSize+1] = nil
        end
    end
    
    return add, remove
end

-- Perform all health bar, texture color, alpha, and priority queue updates
local function updateHealthForUID(unitID, subframes, priorityList, playerTargetGUID, playerCastTime)
    if not unitID or subframes[UnitGUID(unitID)]==nil then
        print("Error, updateSubframeHealth called on nonexistant unitID: ", unitID)
        return
    end

    local unitGUID = UnitGUID(unitID)
    local fs = DiscoSettings.frameSize or 1
    local subframe = subframes[unitGUID]
    -- Update subframe health
    local currentTime = GetTime()
    local healTimer = currentTime + DiscoSettings.castLookAhead
    local isActiveCastTarget = playerTargetGUID == unitGUID and currentTime < playerCastTime
    -- Use playerCastTime instead of lookahead if active target
    if isActiveCastTarget then
        healTimer = playerCastTime + 0.1
    end
    local estimatedHealAmount = HealEstimator:GetHealAmount(unitGUID, healTimer) * HealComm:GetHealModifier(unitGUID)
    local hcHealAmount = (HealComm:GetOthersHealAmount(unitGUID, HealComm.ALL_HEALS, healTimer) or 0) * HealComm:GetHealModifier(unitGUID)
    local healAmount = estimatedHealAmount + hcHealAmount
    local playerHealAmount = healAmount + (HealComm:GetHealAmount(unitGUID, HealComm.ALL_HEALS, playerCastTime, UnitGUID("player")) or 0) * HealComm:GetHealModifier(unitGUID)
    local unitHealth = LibCLHealth.UnitHealth(unitID)
    local maxHealth = UnitHealthMax(unitID)
    local healthRatio = unitHealth/maxHealth
    local inRange = select(1, UnitInRange(unitID)) or UnitIsUnit(unitID, "player")
    local newPriority = (1 - (hcHealAmount + unitHealth + estimatedHealAmount * 0.75) / maxHealth) * 1000
    -- Full health or mind controlled
    if newPriority < 1 or UnitIsEnemy(unitID, "player") then
        newPriority = 0
    end

    subframe.healthBar:SetMinMaxValues(0, maxHealth)
    subframe.healthBar:SetValue(unitHealth)
    subframe.healBar:SetMinMaxValues(0, maxHealth)
    subframe.healBar:SetValue(healAmount + unitHealth)
    subframe.playerHealBar:SetMinMaxValues(0, maxHealth)
    subframe.playerHealBar:SetValue(playerHealAmount + unitHealth)

    if healthRatio > 0.66 then
        subframe.alpha = subframe.defaultAlpha
        subframe.texture:SetColorTexture(0.2, 0.2, 0.2)
    elseif healthRatio > 0.33 then
        subframe.alpha = subframe.defaultAlpha
        subframe.texture:SetColorTexture(0.8, 0.4, 0)
    elseif not UnitIsDeadOrGhost(unitID) then
        subframe.alpha = subframe.defaultAlpha
        subframe.texture:SetColorTexture(0.8, 0, 0)
    else
        -- Unit is dead
        subframe.texture:SetColorTexture(0.2, 0.2, 0.2)
        subframe.alpha = 0.30
        subframe.subtext:SetText("(Dead)")
        subframe.text:SetPoint("BOTTOM", subframe, "TOP", 0, -14*fs)
        subframe.healBar:SetValue(0)
        subframe.healthBar:SetValue(0)
        subframe.playerHealBar:SetValue(0)
        return
    end

    -- No need to check unit alive because of return
    subframe.subtext:SetText("")
    subframe.text:SetPoint("BOTTOM", subframe, "TOP", 0, -17*fs)

    -- Player, Maintanks, and CastTarget always displayed if in range, and are separate from priority list
    local index = string.match (unitID, "%d+")
    if UnitIsUnit(unitID, "player") or (GetNumGroupMembers() < 6 or isActiveCastTarget or index and select(10, GetRaidRosterInfo(index)) == "MAINTANK") and inRange then
        if healthRatio > 0.999 or UnitIsEnemy(unitID, "player") then
            subframe.alpha = subframe.defaultAlpha
        elseif not UnitIsDeadOrGhost(unitID) then
            subframe.alpha = 1
        end
        subframe:SetHidden()
        return
    end

    -- Update priority list
    local _, remove = updatePriorityList(unitID, priorityList, newPriority)

    -- Hide any frames that were removed from priority list
    if remove and UnitGUID(remove) ~= playerTargetGUID then
        subframes[unitGUID].alpha = subframe.defaultAlpha
        subframes[unitGUID]:SetHidden()
    end
    
    -- See if unit in priorityList
    for i=1, #priorityList do
        if unitID == priorityList[i].unitID then
            subframe.alpha = 1
        end
    end

    if not inRange then
        subframe.alpha = subframe.defaultAlpha
    end
    subframe:SetHidden()

end

-- Sweep through all party members and update health
-- Called every 10s to clean up
local function updateHealthFull(allPartyMembers, subframes, overlayFrames, mainFrame, priorityList, playerTargetGUID, playerCastTime)
    local framesNeedUpdate = false
    for i=1, #allPartyMembers do
        if not string.find(allPartyMembers[i], "pet") or DiscoSettings.showPets then
            if not subframes[UnitGUID(allPartyMembers[i])] then
                print("Need update")
                framesNeedUpdate = true
            end
            updateHealthForUID(allPartyMembers[i], subframes, priorityList, playerTargetGUID, playerCastTime)
        end
    end
    if framesNeedUpdate and not InCombatLockdown() then
        recreateAllSubFrames(subframes, overlayFrames, mainFrame, allPartyMembers)
    end
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
    end

    if targetedFriendlyGUID and overlayFrames[targetedFriendlyGUID] then
        unitThreatList[enemyGUID] = {enemyName=UnitName(enemyID), friendlyName=UnitName(enemyID.."target"), threatGuid=targetedFriendlyGUID, timestamp=GetTime()}
        if UnitClassification(enemyID) ~= "worldboss" then
            overlayFrames[targetedFriendlyGUID].threatFrame:SetAlpha(0.75)
        else
            overlayFrames[targetedFriendlyGUID].bossThreatFrame:SetAlpha(0.75)
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
            -- Check player in range
            if select(1, UnitInRange(unitID)) or UnitIsUnit(unitID, "player") then
                subframes[unitID]:SetHidden()
            -- Unit is Mind Controlled
            elseif UnitIsEnemy(unitID, "player") then
                subframes[unitID]:SetAlpha(subframes[unitID].defaultAlpha)
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
            -- DEFAULT SETTINGS
            if DiscoSettings == nil then
                DiscoSettings = {
                    frameSize=1,
                    showNames=true,
                    showPets=false,
                    castLookAhead=4,
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
            recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers, playerTarget)
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
                recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
                clearThreat(discoVars.discoOverlaySubframes, unitTargetList)
            end
        end
    end

    -- Combat Log
    function eventHandlers:COMBAT_LOG_EVENT_UNFILTERED()
        local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, _, spellName, _, healAmount, _, _, crit = CombatLogGetCurrentEventInfo()
        local estimatedTargetGUID = UnitGUID((sourceName or "") .. "-target") or sourceGUID

        local trackedHealer = HealEstimator:GetTrackedHealer(sourceGUID)

        if subevent == "SPELL_CAST_START" and trackedHealer then
            --local estimatedTargetGUID = trackedHealer.targetGUID or sourceGUID
            --local estimatedQueueTargetGUID = trackedHealer.targetGUID3 or sourceGUID
            if HealEstimator:IsDirectHeal(spellName) then
                --[[
                local _, _, _, _, endTime, _, castID, _, spellID = CastingInfo(sourceName)
                print(CastingInfo(sourceName))
                print(ChannelInfo(sourceName))
                ]]
                HealEstimator:RecordHeal(sourceGUID, estimatedTargetGUID, spellName, GetTime())
                updateHealthForUID(HealComm:GetGUIDUnitMapTable()[estimatedTargetGUID], discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
            end
        elseif subevent == "SPELL_HEAL" then
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
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            targetID = guidToUid[playerGUID]
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                casterId = guidToUid[casterGUID]
                if casterId and UnitIsUnit(casterId, "player") and spellType == HealComm.DIRECT_HEALS then
                    discoVars.castTargetGUID = playerGUID
                    discoVars.playerCastTimer = endTime
                    --discoVars.castTicker = C_Timer.NewTicker(0.01, function() UpdateCastBar(discoVars.discoOverlaySubframes[castTargetGUID].castbar); end, castTime*0.1)
                    UpdateCastBar(discoVars.discoOverlaySubframes[targetID].castBarFrame, 0.01, castTime)
                end
                -- Update health bars
                updateHealthForUID(targetID, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
            end
        end

        HealEstimator:UntrackHealer(casterGUID)
    end

    -- Healcomm heal stopped function
    function healcommCallbacks:HealStopped(event, casterGUID, spellID, spellType, interrupted, ...)
        local guidToUid = HealComm:GetGUIDUnitMapTable()
        for i=1, select("#", ...) do
            local playerGUID = select(i, ...)
            targetID = guidToUid[playerGUID]
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                casterId = guidToUid[casterGUID]
                if casterId and UnitIsUnit(casterId, "player") then
                    discoVars.castTargetGUID = nil
                    discoVars.discoOverlaySubframes[targetID].castBarFrame.castAnimationGroup:Stop()
                end
                -- Update Healthbars
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
            targetID = guidToUid[playerGUID]
            if targetID and discoVars.discoSubframes[targetID] then
                -- Update cast bar
                casterId = guidToUid[casterGUID]
                if casterId and UnitIsUnit(casterId, "player") then
                    local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellID)
                    discoVars.castTargetGUID = playerGUID
                    discoVars.playerCastTimer = endTime
                    --discoVars.castTicker:Cancel()
                    --discoVars.castPercent = math.max(0.01, discoVars.castPercent - 50000 / castTime)
                    --discoVars.castTicker = C_Timer.NewTicker(0.01, function() UpdateCastBar(discoVars.discoOverlaySubframes[castTargetGUID].castbar); end, (endTime - GetTime()) / 0.01)
                    local remainingCast = endTime - GetTime()
                    local castPercent = math.max(0.01, (castTime * 0.001 - remainingCast) / (castTime * 0.001))
                    discoVars.discoOverlaySubframes[targetID].castBarFrame.castAnimationGroup:Stop()
                    UpdateCastBar(discoVars.discoOverlaySubframes[targetID].castBarFrame, castPercent, remainingCast)
                    
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
        end
        if checkResetTimer("UPDATE_SLOW", timeDelta, 10) then
            HealEstimator:ListTrackedHealers()
            discoVars.allPartyMembers = getAllPartyUnitIDs()
            updateHealthFull(discoVars.allPartyMembers, discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
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
        if discoVars.discoSubframes[unitID] then
            updateHealthForUID(unitID, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
        end
    end)

    -- Initialize Healcomm
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStarted", "HealStarted")
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealStopped", "HealStopped")
    HealComm.RegisterCallback(healcommCallbacks, "HealComm_HealDelayed", "HealDelayed")

    --[[
    -- Timers called every 10s
    local function cleanup()
        updateHealthFull(discoVars.allPartyMembers, discoVars.discoSubframes, priorityList, discoVars.castTargetGUID, discoVars.playerCastTimer)
        C_Timer.After(10, cleanup)
    end
    cleanup()

    -- Timers called every 0.2s
    local function updateFrequent()
        updatePartyMembersFrequent(discoVars.allPartyMembers, discoVars.discoSubframes, discoVars.discoOverlaySubframes, unitTargetList)

        --updateTargetListFull(discoVars.allPartyMembers, discoVars.discoOverlaySubframes, unitTargetList)
        removeExpiredThreat(discoVars.discoOverlaySubframes, unitTargetList)
        --updatePartyMemberRange(discoVars.allPartyMembers, discoVars.discoSubframes)

        C_Timer.After(0.2, updateFrequent)
    end
    updateFrequent()
    ]]


end
main()