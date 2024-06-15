---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Core: AceModule
local core = addon:NewModule('Core')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class CoreContent : AnimatedFrame
---@field children BaseArchipelagoItem[]
---@field height number

---@class Archipelago : Frame
---@field Base CoreContent
---@field TopCap AnimatedFrame
---@field BottomCap AnimatedFrame
---@field height number

---@class (exact) CoreData
---@field AddChild function
---@field RemoveChild function
---@field itemData table
---@field items table
---@field widget Archipelago
---@field isMaximized boolean
core.proto = {}

local expandedCapHeight = 16
local nonExpandedCapHeight = 8
local nonExpandedWidth = 64

--#region Core Methods

---@param frame Frame
---@param onFinished function?
---@return AnimationGroup
local function CreateCapAnimationIn(frame, onFinished)
    local anim = frame:CreateAnimationGroup('CapAnimationIn')

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
    local anim = frame:CreateAnimationGroup('CapAnimationOut')

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

---@param widget BaseArchipelagoItem
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

---@param widget BaseArchipelagoItem
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

function core:OnInitialize()
    self:Create()
end

--#endregion

function core:Create()
    local position = database:GetWidgetPosition()
    local width = database:GetWidgetWidth()
    local isLocked = database:GetWidgetState()

    self.data = setmetatable({}, { __index = core.proto })
    self.data.items = {}
    self.data.itemData = {}

    ---@type Archipelago
    local arch = CreateFrame('Frame', nil, UIParent)
    arch:SetWidth(nonExpandedWidth)
    arch:SetHeight(nonExpandedCapHeight * 2)
    arch:SetPoint('CENTER', UIParent, 'BOTTOM', position.X, position.Y)
    arch:SetAlpha(0.25)

    --#region Top Cap

    ---@type AnimatedFrame
    local top = CreateFrame('Frame', nil, arch)
    top:SetWidth(nonExpandedWidth)
    top:SetHeight(nonExpandedCapHeight)
    top:SetPoint('TOP')

    local topAnimIn = CreateCapAnimationIn(top, function()
        core.data.widget.TopCap:SetHeight(expandedCapHeight)
    end)
    top.animationIn = topAnimIn

    local topAnimOut = CreateCapAnimationOut(top)
    top.animationOut = topAnimOut

    local topTex = top:CreateTexture(nil, 'ARTWORK')
    topTex:SetAllPoints(top)
    topTex:SetTexture(utils:GetMediaDir() .. 'Art\\bg_top_sm')
    topTex:SetVertexColor(0, 0, 0, 0.65)

    arch.TopCap = top

    --#endregion

    --#region Bottom Cap

    ---@type AnimatedFrame
    local bottom = CreateFrame('Frame', nil, arch)
    bottom:SetWidth(nonExpandedWidth)
    bottom:SetHeight(nonExpandedCapHeight)
    bottom:SetPoint('BOTTOM')

    local bottomAnimIn = CreateCapAnimationIn(bottom, function()
        core.data.widget.BottomCap:SetHeight(expandedCapHeight)
    end)
    bottom.animationIn = bottomAnimIn

    local bottomAnimOut = CreateCapAnimationOut(bottom)
    bottom.animationOut = bottomAnimOut

    local bottomTex = bottom:CreateTexture(nil, 'ARTWORK')
    bottomTex:SetAllPoints(bottom)
    bottomTex:SetTexture(utils:GetMediaDir() .. 'Art\\bg_bottom_sm')
    bottomTex:SetVertexColor(0, 0, 0, 0.65)

    arch.BottomCap = bottom

    --#endregion

    --#region Content

    ---@type CoreContent
    local base = CreateFrame('Frame', nil, arch)
    base:SetWidth(nonExpandedWidth)
    base:SetPoint('TOP', top, 'BOTTOM')
    base:SetPoint('BOTTOM', bottom, 'TOP')

    local backgroundTex = base:CreateTexture(nil, 'ARTWORK')
    backgroundTex:SetAllPoints(base)
    backgroundTex:SetColorTexture(0, 0, 0, 0.65)

    base.animationIn = CreateCapAnimationIn(base)
    base.animationOut = CreateCapAnimationOut(base)

    base.children = {}

    arch.Base = base
    arch.Base.height = 0

    --#endregion

    -- arch:Hide() -- TODO: Toggleable

    arch.height = arch:GetHeight()
    self.data.widget = arch
end

function core:Dissolve()
    if not core.data.isMaximized then return end
    self.data.widget.TopCap.animationOut:Play()
    self.data.widget.BottomCap.animationOut:Play()
    self.data.widget.Base.animationOut:Play()
    core.data.isMaximized = false
end

function core:Precipitate()
    if core.data.isMaximized then return end

    local width = database:GetWidgetWidth()
    core.data.widget:SetWidth(width)
    core.data.widget.TopCap:SetWidth(width)
    core.data.widget.BottomCap:SetWidth(width)
    core.data.widget.Base:SetWidth(width)
    core.data.widget:SetAlpha(1.0)

    core.data.widget.height = expandedCapHeight * 2
    core.data.widget:SetHeight(core.data.widget.height)

    self.data.widget.TopCap.animationIn:Play()
    self.data.widget.BottomCap.animationIn:Play()
    self.data.widget.Base.animationIn:Play()
    core.data.isMaximized = true
end

---@param widget DynamicArchipelagoItem
function events:DYNAMIC_ARCHIPELAGO_ADD(_, widget)
    core:Precipitate()
    core.data:AddChild(widget)
end

---@param widget BaseArchipelagoItem
function events:DYNAMIC_ARCHIPELAGO_ITEM_TIMER_END(_, widget)
    core.data:RemoveChild(widget)
end

core:Enable()
