---@diagnostic disable: assign-type-mismatch
local addonName = ...

---@class Signal: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Debug: AceModule
local debug = addon:NewModule('Debug')

function debug:Show()
    ---@class ItemFrame: AceModule
    local itemFrame = addon:GetModule('ItemFrame')

    ---@class Achievements: NotificationType
    local achievements = addon:GetModule('Achievements')

    local name = UnitName('player')
    local server = GetNormalizedRealmName()
    local playerName = name .. '-' .. server

    local items = {
        'item:6948:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0',
        'item:71635:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0',
        'item:128862:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0',
        'item:87390::::::::70:::::',
        'item:213636::::::::70:265:512::5:9886:10643:10969:10858:11205:70',
    }

    for _, item in ipairs(items) do
        itemFrame:OnEvent(99, 'CHAT_MSG_LOOT', item, playerName)
    end

    local achievementIds = {
        19458,
        19879,
        10994
    }

    for _, id in ipairs(achievementIds) do
        achievements:OnEvent('', id)
    end
end

debug:Disable()
