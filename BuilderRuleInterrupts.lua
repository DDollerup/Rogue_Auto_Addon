local addon = RogueAuto
local result = addon.BuilderRuleResult

local function runInterrupts(self, context)
  if self:TryRotationKick(context) then
    return result.CAST
  end
  if self:TryEmergencyKidneyInterrupt(context) then
    return result.CAST
  end
  if self:TryEmergencyBlindInterrupt(context) then
    return result.CAST
  end
  return result.CONTINUE
end

addon:RegisterBuilderRule({
  id = "interrupts",
  trace = "builder_rule_emergency_preamble",
  execute = runInterrupts,
})
