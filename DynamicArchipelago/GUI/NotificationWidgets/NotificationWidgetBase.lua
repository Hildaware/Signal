local addonName = ...

---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

--[[ All Notifications should inherit from this module ]]
---@class NotificationWidgetBase: AceModule
local widget = addon:NewModule('NotificationWidget')

---@class NotificationWidget: DynamicArchipelagoItem
---@field content Frame
---@field icon Frame

---@class NotificationType: AceModule
---@field _pool ObjectPoolMixin
---@field Type string
---@field Create fun(_): NotificationWidget
widget.proto = {}

---@generic T: NotificationType
---@param type string
---@return T
function widget:New(moduleName, type)
    ---@class NotificationType
    local i = addon:NewModule(moduleName)
    setmetatable(i, { __index = widget.proto })
    i._pool = {}
    i.Type = type

    return i
end

---@param createFunc fun(_): NotificationWidget
---@param resetFunc fun(_, widget: NotificationWidget)
function widget.proto:RegisterPool(createFunc, resetFunc)
    self._pool = CreateObjectPool(createFunc, resetFunc)
    if self._pool.SetResetDisallowedIfNew then
        self._pool:SetResetDisallowedIfNew()
    end
end

---@generic T: NotificationType
---@return T
function widget.proto:Create()
    return self._pool:Acquire()
end

widget:Enable()
