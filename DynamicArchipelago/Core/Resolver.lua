local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Resolver: AceModule
local resolver = addon:NewModule('Resolver')

---@class Types: AceModule
local types = addon:GetModule('Types')

---@return number
function resolver:GetCurrentLevel()
    return UnitLevel('player')
end

---@return number
function resolver:GetMaxLevel()
    MAX_PLAYER_LEVEL_TABLE = {
        [0] = 60,
        [1] = 60,
        [2] = 60,
        [3] = 60,
        [4] = 60,
        [5] = 60,
        [6] = 60,
        [7] = 60,
        [8] = 60,
        [9] = 70,
        [10] = 80
    }

    return MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
end

---@return number
function resolver:GetCurrentXP()
    return UnitXP('player')
end

---@return number
function resolver:GetRequiredXP()
    return UnitXPMax('player')
end

---@return number?
function resolver:GetRestedXP()
    return GetXPExhaustion()
end

---@return boolean
function resolver:InInstance()
    return IsInInstance()
end

resolver:Enable()
