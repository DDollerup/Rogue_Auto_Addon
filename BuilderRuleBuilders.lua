local addon = RogueAuto
local result = addon.BuilderRuleResult

local function executePreferredBuilder(self, context)
  if self:TryPreferredBuilder(context) then
    return result.CAST
  end
  return result.CONTINUE
end

addon:RegisterBuilderRule({
  id = "preferred_builder",
  trace = "builder_rule_preferred_builder_fallback",
  execute = executePreferredBuilder,
})
