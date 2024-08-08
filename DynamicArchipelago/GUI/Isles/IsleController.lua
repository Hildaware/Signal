---@diagnostic disable: assign-type-mismatch
local addonName = ...

---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class IsleControllerFrame: AceModule
local controller = addon:NewModule('IsleControllerFrame')

---@class Resolver: AceModule
local resolver = addon:GetModule('Resolver')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class (exact) IsleController
---@field eventFrame Frame
---@field currentWidget AvailableWidget
---@field availableWidgets AvailableWidget[]
---@field SetWidget function
controller.proto = {}

local basicLocationWidget = {
    widget = addon:GetModule('LocationWidget'),
    priority = 99,
    trigger = function()
        return not resolver:InInstance()
    end
}

---@param eventName WowEvent
function controller.proto:RegisterEvent(eventName)
    self.eventFrame:RegisterEvent(eventName)
end

---@param widget AvailableWidget
function controller.proto:SetWidget(widget)
    self.currentWidget = widget
    events:SendMessage('DYNAMIC_ARCHIPELAGO_SET_ISLE_WIDGET', widget.widget)
end

function controller:OnInitialize()
    self.data = setmetatable({}, { __index = controller.proto })

    ---@class Frame
    ---@field lastUpdated number
    self.data.eventFrame = CreateFrame('Frame', nil, UIParent)
    self.data.eventFrame.lastUpdated = 0

    -- TODO: Add a -nothing- widget?
    -- self.data.currentWidget = {
    --     widget = addon:GetModule('LocationWidget'),
    --     priority = 6,
    --     trigger = function()
    --         return not resolver:InInstance()
    --     end
    -- }

    self.data.availableWidgets = {
        {
            widget = addon:GetModule('ExperienceWidget'),
            priority = 5,
            -- trigger = function()
            --     return resolver:GetMaxLevel() > resolver:GetCurrentLevel()
            -- end
            event = 'PLAYER_XP_UPDATE'
        },
        {
            widget = addon:GetModule('LocationWidget'),
            priority = 6,
            -- trigger = function()
            --     return not resolver:InInstance()
            -- end,
            event = 'ZONE_CHANGED_NEW_AREA'
        }
    }

    for _, widget in pairs(self.data.availableWidgets) do
        if widget.event ~= nil then
            self.data.eventFrame:RegisterEvent(widget.event)
        end
    end


    table.sort(self.data.availableWidgets, function(a, b)
        return a.priority < b.priority
    end)

    self.data.eventFrame:SetScript('OnEvent', function(_, event, ...)
        for _, possibleWidget in pairs(self.data.availableWidgets) do
            if possibleWidget.event == event then
                if self.data.currentWidget == nil then
                    self.data:SetWidget(possibleWidget)
                    return
                end
                if possibleWidget.priority < self.data.currentWidget.priority then
                    self.data:SetWidget(possibleWidget)
                    return
                end
            end
        end
    end)

    ---@param eFrame Frame
    ---@param elapsed number
    self.data.eventFrame:SetScript('OnUpdate', function(eFrame, elapsed)
        eFrame.lastUpdated = eFrame.lastUpdated + elapsed

        if addon.status.isReady == false then return end

        if eFrame.lastUpdated >= 0.25 then
            for _, possibleWidget in pairs(self.data.availableWidgets) do
                if possibleWidget.trigger ~= nil then
                    if possibleWidget.trigger() then
                        if self.data.currentWidget == nil then
                            self.data:SetWidget(possibleWidget)
                            return
                        end
                        if possibleWidget.priority < self.data.currentWidget.priority then
                            self.data:SetWidget(possibleWidget)
                            return
                        end
                    end
                end
            end

            if self.data.currentWidget == nil then
                self.data:SetWidget(basicLocationWidget)
            end
        end
    end)
end

controller:Enable()
