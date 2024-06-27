---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class IsleControllerFrame: AceModule
local controller = addon:NewModule('IsleControllerFrame')

---@class Resolver: AceModule
local resolver = addon:GetModule('Resolver')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class AvailableWidget
---@field widget ArchipelagoWidget
---@field priority number
---@field trigger function? -- This should always return a true / false
---@field event WowEvent?

---@class (exact) IsleController
---@field eventFrame Frame
---@field currentWidget AvailableWidget
---@field availableWidgets AvailableWidget[]
---@field SetWidget function
controller.proto = {}

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

    self.data.eventFrame = CreateFrame('Frame', nil, UIParent)
    self.data.eventFrame.lastUpdated = 0

    self.data.currentWidget = {
        widget = addon:GetModule('LocationWidget'),
        priority = 6,
        trigger = function()
            return resolver:InInstance()
        end
    }

    self.data:SetWidget(self.data.currentWidget)

    self.data.availableWidgets = {
        {
            widget = addon:GetModule('ExperienceWidget'),
            priority = 5,
            trigger = function()
                return resolver:GetMaxLevel() > resolver:GetCurrentLevel()
            end
        },
        {
            widget = addon:GetModule('LocationWidget'),
            priority = 6,
            trigger = function()
                return not resolver:InInstance()
            end
        }
    }

    table.sort(self.data.availableWidgets, function(a, b)
        return a.priority < b.priority
    end)

    self.data.eventFrame:SetScript('OnUpdate', function(eFrame, elapsed)
        eFrame.lastUpdated = eFrame.lastUpdated + elapsed
        if eFrame.lastUpdated >= 0.25 then
            for _, possibleWidget in pairs(self.data.availableWidgets) do
                if possibleWidget.trigger ~= nil then
                    if possibleWidget.trigger() and possibleWidget.priority < self.data.currentWidget.priority then
                        self.data:SetWidget(possibleWidget)
                        return
                    end
                end
            end
        end
    end)
end

--[[
    This fella needs the following:
    - An EventFrame to constantly check on specific events related to enabled Widgets
    - The currently enabled Widget
    - Map of available widgets
        - Contains their 'priority'
        - What triggers them
]]


controller:Enable()
