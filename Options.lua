-------------------------------------------------------------------------------
-- FarmHud Options Panel
-- Custom UI matching retail FarmHud layout from screenshots
-------------------------------------------------------------------------------

local addon = "FarmHud"
local FarmHud = _G[addon]

if not FarmHud then
    print("|cFFFF0000FarmHud Options:|r FarmHud addon not found!")
    return
end

-------------------------------------------------------------------------------
-- Main Frame
-------------------------------------------------------------------------------
local OptionsFrame = CreateFrame("Frame", "FarmHudOptionsFrame", UIParent)
OptionsFrame:SetWidth(700)
OptionsFrame:SetHeight(500)
OptionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
OptionsFrame:SetFrameStrata("DIALOG")
OptionsFrame:SetMovable(true)
OptionsFrame:EnableMouse(true)
OptionsFrame:RegisterForDrag("LeftButton")
OptionsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
OptionsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
OptionsFrame:Hide()
OptionsFrame:SetClampedToScreen(true)
tinsert(UISpecialFrames, "FarmHudOptionsFrame")

-- Dark blue-gray background
OptionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
OptionsFrame:SetBackdropColor(0.1, 0.1, 0.15, 1)

-------------------------------------------------------------------------------
-- Title Bar (Orange "FarmHud" text at top center)
-------------------------------------------------------------------------------
local titleBg = OptionsFrame:CreateTexture(nil, "ARTWORK")
titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
titleBg:SetWidth(200)
titleBg:SetHeight(64)
titleBg:SetPoint("TOP", 0, 12)

local titleText = OptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", OptionsFrame, "TOP", 0, -4)
titleText:SetText("FarmHud")
titleText:SetTextColor(1, 0.82, 0)

-------------------------------------------------------------------------------
-- Version Text (Bottom Left)
-------------------------------------------------------------------------------
local versionText = OptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionText:SetPoint("BOTTOMLEFT", 20, 18)
versionText:SetText("Version: 2.0.0")
versionText:SetTextColor(0.5, 0.5, 0.5)

-------------------------------------------------------------------------------
-- Close Button (Red button at bottom right, like retail)
-------------------------------------------------------------------------------
local closeBtn = CreateFrame("Button", nil, OptionsFrame, "UIPanelButtonTemplate")
closeBtn:SetWidth(80)
closeBtn:SetHeight(22)
closeBtn:SetPoint("BOTTOMRIGHT", -15, 12)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function() OptionsFrame:Hide() end)

-------------------------------------------------------------------------------
-- Left Sidebar (Category list)
-------------------------------------------------------------------------------
local sidebar = CreateFrame("Frame", nil, OptionsFrame)
sidebar:SetWidth(170)
sidebar:SetPoint("TOPLEFT", 15, -25)
sidebar:SetPoint("BOTTOMLEFT", 15, 45)

-------------------------------------------------------------------------------
-- Content Area (Right side) - with scroll support
-------------------------------------------------------------------------------
local contentArea = CreateFrame("Frame", nil, OptionsFrame)
contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
contentArea:SetPoint("BOTTOMRIGHT", -15, 45)

-- Subtle border for content
local contentBorder = contentArea:CreateTexture(nil, "BACKGROUND")
contentBorder:SetAllPoints()
contentBorder:SetTexture(0, 0, 0, 0.3)

-------------------------------------------------------------------------------
-- Category System
-------------------------------------------------------------------------------
local categories = {}
local contentPanels = {}
local currentCategory = nil

local categoryOrder = {
    "General Options",
    "Quest arrow",
    "Range circles",
    "Cardinal points",
    "Server/Local time",
    "Coordinates",
    "OnScreen buttons",
    "Tracking Options",
    "Trail path",
    "Key Bindings",
    "Debug",
}

-------------------------------------------------------------------------------
-- Create Category Button (matching retail style)
-------------------------------------------------------------------------------
local function CreateCategoryButton(name, order)
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetHeight(18)
    btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, -2 - (order - 1) * 18)
    btn:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, -2 - (order - 1) * 18)
    
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", 5, 0)
    text:SetText(name)
    text:SetTextColor(0.6, 0.6, 0.6)
    btn.text = text
    
    -- Highlight texture (shown on hover/selected)
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(1, 1, 1, 0.1)
    
    btn:SetScript("OnEnter", function(self)
        if currentCategory ~= name then
            self.text:SetTextColor(0.9, 0.9, 0.9)
        end
    end)
    
    btn:SetScript("OnLeave", function(self)
        if currentCategory ~= name then
            self.text:SetTextColor(0.6, 0.6, 0.6)
        end
    end)
    
    btn:SetScript("OnClick", function(self)
        FarmHud:SelectCategory(name)
    end)
    
    categories[name] = btn
    return btn
end

-------------------------------------------------------------------------------
-- Create Content Panel with Scroll Frame
-------------------------------------------------------------------------------
local function CreateContentPanel(name)
    -- Container frame (hidden/shown when switching categories)
    local container = CreateFrame("Frame", nil, contentArea)
    container:SetAllPoints()
    container:Hide()
    
    -- Scroll child (the actual content goes here) - create first
    local scrollChild = CreateFrame("Frame", nil, container)
    scrollChild:SetWidth(400)
    scrollChild:SetHeight(800) -- Large enough for content
    scrollChild:SetPoint("TOPLEFT", 5, -5)
    
    -- Just use the scrollChild directly without a ScrollFrame
    -- This avoids the SetVerticalScroll issue in 3.3.5a
    
    contentPanels[name] = container
    container.scrollChild = scrollChild
    return scrollChild
end

-------------------------------------------------------------------------------
-- Create all categories
-------------------------------------------------------------------------------
for i, name in ipairs(categoryOrder) do
    CreateCategoryButton(name, i)
    CreateContentPanel(name)
end

-------------------------------------------------------------------------------
-- Select Category
-------------------------------------------------------------------------------
function FarmHud:SelectCategory(name)
    -- Deselect current
    if currentCategory and categories[currentCategory] then
        categories[currentCategory].text:SetTextColor(0.6, 0.6, 0.6)
    end
    
    -- Hide all panels
    for _, panel in pairs(contentPanels) do
        panel:Hide()
    end
    
    -- Select new (cyan/turquoise color like retail)
    currentCategory = name
    if categories[name] then
        categories[name].text:SetTextColor(0.4, 0.8, 1)
    end
    
    -- Show panel
    if contentPanels[name] then
        contentPanels[name]:Show()
    end
end

-------------------------------------------------------------------------------
-- UI Helpers
-------------------------------------------------------------------------------
local function CreateCheckbox(parent, label, x, y, dbKey, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    text:SetText(label)
    text:SetTextColor(1, 1, 1)
    
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        if dbKey and FarmHudDB then
            FarmHudDB[dbKey] = checked
        end
        if onChange then
            onChange(checked)
        end
    end)
    
    if dbKey and FarmHudDB and FarmHudDB[dbKey] then
        cb:SetChecked(true)
    end
    
    return cb
end

local function CreateDescription(parent, text, x, y)
    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", x, y)
    desc:SetWidth(350)
    desc:SetJustifyH("LEFT")
    desc:SetText(text)
    desc:SetTextColor(0.7, 0.7, 0.7)
    return desc
end
local sliderCounter = 0
local function CreateSlider(parent, label, x, y, minVal, maxVal, step, dbKey, onChange)
    sliderCounter = sliderCounter + 1
    local sliderName = "FarmHudSlider" .. sliderCounter
    
    -- Label
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("TOPLEFT", x, y)
    labelText:SetText(label)
    labelText:SetTextColor(1, 1, 1)
    
    -- Slider frame with a name so getglobal works
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y - 18)
    slider:SetWidth(200)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    
    -- Set low/high text using the named slider
    _G[sliderName .. "Low"]:SetText(tostring(minVal) .. "%")
    _G[sliderName .. "High"]:SetText(tostring(maxVal) .. "%")
    _G[sliderName .. "Text"]:SetText("")
    
    -- Value display
    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.valueText = valueText
    
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        self.valueText:SetText(tostring(value) .. "%")
        if dbKey and FarmHudDB then
            FarmHudDB[dbKey] = value
        end
        if onChange then
            onChange(value)
        end
    end)
    
    -- Initialize
    if dbKey and FarmHudDB and FarmHudDB[dbKey] then
        slider:SetValue(FarmHudDB[dbKey])
    else
        slider:SetValue(minVal)
    end
    
    return slider
end

-------------------------------------------------------------------------------
-- Panel Contents (use .scrollChild for scrollable content)
-------------------------------------------------------------------------------

-- General Options
local generalPanel = contentPanels["General Options"].scrollChild

CreateCheckbox(generalPanel, "Hide Minimap Icon", 10, -10, "hide_minimap_icon", function(checked)
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LDBIcon then
        if checked then
            LDBIcon:Hide(addon)
        else
            LDBIcon:Show(addon)
        end
    end
end)

CreateCheckbox(generalPanel, "Hide in Combat", 10, -35, "hide_in_combat")

CreateCheckbox(generalPanel, "Hide in Instances", 10, -60, "hide_in_instances")

-- Quest arrow
local arrowPanel = contentPanels["Quest arrow"].scrollChild
CreateDescription(arrowPanel, "The extra addon 'FarmHud (QuestArrow)' must be enabled for this option.", 10, -10)
CreateCheckbox(arrowPanel, "Hide quest arrow on opened HUD", 10, -80, "hide_quest_arrow")

-- Range circles
local rangePanel = contentPanels["Range circles"].scrollChild
CreateCheckbox(rangePanel, "Show Gather Circle", 10, -10, "show_gather_circle")

-- Cardinal points
local cardinalPanel = contentPanels["Cardinal points"].scrollChild
CreateCheckbox(cardinalPanel, "Show Cardinal Points", 10, -10, "show_cardinal_points", function(checked)
    if FarmHud and FarmHud.UpdateCardinalVisibility then
        FarmHud:UpdateCardinalVisibility()
    end
end)
CreateCheckbox(cardinalPanel, "Bind to Gather Circle", 10, -35, "cardinal_bind_to_circle", function(checked)
    if FarmHud and FarmHud.UpdateCardinalPositions then
        FarmHud:UpdateCardinalPositions()
    end
end)
CreateSlider(cardinalPanel, "Distance from Center", 10, -90, 10, 99, 1, "cardinal_distance", function(value)
    if FarmHud and FarmHud.UpdateCardinalPositions then
        FarmHud:UpdateCardinalPositions()
    end
end)

-- Server/Local time
local timePanel = contentPanels["Server/Local time"].scrollChild
CreateCheckbox(timePanel, "Show Time", 10, -10, "show_time")
CreateCheckbox(timePanel, "Use Server Time", 10, -35, "use_server_time")

-- Coordinates
local coordsPanel = contentPanels["Coordinates"].scrollChild
CreateCheckbox(coordsPanel, "Show Coordinates", 10, -10, "show_coordinates")

-- OnScreen buttons
local btnPanel = contentPanels["OnScreen buttons"].scrollChild
CreateCheckbox(btnPanel, "Show OnScreen buttons", 10, -10, "show_onscreen_buttons")
CreateCheckbox(btnPanel, "OnScreen buttons on bottom", 10, -35, "onscreen_buttons_bottom")

-- Tracking Options
local trackPanel = contentPanels["Tracking Options"].scrollChild
CreateDescription(trackPanel, "Toggle tracking icons on opened Farm Hud.", 10, -10)

-- Trail path
local trailPanel = contentPanels["Trail path"].scrollChild
CreateCheckbox(trailPanel, "Enable Trail Path", 10, -10, "trail_enabled")

-- Key Bindings
local keysPanel = contentPanels["Key Bindings"].scrollChild
CreateDescription(keysPanel, "Use WoW's Key Bindings menu (Esc > Key Bindings) to set FarmHud keybinds under the 'FarmHud' category.", 10, -10)
CreateDescription(keysPanel, "Or use slash commands:", 10, -40)
CreateDescription(keysPanel, "  /farmhud - Toggle HUD", 10, -55)
CreateDescription(keysPanel, "  /farmhud options - Open this panel", 10, -70)
CreateDescription(keysPanel, "  /farmhud mouse - Toggle mouse", 10, -85)

-- Debug
local debugPanel = contentPanels["Debug"].scrollChild
CreateDescription(debugPanel, "This section contains options to help tracking problems with other addons.", 10, -10)

-------------------------------------------------------------------------------
-- Override OpenOptions
-------------------------------------------------------------------------------
function FarmHud:OpenOptions()
    if OptionsFrame:IsShown() then
        OptionsFrame:Hide()
    else
        OptionsFrame:Show()
        FarmHud:SelectCategory("General Options")
    end
end

-- Select default
FarmHud:SelectCategory("General Options")
