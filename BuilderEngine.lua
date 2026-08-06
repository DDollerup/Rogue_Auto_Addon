local addon = RogueAuto

addon.BuilderRuleResult = {
  CAST = "cast",
  CONTINUE = "continue",
  RESERVE_CONTINUE = "reserve_continue",
  BLOCKED_STOP = "blocked_stop"
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
  "preferred_builder"
}

addon.BuilderRules = {}

function addon.RegisterBuilderRule(self, rule)
  if rule and rule.id then
    self.BuilderRules[rule.id] = rule
  end
end

function addon.SetBuilderPriorityOrder(self, order)
  if type(order) ~= "table" then
    return false
  end

  local nextOrder = {}
  local seen = {}
  local index
  local ruleId

  for index, ruleId in ipairs(order) do
    if self.BuilderRules[ruleId] and not seen[ruleId] then
      table.insert(nextOrder, ruleId)
      seen[ruleId] = true
    end
  end

  for index, ruleId in ipairs(self.BuilderPriorityOrder) do
    if self.BuilderRules[ruleId] and not seen[ruleId] then
      table.insert(nextOrder, ruleId)
      seen[ruleId] = true
    end
  end

  self.BuilderPriorityOrder = nextOrder
  return true
end

function addon.LoadBuilderPriorityOrder(self)
  if RogueAutoDB and RogueAutoDB.builder and type(RogueAutoDB.builder.priorityOrder) == "table" then
    self:SetBuilderPriorityOrder(RogueAutoDB.builder.priorityOrder)
  end
end

function addon.SaveBuilderPriorityOrder(self)
  if not RogueAutoDB or not RogueAutoDB.builder then
    return
  end

  RogueAutoDB.builder.priorityOrder = {}
  for index, ruleId in ipairs(self.BuilderPriorityOrder) do
    table.insert(RogueAutoDB.builder.priorityOrder, ruleId)
  end
end

function addon.MoveBuilderPriority(self, ruleId, direction)
  local order = self.BuilderPriorityOrder
  local index
  local position
  local currentId

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

function addon.RunBuilderPriority(self, context)
  local ruleId
  local rule
  local result
  local shouldStop

  for index, ruleId in ipairs(self.BuilderPriorityOrder) do
    rule = self.BuilderRules[ruleId]
    if rule then
      if not rule.when or rule.when(self, context) then
        result = rule.execute(self, context)
        shouldStop = result == self.BuilderRuleResult.CAST or result == self.BuilderRuleResult.BLOCKED_STOP
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
  end

  return self.BuilderRuleResult.CONTINUE
end
