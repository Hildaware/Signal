---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class PeninsulaWidget: AceModule
local arch = addon:NewModule('Archipelago')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Peninsula: AceModule
local core = addon:GetModule('Peninsula')

---@class Isle: AceModule
local island = addon:GetModule('Isle')

---@class (exact) Archipelago
---@field widget Frame
---@field island IslandLife
---@field core PeninsulaCore
arch.proto = {}
function arch:OnInitialize()
    self:Create()
end

function arch:Create()
    self.data = setmetatable({}, { __index = arch.proto })

    local position = database:GetWidgetPosition()
    local width = database:GetWidgetWidth()

    local frame = CreateFrame('Frame', 'DynamicArchipelago', UIParent)
    frame:SetPoint('CENTER')
    frame:SetSize(width, 300)

    self.data.widget = frame

    local coreIsland = island:Create()
    coreIsland.widget:ClearAllPoints()
    coreIsland.widget:SetParent(frame)
    coreIsland.widget:SetPoint('TOP')

    self.data.island = coreIsland

    local coreContent = core:Create()
    coreContent.widget:ClearAllPoints()
    coreContent.widget:SetParent(frame)
    coreContent.widget:SetPoint('TOP')
    coreContent.widget:SetSize(0, 0)

    self.data.core = coreContent

    frame:Show()
    self.data.island:FadeIn()
end

function events:DYNAMIC_ARCHIPELAGO_CORE_START()
    if arch.data.core.widget:IsShown() then return end -- Shouldn't happend but whatev
    arch.data.island:FadeOut()
end

function events:DYNAMIC_ARCHIPELAGO_CORE_END()
    arch.data.island:FadeIn()
end

arch:Enable()
