local addon = RogueAuto

local function copyPath(path)
  local clone = {}
  for index, value in ipairs(path) do
    clone[index] = value
  end
  return clone
end

function addon:ClampValue(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
end

function addon:GetValueByPath(root, path)
  local value = root
  for _, key in ipairs(path) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[key]
  end
  return value
end

function addon:SetValueByPath(root, path, newValue)
  local value = root
  local pathLength = table.getn(path)
  for index = 1, pathLength - 1 do
    local key = path[index]
    if type(value[key]) ~= "table" then
      value[key] = {}
    end
    value = value[key]
  end
  value[path[pathLength]] = newValue
end

function addon:GetSetting(id)
  local definition = self.settingDefinitions[id]
  if not definition then
    return nil
  end

  if definition.get then
    return definition.get(self)
  end

  return self:GetValueByPath(RogueAutoDB, definition.path)
end

function addon:SetSetting(id, value)
  local definition = self.settingDefinitions[id]
  if not definition then
    return
  end

  if definition.normalize then
    value = definition.normalize(self, value)
  end

  if definition.set then
    definition.set(self, value)
    return
  end

  self:SetValueByPath(RogueAutoDB, definition.path, value)
end

addon.builderOptions = {
  { key = "auto", label = "Auto" },
  { key = "sinister", label = "Sinister" },
  { key = "hemo", label = "Hemo" },
  { key = "backstab", label = "Backstab" },
  { key = "noxious", label = "Noxious" },
}

addon.macroDefinitions = {
  {
    id = "builder",
    macro = "/script RogueAuto:Builder()",
    description = "Builder: builds combo points with the best legal builder, auto-Kicks active casts, can use emergency Kidney Shot when Kick is unavailable and the target is not learned as stun-immune, and can optionally maintain upkeep buffs without spending on damaging finishers.",
  },
  {
    id = "opener",
    macro = "/script RogueAuto:Opener(\"Garrote\")",
    description = "Opener(hint): use an explicit opener like Garrote, Ambush, Cheap Shot, or Pick Pocket. Example macros: /script RogueAuto:Opener(\"Garrote\") or /script RogueAuto:Opener(\"Ambush\").",
  },
}

addon.settingDefinitions = {
  builderMode = {
    path = { "builder", "mode" },
    normalize = function(self, value)
      if value == nil or value == "" then
        return "auto"
      end

      for _, option in ipairs(self.builderOptions) do
        if option.key == value then
          return value
        end
      end

      return "auto"
    end,
  },
  pickPocketHumanoids = {
    path = { "stealth", "pickPocketHumanoids" },
    label = "Pick Pocket before opener when eligible",
    help = "Only affects Opener(hint).",
  },
  builderGhostlyStrike = {
    path = { "builder", "useGhostlyStrike" },
    label = "Prioritize Ghostly Strike in Auto",
    help = "Only affects Builder() while builder mode is Auto.",
  },
  builderFinishers = {
    path = { "builder", "useFinishers" },
    label = "Allow Builder() to maintain upkeep buffs",
    help = "Refreshes Slice and Dice and, when learned and relevant, Envenom. Builder() will not use damaging finishers.",
  },
  builderFlourish = {
    path = { "builder", "useFlourish" },
    label = "Include Flourish in upkeep",
    help = "Allows Builder() to refresh Flourish alongside Slice and Dice and Envenom upkeep.",
  },
  highlightDuration = {
    path = { "notifications", "highlightDuration" },
    label = "Highlight duration",
    min = 3,
    max = 20,
    step = 1,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 3, 20)
    end,
    display = function(value)
      return "Highlight duration: " .. tostring(value) .. " sec"
    end,
  },
}

addon.uiSections = {
  {
    title = "Builder",
    kind = "builder",
    help = "Auto scores Backstab, Surprise Attack, Noxious Assault, Hemorrhage, and Sinister Strike from live combat context. Ghostly Strike is optional. Builder() can also maintain upkeep buffs like Slice and Dice, Envenom for Noxious builds, and optionally Flourish, but it will not spend combo points on damaging finishers.",
    items = { "builderFinishers", "builderFlourish", "builderGhostlyStrike" },
  },
  {
    title = "Openers",
    help = "Opener(hint) only attempts the explicit opener you ask for, but can try Pick Pocket first when eligible.",
    items = { "pickPocketHumanoids" },
  },
  {
    title = "Highlights",
    items = { "highlightDuration" },
  },
  { title = "Macros", kind = "macros" },
}

addon.slashCommandDefinitions = {
  {
    command = "pickpocket",
    type = "toggle",
    setting = "pickPocketHumanoids",
    usage = "on|off",
    success = function(value)
      return "Pick Pocket before opener " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "builder",
    type = "enum",
    setting = "builderMode",
    usage = "auto|sinister|hemo|backstab|noxious",
    values = {
      auto = "auto",
      sinister = "sinister",
      hemo = "hemo",
      backstab = "backstab",
      noxious = "noxious",
    },
    success = function(value)
      return "Builder set to " .. value .. "."
    end,
  },
  {
    command = "builderghostly",
    type = "toggle",
    setting = "builderGhostlyStrike",
    usage = "on|off",
    success = function(value)
      return "Builder Ghostly Strike " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "builderfinishers",
    type = "toggle",
    setting = "builderFinishers",
    usage = "on|off",
    success = function(value)
      return "Builder upkeep buffs " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "builderflourish",
    type = "toggle",
    setting = "builderFlourish",
    usage = "on|off",
    success = function(value)
      return "Builder Flourish upkeep " .. (value and "enabled" or "disabled") .. "."
    end,
  },
}

function addon:GetSlashDefinitions()
  local ordered = {}
  for _, definition in ipairs(self.slashCommandDefinitions) do
    table.insert(ordered, definition)
  end
  return ordered
end

function addon:GetSettingPath(id)
  local definition = self.settingDefinitions[id]
  if not definition or not definition.path then
    return nil
  end
  return copyPath(definition.path)
end
