---@meta

--[[
    Utilize this file specifically for telling the IDE that the following functions are legit.
    It literally does nothing but make the squigglies go bye bye.
]]

--#region External

---@param questId number
---@return number
function GetQuestLogRewardXP(questId) end

---@param hex string
---@return ColorMixin
function CreateColorFromRGBHexString(hex) end

--#region ObjectPoolMixin

---@class ObjectPoolMixin
local ObjectPoolMixin = {}

---@param creationFunc function
---@param resetterFunc? function
---@return ObjectPoolMixin
function CreateObjectPool(creationFunc, resetterFunc) end

---@generic T
---@return T
function ObjectPoolMixin:Acquire() end

---@generic T
---@param widget T
function ObjectPoolMixin:Release(widget) end

function ObjectPoolMixin:ReleaseAll() end

---@return number
function ObjectPoolMixin:EnumerateActive() end

---@return number
function ObjectPoolMixin:EnumerateInactive() end

---@generic T
---@param current T
---@return T
function ObjectPoolMixin:GetNextActive(current) end

---@generic T
---@param current T
---@return T
function ObjectPoolMixin:GetNextInActive(current) end

---@generic T
---@param widget T
---@return boolean
function ObjectPoolMixin:IsActive(widget) end

function ObjectPoolMixin:SetResetDisallowedIfNew() end

--#endregion


--#endregion

--#region Internal

--#region Components

---@class (exact) ComponentModule
---@field Create function

---@class (exact) Component
---@field widget Frame

--#endregion

--#region Isles

---@class (exact) IsleEventFrame : Frame
---@field lastUpdated number?
---@field registeredEvents WowEvent | WowEvent[]
---@field OnEnable function
---@field OnDisable function

---@class (exact) BaseIsle : DynamicArchipelagoItem
---@field type integer -- ISLAND_TYPE
---@field widget Frame
---@field eventFrame IsleEventFrame?
---@field child Frame?
---@field SetChild function
---@field Connect function
---@field Disconnect function

---@class AvailableWidget
---@field widget PeninsulaWidget
---@field id number
---@field trigger? fun(): boolean
---@field event WowEvent?
---@field postTriggerTime? fun(): number
---@field eventValidator? fun(): boolean
---@field fallbackWidget? boolean

--#endregion

--#region Peninsulas

---@class BaseArchipelagoFrame : Frame
---@field container Frame
---@field header FontString
---@field icon Frame
---@field content Frame
---@field progress StatusBar
---@field animationIn AnimationGroup
---@field animationOut AnimationGroup

---@class (exact) BasePeninsula : DynamicArchipelagoItem
---@field id string
---@field frame BaseArchipelagoFrame
---@field child DynamicArchipelagoItem
---@field timer? FunctionContainer
---@field SetHeader function
---@field SetType function
---@field SetContent function
---@field SetIcon function
---@field SetOnFinished? function
---@field GetHeaderHeight function
---@field height number
---@field GetIconWidth function
---@field GetWidgetWidth function
---@field GetHeight function

---@class PeninsulaWidget : Frame
---@field Base PeninsulaWidgetContent
---@field TopCap PeninsulaBase
---@field BottomCap PeninsulaBase
---@field height number
---@field GrowAnimation function
---@field ShrinkAnimation function

---@class PeninsulaWidgetContent : AnimatedFrame
---@field children BasePeninsula[]
---@field height number

--#endregion

--#endregion
