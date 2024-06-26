---@diagnostic disable: undefined-field

local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Events: AceModule, AceEvent-3.0
local events = addon:NewModule('Events', 'AceEvent-3.0')

local eventMessages = {
    'DYNAMIC_ARCHIPELAGO_ADD_CORE_ITEM',
    'DYNAMIC_ARCHIPELAGO_ITEM_TIMER_END',
    'DYNAMIC_ARCHIPELAGO_CORE_START',
    'DYNAMIC_ARCHIPELAGO_CORE_END'
}

function events:OnInitialize()
    for _, value in pairs(eventMessages) do
        events:RegisterMessage(value)
    end
end

events:Enable()
