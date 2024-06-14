local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Resolver: AceModule
local resolver = addon:NewModule('Resolver')

---@class Types: AceModule
local types = addon:GetModule('Types')


resolver:Enable()
