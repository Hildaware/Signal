---@diagnostic disable: undefined-field
local addon = LibStub('AceAddon-3.0'):GetAddon('DynamicArchipelago')

---@class ItemUtils: AceModule
local utils = addon:NewModule('ItemUtils')

---@enum ItemType
ItemType = {
    Item = 1,
    Currency = 2,
    Faction = 3
}

---@class ItemData
---@field time integer
---@field id number
---@field itemType ItemType
---@field stacks number
---@field name string
---@field icon string
---@field rarity Enum.ItemQuality
---@field link string
---@field total number
---@field tertiary? string
---@field sock? string
---@field ilvl? number
---@field isGear? boolean
---@field pQuality? string
---@field isQuest? boolean
---@field factionData? FactionData

---@class FactionData
---@field amountMessage string

---@class ItemContent : Frame
---@field itemType FontString
---@field message FontString

---@class ItemIcon : Frame
---@field texture Texture

---@param type string
---@return boolean
function utils:IsGear(type)
    return type == "Armor" or type == "Weapon"
end

Enum.ItemQuality.Reputation = 98
Enum.ItemQuality.Currency = 99

---@param data ItemData
function utils:FormatItemString(data)
    local message = ''
    if data.stacks > 1 then
        if data.itemType == ItemType.Faction then
            message = '+' .. tostring(data.stacks) .. ' '
        else
            message = tostring(data.stacks) .. 'x '
        end
    end
    message = message .. data.link
    if data.total > 1 then
        local totalCount = tostring(data.total + data.stacks)
        message = message .. ' (' .. totalCount .. 'x)'
    end

    -- Item Tertiaries
    if data.itemType == ItemType.Item and data.isGear then
        message = message .. '\n'
        if data.ilvl then
            message = message .. 'i' .. data.ilvl
        end

        if data.tertiary then
            message = message .. ' |cFF00FFFF' .. data.tertiary .. '|r'
        end

        if data.sock then
            message = message .. ' ' .. data.sock
        end
    end

    -- Reputation
    if data.itemType == ItemType.Faction and data.factionData ~= nil and data.factionData.amountMessage ~= '' then
        message = message .. ' (' .. data.factionData.amountMessage .. ')'
    end

    return message
end

---@param itemStr string
---@param stacks number
---@return ItemData?
function utils:GetItemData(itemStr, stacks)
    local itemName, link, quality, level, minLevel, type, subType, stackCount,
    _, texture, price = C_Item.GetItemInfo(itemStr)

    if not link then return end

    local pQuality = string.match(link, ".*:Professions%-ChatIcon%-Quality%-Tier(%d):?.*")
    local isQuest = type == 'Quest'

    local realItemLevel = C_Item.GetDetailedItemLevelInfo(link)
    local itemStats = C_Item.GetItemStats(link)
    local itemId = C_Item.GetItemIDForItemInfo(itemStr)
    local isGear = self:IsGear(type)

    local sockText = " ";

    if itemStats then
        if itemStats["EMPTY_SOCKET_META"] then
            for i = 1, itemStats["EMPTY_SOCKET_META"] do
                sockText = sockText .. "|T136257:0|t";
            end
        end

        if itemStats["EMPTY_SOCKET_RED"] then
            for i = 1, itemStats["EMPTY_SOCKET_RED"] do
                sockText = sockText .. "|T136258:0|t";
            end
        end

        if itemStats["EMPTY_SOCKET_YELLOW"] then
            for i = 1, itemStats["EMPTY_SOCKET_YELLOW"] do
                sockText = sockText .. "|T136259:0|t";
            end
        end

        if itemStats["EMPTY_SOCKET_BLUE"] then
            for i = 1, itemStats["EMPTY_SOCKET_BLUE"] do
                sockText = sockText .. "|T136256:0|t";
            end
        end

        if itemStats["EMPTY_SOCKET_PRISMATIC"] then
            for i = 1, itemStats["EMPTY_SOCKET_PRISMATIC"] do
                sockText = sockText .. "|T458977:0|t";
            end
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
        itemType = ItemType.Item,
        stacks = stacks,
        name = itemName,
        icon = texture,
        rarity = quality,
        link = link,
        tertiary = tertiary or nil,
        sock = (sockText ~= " ") and sockText or nil,
        ilvl = realItemLevel or nil,
        isGear = isGear or false,
        pQuality = (pQuality and CreateAtlasMarkup('professions-icon-quality-tier' .. pQuality .. '-inv', 32, 32)) or nil,
        isQuest = isQuest or nil,
        total = totalCount
    }

    return newItem
end

--#region Parsers

---@param ... any
---@return ItemData?
function utils:Parse_CHAT_MSG_CURRENCY(...)
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
        ---@type ItemData
        local newItem = {
            id = info.currencyID,
            itemType = ItemType.Currency,
            time = GetTime(),
            stacks = tonumber(count),
            name = info.name,
            icon = info.iconFileID,
            rarity = Enum.ItemQuality.Currency,
            link = itemLink,
            total = info.quantity
        }

        return newItem
    end
end

---@param ... any
---@return ItemData?
function utils:Parse_CHAT_MSG_LOOT(...)
    local itemStr = select(2, ...)
    local player = select(3, ...)

    local name = UnitName('player')
    local server = GetNormalizedRealmName()
    local playerName = name .. '-' .. server

    if player ~= playerName then return end

    itemStr = itemStr:sub(itemStr:find(':') + 2, itemStr:len())
    local stacks = string.match(itemStr, ".*x(%d*)(%.?)$")
    local itemStacks = tonumber(stacks) or 1

    return self:GetItemData(itemStr, itemStacks)
end

---@param ... any
---@return ItemData?
function utils:Parse_ENCOUNTER_LOOT_RECEIVED(...)
    local _, itemID, text, itemStacks, playerName = ...
    if not text then return end
    if playerName ~= GetUnitName('player') then return end
    return self:GetItemData(text, itemStacks)
end

---@param ... any
---@return ItemData?
function utils:Parse_CHAT_MSG_COMBAT_FACTION_CHANGE(...)
    local text = select(2, ...)
    if not text then return end

    local faction = string.match(text, ".*with ([%a %-',%(%)%d:]+) increased by.*") or
        string.match(text, ".*with ([%a %-',%(%)%d:]+) decreased by.*") or ""
    local stacks = tonumber(string.match(text, ".*increased by (%d+)%.?")) or
        (tonumber(string.match(text, ".*decreased by (%d+)%.?")) * -1) or 0

    if faction == '' then return end

    local id = 0
    local factionMessage = ''
    for factionIndex = 1, C_Reputation.GetNumFactions() do
        local factionData = C_Reputation.GetFactionDataByIndex(factionIndex)
        if factionData == nil then break end
        if factionData.name == faction then
            id = factionData.factionID
            factionMessage = factionData.currentStanding .. ' / ' .. factionData.nextReactionThreshold
            break
        end
    end

    return {
        time = GetTime(),
        itemType = ItemType.Faction,
        id = id,
        stacks = stacks,
        name = faction,
        icon = 236681,
        rarity = Enum.ItemQuality.Reputation,
        link = faction,
        total = 0,
        factionData = {
            amountMessage = factionMessage
        }
    }
end

--#endregion

utils:Enable()
