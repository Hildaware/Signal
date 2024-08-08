local addonName = ...

---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceHook-3.0

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class DynamicArchipelagoStatus
---@field isReady boolean
addon.status = {
    isReady = false
}

function addon:OnCompartmentClick(context)
    local button = context.buttonName
    if button == 'RightButton' then
        database:SetWidgetState(not database:GetWidgetState())
    else
        if IsShiftKeyDown() then
            print('Shift')
        else
            -- _G['InterfaceOptionsFrame_OpenToCategory'](options.optionsFrame)
        end
    end
end

function addon:OnInitialize()
    _G['AddonCompartmentFrame']:RegisterAddon({
        text = "Dynamic Archipelago",
        icon = "",
        registerForAnyClick = true,
        notCheckable = true,
        func = addon.OnCompartmentClick,
        funcOnEnter = function()
            GameTooltip:SetOwner(_G['AddonCompartmentFrame'], 'ANCHOR_TOPLEFT')
            GameTooltip:AddLine("Dynamic Archipelago")
            GameTooltip:AddLine("|cffeda55fClick|r |cFFFFFFFFto open the options configuration.|r")
            GameTooltip:AddLine("|cffeda55fRight-Click|r |cFFFFFFFFto move the addon.|r")
            GameTooltip:AddLine("|cffeda55fShift-Click|r |cFFFFFFFFto open the Stats window.|r")
            GameTooltip:Show()
        end,
        funcOnLeave = function()
            GameTooltip:Hide()
        end
    })
end

addon:Enable()
