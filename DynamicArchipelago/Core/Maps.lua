local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Maps: AceModule
local maps = addon:NewModule('Maps')

maps:Enable()
