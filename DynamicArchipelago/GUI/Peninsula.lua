---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Peninsula: AceModule
local core = addon:NewModule('Peninsula')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Animations: AceModule
local animations = addon:GetModule('Animations')

---@class PeninsulaWidget
core.widget = {}

---@class (exact) PeninsulaCore
---@field AddChild function
---@field RemoveChild function
---@field itemData table
---@field items table
---@field widget PeninsulaWidget
---@field isMaximized boolean
core.proto = {}

local expandedCapHeight = 10
local CORE_BASE_PADDING = 4

local growthTimer = nil
local shrinkTimer = nil

--#region Core Methods

function core.widget:GrowAnimation()
    C_Timer.NewTicker(0.001,
        function(ticker)
            local expectedWidth = database:GetWidgetWidth()

            if animations:Grow(self, nil, expectedWidth, nil, 12) then
                ticker:Cancel()
            end
        end,
        256)
end

function core.widget:ShrinkAnimation()
    C_Timer.NewTicker(0.001,
        function(ticker)
            local expectedWidth = ISLE_SMALL_WIDTH

            if animations:Shrink(self, nil, expectedWidth, nil, 12) then
                ticker:Cancel()
            end
        end,
        256)
end

---@param widget BasePeninsula
function core.proto:AddChild(widget)
    local coreContent = self.widget.Base
    local childCount = #coreContent.children

    widget.frame:SetParent(coreContent)
    widget.frame:ClearAllPoints()

    local expectedPositionY = 0
    for _, childWidget in pairs(coreContent.children) do
        expectedPositionY = expectedPositionY + childWidget.height
    end

    if childCount == 0 then
        widget.frame:SetPoint('TOPLEFT', coreContent)
    else
        widget.frame:SetPoint('TOPLEFT', coreContent, 'TOPLEFT', 0, -(expectedPositionY + 1))
    end

    coreContent.children[childCount + 1] = widget

    childCount = childCount + 1

    local expectedHeight = (expectedPositionY + widget.height) + 1
    local expectedWidgetHeight = (expandedCapHeight * 2) + expectedHeight

    if not coreContent:IsShown() then
        coreContent:Show()
    end

    -- Trigger Core Content Growth
    if growthTimer and not growthTimer:IsCancelled() then
        growthTimer:Cancel()
    end

    widget.frame:SetHeight(widget.height)
    widget.frame:Show()
    widget.frame.animationIn:Play()

    growthTimer = C_Timer.NewTicker(0.001,
        function(ticker)
            if self.widget.height < expectedWidgetHeight then
                self.widget.height = self.widget.height + (4 * childCount)
                self.widget:SetHeight(min(self.widget.height, expectedWidgetHeight))
            end

            if self.widget.height >= expectedWidgetHeight then
                self.widget.height = expectedWidgetHeight
                self.widget:SetHeight(expectedWidgetHeight)
                ticker:Cancel()
            end
        end,
        1000)
end

---@param widget BasePeninsula
function core.proto:RemoveChild(widget)
    local coreContent = self.widget.Base
    local childCount = #coreContent.children

    local currentPositionY = 0
    local previousChildHeight = 0
    local childrenToRemove = {}
    for index, child in pairs(coreContent.children) do
        -- Get the current position, subtract its own height
        if child.id == widget.id then
            previousChildHeight = child.height
            tinsert(childrenToRemove, index)
        else
            local point, relativeTo, relativePoint, offsetX, offsetY = child.frame:GetPointByName('TOPLEFT')
            local newPos = offsetY + previousChildHeight
            currentPositionY = currentPositionY + child.height
            child.frame:SetPoint(point, relativeTo, relativePoint, offsetX, newPos)
        end
    end

    for _, index in pairs(childrenToRemove) do
        tremove(coreContent.children, index)
    end

    local expectedWidgetHeight = max(currentPositionY + (expandedCapHeight * 2), (expandedCapHeight * 2))

    if shrinkTimer and not shrinkTimer:IsCancelled() then
        shrinkTimer:Cancel()
    end

    childCount = childCount - 1

    shrinkTimer = C_Timer.NewTicker(0.001,
        function(ticker)
            -- Scale the widget
            if self.widget.height > expectedWidgetHeight then
                self.widget.height = self.widget.height - (4 * max(childCount, 1))
                self.widget:SetHeight(max(self.widget.height, expectedWidgetHeight))
            end

            if self.widget.height <= expectedWidgetHeight then
                widget:Wipe()
                ticker:Cancel()
            end
        end,
        1000)

    if #coreContent.children == 0 then
        core:Dissolve()
    end
end

--#endregion

function core:OnInitialize()
    self.data = setmetatable({}, { __index = core.proto })
    self:Create()
end

---@return PeninsulaCore
function core:Create()
    local position = database:GetWidgetPosition()
    local width = database:GetWidgetWidth()
    local isLocked = database:GetWidgetState()

    self.data.items = {}
    self.data.itemData = {}

    ---@type PeninsulaWidget
    local contentContainer = CreateFrame('Frame', 'DynamicArchipelagoCore', UIParent)
    contentContainer.GrowAnimation = core.widget.GrowAnimation
    contentContainer.ShrinkAnimation = core.widget.ShrinkAnimation
    self.data.widget = contentContainer

    ---@type PeninsulaBase
    local topContentCap = CreateFrame('Frame', nil, contentContainer)
    topContentCap:SetPoint('TOPLEFT', contentContainer, 'TOPLEFT')
    topContentCap:SetPoint('BOTTOMRIGHT', contentContainer, 'TOPRIGHT', 0, -expandedCapHeight)

    topContentCap.bg = topContentCap:CreateTexture(nil, 'ARTWORK')
    topContentCap.bg:SetAllPoints(topContentCap)
    topContentCap.bg:SetColorTexture(0, 0, 0, 0.75)

    topContentCap.mask = topContentCap:CreateMaskTexture()
    topContentCap.mask:SetAllPoints(topContentCap.bg)
    topContentCap.mask:SetTexture(utils:GetMediaDir() .. 'Art\\cap_mask', 'CLAMPTOBLACKADDITIVE',
        'CLAMPTOBLACKADDITIVE')
    topContentCap.bg:AddMaskTexture(topContentCap.mask)

    contentContainer.TopCap = topContentCap

    ---@type PeninsulaBase
    local bottomContentCap = CreateFrame('Frame', nil, contentContainer)
    bottomContentCap:SetPoint('TOPLEFT', contentContainer, 'BOTTOMLEFT', 0, expandedCapHeight)
    bottomContentCap:SetPoint('BOTTOMRIGHT')

    bottomContentCap.bg = bottomContentCap:CreateTexture(nil, 'ARTWORK')
    bottomContentCap.bg:SetAllPoints(bottomContentCap)
    bottomContentCap.bg:SetColorTexture(0, 0, 0, 0.75)

    bottomContentCap.mask = bottomContentCap:CreateMaskTexture()
    bottomContentCap.mask:SetAllPoints(bottomContentCap.bg)
    bottomContentCap.mask:SetTexture(utils:GetMediaDir() .. 'Art\\cap_mask', 'CLAMPTOBLACKADDITIVE',
        'CLAMPTOBLACKADDITIVE')
    bottomContentCap.mask:SetRotation(math.pi)
    bottomContentCap.bg:AddMaskTexture(bottomContentCap.mask)

    contentContainer.BottomCap = bottomContentCap

    ---@type PeninsulaWidgetContent
    local base = CreateFrame('Frame', nil, contentContainer)
    base:SetPoint('TOPLEFT', CORE_BASE_PADDING, -(CORE_BASE_PADDING * 2))
    base:SetPoint('BOTTOMRIGHT', -CORE_BASE_PADDING, CORE_BASE_PADDING * 2)

    local backgroundTex = contentContainer:CreateTexture(nil, 'ARTWORK')
    backgroundTex:SetPoint('TOPLEFT', 0, -expandedCapHeight)
    backgroundTex:SetPoint('BOTTOMRIGHT', 0, expandedCapHeight)
    backgroundTex:SetColorTexture(0, 0, 0, 0.75)

    base.children = {}

    contentContainer.Base = base
    contentContainer.Base.height = 0

    contentContainer:Hide()

    contentContainer.Base.height = base:GetHeight()
    self.data.widget = contentContainer

    return self.data
end

function core:Dissolve()
    if not self.data.isMaximized then return end

    events:SendMessage('DYNAMIC_ARCHIPELAGO_CORE_END')

    self.data.widget:ShrinkAnimation()
    animations:FadeOut(self.data.widget, 0.03)
    self.data.isMaximized = false
end

function core:Precipitate()
    if self.data.isMaximized then return end

    events:SendMessage('DYNAMIC_ARCHIPELAGO_CORE_START')

    self.data.widget:SetWidth(ISLE_SMALL_WIDTH)
    self.data.widget.height = expandedCapHeight * 2
    self.data.widget:SetHeight(self.data.widget.height)

    self.data.widget:Show()
    self.data.widget:SetAlpha(0.0)
    animations:FadeIn(self.data.widget, 0.1)
    self.data.widget:GrowAnimation()

    self.data.isMaximized = true
end

---@param widget BasePeninsula
function core:UpdateHeight(widget)
    self.data.widget.height = (expandedCapHeight * 2) + widget.height
    self.data.widget:SetHeight((expandedCapHeight * 2) + widget.height)
end

---@param widget DynamicArchipelagoItem
function events:DYNAMIC_ARCHIPELAGO_ADD_CORE_ITEM(_, widget)
    core:Precipitate()
    core.data:AddChild(widget)
end

---@param widget BasePeninsula
function events:DYNAMIC_ARCHIPELAGO_UPDATE_CORE_ITEM(_, widget)
    core:UpdateHeight(widget)
end

---@param widget BasePeninsula
function events:DYNAMIC_ARCHIPELAGO_ITEM_TIMER_END(_, widget)
    core.data:RemoveChild(widget)
end

core:Enable()
