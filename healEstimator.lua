local addonName, discoVars = ...

-- Cache Commonly Used Global Functions
local UnitGUID = UnitGUID;
local GetTime = GetTime;
local pairs = pairs;
local _abs = math.abs;
local _insert = table.insert;
local _remove = table.remove;

HealEstimator = {}
local trackedHealers = {}
local untrackedHealers = {}
--[[
local directHeals = {
    8936, 5185, 635, 19750, 2060, 596, 2061, 2054, 2050, 1064, 331, 8004,  
    8938, 5186, 639, 19939, 10963, 996, 9472, 2055, 2052, 10622, 332, 8008, 
    8939, 5187, 647, 19940, 10964, 10960, 9473, 6063, 2053, 10623, 547, 8010, 
    8940, 5188, 1026, 19941, 10965, 10961, 9474, 6064, 913, 10466, 
    8941, 5189, 1042, 19942, 25314, 25316, 10915, 939, 10467, 
    9750, 6778, 3472, 19943, 10916, 959, 10468, 
     9856, 8903, 10328, 10917, 8005, 
    9857, 9758, 10329, 10395,  
    9858, 9888, 25292, 10396, 
    9889, 25357, 
    25297
}
]]

local directHeals = {
    ["Healing Touch"] = {castTime = 3, spellID = 25297},
    ["Greater Heal"] = {castTime = 2.5, spellID = 25314},
    ["Prayer of Healing"] = {castTime = 3, spellID = 25316},
    ["Flash Heal"] = {castTime = 1.5, spellID = 10917},
    ["Lesser Heal"] = {castTime = 2.5, spellID = 2053},
    ["Lesser Healing Wave"] = {castTime = 1.5, spellID = 10468},
    ["Heal"] = {castTime = 2.5, spellID = 6064},
    ["Chain Heal"] = {castTime = 2.5, spellID = 10623},
    ["Flash of Light"] = {castTime = 1.5, spellID = 19943},
    ["Healing Wave"] = {castTime = 3, spellID = 25357},
    ["Holy Light"] = {castTime =2.5 , spellID = 25292},
    ["Regrowth"] = {castTime = 2, spellID = 9858}
}

local healCasts = {}
local healRecipients = {}

--local directHealSpellNames = {}

function HealEstimator:UntrackHealer(unitGUID)
    untrackedHealers[unitGUID] = true
    if trackedHealers[unitGUID] then
        trackedHealers[unitGUID] = nil
    end
end

function HealEstimator:TrackHealer(unitGUID)
    if not trackedHealers[unitGUID] and not untrackedHealers[unitGUID] then
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(unitGUID)
        if not name then return; end
        trackedHealers[unitGUID] = {targetUID = name .. "-target", attempted = 0, correct = 0, healAmounts = {}}
    end
end

function HealEstimator:GetTrackedHealer(unitGUID)
    return trackedHealers[unitGUID]
end

function HealEstimator:ListTrackedHealers()
    for unitGUID, val in pairs(trackedHealers) do
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(unitGUID)
        --print(name, " accuracy: ", val.correct / val.attempted, " total: ", val.attempted)
    end
end

function HealEstimator:IsDirectHeal(spellName)

    --[[
    for i=1, #directHeals do
        name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(directHeals[i])
        if castTime == 0 then
            print(spellId, " ", name)
        end
        --print(GetSpellInfo(directHeals[i]))
    end
    ]]
    
    return directHeals[spellName]
    

end

-- Record a new incomming heal
function HealEstimator:RecordHeal(sourceGUID, estimatedTargetGUID, spellName, startTime)
    local healAmount = 300 * directHeals[spellName].castTime
    if trackedHealers[sourceGUID].healAmounts[spellName] then healAmount = trackedHealers[sourceGUID].healAmounts[spellName].totalHeal / trackedHealers[sourceGUID].healAmounts[spellName].numHeals; end
    local endTime = startTime + directHeals[spellName].castTime
    -- Todo: inefficient use of tables
    local newHeal = {
        endTime = endTime,
        spellName = spellName,
        recipient = estimatedTargetGUID
    }

    -- Combat logs out of order
    if healCasts[sourceGUID] and _abs(startTime - healCasts[sourceGUID].endTime) < 0.2 then
        --print("queued")
        healCasts[sourceGUID].next = newHeal
        local previousHealRecipientTable = healRecipients[healCasts[sourceGUID].recipient]
        if previousHealRecipientTable then
            for i=#previousHealRecipientTable.source, 1, -1 do
                if previousHealRecipientTable.source[i] == sourceGUID then
                    _remove(previousHealRecipientTable.healAmounts, i)
                    _remove(previousHealRecipientTable.endTimes, i)
                    _remove(previousHealRecipientTable.source, i)
                end
            end
        end
    -- Previous heal canceled
    elseif healCasts[sourceGUID] then
        --print("canceled")
        local previousHealRecipientTable = healRecipients[healCasts[sourceGUID].recipient]
        if previousHealRecipientTable then
            for i=#previousHealRecipientTable.source, 1, -1 do
                if previousHealRecipientTable.source[i] == sourceGUID then
                    _remove(previousHealRecipientTable.healAmounts, i)
                    _remove(previousHealRecipientTable.endTimes, i)
                    _remove(previousHealRecipientTable.source, i)
                end
            end
        end
        healCasts[sourceGUID] = newHeal
    -- Regular new heal
    else
        --print("new heal")
        healCasts[sourceGUID] = newHeal
    end

    -- Record heal in healRecipients table
    if trackedHealers[sourceGUID].correct > 0 and trackedHealers[sourceGUID].correct/trackedHealers[sourceGUID].attempted > 0.5 then
        if not healRecipients[estimatedTargetGUID] then 
            healRecipients[estimatedTargetGUID] = {healAmounts = {healAmount}, endTimes = {endTime}, source = {sourceGUID}}
        else
            healRecipients[estimatedTargetGUID].healAmounts[#healRecipients[estimatedTargetGUID].healAmounts + 1] = healAmount
            healRecipients[estimatedTargetGUID].endTimes[#healRecipients[estimatedTargetGUID].endTimes + 1] = endTime
            healRecipients[estimatedTargetGUID].source[#healRecipients[estimatedTargetGUID].source + 1] = sourceGUID
        end
    end
end

-- Called on Heal Landing
function HealEstimator:VerifyHeal(sourceGUID, targetGUID, spellName, healAmount, crit, time)
    if not healCasts[sourceGUID] then
        trackedHealers[sourceGUID].attempted = trackedHealers[sourceGUID].attempted + 1
        return
    end

    -- Negative means landing early, positive means late
    local endDiff = time - healCasts[sourceGUID].endTime

    -- Last heal was expired
    if endDiff > 1 and healCasts[sourceGUID].next then
        healCasts[sourceGUID] = healCasts[sourceGUID].next
    end

    local correctTarget = healCasts[sourceGUID].recipient == targetGUID
    local correctSpell = healCasts[sourceGUID].spellName == spellName

    -- Record Heal Amount
    local ha = trackedHealers[sourceGUID].healAmounts[spellName]
    if ha then
        ha.totalHeal = ha.totalHeal + healAmount
        ha.numHeals = ha.numHeals + 1
    else
        trackedHealers[sourceGUID].healAmounts[spellName] = {
            totalHeal = healAmount,
            numHeals = 1
        }
    end

    -- Check for queued heal
    if healCasts[sourceGUID].next then
        healCasts[sourceGUID] = healCasts[sourceGUID].next
    else
        healCasts[sourceGUID] = nil
    end

    trackedHealers[sourceGUID].attempted = trackedHealers[sourceGUID].attempted + 1
    if correctTarget and correctSpell then
        trackedHealers[sourceGUID].correct = trackedHealers[sourceGUID].correct + 1
    --[[
    else
        local _, _, _, _, _, actualName, _ = GetPlayerInfoByGUID(targetGUID)
        if not correctTarget then
            print("wrong target, estimated ", estName, " got ", actualName)
        elseif not correctSpell then
            print("wrong spell: ", spellName)
        end
    ]]
    end
end

-- Get all heals ending within timeframe
function HealEstimator:GetHealAmount(targetGUID, endTime)
    local currentTime = GetTime()
    local healAmount = 0
    healRecipientTable = healRecipients[targetGUID]

    if healRecipientTable then
        for i=#healRecipientTable.endTimes, 1, -1 do
            if healRecipientTable.endTimes[i] < currentTime then
                _remove(healRecipientTable.healAmounts, i)
                _remove(healRecipientTable.endTimes, i)
                _remove(healRecipientTable.source, i)
            elseif endTime == nil or healRecipientTable.endTimes[i] < endTime then
                healAmount = healAmount + healRecipients[targetGUID].healAmounts[i]
            end
        end
    end

    return healAmount
end


function HealEstimator:UpdateTargets()
    for unitGUID, val in pairs(trackedHealers) do
        --trackedHealers[unitGUID].targetGUID4 = trackedHealers[unitGUID].targetGUID3
        --trackedHealers[unitGUID].targetGUID3 = trackedHealers[unitGUID].targetGUID2
        --trackedHealers[unitGUID].targetGUID2 = trackedHealers[unitGUID].targetGUID
        --trackedHealers[unitGUID].targetGUID = UnitGUID(val.targetUID)
    end
end


--HealEstimator.eventFrame = CreateFrame("Frame")
--[[
HealEstimator:IsDirectHeal()
for i=1, #directHeals do
    local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(directHeals[i])
    directHealSpellNames[name] = directHeals[i]
end


for key,val in pairs(directHealSpellNames) do
    print(GetSpellInfo(val))
end
]]

--[[
local tempTime
HealEstimator.eventFrame:SetScript("OnEvent", function(self, event, ...)
    eventTime = GetTime()
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, _, spellName = CombatLogGetCurrentEventInfo()


    if subevent == "SPELL_CAST_START" then
        print("start")
        --tempTime = GetTime()
        
    elseif subevent == "SPELL_HEAL" then
        print('end')
        --print("interval: ", GetTime() - tempTime)
    end


    if subevent == "SPELL_CAST_START" and HealEstimator:GetTrackedHealer(sourceGUID) then
        estimatedTargetName = UnitName(sourceName .. "-target") or souceName
        estimatedTargetGUID = UnitGUID(sourceName .. "-target") or sourceGUID
        if estimatedTargetGUID and HealEstimator:IsDirectHeal(spellName) and discoVars.discoSubframes[estimatedTargetGUID] then
            HealEstimator:RecordHeal(sourceGUID, estimatedTargetGUID, spellName, eventTime)
        end
        
    elseif subevent == "SPELL_HEAL" then
        if HealEstimator:GetTrackedHealer(sourceGUID) and HealEstimator:IsDirectHeal(spellName) and discoVars.discoSubframes[estimatedTargetGUID] then
            HealEstimator:VerifyHeal(sourceGUID, destGUID, spellName, eventTime)
        end

    end

end)
HealEstimator.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
]]