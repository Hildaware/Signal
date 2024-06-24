local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class BaseFrame: AceModule
local baseFrame = addon:NewModule('BaseFrame')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Database: AceModule
local database = addon:GetModule('Database')

--#region Types

---@class BaseArchipelagoFrame : Frame
---@field header FontString
---@field icon Frame
---@field content Frame
---@field progress StatusBar
---@field animationIn AnimationGroup
---@field animationOut AnimationGroup

---@class (exact) BaseArchipelagoItem : DynamicArchipelagoItem
---@field id string
---@field frame BaseArchipelagoFrame
---@field child DynamicArchipelagoItem
---@field SetHeader function
---@field SetType function
---@field SetContent function
---@field SetIcon function
---@field GetHeaderHeight function
---@field height number
---@field GetIconWidth function
---@field GetWidgetWidth function
baseFrame.baseProto = {}

--#endregion

local padding = 8

--#region Base Item Methods

---@return number
function baseFrame.baseProto:GetWidgetWidth()
    return database:GetWidgetWidth()
end

---@return number
function baseFrame.baseProto:GetIconWidth()
    return database:GetWidgetWidth() / 4
end

---@return number
function baseFrame.baseProto:GetHeaderHeight()
    return self.frame.header:GetHeight()
end

---@param str string
function baseFrame.baseProto:SetHeader(str)
    self.frame.header:SetText(str)
end

---@param str string
function baseFrame.baseProto:SetType(str)
    self.frame.header:SetText(str .. ' - Just Now')
end

---@param content Frame
function baseFrame.baseProto:SetContent(content)
    content:SetParent(self.frame.content)
    content:ClearAllPoints()
    content:SetPoint('TOPLEFT', self.frame.header, 'BOTTOMLEFT')
    content:SetPoint('BOTTOMRIGHT')
end

---@param widget DynamicArchipelagoItem
function baseFrame.baseProto:SetChild(widget)
    self.child = widget
end

---@param icon Frame
function baseFrame.baseProto:SetIcon(icon)
    icon:SetParent(self.frame.icon)
    icon:ClearAllPoints()
    icon:SetPoint('TOPLEFT')
    icon:SetPoint('BOTTOMRIGHT')
end

---@param visibilityTime number
function baseFrame.baseProto:SetProgressBar(visibilityTime)
    local duration = visibilityTime
    local progressBar = self.frame.progress
    ---@diagnostic disable-next-line: undefined-field
    progressBar:SetMinMaxSmoothedValue(0, visibilityTime)

    progressBar:SetScript('OnUpdate', function(bar, elapsed)
        duration = duration - elapsed
        bar:SetSmoothedValue(duration)
    end)
end

function baseFrame.baseProto:Release()
    baseFrame._pool:Release(self)
end

function baseFrame.baseProto:Wipe()
    self.frame:Hide()
    self.frame:SetParent(nil)
    self.frame:ClearAllPoints()
    self:CleanBaseData()
end

function baseFrame.baseProto:CleanBaseData()
    if self.child == nil then return end

    self.child:Wipe()
    self.child = nil
end

--#endregion

function baseFrame:OnInitialize()
    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end

    _G['DynamicArchipelago'].BaseFrame = self
end

---@param item BaseArchipelagoItem
function baseFrame:_DoReset(item)
    item:CleanBaseData()
end

---@return BaseArchipelagoItem
function baseFrame:_DoCreate()
    local i = setmetatable({}, { __index = baseFrame.baseProto })
    i.id = utils:GenerateId()
    i.child = nil

    local width = database:GetWidgetWidth()
    local iconWidth = width / 4

    -- Create the Frame
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetWidth(width)
    frame:SetHeight(128)
    frame:Hide()

    i.frame = frame

    local content = CreateFrame('Frame', nil, frame)
    content:SetPoint('TOPLEFT', padding, -padding)
    content:SetPoint('BOTTOMRIGHT', -padding, padding)

    local prog = CreateFrame('StatusBar', nil, content)
    prog:SetPoint('TOPLEFT', content, 'BOTTOMLEFT', 0, -2)
    prog:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', 0, 0)
    prog:SetColorFill(0.5, 0.5, 1.0)
    Mixin(prog, SmoothStatusBarMixin)

    ---@diagnostic disable-next-line: undefined-field
    prog:SetMinMaxSmoothedValue(0, 100)

    i.frame.progress = prog

    --#region Animations

    local inAnim = frame:CreateAnimationGroup()

    local fade = inAnim:CreateAnimation('Alpha')
    fade:SetDuration(0.5)
    fade:SetFromAlpha(0.0)
    fade:SetToAlpha(1.0)

    i.frame.animationIn = inAnim

    local outAnim = frame:CreateAnimationGroup()

    local fadeOut = outAnim:CreateAnimation('Alpha')
    fadeOut:SetDuration(0.25)
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.0)

    outAnim:SetScript('OnFinished', function()
        i.frame:Hide()
        events:SendMessage('DYNAMIC_ARCHIPELAGO_ITEM_TIMER_END', i)
    end)

    i.frame.animationOut = outAnim

    --#endregion

    local iconGroup = CreateFrame('Frame', nil, content)
    iconGroup:SetPoint('TOPLEFT', padding, -padding)
    iconGroup:SetPoint('BOTTOMRIGHT', content, 'BOTTOMLEFT', iconWidth - padding, padding)

    i.frame.icon = iconGroup

    local contentGroup = CreateFrame('Frame', nil, content)
    contentGroup:SetPoint('TOPLEFT', iconGroup, 'TOPRIGHT', padding, -padding)
    contentGroup:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -padding, padding)

    i.frame.content = contentGroup

    local header = contentGroup:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    header:SetPoint('TOPLEFT')
    header:SetText('HEADER')
    header:SetTextColor(0.5, 0.5, 1.0)

    i.frame.header = header

    return i
end

---@param visibilityTime number
---@return BaseArchipelagoItem
function baseFrame:Create(visibilityTime)
    ---@type BaseArchipelagoItem
    local i = self._pool:Acquire()
    C_Timer.NewTimer(visibilityTime, function()
        i.frame.animationOut:Play()
    end)

    i:SetProgressBar(visibilityTime)

    return i
end

baseFrame:Enable()
