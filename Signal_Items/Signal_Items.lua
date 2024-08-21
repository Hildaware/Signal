---@diagnostic disable: undefined-field
local addon = LibStub('AceAddon-3.0'):GetAddon('Signal')
local Type = 'Item'

local Masque = LibStub('Masque', true)

---@class ItemFrame: AceModule
local itemFrame = addon:NewModule('ItemFrame')

---@class ItemUtils: AceModule
local itemUtils = addon:GetModule('ItemUtils')

---@class FrameHelpers: AceModule
local helpers = addon:GetModule('FrameHelpers')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Options: AceModule
local options = addon:GetModule('Options')

---@class PeninsulaBase: AceModule
local baseFrame = addon:GetModule('PeninsulaBase')

local ITEM_EVENTS = {
    CHAT_MSG_LOOT = 1,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 2,
    CHAT_MSG_CURRENCY = 3,
    ENCOUNTER_LOOT_RECEIVED = 4
}

local ITEM_DEFAULT_HEIGHT = 50

--#region Types

---@class (exact) Item : SignalItem
---@field content ItemContent
---@field icon ItemIcon
---@field data ItemData
itemFrame.itemProto = {}

---@class CompactItemContent : Frame
---@field children Frame[]

---@class (exact) ItemCompact : SignalItem
---@field content CompactItemContent
---@field data ItemData
itemFrame.compactItemProto = {}

---@type table<integer, BasePeninsula>
itemFrame.collection = {}

---@class ItemCompactData
---@field widget BasePeninsula?
---@field item ItemCompact?
itemFrame.compactData = {}

---#endregion

--#region CompactItem

---@param icon Frame
function itemFrame.compactItemProto:AddIcon(icon)
    local iconCount = #self.content.children
    local widgetWidth = database:GetWidgetWidth()
    local frameWidth = icon:GetWidth()
    local padding = 8
    local itemsPerRow = floor(widgetWidth / (frameWidth + padding))
    local row = floor(iconCount / itemsPerRow)

    icon:SetParent(self.content)

    local xPos = ((iconCount % itemsPerRow) * frameWidth) + (padding * (iconCount % itemsPerRow))
    local yPos = -(row * (frameWidth)) - (padding * row)

    icon:SetPoint('TOPLEFT', self.content, 'TOPLEFT', xPos, yPos)

    icon:Show()

    self.content.children[iconCount + 1] = icon
end

function itemFrame.compactItemProto:Wipe()
    for _, child in ipairs(self.content.children) do
        child:Hide()
        child:SetParent(nil)
        child:ClearAllPoints()
    end

    self.content:Hide()
    self.content:SetParent(nil)
    self.content:ClearAllPoints()
    self.content.children = {}

    self:CleanChatDataCompact()
end

function itemFrame.compactItemProto:CleanChatDataCompact()
    -- TODO
end

--#endregion

--#region Item

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

--#endregion

--#region Database

---@param value boolean
function database:SetCompactItems(value)
    database.internal.global.Items.Compact = value
end

---@return boolean
function database:GetCompactItemsMode()
    return database.internal.global.Items.Compact
end

---@param rarity Enum.ItemQuality
---@param val number
function database:SetDurationByRarity(rarity, val)
    database.internal.global.Items[rarity] = val
end

---@param rarity Enum.ItemQuality
---@return number
function database:GetDurationByRarity(rarity)
    return database.internal.global.Items[rarity]
end

function database:SetDisableAlertFrame(value)
    database.internal.global.Items.DisableAlertFrame = value

    if value then
        hooksecurefunc(AlertFrame, "RegisterEvent", function(_, event)
            AlertFrame:UnregisterEvent(event)
        end)
        AlertFrame:UnregisterAllEvents()
    end
end

function database:GetDisableAlertFrame()
    return database.internal.global.Items.DisableAlertFrame
end

--#endregion

function itemFrame:InitializeOptions()
    ---@param str string
    ---@param rarity Enum.ItemQuality
    ---@return AceConfig.OptionsTable
    local function RarityOptions(str, rarity)
        local config = {
            name = str,
            type = 'range',
            min = 0,
            max = 30,
            order = rarity + 5,
            get = function() return database:GetDurationByRarity(rarity) end,
            set = function(_, val) database:SetDurationByRarity(rarity, val) end
        }

        return config
    end

    --- Options
    ---@type AceConfig.OptionsTable
    local itemOptions = {
        name = 'Items',
        type = 'group',
        order = 2,
        args = {
            style = {
                name = 'Enable Compact Mode',
                desc = 'Enables a smaller version for item popups. This does not include Currency and Reputation.',
                type = 'toggle',
                order = 1,
                get = function() return database:GetCompactItemsMode() end,
                set = function(_, val) database:SetCompactItems(val) end
            },
            disableAlerts = {
                name = 'Disable Blizzard Alerts',
                desc = 'Removes the default Item Alerts that popup.',
                type = 'toggle',
                order = 2,
                get = function() return database:GetDisableAlertFrame() end,
                set = function(_, val) database:SetDisableAlertFrame(val) end
            },
            header = {
                name = 'Duration Settings',
                type = 'header',
                order = 3
            },
            info = {
                name = 'Set the duration based on Item Quality. 0 will disable the item from showing.',
                type = 'description',
                order = 4
            }
        }
    }

    itemOptions.args['Poor'] = RarityOptions('Poor', Enum.ItemQuality.Poor)

    for quality, rarity in pairs(Enum.ItemQuality) do
        if rarity == Enum.ItemQuality.WoWToken then break end
        itemOptions.args[tostring(quality)] = RarityOptions(tostring(quality), rarity)
    end

    options:AddSettings('itemOptions', itemOptions)
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

    self._compactPool = CreateObjectPool(self._DoCreateCompact, self._DoResetCompact)
    if self._compactPool.SetResetDisallowedIfNew then
        self._compactPool:SetResetDisallowedIfNew()
    end

    self.collection = {}

    self:InitializeOptions()

    -- Database Defaults
    if database.internal.global.Items == nil then
        database.internal.global.Items = {
            Compact = false,
            DisableAlertFrame = true,
            [Enum.ItemQuality.Poor] = 5,
            [Enum.ItemQuality.Common] = 5,
            [Enum.ItemQuality.Uncommon] = 8,
            [Enum.ItemQuality.Rare] = 11,
            [Enum.ItemQuality.Epic] = 14,
            [Enum.ItemQuality.Legendary] = 17,
            [Enum.ItemQuality.Artifact] = 20,
            [Enum.ItemQuality.Heirloom] = 23,
            [Enum.ItemQuality.Reputation] = 10,
            [Enum.ItemQuality.Currency] = 8
        }
    end

    if database.internal.global.Items.DisableAlertFrame then
        hooksecurefunc(AlertFrame, "RegisterEvent", function(_, event)
            AlertFrame:UnregisterEvent(event)
        end)
        AlertFrame:UnregisterAllEvents()
    end
end

---@param eventType integer
---@param ... any
function itemFrame:OnEvent(eventType, ...)
    local itemData = nil
    if eventType == ITEM_EVENTS.CHAT_MSG_CURRENCY then
        itemData = itemUtils:Parse_CHAT_MSG_CURRENCY(...)
    elseif eventType == ITEM_EVENTS.CHAT_MSG_LOOT then
        itemData = itemUtils:Parse_CHAT_MSG_LOOT(...)
    elseif eventType == ITEM_EVENTS.ENCOUNTER_LOOT_RECEIVED then
        itemData = itemUtils:Parse_ENCOUNTER_LOOT_RECEIVED(...)
    elseif eventType == ITEM_EVENTS.CHAT_MSG_COMBAT_FACTION_CHANGE then
        itemData = itemUtils:Parse_CHAT_MSG_COMBAT_FACTION_CHANGE(...)
    elseif eventType == 99 then -- Debug
        itemData = itemUtils:GetItemData(select(2, ...), 1)
    end

    if itemData == nil then return end

    local time = GetTime()

    local itemType = itemData.itemType

    local duration = database:GetDurationByRarity(itemData.rarity)
    if duration == 0 then return end

    -- Currency & Faction will always be full size
    if itemType == ItemType.Currency or itemType == ItemType.Faction or not database:GetCompactItemsMode() then
        -- If the item already exists, we want to extend the duraction
        if self.collection[itemData.id] then
            local widget = self.collection[itemData.id]

            if itemData.total == widget.data.total and not itemType == ItemType.Faction then
                return
            end

            widget.data.time = time
            widget.data.stacks = widget.data.stacks + itemData.stacks
            widget.data.total = itemData.total

            if itemData.itemType == ItemType.Faction and itemData.factionData ~= nil then
                widget.data.factionData = itemData.factionData
            end

            itemData.total = itemData.total - itemData.stacks
            itemData.stacks = widget.data.stacks

            widget:UpdateDuration(database:GetVisibilityTimeByType(Type)) -- TODO: TYPE
            widget.child:SetMessage(itemUtils:FormatItemString(itemData))

            return
        end

        -- Create a new Item
        local viewTime = eventType == 99 and 3 or database:GetDurationByRarity(itemData.rarity)
        local widget = baseFrame:Create(viewTime)

        local item = itemFrame:Create()
        item.icon = self:CreateIcon(itemData)

        if itemType == ItemType.Faction or itemType == ItemType.Currency then
            local type = itemType == ItemType.Faction and 'Reputation' or 'Currency'
            widget:SetType(type)
        end

        item:SetMessage(itemUtils:FormatItemString(itemData))

        widget:SetIcon(item.icon)
        widget:SetContent(item.content)
        widget:SetOnFinished(function()
            self.collection[itemData.id] = nil
        end)

        widget:SetChild(item)

        -- height
        local height = widget:GetHeaderHeight()
        height = height + item.content.message:GetHeight()

        widget.height = max(ITEM_DEFAULT_HEIGHT, height)

        item.content:Show()
        item.icon:Show()

        ---@type ItemData
        widget.data = {
            type = Type,
            time = time,
            rarity = itemData.rarity,
            icon = itemData.icon,
            link = itemData.link,
            name = itemData.name,
            itemType = itemType,
            id = itemData.id,
            stacks = itemData.stacks,
            total = itemData.total,
            tertiary = itemData.tertiary,
            sock = itemData.sock,
            ilvl = itemData.ilvl,
            isGear = itemData.isGear,
            pQuality = itemData.pQuality,
            factionData = itemData.factionData,
        }

        self.collection[itemData.id] = widget

        events:SendMessage('SIGNAL_ADD_CORE_ITEM', widget)

        return
    end

    -- Compact Mode
    if self.compactData.item == nil or self.compactData.widget == nil then
        local viewTime = eventType == 99 and 60 or database:GetVisibilityTimeByType(Type)
        local widget = baseFrame:Create(viewTime)
        -- widget:SetType(Type .. 's')

        widget.frame.icon:SetPoint('BOTTOMRIGHT', widget.frame.container, 'BOTTOMLEFT', 0, 0)

        local item = itemFrame:CreateCompact()

        local itemIcon = self:CreateIcon(itemData)
        item:AddIcon(itemIcon)

        widget:SetContent(item.content)
        widget:SetOnFinished(function()
            self.compactData = {}
        end)

        widget:SetChild(item)

        local height = widget:GetHeaderHeight()
        height = height + item.content:GetHeight()

        widget.height = max(ITEM_DEFAULT_HEIGHT, height)

        item.content:Show()

        self.compactData = {
            widget = widget,
            item = item
        }

        events:SendMessage('SIGNAL_ADD_CORE_ITEM', widget)
    else
        local widget = self.compactData.widget
        local item = self.compactData.item
        if widget == nil or item == nil then return end

        local itemIcon = self:CreateIcon(itemData)
        item:AddIcon(itemIcon)

        local height = widget:GetHeaderHeight()

        local iconCount = #item.content.children - 1
        local widgetWidth = database:GetWidgetWidth()
        local frameWidth = itemIcon:GetWidth()
        local padding = 8
        local itemsPerRow = floor(widgetWidth / (frameWidth + padding))
        local row = floor(iconCount / itemsPerRow)

        local itemHeight = (row + 1) * ITEM_DEFAULT_HEIGHT
        item.content:SetHeight(itemHeight)

        height = height + itemHeight

        widget.height = max(ITEM_DEFAULT_HEIGHT, height)

        widget:UpdateDuration(database:GetVisibilityTimeByType(Type))
        widget:UpdateHeight()

        events:SendMessage('SIGNAL_UPDATE_CORE_ITEM', widget)
    end
end

---@return Item
function itemFrame:Create()
    return self._pool:Acquire()
end

---@return ItemCompact
function itemFrame:CreateCompact()
    return self._compactPool:Acquire()
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

    contentFrame:SetScript('OnMouseDown', function()
        _G['ToggleAllBags']()
    end)

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

---@return ItemCompact
function itemFrame:_DoCreateCompact()
    ---@type ItemCompact
    local i = setmetatable({}, { __index = itemFrame.compactItemProto })

    local baseWidth = baseFrame.baseProto:GetWidgetWidth()

    local contentFrame = CreateFrame('Frame', nil, UIParent)
    contentFrame:SetWidth(baseWidth)
    contentFrame:SetHeight(ITEM_DEFAULT_HEIGHT)
    contentFrame:Hide()

    i.content = contentFrame
    i.content.children = {}

    return i
end

---@param item Item
function itemFrame:_DoReset(item)
    item:CleanChatData()
end

---@param item ItemCompact
function itemFrame:_DoResetCompact(item)
    item:CleanChatDataCompact()
end

---@param item ItemData
function itemFrame:CreateIcon(item)
    local iconFrame = CreateFrame('Frame', nil, UIParent)
    iconFrame:SetWidth(ITEM_DEFAULT_HEIGHT - 16)
    iconFrame:SetHeight(ITEM_DEFAULT_HEIGHT - 16)
    iconFrame:Hide()

    local iconTex = iconFrame:CreateTexture(nil, 'BACKGROUND')
    iconTex:SetAllPoints(iconFrame)
    iconTex:SetTexture(item.icon)

    local iconBorder = iconFrame:CreateTexture(nil, 'OVERLAY')
    iconBorder:SetAllPoints(iconFrame)
    iconBorder:SetTexture('Interface\\FriendsFrame\\WowShareTextures')
    iconBorder:SetAtlas('WoWShare-ItemQualityBorder')

    local r, g, b = C_Item.GetItemQualityColor(item.rarity)
    iconBorder:SetVertexColor(r, g, b, 1.0)

    if item.isQuest then
        local questTexture = iconFrame:CreateTexture(nil, 'OVERLAY')
        questTexture:SetAllPoints(iconFrame)
        questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
    end

    if item.isCosmetic then
        local cosmeticTexture = iconFrame:CreateTexture(nil, 'OVERLAY')
        cosmeticTexture:SetAllPoints(iconFrame)
        cosmeticTexture:SetTexture('Interface\\ContainerFrame\\CosmeticIconBorder')
        cosmeticTexture:SetAtlas('CosmeticIconFrame')
    end

    iconFrame:SetScript('OnEnter', function()
        GameTooltip:SetOwner(iconFrame, 'ANCHOR_TOPRIGHT')
        GameTooltip:SetHyperlink(item.link)
        GameTooltip:Show()
    end)

    iconFrame:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    if Masque then
        helpers:ApplyMasqueGroup(iconFrame)
    end

    return iconFrame
end

itemFrame:Enable()
