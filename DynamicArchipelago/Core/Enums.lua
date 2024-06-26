local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Enums: AceModule
local enums = addon:NewModule('Enums')

ISLAND_BASE_WIDTH = 64
ISLAND_SMALL_WIDTH = 128
ISLAND_FULL_WIDTH = 256
-- Height will always be width / 4

enums:Enable()
