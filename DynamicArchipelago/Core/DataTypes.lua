local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Types: AceModule
local types = addon:NewModule('Types')

---@class DynamicArchipelagoItem : Frame
---@field data table
---@field Wipe function

---@class AnimatedFrame : Frame
---@field animation AnimationGroup?
---@field animationIn AnimationGroup?
---@field animationOut AnimationGroup?

---@class Coords
---@field X number
---@field Y number

---@class PeninsulaBase : Frame
---@field bg Texture
---@field mask MaskTexture

--#region IslandContent

---@class (exact) IslandContent
---@field widget Frame
---@field Small BaseIsle
---@field Full BaseIsle
---@field OnClick function?

---@class IslandFrame : AnimatedFrame
---@field Content IslandContent

--#endregion

types:Enable()
