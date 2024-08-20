---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class DungeonTimerWidget: AceModule
local dungeonTimer = addon:NewModule('DungeonTimerWidget')

---@class Resolver: AceModule
local resolver = addon:GetModule('Resolver')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Components: AceModule
local components = addon:GetModule('Components')

---@class IsleBase: AceModule
local isleBase = addon:GetModule('IsleBase')

---@class DungeonTimer: IslandContent
---@field timer FunctionContainer

---@return IslandContent?
function dungeonTimer:Create()
    ---@type DungeonTimer
    local islandData = { Small = nil, Full = nil, widget = nil, timer = nil }

    ---@type BaseIsle
    local smallIslandWidget = isleBase:Create(ISLE_TYPE.SMALL)
    if smallIslandWidget == nil then return end

    local smallContent = CreateFrame('Frame', nil, smallIslandWidget.widget)
    smallContent:SetAllPoints(smallIslandWidget.widget)

    local smallIconSize = smallIslandWidget.widget:GetHeight() - (ISLE_BASE_PADDING * 2)

    ---@type CircularProgressComponent?
    local smallProgress = components:Fetch('CircularProgress')
    if smallProgress == nil then return end

    smallProgress.widget:SetParent(smallContent)
    smallProgress.widget:ClearAllPoints()
    smallProgress.widget:SetPoint('LEFT', ISLE_BASE_PADDING, 0)
    smallProgress.widget:SetSize(smallIconSize, smallIconSize)

    local text = smallContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    text:SetJustifyH('RIGHT')
    text:SetPoint('TOPLEFT', smallIconSize, 0)
    text:SetPoint('BOTTOMRIGHT', -(ISLE_BASE_PADDING * 2), 2)

    text:SetText('')
    smallProgress:SetColor(utils:GetMergedColorPercentage(COLOR.YELLOW, COLOR.BLUE, 0))
    smallProgress.value = 0
    smallProgress:SetValue(smallProgress.value)

    ---@type BaseIsle
    local largeIsland = isleBase:Create(ISLE_TYPE.FULL)
    if largeIsland == nil then return end

    local largeContent = CreateFrame('Frame', nil, largeIsland.widget)
    largeContent:SetAllPoints(largeIsland.widget)

    -- Bar
    -- Timer




    local currentTimer = 0
    local timer = C_Timer.NewTicker(0.1, function()
        currentTimer = currentTimer + 0.1
        text:SetText(utils:GetReadableTime(currentTimer))

        local curPerc = utils:Round(currentTimer / 900, 4)
        smallProgress:SetColor(utils:GetMergedColorPercentage(COLOR.YELLOW, COLOR.BLUE, curPerc))
        smallProgress.value = curPerc
        smallProgress:SetValue(smallProgress.value)

        -- Update the large as well
    end)

    islandData.timer = timer
    islandData.Small = smallIslandWidget
    islandData.Full = largeIsland

    return islandData
end

dungeonTimer:Enable()
