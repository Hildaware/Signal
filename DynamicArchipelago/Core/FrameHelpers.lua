local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local Masque = LibStub('Masque', true)

---@class FrameHelpers: AceModule
local helpers = addon:NewModule('FrameHelpers')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

helpers.data = {
    masqueGroup = nil
}

function helpers:OnInitialize()
    if not Masque then return end

    ---@diagnostic disable-next-line: undefined-field
    self.data.masqueGroup = Masque:Group('Dynamic Archipelago')
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

---@return CircularProgress
function helpers:CreateCircularProgressFrame()
    ---@class CircularProgressFrame: AceModule
    local circ = addon:GetModule('CircularProgressFrame')

    local prog = circ:CreateSpinner()
    prog.widget:SetPoint('CENTER')
    prog.widget:SetSize(64, 64)
    prog:SetTexture(utils:GetMediaDir() .. 'Art\\circular_progress')

    prog:SetClockwise(true)
    prog:SetReverse(false)

    local bgTex = prog.widget:CreateTexture(nil, 'ARTWORK')
    bgTex:SetAllPoints(prog.widget)
    bgTex:SetTexture(utils:GetMediaDir() .. 'Art\\circular_progress')
    bgTex:SetVertexColor(1, 1, 1, 0.25)

    return prog
end

function helpers:ApplyMasqueGroup(frame)
    if self.data.masqueGroup == nil then return end

    ---@diagnostic disable-next-line: undefined-field
    self.data.masqueGroup:AddButton(frame)
end

helpers:Enable()
