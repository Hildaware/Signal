local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@cast addon +AceHook-3.0

function addon:OnInitialize()
    -- TODO: Create 'art' - top / bottom caps

    -- _G['AddonCompartmentFrame']:RegisterAddon({
    --     text = "Ride the Wind",
    --     icon = "Interface\\AddOns\\RideTheWind\\Media\\logo.blp",
    --     registerForAnyClick = true,
    --     notCheckable = true,
    --     func = addon.OnCompartmentClick,
    --     funcOnEnter = function()
    --         GameTooltip:SetOwner(_G['AddonCompartmentFrame'], 'ANCHOR_TOPRIGHT')
    --         GameTooltip:AddLine("Ride the Wind")
    --         GameTooltip:AddLine("|cffeda55fClick|r |cFFFFFFFFto open the options configuration.|r")
    --         GameTooltip:AddLine("|cffeda55fRight-Click|r |cFFFFFFFFto toggle the Zone View window.|r")
    --         GameTooltip:AddLine("|cffeda55fShift-Click|r |cFFFFFFFFto open the Stats window.|r")
    --         GameTooltip:Show()
    --     end,
    --     funcOnLeave = function()
    --         GameTooltip:Hide()
    --     end
    -- })
end
