local addon = RogueAuto
local result = addon.BuilderRuleResult

local function executeCombatBuffMaintenance(self, context)
  if self:TryBuilderCombatBuffUpkeep(context) then
    return result.CAST
  end
  return result.CONTINUE
end

local function shouldMaintainFlourish(self, context)
  return self:ShouldMaintainBuilderFlourish(context.comboPoints, context)
end

local function executeFlourishMaintenance(self, context)
  if self:TryBuilderFlourishUpkeep(context) then
    return result.CAST
  end
  return result.CONTINUE
end

addon:RegisterBuilderRule({
  id = "combat_buff_maintenance",
  trace = "builder_rule_combat_buff_upkeep",
  execute = executeCombatBuffMaintenance,
})

addon:RegisterBuilderRule({
  id = "flourish_maintenance",
  trace = "builder_rule_flourish_upkeep",
  when = shouldMaintainFlourish,
  execute = executeFlourishMaintenance,
})
