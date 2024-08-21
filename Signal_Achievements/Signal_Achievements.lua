---@diagnostic disable: undefined-field

---@class Signal: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon('Signal')
local Type = 'Achievement'
local Module = 'Achievements'

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Options: AceModule
local options = addon:GetModule('Options')

---@class PeninsulaBase: AceModule
local baseFrame = addon:GetModule('PeninsulaBase')

---@class NotificationWidgetBase: AceModule
local widgetBase = addon:GetModule('NotificationWidget')

---@class Achievements: NotificationType
local achievements = widgetBase:New(Module, Type)

local ITEM_DEFAULT_HEIGHT = 50

---@class (exact) Achievement : SignalItem
---@field content ItemContent
---@field icon ItemIcon
---@field data ItemData
achievements.itemProto = {}

function achievements.itemProto:Wipe()
    self.icon:Hide()
    self.icon:SetParent(nil)
    self.icon:ClearAllPoints()

    self.content:Hide()
    self.content:SetParent(nil)
    self.content:ClearAllPoints()
end

function achievements:OnInitialize()
    self:RegisterPool(self._DoCreate, self._DoReset)

    events:RegisterEvent('ACHIEVEMENT_EARNED', function(...) self:OnEvent(...) end)
end

function achievements:OnEvent(_, ...)
    local id = ...
    if id == nil then return end

    local _, name, _, _, _, _, _, _, _, icon, rewardText, _ = GetAchievementInfo(id)

    local viewTime = 10
    local widget = baseFrame:Create(viewTime)
    widget:SetType(Type)

    ---@type BossMod
    local frame = self:Create()
    frame.icon.texture:SetTexture(icon)

    frame.content.message:SetText(name)

    local hasReward = false
    if rewardText ~= nil and rewardText ~= '' then
        frame.content.message:ClearPoint('BOTTOMRIGHT')

        local subMessage = frame.content:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalTiny')
        subMessage:SetTextColor(CreateColorFromRGBHexString('1086C9'):GetRGB())
        subMessage:SetJustifyH('LEFT')
        subMessage:SetJustifyV('BOTTOM')
        subMessage:SetPoint('TOPLEFT', message, 'BOTTOMLEFT')
        subMessage:SetPoint('BOTTOMRIGHT', frame.content, 'BOTTOMRIGHT')
        subMessage:SetText(rewardText)

        hasReward = true
    end

    widget:SetIcon(frame.icon)
    widget:SetContent(frame.content)
    widget:SetChild(frame)

    local height = widget:GetHeaderHeight()
    height = height + frame.content.message:GetHeight() + (hasReward and 28 or 0)

    widget.height = max(ITEM_DEFAULT_HEIGHT, height)

    frame.content:Show()
    frame.icon:Show()

    events:SendMessage('SIGNAL_ADD_CORE_ITEM', widget)
end

---@return Achievement
function achievements:_DoCreate()
    local i = setmetatable({}, { __index = achievements.itemProto })

    local baseWidth = baseFrame.baseProto:GetWidgetWidth()

    local iconFrame = CreateFrame('Frame', nil, UIParent)
    iconFrame:SetWidth(ITEM_DEFAULT_HEIGHT - 16)
    iconFrame:SetHeight(ITEM_DEFAULT_HEIGHT - 16)
    iconFrame:Hide()

    local iconTex = iconFrame:CreateTexture(nil, 'BACKGROUND')
    iconTex:SetAllPoints(iconFrame)

    local contentFrame = CreateFrame('Frame', nil, UIParent)
    contentFrame:SetWidth(baseWidth - (ITEM_DEFAULT_HEIGHT - 16))
    contentFrame:SetHeight(ITEM_DEFAULT_HEIGHT)
    contentFrame:Hide()

    contentFrame:SetScript('OnMouseDown', function()
        _G['AchievementFrame']:Show()
    end)

    local message = contentFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
    message:SetText('MESSAGE')
    message:SetTextColor(1.0, 1.0, 1.0, 1.0)
    message:SetJustifyH('LEFT')
    message:SetJustifyV('MIDDLE')
    message:SetPoint('TOPLEFT')
    message:SetPoint('BOTTOMRIGHT')

    i.content = contentFrame
    i.content.message = message

    i.icon = iconFrame
    i.icon.texture = iconTex

    return i
end

function achievements:_DoReset()
    -- TODO
end

achievements:Enable()
