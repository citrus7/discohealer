debugTime = 0

-- Track enemies from every single party member
--[[
function updateThreatListFull(overlayFrames, unitThreatList)
    local partySize = GetNumGroupMembers()
    for i=1, partySize do
        key = "raid" .. i
        updateThreatList(key, overlayFrames, unitThreatList)
    end
    if partySize < 6 then
        for i=1, partySize do
            key = "party" .. i
            updateThreatList(key, overlayFrames, unitThreatList)
        end
    end
    updateThreatList("player", overlayFrames, unitThreatList)
end
]]

-- Track enemies from every single party member
function updateTargetListFull(allPartyMembers, overlayFrames, unitThreatList)
    --[[
    local partySize = GetNumGroupMembers()
    updateTargetedList("target", overlayFrames, unitThreatList)
    for i=1, partySize do
        key = "raid" .. i
        pkey = "raidpet" .. i
        if UnitExists(key) then
            updateTargetedList(key.."target", overlayFrames, unitThreatList)
        end
        if UnitExists(pkey) then
            updateTargetedList(key.."target", overlayFrames, unitThreatList)
        end
    end
    for i=1, min(5, partySize) do
        key = "party" .. i
        pkey = "partypet" .. i
        if UnitExists(key) then
            updateTargetedList(key.."target", overlayFrames, unitThreatList)
        end
        if UnitExists(pkey) then
            updateTargetedList(key.."target", overlayFrames, unitThreatList)
        end
    end
    ]]
    for _,v in pairs(allPartyMembers) do
        updateTargetedList(v.."target", overlayFrames, unitThreatList)
    end
end

-- Track targets to see if friendly units are targeted
function updateTargetedList(enemyId, overlayFrames, unitThreatList)
    -- make sure targeted unit exists and is an enemy
    if not (UnitExists(enemyId) and UnitIsEnemy("player", enemyId)) then
        return
    end

    local enemyGuid = UnitGUID(enemyId)
    local targetedFriendlyGuid = UnitGUID(enemyId .. "target")

    -- enemy target changed
    if unitThreatList[enemyGuid] and unitThreatList[enemyGuid].threatGuid ~= targetedFriendlyGuid then
        overlayFrames[unitThreatList[enemyGuid].threatGuid].threatFrame:SetAlpha(0)
    end

    if targetedFriendlyGuid and overlayFrames[targetedFriendlyGuid] then
        unitThreatList[enemyGuid] = {enemyName=UnitName(enemyId), friendlyName=UnitName(enemyId.."target"), threatGuid=targetedFriendlyGuid, timestamp=time()}
        if UnitInRange(UnitName(enemyId.."target")) then
            overlayFrames[targetedFriendlyGuid]:setThreatHigh()
        else
            overlayFrames[targetedFriendlyGuid]:setThreatMedium()
        end
    else
        unitThreatList[enemyGuid] = nil
    end
end

-- Track enemy targets using combat logs
--[[
function updateThreatListCombatTemp(friendlyUnitName, overlayFrames, unitThreatList)

    if not UnitIsEnemy("player", friendlyUnitName .. "-target") then
        return
    end
    local targetedFriendlyUnitName = (UnitName(friendlyUnitName .. "-target-target"))
    local enemyUnitGuid = UnitGUID(friendlyUnitName .. "-target")

    if unitThreatList[enemyUnitGuid] and unitThreatList[enemyUnitGuid].unitName ~= targetedFriendlyUnitName then
        overlayFrames[unitThreatList[enemyUnitGuid].unitName].threatFrame:SetAlpha(0)
    end

    if not targetedFriendlyUnitName or not overlayFrames[targetedFriendlyUnitName] then
        return
    end

    unitThreatList[enemyUnitGuid] = {unitName=targetedFriendlyUnitName, timestamp=time()}
    overlayFrames[targetedFriendlyUnitName].threatFrame:SetAlpha(0.5)
end
]]

-- Iterates mob list and updates threat
function refreshThreat(overlayFrames, unitThreatList)
    for mobGUID, unitGUID in pairs(unitThreatList) do
        --print(mobGUID, " -> ", ThreatLib:GetMaxThreatOnTarget(mobGUID))
        updateThreatListCombat(mobGUID, overlayFrames, unitThreatList)
    end
    --print("---")
end

-- Update list of party units with high threat
function updateThreatListCombat(enemyGUID, overlayFrames, unitThreatList)
    local threatValue, highThreatGuid = ThreatLib:GetMaxThreatOnTarget(enemyGUID)
    --print("t: ", threatValue, " tar: ", highThreatGuid)
    --[[
    if time() - debugTime > 30 then
        for k, v in pairs(unitThreatList) do
            print(k, " ", v.threatGuid)
            t,t2 = ThreatLib:GetMaxThreatOnTarget(k)
            print(t, " ", t2)
        end
        debugTime = time()
    end
    ]]

    -- Testing
    -- IterateGroupThreatForTarget currently does not return threat values
    --[[
    local threatIter, t, k = ThreatLib:IterateGroupThreatForTarget(destGUID)
    for i=1, 3 do
        local tarGuid  = threatIter(t,nil)
        if not tarGuid then
            return
        end
        print("tar: ", tarGuid)

        -- enemy target changed
        if unitThreatList[enemyGUID] and unitThreatList[enemyGUID].threatGuid ~= highThreatGuid then
            overlayFrames[unitThreatList[enemyGUID].threatGuid].threatFrame:SetAlpha(0)
        end

        if overlayFrames[tarGuid] then
            unitThreatList[enemyGUID] = {threatGuid=tarGuid, timestamp=time()}
            overlayFrames[tarGuid].threatFrame:SetAlpha(0.75)
        else
            unitThreatList[enemyGUID] = nil
        end
    end
    ]]

    -- enemy target changed
    if unitThreatList[enemyGUID] and (unitThreatList[enemyGUID].threatGuid ~= highThreatGuid or threatValue<100) then
        overlayFrames[unitThreatList[enemyGUID].threatGuid].threatFrame:SetAlpha(0)
    end

    if highThreatGuid and threatValue>100 and overlayFrames[highThreatGuid] then
        unitThreatList[enemyGUID] = {threatGuid=highThreatGuid, timestamp=time()}
        overlayFrames[highThreatGuid].threatFrame:SetAlpha(0.75)
    else
        unitThreatList[enemyGUID] = nil
    end
end

function removeExpiredThreat(overlayFrames, unitThreatList)
    --[[
    local doPrint = false
    if time() - debugTime > 30 then
        doPrint = true
        debugTime = time()
    end
    ]]
    for guid, val in pairs(unitThreatList) do
        if (time() - val.timestamp) > 3 then
            removeThreat(guid, overlayFrames, unitThreatList)
        end
        --[[
        if doPrint then
            print(val.enemyName, " -> ", val.friendlyName)
        end
        ]]
    end
end

-- Check if unitGUID in threat list and clear threat
function removeThreat(unitGUID, overlayFrames, unitThreatList)
    if unitThreatList[unitGUID] then
        overlayFrames[unitThreatList[unitGUID].threatGuid].threatFrame:SetAlpha(0)
        unitThreatList[unitGUID] = nil
    end
end

-- Clears all threat
function clearThreat(overlayFrames, unitThreatList)
    for guid, threatInfo in pairs(unitThreatList) do
        overlayFrames[threatInfo.threatGuid].threatFrame:SetAlpha(0)
        unitThreatList[guid] = nil
    end
end