-------------------------------------------------------------------------------
-- FarmHud v2.0.0
-- A transparent HUD for farming herbs and ore
-- Modernized for 3.3.5a with generic addon compatibility
-------------------------------------------------------------------------------

local addon = "FarmHud"
local FarmHud = CreateFrame("Frame", addon, UIParent)
_G[addon] = FarmHud

-------------------------------------------------------------------------------
-- Create HUD Container Frame
-- This frame acts as the parent for Minimap when HUD is active
-------------------------------------------------------------------------------
local FarmHudMapCluster = CreateFrame("Frame", "FarmHudMapCluster", UIParent)
FarmHudMapCluster:SetFrameStrata("BACKGROUND")
FarmHudMapCluster:SetAllPoints(UIParent)
FarmHudMapCluster:Hide()

-------------------------------------------------------------------------------
-- Libraries
-------------------------------------------------------------------------------
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local HUD_SCALE = 1.4
local CARDINAL_DIRECTIONS = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
local UPDATE_INTERVAL = 1 / 90  -- ~90 FPS for smooth rotation

-------------------------------------------------------------------------------
-- State variables
-------------------------------------------------------------------------------
local originalRotateSetting
local originalMinimapParent
local originalMinimapPoint = {}
local originalMinimapAlpha
local directions = {}
local updateTotal = 0
local playerDot, gatherCircle, mouseWarn

-------------------------------------------------------------------------------
-- LibDataBroker launcher
-------------------------------------------------------------------------------
local dataObject
if LDB then
    dataObject = LDB:NewDataObject(addon, {
        type = "launcher",
        icon = "Interface\\Icons\\INV_Misc_Herb_MountainSilverSage",
        label = addon,
        text = addon,
        OnTooltipShow = function(tt)
            tt:AddLine("FarmHud")
            tt:AddLine("|cffffff00Click|r to toggle FarmHud")
            tt:AddLine("|cffffff00Right click|r to config")
            tt:AddLine("Or macro with /script FarmHud:Toggle()")
        end,
        OnClick = function(_, button)
            if button == "LeftButton" then
                FarmHud:Toggle()
            else
                FarmHud:OpenOptions()
            end
        end
    })
end

-------------------------------------------------------------------------------
-- Keybinding headers
-------------------------------------------------------------------------------
BINDING_HEADER_FARMHUD = addon
BINDING_NAME_TOGGLEFARMHUD = "Toggle FarmHud's Display"
BINDING_NAME_TOGGLEFARMHUDMOUSE = "Toggle FarmHud's tooltips (Can't click through Hud)"

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------
SLASH_FARMHUD1 = "/farmhud"
SLASH_FARMHUD2 = "/fh"

SlashCmdList["FARMHUD"] = function(msg)
    msg = msg:lower():trim()
    
    if msg == "" or msg == "toggle" then
        -- Toggle HUD
        FarmHud:Toggle()
    elseif msg == "options" or msg == "config" or msg == "settings" then
        -- Open options panel
        FarmHud:OpenOptions()
    elseif msg == "mouse" then
        -- Toggle mouse
        FarmHud:MouseToggle()
    elseif msg == "help" then
        print("|cFFFFCC00FarmHud Commands:|r")
        print("  /farmhud or /fh - Toggle HUD")
        print("  /farmhud options - Open options panel")
        print("  /farmhud mouse - Toggle mouse interaction")
        print("  /farmhud help - Show this help")
    else
        print("|cFFFFCC00FarmHud:|r Unknown command. Type /farmhud help for commands.")
    end
end

-------------------------------------------------------------------------------
-- Addon Compatibility Layer
-------------------------------------------------------------------------------

-- Reparent addon-specific pins using their APIs
local function ReparentAddonPins(targetParent)
    -- GatherMate2
    if GatherMate2 and FarmHudDB.show_gathermate then
        pcall(function()
            local display = GatherMate2:GetModule("Display")
            if display and display.ReparentMinimapPins then
                display:ReparentMinimapPins(targetParent)
                display:ChangedVars(nil, "ROTATE_MINIMAP", "1")
            end
        end)
    end
    
    -- Routes
    if Routes and Routes.ReparentMinimap and FarmHudDB.show_routes then
        pcall(function()
            Routes:ReparentMinimap(targetParent)
            Routes:CVAR_UPDATE(nil, "ROTATE_MINIMAP", "1")
        end)
    end
    
    -- NPCScan.Overlay
    local NPCScan = _NPCScan and _NPCScan.Overlay and _NPCScan.Overlay.Modules and _NPCScan.Overlay.Modules.List
    if NPCScan and NPCScan["Minimap"] and NPCScan["Minimap"].SetMinimapFrame and FarmHudDB.show_npcscan then
        pcall(function()
            NPCScan["Minimap"]:SetMinimapFrame(targetParent)
        end)
    end
end

-- Restore addon-specific pins to Minimap
local function RestoreAddonPins()
    -- GatherMate2
    if GatherMate2 then
        pcall(function()
            local display = GatherMate2:GetModule("Display")
            if display and display.ReparentMinimapPins then
                display:ReparentMinimapPins(Minimap)
                display:ChangedVars(nil, "ROTATE_MINIMAP", originalRotateSetting or "0")
            end
        end)
    end
    
    -- Routes
    if Routes and Routes.ReparentMinimap then
        pcall(function()
            Routes:ReparentMinimap(Minimap)
            Routes:CVAR_UPDATE(nil, "ROTATE_MINIMAP", originalRotateSetting or "0")
        end)
    end
    
    -- NPCScan.Overlay
    local NPCScan = _NPCScan and _NPCScan.Overlay and _NPCScan.Overlay.Modules and _NPCScan.Overlay.Modules.List
    if NPCScan and NPCScan["Minimap"] and NPCScan["Minimap"].SetMinimapFrame then
        pcall(function()
            NPCScan["Minimap"]:SetMinimapFrame(Minimap)
        end)
    end
    
    -- HandyNotes - refresh minimap pins
    if HandyNotes and HandyNotes.UpdateMinimap then
        pcall(function()
            HandyNotes:UpdateMinimap()
        end)
    end
end

-------------------------------------------------------------------------------
-- HUD Visual Updates
-------------------------------------------------------------------------------

local function UpdateCardinalDirections(bearing)
    -- Check if cardinal points should be shown
    if FarmHudDB and FarmHudDB.show_cardinal_points == false then
        for _, dir in ipairs(directions) do
            dir:Hide()
        end
        return
    end
    
    -- Calculate radius based on settings
    local baseRadius
    if FarmHudDB and FarmHudDB.cardinal_bind_to_circle then
        -- Bind to gather circle size
        local circleSize = gatherCircle and gatherCircle:GetWidth() or 140
        baseRadius = circleSize * 0.5
    else
        -- Use distance from center percentage
        local distance = (FarmHudDB and FarmHudDB.cardinal_distance) or 30
        baseRadius = 140 * (distance / 100)
    end
    
    for _, dir in ipairs(directions) do
        local x = math.sin(dir.rad + bearing) * baseRadius
        local y = math.cos(dir.rad + bearing) * baseRadius
        dir:ClearAllPoints()
        dir:SetPoint("CENTER", FarmHudMapCluster, "CENTER", x * HUD_SCALE, y * HUD_SCALE)
        dir:Show()
    end
end

local function OnUpdate(self, elapsed)
    updateTotal = updateTotal + elapsed
    if updateTotal < UPDATE_INTERVAL then return end
    updateTotal = updateTotal - UPDATE_INTERVAL
    
    -- Ensure MinimapCluster stays hidden
    if MinimapCluster:IsVisible() then
        MinimapCluster:Hide()
    end
    
    -- Update cardinal direction positions based on player facing
    local bearing = GetPlayerFacing() or 0
    UpdateCardinalDirections(bearing)
end

-------------------------------------------------------------------------------
-- HUD Size and Scale
-------------------------------------------------------------------------------

function FarmHud:SetScales()
    local size = UIParent:GetHeight() / HUD_SCALE
    
    -- Position Minimap in center of screen, scaled up
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", UIParent, "CENTER")
    Minimap:SetScale(HUD_SCALE)
    
    if gatherCircle then
        gatherCircle:SetWidth(size * 0.45)
        gatherCircle:SetHeight(size * 0.45)
    end
    
    if playerDot then
        playerDot:SetWidth(15)
        playerDot:SetHeight(15)
    end
    
    -- Update cardinal direction radius
    local radius = Minimap:GetWidth() * 0.214
    for _, dir in ipairs(directions) do
        dir.radius = radius
    end
end

-------------------------------------------------------------------------------
-- Show/Hide Logic
-------------------------------------------------------------------------------

local function SaveMinimapState()
    -- Save original minimap parent
    originalMinimapParent = Minimap:GetParent()
    
    -- Save original minimap position
    local point, relativeTo, relativePoint, xOfs, yOfs = Minimap:GetPoint()
    originalMinimapPoint = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
    
    -- Save original alpha
    originalMinimapAlpha = Minimap:GetAlpha()
end

local function RestoreMinimapState()
    -- Only restore if state was actually saved
    if not originalMinimapParent then
        return
    end
    
    -- Restore parent
    Minimap:SetParent(originalMinimapParent)
    
    -- Restore position
    if originalMinimapPoint.point then
        Minimap:ClearAllPoints()
        -- Use MinimapCluster as fallback if relativeTo is nil
        local relativeTo = originalMinimapPoint.relativeTo or MinimapCluster
        Minimap:SetPoint(
            originalMinimapPoint.point,
            relativeTo,
            originalMinimapPoint.relativePoint or originalMinimapPoint.point,
            originalMinimapPoint.xOfs or 0,
            originalMinimapPoint.yOfs or 0
        )
    end
    
    -- Restore scale
    Minimap:SetScale(1)
    
    -- Restore alpha
    if originalMinimapAlpha then
        Minimap:SetAlpha(originalMinimapAlpha)
    end
end

-------------------------------------------------------------------------------
-- Quest Arrow Hiding
-- Based on FarmHud_QuestArrow approach - directly access addon arrow objects
-------------------------------------------------------------------------------
local arrowVisibilityState = {}  -- Track which arrows were visible before hiding

local function HideQuestArrows()
    if not FarmHudDB.hide_quest_arrow then return end
    
    -- Clear previous state
    wipe(arrowVisibilityState)
    
    -- TomTom - toggle profile setting instead of direct hide (preserves addon arrow state)
    if TomTom and TomTom.profile and TomTom.profile.arrow then
        if TomTom.profile.arrow.enable and TomTom.crazyArrow and TomTom.crazyArrow:IsVisible() then
            arrowVisibilityState.TomTomEnable = true
            TomTom.profile.arrow.enable = false
            TomTom.crazyArrow:Hide()
        end
    end
    
    -- pfQuest arrow - need to toggle config, not just hide (OnUpdate re-shows it)
    if pfQuest_config and pfQuest_config["arrow"] then
        if pfQuest_config["arrow"] == "1" then
            arrowVisibilityState.pfQuestConfig = pfQuest_config["arrow"]
            pfQuest_config["arrow"] = "0"
            -- Also hide immediately
            if pfQuest and pfQuest.route and pfQuest.route.arrow then
                pfQuest.route.arrow:Hide()
            end
        end
    end
    
    -- QuestHelper
    if QHArrowFrame then
        if QHArrowFrame:IsVisible() then
            arrowVisibilityState.QuestHelper = true
            QHArrowFrame:Hide()
        end
    end
    
    -- Questie (if available)
    if Questie and Questie.arrow then
        if Questie.arrow:IsVisible() then
            arrowVisibilityState.Questie = true
            Questie.arrow:Hide()
        end
    end
    
    -- Global frame fallbacks
    local globalFrames = {
        "TomTomCrazyArrow",
        "pfQuestRouteArrow",  -- pfQuest arrow global name
        "DugisArrowFrame", 
        "ZygorGuidesViewerPointer",
    }
    for _, frameName in ipairs(globalFrames) do
        local frame = _G[frameName]
        if frame and frame:IsVisible() then
            arrowVisibilityState[frameName] = true
            frame:Hide()
        end
    end
end

local function ShowQuestArrows()
    -- TomTom - restore enable setting
    if arrowVisibilityState.TomTomEnable and TomTom and TomTom.profile and TomTom.profile.arrow then
        TomTom.profile.arrow.enable = true
        -- Call ShowHideCrazyArrow to properly restore the arrow
        if TomTom.ShowHideCrazyArrow then
            TomTom:ShowHideCrazyArrow()
        end
    end
    
    -- pfQuest - restore config
    if arrowVisibilityState.pfQuestConfig and pfQuest_config then
        pfQuest_config["arrow"] = arrowVisibilityState.pfQuestConfig
    end
    
    -- QuestHelper
    if arrowVisibilityState.QuestHelper and QHArrowFrame then
        QHArrowFrame:Show()
    end
    
    -- Questie
    if arrowVisibilityState.Questie and Questie and Questie.arrow then
        Questie.arrow:Show()
    end
    
    -- Global frame fallbacks
    local globalFrames = {"TomTomCrazyArrow", "pfQuestRouteArrow", "DugisArrowFrame", "ZygorGuidesViewerPointer"}
    for _, frameName in ipairs(globalFrames) do
        if arrowVisibilityState[frameName] then
            local frame = _G[frameName]
            if frame then
                frame:Show()
            end
        end
    end
    
    wipe(arrowVisibilityState)
end

local function OnShow()
    -- Store original minimap rotation setting
    originalRotateSetting = GetCVar("rotateMinimap")
    SetCVar("rotateMinimap", "1")
    
    -- Save minimap state before modifying
    SaveMinimapState()
    
    -- Reparent Minimap to our HUD container
    Minimap:SetParent(FarmHudMapCluster)
    
    -- Make minimap background transparent (only show pins)
    Minimap:SetAlpha(0)
    
    -- Reparent addon pins
    ReparentAddonPins(Minimap)
    
    -- Set scales and position
    FarmHud:SetScales()
    
    -- Disable minimap mouse on HUD
    Minimap:EnableMouse(false)
    
    -- Hide original minimap cluster
    MinimapCluster:Hide()
    
    -- Hide quest arrows from other addons if setting is enabled
    HideQuestArrows()
    
    -- Start update loop
    FarmHud:SetScript("OnUpdate", OnUpdate)
end

local function OnHide()
    -- Restore minimap rotation setting
    SetCVar("rotateMinimap", originalRotateSetting or "0")
    
    -- Restore addon pins
    RestoreAddonPins()
    
    -- Restore minimap state (parent, position, scale, alpha)
    RestoreMinimapState()
    
    -- Ensure minimap is visible
    Minimap:Show()
    
    -- Re-enable minimap mouse
    Minimap:EnableMouse(true)
    
    -- Show original minimap cluster
    MinimapCluster:Show()
    
    -- Restore quest arrows that we hid
    ShowQuestArrows()
    
    -- Stop update loop
    FarmHud:SetScript("OnUpdate", nil)
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function FarmHud:Toggle(flag)
    if flag == nil then
        if FarmHudMapCluster:IsVisible() then
            FarmHudMapCluster:Hide()
        else
            FarmHudMapCluster:Show()
        end
    else
        if flag then
            FarmHudMapCluster:Show()
        else
            FarmHudMapCluster:Hide()
        end
    end
end

function FarmHud:MouseToggle()
    if Minimap:IsMouseEnabled() then
        Minimap:EnableMouse(false)
        if mouseWarn then mouseWarn:Hide() end
    else
        Minimap:EnableMouse(true)
        if mouseWarn then mouseWarn:Show() end
    end
end

-- OpenOptions will be overridden by Options.lua
function FarmHud:OpenOptions()
    if FarmHudOptionsFrame then
        if FarmHudOptionsFrame:IsShown() then
            FarmHudOptionsFrame:Hide()
        else
            FarmHudOptionsFrame:Show()
        end
    else
        print("|cFFFFCC00FarmHud:|r Options panel not available")
    end
end

function FarmHud:UpdateCardinalVisibility()
    local show = FarmHudDB.show_cardinal_points ~= false  -- Default to true if nil
    for _, dir in ipairs(directions) do
        if show then
            dir:Show()
        else
            dir:Hide()
        end
    end
end

function FarmHud:UpdateCardinalPositions()
    -- This is called when settings change
    -- Cardinal positions are recalculated every frame in OnUpdate
    -- No action needed here - the OnUpdate loop will pick up the new settings
end

-------------------------------------------------------------------------------
-- Create HUD Elements
-------------------------------------------------------------------------------

local function CreateHUDElements()
    -- Gather circle (attached to FarmHudMapCluster, not Minimap)
    gatherCircle = FarmHudMapCluster:CreateTexture(nil, "OVERLAY")
    gatherCircle:SetTexture([[SPELLS\CIRCLE.BLP]])
    gatherCircle:SetBlendMode("ADD")
    gatherCircle:SetPoint("CENTER")
    gatherCircle:SetVertexColor(0, 1, 0, 0.7)
    
    -- Player dot
    playerDot = FarmHudMapCluster:CreateTexture(nil, "OVERLAY")
    playerDot:SetTexture([[Interface\GLUES\MODELS\UI_Tauren\gradientCircle.blp]])
    playerDot:SetBlendMode("ADD")
    playerDot:SetPoint("CENTER")
    playerDot:SetWidth(15)
    playerDot:SetHeight(15)
    
    -- Cardinal directions
    local radius = 140 * 0.214 -- Initial radius, will be updated
    for i, text in ipairs(CARDINAL_DIRECTIONS) do
        local rot = (0.785398163 * (i - 1))  -- 45 degrees in radians
        local dir = FarmHudMapCluster:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dir:SetText(text)
        dir:SetShadowOffset(0.2, -0.2)
        dir.rad = rot
        dir.radius = radius
        table.insert(directions, dir)
    end
    
    -- Mouse warning text
    mouseWarn = FarmHudMapCluster:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mouseWarn:SetPoint("CENTER", FarmHudMapCluster, "CENTER", 0, 50)
    mouseWarn:SetText("MOUSE ON")
    mouseWarn:Hide()
end

-------------------------------------------------------------------------------
-- Initialize Database
-------------------------------------------------------------------------------

local function InitializeDB()
    if not FarmHudDB then
        FarmHudDB = {}
    end
    
    if not FarmHudDB.MinimapIcon then
        FarmHudDB.MinimapIcon = {
            hide = false,
            minimapPos = 220,
            radius = 80,
        }
    end
    
    if FarmHudDB.show_gathermate == nil then
        FarmHudDB.show_gathermate = true
    end
    
    if FarmHudDB.show_routes == nil then
        FarmHudDB.show_routes = true
    end
    
    if FarmHudDB.show_npcscan == nil then
        FarmHudDB.show_npcscan = true
    end
    
    -- Cardinal points defaults
    if FarmHudDB.show_cardinal_points == nil then
        FarmHudDB.show_cardinal_points = true
    end
    
    if FarmHudDB.cardinal_bind_to_circle == nil then
        FarmHudDB.cardinal_bind_to_circle = false
    end
    
    if FarmHudDB.cardinal_distance == nil then
        FarmHudDB.cardinal_distance = 30  -- Default distance from center (percentage)
    end
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

function FarmHud:PLAYER_LOGIN()
    InitializeDB()
    
    -- Register minimap icon
    if LDBIcon and dataObject then
        LDBIcon:Register(addon, dataObject, FarmHudDB.MinimapIcon)
    end
    
    -- Setup FarmHudMapCluster
    FarmHudMapCluster:SetAlpha(FarmHudDB.hud_alpha or 0.7)
    
    -- Create visual elements
    CreateHUDElements()
    
    -- Setup show/hide scripts
    FarmHudMapCluster:SetScript("OnShow", OnShow)
    FarmHudMapCluster:SetScript("OnHide", OnHide)
end

function FarmHud:PLAYER_LOGOUT()
    self:Toggle(false)
end

-- Hide in combat support
function FarmHud:PLAYER_REGEN_DISABLED()
    if FarmHudDB.hide_in_combat and FarmHudMapCluster:IsVisible() then
        self._wasVisibleBeforeCombat = true
        self:Toggle(false)
    end
end

function FarmHud:PLAYER_REGEN_ENABLED()
    if self._wasVisibleBeforeCombat then
        self._wasVisibleBeforeCombat = nil
        self:Toggle(true)
    end
end

-- Hide in instances support
function FarmHud:ZONE_CHANGED_NEW_AREA()
    if FarmHudDB.hide_in_instances then
        local inInstance, instanceType = IsInInstance()
        if inInstance and FarmHudMapCluster:IsVisible() then
            self._wasVisibleBeforeInstance = true
            self:Toggle(false)
        elseif not inInstance and self._wasVisibleBeforeInstance then
            self._wasVisibleBeforeInstance = nil
            self:Toggle(true)
        end
    end
end

-------------------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------------------

FarmHud:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        return self[event](self, ...)
    end
end)

FarmHud:RegisterEvent("PLAYER_LOGIN")
FarmHud:RegisterEvent("PLAYER_LOGOUT")
FarmHud:RegisterEvent("PLAYER_REGEN_DISABLED")
FarmHud:RegisterEvent("PLAYER_REGEN_ENABLED")
FarmHud:RegisterEvent("ZONE_CHANGED_NEW_AREA")
