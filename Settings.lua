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
  { key = "auto", label = "Smart Choice" },
  { key = "sinister", label = "Sinister Strike" },
  { key = "hemo", label = "Hemorrhage" },
  { key = "backstab", label = "Backstab" },
  { key = "noxious", label = "Noxious Assault" },
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
    description = "Builder: handles interrupts before Feint, maintains Envenom ahead of Slice and Dice, can optionally maintain Flourish, scores the best legal builder, and uses Eviscerate at 5 combo points. Builder automatically switches to a Slice and Dice, Sinister Strike, and Eviscerate rotation when the target is poison immune or neither weapon has poison.",
  },
  {
    id = "opener",
    macro = "/script RogueAuto:Opener(\"Garrote\")",
    description = "Opener(hint): use an explicit opener like Garrote, Ambush, Cheap Shot, or Pick Pocket. Example macros: /rga opener Garrote or /rga opener Ambush.",
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
    label = "Try Pick Pocket first",
    help = "The Opener button will try to grab treasure before attacking when it is safe.",
  },
  comboPointsEnabled = {
    path = { "ui", "comboPoints", "enabled" },
    label = "Show my combo points",
    help = "Shows five easy-to-see dots near your character.",
  },
  comboPointsUnlocked = {
    path = { "ui", "comboPoints", "unlocked" },
    label = "Let me move the combo points",
    help = "Turn this on, drag the dots where you want them, then turn it off.",
  },
  pickPocketGoldStatsEnabled = {
    path = { "ui", "pickPocketStats", "enabled" },
    label = "Show my stolen gold",
    help = "Shows how much money Pick Pocket has found.",
  },
  pickPocketGoldStatsUnlocked = {
    path = { "ui", "pickPocketStats", "unlocked" },
    label = "Let me move the gold box",
    help = "Turn this on, drag the gold box, then turn it off.",
  },
  builderGhostlyStrike = {
    path = { "builder", "useGhostlyStrike" },
    label = "Use Ghostly Strike when helpful",
    help = "Smart Choice can use Ghostly Strike to help you dodge.",
  },
  builderFlourish = {
    path = { "builder", "useFlourish" },
    label = "Keep Flourish active",
    help = "The combat helper will refresh Flourish when your important buffs are safe.",
  },
  builderFeint = {
    path = { "builder", "useFeint" },
    label = "Use Feint to stay safe",
    help = "The combat helper can use Feint when an enemy attacks you in a group.",
  },
  interruptKidneyShot = {
    label = "Use Kidney Shot for interrupts",
    help = "When Kick cannot be used, the combat helper may spend combo points to stop a dangerous spell.",
    get = function(self)
      return RogueAutoDB.builder.useKidneyShotInterrupt ~= false
    end,
    set = function(self, value)
      RogueAutoDB.builder.useKidneyShotInterrupt = value == true
    end,
  },
  interruptBlind = {
    label = "Use Blind for interrupts",
    help = "When Kick and Kidney Shot cannot help, the combat helper may use Blind to stop a dangerous spell.",
    get = function(self)
      return RogueAutoDB.builder.useBlindInterrupt ~= false
    end,
    set = function(self, value)
      RogueAutoDB.builder.useBlindInterrupt = value == true
    end,
  },
  highlightDuration = {
    path = { "notifications", "highlightDuration" },
    label = "How long should hints glow?",
    min = 3,
    max = 20,
    step = 1,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 3, 20)
    end,
    display = function(value)
      return "Hints glow for " .. tostring(value) .. " seconds"
    end,
  },
  roleplayEnabled = {
    path = { "roleplay", "enabled" },
    label = "Enable nearby RP emotes",
    help = "Sends occasional custom /emote messages only after confirmed actions and outcomes.",
  },
  roleplayEnabledMode = {
    label = "Let my rogue talk",
    help = "When this is on, your rogue sometimes acts out nearby emotes. Off is quiet.",
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
    label = "Choose a personality",
    help = "Silent Blade is calm, Scoundrel is silly, and Venomous likes poison jokes.",
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
    label = "How often should my rogue talk?",
    help = "A higher number means more roleplay messages during fights.",
    min = 10,
    max = 100,
    step = 5,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 10, 100)
    end,
    display = function(value)
      return "Talk chance: " .. tostring(value) .. "%"
    end,
  },
}

addon.uiSections = {
  {
    title = "1. Combat Helper",
    kind = "builder",
    color = { 0.25, 0.82, 0.38 },
    help = "Choose Smart Choice if you are unsure. RogueAuto will pick attacks, keep important buffs active, interrupt danger, and spend combo points.",
    items = {
      "builderFlourish",
      "builderGhostlyStrike",
      "builderFeint",
      "interruptKidneyShot",
      "interruptBlind",
    },
  },
  {
    title = "2. Poison Weapons",
    kind = "poisonWeapons",
    color = { 0.32, 0.86, 0.56 },
    help = "Save one normal poisoned weapon pair and one Dissolvent Poison pair. RogueAuto can swap between the exact saved weapons for the creature you are fighting.",
  },
  {
    title = "3. Riding Clothes",
    kind = "mountGear",
    color = { 0.28, 0.72, 1.0 },
    help = "Put on your fastest riding items, press Save Riding Clothes, and turn on Auto Change. Your normal clothes return when you get off your mount.",
  },
  {
    title = "4. Sneaking",
    color = { 0.72, 0.48, 1.0 },
    help = "Choose whether the Opener button should try Pick Pocket before your selected stealth attack.",
    items = { "pickPocketHumanoids" },
  },
  {
    title = "5. Treasure Counter",
    kind = "pickPocketGold",
    color = { 1.0, 0.74, 0.18 },
    help = "Keep a little box on screen that counts the money found with Pick Pocket.",
    items = { "pickPocketGoldStatsEnabled", "pickPocketGoldStatsUnlocked" },
  },
  {
    title = "6. Things on My Screen",
    color = { 1.0, 0.48, 0.22 },
    help = "Show combo points near your character and choose where they sit.",
    items = { "comboPointsEnabled", "comboPointsUnlocked" },
  },
  {
    title = "7. Helpful Glows",
    color = { 1.0, 0.82, 0.25 },
    help = "Choose how long RogueAuto keeps an important hint glowing.",
    items = { "highlightDuration" },
  },
  {
    title = "8. Rogue Personality",
    kind = "roleplay",
    color = { 0.98, 0.42, 0.58 },
    help = "Your rogue can sometimes say playful things after successful actions. This is optional and starts quiet.",
    items = { "roleplayEnabledMode", "roleplayPersonality", "roleplayFrequency" },
  },
  {
    title = "8. Action Buttons",
    kind = "macros",
    color = { 0.32, 0.82, 0.76 },
    help = "These are the commands used by your RogueAuto action-bar buttons.",
  },
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
    command = "ppstats",
    type = "action",
    usage = "reset",
    action = function()
      if addon.ResetPickPocketGoldStats then
        addon:ResetPickPocketGoldStats()
      end
      return "Pick Pocket gold stats reset."
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
    command = "builderfeint",
    type = "toggle",
    setting = "builderFeint",
    usage = "on|off",
    success = function(value)
      return "Builder Feint " .. (value and "enabled" or "disabled") .. "."
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
