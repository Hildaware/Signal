local addonName, core = ...
local addon = LibStub('AceAddon-3.0'):NewAddon(core, addonName, 'AceHook-3.0')
addon:SetDefaultModuleState(false)

_G['DynamicArchipelago'] = {}
