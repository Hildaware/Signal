---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class LocationWidget: AceModule
local location = addon:NewModule('LocationWidget')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class FrameHelpers: AceModule
local helper = addon:GetModule('FrameHelpers')

---@return IslandContent?
function location:Create()
    ---@type IslandContent
    local islandData = { Small = nil, Full = nil, widget = nil }

    ---@class Island: AceModule
    local island = addon:GetModule('Island')

    local smallIsland = _G['DynamicArchipelago'].IslandSmall:Create()

    ---@type BaseIsland
    local smallContent = CreateFrame('Frame', nil, smallIsland.widget)
    smallContent:SetAllPoints(smallIsland.widget)

    local smallIconSize = smallIsland.widget:GetHeight() - (ISLAND_BASE_PADDING * 2)

    local smallIcon = helper:CreateIconFrame(237386)
    smallIcon:SetParent(smallContent)
    smallIcon:ClearAllPoints()
    smallIcon:SetPoint('LEFT', ISLAND_BASE_PADDING, 0)
    smallIcon:SetSize(smallIconSize, smallIconSize)

    local positionXY = smallContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    positionXY:SetJustifyH('RIGHT')
    positionXY:SetPoint('TOPLEFT', smallIconSize, 0)
    positionXY:SetPoint('BOTTOMRIGHT', -(ISLAND_BASE_PADDING * 2), 2)

    smallIsland:SetChild(smallContent)

    local smallOnEnable = function(eventFrame, elapsed)
        eventFrame.lastUpdated = eventFrame.lastUpdated + elapsed
        if eventFrame.lastUpdated >= 1 then
            local mapId = C_Map.GetBestMapForUnit('player')
            if mapId == nil then return nil end

            local position = C_Map.GetPlayerMapPosition(mapId, 'player')
            if position == nil then return nil end

            local x, y = position:GetXY()
            local positionStr = '(' .. string.format("%.2f", x * 100) .. ', ' .. string.format("%.2f", y * 100) .. ')'

            positionXY:SetText(positionStr)

            eventFrame.lastUpdated = 0
        end
    end

    helper:CreateIslandEventFrame(smallContent, smallOnEnable)

    local largeIsland = _G['DynamicArchipelago'].IslandLarge:Create()

    ---@type BaseIsland
    local largeContent = CreateFrame('Frame', nil, largeIsland.widget)
    largeContent:SetAllPoints(largeIsland.widget)

    local largeIconSize = largeIsland.widget:GetHeight() - (ISLAND_BASE_PADDING * 4)

    local largeIconPadding = ISLAND_BASE_PADDING * 2

    local largeIcon = helper:CreateIconFrame(237386)
    largeIcon:SetParent(largeContent)
    largeIcon:ClearAllPoints()
    largeIcon:SetPoint('LEFT', largeIconPadding, 0)
    largeIcon:SetSize(largeIconSize, largeIconSize)

    local largePosition = largeContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightLarge')
    largePosition:SetJustifyH('CENTER')
    largePosition:SetPoint('TOPLEFT', largeIconSize + largeIconPadding, 0)
    largePosition:SetPoint('BOTTOMRIGHT', -largeIconPadding, 2)

    largeIsland:SetChild(largeContent)

    local largeOnEnable = function(eventFrame, elapsed)
        eventFrame.lastUpdated = eventFrame.lastUpdated + elapsed
        if eventFrame.lastUpdated >= 1 then
            local mapId = C_Map.GetBestMapForUnit('player')
            if mapId == nil then return nil end

            local mapInfo = C_Map.GetMapInfo(mapId)
            local position = C_Map.GetPlayerMapPosition(mapId, 'player')
            if position == nil then return nil end

            local x, y = position:GetXY()
            local positionStr = '(' .. string.format("%.2f", x * 100) .. ', ' .. string.format("%.2f", y * 100) .. ')'

            largePosition:SetText(mapInfo.name .. " " .. positionStr)

            eventFrame.lastUpdated = 0
        end
    end

    helper:CreateIslandEventFrame(largeContent, largeOnEnable)

    islandData.Small = smallIsland
    islandData.Full = largeIsland

    local onClick = function()
        ShowUIPanel(WorldMapFrame)
    end

    islandData.OnClick = onClick

    return islandData
end

location:Enable()
