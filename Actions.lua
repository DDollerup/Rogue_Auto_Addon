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

local function executeBuilderRules(self, context, rules)
  for _, rule in ipairs(rules) do
    local shouldRun = true
    if rule.when and not rule.when() then
      shouldRun = false
    end

    if shouldRun and rule.action then
      local wasHandled = rule.action()
      if rule.trace and self.Trace and (wasHandled or rule.terminal) then
        self:Trace(rule.trace)
      end
      if rule.terminal then
        return true
      end
      if wasHandled then
        return true
      end
    end
  end
  return false
end

local function buildBuilderRules(self, context)
  local shockWindow = self.builderEviscerateShockWindow or 7
  return {
    {
      trace = "Builder rule: emergency kick/riposte/interrupt preamble",
      action = function()
        return runInterruptPreamble(self, context)
      end,
    },
    {
      trace = "Builder rule: feint",
      action = function()
        return self:TryBuilderFeint()
      end,
    },
    {
      trace = "Builder rule: riposte",
      action = function()
        return self:TryRiposte()
      end,
    },
    {
      trace = "Builder rule: armed Eviscerate at 5 CP",
      when = function()
        return context.comboPoints >= 5 and self:GetBuilderEviscerateIntent(context) ~= nil
      end,
      terminal = true,
      action = function()
        return self:TryBuilderEviscerate(context, true, true, true)
      end,
    },
    {
      trace = "Builder rule: forced Eviscerate at 5 CP",
      when = function()
        return context.comboPoints >= 5
      end,
      terminal = true,
      action = function()
        return self:TryBuilderEviscerate(context, false, true, true)
      end,
    },
    {
      trace = "Builder rule: combat buff upkeep",
      action = function()
        return self:TryBuilderCombatBuffUpkeep(context)
      end,
    },
    {
      trace = "Builder rule: flourish upkeep",
      when = function()
        return self:ShouldMaintainBuilderFlourish(context.comboPoints, context)
      end,
      action = function()
        return self:TryBuilderFlourishUpkeep(context)
      end,
    },
    {
      trace = "Builder rule: arm eviscerate at 4 CP",
      when = function()
        return context.comboPoints == 4
      end,
      terminal = true,
      action = function()
        if self:HasBuilderEviscerateShockWindow(context) then
          if self:ArmBuilderEviscerate(context, true) then
            self:Trace("Shock Eviscerate path: arming at 4 CP with SnD/Envenom >= " .. shockWindow .. "s")
            return self:TryPreferredBuilder(context)
          end
        elseif self:ArmBuilderEviscerate(context) then
          return self:TryPreferredBuilder(context)
        end
        return false
      end,
    },
    {
      trace = "Builder rule: preferred builder fallback",
      action = function()
        return self:TryPreferredBuilder(context)
      end,
    },
  }
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
  local rules = buildBuilderRules(self, context)
  executeBuilderRules(self, context, rules)
end

function addon:Opener(hint)
  self.state.activeRotationMode = "opener"
  self.state.activeOpenerHint = self:ResolveOpenerHint(hint)
  if not self:PrepareAction(true) then
    return
  end

  self:TryOpenerHint(hint)
end
