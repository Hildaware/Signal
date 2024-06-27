local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class IsleBase: AceModule
local base = addon:NewModule('IsleBase')

---@class (exact) IslandEventFrame : Frame
---@field lastUpdated number?
---@field registeredEvents WowEvent | WowEvent[]
---@field OnEnable function
---@field OnDisable function

---@class (exact) BaseIsland : DynamicArchipelagoItem
---@field type integer -- ISLAND_TYPE
---@field widget Frame
---@field eventFrame IslandEventFrame?
---@field child Frame?
---@field SetChild function
---@field Connect function
---@field Disconnect function
base.proto = {}

function base.proto:Connect()
    if self.child == nil or self.eventFrame == nil then return end

    if self.eventFrame.registeredEvents ~= nil then
        self:RegisterEvents(self.eventFrame.registeredEvents)
    end

    self.eventFrame:OnEnable()
    self.eventFrame:Show()
end

function base.proto:Disconnect()
    if self.child == nil or self.eventFrame == nil then return end

    if self.eventFrame.registeredEvents ~= nil then
        self:UnRegisterEvents()
    end

    self.eventFrame:OnDisable()
    self.eventFrame:Hide()
end

---@param widget DynamicArchipelagoItem|Frame
function base.proto:SetChild(widget)
    self.child = widget
end

function base.proto:Release()
    base._pool:Release(self)
end

function base.proto:CleanBaseData()
    if self.child ~= nil then
        self.child:Hide()
        self.child:SetParent(nil)
        self.child:ClearAllPoints()
        self.child = nil
    end
end

function base.proto:Wipe()
    self.widget:Hide()
    self.widget:SetParent(nil)
    self.widget:ClearAllPoints()
    self:CleanBaseData()
end

---@param scriptType ScriptFrame
---@param enableFunc function
---@param disableFunc function?
function base.proto:RegisterEventFrame(scriptType, enableFunc, disableFunc)
    ---@type IslandEventFrame
    local eventFrame = CreateFrame('Frame', nil, self.widget)
    eventFrame.lastUpdated = 0

    eventFrame.OnEnable = function()
        if scriptType == 'OnUpdate' then
            eventFrame:SetScript(scriptType, function(eFrame, args)
                enableFunc(eFrame, args)
            end)
        elseif scriptType == 'OnEvent' then
            eventFrame:SetScript(scriptType, function(eFrame, eventName, args)
                enableFunc(eFrame, eventName, args)
            end)
        else
            eventFrame:SetScript(scriptType, function(eFrame, args)
                enableFunc(eFrame, args)
            end)
            eventFrame:Hide()
        end
    end

    eventFrame.OnDisable = function()
        if disableFunc ~= nil then
            eventFrame:SetScript(scriptType, function(eFrame, arg)
                disableFunc()
            end)
        else
            eventFrame:SetScript(scriptType, nil)
        end
    end

    self.eventFrame = eventFrame
end

---@param events WowEvent|WowEvent[]
function base.proto:RegisterEvents(events)
    if self.eventFrame == nil then return end
    self.eventFrame.registeredEvents = events

    if type(events) == 'table' then
        for _, event in pairs(events) do
            self.eventFrame:RegisterEvent(event)
        end
        return
    end

    self.eventFrame:RegisterEvent(events)
end

function base.proto:UnRegisterEvents()
    if self.eventFrame == nil or self.eventFrame.registeredEvents == nil then return end
    self.eventFrame:UnregisterAllEvents()
end

function base:OnInitialize()
    self._pool = CreateObjectPool(self._DoCreate, self._DoReset)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end
end

---@param item BaseIsland
function base:_DoReset(item)
    item:CleanBaseData()
end

---@return BaseIsland?
function base:_DoCreate()
    local i = setmetatable({}, { __index = base.proto })
    i.child = nil

    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetSize(128, 128 / 4)
    frame:Hide()

    i.widget = frame

    return i
end

---@param type integer -- ISLAND_TYPE
---@return BaseIsland?
function base:Create(type)
    local size = ISLAND_FULL_WIDTH
    if type == ISLAND_TYPE.SMALL then
        size = ISLAND_SMALL_WIDTH
    elseif type == ISLAND_TYPE.FULL then
        size = ISLAND_FULL_WIDTH
    else
        print('No Size!!')
        return nil
    end

    self._pool.requiredType = type
    local i = self._pool:Acquire()

    if i.type == type then return i end

    i.type = type
    i.widget:SetSize(size, size / 4)

    return i
end

base:Enable()
