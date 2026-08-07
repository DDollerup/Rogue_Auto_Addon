local addon = RogueAuto

addon.version = "1.0.1"

local originalOnPlayerLogin = addon.OnPlayerLogin
function addon:OnPlayerLogin()
  local alreadyHandled = self.state and self.state.playerLoginHandled == true
  originalOnPlayerLogin(self)

  if not alreadyHandled and self.state and self.state.playerLoginHandled == true then
    self:Print("RogueAuto v" .. tostring(self.version) .. " loaded.")
  end
end
