local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Enums: AceModule
local enums = addon:NewModule('Enums')

ISLE_BASE_PADDING = 4

ISLE_BASE_WIDTH = 64
ISLE_SMALL_WIDTH = 128
ISLE_FULL_WIDTH = 312
-- Height will always be width / 4

ISLE_NAME = {
    SMALL = 'Small',
    FULL = 'Full'
}

ISLE_TYPE = {
    SMALL = 1,
    FULL = 2
}

---@enum PeninsulaStyle
PENINSULA_STYLE = {
    HORIZONTAL = 1,
    VERTICAL = 2
}

MAX_PLAYER_LEVEL_BY_EXPANSION = {
    [0] = 60, -- Classic
    [1] = 60, -- BC
    [2] = 60, -- Wrath
    [3] = 60, -- Cata
    [4] = 60, -- MoP
    [5] = 60, -- WoD
    [6] = 60, -- Legion
    [7] = 60, -- BfA
    [8] = 60, -- Shadowlands
    [9] = 70, -- DF
    [10] = 80 -- TWW
}

COLOR = {
    YELLOW = 'F5EC27',
    BLUE = '27A1F5'
}

enums:Enable()
