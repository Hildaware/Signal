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
---@param expectedHeight number?
---@param expectedWidth number?
---@param heightGrowthModifier number?
---@param widthGrowthModifier number?
---@return boolean
function anim:Grow(frame, expectedHeight, expectedWidth, heightGrowthModifier, widthGrowthModifier)
    heightGrowthModifier = heightGrowthModifier or 4
    widthGrowthModifier = widthGrowthModifier or 4

    local currentHeight = frame:GetHeight(true)
    local currentWidth = frame:GetWidth(true)

    if (expectedWidth and currentWidth >= expectedWidth) and (expectedHeight and currentHeight >= expectedHeight) then
        frame:SetWidth(expectedWidth)
        frame:SetHeight(expectedHeight)
        return true
    end

    if expectedHeight ~= nil then
        if currentHeight < expectedHeight then
            local newHeight = currentHeight + heightGrowthModifier
            frame:SetHeight(min(newHeight, expectedHeight))
        end
    end

    if expectedWidth ~= nil then
        if currentWidth < expectedWidth then
            local newWidth = currentWidth + widthGrowthModifier
            frame:SetWidth(min(newWidth, expectedWidth))
        end
    end

    return false
end

---@param frame Frame
---@param expectedHeight number?
---@param expectedWidth number?
---@param heightRegressionModifier number?
---@param widthRegressionModifier number?
---@return boolean
function anim:Shrink(frame, expectedHeight, expectedWidth, heightRegressionModifier, widthRegressionModifier)
    heightRegressionModifier = heightRegressionModifier or 4
    widthRegressionModifier = widthRegressionModifier or 4

    local currentHeight = frame:GetHeight(true)
    local currentWidth = frame:GetWidth(true)

    if (expectedWidth and currentWidth <= expectedWidth) and (expectedHeight and currentHeight <= expectedHeight) then
        frame:SetWidth(expectedWidth)
        frame:SetHeight(expectedHeight)
        return true
    end

    if expectedHeight ~= nil then
        if currentHeight > expectedHeight then
            local newHeight = currentHeight - heightRegressionModifier
            frame:SetHeight(max(newHeight, expectedHeight))
        end
    end

    if expectedWidth ~= nil then
        if currentWidth > expectedWidth then
            local newWidth = currentWidth - widthRegressionModifier
            frame:SetWidth(max(newWidth, expectedWidth))
        end
    end

    return false
end

--#endregion



anim:Enable()
