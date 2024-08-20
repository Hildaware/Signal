---@diagnostic disable: assign-type-mismatch
local addonName = ...

---@class Signal: AceAddon
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
---@field fallbackWidget AvailableWidget
---@field availableWidgets AvailableWidget[]
---@field shouldWidgetReset boolean
---@field lastEventTrigger WowEvent
controller.proto = {}

local basicLocationWidget = {
    widget = addon:GetModule('LocationWidget'),
    id = 1,
    event = 'ZONE_CHANGED_NEW_AREA',
    fallbackWidget = true
}

---@param eventName WowEvent
function controller.proto:RegisterEvent(eventName)
    self.eventFrame:RegisterEvent(eventName)
end

---@param widget AvailableWidget
function controller.proto:SetWidget(widget)
    self.currentWidget = widget
    events:SendMessage('SIGNAL_SET_ISLE_WIDGET', widget.widget)

    if widget.fallbackWidget == nil or widget.fallbackWidget == false then
        self.shouldWidgetReset = false
    else
        self.fallbackWidget = widget
    end

    if widget.postTriggerTime ~= nil then
        local time = widget.postTriggerTime()
        C_Timer.After(time, function()
            self.shouldWidgetReset = true
            self:SetWidget(self.fallbackWidget)
        end)
    end
end

function controller:OnInitialize()
    self.data = setmetatable({}, { __index = controller.proto })

    ---@class Frame
    ---@field lastUpdated number
    self.data.eventFrame = CreateFrame('Frame', nil, UIParent)
    self.data.eventFrame.lastUpdated = 0

    self.data.lastEventTrigger = ''
    self.data.shouldWidgetReset = true
    self.data.fallbackWidget = basicLocationWidget
    self.data:SetWidget(basicLocationWidget)

    self.data.availableWidgets = {
        -- {
        --     widget = addon:GetModule('DungeonTimerWidget'),
        --     event = 'PLAYER_ENTERING_WORLD',
        --     eventValidator = function()
        --         return resolver:InInstance()
        --     end,
        --     fallbackWidget = true
        -- },
        {
            widget = addon:GetModule('ExperienceWidget'),
            id = 2,
            event = 'PLAYER_XP_UPDATE',
            postTriggerTime = function()
                return resolver:InInstance() and 5 or 30
            end
        },
        {
            widget = addon:GetModule('LocationWidget'),
            id = 1,
            event = 'ZONE_CHANGED_NEW_AREA',
            fallbackWidget = true
        }
    }

    for _, widget in pairs(self.data.availableWidgets) do
        if widget.event ~= nil then
            self.data.eventFrame:RegisterEvent(widget.event)
        end
    end

    self.data.eventFrame:SetScript('OnEvent', function(_, event, ...)
        self.data.lastEventTrigger = event
        if self.data.shouldWidgetReset == false then return end -- Always bail if we don't want to

        for _, widget in pairs(self.data.availableWidgets) do
            if widget.event == event and self.data.currentWidget.id ~= widget.id then
                if widget.eventValidator and not widget.eventValidator() then return end
                self.data:SetWidget(widget)
                return
            end
        end
    end)

    ---@param eFrame Frame
    ---@param elapsed number
    -- self.data.eventFrame:SetScript('OnUpdate', function(eFrame, elapsed)
    --     eFrame.lastUpdated = eFrame.lastUpdated + elapsed

    --     if addon.status.isReady == false then return end

    --     if eFrame.lastUpdated >= 0.25 then
    --         for _, possibleWidget in pairs(self.data.availableWidgets) do
    --             if possibleWidget.trigger ~= nil then
    --                 if possibleWidget.trigger() then
    --                     if self.data.currentWidget == nil then
    --                         self.data:SetWidget(possibleWidget)
    --                         return
    --                     end
    --                     if possibleWidget.priority < self.data.currentWidget.priority then
    --                         self.data:SetWidget(possibleWidget)
    --                         return
    --                     end
    --                 end
    --             end
    --         end

    --         if self.data.currentWidget == nil then
    --             self.data:SetWidget(basicLocationWidget)
    --         end
    --     end
    -- end)
end

controller:Enable()
