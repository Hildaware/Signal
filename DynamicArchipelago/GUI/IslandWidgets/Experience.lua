---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class ExperienceWidget: AceModule
local exp = addon:NewModule('ExperienceWidget')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Resolver: AceModule
local resolver = addon:GetModule('Resolver')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class FrameHelpers: AceModule
local helper = addon:GetModule('FrameHelpers')

---@return IslandContent?
function exp:Create()
    ---@type IslandContent
    local islandData = { Small = nil, Full = nil, widget = nil }

    ---@class Island: AceModule
    local island = addon:GetModule('Island')

    local smallIsland = _G['DynamicArchipelago'].IslandSmall:Create()

    ---@type BaseIsland
    local smallContent = CreateFrame('Frame', nil, smallIsland.widget)
    smallContent:SetAllPoints(smallIsland.widget)

    local smallIconSize = smallIsland.widget:GetHeight() - (ISLAND_BASE_PADDING * 2)

    local smallProgress = helper:CreateCircularProgressFrame()
    smallProgress.widget:SetParent(smallContent)
    smallProgress.widget:ClearAllPoints()
    smallProgress.widget:SetPoint('LEFT', ISLAND_BASE_PADDING, 0)
    smallProgress.widget:SetSize(smallIconSize, smallIconSize)

    local text = smallContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    text:SetJustifyH('RIGHT')
    text:SetPoint('TOPLEFT', smallIconSize, 0)
    text:SetPoint('BOTTOMRIGHT', -(ISLAND_BASE_PADDING * 2), 2)

    smallIsland:SetChild(smallContent)

    local smallOnEnable = function(eventFrame, eventName, args)
        if eventName ~= 'PLAYER_XP_UPDATE' and eventName ~= 'PLAYER_ENTERING_WORLD' then return end

        local currentLevel = resolver:GetCurrentLevel()
        local currentXP = resolver:GetCurrentXP()
        local requiredXP = resolver:GetRequiredXP()

        local remainingXP = requiredXP - currentXP
        local currentPercent = utils:Round(currentXP / requiredXP, 4)
        local remainingPercent = utils:Round(remainingXP / requiredXP, 4)

        local levelStr = 'Level ' .. currentLevel .. ' ' .. format('%.1f%%', currentPercent * 100)
        text:SetText(levelStr)
        smallProgress.value = 0.38
        smallProgress:SetValue(smallProgress.value)
    end

    helper:CreateIslandEventFrame(smallContent, 'OnEvent', smallOnEnable)
    smallContent.eventFrame:RegisterEvent('PLAYER_XP_UPDATE') -- TODO: Unregister Event
    smallContent.eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')

    local largeIsland = _G['DynamicArchipelago'].IslandLarge:Create()

    ---@type BaseIsland
    local largeContent = CreateFrame('Frame', nil, largeIsland.widget)
    largeContent:SetAllPoints(largeIsland.widget)

    local largeIconPadding = ISLAND_BASE_PADDING * 2

    -- Bar & Text
    local bar = CreateFrame('StatusBar', nil, largeContent)
    bar:SetWidth(largeIsland.widget:GetWidth(true) - (largeIconPadding * 2))
    bar:SetHeight(16)
    bar:SetPoint('LEFT', largeContent, 'LEFT', largeIconPadding, 0)
    bar:SetPoint('RIGHT', largeContent, 'RIGHT', -largeIconPadding, 0)
    bar:SetStatusBarTexture(utils:GetMediaDir() .. 'Art\\progress_bar')
    bar:SetStatusBarColor(1, 1, 1, 1)
    bar:SetMinMaxValues(0.0, 1.0)

    local bgTex = bar:CreateTexture(nil, 'ARTWORK')
    bgTex:SetAllPoints(bar)
    bgTex:SetTexture(utils:GetMediaDir() .. 'Art\\progress_bar')
    bgTex:SetVertexColor(1, 1, 1, 0.25)

    local largeTextTop = largeContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightLarge')
    largeTextTop:SetJustifyH('CENTER')
    largeTextTop:SetPoint('TOPLEFT', largeIconPadding, 0)
    largeTextTop:SetPoint('BOTTOMRIGHT', bar, 'TOPRIGHT')

    local largeTextBottom = largeContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    largeTextBottom:SetJustifyH('CENTER')
    largeTextBottom:SetPoint('TOPLEFT', bar, 'BOTTOMLEFT', largeIconPadding, 0)
    largeTextBottom:SetPoint('BOTTOMRIGHT', -largeIconPadding, 0)

    largeIsland:SetChild(largeContent)

    local largeOnEnable = function(eventFrame, args)
        local currentLevel = resolver:GetCurrentLevel()
        local currentXP = resolver:GetCurrentXP()
        local requiredXP = resolver:GetRequiredXP()

        local remainingXP = requiredXP - currentXP
        local currentPercent = utils:Round(currentXP / requiredXP, 4)
        local remainingPercent = utils:Round(remainingXP / requiredXP, 4)

        local levelStr = format('%.1f%%', currentPercent * 100) ..
            ' (' .. format('%.1f%%', remainingPercent * 100) .. ' remaining)'
        local level = 'Level ' .. currentLevel .. ' ' .. currentXP .. ' / ' .. requiredXP
        largeTextTop:SetText(level)
        largeTextBottom:SetText(levelStr)
        bar:SetValue(currentPercent)
    end

    helper:CreateIslandEventFrame(largeContent, 'OnShow', largeOnEnable)
    largeContent.eventFrame:Hide()

    islandData.Small = smallIsland
    islandData.Full = largeIsland

    return islandData
end

exp:Enable()
