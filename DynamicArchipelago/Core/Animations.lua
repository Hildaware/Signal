local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Animations: AceModule
local anim = addon:NewModule('Animations')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

--#region Animations

---@param frame Frame
---@param alphaModifier number?
function anim:FadeOut(frame, alphaModifier)
    local currentAlpha = frame:GetAlpha()
    alphaModifier = alphaModifier or 0.01
    C_Timer.NewTicker(0.001,
        function(ticker)
            currentAlpha = currentAlpha - alphaModifier
            frame:SetAlpha(max(currentAlpha, 0.0))

            -- Anim Finished
            if frame:GetAlpha() <= 0.0 then
                frame:SetAlpha(0.0)
                frame:Hide()
                ticker:Cancel()
            end
        end,
        250)
end

---@param frame Frame
---@param alphaModifier number?
function anim:FadeIn(frame, alphaModifier)
    local currentAlpha = frame:GetAlpha()
    alphaModifier = alphaModifier or 0.01
    C_Timer.NewTicker(0.001,
        function(ticker)
            currentAlpha = currentAlpha + alphaModifier
            frame:SetAlpha(min(currentAlpha, 1.0))

            -- Anim Finished
            if frame:GetAlpha() >= 1.0 then
                frame:SetAlpha(1.0)
                ticker:Cancel()
            end
        end,
        250)
end

---@param frame Frame
---@param expectedWidth number
---@param widthGrowthModifier number?
---@return boolean
function anim:GrowHorizontal(frame, expectedWidth, widthGrowthModifier)
    widthGrowthModifier = widthGrowthModifier or 4

    local currentWidth = frame:GetWidth()

    if expectedWidth and currentWidth >= expectedWidth then
        frame:SetWidth(expectedWidth)
        return true
    end

    if currentWidth < expectedWidth then
        local newWidth = currentWidth + widthGrowthModifier
        frame:SetWidth(min(newWidth, expectedWidth))
    end

    return false
end

---@param frame Frame
---@param expectedWidth number
---@param widthRegressionModifier number?
---@return boolean
function anim:ShrinkHorizontal(frame, expectedWidth, widthRegressionModifier)
    widthRegressionModifier = widthRegressionModifier or 4

    local currentWidth = frame:GetWidth()

    if expectedWidth and currentWidth <= expectedWidth then
        frame:SetWidth(expectedWidth)
        return true
    end

    if currentWidth > expectedWidth then
        local newWidth = currentWidth - widthRegressionModifier
        frame:SetWidth(max(newWidth, expectedWidth))
    end

    return false
end

--#endregion



anim:Enable()
