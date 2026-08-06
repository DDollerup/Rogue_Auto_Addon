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
          local traceArgs = {}
          if rule.traceArgs then
            local generated = rule.traceArgs()
            traceArgs = generated or {}
          end
          self:TraceEvent(rule.trace, unpack(traceArgs))
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
      trace = "builder_rule_emergency_preamble",
      action = function()
        return runInterruptPreamble(self, context)
      end,
    },
    {
      trace = "builder_rule_feint",
      action = function()
        return self:TryBuilderFeint()
      end,
    },
    {
      trace = "builder_rule_riposte",
      action = function()
        return self:TryRiposte()
      end,
    },
    {
      trace = "builder_rule_armed_eviscerate_5cp",
      when = function()
        return context.comboPoints >= 5 and self:GetBuilderEviscerateIntent(context) ~= nil
      end,
      terminal = true,
      action = function()
        return self:TryBuilderEviscerate(context, true, true, true)
      end,
    },
    {
      trace = "builder_rule_forced_eviscerate_5cp",
      when = function()
        return context.comboPoints >= 5
      end,
      terminal = true,
      action = function()
        return self:TryBuilderEviscerate(context, false, true, true)
      end,
    },
    {
      trace = "builder_rule_combat_buff_upkeep",
      action = function()
        return self:TryBuilderCombatBuffUpkeep(context)
      end,
    },
    {
      trace = "builder_rule_flourish_upkeep",
      when = function()
        return self:ShouldMaintainBuilderFlourish(context.comboPoints, context)
      end,
      action = function()
        return self:TryBuilderFlourishUpkeep(context)
      end,
    },
    {
      trace = "builder_rule_arm_eviscerate_4cp",
      when = function()
        return context.comboPoints == 4
      end,
      terminal = true,
      action = function()
        if self:HasBuilderEviscerateShockWindow(context) then
          if self:ArmBuilderEviscerate(context, true) then
            self:TraceEvent("builder_shock_eviscerate_armed", shockWindow)
            return self:TryPreferredBuilder(context)
          end
        elseif self:ArmBuilderEviscerate(context) then
          return self:TryPreferredBuilder(context)
        end
        return false
      end,
    },
    {
      trace = "builder_rule_preferred_builder_fallback",
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
