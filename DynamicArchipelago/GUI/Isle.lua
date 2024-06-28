---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Isle: AceModule
local island = addon:NewModule('Isle')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Animations: AceModule
local animations = addon:GetModule('Animations')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class (exact) IslandLife
---@field widget IslandFrame
---@field SetDataContent function
---@field EnableIsland function
---@field SetWidgetSize function
---@field FadeIn function
---@field FadeOut function
island.proto = {}

--#region IslandLife

---@param islandType number
function island.proto:EnableIsland(islandType)
    local content = self.widget.Content
    local widgetSize = ISLE_SMALL_WIDTH

    ---@type BaseIsle
    local enableFrame = nil

    if islandType == ISLE_TYPE.SMALL then
        enableFrame = content[ISLE_NAME.SMALL]
        widgetSize = ISLE_SMALL_WIDTH
    end
    if islandType == ISLE_TYPE.FULL then
        enableFrame = content[ISLE_NAME.FULL]
        widgetSize = ISLE_FULL_WIDTH
    end

    if enableFrame == nil then return end

    self:SetWidgetSize(widgetSize)

    enableFrame.widget:SetParent(content.widget)
    enableFrame.widget:SetAllPoints(content.widget)
    enableFrame.widget:Show()

    enableFrame:Connect()

    if content.OnClick ~= nil then
        self.widget:SetMouseClickEnabled(true)
        self.widget:SetScript('OnMouseDown', function()
            content.OnClick()
        end)
    end
end

function island.proto:SetWidgetSize(size)
    self.widget:SetSize(size, size / 4)
end

---@param content IslandContent
function island.proto:SetDataContent(content)
    self.widget.Content.Small = content.Small
    self.widget.Content.Full = content.Full
    self.widget.Content.OnClick = content.OnClick

    self:EnableIsland(ISLE_TYPE.SMALL)
end

function island.proto:StartAnimationIn()
    C_Timer.NewTicker(0.001,
        function(ticker)
            local expectedWidgetHeight = ISLE_FULL_WIDTH / 4
            local expectedWidgetWidth = ISLE_FULL_WIDTH

            local currentHeight = self.widget:GetHeight(true)
            local currentWidth = self.widget:GetWidth(true)
            -- Scale the height
            if currentHeight < expectedWidgetHeight then
                local newHeight = currentHeight + 3
                self.widget:SetHeight(min(newHeight, expectedWidgetHeight))
            end
            -- Scale the width
            if currentWidth < expectedWidgetWidth then
                local newWidth = currentWidth + 12
                self.widget:SetWidth(min(newWidth, expectedWidgetWidth))
            end

            -- Anim Finished
            if self.widget:GetWidth(true) >= expectedWidgetWidth and self.widget:GetHeight(true) >= expectedWidgetHeight then
                self.widget:SetHeight(expectedWidgetHeight)
                self.widget:SetWidth(expectedWidgetWidth)

                island.data:EnableIsland(ISLE_TYPE.FULL)
                ticker:Cancel()
            end
        end,
        40)
end

function island.proto:StartAnimationOut()
    C_Timer.NewTicker(0.001,
        function(ticker)
            local expectedWidgetHeight = ISLE_SMALL_WIDTH / 4
            local expectedWidgetWidth = ISLE_SMALL_WIDTH

            local currentHeight = self.widget:GetHeight(true)
            local currentWidth = self.widget:GetWidth(true)
            -- Scale the height
            if currentHeight > expectedWidgetHeight then
                local newHeight = currentHeight - 3
                self.widget:SetHeight(max(newHeight, expectedWidgetHeight))
            end
            -- Scale the width
            if currentWidth > expectedWidgetWidth then
                local newWidth = currentWidth - 12
                self.widget:SetWidth(max(newWidth, expectedWidgetWidth))
            end

            -- Anim Finished
            if self.widget:GetWidth(true) <= expectedWidgetWidth and self.widget:GetHeight(true) <= expectedWidgetHeight then
                self.widget:SetHeight(expectedWidgetHeight)
                self.widget:SetWidth(expectedWidgetWidth)

                island.data:EnableIsland(ISLE_TYPE.SMALL)
                ticker:Cancel()
            end
        end,
        40)
end

function island.proto:FadeIn()
    self.widget:Show()
    animations:FadeIn(self.widget, 0.05)
    self:EnableIsland(ISLE_TYPE.SMALL)
end

function island.proto:FadeOut()
    self.widget.Content.Small.widget:Hide()
    self.widget.Content.Small:Disconnect()
    self.widget.Content.Full.widget:Hide()
    self.widget.Content.Full:Disconnect()

    animations:FadeOut(self.widget, 0.05)
end

--#endregion

function island:OnInitialize()
    -- ???
end

---@return IslandLife
function island:Create()
    self.data = setmetatable({}, { __index = island.proto })

    ---@type IslandFrame
    local main = CreateFrame('Frame', 'DynamicArchipelagoIsland', UIParent)
    main:SetWidth(ISLE_BASE_WIDTH)
    main:SetHeight(ISLE_BASE_WIDTH / 4)
    main:SetPoint('CENTER')

    ---@type IsleControllerFrame
    local controller = addon:GetModule('IsleControllerFrame')
    controller.data.eventFrame:SetParent(main)

    -- Custom Animations
    main:SetScript('OnEnter', function()
        self.data.widget.Content.Small.widget:Hide()
        self.data.widget.Content.Small:Disconnect()
        self.data:StartAnimationIn()
    end)

    main:SetScript('OnLeave', function()
        self.data.widget.Content.Full.widget:Hide()
        self.data.widget.Content.Full:Disconnect()
        self.data:StartAnimationOut()
    end)

    local bgTex = main:CreateTexture(nil, 'ARTWORK')
    bgTex:SetAllPoints(main)
    bgTex:SetColorTexture(0, 0, 0, 0.75)

    local islandMask = main:CreateMaskTexture()
    islandMask:SetAllPoints(bgTex)
    islandMask:SetTexture(utils:GetMediaDir() .. 'Art\\island_mask', 'CLAMPTOBLACKADDITIVE',
        'CLAMPTOBLACKADDITIVE')
    bgTex:AddMaskTexture(islandMask)

    ---@type AnimatedFrame
    local islandContent = CreateFrame('Frame', nil, main)
    islandContent:SetAllPoints(main)

    main:Hide()

    main.Content = {
        widget = islandContent,
        Small = nil,
        Full = nil
    }

    self.data.widget = main

    return self.data
end

---@param widget PeninsulaWidget
function events:DYNAMIC_ARCHIPELAGO_SET_ISLE_WIDGET(_, widget)
    if island.data == nil then return end
    local newWidget = widget:Create()
    island.data:SetDataContent(newWidget)
end

island:Enable()
