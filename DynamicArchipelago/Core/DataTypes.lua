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

---@class BaseFrame : Frame
---@field bg Texture
---@field mask MaskTexture

--#region IslandContent

---@class (exact) IslandContent
---@field widget Frame
---@field Small BaseSmallIsland
---@field Full BaseLargeIsland
---@field OnClick function?

--- Large / Small Islands must implement this
---@class BaseIsland : DynamicArchipelagoItem
---@field eventFrame IslandEventFrame?
---@field Connect function
---@field Disconnect function

---@class (exact) IslandEventFrame : Frame
---@field lastUpdated number
---@field OnEnable function
---@field OnDisable function

---@class IslandFrame : AnimatedFrame
---@field Content IslandContent

--#endregion


types:Enable()
