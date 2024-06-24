local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class IslandSmall: AceModule
local small = addon:NewModule('IslandSmall')

---@class (exact) BaseSmallIsland : DynamicArchipelagoItem
---@field widget Frame
---@field child BaseIsland?
---@field SetChild function
small.baseProto = {}

function small.baseProto:Connect()
    if self.child == nil or self.child.eventFrame == nil then return end
    self.child.eventFrame:OnEnable()
    self.child.eventFrame:Show()
    -- Enable the event frame if it has one
    -- Enable the Events func? if it has one
end

function small.baseProto:Disconnect()
    -- Disable the event frame
    if self.child == nil or self.child.eventFrame == nil then return end
    self.child.eventFrame:OnDisable()
    self.child.eventFrame:Hide()
end

---@param widget DynamicArchipelagoItem|Frame
function small.baseProto:SetChild(widget)
    self.child = widget
end

function small.baseProto:Release()
    small._pool:Release(self)
end

function small.baseProto:CleanBaseData()
    if self.child == nil then return end

    self.child:Wipe()
    self.child = nil
end

function small.baseProto:Wipe()
    self.widget:Hide()
    self.widget:SetParent(nil)
    self.widget:ClearAllPoints()
    self:CleanBaseData()
end

function small:OnInitialize()
    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end

    _G['DynamicArchipelago'].IslandSmall = self
end

---@param item BaseSmallIsland
function small:_DoReset(item)
    item:CleanBaseData()
end

---@return BaseSmallIsland
function small:_DoCreate()
    local i = setmetatable({}, { __index = small.baseProto })
    i.child = nil

    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetSize(128, 128 / 4) -- TODO: From Config
    frame:Hide()

    i.widget = frame

    return i
end

---@return BaseSmallIsland
function small:Create()
    local i = self._pool:Acquire()

    return i
end

small:Enable()
