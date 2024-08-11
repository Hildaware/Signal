---@diagnostic disable: undefined-field
local addon = LibStub('AceAddon-3.0'):GetAddon('DynamicArchipelago')
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

CHAT_TYPE = {
    WHISPER = 1,
    PARTY = 2,
    INSTANCE = 3,
    RAID = 4
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

---@class (exact) ChatItem : DynamicArchipelagoItem
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
        -- TODO: Class? That doesn't exist
        -- local texture = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
        -- local coords = CLASS_ICON_TCOORDS[class]
        -- self.icon.texture:SetTexture(texture)
        -- self.icon.texture:SetTexCoord(table.unpack(coords))
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
    -- Register Events
    events:RegisterEvent('CHAT_MSG_WHISPER', function(...)
        self:OnEvent(CHAT_TYPE.WHISPER, ...)
    end)
    events:RegisterEvent('CHAT_MSG_PARTY_LEADER', function(...)
        self:OnEvent(CHAT_TYPE.PARTY, ...)
    end)
    events:RegisterEvent('CHAT_MSG_PARTY', function(...)
        self:OnEvent(CHAT_TYPE.PARTY, ...)
    end)
    events:RegisterEvent('CHAT_MSG_INSTANCE_CHAT_LEADER', function(...)
        self:OnEvent(CHAT_TYPE.INSTANCE, ...)
    end)
    events:RegisterEvent('CHAT_MSG_INSTANCE_CHAT', function(...)
        self:OnEvent(CHAT_TYPE.INSTANCE, ...)
    end)
    events:RegisterEvent('CHAT_MSG_RAID', function(...)
        self:OnEvent(CHAT_TYPE.RAID, ...)
    end)
    events:RegisterEvent('CHAT_MSG_RAID_LEADER', function(...)
        self:OnEvent(CHAT_TYPE.RAID, ...)
    end)
    events:RegisterEvent('CHAT_MSG_RAID_WARNING', function(...)
        self:OnEvent(CHAT_TYPE.RAID, ...)
    end)

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

    local iconFrame = CreateFrame('Frame', nil, UIParent)
    iconFrame:SetWidth(ITEM_DEFAULT_HEIGHT - 12)
    iconFrame:SetHeight(ITEM_DEFAULT_HEIGHT - 12)
    iconFrame:Hide()

    local bgTex = iconFrame:CreateTexture()
    bgTex:SetPoint('TOP', iconFrame, 'TOP', 0, -2)
    bgTex:SetWidth(ITEM_DEFAULT_HEIGHT - 32)
    bgTex:SetHeight(ITEM_DEFAULT_HEIGHT - 32)
    bgTex:SetTexture(utils:GetMediaDir() .. 'Art\\box')
    bgTex:SetVertexColor(0, 0, 0, 0.65)

    local iconTex = iconFrame:CreateTexture()
    iconTex:SetPoint('TOPLEFT', bgTex, 'TOPLEFT', 2, -2)
    iconTex:SetPoint('BOTTOMRIGHT', bgTex, 'BOTTOMRIGHT', -2, 2)

    local iconLabel = iconFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalTiny')
    iconLabel:SetText('Player Name')
    iconLabel:SetJustifyH('CENTER')
    iconLabel:SetPoint('TOP', iconTex, 'BOTTOM', 0, -4)

    local contentFrame = CreateFrame('Frame', nil, UIParent)
    contentFrame:SetWidth(baseWidth - ITEM_DEFAULT_HEIGHT)
    contentFrame:SetHeight(ITEM_DEFAULT_HEIGHT)
    contentFrame:Hide()

    local chatType = contentFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
    chatType:SetText('CHAT TYPE')
    chatType:SetPoint('TOPLEFT')

    local message = contentFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
    message:SetText('MESSAGE.')
    message:SetWordWrap(true)
    message:SetJustifyH('LEFT')
    message:SetJustifyV('MIDDLE')
    message:SetPoint('TOPLEFT', chatType, 'BOTTOMLEFT')
    message:SetPoint('BOTTOMRIGHT')

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
    -- if playerId == nil or playerId == UnitGUID('player') then return end

    local locClass, engClass, locRace, engRace, gender, className, server = GetPlayerInfoByGUID(playerId)
    if engClass == nil or engClass == '' then return end

    local viewTime = string.len(message) * 0.10
    local widget = baseFrame:Create(viewTime)
    widget:SetType(Type)

    local formattedName = '|c' .. utils:GetClassColor(engClass) .. name .. '|r'

    local chatItem = chatFrame:Create()
    chatItem:SetPortrait(playerId, engClass)
    chatItem:SetIconLabel(string.sub(formattedName, 1, 24))

    chatItem:SetChatType(chatType)
    chatItem:SetMessage(message)

    widget:SetIcon(chatItem.icon)

    local chatHeight = max(string.len(message) * 1.1, ITEM_DEFAULT_HEIGHT)
    chatItem.content:SetHeight(chatHeight)
    widget:SetContent(chatItem.content)

    widget.height = max(ITEM_DEFAULT_HEIGHT, chatHeight)

    chatItem.content:Show()
    chatItem.icon:Show()

    widget.data = {
        time = time,
        playerId = playerId,
        name = name,
        class = engClass,
        type = chatType,
        message = message,
    }

    events:SendMessage('DYNAMIC_ARCHIPELAGO_ADD_CORE_ITEM', widget)
end

chatFrame:Enable()
