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
    return 'Interface\\Addons\\Signal\\Media\\'
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

---@param time number
---@return string
function utils:GetReadableTime(time)
    local days = floor(time / 86400)
    local hours = floor(mod(time, 86400) / 3600)
    local minutes = floor(mod(time, 3600) / 60)
    local seconds = floor(mod(time, 60))
    return format("%d:%02d:%02d:%02d", days, hours, minutes, seconds)
end

---@param engClass string
---@return string
function utils:GetClassColor(engClass)
    local _, _, _, classColor = GetClassColor(engClass)
    return classColor
end

---@param number number
---@param decimalPoints number
---@return number
function utils:Round(number, decimalPoints)
    if type(number) ~= 'number' then
        return number
    end

    if decimalPoints and decimalPoints > 0 then
        local mult = 10 ^ decimalPoints
        return floor(number * mult + 0.5) / mult
    end

    return floor(number + 0.5)
end

local CS = CreateFrame("ColorSelect")

---@class RGBHSV
---@field r number
---@field g number
---@field b number
---@field h number
---@field s number
---@field v number

---@param percentage number
---@return RGBHSV
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

---@param colorA ColorMixin
---@param colorB ColorMixin
---@param percentage number
---@return ColorMixin
function utils:GetGradientByPercentage(colorA, colorB, percentage)
    local color = self:GetSmudgeColorRGB(colorA, colorB, percentage)
    return { color.r, color.g, color.b, 1.0 }
end

---@param hexA string
---@param hexB string
---@param percentage number
---@return ColorMixin
function utils:GetMergedColorPercentage(hexA, hexB, percentage)
    local colorA = CreateColorFromRGBHexString(hexA)
    local colorB = CreateColorFromRGBHexString(hexB)
    local color = self:GetSmudgeColorRGB(colorA, colorB, percentage)
    return { color.r, color.g, color.b, 1.0 }
end

local function round(num)
    return math.floor(num + 0.5)
end

local function roundH(num)
    return math.floor((num * 100) + 0.5) / 100
end

---@param hexColor string
---@param amt number
---@return string
function utils:LightenColor(hexColor, amt)
    local r, g, b, a
    local hex = hexColor:gsub("#", "")
    if #hex < 6 then
        local t = {}
        for i = 1, #hex do
            local char = hex:sub(i, i)
            t[i] = char .. char
        end
        hex = table.concat(t)
    end
    r = tonumber(hex:sub(1, 2), 16) / 255
    g = tonumber(hex:sub(3, 4), 16) / 255
    b = tonumber(hex:sub(5, 6), 16) / 255
    if #hex ~= 6 then
        a = roundH(tonumber(hex:sub(7, 8), 16) / 255)
    end

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local c = max - min
    -----------------------------
    -- Hue
    local h
    if c == 0 then
        h = 0
    elseif max == r then
        h = ((g - b) / c) % 6
    elseif max == g then
        h = ((b - r) / c) + 2
    elseif max == b then
        h = ((r - g) / c) + 4
    end
    h = h * 60
    -----------------------------
    -- Luminance
    local l = (max + min) * 0.5
    -----------------------------
    -- Saturation
    local s
    if l <= 0.5 then
        s = c / (l * 2)
    elseif l > 0.5 then
        s = c / (2 - (l * 2))
    end
    -----------------------------
    local H, S, L, A
    H = round(h) / 360
    S = round(s * 100) / 100
    L = round(l * 100) / 100

    amt = amt / 100
    if L + amt > 1 then
        L = 1
    elseif L + amt < 0 then
        L = 0
    else
        L = L + amt
    end

    local R, G, B
    if S == 0 then
        R, G, B = round(L * 255), round(L * 255), round(L * 255)
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then
                return p + (q - p) * (6 * t)
            end
            if t < 1 / 2 then
                return q
            end
            if t < 2 / 3 then
                return p + (q - p) * (2 / 3 - t) * 6
            end
            return p
        end
        local q
        if L < 0.5 then
            q = L * (1 + S)
        else
            q = L + S - (L * S)
        end
        local p = 2 * L - q
        R = round(hue2rgb(p, q, (H + 1 / 3)) * 255)
        G = round(hue2rgb(p, q, H) * 255)
        B = round(hue2rgb(p, q, (H - 1 / 3)) * 255)
    end

    if a ~= nil then
        A = round(a * 255)
        return string.format('%.2x%.2x%.2x%.2x', R, G, B, A)
    else
        return string.format('%.2x%.2x%.2x', R, G, B)
    end
end

---comment
---@param frame Frame
---@param color ColorMixin
function utils:DebugFrame(frame, color)
    local tex = frame:CreateTexture(nil, 'BACKGROUND')
    tex:SetAllPoints(frame)
    tex:SetColorTexture(color.r, color.g, color.b, color.a or 1)
end

utils:Enable()
