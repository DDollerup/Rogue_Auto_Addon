local addon = RogueAuto

function addon:PrepareAction(needsTarget)
  self:InitDB()

  if self:IsPickPocketActionBlocked() then
    return false
  end

  if needsTarget and not self:TargetFallback() then
    return false
  end

  if self:IsHostileTarget() then
    self:StartAttack()
  end

  if not needsTarget then
    return true
  end

  return self:IsHostileTarget()
end

function addon:Builder()
  self.state.activeRotationMode = "builder"
  self.state.activeOpenerHint = nil
  if not self:PrepareAction(true) then
    return
  end
  if self.PreparePoisonWeaponsForBuilder then
    self:PreparePoisonWeaponsForBuilder()
  end

  self:LoadBuilderPriorityOrder()
  local context = self:GetComboPointContext("builder")
  self:RunBuilderPriority(context)
end

function addon:Opener(hint)
  if not self or type(self) ~= "table" then
    return false
  end
  if not self.state or type(self.state) ~= "table" then
    return false
  end

  if type(hint) ~= "string" then
    hint = tostring(hint or "")
  end

  self.state.activeRotationMode = "opener"
  self.state.activeOpenerHint = self:ResolveOpenerHint(hint)
  if not self:PrepareAction(true) then
    return false
  end

  return self:TryOpenerHint(hint)
end
