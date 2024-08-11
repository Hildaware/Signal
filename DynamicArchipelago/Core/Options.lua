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
    args = {}
    -- type = 'group',
    -- args = {
    --     zoneview = {
    --         name = 'Zone View',
    --         type = 'group',
    --         order = 1,
    --         args = {
    --             enabled = {
    --                 name = 'Enabled',
    --                 desc = 'Enable the Zone View frame',
    --                 type = 'toggle',
    --                 order = 1,
    --                 get = function() return database:GetZoneViewEnabled() end,
    --                 set = function(_, val) database:SetZoneViewEnabled(val) end
    --             },
    --             show = {
    --                 name = 'Show',
    --                 type = 'execute',
    --                 order = 2,
    --                 func = function()
    --                     ---@class ZoneView
    --                     local zoneView = addon:GetModule('ZoneView')
    --                     zoneView:Show()
    --                 end
    --             },
    --             style = {
    --                 name = 'Styling',
    --                 type = 'header',
    --                 order = 3,
    --             },
    --             backgroundColor = {
    --                 name = 'Background Color',
    --                 desc = 'Set the background color of the frame',
    --                 type = 'color',
    --                 order = 4,
    --                 hasAlpha = true,
    --                 get = function()
    --                     local color = database:GetZoneViewColor()
    --                     return color.r, color.g, color.b, color.a
    --                 end,
    --                 set = function(_, r, g, b, a)
    --                     database:SetZoneViewColor(r, g, b, a)
    --                 end
    --             },
    --             font = {
    --                 name = 'Font',
    --                 desc = 'Set the default font used',
    --                 type = 'select',
    --                 order = 5,
    --                 style = 'dropdown',
    --                 dialogControl = 'LSM30_Font',
    --                 values = LSM:HashTable("font"),
    --                 get = function()
    --                     return database:GetZoneViewFont().name
    --                 end,
    --                 set = function(_, font)
    --                     database:SetZoneViewFont(font, LSM:HashTable('font')[font])
    --                 end
    --             }
    --         }
    --     },
    --     headsUp = {
    --         name = 'Heads-Up Display',
    --         type = 'group',
    --         order = 2,
    --         args = {
    --             enabled = {
    --                 name = 'Enabled',
    --                 desc = 'Enable the Heads-Up Display',
    --                 type = 'toggle',
    --                 order = 1,
    --                 get = function() return database:GetHeadsUpViewEnabled() end,
    --                 set = function(_, val) database:SetHeadsUpViewEnabled(val) end
    --             },
    --             locked = {
    --                 name = 'Locked',
    --                 desc = 'Lock the Heads-Up Display',
    --                 type = 'toggle',
    --                 order = 2,
    --                 get = function() return database:GetHeadsUpViewLocked() end,
    --                 set = function(_, val) database:SetHeadsUpViewLocked(val) end
    --             },
    --             showDefault = {
    --                 name = 'Show Default Display',
    --                 desc = 'Show the default Dragonriding display',
    --                 type = 'toggle',
    --                 order = 3,
    --                 get = function() return database:GetDefaultDisplayEnabled() end,
    --                 set = function(_, val) database:SetDefaultDisplayEnabled(val) end
    --             },
    --             position = {
    --                 name = 'Position',
    --                 type = 'header',
    --                 order = 4
    --             },
    --             x = {
    --                 name = 'X',
    --                 type = 'range',
    --                 order = 5,
    --                 min = 0,
    --                 max = 6000,
    --                 step = 1,
    --                 get = function() return database:GetHeadsUpViewPosition().X end,
    --                 set = function(_, val) database:SetHeadsUpViewPositionX(val) end
    --             },
    --             y = {
    --                 name = 'Y',
    --                 type = 'range',
    --                 order = 6,
    --                 min = 0,
    --                 max = 6000,
    --                 step = 1,
    --                 get = function() return database:GetHeadsUpViewPosition().Y end,
    --                 set = function(_, val) database:SetHeadsUpViewPositionY(val) end
    --             },
    --             styling = {
    --                 name = 'Styling',
    --                 type = 'header',
    --                 order = 7
    --             },
    --             scale = {
    --                 name = 'Scale',
    --                 desc = 'Set the scaling of the heads up display',
    --                 type = 'range',
    --                 order = 8,
    --                 min = 0.5,
    --                 max = 4.0,
    --                 step = 0.1,
    --                 get = function() return database:GetHeadsUpViewScale() end,
    --                 set = function(_, val) database:SetHeadsUpViewScale(val) end
    --             }
    --         }
    --     },
    --     raceview = {
    --         name = 'Race Info',
    --         type = 'group',
    --         order = 1,
    --         args = {
    --             enabled = {
    --                 name = 'Enabled',
    --                 desc = 'Enable the Race Info View',
    --                 type = 'toggle',
    --                 order = 1,
    --                 get = function() return database:GetRaceViewEnabled() end,
    --                 set = function(_, val) database:SetRaceViewEnabled(val) end
    --             },
    --             show = {
    --                 name = 'Show',
    --                 desc = 'Temporarily Show Race Info View (Useful for positioning',
    --                 type = 'execute',
    --                 order = 2,
    --                 func = function()
    --                     ---@class RaceView
    --                     local raceView = addon:GetModule('RaceView')
    --                     raceView:Toggle()
    --                 end
    --             },
    --             position = {
    --                 name = 'Position',
    --                 type = 'header',
    --                 order = 4
    --             },
    --             x = {
    --                 name = 'X',
    --                 type = 'range',
    --                 order = 5,
    --                 min = 0,
    --                 max = 6000,
    --                 step = 1,
    --                 get = function() return database:GetRaceViewPosition().X end,
    --                 set = function(_, val) database:SetRaceViewPositionX(val) end
    --             },
    --             y = {
    --                 name = 'Y',
    --                 type = 'range',
    --                 order = 6,
    --                 min = 0,
    --                 max = 6000,
    --                 step = 1,
    --                 get = function() return database:GetRaceViewPosition().Y end,
    --                 set = function(_, val) database:SetRaceViewPositionY(val) end
    --             },
    --         }
    --     }
    -- }
}

function options:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, settings)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

    addon:RegisterChatCommand('da', 'SlashCommand')
    addon:RegisterChatCommand('dynamicarchipelago', 'SlashCommand')
end

---@param msg string
function addon:SlashCommand(msg)
    if msg == '' then
        -- TODO: Open config
        return
    end

    if msg == 'debug' then
        ---@class Debug: AceModule
        local debug = addon:GetModule('Debug')
        debug:Enable()
        debug:Show()
    end
end

options:Enable()
