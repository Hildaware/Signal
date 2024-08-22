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

--#region Database

---@param val number
function database:SetBossModsDuration(val)
    database.internal.global.BossMods.Duration = val
end

---@return number
function database:GetBossModsDuration()
    return database.internal.global.BossMods.Duration
end

---@param value boolean
function database:SetBossModsState(value)
    database.internal.global.BossMods.Enabled = value
end

function database:GetBossModsState()
    return database.internal.global.BossMods.Enabled
end

function database:GetDBMDisableWarningFrame()
    return database.internal.global.BossMods.DisableDBMWarnings
end

---@param value boolean
function database:SetDBMDisableWarningFrame(value)
    database.internal.global.BossMods.DisableDBMWarnings = value
    bossMods:RefreshOptions()
end

function database:GetDBMDisableSpecialWarningFrame()
    return database.internal.global.BossMods.DisableDBMSpecialWarnings
end

---@param value boolean
function database:SetDBMDisableSpecialWarningFrame(value)
    database.internal.global.BossMods.DisableDBMSpecialWarnings = value
    bossMods:RefreshOptions()
end

--#endregion

function bossMods:InitializeOptions()
    ---@type AceConfig.OptionsTable
    local bossModsOptions = {
        name = 'Boss Mods',
        type = 'group',
        order = 4,
        args = {
            enable = {
                order = 1,
                name = 'Enable',
                type = 'toggle',
                get = function() return database:GetBossModsState() end,
                set = function(_, val) database:SetBossModsState(val) end
            },
            duration = {
                order = 2,
                name = 'Duration',
                type = 'range',
                min = 0,
                max = 30,
                get = function() return database:GetBossModsDuration() end,
                set = function(_, val) database:SetBossModsDuration(val) end
            },
            dbmHeader = {
                order = 3,
                name = 'Deadly Boss Mods',
                type = 'header',
            },
            dbmInfo = {
                order = 4,
                name = 'Options specific to DBM Notifications',
                type = 'description',
            },
            disableDbmWarnings = {
                order = 5,
                name = 'Disable Default Warnings',
                desc = 'Removes the default DBM Warnings Popup frame. Tnis cannot be disabled through DBM itself.',
                type = 'toggle',
                get = function() return database:GetDBMDisableWarningFrame() end,
                set = function(_, val) database:SetDBMDisableWarningFrame(val) end
            },
            disableDbmSpecialWarnings = {
                order = 6,
                name = 'Disable Default Specials',
                desc =
                'Removes the default DBM Special Warnings Popup frame. Tnis cannot be disabled through DBM itself.',
                type = 'toggle',
                get = function() return database:GetDBMDisableSpecialWarningFrame() end,
                set = function(_, val) database:SetDBMDisableSpecialWarningFrame(val) end
            },
        }
    }

    options:AddSettings('bossModsOptions', bossModsOptions)
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

    self:InitializeOptions()

    if database.internal.global.BossMods == nil then
        database.internal.global.BossMods = {
            Enabled = true,
            Duration = 5,
            DisableDBMWarnings = true,
            DisableDBMSpecialWarnings = true
        }
    end

    self:RefreshOptions()
end

function bossMods:OnEvent(eventType, ...)
    if not database:GetBossModsState() then return end

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

    local widget = baseFrame:Create(database:GetBossModsDuration())
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

function bossMods:RefreshOptions()
    if dbm == nil then return end

    if database:GetDBMDisableWarningFrame() then
        _G['DBMWarning']:Hide()
    else
        _G['DBMWarning']:Show()
    end

    if database:GetDBMDisableSpecialWarningFrame() then
        _G['DBMSpecialWarning']:Hide()
    else
        _G['DBMSpecialWarning']:Show()
    end
end

bossMods:Enable()
