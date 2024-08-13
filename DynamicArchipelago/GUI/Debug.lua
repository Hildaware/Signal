---@diagnostic disable: assign-type-mismatch
local addonName = ...

---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Debug: AceModule
local debug = addon:NewModule('Debug')


function debug:Show()
    ---@class ItemFrame: AceModule
    local itemFrame = addon:GetModule('ItemFrame')

    local name = UnitName('player')
    local server = GetNormalizedRealmName()
    local playerName = name .. '-' .. server
    itemFrame:OnEvent(99, 'CHAT_MSG_LOOT', 6948, playerName)
    itemFrame:OnEvent(99, 'CHAT_MSG_LOOT', 71635, playerName)
    itemFrame:OnEvent(99, 'CHAT_MSG_LOOT', 128862, playerName)
    itemFrame:OnEvent(99, 'CHAT_MSG_LOOT', 152161, playerName)
end

debug:Disable()
