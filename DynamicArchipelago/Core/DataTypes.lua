local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Types: AceModule
local types = addon:NewModule('Types')

---@class DynamicArchipelagoItem
---@field data table
---@field Wipe function

---@class AnimatedFrame : Frame
---@field animation AnimationGroup?
---@field animationIn AnimationGroup?
---@field animationOut AnimationGroup?

---@class Coords
---@field X number
---@field Y number

types:Enable()
