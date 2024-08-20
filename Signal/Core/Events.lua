---@diagnostic disable: undefined-field

local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Events: AceModule, AceEvent-3.0
local events = addon:NewModule('Events', 'AceEvent-3.0')

local eventMessages = {
    'SIGNAL_UPDATE_CONFIG',
    'SIGNAL_ADD_CORE_ITEM',
    'SIGNAL_ITEM_TIMER_END',
    'SIGNAL_UPDATE_CORE_ITEM',
    'SIGNAL_CORE_START',
    'SIGNAL_CORE_END',
    'SIGNAL_SET_ISLE_WIDGET'
}

function events:OnInitialize()
    for _, value in pairs(eventMessages) do
        events:RegisterMessage(value)
    end
end

events:Enable()
