DiscoFrameSize = 1.5

-- Initialize the main DiscoHealer frame
function generateMainDiscoFrame()
    local mainFrame = CreateFrame("FRAME", "DiscoMainFrame", UIParent)
    mainFrame:SetSize(500, 130)
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
function generateDiscoSubframes(subframes, overlaySubframes, discoMainFrame)
    
    local function createSubFrame(i, subframes, frameType)
        local key = i
        if frameType == "large" then
            key = "large" .. i
        end

        -- Generate subframes
        subframes[key] = CreateFrame("BUTTON", "DiscoRaidSubFrame" .. key, discoMainFrame, "SecureActionButtonTemplate")
        subframes[key]:RegisterForClicks("AnyDown")

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
        subframes[key].textFrame:SetFrameStrata("HIGH")
        subframes[key].text = subframes[key].textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subframes[key].text:SetPoint("BOTTOM", subframes[key], "TOP", 0, -15)

        subframes[key]:SetAttribute("type", "target")

        if frameType == "large" then
            subframes[key]:SetSize(90, 20)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*100+5, -5)

            subframes[key].healthBar:SetSize(85, 15)
            subframes[key].healBar:SetSize(85, 15)

            subframes[key].defaultAlpha = 0.2
        else
            subframes[key]:SetSize(40, 20)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*50+5, math.floor((i-0.1)/10)*-25-30)

            subframes[key].healthBar:SetSize(35, 15)
            subframes[key].healBar:SetSize(35, 15)
            
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
    local function createSubFrameOverlay(i, subframes, frameType)
        local key
        if frameType == "large" then
            key = "large" .. i
        else
            key = i
        end
        subframes[key]=CreateFrame("FRAME", "DiscoRaidSubFrameOverlay"..key, discoMainFrame)
        subframes[key]:SetFrameStrata("HIGH")

        subframes[key].threatFrame = CreateFrame("FRAME", "DiscoRaidThreatSubFrame"..key, subframes[key])
        --subframes[key].threatFrame:SetAllPoints(subframes[key])
        subframes[key].threatFrame:SetPoint("CENTER", subframes[key], "TOPLEFT", 7, -7)
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

        if frameType == "large" then
            subframes[key]:SetSize(90, 20)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*100+5, -5)
            subframes[key].targeted:SetSize(90, 3)
        else
            subframes[key]:SetSize(40, 20)
            subframes[key]:SetPoint("TOPLEFT", discoMainFrame, "TOPLEFT", (i-1)%10*50+5, math.floor((i-0.1)/10)*-25-30)
            subframes[key].targeted:SetSize(40, 3)
        end

        subframes[key].target = function(self)
            self.targeted:SetAlpha(1)
        end
        subframes[key].untarget = function(self)
            self.targeted:SetAlpha(0)
        end

        subframes[key]:SetAlpha(1)
    end

    -- Generate all large and regular subframes
    for i=1, 40 do
        createSubFrame(i, subframes)
        createSubFrameOverlay(i, overlaySubframes)
    end

    for i=1, 5 do
        createSubFrame(i, subframes, "large")
        createSubFrameOverlay(i, overlaySubframes, "large")
    end
end