local addonName, addonTable = ...
---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):NewAddon(addonTable, addonName, 'AceHook-3.0', 'AceConsole-3.0')
addon:SetDefaultModuleState(false)
