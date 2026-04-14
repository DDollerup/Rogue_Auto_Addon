local addon = RogueAuto

local function runSharedCombatPreamble(self, mode)
  if self:TryRotationKick() then
    return true
  end

  if self:TryEmergencyKidneyInterrupt(mode) then
    return true
  end

  if self:TryRiposte() then
    return true
  end

  if mode == "builder" and self:TryBuilderFeint() then
    return true
  end

  return false
end

function addon:PrepareAction(needsTarget)
  self:InitDB()
  self:RefreshKnownSpells()

  if needsTarget and not self:TargetFallback() then
    return false
  end

  if UnitExists("target") and not UnitIsDead("target") then
    self:StartAttack()
  end

  if not needsTarget then
    return true
  end

  return UnitExists("target") and not UnitIsDead("target")
end

function addon:Builder()
  self.state.activeRotationMode = "builder"
  self.state.activeOpenerHint = nil
  if not self:PrepareAction(true) then
    return
  end

  if runSharedCombatPreamble(self, "builder") then
    return
  end

  local context = self:GetComboPointContext("builder")
  local finisher = self:GetPreferredBuilderFinisher(context)
  if finisher and self:TryCast(finisher) then
    return
  end

  self:TryPreferredBuilder()
end

function addon:Opener(hint)
  self.state.activeRotationMode = "opener"
  self.state.activeOpenerHint = self:ResolveOpenerHint(hint)
  if not self:PrepareAction(true) then
    return
  end

  self:TryOpenerHint(hint)
end
