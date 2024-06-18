local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local Masque = LibStub('Masque', true)

---@class FrameHelpers: AceModule
local helpers = addon:NewModule('FrameHelpers')

helpers.data = {
    masqueGroup = nil
}

function helpers:OnInitialize()
    if not Masque then return end

    ---@diagnostic disable-next-line: undefined-field
    self.data.masqueGroup = Masque:Group('Dynamic Archipelago')
end

--- Builds the Event Frame for a Base Island.
---@param parent BaseIsland
---@param enableFunc function
---@param disableFunc function?
---@return IslandEventFrame
function helpers:CreateIslandEventFrame(parent, enableFunc, disableFunc)
    ---@type IslandEventFrame
    local eventFrame = CreateFrame('Frame', nil, parent)
    eventFrame.lastUpdated = 0

    eventFrame.OnEnable = function()
        eventFrame:SetScript('OnUpdate', function(eFrame, elapsed)
            enableFunc(eFrame, elapsed)
        end)
    end

    eventFrame.OnDisable = function()
        if disableFunc ~= nil then
            eventFrame:SetScript('OnUpdate', function(eFrame, elapsed)
                disableFunc()
            end)
        else
            eventFrame:SetScript('OnUpdate', nil)
        end
    end

    parent.eventFrame = eventFrame
    return eventFrame
end

---@param iconId number
---@return Frame
function helpers:CreateIconFrame(iconId)
    local main = CreateFrame('Frame', nil, UIParent)
    main:SetPoint('CENTER')

    local bgTex = main:CreateTexture(nil, 'ARTWORK')
    bgTex:SetAllPoints(main)
    bgTex:SetTexture(iconId)
    bgTex:SetTexCoord(.15, .85, .15, .85)

    local mask = main:CreateMaskTexture()
    mask:SetAllPoints(bgTex)
    mask:SetTexture('Interface/CHARACTERFRAME/TempPortraitAlphaMask', 'CLAMPTOBLACKADDITIVE',
        'CLAMPTOBLACKADDITIVE')
    bgTex:AddMaskTexture(mask)

    return main
end

helpers:Enable()


function helpers:ApplyMasqueGroup(frame)
    if self.data.masqueGroup == nil then return end

    ---@diagnostic disable-next-line: undefined-field
    self.data.masqueGroup:AddButton(frame)
end
