local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Types: AceModule
local types = addon:NewModule('Types')

---@class DynamicArchipelagoItem
---@field data table
---@field Wipe function

---@class AnimatedFrame : Frame
---@field animation AnimationGroup

types:Enable()
