local addon = RogueAuto
local result = addon.BuilderRuleResult

local function executeFeint(self)
  if self:TryBuilderFeint() then
    return result.CAST
  end
  return result.CONTINUE
end

local function executeRiposte(self)
  if self:TryRiposte() then
    return result.CAST
  end
  return result.CONTINUE
end

addon:RegisterBuilderRule({
  id = "feint",
  trace = "builder_rule_feint",
  execute = executeFeint,
})

addon:RegisterBuilderRule({
  id = "riposte",
  trace = "builder_rule_riposte",
  execute = executeRiposte,
})
