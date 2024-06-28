---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class LocationWidget: AceModule
local location = addon:NewModule('LocationWidget')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class FrameHelpers: AceModule
local helper = addon:GetModule('FrameHelpers')

---@class IsleBase: AceModule
local isleBase = addon:GetModule('IsleBase')

---@return IslandContent?
function location:Create()
    ---@type IslandContent
    local islandData = { Small = nil, Full = nil, widget = nil }

    local smallIslandWidget = isleBase:Create(ISLE_TYPE.SMALL)
    if smallIslandWidget == nil then return end

    local smallContent = CreateFrame('Frame', nil, smallIslandWidget.widget)
    smallContent:SetAllPoints(smallIslandWidget.widget)

    local smallIconSize = smallIslandWidget.widget:GetHeight() - (ISLE_BASE_PADDING * 2)

    local smallIcon = helper:CreateIconFrame(237386)
    smallIcon:SetParent(smallContent)
    smallIcon:ClearAllPoints()
    smallIcon:SetPoint('LEFT', ISLE_BASE_PADDING, 0)
    smallIcon:SetSize(smallIconSize, smallIconSize)

    local locationText = smallContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightLarge')
    locationText:SetJustifyH('CENTER')
    locationText:SetPoint('LEFT', smallIcon, 'RIGHT', ISLE_BASE_PADDING, 1)
    locationText:SetPoint('RIGHT', -ISLE_BASE_PADDING, 1)

    smallIslandWidget:SetChild(smallContent)

    local smallOnEnable = function(eventFrame, elapsed)
        eventFrame.lastUpdated = eventFrame.lastUpdated + elapsed
        if eventFrame.lastUpdated >= 1 then
            local mapId = C_Map.GetBestMapForUnit('player')
            if mapId == nil then return nil end

            local position = C_Map.GetPlayerMapPosition(mapId, 'player')
            if position == nil then return nil end

            local x, y = position:GetXY()
            local positionStr = '(' .. string.format("%.1f", x * 100) .. ', ' .. string.format("%.1f", y * 100) .. ')'

            locationText:SetText(positionStr)

            eventFrame.lastUpdated = 0
        end
    end

    smallIslandWidget:RegisterEventFrame('OnUpdate', smallOnEnable)

    ---@type BaseIsland
    local largeIsland = isleBase:Create(ISLE_TYPE.FULL)
    if largeIsland == nil then return end

    local largeContent = CreateFrame('Frame', nil, largeIsland.widget)
    largeContent:SetAllPoints(largeIsland.widget)

    local largeIconSize = largeIsland.widget:GetHeight() - (ISLE_BASE_PADDING * 4)

    local largeIconPadding = ISLE_BASE_PADDING * 2

    local largeIcon = helper:CreateIconFrame(237386)
    largeIcon:SetParent(largeContent)
    largeIcon:ClearAllPoints()
    largeIcon:SetPoint('LEFT', largeIconPadding, 0)
    largeIcon:SetSize(largeIconSize, largeIconSize)

    local largeLocation = largeContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightLarge')
    largeLocation:SetJustifyH('CENTER')
    largeLocation:SetPoint('TOPLEFT', largeIcon, 'TOPRIGHT', largeIconPadding, 0)
    largeLocation:SetPoint('BOTTOMRIGHT', -largeIconPadding * 2, smallIslandWidget.widget:GetHeight())

    local largePosition = largeContent:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightLarge')
    largePosition:SetJustifyH('CENTER')
    largePosition:SetPoint('TOPLEFT', largeLocation, 'BOTTOMLEFT')
    largePosition:SetPoint('RIGHT', -largeIconPadding * 2, 0)

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

            largeLocation:SetText(mapInfo.name)
            largePosition:SetText(positionStr)

            eventFrame.lastUpdated = 0
        end
    end

    largeIsland:RegisterEventFrame('OnUpdate', largeOnEnable)

    islandData.Small = smallIslandWidget
    islandData.Full = largeIsland

    local onClick = function()
        ShowUIPanel(WorldMapFrame)
    end

    islandData.OnClick = onClick

    return islandData
end

location:Enable()
