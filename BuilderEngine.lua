local addon = RogueAuto

addon.BuilderRuleResult = {
  CAST = "cast",
  CONTINUE = "continue",
  RESERVE_CONTINUE = "reserve_continue",
  BLOCKED_STOP = "blocked_stop",
}

addon.BuilderPriorityOrder = {
  "interrupts",
  "eviscerate_armed",
  "eviscerate_forced",
  "eviscerate_shock",
  "combat_buff_maintenance",
  "flourish_maintenance",
  "feint",
  "riposte",
  "eviscerate_arm",
  "preferred_builder",
}

addon.BuilderRules = {}

function addon:RegisterBuilderRule(rule)
  if not rule or not rule.id then
    return
  end
  self.BuilderRules[rule.id] = rule
end

function addon:SetBuilderPriorityOrder(order)
  if type(order) ~= "table" then
    return false
  end

  local nextOrder = {}
  local seen = {}
  for index, ruleId in ipairs(order) do
    if self.BuilderRules[ruleId] and not seen[ruleId] then
      table.insert(nextOrder, ruleId)
      seen[ruleId] = true
    end
  end

  for _, ruleId in ipairs(self.BuilderPriorityOrder) do
    if self.BuilderRules[ruleId] and not seen[ruleId] then
      table.insert(nextOrder, ruleId)
      seen[ruleId] = true
    end
  end

  self.BuilderPriorityOrder = nextOrder
  return true
end

function addon:LoadBuilderPriorityOrder()
  if RogueAutoDB and RogueAutoDB.builder and type(RogueAutoDB.builder.priorityOrder) == "table" then
    self:SetBuilderPriorityOrder(RogueAutoDB.builder.priorityOrder)
  end
end

function addon:SaveBuilderPriorityOrder()
  if not RogueAutoDB or not RogueAutoDB.builder then
    return
  end

  RogueAutoDB.builder.priorityOrder = {}
  for _, ruleId in ipairs(self.BuilderPriorityOrder) do
    table.insert(RogueAutoDB.builder.priorityOrder, ruleId)
  end
end

function addon:MoveBuilderPriority(ruleId, direction)
  local order = self.BuilderPriorityOrder
  local index = nil
  for position, currentId in ipairs(order) do
    if currentId == ruleId then
      index = position
      break
    end
  end

  if not index then
    return false
  end

  local target = index + direction
  if target < 1 or target > table.getn(order) then
    return false
  end

  order[index], order[target] = order[target], order[index]
  return true
end

function addon:RunBuilderPriority(context)
  for _, ruleId in ipairs(self.BuilderPriorityOrder) do
    local rule = self.BuilderRules[ruleId]
    if rule and (not rule.when or rule.when(self, context)) then
      local result = rule.execute(self, context)
      local shouldStop = result == self.BuilderRuleResult.CAST or result == self.BuilderRuleResult.BLOCKED_STOP
      if shouldStop then
        if rule.trace then
          self:TraceEvent(rule.trace)
        end
        return result
      end

      if result == self.BuilderRuleResult.RESERVE_CONTINUE and rule.trace then
        self:TraceEvent(rule.trace)
      end
    end
  end

  return self.BuilderRuleResult.CONTINUE
end
