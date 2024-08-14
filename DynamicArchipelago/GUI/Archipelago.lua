---@diagnostic disable: assign-type-mismatch
local addonName = ...

---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class PeninsulaWidget: AceModule
local arch = addon:NewModule('Archipelago')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Peninsula: AceModule
local core = addon:GetModule('Peninsula')

---@class Isle: AceModule
local island = addon:GetModule('Isle')

---@class (exact) Archipelago
---@field widget Frame
---@field island IslandLife
---@field core PeninsulaCore
arch.proto = {}

function arch:OnInitialize()
    self:Create()
end

function arch:Create()
    self.data = setmetatable({}, { __index = arch.proto })

    local position = database:GetWidgetPosition()
    local width = database:GetWidgetWidth()

    local frame = CreateFrame('Frame', 'DynamicArchipelago', UIParent)
    frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    frame:SetSize(width, 64)

    frame:SetScript('OnDragStart', function(f, button)
        if button == 'LeftButton' then
            f:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()

        local point, _, relativePoint, offsetX, offsetY = frame:GetPoint(1)
        database:SetWidgetPosition({ point = point, relativePoint = relativePoint, x = offsetX, y = offsetY })
    end)

    --#region Movable Items

    frame.movable = {}

    local closeButton = CreateFrame('Button', nil, frame, 'UIPanelCloseButton')
    closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
    closeButton:SetScript('OnClick', function()
        arch:ToggleLockedState(true)
    end)

    closeButton:Hide()

    frame.movable.close = closeButton

    local movableTexture = frame:CreateTexture(nil, 'BACKGROUND')
    movableTexture:SetAllPoints(frame)
    movableTexture:SetColorTexture(0, 0, 0, 0.5)
    movableTexture:Hide()
    frame.movable.texture = movableTexture

    --#endregion

    self.data.widget = frame

    local growUp = database:GetNotificationGrowth()
    local growthPoint = growUp and 'BOTTOM' or 'TOP'

    local coreIsland = island:Create()
    coreIsland.widget:ClearAllPoints()
    coreIsland.widget:SetParent(frame)
    coreIsland.widget:SetPoint(growthPoint, frame, growthPoint, 0, 0)

    self.data.island = coreIsland

    local coreContent = core:Create()
    coreContent.widget:ClearAllPoints()
    coreContent.widget:SetParent(frame)
    coreContent.widget:SetPoint(growthPoint, frame, growthPoint, 0, 0)
    coreContent.widget:SetSize(0, 0)

    self.data.core = coreContent

    frame:Show()
    self.data.island:FadeIn()

    addon.status.isReady = true
end

---@param state boolean
function arch:ToggleLockedState(state)
    local widget = self.data.widget
    if state == true then
        widget.movable.texture:Hide()
        widget.movable.close:Hide()
        widget:SetMovable(false)
        widget:EnableMouse(false)
    else
        widget.movable.texture:Show()
        widget.movable.close:Show()
        widget:RegisterForDrag('LeftButton')
        widget:SetMovable(true)
        widget:EnableMouse(true)
    end
end

function events:DYNAMIC_ARCHIPELAGO_CORE_START()
    if arch.data.core.widget:IsShown() then return end -- Shouldn't happend but whatev
    arch.data.island:FadeOut()
end

function events:DYNAMIC_ARCHIPELAGO_CORE_END()
    arch.data.island:FadeIn()
end

function events:DYNAMIC_ARCHIPELAGO_UPDATE_CONFIG()
    -- Update specific things that are adjusted!
    local growUp = database:GetNotificationGrowth()
    local growthPoint = growUp and 'BOTTOM' or 'TOP'

    arch.data.island.widget:ClearAllPoints()
    arch.data.island.widget:SetPoint(growthPoint, arch.data.widget, growthPoint, 0, 0)

    arch.data.core.widget:ClearAllPoints()
    arch.data.core.widget:SetPoint(growthPoint, arch.data.widget, growthPoint, 0, 0)
end

arch:Enable()
