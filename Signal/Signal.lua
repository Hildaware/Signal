local addonName = ...

---@class Signal: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceHook-3.0

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Options: AceModule
local options = addon:GetModule('Options')

---@class SignalStatus
---@field isReady boolean
addon.status = {
    isReady = false
}

function addon:OnCompartmentClick(context)
    local button = context.buttonName
    if button == 'RightButton' then
        database:SetWidgetState(not database:GetWidgetState())
    else
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    end
end

function addon:OnInitialize()
    _G['AddonCompartmentFrame']:RegisterAddon({
        text = "Signal",
        icon = "Interface\\AddOns\\Signal\\Media\\Art\\logo",
        registerForAnyClick = true,
        notCheckable = true,
        func = addon.OnCompartmentClick,
        funcOnEnter = function()
            GameTooltip:SetOwner(_G['AddonCompartmentFrame'], 'ANCHOR_TOPLEFT')
            GameTooltip:AddLine("Signal")
            GameTooltip:AddLine("|cffeda55fClick|r |cFFFFFFFFto open the options configuration.|r")
            GameTooltip:AddLine("|cffeda55fRight-Click|r |cFFFFFFFFto move the addon.|r")
            GameTooltip:Show()
        end,
        funcOnLeave = function()
            GameTooltip:Hide()
        end
    })
end

addon:Enable()
