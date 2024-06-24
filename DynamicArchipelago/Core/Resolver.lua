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

resolver:Enable()
