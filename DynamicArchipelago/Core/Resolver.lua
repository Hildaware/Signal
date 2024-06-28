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
    return MAX_PLAYER_LEVEL_BY_EXPANSION[GetExpansionLevel()]
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
    return IsInInstance() ---@diagnostic disable-line: redundant-return-value
end

resolver:Enable()
