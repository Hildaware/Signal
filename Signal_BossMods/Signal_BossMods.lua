---@diagnostic disable: undefined-field

---@class Signal: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon('Signal')
local Type = 'Boss Mods'
local Module = 'BossMods'

---@class DBM
---@field RegisterCallback fun(self, event: string, callback: function)
local dbm = _G['DBM']

---@class BigWigs
---@field RegisterMessage fun(self, event: string, callback:function)
local bigWigs = _G['BigWigsLoader']

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

---@class BossMods: NotificationType
local bossMods = widgetBase:New(Module, Type)

local ITEM_DEFAULT_HEIGHT = 50

local MOD_TYPE = {
    DBM = 1,
    BigWigs = 2
}

---@class (exact) BossMod : SignalItem
---@field content ItemContent
---@field icon ItemIcon
---@field data ItemData
bossMods.itemProto = {}

function bossMods.itemProto:Wipe()
    self.icon:Hide()
    self.icon:SetParent(nil)
    self.icon:ClearAllPoints()

    self.content:Hide()
    self.content:SetParent(nil)
    self.content:ClearAllPoints()
end

function bossMods:OnInitialize()
    self:RegisterPool(self._DoCreate, self._DoReset)

    if dbm ~= nil then
        dbm:RegisterCallback('DBM_Announce',
            function(...) self:OnEvent(MOD_TYPE.DBM, ...) end)
    end

    if bigWigs ~= nil then
        bigWigs.RegisterMessage(self, 'BigWigs_Message',
            function(...) self:OnEvent(MOD_TYPE.BigWigs, ...) end)
    end

    if _G['DBMWarning'] ~= nil then
        _G['DBMWarning']:Hide()
    end

    if _G['DBMSpecialWarning'] ~= nil then
        _G['DBMSpecialWarning']:Hide()
    end
    -- TODO: Options
end

function bossMods:OnEvent(eventType, ...)
    local messageText, iconTexture = nil, nil
    if eventType == MOD_TYPE.DBM then
        local _, message, icon, _, _, _, _ = ...
        messageText = message
        iconTexture = icon
    else
        local _, _, _, text, _, icon = ...
        messageText = text
        iconTexture = icon
    end

    if messageText == nil or iconTexture == nil then return end

    local viewTime = 5
    local widget = baseFrame:Create(viewTime)
    widget:SetType(Type)

    ---@type BossMod
    local frame = self:Create()
    frame.icon.texture:SetTexture(iconTexture)
    frame.content.message:SetText(messageText)

    widget:SetIcon(frame.icon)
    widget:SetContent(frame.content)
    widget:SetChild(frame)

    local height = widget:GetHeaderHeight()
    height = height + frame.content.message:GetHeight()

    widget.height = max(ITEM_DEFAULT_HEIGHT, height)

    frame.content:Show()
    frame.icon:Show()

    events:SendMessage('SIGNAL_ADD_CORE_ITEM', widget)
end

---@return BossMod
function bossMods:_DoCreate()
    local i = setmetatable({}, { __index = bossMods.itemProto })

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

    local message = contentFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
    message:SetText('MESSAGE')
    message:SetWordWrap(true)
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

function bossMods:_DoReset()
    -- TODO
end

bossMods:Enable()
