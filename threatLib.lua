-- Track enemies from every single party member
function updateTargetListFull(allPartyMembers, overlayFrames, unitThreatList)
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
    for guid, val in pairs(unitThreatList) do
        if (time() - val.timestamp) > 3 then
            removeThreat(guid, overlayFrames, unitThreatList)
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