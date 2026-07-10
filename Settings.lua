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

addon.roleplayPersonalityOptions = {
  { key = "silent", label = "Silent Blade" },
  { key = "scoundrel", label = "Scoundrel" },
  { key = "venom", label = "Venomous" },
}

addon.macroDefinitions = {
  {
    id = "builder",
    macro = "/script RogueAuto:Builder()",
    description = "Builder: prioritizes Feint when grouped and targeted, handles interrupts, maintains Slice and Dice and Envenom, can optionally maintain Flourish, scores the best legal builder, and uses Eviscerate at 5 combo points when both main buffs are safe.",
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
  comboPointsEnabled = {
    path = { "ui", "comboPoints", "enabled" },
    label = "Show combo point bullets above the player",
    help = "Displays five combo point bullets near the center of the screen.",
  },
  comboPointsUnlocked = {
    path = { "ui", "comboPoints", "unlocked" },
    label = "Unlock combo point bullets for dragging",
    help = "When enabled, drag the bullets to move them. Disable it to lock them back in place.",
  },
  builderGhostlyStrike = {
    path = { "builder", "useGhostlyStrike" },
    label = "Prioritize Ghostly Strike in Auto",
    help = "Only affects Builder() while builder mode is Auto.",
  },
  builderFlourish = {
    path = { "builder", "useFlourish" },
    label = "Maintain Flourish",
    help = "Allows Builder() to refresh Flourish after Slice and Dice and Envenom upkeep and before starting a new Eviscerate cycle.",
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
  roleplayEnabled = {
    path = { "roleplay", "enabled" },
    label = "Enable nearby RP emotes",
    help = "Sends occasional custom /emote messages only after confirmed actions and outcomes.",
  },
  roleplayEnabledMode = {
    label = "RP emotes",
    help = "Off is the safe default. On sends throttled nearby /emote messages after confirmed actions.",
    options = {
      { key = "off", label = "Off" },
      { key = "on", label = "On" },
    },
    get = function(self)
      return RogueAutoDB.roleplay.enabled and "on" or "off"
    end,
    set = function(self, value)
      RogueAutoDB.roleplay.enabled = value == "on"
    end,
    normalize = function(self, value)
      return value == "on" and "on" or "off"
    end,
  },
  roleplayPersonality = {
    path = { "roleplay", "personality" },
    label = "Personality",
    help = "Silent Blade is restrained, Scoundrel is playful, and Venomous is dark and poison-focused.",
    options = addon.roleplayPersonalityOptions,
    normalize = function(self, value)
      for _, option in ipairs(self.roleplayPersonalityOptions) do
        if option.key == value then
          return value
        end
      end
      return "silent"
    end,
  },
  roleplayFrequency = {
    path = { "roleplay", "frequency" },
    label = "Combat emote chance",
    help = "Pick Pocket outcomes and victories always qualify; combat abilities use this chance and are still throttled.",
    min = 10,
    max = 100,
    step = 5,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 10, 100)
    end,
    display = function(value)
      return "Combat emote chance: " .. tostring(value) .. "%"
    end,
  },
}

addon.uiSections = {
  {
    title = "Roleplay",
    kind = "roleplay",
    help = "Choose Off or On, then select a personality. Emotes cover Pick Pocket, finishers, Kick, control, openers, Vanish, Sprint, Evasion, Sap, Shoot/Throw, and victories.",
    items = { "roleplayEnabledMode", "roleplayPersonality", "roleplayFrequency" },
  },
  {
    title = "Builder",
    kind = "builder",
    help = "Auto compares Backstab, Surprise Attack, Noxious Assault, Hemorrhage, and Sinister Strike from live combat context. Builder() prioritizes Feint when grouped and targeted, maintains Slice and Dice and Envenom, can optionally maintain Flourish, and sets up safe 5-point Eviscerates.",
    items = { "builderFlourish", "builderGhostlyStrike" },
  },
  {
    title = "Openers",
    help = "Opener(hint) only attempts the explicit opener you ask for, but can try Pick Pocket first when eligible.",
    items = { "pickPocketHumanoids" },
  },
  {
    title = "Combo Points",
    help = "By default the bullets sit centered above the player. Unlock them to drag the display to a better spot, then lock it again when you're done.",
    items = { "comboPointsEnabled", "comboPointsUnlocked" },
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
    command = "builderflourish",
    type = "toggle",
    setting = "builderFlourish",
    usage = "on|off",
    success = function(value)
      return "Builder Flourish upkeep " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "rp",
    type = "toggle",
    setting = "roleplayEnabled",
    usage = "on|off",
    success = function(value)
      return "Roleplay emotes " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "personality",
    type = "enum",
    setting = "roleplayPersonality",
    usage = "silent|scoundrel|venom",
    values = {
      silent = "silent",
      scoundrel = "scoundrel",
      venom = "venom",
    },
    success = function(value)
      return "Roleplay personality set to " .. value .. "."
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
