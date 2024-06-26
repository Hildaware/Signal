local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class IsleBaseFull: AceModule
local full = addon:NewModule('IsleBaseFull')

---@class (exact) BaseLargeIsland : DynamicArchipelagoItem
---@field widget Frame
---@field child BaseIsland?
---@field SetChild function
full.baseProto = {}

function full.baseProto:Connect()
    if self.child == nil or self.child.eventFrame == nil then return end
    self.child.eventFrame:OnEnable()
    self.child.eventFrame:Show()
    -- Enable the event frame if it has one
    -- Enable the Events func? if it has one
end

function full.baseProto:Disconnect()
    -- Disable the event frame
    if self.child == nil or self.child.eventFrame == nil then return end
    self.child.eventFrame:OnDisable()
    self.child.eventFrame:Hide()
end

---@param widget DynamicArchipelagoItem|Frame
function full.baseProto:SetChild(widget)
    self.child = widget
end

function full.baseProto:Release()
    full._pool:Release(self)
end

function full.baseProto:CleanBaseData()
    if self.child == nil then return end

    self.child:Wipe()
    self.child = nil
end

function full.baseProto:Wipe()
    self.widget:Hide()
    self.widget:SetParent(nil)
    self.widget:ClearAllPoints()
    self:CleanBaseData()
end

function full:OnInitialize()
    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end

    -- _G['DynamicArchipelago'].IslandLarge = self
end

---@param item BaseLargeIsland
function full:_DoReset(item)
    item:CleanBaseData()
end

---@return BaseLargeIsland
function full:_DoCreate()
    local i = setmetatable({}, { __index = full.baseProto })
    i.child = nil

    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetSize(256, 256 / 4) -- TODO: From Config
    frame:Hide()

    i.widget = frame

    return i
end

---@return BaseLargeIsland
function full:Create()
    local i = self._pool:Acquire()

    return i
end

full:Enable()
