local addonName, discoVars = ...

SLASH_DISCO1 = "/disco"
SlashCmdList["DISCO"] = function(msg)
    InterfaceOptionsFrame_OpenToCategory("DiscoHealer");
    InterfaceOptionsFrame_OpenToCategory("DiscoHealer");
 end 

DiscoHealerOptionsPanel = {}
DiscoHealerOptionsPanel.panel = CreateFrame( "FRAME", "DiscoHealerPanel", UIParent );
DiscoHealerOptionsPanel.panel.name = "DiscoHealer";

-- Refresh Function
DiscoHealerOptionsPanel.panel.refresh = function() 
    DiscoHealerOptionsPanel.tempSettings = DiscoSettings

    DiscoHealerOptionsPanel.panel.slider:SetValue(DiscoHealerOptionsPanel.tempSettings.frameSize)


    if DiscoHealerOptionsPanel.tempSettings.clickAction == "target" then
        UIDropDownMenu_SetText(DiscoHealerOptionsPanel.panel.actionSelector, "Target Player")
    else
        UIDropDownMenu_SetText(DiscoHealerOptionsPanel.panel.actionSelector, "Cast On Player")
    end


    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetText(DiscoHealerOptionsPanel.tempSettings.leftMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetText(DiscoHealerOptionsPanel.tempSettings.rightMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetText(DiscoHealerOptionsPanel.tempSettings.shiftLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetText(DiscoHealerOptionsPanel.tempSettings.shiftRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlRMacro)

    if not InCombatLockdown() then
        if DiscoSettings.clickAction == "target" then
            DiscoHealerOptionsPanel.panel.spellSelect:Hide()
        elseif DiscoSettings.clickAction == "spell" then
            DiscoHealerOptionsPanel.panel.spellSelect:Show()
        elseif DiscoSettings.clickAction == "macro" then
            DiscoHealerOptionsPanel.panel.spellSelect:Hide()
        end 
    end
end
-- Okay Function
DiscoHealerOptionsPanel.panel.okay = function()
    DiscoSettings = DiscoHealerOptionsPanel.tempSettings

    DiscoSettings.leftMacro = DiscoHealerOptionsPanel.panel.spellSelect.box1:GetText()
    DiscoSettings.rightMacro = DiscoHealerOptionsPanel.panel.spellSelect.box2:GetText()
    DiscoSettings.shiftLMacro = DiscoHealerOptionsPanel.panel.spellSelect.box3:GetText()
    DiscoSettings.shiftRMacro = DiscoHealerOptionsPanel.panel.spellSelect.box4:GetText()
    DiscoSettings.ctrlLMacro = DiscoHealerOptionsPanel.panel.spellSelect.box5:GetText()
    DiscoSettings.ctrlRMacro = DiscoHealerOptionsPanel.panel.spellSelect.box6:GetText()

    if InCombatLockdown() then
    else
        generateMainDiscoFrame(discoVars.discoMainFrame)
        generateDiscoSubframes(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame)
        recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
    end
end
-- Default Function
DiscoHealerOptionsPanel.panel.default = function()
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
    DiscoHealerOptionsPanel.panel.refresh()
end
InterfaceOptions_AddCategory(DiscoHealerOptionsPanel.panel);

function generateOptionsPanel()
    -- UI Scale Slider
    DiscoHealerOptionsPanel.panel.UIScaleTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.UIScaleTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -25)
    DiscoHealerOptionsPanel.panel.UIScaleTitle:SetText("UI Scale")

    DiscoHealerOptionsPanel.panel.UIScaleValue = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.UIScaleValue:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -50)
    DiscoHealerOptionsPanel.panel.UIScaleValue:SetText(math.floor(DiscoHealerOptionsPanel.tempSettings.frameSize * 100) .. "%")

    DiscoHealerOptionsPanel.panel.slider = CreateFrame("Slider", "DiscoScaleSlider", DiscoHealerOptionsPanel.panel, "OptionsSliderTemplate")
    DiscoHealerOptionsPanel.panel.slider:SetWidth(200)
    DiscoHealerOptionsPanel.panel.slider:SetHeight(20)
    DiscoHealerOptionsPanel.panel.slider:SetMinMaxValues(0.5,3);
    DiscoHealerOptionsPanel.panel.slider:SetValue(DiscoHealerOptionsPanel.tempSettings.frameSize)
    DiscoHealerOptionsPanel.panel.slider:SetValueStep(0.1)
    DiscoHealerOptionsPanel.panel.slider:SetObeyStepOnDrag(true);
    DiscoHealerOptionsPanel.panel.slider:SetScript("OnValueChanged", function(self)
        local value = self:GetValue()
        DiscoHealerOptionsPanel.tempSettings.frameSize = value
        DiscoHealerOptionsPanel.panel.UIScaleValue:SetText(math.floor(DiscoHealerOptionsPanel.tempSettings.frameSize * 100) .. "%")
    end)
    DiscoHealerOptionsPanel.panel.slider:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -75)
    getglobal(DiscoHealerOptionsPanel.panel.slider:GetName() .. 'Low'):SetText("50%")
    getglobal(DiscoHealerOptionsPanel.panel.slider:GetName() .. 'High'):SetText("300%")

    --  Cast Time Lookahead
    DiscoHealerOptionsPanel.panel.CastLookaheadTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.CastLookaheadTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -125)
    DiscoHealerOptionsPanel.panel.CastLookaheadTitle:SetText("Display Friendly Heals landing within X Seconds")
    
    DiscoHealerOptionsPanel.panel.CastLookaheadBox = CreateFrame("EditBox", "DiscoLookAheadBox", DiscoHealerOptionsPanel.panel, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetSize(50,20)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -150)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetText(DiscoHealerOptionsPanel.tempSettings.castLookAhead)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetCursorPosition(0)

    -- Action Dropdown Selector
    DiscoHealerOptionsPanel.panel.actionTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.actionTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -185)
    DiscoHealerOptionsPanel.panel.actionTitle:SetText("Frame On Click Behavior")

    DiscoHealerOptionsPanel.panel.actionSelector = CreateFrame("BUTTON", "DiscoActionDropdownMenu", DiscoHealerOptionsPanel.panel, "UIDropDownMenuTemplate")
    DiscoHealerOptionsPanel.panel.actionSelector:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -75, -225)
    
    function WPDropDownDemo_Menu(frame, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        
        if level == 1 then
            -- Function called when dropdown changed
            local function select(selection)
                DiscoHealerOptionsPanel.tempSettings.clickAction = selection
                UIDropDownMenu_SetText(DiscoHealerOptionsPanel.panel.actionSelector, selection)
                if not InCombatLockdown() then
                    if selection == "target" then
                        DiscoHealerOptionsPanel.panel.spellSelect:Hide()
                    elseif selection == "spell" then
                        DiscoHealerOptionsPanel.panel.spellSelect:Show()
                    elseif selection == "macro" then
                        DiscoHealerOptionsPanel.panel.spellSelect:Hide()
                    end
                end
            end
            info.text, info.checked, info.func = "Target Player", DiscoHealerOptionsPanel.tempSettings.clickAction == "target", function() select("target"); end
            UIDropDownMenu_AddButton(info)
            info.text, info.checked, info.func = "Cast On Player", DiscoHealerOptionsPanel.tempSettings.clickAction == "spell", function() select("spell"); end
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(DiscoHealerOptionsPanel.panel.actionSelector, WPDropDownDemo_Menu)
    UIDropDownMenu_SetText(DiscoHealerOptionsPanel.panel.actionSelector, DiscoHealerOptionsPanel.tempSettings.clickAction)

    -- Spell Select Frame
    DiscoHealerOptionsPanel.panel.spellSelect = CreateFrame("FRAME", "DiscoSpellSelect", DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect:Hide()

    -- Left Click
    DiscoHealerOptionsPanel.panel.spellSelect.box1Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box1Label:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -272)
    DiscoHealerOptionsPanel.panel.spellSelect.box1Label:SetText("Left Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect:SetAllPoints(DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect.box1 = CreateFrame("EditBox", "DiscoSpellBox1", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 10, -275)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetText(DiscoHealerOptionsPanel.tempSettings.leftMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetCursorPosition(0)

    -- Right Click
    DiscoHealerOptionsPanel.panel.spellSelect.box2Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box2Label:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -297)
    DiscoHealerOptionsPanel.panel.spellSelect.box2Label:SetText("Right Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect:SetAllPoints(DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect.box2 = CreateFrame("EditBox", "DiscoSpellBox2", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 10, -300)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetText(DiscoHealerOptionsPanel.tempSettings.rightMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetCursorPosition(0)

    -- Shift Left
    DiscoHealerOptionsPanel.panel.spellSelect.box3Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box3Label:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -322)
    DiscoHealerOptionsPanel.panel.spellSelect.box3Label:SetText("Shift Left Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect:SetAllPoints(DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect.box3 = CreateFrame("EditBox", "DiscoSpellBox3", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 10, -325)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetText(DiscoHealerOptionsPanel.tempSettings.shiftLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetCursorPosition(0)

    -- Shift Right
    DiscoHealerOptionsPanel.panel.spellSelect.box4Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box4Label:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -347)
    DiscoHealerOptionsPanel.panel.spellSelect.box4Label:SetText("Shift Right Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect:SetAllPoints(DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect.box4 = CreateFrame("EditBox", "DiscoSpellBox4", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 10, -350)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetText(DiscoHealerOptionsPanel.tempSettings.shiftRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetCursorPosition(0)

    -- Ctrl Left
    DiscoHealerOptionsPanel.panel.spellSelect.box5Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box5Label:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -372)
    DiscoHealerOptionsPanel.panel.spellSelect.box5Label:SetText("Ctrl Left Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect:SetAllPoints(DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect.box5 = CreateFrame("EditBox", "DiscoSpellBox5", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 10, -375)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetCursorPosition(0)

    -- Ctrl Right
    DiscoHealerOptionsPanel.panel.spellSelect.box6Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box6Label:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -397)
    DiscoHealerOptionsPanel.panel.spellSelect.box6Label:SetText("Ctrl Right Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect:SetAllPoints(DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect.box6 = CreateFrame("EditBox", "DiscoSpellBox6", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 10, -400)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetCursorPosition(0)

end

