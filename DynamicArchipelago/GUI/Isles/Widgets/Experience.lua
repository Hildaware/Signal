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

---@class IsleBase: AceModule
local isleBase = addon:GetModule('IsleBase')

---@return IslandContent?
function exp:Create()
    ---@type IslandContent
    local islandData = { Small = nil, Full = nil, widget = nil }

    ---@type BaseIsland
    local smallIslandWidget = isleBase:Create(ISLAND_TYPE.SMALL)
    if smallIslandWidget == nil then return end

    local smallContent = CreateFrame('Frame', nil, smallIslandWidget.widget)
    smallContent:SetAllPoints(smallIslandWidget.widget)

    local smallIconSize = smallIslandWidget.widget:GetHeight() - (ISLAND_BASE_PADDING * 2)

    local smallProgress = helper:CreateCircularProgressFrame()
    smallProgress.widget:SetParent(smallContent)
    smallProgress.widget:ClearAllPoints()
    smallProgress.widget:SetPoint('LEFT', ISLAND_BASE_PADDING, 0)
    smallProgress.widget:SetSize(smallIconSize, smallIconSize)

    local text = smallContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    text:SetJustifyH('RIGHT')
    text:SetPoint('TOPLEFT', smallIconSize, 0)
    text:SetPoint('BOTTOMRIGHT', -(ISLAND_BASE_PADDING * 2), 2)

    -- Populate on initialize
    local currentLevel = resolver:GetCurrentLevel()
    local currentXP = resolver:GetCurrentXP()
    local requiredXP = resolver:GetRequiredXP()

    local currentPercent = utils:Round(currentXP / requiredXP, 4)
    local levelStr = 'Level ' .. currentLevel .. ' (' .. format('%.1f%%', currentPercent * 100) .. ')'

    text:SetText(levelStr)
    smallProgress.value = currentPercent
    smallProgress:SetValue(smallProgress.value)

    smallIslandWidget:SetChild(smallContent)

    local smallOnEnable = function(eventFrame, eventName, args)
        print('smallOnEnable', eventName)
        if eventName ~= 'PLAYER_XP_UPDATE' and eventName ~= 'PLAYER_REGEN_ENABLED' then return end

        local curLvl = resolver:GetCurrentLevel()
        local curXP = resolver:GetCurrentXP()
        local reqXP = resolver:GetRequiredXP()

        local curPerc = utils:Round(curXP / reqXP, 4)

        local lvlStr = 'Level ' .. curLvl .. ' (' .. format('%.1f%%', curPerc * 100) .. ')'
        text:SetText(lvlStr)
        smallProgress.value = curPerc
        smallProgress:SetValue(smallProgress.value)
    end

    smallIslandWidget:RegisterEventFrame('OnEvent', smallOnEnable)
    smallIslandWidget:RegisterEvents({ 'PLAYER_REGEN_ENABLED', 'PLAYER_XP_UPDATE' })

    ---@type BaseIsland
    local largeIsland = isleBase:Create(ISLAND_TYPE.FULL)
    if largeIsland == nil then return end

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
        local curLvl = resolver:GetCurrentLevel()
        local curXP = resolver:GetCurrentXP()
        local reqXP = resolver:GetRequiredXP()

        local curPerc = utils:Round(curXP / reqXP, 4)

        local turnInXP = 0
        local completedQuests = 0
        local questEntries = C_QuestLog.GetNumQuestLogEntries()
        for i = 1, questEntries, 1 do
            local questId = C_QuestLog.GetQuestIDForLogIndex(i)
            if questId ~= nil and questId > 0 then
                local rewardXP = GetQuestLogRewardXP(questId)

                if rewardXP > 0 then
                    if C_QuestLog.IsComplete(questId) or C_QuestLog.ReadyForTurnIn(questId) then
                        completedQuests = completedQuests + 1
                        turnInXP = turnInXP + rewardXP
                    end
                end
            end
        end

        local questsCompletedPercent = utils:Round(turnInXP / reqXP, 4)

        local lvlStr = completedQuests .. ' Quests Completed' ..
            ' (' .. format('%.1f%%', questsCompletedPercent * 100) .. ')'
        local level = 'Level ' .. curLvl .. ' (' .. format('%.1f%%', curPerc * 100) .. ')'
        largeTextTop:SetText(level)
        largeTextBottom:SetText(lvlStr)
        bar:SetValue(curPerc)
    end

    largeIsland:RegisterEventFrame('OnShow', largeOnEnable)

    islandData.Small = smallIslandWidget
    islandData.Full = largeIsland

    return islandData
end

exp:Enable()
