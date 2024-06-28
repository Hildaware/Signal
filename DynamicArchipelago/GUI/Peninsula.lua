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

local expandedCapHeight = 16
local nonExpandedCapHeight = 8
local nonExpandedWidth = 64

local CORE_BASE_PADDING = 8

--#region Core Methods

function core.widget:GrowAnimation()
    C_Timer.NewTicker(0.001,
        function(ticker)
            local expectedWidth = 512

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

---@param frame Frame
---@param onFinished function?
---@return AnimationGroup
local function CreateCapAnimationIn(frame, onFinished)
    local anim = frame:CreateAnimationGroup()

    local fade = anim:CreateAnimation('Alpha')
    fade:SetDuration(0.55)
    fade:SetFromAlpha(0.25)
    fade:SetToAlpha(1.0)

    local grow = anim:CreateAnimation('Scale')
    grow:SetDuration(0.55)
    grow:SetScaleFrom(0.125, 1.0)
    grow:SetScaleTo(1.0, 1.0)

    if onFinished ~= nil then
        anim:SetScript('OnFinished', function()
            onFinished()
        end)
    end

    return anim
end

---@param frame Frame
---@return AnimationGroup
local function CreateCapAnimationOut(frame)
    local anim = frame:CreateAnimationGroup()

    local fade = anim:CreateAnimation('Alpha')
    fade:SetDuration(0.55)
    fade:SetFromAlpha(1.0)
    fade:SetToAlpha(0.25)

    local shrink = anim:CreateAnimation('Scale')
    shrink:SetDuration(0.55)
    shrink:SetScaleFrom(1.0, 1.0)
    shrink:SetScaleTo(0.125, 1.0)

    anim:SetScript('OnFinished', function()
        local widget = core.data.widget
        widget:SetWidth(nonExpandedWidth)
        widget.height = nonExpandedCapHeight * 2
        widget:SetHeight(widget.height)

        widget.TopCap:SetWidth(nonExpandedWidth)
        widget.TopCap:SetHeight(nonExpandedCapHeight)

        widget.BottomCap:SetWidth(nonExpandedWidth)
        widget.BottomCap:SetHeight(nonExpandedCapHeight)

        widget.Base:SetWidth(nonExpandedWidth)
        widget:SetAlpha(0.25)
        -- if core.data.shouldHide then -- TODO: Lock this behind a toggle for people
        --     core.data.widget:Hide()
        --     core.data.shouldHide = false
        -- end
    end)

    return anim
end

---@param widget BasePeninsula
function core.proto:AddChild(widget)
    local coreContent = self.widget.Base
    local childCount = #coreContent.children

    widget.frame:SetParent(coreContent)
    widget.frame:ClearAllPoints()

    if childCount == 0 then
        widget.frame:SetPoint('TOPLEFT', coreContent)
    elseif childCount == 1 then
        widget.frame:SetPoint('TOPLEFT', coreContent.children[childCount].frame, 'BOTTOMLEFT')
    else
        widget.frame:SetPoint('TOPLEFT', coreContent.children[childCount - 1].frame, 'BOTTOMLEFT')
    end

    coreContent.children[childCount + 1] = widget

    local expectedHeight = coreContent.height + widget.height
    local expectedWidgetHeight = self.widget.height + widget.height

    if not coreContent:IsShown() then
        coreContent:Show()
    end

    C_Timer.NewTicker(0.001,
        function(ticker)
            -- Scale the widget
            if self.widget.height < expectedWidgetHeight then
                self.widget.height = self.widget.height + 4
                self.widget:SetHeight(min(self.widget.height, expectedWidgetHeight))
            end

            -- Scale the content container
            if coreContent.height < expectedHeight then
                coreContent.height = coreContent.height + 4
                coreContent:SetHeight(min(coreContent.height, expectedHeight))
            end

            if self.widget.height >= expectedWidgetHeight and coreContent.height >= expectedHeight then
                widget.frame:SetHeight(widget.height)
                widget.frame:Show()
                widget.frame.animationIn:Play()
                ticker:Cancel()
            end
        end,
        widget.height)
end

---@param widget BasePeninsula
function core.proto:RemoveChild(widget)
    local coreContent = self.widget.Base

    for index, child in pairs(coreContent.children) do
        if child.id == widget.id then
            -- Set the next item in the stack to the removed point
            if #coreContent.children > index then
                local point, relativeTo, relativePoint, _, _ = child.frame:GetPointByName('TOPLEFT')
                coreContent.children[index + 1].frame:SetPoint(point, relativeTo, relativePoint)
            end

            tremove(coreContent.children, index)
        end
    end

    local expectedHeight = coreContent.height - widget.height
    local expectedWidgetHeight = self.widget.height - widget.height

    C_Timer.NewTicker(0.001,
        function(ticker)
            -- Scale the widget
            if self.widget.height > expectedWidgetHeight then
                self.widget.height = self.widget.height - 4
                self.widget:SetHeight(max(self.widget.height, expectedWidgetHeight))
            end

            -- Scale the content container
            if coreContent.height > expectedHeight then
                coreContent.height = coreContent.height - 4
                coreContent:SetHeight(max(coreContent.height, expectedHeight))
            end

            if self.widget.height <= expectedWidgetHeight and coreContent.height <= expectedHeight then
                widget:Wipe()
                ticker:Cancel()
            end
        end,
        widget.height)

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
    topContentCap:SetPoint('BOTTOMRIGHT', contentContainer, 'TOPRIGHT', 0, -16)

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
    bottomContentCap:SetPoint('TOPLEFT', contentContainer, 'BOTTOMLEFT', 0, 16)
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
    backgroundTex:SetPoint('TOPLEFT', 0, -16)
    backgroundTex:SetPoint('BOTTOMRIGHT', 0, 16)
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

---@param widget DynamicArchipelagoItem
function events:DYNAMIC_ARCHIPELAGO_ADD_CORE_ITEM(_, widget)
    core:Precipitate()
    core.data:AddChild(widget)
end

---@param widget BasePeninsula
function events:DYNAMIC_ARCHIPELAGO_ITEM_TIMER_END(_, widget)
    core.data:RemoveChild(widget)
end

core:Enable()
