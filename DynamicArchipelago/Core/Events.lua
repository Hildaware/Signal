---@diagnostic disable: undefined-field

local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Events: AceModule, AceEvent-3.0
local events = addon:NewModule('Events', 'AceEvent-3.0')

function events:OnInitialize()
    events:RegisterMessage('DYNAMIC_ARCHIPELAGO_ADD')
    events:RegisterMessage('DYNAMIC_ARCHIPELAGO_ITEM_TIMER_END')
end

events:Enable()
