---@diagnostic disable: undefined-field
local addon = LibStub('AceAddon-3.0'):GetAddon('Signal')
local gInspect = LibStub("LibGroupInSpecT-1.1")
local Type = 'Chat'

---@class ChatFrame: AceModule
local chatFrame = addon:NewModule('ChatFrame')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class PeninsulaBase: AceModule
local baseFrame = addon:GetModule('PeninsulaBase')

local CHAT_TYPE = {
    WHISPER = 1,
    PARTY = 2,
    INSTANCE = 3,
    RAID = 4,
    BNET = 5,
}

local MESSAGE_EVENTS = {
    ['CHAT_MSG_WHISPER'] = CHAT_TYPE.WHISPER,
    ['CHAT_MSG_BN_WHISPER'] = CHAT_TYPE.BNET,
    ['CHAT_MSG_PARTY_LEADER'] = CHAT_TYPE.PARTY,
    ['CHAT_MSG_PARTY'] = CHAT_TYPE.PARTY,
    ['CHAT_MSG_INSTANCE_CHAT_LEADER'] = CHAT_TYPE.INSTANCE,
    ['CHAT_MSG_INSTANCE_CHAT'] = CHAT_TYPE.INSTANCE,
    ['CHAT_MSG_RAID'] = CHAT_TYPE.RAID,
    ['CHAT_MSG_RAID_LEADER'] = CHAT_TYPE.RAID,
    ['CHAT_MSG_RAID_WARNING'] = CHAT_TYPE.RAID,
}

local ITEM_DEFAULT_HEIGHT = 90

--#region Types

---@class ChatData
---@field time integer
---@field playerId string
---@field name string
---@field class string
---@field type string
---@field message string

---@class ChatContent : Frame
---@field chatType FontString
---@field message FontString

---@class ChatIcon : Frame
---@field texture Texture
---@field label FontString

---@class (exact) ChatItem : SignalItem
---@field container Frame
---@field content ChatContent
---@field icon ChatIcon
---@field SetPortrait function
---@field SetIconLabel function
---@field SetChatType function
---@field SetMessage function
---@field data ChatData
chatFrame.chatProto = {}

---#endregion

---@param chatType string
local function GetChatTypeColored(chatType)
    if chatType == CHAT_TYPE.WHISPER then
        return '|cffDA70D6WHISPER|r'
    end
    if chatType == CHAT_TYPE.PARTY then
        return '|cff00ccffPARTY|r'
    end
    if chatType == CHAT_TYPE.INSTANCE then
        return '|cffFF4500INSTANCE|r'
    end
    if chatType == CHAT_TYPE.RAID then
        return '|cffff6060RAID|r'
    end
    if chatType == CHAT_TYPE.BNET then
        return '|cff00AEFFBNET|r'
    end

    return 'CHANNEL'
end

---@param playerId string
---@param class string
function chatFrame.chatProto:SetPortrait(playerId, class)
    local unitId = gInspect:GuidToUnit(playerId)
    if unitId then
        SetPortraitTexture(self.icon.texture, unitId, false)
    else
        local classAtlas = GetClassAtlas(class)
        local texture = ("Interface\\ICONS\\ClassIcon_" .. class)
        if classAtlas then
            self.icon.texture:SetAtlas(classAtlas)
        else
            self.icon.texture:SetTexture(texture)
        end
    end
end

---@param label string
function chatFrame.chatProto:SetIconLabel(label)
    self.icon.label:SetText(label)
end

---@param chatType string
function chatFrame.chatProto:SetChatType(chatType)
    self.content.chatType:SetText(GetChatTypeColored(chatType))
end

---@param message string
function chatFrame.chatProto:SetMessage(message)
    self.content.message:SetText(message)
end

function chatFrame.chatProto:Release()
    chatFrame._pool:Release(self)
end

function chatFrame.chatProto:Wipe()
    self.content:Hide()
    self.content:SetParent(nil)
    self.content:ClearAllPoints()

    self.icon:Hide()
    self.icon:SetParent(nil)
    self.icon:ClearAllPoints()

    self:CleanChatData()
end

function chatFrame.chatProto:CleanChatData()
    -- TODO: Clear out content / icon data
end

function chatFrame:OnInitialize()
    for event, chatType in pairs(MESSAGE_EVENTS) do
        events:RegisterEvent(event, function(...)
            self:OnEvent(chatType, ...)
        end)
    end

    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end
end

---@param item ChatItem
function chatFrame:_DoReset(item)
    item:CleanChatData()
end

---@return ChatItem
function chatFrame:_DoCreate()
    local i = setmetatable({}, { __index = chatFrame.chatProto })

    local baseWidth = baseFrame.baseProto:GetWidgetWidth()
    local actualWidth = baseWidth - 32

    local container = CreateFrame('Frame', nil, UIParent)
    container:SetWidth(actualWidth)
    container:SetHeight(ITEM_DEFAULT_HEIGHT)

    local chatType = container:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
    chatType:SetText('CHAT TYPE')
    chatType:SetPoint('TOPLEFT')

    local iconFrame = CreateFrame('Frame', nil, container)
    iconFrame:SetPoint('TOPLEFT', chatType, 'BOTTOMLEFT', 0, -4)
    iconFrame:SetWidth(actualWidth)
    iconFrame:SetHeight(40)
    iconFrame:Hide()

    local bgTex = iconFrame:CreateTexture()
    bgTex:SetPoint('TOPLEFT', iconFrame, 'TOPLEFT', 0, -2)
    bgTex:SetWidth(40)
    bgTex:SetHeight(40)
    bgTex:SetTexture(utils:GetMediaDir() .. 'Art\\box')
    bgTex:SetVertexColor(0, 0, 0, 0.65)

    local iconTex = iconFrame:CreateTexture()
    iconTex:SetPoint('TOPLEFT', bgTex, 'TOPLEFT', 2, -2)
    iconTex:SetPoint('BOTTOMRIGHT', bgTex, 'BOTTOMRIGHT', -2, 2)

    local iconLabel = iconFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
    iconLabel:SetText('Player Name')
    iconLabel:SetJustifyH('CENTER')
    iconLabel:SetPoint('LEFT', iconTex, 'RIGHT', 4, 0)

    local contentFrame = CreateFrame('Frame', nil, container)
    contentFrame:SetPoint('TOPLEFT', iconFrame, 'BOTTOMLEFT', 0, -4)
    contentFrame:SetWidth(actualWidth)
    contentFrame:SetHeight(ITEM_DEFAULT_HEIGHT)
    contentFrame:Hide()

    local message = contentFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
    message:SetText('MESSAGE.')
    message:SetTextColor(1.0, 1.0, 1.0, 1.0)
    message:SetWordWrap(true)
    message:SetJustifyH('LEFT')
    message:SetJustifyV('MIDDLE')
    message:SetAllPoints(contentFrame)
    message:SetHeight(400)

    -- utils:DebugFrame(iconFrame, { r = 1.0, g = 0.0, b = 0.0, a = 1.0 })
    -- utils:DebugFrame(contentFrame, { r = 0.0, g = 1.0, b = 0.0, a = 1.0 })

    i.container = container

    i.content = contentFrame
    i.content.chatType = chatType
    i.content.message = message

    i.icon = iconFrame
    i.icon.texture = iconTex
    i.icon.label = iconLabel

    return i
end

---@return ChatItem
function chatFrame:Create()
    return self._pool:Acquire()
end

function chatFrame:OnEvent(chatType, ...)
    local _, message, name, _, _, _, _, _, _, _, _, _, playerId = ...
    local time = GetTime()

    local playerClass = ''
    if chatType ~= CHAT_TYPE.BNET then
        if playerId == nil or playerId == UnitGUID('player') then return end
        local _, engClass, _, _, _, _, _ = GetPlayerInfoByGUID(playerId)
        if engClass == nil or engClass == '' then return end
        playerClass = engClass
    end

    local viewTime = max(string.len(message) * 0.10, 10)
    local widget = baseFrame:Create(viewTime)
    widget:WithoutIcon()
    widget:SetType(Type)

    local formattedName = '|c' .. (chatType ~= CHAT_TYPE.BNET and utils:GetClassColor(playerClass) or
        'FF00AEFF') .. name .. '|r'

    local chatItem = chatFrame:Create()

    if chatType == CHAT_TYPE.BNET then
        chatItem.icon.texture:SetAtlas('')   -- BNET atlas
        chatItem.icon.texture:SetTexture('') -- BNET icon
    else
        chatItem:SetPortrait(playerId, playerClass)
    end
    chatItem:SetIconLabel(formattedName)

    chatItem:SetChatType(chatType)
    chatItem:SetMessage(message)

    local lineHeight = chatItem.content.message:GetStringHeight()
    local charactersPerLine = 54
    local requiredLines = math.ceil(string.len(message) / charactersPerLine)
    local chatHeight = max(requiredLines * lineHeight, 45)

    chatItem.content:SetHeight(chatHeight)
    widget:SetContent(chatItem.container)

    local totalHeight = chatHeight + 100
    widget.height = max(ITEM_DEFAULT_HEIGHT, totalHeight)

    chatItem.content:Show()
    chatItem.icon:Show()

    widget.data = {
        time = time,
        playerId = playerId,
        name = name,
        class = playerClass,
        type = chatType,
        message = message,
    }

    events:SendMessage('SIGNAL_ADD_CORE_ITEM', widget)
end

chatFrame:Enable()
