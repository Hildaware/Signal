local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class PeninsulaBase: AceModule
local penBase = addon:NewModule('PeninsulaBase')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class BasePeninsula
penBase.baseProto = {}

local padding = 4

--#region Base Item Methods

function penBase.baseProto:WithoutIcon()
    self.frame.icon:SetPoint('BOTTOMRIGHT', self.frame.container, 'BOTTOMLEFT', 0, 0)
end

---@return number
function penBase.baseProto:GetWidgetWidth()
    return database:GetWidgetWidth()
end

---@return number
function penBase.baseProto:GetIconWidth()
    return database:GetWidgetWidth() / 4
end

---@param width number
function penBase.baseProto:SetIconWidth(width)
    self.frame.icon:SetWidth(width)
end

---@return number
function penBase.baseProto:GetHeaderHeight()
    return self.frame.header:GetHeight()
end

---@param str string
function penBase.baseProto:SetHeader(str)
    self.frame.header:SetText(str)
end

---@param style PeninsulaStyle
function penBase.baseProto:SetStyle(style)
    local iconWidth = database:GetWidgetWidth() / 4
    self.frame.icon:ClearAllPoints()
    self.frame.content:ClearAllPoints()

    if style == PENINSULA_STYLE.HORIZONTAL then
        self.frame.icon:SetPoint('TOPLEFT', padding, -padding)
        self.frame.icon:SetPoint('BOTTOMRIGHT', self.frame.container, 'BOTTOMLEFT', iconWidth + padding, padding)

        self.frame.content:SetPoint('TOPLEFT', self.frame.icon, 'TOPRIGHT', padding, 0)
        self.frame.content:SetPoint('BOTTOMRIGHT', self.frame.container, 'BOTTOMRIGHT', -padding, padding)
    else
        self.frame.icon:SetPoint('TOPLEFT', padding, -padding)
        self.frame.icon:SetPoint('BOTTOMRIGHT', self.frame.container, 'TOPRIGHT', -padding, -(iconWidth + padding))

        self.frame.content:SetPoint('TOPLEFT', self.frame.icon, 'BOTTOMLEFT', 0, -padding)
        self.frame.content:SetPoint('BOTTOMRIGHT', self.frame.container, 'BOTTOMRIGHT', -padding, padding)
    end
end

---@param str string
function penBase.baseProto:SetType(str)
    self.frame.header:SetText(str .. ' - Just Now')
end

---@param content Frame
function penBase.baseProto:SetContent(content)
    content:SetParent(self.frame.content)
    content:ClearAllPoints()
    content:SetPoint('TOPLEFT', self.frame.header, 'BOTTOMLEFT')
    content:SetPoint('BOTTOMRIGHT')
end

---@param widget SignalItem
function penBase.baseProto:SetChild(widget)
    self.child = widget
end

---@param icon Frame
function penBase.baseProto:SetIcon(icon)
    self.frame.icon:SetPoint('BOTTOMRIGHT', self.frame.container, 'BOTTOMLEFT', icon:GetWidth() + padding, padding)
    icon:SetParent(self.frame.icon)
    icon:ClearAllPoints()
    icon:SetPoint('CENTER', self.frame.icon, 'CENTER')
end

---@param visibilityTime number
function penBase.baseProto:SetProgressBar(visibilityTime)
    local duration = visibilityTime
    local progressBar = self.frame.progress
    ---@diagnostic disable-next-line: undefined-field
    progressBar:SetMinMaxSmoothedValue(0, visibilityTime)

    progressBar:SetScript('OnUpdate', function(bar, elapsed)
        duration = duration - elapsed
        bar:SetSmoothedValue(duration)
    end)
end

---@param callback function
function penBase.baseProto:SetOnFinished(callback)
    self.frame.animationOut:HookScript('OnFinished', function()
        callback()
    end)
end

---@param visibilityItem number
function penBase.baseProto:UpdateDuration(visibilityItem)
    if self.timer then
        self.timer:Cancel()
    end
    self.timer = C_Timer.NewTimer(visibilityItem, function()
        self.frame.animationOut:Play()
    end)

    self:SetProgressBar(visibilityItem)
end

function penBase.baseProto:UpdateHeight()
    self.frame:SetHeight(self.height)
end

function penBase.baseProto:GetHeight()
    return self.frame:GetHeight()
end

function penBase.baseProto:Release()
    penBase._pool:Release(self)
end

function penBase.baseProto:Wipe()
    self.frame:Hide()
    self.frame:SetParent(nil)
    self.frame:ClearAllPoints()
    self:CleanBaseData()
end

function penBase.baseProto:CleanBaseData()
    if self.child == nil then return end

    self.child:Wipe()
    self.child = nil
end

--#endregion

function penBase:OnInitialize()
    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end

    -- _G['Signal'].BaseFrame = self
end

---@param item BasePeninsula
function penBase:_DoReset(item)
    item:CleanBaseData()
end

---@return BasePeninsula
function penBase:_DoCreate()
    local i = setmetatable({}, { __index = penBase.baseProto })
    i.id = utils:GenerateId()
    i.child = nil

    local width = database:GetWidgetWidth()
    local iconWidth = width / 4 -- TODO: dynamic?

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

    i.frame.container = content

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

    local scale = inAnim:CreateAnimation('Scale')
    scale:SetDuration(0.5)
    scale:SetScaleFrom(1.0, 0.0)
    scale:SetScaleTo(1.0, 1.0)

    i.frame.animationIn = inAnim

    local outAnim = frame:CreateAnimationGroup()

    local fadeOut = outAnim:CreateAnimation('Alpha')
    fadeOut:SetDuration(0.25)
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.0)

    outAnim:SetScript('OnFinished', function()
        i.frame:Hide()
        events:SendMessage('SIGNAL_ITEM_TIMER_END', i)
    end)

    i.frame.animationOut = outAnim

    --#endregion

    local iconGroup = CreateFrame('Frame', nil, content)
    iconGroup:SetPoint('TOPLEFT', padding, -padding)
    iconGroup:SetPoint('BOTTOMRIGHT', content, 'BOTTOMLEFT', iconWidth + padding, padding)

    i.frame.icon = iconGroup

    local contentGroup = CreateFrame('Frame', nil, content)
    contentGroup:SetPoint('TOPLEFT', iconGroup, 'TOPRIGHT', padding, 0)
    contentGroup:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -padding, padding)

    i.frame.content = contentGroup

    local header = contentGroup:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    header:SetPoint('TOPLEFT')
    header:SetJustifyV('TOP')
    header:SetTextColor(0.5, 0.5, 1.0)

    i.frame.header = header

    return i
end

---@param visibilityTime number
---@return BasePeninsula
function penBase:Create(visibilityTime)
    ---@type BasePeninsula
    local i = self._pool:Acquire()
    i.timer = C_Timer.NewTimer(visibilityTime, function()
        i.frame.animationOut:Play()
    end)

    i:SetProgressBar(visibilityTime)

    return i
end

penBase:Enable()
