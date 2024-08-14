local addonName = ...

---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceConsole-3.0

local LSM = LibStub("LibSharedMedia-3.0")

---@class Options: AceModule
local options = addon:NewModule('Options')

---@class Database: AceModule
local database = addon:GetModule('Database')

local optionsFrame

---@class AceConfig.OptionsTable
local settings = {
    type = 'group',
    args = {
        baseOptions = {
            name = 'Configuration',
            type = 'group',
            order = 1,
            args = {
                growth = {
                    name = 'Grow Up',
                    desc = 'When enabled, notifications will grow up instead of down.',
                    type = 'toggle',
                    order = 1,
                    get = function() return database:GetNotificationGrowth() end,
                    set = function(_, value) database:SetNotificationGrowth(value) end
                }
            }
        }
    }
}

function options:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, settings)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, 'Dynamic Archipelago')

    addon:RegisterChatCommand('da', 'SlashCommand')
    addon:RegisterChatCommand('dynamicarchipelago', 'SlashCommand')
end

---@param key string
---@param aceOptions AceConfig.OptionsTable
function options:AddSettings(key, aceOptions)
    settings.args[key] = aceOptions

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, settings)
end

---@param msg string
function addon:SlashCommand(msg)
    if msg == '' then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
        return
    end

    if msg == 'debug' then
        ---@class Debug: AceModule
        local debug = addon:GetModule('Debug')
        debug:Enable()
        debug:Show()
        return
    end
end

options:Enable()
