local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Components: AceModule
local components = addon:NewModule('Components')

---@type ComponentModule[]
components.items = {
    ['CircularProgress'] = addon:GetModule('CircularProgress')
}

---@generic T
---@param component `T` | ComponentModule
---@return Component?
function components:Fetch(component)
    if self.items[component] == nil then return end

    return self.items[component]:Create()
end

components:Enable()

---@meta
---@alias ComponentModuleType
---|'CircularProgress'

---@alias ComponentType
---|'CircularProgressComponent'
