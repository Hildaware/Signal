---@diagnostic disable: assign-type-mismatch
local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Island: AceModule
local island = addon:NewModule('Island')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Utils: AceModule
local utils = addon:GetModule('Utils')

-- TODO: Configurable
local baseWidth = 64
local dataFilledWidth = 128
local hoverWidth = 256 -- 256?
-- Height will always be width / 4

ISLAND_NAME = {
    SMALL = 'Small',
    FULL = 'Full'
}

ISLAND_TYPE = {
    SMALL = 1,
    FULL = 2
}

ISLAND_BASE_PADDING = 4

---@class (exact) IslandLife
---@field widget IslandFrame
---@field SetDataContent function
---@field EnableIsland function
---@field SetWidgetSize function
island.proto = {}

--#region IslandLife

---@param islandType number
function island.proto:EnableIsland(islandType)
    local content = self.widget.Content
    local widgetSize = dataFilledWidth

    ---@type BaseLargeIsland|BaseSmallIsland
    local enableFrame = nil

    if islandType == ISLAND_TYPE.SMALL then
        enableFrame = content[ISLAND_NAME.SMALL]
        widgetSize = dataFilledWidth
    end
    if islandType == ISLAND_TYPE.FULL then
        enableFrame = content[ISLAND_NAME.FULL]
        widgetSize = hoverWidth
    end

    if enableFrame == nil then return end

    self:SetWidgetSize(widgetSize)

    enableFrame.widget:SetParent(content.widget)
    enableFrame.widget:SetAllPoints(content.widget)
    enableFrame.widget:Show()
    enableFrame:Connect()

    if content.OnClick ~= nil then
        self.widget:SetMouseClickEnabled(true)
        self.widget:SetScript('OnMouseDown', function()
            content.OnClick()
        end)
    end
end

function island.proto:SetWidgetSize(size)
    self.widget:SetSize(size, size / 4)
end

---@param content IslandContent
function island.proto:SetDataContent(content)
    self.widget.Content.Small = content.Small
    self.widget.Content.Full = content.Full
    self.widget.Content.OnClick = content.OnClick

    self:EnableIsland(ISLAND_TYPE.SMALL)
end

--#endregion

--#region Island

function island:OnInitialize()
    self:Create()

    ---@type LocationWidget
    local location = addon:GetModule('LocationWidget')
    self.data:SetDataContent(location:Create())
end

function island:Create()
    self.data = setmetatable({}, { __index = island.proto })

    local position = database:GetWidgetPosition()

    ---@type IslandFrame
    local main = CreateFrame('Frame', nil, UIParent)
    main:SetWidth(baseWidth)
    main:SetHeight(baseWidth / 4)
    main:SetPoint('CENTER')
    -- main:SetPoint('CENTER', UIParent, 'BOTTOM', position.X, position.Y)

    local animOut = main:CreateAnimationGroup('Grow')
    local grow = animOut:CreateAnimation('Scale')
    grow:SetDuration(0.1)
    grow:SetScaleFrom(1.0, 1.0)
    grow:SetScaleTo(2.0, 2.0)
    animOut:SetScript('OnFinished', function()
        self.data:EnableIsland(ISLAND_TYPE.FULL)
    end)

    main.animationOut = animOut

    local animIn = main:CreateAnimationGroup('Grow')
    local shrink = animIn:CreateAnimation('Scale')
    shrink:SetDuration(0.1)
    shrink:SetScaleFrom(1.0, 1.0)
    shrink:SetScaleTo(0.5, 0.5)
    animIn:SetScript('OnFinished', function()
        self.data:EnableIsland(ISLAND_TYPE.SMALL)
    end)

    main.animationIn = animIn

    main:SetScript('OnEnter', function()
        self.data.widget.Content.Small.widget:Hide()
        self.data.widget.Content.Small:Disconnect()
        self.data.widget.animationOut:Play()
    end)

    main:SetScript('OnLeave', function()
        self.data.widget.Content.Full.widget:Hide()
        self.data.widget.Content.Full:Disconnect()
        self.data.widget.animationIn:Play()
    end)

    local bgTex = main:CreateTexture(nil, 'ARTWORK')
    bgTex:SetAllPoints(main)
    bgTex:SetColorTexture(0, 0, 0, 0.75)

    local mask = main:CreateMaskTexture()
    mask:SetAllPoints(bgTex)
    mask:SetTexture(utils:GetMediaDir() .. 'Art\\island_mask', 'CLAMPTOBLACKADDITIVE',
        'CLAMPTOBLACKADDITIVE')
    bgTex:AddMaskTexture(mask)

    ---@type AnimatedFrame
    local content = CreateFrame('Frame', nil, main)
    content:SetAllPoints(main)

    main.Content = {
        widget = content,
        Small = nil,
        Full = nil
    }

    self.data.widget = main
end

--#endregion

island:Enable()
