local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Session: AceModule
local session = addon:NewModule('Session')

function session:OnInitialize()

end

session:Enable()
