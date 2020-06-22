-- Initialize the main DiscoHealer frame
function generateMainDiscoFrame(discoSettings)
    local mainFrame = CreateFrame("FRAME", "DiscoMainFrame", UIParent)
    mainFrame:SetSize(500*discoSettings.frameSize, 130*discoSettings.frameSize)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetPoint("CENTER", UIParent, "CENTER")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame.texture = mainFrame:CreateTexture(nil, "BACKGROUND")
    mainFrame.texture:SetAllPoints(mainFrame)
    mainFrame.texture:SetColorTexture(1,1,1)
    mainFrame.texture:SetAlpha(0.1)

    return mainFrame
end

-- Initialize subframes
function generateDiscoSubframes(subframes, overlaySubframes, discoMainFrame, discoSettings)

    local function createSubFrame(i, subframes, frameType, discoSettings)
        local fs = discoSettings.frameSize or 1
        local key = i
        if frameType == "large" then
            key = "large" .. i
        end

        -- Generate subframes
        subframes[key] = CreateFrame("BUTTON", "DiscoRaidSubFrame" .. key, discoMainFrame, "SecureActionButtonTemplate")
        subframes[key]:RegisterForClicks("AnyDown")
        --[[
        subframes[key].leftClick = CreateFrame("BUTTON", "DiscoRaidSubFrameLeftClick" .. key, subframes[key])
        subframes[key].leftClick:SetAllPoints(subframes[key])
        subframes[key].leftClick:RegisterForClicks("LeftButtonDown")
        subframes[key].leftClick:SetSize(100*fs, 25*fs)
        subframes[key].leftClick:SetText("button")
        subframes[key].leftClick.texture = subframes[key].leftClick:CreateTexture(nil, "BACKGROUND")
        subframes[key].leftClick.texture:SetAllPoints(subframes[key])
        subframes[key].leftClick.texture:SetColorTexture(0.5,1,0.5)
        subframes[key].leftClick.texture:SetAlpha(0.3)
        ]]

        subframes[key].texture = subframes[key]:CreateTexture(nil, "BACKGROUND")
        subframes[key].texture:SetAllPoints(subframes[key])
        subframes[key].texture:SetColorTexture(0.5,1,0.5)
        subframes[key].texture:SetAlpha(0.3)

        subframes[key].healthBar = CreateFrame("StatusBar", nil, subframes[key])
        subframes[key].healthBar:SetFrameStrata("MEDIUM")
        subframes[key].healthBar:SetPoint("CENTER", subframes[key], "CENTER", 0, 0)
        subframes[key].healthBar:SetStatusBarTexture(0,0.65,0)

        subframes[key].healBar = CreateFrame("StatusBar", nil, subframes[key])
        subframes[key].healBar:SetFrameStrata("LOW")
        subframes[key].healBar:SetPoint("CENTER", subframes[key], "CENTER", 0, 0)
        subframes[key].healBar:SetStatusBarTexture(0,0.2,1)

        subframes[key].textFrame = CreateFrame("FRAME", "DiscoRaidTextSubFrame"..key, subframes[key])
        subframes[key].textFrame:SetFrameStrata("MEDIUM")
        subframes[key].text = subframes[key].textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subframes[key].text:SetPoint("BOTTOM", subframes[key], "TOP", 0, -17*fs)

        if frameType == "large" then
            subframes[key]:SetSize(100*fs, 25*fs)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*100*fs, -2*fs)

            subframes[key].healthBar:SetSize(95*fs, 20*fs)
            subframes[key].healBar:SetSize(95*fs, 20*fs)

            subframes[key].defaultAlpha = 0.2
        else
            subframes[key]:SetSize(50*fs, 25*fs)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*50*fs, math.floor((i-0.1)/10)*-25*fs-30*fs)

            subframes[key].healthBar:SetSize(45*fs, 20*fs)
            subframes[key].healBar:SetSize(45*fs, 20*fs)
            
            subframes[i].text:Hide()

            subframes[key].defaultAlpha = 0.05
        end

        -- Frame alpha settings
        subframes[key].alpha = subframes[key].defaultAlpha
        subframes[key].setHidden = function(self)
            self:SetAlpha(self.alpha)
        end

        subframes[key]:SetAlpha(0)
    end

    -- Generate overlay for frame
    local function createSubFrameOverlay(i, subframes, frameType, discoSettings)
        local fs = discoSettings.frameSize or 1
        local key
        if frameType == "large" then
            key = "large" .. i
        else
            key = i
        end
        subframes[key]=CreateFrame("FRAME", "DiscoRaidSubFrameOverlay"..key, discoMainFrame)
        subframes[key]:SetFrameStrata("HIGH")

        subframes[key].threatFrame = CreateFrame("FRAME", "DiscoRaidThreatSubFrame"..key, subframes[key])
        subframes[key].threatFrame:SetPoint("CENTER", subframes[key], "TOPLEFT", 7*fs, -7*fs)
        subframes[key].threatFrame:SetSize(12, 12)
        subframes[key].threatFrame:SetAlpha(0)

        subframes[key].textureH = subframes[key].threatFrame:CreateTexture(nil, "BACKGROUND")
        subframes[key].textureH:SetAllPoints(subframes[key].threatFrame)
        subframes[key].textureH:SetColorTexture(1,0.2,0.2)
        subframes[key].textureH:SetGradientAlpha("HORIZONTAL", 1,0.2,0.2,0.5, 1,0.2,0.2,0)

        subframes[key].textureV = subframes[key].threatFrame:CreateTexture(nil, "BACKGROUND")
        subframes[key].textureV:SetAllPoints(subframes[key].threatFrame)
        subframes[key].textureV:SetColorTexture(1,0.2,0.2)
        subframes[key].textureV:SetGradientAlpha("VERTICAL", 1,0.2,0.2,0, 1,0.2,0.2,0.5)

        subframes[key].targeted = CreateFrame("StatusBar", nil, subframes[key])
        subframes[key].targeted:SetFrameStrata("HIGH")
        subframes[key].targeted:SetPoint("CENTER", subframes[key], "BOTTOM", 0, 0)
        subframes[key].targeted:SetStatusBarTexture(0.9,0.9,0.9)
        subframes[key].targeted:SetAlpha(0)

        subframes[key].textFrame = CreateFrame("FRAME", "DiscoRaidThreatTextSubFrame"..key, subframes[key])
        subframes[key].textFrame:SetFrameStrata("HIGH")
        subframes[key].text = subframes[key].textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subframes[key].text:SetPoint("BOTTOM", subframes[key], "TOP", 0, -16)
        subframes[key].text:SetText("T")
        subframes[key].text:SetTextColor(1,0,0)
        subframes[key].textFrame:SetAlpha(0)


        subframes[key].castBarFrame = CreateFrame("FRAME", "DiscoRaidCastBarSubFrame"..key, subframes[key])

        subframes[key].castAnimationGroup = subframes[key].castBarFrame:CreateAnimationGroup()
        subframes[key].castAnimationGroup:SetLooping("NONE")
        subframes[key].castAnimationGroup:SetScript("OnPlay", function(self)
            self.castBar:SetAlpha(0.3)
        end)
        subframes[key].castAnimationGroup:SetScript("OnStop", function(self)
            self.castBar:SetAlpha(0)
        end)
        subframes[key].castAnimationGroup:SetScript("OnFinished", function(self)
            self.castBar:SetAlpha(0)
        end)

        subframes[key].castAnimationGroup.castBar = subframes[key].castBarFrame:CreateTexture(nil, "HIGH")
        subframes[key].castAnimationGroup.castBar:SetPoint("CENTER", subframes[key], "LEFT", 0, 0)
        subframes[key].castAnimationGroup.castBar:SetSize(1*fs, 25*fs)
        subframes[key].castAnimationGroup.castBar:SetColorTexture(0.9, 0.9, 0.9)
        subframes[key].castAnimationGroup.castBar:SetAlpha(0)

        subframes[key].castAnimation = subframes[key].castAnimationGroup:CreateAnimation("SCALE")
        subframes[key].castAnimation:SetOrigin("LEFT",0,0)


        if frameType == "large" then
            subframes[key]:SetSize(100*fs, 25*fs)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*100*fs, 0)
            subframes[key].targeted:SetSize(100*fs, 3.5*fs)
            subframes[key].threatAlphaMedium = 0.75
            subframes[key].threatAlphaHigh = 0.75
            subframes[key].castAnimation:SetScale(100,1)
        else
            subframes[key]:SetSize(50*fs, 25*fs)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*50*fs, math.floor((i-0.1)/10)*-25*fs-30*fs)
            subframes[key].targeted:SetSize(50*fs, 3.5*fs)
            subframes[key].threatAlphaMedium = 0.15
            subframes[key].threatAlphaHigh = 0.75
            subframes[key].castAnimation:SetScale(50,1)
        end

        subframes[key].target = function(self)
            self.targeted:SetAlpha(1)
        end
        subframes[key].untarget = function(self)
            self.targeted:SetAlpha(0)
        end

        subframes[key].setThreatMedium = function(self)
            self.threatFrame:SetAlpha(self.threatAlphaMedium)
        end
        subframes[key].setThreatHigh = function(self)
            self.threatFrame:SetAlpha(self.threatAlphaHigh)
        end

        subframes[key]:SetAlpha(1)
    end

    -- Generate all large and regular subframes
    for i=1, 40 do
        createSubFrame(i, subframes, nil, discoSettings)
        createSubFrameOverlay(i, overlaySubframes, nil, discoSettings)
    end

    for i=1, 5 do
        createSubFrame(i, subframes, "large", discoSettings)
        createSubFrameOverlay(i, overlaySubframes, "large", discoSettings)
    end
end

-- Redraw all the subframes when the party changes
function recreateAllSubFrames(subframes, overlayFrames, mainframe, discoSettings, allPartyMembers)
    local partySize = GetNumGroupMembers()
    -- guid to {key, unitIDs}
    local playerMapping = {[UnitGUID("player")]={key="large1", unitName=UnitName("player"), unitIDs={player=""}}}
    -- Create player mapping
    local j,k= 2,1
    for _, key in pairs(allPartyMembers) do
        if not string.find(key, "pet") then
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
            if discoSettings.leftClickAction == "target" then
                subframes[v.key]:SetAttribute("type", "target")
                subframes[v.key]:SetAttribute("unit", unitId)
            elseif discoSettings.leftClickAction == "cast" then
                subframes[v.key]:SetAttribute("type", "spell")
                subframes[v.key]:SetAttribute("spell", "Flash Of Light(rank 4)")
                subframes[v.key]:SetAttribute("target", unitId)
            end
        end
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

    resizeMainFrame(k, mainframe, discoSettings)
end

-- Set frame onClick attributes
function setOnClickActions()

end

-- Resize the main disco healer frame
-- This function can only be called out of combat
function resizeMainFrame(nextFrame, mainframe, discoSettings)
    local fs = discoSettings.frameSize
    if nextFrame == 1 then
        discoMainFrame:SetSize(500*fs, 28*fs)
    elseif nextFrame <12 then
        discoMainFrame:SetSize(500*fs, 56*fs)
    elseif nextFrame < 22 then
        discoMainFrame:SetSize(500*fs, 82*fs)
    elseif nextFrame < 32 then
        discoMainFrame:SetSize(500*fs, 108*fs)
    else
        discoMainFrame:SetSize(500*fs, 134*fs)
    end
end