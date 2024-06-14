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

---@class CoreContent : Frame
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
---@field shouldHide boolean
core.proto = {}

-- TODO: Make this a configurable setting!
local animationTime = 0.5

-- TODO: Move to utils or something
---@param frame Frame
---@param offset number
---@return AnimationGroup
local function CreateCapAnimation(frame, offset)
    local anim = frame:CreateAnimationGroup('AnimTest')

    local trans = anim:CreateAnimation('Translation')
    trans:SetOffset(0, offset)
    trans:SetDuration(animationTime)
    local fade = anim:CreateAnimation('Alpha')
    fade:SetDuration(animationTime)
    fade:SetToAlpha(0.0)
    fade:SetFromAlpha(1.0)

    anim:SetScript('OnFinished', function()
        if core.data.shouldHide then
            core.data.widget:Hide()
            core.data.shouldHide = false
        end
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

    coreContent.height = coreContent.height + widget.height
    coreContent:SetHeight(coreContent.height)

    self.widget.height = self.widget.height + widget.height
    self.widget:SetHeight(self.widget.height)

    widget.frame:SetHeight(widget.height)
    widget.frame:Show()
    widget.frame.content:Show()
    widget.frame.icon:Show()

    widget.frame.animationIn:Play()
    coreContent:Show()
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

    self.widget.height = self.widget.height - widget.height
    coreContent.height = coreContent.height - widget.height

    widget:Wipe()

    if #coreContent.children == 0 then
        core:Dissolve()
        C_Timer.NewTimer(animationTime, function()
            self.widget:SetHeight(self.widget.height)
            coreContent:SetHeight(coreContent.height)
        end)
    else
        self.widget:SetHeight(self.widget.height)
        coreContent:SetHeight(coreContent.height)
    end
end

function core:OnInitialize()
    self:Create()
end

function core:Create()
    -- TODO: These props
    -- local position = database:GetHeadsUpViewPosition()
    -- local scale = database:GetHeadsUpViewScale()
    -- local isLocked = database:GetHeadsUpViewLocked()
    local width = database:GetWidgetWidth()

    self.data = setmetatable({}, { __index = core.proto })
    self.data.items = {}
    self.data.itemData = {}
    self.data.shouldHide = true

    ---@type Archipelago
    local arch = CreateFrame('Frame', nil, UIParent)
    arch:SetWidth(width)
    arch:SetHeight(32)
    arch:SetPoint('CENTER')

    --#region Top Cap

    ---@type AnimatedFrame
    local top = CreateFrame('Frame', nil, arch)
    top:SetPoint('TOPLEFT')
    top:SetPoint('BOTTOMRIGHT', arch, 'TOPRIGHT', 0, -16)

    local topAnim = CreateCapAnimation(top, -64)
    top.animation = topAnim

    local topTex = top:CreateTexture(nil, 'ARTWORK')
    topTex:SetAllPoints(top)
    topTex:SetTexture(utils:GetMediaDir() .. 'Art\\bg_top_sm')
    topTex:SetVertexColor(0, 0, 0, 0.65)

    arch.TopCap = top

    --#endregion

    --#region Bottom Cap

    ---@type AnimatedFrame
    local bottom = CreateFrame('Frame', nil, arch)
    bottom:SetPoint('TOPLEFT', arch, 'BOTTOMLEFT', 0, 16)
    bottom:SetPoint('BOTTOMRIGHT', arch, 'BOTTOMRIGHT')

    local bottomAnim = CreateCapAnimation(bottom, 64)
    bottom.animation = bottomAnim

    local bottomTex = bottom:CreateTexture(nil, 'ARTWORK')
    bottomTex:SetAllPoints(bottom)
    bottomTex:SetTexture(utils:GetMediaDir() .. 'Art\\bg_bottom_sm')
    bottomTex:SetVertexColor(0, 0, 0, 0.65)

    arch.BottomCap = bottom

    --#endregion

    ---@type CoreContent
    local base = CreateFrame('Frame', nil, arch)
    base:SetPoint('TOPLEFT', top, 'BOTTOMLEFT')
    base:SetPoint('BOTTOMRIGHT', bottom, 'TOPRIGHT')

    base.children = {}

    arch.Base = base
    arch.Base.height = 0

    arch:Hide()

    arch.height = arch:GetHeight()
    self.data.widget = arch
end

function core:Dissolve()
    if not self.data.widget:IsShown() then return end
    self.data.shouldHide = true
    self.data.widget.TopCap.animation:Play()
    self.data.widget.BottomCap.animation:Play()
end

function core:Precipitate()
    if self.data.widget:IsShown() then return end
    core.data.widget:Show()
    self.data.shouldHide = false
    self.data.widget.TopCap.animation:Play(true)
    self.data.widget.BottomCap.animation:Play(true)
end

---@param widget DynamicArchipelagoItem
function events:DYNAMIC_ARCHIPELAGO_ADD(_, widget)
    core.data:AddChild(widget)
    core:Precipitate()
end

---@param widget BaseArchipelagoItem
function events:DYNAMIC_ARCHIPELAGO_ITEM_TIMER_END(_, widget)
    core.data:RemoveChild(widget)
end

core:Enable()
