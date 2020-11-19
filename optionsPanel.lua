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

    DiscoHealerOptionsPanel.panel.ShowPetSelector:SetChecked((DiscoHealerOptionsPanel.tempSettings.showPets))

    --DiscoHealerOptionsPanel.panel.estimateHealsSelector:SetChecked((DiscoHealerOptionsPanel.tempSettings.estimateHeals))
    DiscoHealerOptionsPanel.panel.arrangeByGroupSelector:SetChecked((DiscoHealerOptionsPanel.tempSettings.arrangeByGroup))
    DiscoHealerOptionsPanel.panel.prioritizeGroupSelector:SetChecked((DiscoHealerOptionsPanel.tempSettings.prioritizeGroup))

    if DiscoHealerOptionsPanel.tempSettings.clickAction == "target" then
        UIDropDownMenu_SetText(DiscoHealerOptionsPanel.panel.actionSelector, "Target Player")
    else
        UIDropDownMenu_SetText(DiscoHealerOptionsPanel.panel.actionSelector, "Cast On Player")
    end

    --DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetText(DiscoHealerOptionsPanel.tempSettings.castLookAhead)

    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetText(DiscoHealerOptionsPanel.tempSettings.leftMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetText(DiscoHealerOptionsPanel.tempSettings.rightMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetText(DiscoHealerOptionsPanel.tempSettings.shiftLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetText(DiscoHealerOptionsPanel.tempSettings.shiftRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box7:SetText(DiscoHealerOptionsPanel.tempSettings.scrollClickMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box8:SetText(DiscoHealerOptionsPanel.tempSettings.mb4Macro)
    DiscoHealerOptionsPanel.panel.spellSelect.box9:SetText(DiscoHealerOptionsPanel.tempSettings.mb5Macro)
    DiscoHealerOptionsPanel.panel.spellSelect.box10:SetText(DiscoHealerOptionsPanel.tempSettings.altLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box11:SetText(DiscoHealerOptionsPanel.tempSettings.altRMacro)

    if not InCombatLockdown() then
        if DiscoSettings.clickAction == "target" then
            DiscoHealerOptionsPanel.panel.spellSelect:Hide()
        elseif DiscoSettings.clickAction == "spell" then
            DiscoHealerOptionsPanel.panel.spellSelect:Show()
        elseif DiscoSettings.clickAction == "macro" then
            DiscoHealerOptionsPanel.panel.spellSelect:Hide()
        end 
    end

    DiscoHealerOptionsPanel.panel.colorPicker1.texture:SetColorTexture(DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.b)
    DiscoHealerOptionsPanel.panel.colorPicker2.texture:SetColorTexture(DiscoHealerOptionsPanel.tempSettings.medPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.medPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.medPrioRGB.b)
    DiscoHealerOptionsPanel.panel.colorPicker3.texture:SetColorTexture(DiscoHealerOptionsPanel.tempSettings.highPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.highPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.highPrioRGB.b)
end
-- Okay Function
DiscoHealerOptionsPanel.panel.okay = function()
    DiscoSettings = DiscoHealerOptionsPanel.tempSettings

    --DiscoSettings.castLookAhead = DiscoHealerOptionsPanel.panel.CastLookaheadBox:GetText()

    DiscoSettings.leftMacro = DiscoHealerOptionsPanel.panel.spellSelect.box1:GetText()
    DiscoSettings.rightMacro = DiscoHealerOptionsPanel.panel.spellSelect.box2:GetText()
    DiscoSettings.shiftLMacro = DiscoHealerOptionsPanel.panel.spellSelect.box3:GetText()
    DiscoSettings.shiftRMacro = DiscoHealerOptionsPanel.panel.spellSelect.box4:GetText()
    DiscoSettings.ctrlLMacro = DiscoHealerOptionsPanel.panel.spellSelect.box5:GetText()
    DiscoSettings.ctrlRMacro = DiscoHealerOptionsPanel.panel.spellSelect.box6:GetText()
    DiscoSettings.scrollClickMacro = DiscoHealerOptionsPanel.panel.spellSelect.box7:GetText()
    DiscoSettings.mb4Macro = DiscoHealerOptionsPanel.panel.spellSelect.box8:GetText()
    DiscoSettings.mb5Macro = DiscoHealerOptionsPanel.panel.spellSelect.box9:GetText()
    DiscoSettings.altLMacro = DiscoHealerOptionsPanel.panel.spellSelect.box10:GetText()
    DiscoSettings.altRMacro = DiscoHealerOptionsPanel.panel.spellSelect.box11:GetText()

    if InCombatLockdown() then
    else
        generateMainDiscoFrame(discoVars.discoMainFrame)
        generateDiscoSubframes(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame)
        recreateAllSubFrames(discoVars.discoSubframes, discoVars.discoOverlaySubframes, discoVars.discoMainFrame, discoVars.allPartyMembers)
    end
end
-- Default Function
DiscoHealerOptionsPanel.panel.default = function()
    DiscoSettings = discoVars.defaultSettings
    DiscoHealerOptionsPanel.panel.refresh()
end
InterfaceOptions_AddCategory(DiscoHealerOptionsPanel.panel);

function generateOptionsPanel()
    -- UI Scale Slider
    DiscoHealerOptionsPanel.panel.UIScaleTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.UIScaleTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -50)
    DiscoHealerOptionsPanel.panel.UIScaleTitle:SetText("UI Scale")

    DiscoHealerOptionsPanel.panel.UIScaleValue = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.UIScaleValue:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -25)
    DiscoHealerOptionsPanel.panel.UIScaleValue:SetText((DiscoHealerOptionsPanel.tempSettings.frameSize * 100) .. "%")

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
    DiscoHealerOptionsPanel.panel.slider:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -50)
    getglobal(DiscoHealerOptionsPanel.panel.slider:GetName() .. 'Low'):SetText("50%")
    getglobal(DiscoHealerOptionsPanel.panel.slider:GetName() .. 'High'):SetText("300%")

    -- Reset Position
    DiscoHealerOptionsPanel.panel.resetPosition = CreateFrame("Button", "DiscoPositionReset", DiscoHealerOptionsPanel.panel, "UIPanelButtonTemplate")
    DiscoHealerOptionsPanel.panel.resetPosition:SetSize(120 ,22) -- width, height
    DiscoHealerOptionsPanel.panel.resetPosition:SetText("Reset Position")
    DiscoHealerOptionsPanel.panel.resetPosition:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 0, -155)
    DiscoHealerOptionsPanel.panel.resetPosition:SetScript("OnClick", function()
        discoVars.discoMainFrame:ClearAllPoints()
        discoVars.discoMainFrame:SetPoint("CENTER", UIParent, "CENTER")
    end)

    
    --  Estimated Heals
    --[[
    DiscoHealerOptionsPanel.panel.estimateHealsTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.estimateHealsTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -180, -100)
    DiscoHealerOptionsPanel.panel.estimateHealsTitle:SetText("Estimate heals from non-addon users")

    DiscoHealerOptionsPanel.panel.estimateHealsSelector = CreateFrame("CHECKBUTTON", "DiscoCheckButton", DiscoHealerOptionsPanel.panel, "ChatConfigCheckButtonTemplate")
    DiscoHealerOptionsPanel.panel.estimateHealsSelector:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -50, -105)
    DiscoHealerOptionsPanel.panel.estimateHealsSelector:SetScript("OnClick", 
    function()
        DiscoHealerOptionsPanel.tempSettings.estimateHeals = DiscoHealerOptionsPanel.panel.estimateHealsSelector:GetChecked()
    end
    );
    ]]

    -- Arrange by group
    DiscoHealerOptionsPanel.panel.arrangeByGroupTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.arrangeByGroupTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -230, -100)
    DiscoHealerOptionsPanel.panel.arrangeByGroupTitle:SetText("Arrange by group")

    DiscoHealerOptionsPanel.panel.arrangeByGroupSelector = CreateFrame("CHECKBUTTON", "arrangeByGroupCheckButton", DiscoHealerOptionsPanel.panel, "ChatConfigCheckButtonTemplate")
    DiscoHealerOptionsPanel.panel.arrangeByGroupSelector:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -150, -105)
    DiscoHealerOptionsPanel.panel.arrangeByGroupSelector:SetScript("OnClick", 
    function()
        DiscoHealerOptionsPanel.tempSettings.arrangeByGroup = DiscoHealerOptionsPanel.panel.arrangeByGroupSelector:GetChecked()
    end
    );

    -- Prioritize group
    DiscoHealerOptionsPanel.panel.prioritizeGroupTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.prioritizeGroupTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -30, -100)
    DiscoHealerOptionsPanel.panel.prioritizeGroupTitle:SetText("Prioritize group members")

    DiscoHealerOptionsPanel.panel.prioritizeGroupSelector = CreateFrame("CHECKBUTTON", "prioritizeGroupCheckButton", DiscoHealerOptionsPanel.panel, "ChatConfigCheckButtonTemplate")
    DiscoHealerOptionsPanel.panel.prioritizeGroupSelector:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", 70, -105)
    DiscoHealerOptionsPanel.panel.prioritizeGroupSelector:SetScript("OnClick", 
    function()
        DiscoHealerOptionsPanel.tempSettings.prioritizeGroup = DiscoHealerOptionsPanel.panel.prioritizeGroupSelector:GetChecked()
    end
    );
    
    --  Cast Time Lookahead
    --[[
    DiscoHealerOptionsPanel.panel.CastLookaheadTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.CastLookaheadTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -125, -100)
    DiscoHealerOptionsPanel.panel.CastLookaheadTitle:SetText("Display Friendly Heals ending within                    Seconds")
    
    DiscoHealerOptionsPanel.panel.CastLookaheadBox = CreateFrame("EditBox", "DiscoLookAheadBox", DiscoHealerOptionsPanel.panel, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetSize(50,20)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -40, -101)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetText(DiscoHealerOptionsPanel.tempSettings.castLookAhead)
    DiscoHealerOptionsPanel.panel.CastLookaheadBox:SetCursorPosition(0)
    ]]

    --  Show Pets
    DiscoHealerOptionsPanel.panel.ShowPetTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.ShowPetTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -250, -150)
    DiscoHealerOptionsPanel.panel.ShowPetTitle:SetText("Show Pets")
    
    DiscoHealerOptionsPanel.panel.ShowPetSelector = CreateFrame("CHECKBUTTON", "DiscoCheckButton", DiscoHealerOptionsPanel.panel, "ChatConfigCheckButtonTemplate")
    DiscoHealerOptionsPanel.panel.ShowPetSelector:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -200, -155)
    DiscoHealerOptionsPanel.panel.ShowPetSelector:SetScript("OnClick", 
    function()
        DiscoHealerOptionsPanel.tempSettings.showPets = DiscoHealerOptionsPanel.panel.ShowPetSelector:GetChecked()
    end
    );
    
    -- Action Dropdown Selector
    DiscoHealerOptionsPanel.panel.actionTitle = DiscoHealerOptionsPanel.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.actionTitle:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -210, -200)
    DiscoHealerOptionsPanel.panel.actionTitle:SetText("Frame On Click Behavior")

    DiscoHealerOptionsPanel.panel.actionSelector = CreateFrame("BUTTON", "DiscoActionDropdownMenu", DiscoHealerOptionsPanel.panel, "UIDropDownMenuTemplate")
    DiscoHealerOptionsPanel.panel.actionSelector:SetPoint("BOTTOM", DiscoHealerOptionsPanel.panel, "TOP", -110, -210)
    
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
    --DiscoHealerOptionsPanel.panel.spellSelect:SetAllPoints(DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.spellSelect:SetPoint("TOPLEFT", DiscoHealerOptionsPanel.panel ,"TOPLEFT", 0, 50)
    DiscoHealerOptionsPanel.panel.spellSelect:SetPoint("BOTTOMRIGHT", DiscoHealerOptionsPanel.panel ,"BOTTOMRIGHT", 0, 50)
    --DiscoHealerOptionsPanel.panel.spellSelect:SetPoint("CENTER", DiscoHealerOptionsPanel.panel, "CENTER", 0, 100)
    DiscoHealerOptionsPanel.panel.spellSelect:Hide()

    -- Left Click
    DiscoHealerOptionsPanel.panel.spellSelect.box1Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box1Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, 0)
    DiscoHealerOptionsPanel.panel.spellSelect.box1Label:SetText("Left Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box1 = CreateFrame("EditBox", "DiscoSpellBox1", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, 0)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetText(DiscoHealerOptionsPanel.tempSettings.leftMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box1:SetCursorPosition(0)

    -- Right Click
    DiscoHealerOptionsPanel.panel.spellSelect.box2Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box2Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -25)
    DiscoHealerOptionsPanel.panel.spellSelect.box2Label:SetText("Right Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box2 = CreateFrame("EditBox", "DiscoSpellBox2", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -25)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetText(DiscoHealerOptionsPanel.tempSettings.rightMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box2:SetCursorPosition(0)

    -- Shift Left
    DiscoHealerOptionsPanel.panel.spellSelect.box3Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box3Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -50)
    DiscoHealerOptionsPanel.panel.spellSelect.box3Label:SetText("Shift Left Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box3 = CreateFrame("EditBox", "DiscoSpellBox3", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -50)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetText(DiscoHealerOptionsPanel.tempSettings.shiftLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box3:SetCursorPosition(0)

    -- Shift Right
    DiscoHealerOptionsPanel.panel.spellSelect.box4Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box4Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -75)
    DiscoHealerOptionsPanel.panel.spellSelect.box4Label:SetText("Shift Right Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box4 = CreateFrame("EditBox", "DiscoSpellBox4", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -75)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetText(DiscoHealerOptionsPanel.tempSettings.shiftRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box4:SetCursorPosition(0)

    -- Ctrl Left
    DiscoHealerOptionsPanel.panel.spellSelect.box5Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box5Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -100)
    DiscoHealerOptionsPanel.panel.spellSelect.box5Label:SetText("Ctrl Left Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box5 = CreateFrame("EditBox", "DiscoSpellBox5", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -100)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box5:SetCursorPosition(0)

    -- Ctrl Right
    DiscoHealerOptionsPanel.panel.spellSelect.box6Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box6Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -125)
    DiscoHealerOptionsPanel.panel.spellSelect.box6Label:SetText("Ctrl Right Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box6 = CreateFrame("EditBox", "DiscoSpellBox6", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -125)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetText(DiscoHealerOptionsPanel.tempSettings.ctrlRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box6:SetCursorPosition(0)

    -- Scroll Wheel Click
    DiscoHealerOptionsPanel.panel.spellSelect.box7Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box7Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -150)
    DiscoHealerOptionsPanel.panel.spellSelect.box7Label:SetText("Scroll Wheel Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box7 = CreateFrame("EditBox", "DiscoSpellBox7", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box7:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box7:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box7:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -150)
    DiscoHealerOptionsPanel.panel.spellSelect.box7:SetText(DiscoHealerOptionsPanel.tempSettings.scrollClickMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box7:SetCursorPosition(0)

    -- MB4 (back)
    DiscoHealerOptionsPanel.panel.spellSelect.box8Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box8Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -175)
    DiscoHealerOptionsPanel.panel.spellSelect.box8Label:SetText("MB4 (back)")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box8 = CreateFrame("EditBox", "DiscoSpellBox8", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box8:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box8:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box8:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -175)
    DiscoHealerOptionsPanel.panel.spellSelect.box8:SetText(DiscoHealerOptionsPanel.tempSettings.mb4Macro)
    DiscoHealerOptionsPanel.panel.spellSelect.box8:SetCursorPosition(0)

    -- MB5 (forward)
    DiscoHealerOptionsPanel.panel.spellSelect.box9Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box9Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -200)
    DiscoHealerOptionsPanel.panel.spellSelect.box9Label:SetText("MB5 (forwards)")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box9 = CreateFrame("EditBox", "DiscoSpellBox9", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box9:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box9:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box9:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -200)
    DiscoHealerOptionsPanel.panel.spellSelect.box9:SetText(DiscoHealerOptionsPanel.tempSettings.mb5Macro)
    DiscoHealerOptionsPanel.panel.spellSelect.box9:SetCursorPosition(0)

    -- Alt Left
    DiscoHealerOptionsPanel.panel.spellSelect.box10Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box10Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -225)
    DiscoHealerOptionsPanel.panel.spellSelect.box10Label:SetText("Alt Left Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box10 = CreateFrame("EditBox", "DiscoSpellBox10", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box10:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box10:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box10:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -225)
    DiscoHealerOptionsPanel.panel.spellSelect.box10:SetText(DiscoHealerOptionsPanel.tempSettings.altLMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box10:SetCursorPosition(0)

    -- Alt Right
    DiscoHealerOptionsPanel.panel.spellSelect.box11Label = DiscoHealerOptionsPanel.panel.spellSelect:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.spellSelect.box11Label:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "LEFT", 65, -250)
    DiscoHealerOptionsPanel.panel.spellSelect.box11Label:SetText("Alt Right Click")
    
    DiscoHealerOptionsPanel.panel.spellSelect.box11 = CreateFrame("EditBox", "DiscoSpellBox11", DiscoHealerOptionsPanel.panel.spellSelect, "InputBoxTemplate")
    DiscoHealerOptionsPanel.panel.spellSelect.box11:SetSize(400,20)
    DiscoHealerOptionsPanel.panel.spellSelect.box11:SetAutoFocus(false)
    DiscoHealerOptionsPanel.panel.spellSelect.box11:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.spellSelect, "CENTER", 10, -250)
    DiscoHealerOptionsPanel.panel.spellSelect.box11:SetText(DiscoHealerOptionsPanel.tempSettings.altRMacro)
    DiscoHealerOptionsPanel.panel.spellSelect.box11:SetCursorPosition(0)

    -- Color Picker
    local selectedColor
    local selectedColorPicker
    local function colorPickerCallback(restore)
        local newR, newG, newB;
        if restore then
         newR, newG, newB = unpack(restore);
         --print("canceled")
        else
         -- Something changed
         newR, newG, newB = ColorPickerFrame:GetColorRGB();
         selectedColor.r, selectedColor.g, selectedColor.b = ColorPickerFrame:GetColorRGB();
        end
        
        -- Update our internal storage.
        --r, g, b, a = newR, newG, newB, newA;
        -- And update any UI elements that use this color...
        selectedColor.r = newR
        selectedColor.g = newG
        selectedColor.b = newB
        selectedColorPicker:SetColorTexture(newR, newG, newB)
    end
    local function showColorPicker(r, g, b, a, changedCallback)
        ColorPickerFrame:SetColorRGB(r,g,b);
        ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
        ColorPickerFrame.previousValues = {r,g,b,a};
        ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
         changedCallback, changedCallback, changedCallback;
        ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
        ColorPickerFrame:Show();
    end
    
    DiscoHealerOptionsPanel.panel.colorPicker = CreateFrame("FRAME", "DiscoColorPicker", DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.colorPicker:SetPoint("TOPLEFT", DiscoHealerOptionsPanel.panel ,"TOPLEFT", 0, -150)
    DiscoHealerOptionsPanel.panel.colorPicker:SetPoint("BOTTOMRIGHT", DiscoHealerOptionsPanel.panel ,"BOTTOMRIGHT", 0, -150)

    -- Low Priority
    DiscoHealerOptionsPanel.panel.colorPicker.lowPrioLabel = DiscoHealerOptionsPanel.panel.colorPicker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.colorPicker.lowPrioLabel:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.colorPicker, "LEFT", 65, -80)
    DiscoHealerOptionsPanel.panel.colorPicker.lowPrioLabel:SetText("Low Priority")

    DiscoHealerOptionsPanel.panel.colorPicker1 = CreateFrame("FRAME", "DiscoColorPicker1", DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.colorPicker1:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.colorPicker, "LEFT", 140, -80)
    DiscoHealerOptionsPanel.panel.colorPicker1:SetSize(40, 20)

    DiscoHealerOptionsPanel.panel.colorPicker1.bgTexture = DiscoHealerOptionsPanel.panel.colorPicker1:CreateTexture(nil, "BACKGROUND")
    DiscoHealerOptionsPanel.panel.colorPicker1.bgTexture:SetAllPoints(DiscoHealerOptionsPanel.panel.colorPicker1)
    DiscoHealerOptionsPanel.panel.colorPicker1.bgTexture:SetColorTexture(1, 0.8, 0)
    
    DiscoHealerOptionsPanel.panel.colorPicker1.texture = DiscoHealerOptionsPanel.panel.colorPicker1:CreateTexture(nil, "BORDER")
    DiscoHealerOptionsPanel.panel.colorPicker1.texture:SetPoint("TOPLEFT", DiscoHealerOptionsPanel.panel.colorPicker1 ,"TOPLEFT", 1, -1)
    DiscoHealerOptionsPanel.panel.colorPicker1.texture:SetPoint("BOTTOMRIGHT", DiscoHealerOptionsPanel.panel.colorPicker1 ,"BOTTOMRIGHT", -1, 1)
    DiscoHealerOptionsPanel.panel.colorPicker1.texture:SetColorTexture(DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.b)
    
    DiscoHealerOptionsPanel.panel.colorPicker1:SetScript("OnMouseDown", function(self, button)
        selectedColor = DiscoHealerOptionsPanel.tempSettings.lowPrioRGB
        selectedColorPicker = DiscoHealerOptionsPanel.panel.colorPicker1.texture
        showColorPicker(DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.lowPrioRGB.b, nil, colorPickerCallback)
      end)

    -- Medium Priority
    DiscoHealerOptionsPanel.panel.colorPicker.medPrioLabel = DiscoHealerOptionsPanel.panel.colorPicker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.colorPicker.medPrioLabel:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.colorPicker, "LEFT", 265, -80)
    DiscoHealerOptionsPanel.panel.colorPicker.medPrioLabel:SetText("Medium Priority")

    DiscoHealerOptionsPanel.panel.colorPicker2 = CreateFrame("FRAME", "DiscoColorPicker2", DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.colorPicker2:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.colorPicker, "LEFT", 340, -80)
    DiscoHealerOptionsPanel.panel.colorPicker2:SetSize(40, 20)

    DiscoHealerOptionsPanel.panel.colorPicker2.bgTexture = DiscoHealerOptionsPanel.panel.colorPicker2:CreateTexture(nil, "BACKGROUND")
    DiscoHealerOptionsPanel.panel.colorPicker2.bgTexture:SetAllPoints(DiscoHealerOptionsPanel.panel.colorPicker2)
    DiscoHealerOptionsPanel.panel.colorPicker2.bgTexture:SetColorTexture(1, 0.8, 0)
    
    DiscoHealerOptionsPanel.panel.colorPicker2.texture = DiscoHealerOptionsPanel.panel.colorPicker2:CreateTexture(nil, "BORDER")
    DiscoHealerOptionsPanel.panel.colorPicker2.texture:SetPoint("TOPLEFT", DiscoHealerOptionsPanel.panel.colorPicker2 ,"TOPLEFT", 1, -1)
    DiscoHealerOptionsPanel.panel.colorPicker2.texture:SetPoint("BOTTOMRIGHT", DiscoHealerOptionsPanel.panel.colorPicker2 ,"BOTTOMRIGHT", -1, 1)
    DiscoHealerOptionsPanel.panel.colorPicker2.texture:SetColorTexture(DiscoHealerOptionsPanel.tempSettings.medPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.medPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.medPrioRGB.b)
    
    DiscoHealerOptionsPanel.panel.colorPicker2:SetScript("OnMouseDown", function(self, button)
        selectedColor = DiscoHealerOptionsPanel.tempSettings.medPrioRGB
        selectedColorPicker = DiscoHealerOptionsPanel.panel.colorPicker2.texture
        showColorPicker(DiscoHealerOptionsPanel.tempSettings.medPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.medPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.medPrioRGB.b, nil, colorPickerCallback)
      end)

    -- High Priority
    DiscoHealerOptionsPanel.panel.colorPicker.highPrioLabel = DiscoHealerOptionsPanel.panel.colorPicker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DiscoHealerOptionsPanel.panel.colorPicker.highPrioLabel:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.colorPicker, "LEFT", 465, -80)
    DiscoHealerOptionsPanel.panel.colorPicker.highPrioLabel:SetText("High Priority")

    DiscoHealerOptionsPanel.panel.colorPicker3 = CreateFrame("FRAME", "DiscoColorPicker3", DiscoHealerOptionsPanel.panel)
    DiscoHealerOptionsPanel.panel.colorPicker3:SetPoint("CENTER", DiscoHealerOptionsPanel.panel.colorPicker, "LEFT", 540, -80)
    DiscoHealerOptionsPanel.panel.colorPicker3:SetSize(40, 20)

    DiscoHealerOptionsPanel.panel.colorPicker3.bgTexture = DiscoHealerOptionsPanel.panel.colorPicker3:CreateTexture(nil, "BACKGROUND")
    DiscoHealerOptionsPanel.panel.colorPicker3.bgTexture:SetAllPoints(DiscoHealerOptionsPanel.panel.colorPicker3)
    DiscoHealerOptionsPanel.panel.colorPicker3.bgTexture:SetColorTexture(1, 0.8, 0)
    
    DiscoHealerOptionsPanel.panel.colorPicker3.texture = DiscoHealerOptionsPanel.panel.colorPicker3:CreateTexture(nil, "BORDER")
    DiscoHealerOptionsPanel.panel.colorPicker3.texture:SetPoint("TOPLEFT", DiscoHealerOptionsPanel.panel.colorPicker3 ,"TOPLEFT", 1, -1)
    DiscoHealerOptionsPanel.panel.colorPicker3.texture:SetPoint("BOTTOMRIGHT", DiscoHealerOptionsPanel.panel.colorPicker3 ,"BOTTOMRIGHT", -1, 1)
    DiscoHealerOptionsPanel.panel.colorPicker3.texture:SetColorTexture(DiscoHealerOptionsPanel.tempSettings.highPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.highPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.highPrioRGB.b)
    
    DiscoHealerOptionsPanel.panel.colorPicker3:SetScript("OnMouseDown", function(self, button)
        selectedColor = DiscoHealerOptionsPanel.tempSettings.highPrioRGB
        selectedColorPicker = DiscoHealerOptionsPanel.panel.colorPicker3.texture
        showColorPicker(DiscoHealerOptionsPanel.tempSettings.highPrioRGB.r, DiscoHealerOptionsPanel.tempSettings.highPrioRGB.g, DiscoHealerOptionsPanel.tempSettings.highPrioRGB.b, nil, colorPickerCallback)
      end)



end

