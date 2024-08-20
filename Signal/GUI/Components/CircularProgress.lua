local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CircularProgress: AceModule, ComponentModule
local circ = addon:NewModule('CircularProgress')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

---@class (exact) CircularProgressComponent: Component
---@field widget Frame
---@field scrollFrame ScrollFrame
---@field wedge Texture
---@field textures Texture[]
---@field clockwise boolean
---@field reverse boolean
---@field quadrant integer
---@field animation AnimationGroup
---@field aspectRatio number
---@field rotation Rotation
---@field value number
---@field SetValue function
---@field SetClockwise function
---@field SetReverse function
---@field SetTexture function
---@field SetVertexColor function
---@field SetColor function
circ.proto = {}

local cos, sin, pi2, halfpi = math.cos, math.sin, math.rad(360), math.rad(90)

function circ:Transform(tx, x, y, angle, aspect) -- Translates texture to x, y and rotates about its center
    local c, s = cos(angle), sin(angle)
    local y, oy = y / aspect, 0.5 / aspect
    local ULx, ULy = 0.5 + (x - 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x - 0.5) * s) * aspect
    local LLx, LLy = 0.5 + (x - 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x - 0.5) * s) * aspect
    local URx, URy = 0.5 + (x + 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x + 0.5) * s) * aspect
    local LRx, LRy = 0.5 + (x + 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x + 0.5) * s) * aspect
    tx:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

function circ.proto:SetValue(value)
    -- Correct invalid ranges, preferably just don't feed it invalid numbers
    if value > 1 then
        value = 1
    elseif value < 0 then
        value = 0
    end

    -- Reverse our normal behavior
    if self.reverse then
        value = 1 - value
    end

    -- Determine which quadrant we're in
    ---@diagnostic disable-next-line: unbalanced-assignments
    local q, quadrant = self.clockwise and (1 - value) or value -- 4 - floor(value / 0.25)
    if q >= 0.75 then
        quadrant = 1
    elseif q >= 0.5 then
        quadrant = 2
    elseif q >= 0.25 then
        quadrant = 3
    else
        quadrant = 4
    end

    if self.quadrant ~= quadrant then
        self.quadrant = quadrant
        -- Show/hide necessary textures if we need to
        if self.clockwise then
            for i = 1, 4 do
                self.textures[i]:SetShown(i < quadrant)
            end
        else
            for i = 1, 4 do
                self.textures[i]:SetShown(i > quadrant)
            end
        end
        -- Move scrollframe/wedge to the proper quadrant
        self.scrollFrame:Hide();
        self.scrollFrame:SetAllPoints(self.textures[quadrant])
        self.scrollFrame:Show();
    end

    -- Rotate the things
    local rads = value * pi2
    if not self.clockwise then rads = -rads + halfpi end

    circ:Transform(self.wedge, -0.5, -0.5, rads, self.aspectRatio)
    self.rotation:SetDuration(0.000001)
    self.rotation:SetEndDelay(2147483647)
    self.rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
    self.rotation:SetRadians(-rads);
    self.animation:Play();
end

function circ.proto:SetClockwise(clockwise)
    self.clockwise = clockwise
end

function circ.proto:SetReverse(reverse)
    self.reverse = reverse
end

-- Creates a function that calls a method on all textures at once
local function CreateTextureFunction(func, self, ...)
    return function(self, ...)
        for i = 1, 4 do
            local tx = self.textures[i]
            tx[func](tx, ...)
        end
        self.wedge[func](self.wedge, ...)
    end
end

-- Pass calls to these functions on our frame to its textures
local TextureFunctions = {
    SetTexture = CreateTextureFunction('SetTexture'),
    SetBlendMode = CreateTextureFunction('SetBlendMode'),
    SetVertexColor = CreateTextureFunction('SetVertexColor'),
}

---@return CircularProgressComponent
local function CreateSpinner()
    local progress = setmetatable({}, { __index = circ.proto })
    local spinner = CreateFrame('Frame', nil, UIParent)

    -- ScrollFrame clips the actively animating portion of the spinner
    local scrollframe = CreateFrame('ScrollFrame', nil, spinner)
    scrollframe:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
    scrollframe:SetPoint('TOPRIGHT')
    progress.scrollFrame = scrollframe

    local scrollchild = CreateFrame('frame', nil, scrollframe)
    scrollframe:SetScrollChild(scrollchild)
    scrollchild:SetAllPoints(scrollframe)

    -- Wedge thing
    local wedge = scrollchild:CreateTexture()
    wedge:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
    progress.wedge = wedge

    -- Top Right
    local trTexture = spinner:CreateTexture(nil, 'OVERLAY')
    trTexture:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
    trTexture:SetPoint('TOPRIGHT')
    trTexture:SetTexCoord(0.5, 1, 0, 0.5)

    -- Bottom Right
    local brTexture = spinner:CreateTexture(nil, 'OVERLAY')
    brTexture:SetPoint('TOPLEFT', spinner, 'CENTER')
    brTexture:SetPoint('BOTTOMRIGHT')
    brTexture:SetTexCoord(0.5, 1, 0.5, 1)

    -- Bottom Left
    local blTexture = spinner:CreateTexture(nil, 'OVERLAY')
    blTexture:SetPoint('TOPRIGHT', spinner, 'CENTER')
    blTexture:SetPoint('BOTTOMLEFT')
    blTexture:SetTexCoord(0, 0.5, 0.5, 1)

    -- Top Left
    local tlTexture = spinner:CreateTexture(nil, 'OVERLAY')
    tlTexture:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
    tlTexture:SetPoint('TOPLEFT')
    tlTexture:SetTexCoord(0, 0.5, 0, 0.5)

    -- /4|1\ -- Clockwise texture arrangement
    -- \3|2/ --

    progress.textures = { trTexture, brTexture, blTexture, tlTexture }
    progress.quadrant = nil                   -- Current active quadrant
    progress.clockwise = true                 -- fill clockwise
    progress.reverse = false                  -- Treat the provided value as its inverse, eg. 75% will display as 25%
    progress.aspectRatio = 1                  -- aspect ratio, width / height of spinner frame
    spinner:HookScript('OnSizeChanged', function(self, width, height)
        progress.wedge:SetSize(width, height) -- it's important to keep this texture sized correctly
        progress.aspectRatio = width / height -- required to calculate the texture coordinates
    end)

    for method, func in pairs(TextureFunctions) do
        progress[method] = func
    end

    local group = wedge:CreateAnimationGroup()
    local rotation = group:CreateAnimation('Rotation')
    progress.rotation = rotation

    progress.animation = group
    progress.animation:SetScript('OnFinished', function()
        progress.animation:Play()
    end)

    progress.widget = spinner

    return progress
end

---@return CircularProgressComponent
function circ:Create()
    local spinner = CreateSpinner()
    spinner.widget:SetPoint('CENTER')
    spinner.widget:SetSize(64, 64)
    spinner:SetTexture(utils:GetMediaDir() .. 'Art\\circular_progress')

    spinner:SetClockwise(true)
    spinner:SetReverse(false)

    local bgTex = spinner.widget:CreateTexture(nil, 'ARTWORK')
    bgTex:SetAllPoints(spinner.widget)
    bgTex:SetTexture(utils:GetMediaDir() .. 'Art\\circular_progress')
    bgTex:SetVertexColor(1, 1, 1, 0.25)

    ---@param color ColorMixin
    spinner.SetColor = function(_, color)
        spinner:SetVertexColor(unpack(color))

        local rgbaColor = CreateColor(unpack(color))
        local hexColor = rgbaColor:GenerateHexColor()
        local lighterColor = utils:LightenColor(hexColor, -50)
        local newColor = CreateColorFromHexString(lighterColor)
        bgTex:SetVertexColor(newColor.r, newColor.g, newColor.b, 1.0)
    end

    return spinner
end

circ:Enable()
