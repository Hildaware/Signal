local addonName = ...

---@class DynamicArchipelago: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
local Type = 'Call To Arms'
local Module = 'CallToArms'

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Database: AceModule
local database = addon:GetModule('Database')

---@class Options: AceModule
local options = addon:GetModule('Options')

---@class PeninsulaBase: AceModule
local baseFrame = addon:GetModule('PeninsulaBase')

---@class NotificationWidgetBase: AceModule
local widgetBase = addon:GetModule('NotificationWidget')

---@class CallToArms: NotificationType
---@field eventFrame Frame
---@field elapsedSinceUpdate number
---@field rewards table<number, CTARewards>
local cta = widgetBase:New(Module, Type)

local ITEM_DEFAULT_HEIGHT = 50
local UPDATE_INTERVAL = 30

---@enum InstanceType
local INSTANCE_TYPE = {
    DUNGEON = 1,
    RAID = 2,
}

---@class CTARewards
---@field id integer
---@field type InstanceType
---@field time integer
---@field name string
---@field eligible boolean
---@field tank boolean
---@field healer boolean
---@field dps boolean
---@field unavailable boolean
---@field isNew boolean

---@class CallToArmsData
---@field rewards CTARewards
---@field time integer
---@field playerId string
---@field name string
---@field class string
---@field type string
---@field message string

---@class CallToArmsContent : Frame
---@field message FontString

---@class CallToArmsIcon : Frame
---@field texture Texture

---@class (exact) CallToArmsWidget : NotificationWidget
---@field content CallToArmsContent
---@field icon CallToArmsIcon
---@field data CallToArmsData
cta.proto = {}

---@param value boolean
function database:SetCallToArmsEnabled(value)
    database.internal.global.CallToArms.Enabled = value
end

---@return boolean
function database:GetCallToArmsEnabled()
    return database.internal.global.CallToArms.Enabled
end

function cta.proto:Wipe()
    self.content:Hide()
    self.content:SetParent(nil)
    self.content:ClearAllPoints()
end

---@param instanceId number
---@param instanceName string
---@param roleShortage integer
---@param instanceType InstanceType
function cta:ParseRewards(instanceId, instanceName, roleShortage, instanceType)
    local eligible, forTank, forHealer, forDamage, itemCount = GetLFGRoleShortageRewards(instanceId, roleShortage)
    if not eligible then return end

    local isNew = false
    local lastTime = GetTime()
    if self.rewards[instanceId] ~= nil then
        if self.rewards[instanceId].time < GetTime() - 600 then
            lastTime = self.rewards[instanceId].time
            isNew = true
        else
            lastTime = self.rewards[instanceId].time
        end
    else
        isNew = true
    end

    self.rewards[instanceId] = {
        id = instanceId,
        name = instanceName,
        type = instanceType,
        time = lastTime,
        isNew = isNew,
        eligible = eligible,
        tank = forTank,
        healer = forHealer,
        dps = forDamage,
        unavailable = not forTank and not forHealer and not forDamage,
        itemCount = itemCount
    }
end

function cta:OnUpdate()
    for i = 1, GetNumRandomDungeons() do
        local id, name = GetLFGRandomDungeonInfo(i)
        -- for x = 1, LFG_ROLE_NUM_SHORTAGE_TYPES do
        self:ParseRewards(id, name, 1, INSTANCE_TYPE.DUNGEON)
        -- end
    end

    for i = 1, GetNumRFDungeons() do
        local id, name = GetRFDungeonInfo(i)
        -- for x = 1, LFG_ROLE_NUM_SHORTAGE_TYPES do
        self:ParseRewards(id, name, 1, INSTANCE_TYPE.RAID)
        -- end
    end

    self:Trigger()
end

function cta:OnInitialize()
    self.rewards = {}
    self.elapsedSinceUpdate = 0

    self:RegisterPool(self._DoCreate, self._DoReset)

    local eventFrame = CreateFrame('Frame', nil, UIParent)
    eventFrame:SetScript('OnUpdate', function(_, elapsed)
        if self.elapsedSinceUpdate > UPDATE_INTERVAL then
            self:OnUpdate()
            self.elapsedSinceUpdate = 0
        else
            self.elapsedSinceUpdate = self.elapsedSinceUpdate + elapsed
        end
    end)


    -- options
    ---@type AceConfig.OptionsTable
    local ctaOptions = {
        name = 'Call To Arms Options',
        type = 'group',
        order = 3,
        args = {
            enable = {
                name = 'Enable',
                desc = 'Enable the Call To Arms notifications',
                type = 'toggle',
                order = 1,
                get = function() return database:GetCallToArmsEnabled() end,
                set = function(_, val) database:SetCallToArmsEnabled(val) end
            }
        }
    }

    options:AddSettings('callToArmsOptions', ctaOptions)

    -- db
    if database.internal.global.CallToArms == nil then
        database.internal.global.CallToArms = {
            Enabled = true
        }
    end
end

function cta:Trigger()
    ---@type CTARewards[]
    local newRewards = {}

    for _, v in pairs(self.rewards) do
        if v.isNew then
            table.insert(newRewards, v)
            v.isNew = false
        end
    end

    if #newRewards == 0 then return end

    local filteredRewards = {}
    for _, reward in pairs(newRewards) do
        if reward.tank or reward.healer or reward.dps then
            table.insert(filteredRewards, reward)
        end
    end

    if #filteredRewards == 0 then return end

    local time = GetTime()
    local widget = baseFrame:Create(15) -- TODO: Config?
    widget:SetType(Type)
    widget:WithoutIcon()

    ---@type CallToArmsWidget
    local ctaFrame = self:Create()

    for i = 1, #filteredRewards do
        local reward = filteredRewards[i]
        local frame = self:CreateInstanceWidget(reward)
        frame:SetParent(ctaFrame.content)
        frame:ClearAllPoints()
        frame:SetPoint('TOPLEFT', ctaFrame.content, 'TOPLEFT', 0, -((i - 1) * ITEM_DEFAULT_HEIGHT))
        frame:Show()
    end

    local height = (#filteredRewards * (ITEM_DEFAULT_HEIGHT)) + 24
    ctaFrame.content:SetHeight(height)
    ctaFrame.content:Show()

    widget:SetContent(ctaFrame.content)
    widget:SetChild(ctaFrame)

    widget.height = height

    widget.data = {}

    events:SendMessage('DYNAMIC_ARCHIPELAGO_ADD_CORE_ITEM', widget)
end

---comment
---@param reward CTARewards
function cta:CreateInstanceWidget(reward)
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetPoint('CENTER')
    frame:SetWidth(baseFrame.baseProto:GetWidgetWidth())
    frame:SetHeight(ITEM_DEFAULT_HEIGHT)

    local iconFrameWidth = 0
    local iconFrame = CreateFrame('Frame', nil, frame)
    iconFrame:SetHeight(ITEM_DEFAULT_HEIGHT)
    iconFrame:SetPoint('LEFT', frame, 'LEFT')

    local icons = {}
    if reward.tank then
        iconFrameWidth = iconFrameWidth + ITEM_DEFAULT_HEIGHT - 12
        local hIcon = iconFrame:CreateTexture(nil, 'BACKGROUND')
        hIcon:SetPoint('LEFT', iconFrame, 'LEFT')
        hIcon:SetSize(ITEM_DEFAULT_HEIGHT - 16, ITEM_DEFAULT_HEIGHT - 16)
        hIcon:SetTexture('Interface\\LFGFrame\\UILFGPrompts')
        hIcon:SetAtlas('UI-LFG-RoleIcon-Tank')

        table.insert(icons, hIcon)
    end

    if reward.healer then
        iconFrameWidth = iconFrameWidth + ITEM_DEFAULT_HEIGHT - 12
        local hIcon = iconFrame:CreateTexture(nil, 'BACKGROUND')
        hIcon:SetPoint('LEFT', icons[1] ~= nil and icons[1] or iconFrame, 'LEFT')
        hIcon:SetSize(ITEM_DEFAULT_HEIGHT - 16, ITEM_DEFAULT_HEIGHT - 16)
        hIcon:SetTexture('Interface\\LFGFrame\\UILFGPrompts')
        hIcon:SetAtlas('UI-LFG-RoleIcon-Healer')

        table.insert(icons, hIcon)
    end

    if reward.dps then
        iconFrameWidth = iconFrameWidth + ITEM_DEFAULT_HEIGHT - 12
        local hIcon = iconFrame:CreateTexture(nil, 'BACKGROUND')
        hIcon:SetPoint('LEFT', icons[1] ~= nil and icons[1] or icons[2] ~= nil and icons[2] or iconFrame, 'LEFT')
        hIcon:SetSize(ITEM_DEFAULT_HEIGHT - 16, ITEM_DEFAULT_HEIGHT - 16)
        hIcon:SetTexture('Interface\\LFGFrame\\UILFGPrompts')
        hIcon:SetAtlas('UI-LFG-RoleIcon-DPS')
    end

    iconFrame:SetWidth(iconFrameWidth)

    local rewardName = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
    rewardName:SetJustifyH('LEFT')
    rewardName:SetJustifyV('MIDDLE')
    rewardName:SetPoint('LEFT', iconFrame, 'RIGHT', 4, 0)
    rewardName:SetText(reward.name)

    frame:Hide()

    return frame
end

---@return CallToArmsWidget
function cta:_DoCreate()
    local i = setmetatable({}, { __index = cta.proto })

    local baseWidth = baseFrame.baseProto:GetWidgetWidth()

    local contentFrame = CreateFrame('Frame', nil, UIParent)
    contentFrame:SetWidth(baseWidth)
    contentFrame:SetHeight(ITEM_DEFAULT_HEIGHT)
    contentFrame:Hide()
    contentFrame:EnableMouse(true)

    contentFrame:SetScript('OnMouseDown', function(_, button)
        if button == 'LeftButton' then
            PVEFrame_ToggleFrame('GroupFinderFrame', _G['LFDParentFrame'])
        end
    end)

    i.content = contentFrame

    return i
end

function cta:_DoReset()
    -- TODO
end

cta:Enable()
