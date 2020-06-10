-- Track enemies from every single party member
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

-- Track targets to see if friendly units are targeted
--[[
function updateThreatList(unitId, overlayFrames, unitThreatList)
    --print((UnitName(unitId .. "targettarget")))
    local enemyUnitGuid
    local targetedFriendlyUnitName

    if UnitIsEnemy("player", unitId) then
        enemyUnitGuid = UnitGUID(unitId)
        targetedFriendlyUnitName = (UnitName(unitId .. "target"))
    elseif UnitIsEnemy("player", unitId .. "target") then
        enemyUnitGuid = UnitGUID(unitId .. "target")
        targetedFriendlyUnitName = (UnitName(unitId .. "targettarget"))
    else
        return
    end

    if overlayFrames[targetedFriendlyUnitName] then
        if unitThreatList[enemyUnitGuid] and unitThreatList[enemyUnitGuid].unitName ~= targetedFriendlyUnitName then
            overlayFrames[unitThreatList[enemyUnitGuid].unitName].threatFrame:SetAlpha(0)
        end
        unitThreatList[enemyUnitGuid] = {unitName=targetedFriendlyUnitName, timestamp=time()}
        overlayFrames[targetedFriendlyUnitName].threatFrame:SetAlpha(0.5)
    end
end
]]

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

-- Update max threat
function updateThreatListCombat(enemyGUID, overlayFrames, unitThreatList)
    local _, highThreatGuid = ThreatLib:GetMaxThreatOnTarget(enemyGUID)
    
    -- enemy target changed
    if unitThreatList[enemyGUID] and unitThreatList[enemyGUID].threatGuid ~= highThreatGuid then
        overlayFrames[unitThreatList[enemyGUID].threatGuid].threatFrame:SetAlpha(0)
    end

    if highThreatGuid and overlayFrames[highThreatGuid] then
        unitThreatList[enemyGUID] = {threatGuid=highThreatGuid, timestamp=time()}
        overlayFrames[highThreatGuid].threatFrame:SetAlpha(0.75)
    else
        unitThreatList[enemyGUID] = nil
    end
end

function removeExpiredThreat(overlayFrames, unitThreatList)
    for guid, val in pairs(unitThreatList) do
        if (time() - val.timestamp) > 3 then
            removeThreat(guid, overlayFrames, unitThreatList)
            print("expired threat removed - is this even called?")
        end
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