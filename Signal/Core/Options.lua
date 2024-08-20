local addonName = ...

---@class Signal: AceAddon
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
            name = 'General Configuration',
            type = 'group',
            order = 1,
            args = {
                isleOptions = {
                    name = 'Isle Options',
                    type = 'header',
                    order = 1,
                },
                enable = {
                    name = 'Enable',
                    desc =
                    "When disabled, the 'always on' pill will not be shown. Notification will still be shown as normal.",
                    type = 'toggle',
                    order = 2,
                    get = function() return database:GetIsleEnabled() end,
                    set = function(_, value) database:SetIsleEnabled(value) end
                },
                unlock = {
                    name = 'Unlock',
                    desc = 'Unlocks the frame so it can be freely moved.',
                    type = 'toggle',
                    order = 3,
                    get = function() return not database:GetWidgetState() end,
                    set = function() database:SetWidgetState(not database:GetWidgetState()) end
                },
                notificationOptions = {
                    name = 'Notification Options',
                    type = 'header',
                    order = 4,
                },
                growth = {
                    name = 'Growth Up',
                    desc = 'When enabled, notifications will grow up instead of down.',
                    type = 'toggle',
                    order = 5,
                    get = function() return database:GetNotificationGrowth() end,
                    set = function(_, value) database:SetNotificationGrowth(value) end
                },
            }
        }
    }
}

function options:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, settings)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, 'Signal')

    addon:RegisterChatCommand('sig', 'SlashCommand')
    addon:RegisterChatCommand('signal', 'SlashCommand')
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
