local addon = RogueAuto

local function runInterruptPreamble(self, context)
  if self:TryRotationKick(context) then
    return true
  end

  if self:TryEmergencyKidneyInterrupt(context) then
    return true
  end

  if self:TryEmergencyBlindInterrupt(context) then
    return true
  end

  return false
end

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

  local context = self:GetComboPointContext("builder")
  if runInterruptPreamble(self, context) then
    return
  end

  if self:TryBuilderFeint() then
    return
  end

  if self:TryRiposte() then
    return
  end

  if self:IsBuilderEviscerateUrgent(context) then
    self.state.builderEviscerateUrgentAtFive = true
    self:Trace("Urgent builder Eviscerate at 5 combo points; casting immediately")
    if self:TryBuilderEviscerate(context, true, true, true) then
      return
    end

    self:Trace("Urgent Eviscerate attempt failed; falling back to armed/normal eviscerate path")
  end

  if self:IsBuilderEviscerateArmed(context) then
    if context.comboPoints >= 5 then
      self:TryBuilderEviscerate(context, true, true, true)
      return
    end

    if context.comboPoints == 4 then
      self:TryPreferredBuilder(context)
      return
    end
  end

  if self:TryBuilderCombatBuffUpkeep(context) then
    return
  end

  if self:ShouldMaintainBuilderFlourish(context.comboPoints, context) then
    self:TryBuilderFlourishUpkeep(context)
    return
  end

  if context.comboPoints >= 5 then
    self:TryBuilderEviscerate(context, false)
    return
  end

  if context.comboPoints == 4 then
    local shockWindow = self.builderEviscerateShockWindow or 7
    if self:HasBuilderEviscerateShockWindow(context) then
      if self:ArmBuilderEviscerate(context, true) then
        self:Trace("Shock Eviscerate path: arming at 4 CP with SnD/Envenom >= " .. shockWindow .. "s")
        self:TryPreferredBuilder(context)
        return
      end
    elseif self:ArmBuilderEviscerate(context) then
      self:TryPreferredBuilder(context)
      return
    end
  end

  self:TryPreferredBuilder(context)
end

function addon:Opener(hint)
  self.state.activeRotationMode = "opener"
  self.state.activeOpenerHint = self:ResolveOpenerHint(hint)
  if not self:PrepareAction(true) then
    return
  end

  self:TryOpenerHint(hint)
end
