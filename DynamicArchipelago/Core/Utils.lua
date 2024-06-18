local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
local random = math.random

---@class Utils: AceModule
local utils = addon:NewModule('Utils')

---@class Enums: AceModule
local enums = addon:GetModule('Enums')

---@class Session: AceModule
local session = addon:GetModule('Session')

---@class Resolver: AceModule
local resolver = addon:GetModule('Resolver')

---@return string
function utils:GetMediaDir()
    return 'Interface\\Addons\\DynamicArchipelago\\Media\\'
end

---@return string
function utils:GenerateId()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    ---@diagnostic disable-next-line: redundant-return-value
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function utils.GetTableValue(table, value)
    for _, val in pairs(table) do
        if val == value then
            return val
        end
    end
    return nil
end

function utils:DeepFind(table, findKey)
    for key, value in pairs(table) do
        if type(value) == 'table' then
            return self:DeepFind(value, findKey)
        end
        if key == findKey then
            print('Found: ' .. findKey, value)
        end
    end
end

---@return string
function utils:GetReadableTime()
    local time = time()
    local minutes = floor(mod(time, 3600) / 60)
    local seconds = floor(mod(time, 60))
    local milliseconds = floor(mod(time, 6))
    return format("%02d:%02d:%02d", minutes, seconds, milliseconds)
end

---@param engClass string
---@return string
function utils:GetClassColor(engClass)
    local _, _, _, classColor = GetClassColor(engClass)
    return classColor
end

function utils:Round(number, decimalPoints)
    local precision = 10 ^ (decimalPoints or 0)
    number = number + (precision / 2)
    return math.floor(number / precision) * precision
end

local CS = CreateFrame("ColorSelect")

function utils:GetSmudgeColorRGB(colorA, colorB, percentage)
    CS:SetColorRGB(colorA.r, colorA.g, colorA.b)
    colorA.h, colorA.s, colorA.v = CS:GetColorHSV()
    CS:SetColorRGB(colorB.r, colorB.g, colorB.b)
    colorB.h, colorB.s, colorB.v = CS:GetColorHSV()
    local colorC = {}
    --check if the angle between the two H values is > 180
    if abs(colorA.h - colorB.h) > 180 then
        local angle = (360 - abs(colorA.h - colorB.h)) * percentage
        if colorA.h < colorB.h then
            colorC.h = floor(colorA.h - angle)
            if colorC.h < 0 then
                colorC.h = 360 + colorC.h
            end
        else
            colorC.h = floor(colorA.h + angle)
            if colorC.h > 360 then
                colorC.h = colorC.h - 360
            end
        end
    else
        colorC.h = floor(colorA.h - (colorA.h - colorB.h) * percentage)
    end
    colorC.s = colorA.s - (colorA.s - colorB.s) * percentage
    colorC.v = colorA.v - (colorA.v - colorB.v) * percentage
    CS:SetColorHSV(colorC.h, colorC.s, colorC.v)
    colorC.r, colorC.g, colorC.b = CS:GetColorRGB()
    return colorC
end

utils:Enable()
