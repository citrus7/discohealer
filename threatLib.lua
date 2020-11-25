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

    -- enemy target changed
    if unitThreatList[enemyGUID] and (unitThreatList[enemyGUID].threatGUID ~= highThreatGuid or threatValue<100) then
        overlayFrames[unitThreatList[enemyGUID].threatGUID].threatFrame:SetAlpha(0)
    end

    if highThreatGuid and threatValue>100 and overlayFrames[highThreatGuid] then
        unitThreatList[enemyGUID] = {threatGUID=highThreatGuid, timestamp=time()}
        overlayFrames[highThreatGuid].threatFrame:SetAlpha(0.75)
    else
        unitThreatList[enemyGUID] = nil
    end
end

-- Check if unitGUID in threat list and clear threat
function removeThreat(unitGUID, overlayFrames, unitThreatList, playerMapping)
    if unitThreatList[unitGUID] then
        overlayFrames[unitThreatList[unitGUID].threatGUID].threatFrame:SetAlpha(0)
        overlayFrames[unitThreatList[unitGUID].threatGUID].bossThreatFrame:SetAlpha(0)
        playerMapping[unitThreatList[unitGUID].threatGUID].isBossTarget = false
        unitThreatList[unitGUID] = nil
    end
end

-- Clears all threat
function clearThreat(overlayFrames, unitThreatList)
    for guid, threatInfo in pairs(unitThreatList) do
        overlayFrames[threatInfo.threatGUID].threatFrame:SetAlpha(0)
        unitThreatList[guid] = nil
    end
end