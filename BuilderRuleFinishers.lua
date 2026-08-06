local addon = RogueAuto
local result = addon.BuilderRuleResult

local function hasFivePoints(self, context)
  return context.comboPoints >= 5
end

local function hasArmedFivePointEviscerate(self, context)
  return context.comboPoints >= 5
    and self:GetBuilderEviscerateIntent(context) ~= nil
end

local function executeArmedEviscerate(self, context)
  if self:TryBuilderEviscerate(context, true, true, true) then
    return result.CAST
  end
  return result.BLOCKED_STOP
end

local function executeForcedEviscerate(self, context)
  if self:TryBuilderEviscerate(context, false, true, true) then
    return result.CAST
  end
  return result.BLOCKED_STOP
end

local function hasShockWindow(self, context)
  return context.comboPoints == 4 and self:HasBuilderEviscerateShockWindow(context)
end

local function executeShockEviscerate(self, context)
  if not self:ArmBuilderEviscerate(context, true) then
    return result.CONTINUE
  end

  self:TraceEvent("builder_shock_eviscerate_armed", self.builderEviscerateShockWindow or 7)
  if self:TryBuilderEviscerate(context, true, true, true) then
    return result.CAST
  end
  return result.BLOCKED_STOP
end

local function hasStandardArmOpportunity(self, context)
  return context.comboPoints == 4
    and not self:HasBuilderEviscerateShockWindow(context)
end

local function executeStandardArm(self, context)
  if self:ArmBuilderEviscerate(context, false) then
    return result.RESERVE_CONTINUE
  end
  return result.CONTINUE
end

addon:RegisterBuilderRule({
  id = "eviscerate_armed",
  trace = "builder_rule_armed_eviscerate_5cp",
  when = hasArmedFivePointEviscerate,
  execute = executeArmedEviscerate,
})

addon:RegisterBuilderRule({
  id = "eviscerate_forced",
  trace = "builder_rule_forced_eviscerate_5cp",
  when = hasFivePoints,
  execute = executeForcedEviscerate,
})

addon:RegisterBuilderRule({
  id = "eviscerate_shock",
  trace = "builder_rule_shock_eviscerate",
  when = hasShockWindow,
  execute = executeShockEviscerate,
})

addon:RegisterBuilderRule({
  id = "eviscerate_arm",
  trace = "builder_rule_arm_eviscerate_4cp",
  when = hasStandardArmOpportunity,
  execute = executeStandardArm,
})
