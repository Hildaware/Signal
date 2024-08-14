local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Database: AceModule
local database = addon:NewModule('Database')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class databaseOptions
local defaults = {
    global = {
        Settings = {
            WidgetWidth = 256,
            VisibilityTimes = {
                Chat = 5.0
            },
            ---@type Coords
            Position = {
                point = 'CENTER',
                relativePoint = 'CENTER',
                x = 0,
                y = 0
            },
            Locked = true,
            NotificationGrowth = false
        }
    }
}

function database:OnInitialize()
    database.internal = LibStub('AceDB-3.0'):New(addonName .. 'DB',
        defaults --[[@as AceDB.Schema]], true) --[[@as databaseOptions]]
end

--#region Gets

---@return boolean
function database:GetWidgetState()
    return database.internal.global.Settings.Locked
end

---@return Coords
function database:GetWidgetPosition()
    return database.internal.global.Settings.Position
end

---@return integer
function database:GetWidgetWidth()
    return database.internal.global.Settings.WidgetWidth
end

---@param type string
---@return number
function database:GetVisibilityTimeByType(type)
    return database.internal.global.Settings.VisibilityTimes[type] or 5.0
end

---@return boolean
function database:GetNotificationGrowth()
    return database.internal.global.Settings.NotificationGrowth
end

--#endregion

--#region Sets

---@param state boolean
function database:SetWidgetState(state)
    database.internal.global.Settings.Locked = state


    ---@class PeninsulaWidget: AceModule
    local arch = addon:GetModule('Archipelago')
    arch:ToggleLockedState(state)
end

---@param position Coords
function database:SetWidgetPosition(position)
    database.internal.global.Settings.Position = position
end

---@param position number
function database:SetWidgetPositionX(position)
    database.internal.global.Settings.Position.x = position
end

---@param position number
function database:SetWidgetPositionY(position)
    database.internal.global.Settings.Position.y = position
end

---@param value boolean
function database:SetNotificationGrowth(value)
    database.internal.global.Settings.NotificationGrowth = value
    events:SendMessage('DYNAMIC_ARCHIPELAGO_UPDATE_CONFIG')
end

--#endregion

database:Enable()
