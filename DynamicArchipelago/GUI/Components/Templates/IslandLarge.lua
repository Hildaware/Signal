local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class IslandLarge: AceModule
local large = addon:NewModule('IslandLarge')

---@class (exact) BaseLargeIsland : DynamicArchipelagoItem
---@field widget Frame
---@field child BaseIsland?
---@field SetChild function
large.baseProto = {}

function large.baseProto:Connect()
    if self.child == nil or self.child.eventFrame == nil then return end
    self.child.eventFrame:OnEnable()
    self.child.eventFrame:Show()
    -- Enable the event frame if it has one
    -- Enable the Events func? if it has one
end

function large.baseProto:Disconnect()
    -- Disable the event frame
    if self.child == nil or self.child.eventFrame == nil then return end
    self.child.eventFrame:OnDisable()
    self.child.eventFrame:Hide()
end

---@param widget DynamicArchipelagoItem|Frame
function large.baseProto:SetChild(widget)
    self.child = widget
end

function large.baseProto:Release()
    large._pool:Release(self)
end

function large.baseProto:CleanBaseData()
    if self.child == nil then return end

    self.child:Wipe()
    self.child = nil
end

function large.baseProto:Wipe()
    self.widget:Hide()
    self.widget:SetParent(nil)
    self.widget:ClearAllPoints()
    self:CleanBaseData()
end

function large:OnInitialize()
    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end

    _G['DynamicArchipelago'].IslandLarge = self
end

---@param item BaseLargeIsland
function large:_DoReset(item)
    item:CleanBaseData()
end

---@return BaseLargeIsland
function large:_DoCreate()
    local i = setmetatable({}, { __index = large.baseProto })
    i.child = nil

    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetSize(256, 256 / 4) -- TODO: From Config
    frame:Hide()

    i.widget = frame

    return i
end

---@return BaseLargeIsland
function large:Create()
    local i = self._pool:Acquire()

    return i
end

large:Enable()
