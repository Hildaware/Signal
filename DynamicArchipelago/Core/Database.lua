local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Database: AceModule
local database = addon:NewModule('Database')

---@class databaseOptions
local defaults = {
    global = {
        Settings = {
            WidgetWidth = 512,
            VisibilityTimes = {
                Chat = 5.0
            }
        }
    }
}

function database:OnInitialize()
    database.internal = LibStub('AceDB-3.0'):New(addonName .. 'DB',
        defaults --[[@as AceDB.Schema]], true) --[[@as databaseOptions]]
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

database:Enable()
