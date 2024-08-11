---@diagnostic disable: undefined-field
local addon = LibStub('AceAddon-3.0'):GetAddon('DynamicArchipelago')
local Type = 'Item'

---@class ItemFrame: AceModule
local itemFrame = addon:NewModule('ItemFrame')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class PeninsulaBase: AceModule
local baseFrame = addon:GetModule('PeninsulaBase')

ITEM_EVENTS = {
    CHAT_MSG_LOOT = 1,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 2,
    CHAT_MSG_CURRENCY = 3,
    ENCOUNTER_LOOT_RECEIVED = 4
}

local ITEM_DEFAULT_HEIGHT = 50

--#region Types

---@class ItemData
---@field time integer
---@field id number
---@field stacks number
---@field name string
---@field icon string
---@field price number
---@field rarity number
---@field link string
---@field total number
---@field tertiary string
---@field sock string
---@field ilvl number
---@field isGear boolean
---@field pQuality string
---@field factionTotal? string
---@field isFaction? boolean
---@field isCurrency? boolean

---@class ItemContent : Frame
---@field itemType FontString
---@field message FontString

---@class ItemIcon : Frame
---@field texture Texture

---@class (exact) Item : DynamicArchipelagoItem
---@field content ItemContent
---@field icon ItemIcon
---@field data ItemData
itemFrame.itemProto = {}

---@type table<integer, BasePeninsula>
itemFrame.collection = {}

---#endregion

--#region Private Methods

local function GetDuration(type)
    local dur = 1 -- TODO: Make this configurable
    return dur
end

local function IsGear(type)
    return type == "Armor" or type == "Weapon"
end

---@param data ItemData
local function FormatMessage(data)
    local message = ''
    if data.stacks > 1 then
        message = tostring(data.stacks) .. 'x '
    end
    message = message .. data.link
    if data.total > 1 then
        local totalCount = tostring(data.total + data.stacks)
        message = message .. ' (' .. totalCount .. 'x)'
    end
    if data.factionTotal then
        message = message .. ' (' .. data.factionTotal .. ')'
    end
    return message
end

---@param itemStr string
---@param stacks number
---@return ItemData?
local function GetItemData(itemStr, stacks)
    local itemName, link, quality, level, minLevel, type, subType, stackCount,
    _, texture, price = C_Item.GetItemInfo(itemStr)

    if not link then return end

    local pQuality = string.match(link, ".*:Professions%-ChatIcon%-Quality%-Tier(%d):?.*")
    local isQuest = type == 'Quest'

    local realItemLevel = C_Item.GetDetailedItemLevelInfo(link)
    local itemStats = C_Item.GetItemStats(link)
    local itemId = C_Item.GetItemIDForItemInfo(itemStr)
    local isGear = IsGear(type)

    local sockText = " ";

    if itemStats then
        local socket = false

        if itemStats["EMPTY_SOCKET_META"] then
            for i = 1, itemStats["EMPTY_SOCKET_META"] do
                sockText = sockText .. "|T136257:0|t";
            end
            socket = true;
        end

        if itemStats["EMPTY_SOCKET_RED"] then
            for i = 1, itemStats["EMPTY_SOCKET_RED"] do
                sockText = sockText .. "|T136258:0|t";
            end
            socket = true;
        end

        if itemStats["EMPTY_SOCKET_YELLOW"] then
            for i = 1, itemStats["EMPTY_SOCKET_YELLOW"] do
                sockText = sockText .. "|T136259:0|t";
            end
            socket = true;
        end

        if itemStats["EMPTY_SOCKET_BLUE"] then
            for i = 1, itemStats["EMPTY_SOCKET_BLUE"] do
                sockText = sockText .. "|T136256:0|t";
            end
            socket = true;
        end

        if itemStats["EMPTY_SOCKET_PRISMATIC"] then
            for i = 1, itemStats["EMPTY_SOCKET_PRISMATIC"] do
                sockText = sockText .. "|T458977:0|t";
            end
            socket = true;
        end

        if socket then
            sockText = sockText .. "|cFFFF00FFSocket|r";
        end
    end

    local tertiary
    if itemStats["ITEM_MOD_CR_AVOIDANCE_SHORT"] then tertiary = " |cFF00FFFFAvoidance|r" end
    if itemStats["ITEM_MOD_CR_LIFESTEAL_SHORT"] then tertiary = " |cFF00FFFFLeech|r" end
    if itemStats["ITEM_MOD_CR_SPEED_SHORT"] then tertiary = " |cFF00FFFFSpeed|r" end
    if itemStats["ITEM_MOD_CR_STURDINESS_SHORT"] then tertiary = " |cFF00FFFFIndestructible|r" end

    local totalCount = C_Item.GetItemCount(link)

    ---@type ItemData
    local newItem = {
        time = GetTime(),
        id = itemId,
        stacks = stacks,
        name = itemName,
        icon = texture,
        price = price,
        rarity = quality,
        link = link,
        tertiary = tertiary or nil,
        sock = (sockText ~= " ") and sockText or nil,
        ilvl = realItemLevel or nil,
        isGear = isGear or false,
        pQuality = (pQuality and CreateAtlasMarkup('professions-icon-quality-tier' .. pQuality .. '-inv', 32, 32)) or nil,
        total = totalCount
    }

    return newItem
end

---@param ... any
---@return ItemData?
local function CHAT_MSG_CURRENCY(...)
    local itemStr = select(2, ...)

    if itemStr == nil then
        return
    end

    local itemLink, count = string.match(itemStr, "(|c.+|r) ?x?(%d*).?")
    if count == nil then
        return
    end

    local info = C_CurrencyInfo.GetCurrencyInfoFromLink(itemLink)

    local itemIcon = info.iconFileID
    local text = info.name
    if itemIcon and tonumber(count) ~= 0 then
        -- Item Format

        ---@type ItemData
        local newItem = {
            id = info.currencyID,
            time = GetTime(),
            stacks = tonumber(count),
            name = info.name,
            icon = info.iconFileID,
            price = 0,
            rarity = 6,
            link = itemLink,
            total = info.quantity,
            isCurrency = true
        }

        return newItem
    end
end

---@param ... any
---@return ItemData?
local function CHAT_MSG_LOOT(...)
    local itemStr = select(2, ...)
    local player = select(3, ...)

    local name = UnitName('player')
    local server = GetNormalizedRealmName()
    local playerName = name .. '-' .. server

    if player ~= playerName then return end

    itemStr = itemStr:sub(itemStr:find(':') + 2, itemStr:len())
    local stacks = string.match(itemStr, ".*x(%d*)(%.?)$")
    local itemStacks = tonumber(stacks) or 1

    return GetItemData(itemStr, itemStacks)
end

---@param ... any
---@return ItemData?
local function ENCOUNTER_LOOT_RECEIVED(...)
    local _, itemID, text, itemStacks, playerName = ...
    if not text then return end
    if playerName ~= GetUnitName('player') then return end
    return GetItemData(text, itemStacks)
end

---@param ... any
---@return ItemData?
local function CHAT_MSG_COMBAT_FACTION_CHANGE(...)
    local text = select(2, ...)
    if not text then return end

    local faction = string.match(text, ".*with ([%a %-',%(%)%d:]+) increased by.*") or
        string.match(text, ".*with ([%a %-',%(%)%d:]+) decreased by.*") or ""
    local stacks = tonumber(string.match(text, ".*increased by (%d+)%.?")) or
        (tonumber(string.match(text, ".*decreased by (%d+)%.?")) * -1) or 0

    local id = 0
    local factionTotal = ''
    for factionIndex = 1, C_Reputation.GetNumFactions() do
        local factionData = C_Reputation.GetFactionDataByIndex(factionIndex)
        if factionData == nil then break end
        if factionData.name == faction then
            id = factionData.factionID
            factionTotal = factionData.currentStanding .. ' / ' .. factionData.nextReactionThreshold
            break
        end
    end

    return {
        time = GetTime(),
        id = id,
        stacks = stacks,
        name = faction,
        icon = 236681,
        price = 0,
        rarity = 7,
        link = faction,
        total = 0,
        factionTotal = factionTotal,
        isFaction = true
    }
end

--#endregion


---@param iconId string
function itemFrame.itemProto:SetIcon(iconId)
    self.icon.texture:SetTexture(iconId)
end

---@param label string
function itemFrame.itemProto:SetIconLabel(label)
    self.icon.label:SetText(label)
end

function itemFrame.itemProto:SetItemType()
    self.content.itemType:SetText('')
end

---@param message string
function itemFrame.itemProto:SetMessage(message)
    self.content.message:SetText(message)
end

function itemFrame.itemProto:Release()
    itemFrame._pool:Release(self)
end

function itemFrame.itemProto:Wipe()
    self.content:Hide()
    self.content:SetParent(nil)
    self.content:ClearAllPoints()

    self.icon:Hide()
    self.icon:SetParent(nil)
    self.icon:ClearAllPoints()

    self:CleanChatData()
end

function itemFrame.itemProto:CleanChatData()
    -- TODO: Clear out content / icon data
end

function itemFrame:OnInitialize()
    -- Register Events
    events:RegisterEvent('CHAT_MSG_LOOT', function(...)
        self:OnEvent(ITEM_EVENTS.CHAT_MSG_LOOT, ...)
    end)
    events:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE', function(...)
        self:OnEvent(ITEM_EVENTS.CHAT_MSG_COMBAT_FACTION_CHANGE, ...)
    end)
    events:RegisterEvent('CHAT_MSG_CURRENCY', function(...)
        self:OnEvent(ITEM_EVENTS.CHAT_MSG_CURRENCY, ...)
    end)
    events:RegisterEvent('ENCOUNTER_LOOT_RECEIVED', function(...)
        self:OnEvent(ITEM_EVENTS.ENCOUNTER_LOOT_RECEIVED, ...)
    end)

    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end

    self.collection = {}
end

---@param item ChatItem
function itemFrame:_DoReset(item)
    item:CleanChatData()
end

---@return Item
function itemFrame:_DoCreate()
    ---@type Item
    local i = setmetatable({}, { __index = itemFrame.itemProto })

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

    local message = contentFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
    message:SetText('MESSAGE')
    message:SetWordWrap(true)
    message:SetJustifyH('LEFT')
    message:SetJustifyV('TOP')
    message:SetPoint('TOPLEFT')
    message:SetPoint('BOTTOMRIGHT')

    i.content = contentFrame
    i.content.message = message

    i.icon = iconFrame
    i.icon.texture = iconTex

    return i
end

---@return Item
function itemFrame:Create()
    return self._pool:Acquire()
end

---@param eventType integer
---@param ... any
function itemFrame:OnEvent(eventType, ...)
    local itemData = nil
    if eventType == ITEM_EVENTS.CHAT_MSG_CURRENCY then
        itemData = CHAT_MSG_CURRENCY(...)
    elseif eventType == ITEM_EVENTS.CHAT_MSG_LOOT then
        itemData = CHAT_MSG_LOOT(...)
    elseif eventType == ITEM_EVENTS.ENCOUNTER_LOOT_RECEIVED then
        itemData = ENCOUNTER_LOOT_RECEIVED(...)
    elseif eventType == ITEM_EVENTS.CHAT_MSG_COMBAT_FACTION_CHANGE then
        itemData = CHAT_MSG_COMBAT_FACTION_CHANGE(...)
    elseif eventType == 99 then -- Debug
        itemData = GetItemData('item:6948', 1)
    end

    if itemData == nil then return end

    local time = GetTime()

    -- Does this exist? If so, extend and break
    if self.collection[itemData.id] then
        local widget = self.collection[itemData.id]

        if itemData.total == widget.data.total and not itemData.isFaction == true then
            return
        end

        widget.data.time = time
        widget.data.stacks = widget.data.stacks + itemData.stacks
        widget.data.total = itemData.total

        if itemData.factionTotal and itemData.isFaction == true then
            widget.data.factionTotal = itemData.factionTotal
        end

        itemData.total = itemData.total - itemData.stacks
        itemData.stacks = widget.data.stacks

        widget:UpdateDuration(database:GetVisibilityTimeByType(Type))
        widget.child:SetMessage(FormatMessage(itemData))
        return
    end

    local viewTime = eventType == 99 and 60 or database:GetVisibilityTimeByType(Type)
    local widget = baseFrame:Create(viewTime)

    local type = itemData.isFaction == true and 'Reputation' or itemData.isCurrency == true and 'Currency' or Type
    widget:SetType(type)

    -- print('Stacks:', itemData.stacks) -- Count Received
    -- print('Name:', itemData.name)
    -- print('Icon:', itemData.icon)
    -- print('Price:', itemData.price) -- Sell Price
    -- print('Rarity:', itemData.rarity)
    -- print('Link:', itemData.link)
    -- print('Total:', itemData.total) -- How many in bags
    -- print('Tertiary:', itemData.tertiary)
    -- print('Sock:', itemData.sock)
    -- print('ilvl:', itemData.ilvl)
    -- print('isGear:', itemData.isGear)
    -- print('pQuality:', itemData.pQuality)

    local item = itemFrame:Create()
    item:SetIcon(itemData.icon)

    item:SetMessage(FormatMessage(itemData))

    widget:SetIcon(item.icon)
    widget:SetContent(item.content)
    widget:SetOnFinished(function()
        self.collection[itemData.id] = nil
    end)

    widget:SetChild(item)

    -- height
    local height = widget:GetHeaderHeight()
    height = height + item.content.message:GetHeight()
    -- height = height + item.content.itemType:GetHeight()

    widget.height = max(ITEM_DEFAULT_HEIGHT, height)

    item.content:Show()
    item.icon:Show()

    widget.data = {
        time = time,
        link = itemData.link,
        name = itemData.name,
        type = eventType,
        id = itemData.id,
        stacks = itemData.stacks,
        total = itemData.total,
        tertiary = itemData.tertiary,
        sock = itemData.sock,
        ilvl = itemData.ilvl,
        isGear = itemData.isGear,
        pQuality = itemData.pQuality,
    }

    self.collection[itemData.id] = widget

    events:SendMessage('DYNAMIC_ARCHIPELAGO_ADD_CORE_ITEM', widget)
end

itemFrame:Enable()
