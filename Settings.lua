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
  for index = 1, #path - 1 do
    local key = path[index]
    if type(value[key]) ~= "table" then
      value[key] = {}
    end
    value = value[key]
  end
  value[path[#path]] = newValue
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
    id = "bleed",
    macro = "/script RogueAuto:Bleed()",
    description = "Bleed: stealth opener plus rupture and Shadow of Death upkeep, with toggles for order and Rupture guarantee.",
  },
  {
    id = "direct",
    macro = "/script RogueAuto:Direct()",
    description = "Direct: stealth opener plus Expose Armor, Slice and Dice, Envenom, and faster damage pressure on short normal-mob fights, with toggles for order and Expose Armor guarantee.",
  },
  {
    id = "interrupt",
    macro = "/script RogueAuto:Interrupt()",
    description = "Interrupt: ranged interrupt tools first, then Kick, Kidney Shot, Gouge, and optional Blind.",
  },
  {
    id = "defensive",
    macro = "/script RogueAuto:Defensive()",
    description = "Defensive: Vanish and Evasion at thresholds, then Flourish, Ghostly Strike, and Feint.",
  },
}

addon.settingDefinitions = {
  builderMode = {
    path = { "builder", "mode" },
  },
  nearestFallback = {
    path = { "targeting", "nearestFallback" },
    label = "Nearest target fallback",
  },
  autoStartAttack = {
    path = { "targeting", "autoStartAttack" },
    label = "Auto start attack",
  },
  integratedStealth = {
    path = { "stealth", "integrated" },
    label = "Integrated stealth openers",
  },
  pickPocketHumanoids = {
    path = { "stealth", "pickPocketHumanoids" },
    label = "Pick Pocket humanoids first",
  },
  keepSliceAndDice = {
    path = { "core", "keepSliceAndDice" },
    label = "Maintain Slice and Dice in DPS macros",
    help = "Shared across Bleed and Direct.",
  },
  bleedSliceAndDiceFirst = {
    path = { "core", "bleed", "sliceAndDiceFirst" },
    label = "Slice and Dice before Rupture",
  },
  guaranteeBleedDebuff = {
    path = { "core", "bleed", "guaranteePrimaryDebuff" },
    label = "Guarantee Rupture before buff upkeep",
  },
  directSliceAndDiceFirst = {
    path = { "core", "direct", "sliceAndDiceFirst" },
    label = "Slice and Dice before Expose Armor",
  },
  guaranteeDirectDebuff = {
    path = { "core", "direct", "guaranteePrimaryDebuff" },
    label = "Guarantee Expose Armor before short-fight damage",
  },
  softFeint = {
    path = { "core", "softDefensives", "feint" },
    label = "Use Feint in DPS buttons",
  },
  softGhostlyStrike = {
    path = { "core", "softDefensives", "ghostlyStrike" },
    label = "Use Ghostly Strike in DPS buttons",
  },
  softFlourish = {
    path = { "core", "softDefensives", "flourish" },
    label = "Use Flourish in DPS buttons",
  },
  useBlind = {
    path = { "interrupt", "useBlind" },
    label = "Allow Blind in interrupt button",
  },
  kidneyMinCP = {
    path = { "interrupt", "kidneyMinCP" },
    label = "Kidney Shot combo minimum",
    min = 1,
    max = 5,
    step = 1,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 1, 5)
    end,
    display = function(value)
      return "Kidney Shot combo minimum: " .. tostring(value)
    end,
  },
  executeHealthPct = {
    path = { "core", "executeHealthPct" },
    label = "Direct finisher below",
    min = 5,
    max = 100,
    step = 1,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 5, 100)
    end,
    display = function(value)
      return "Direct finisher below: " .. tostring(value) .. "%"
    end,
  },
  evasionPct = {
    path = { "panic", "evasionPct" },
    label = "Evasion",
    min = 5,
    max = 100,
    step = 1,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 5, 100)
    end,
    display = function(value)
      return "Evasion: " .. tostring(value) .. "%"
    end,
  },
  vanishPct = {
    path = { "panic", "vanishPct" },
    label = "Vanish",
    min = 5,
    max = 100,
    step = 1,
    normalize = function(self, value)
      return self:ClampValue(math.floor(value + 0.5), 5, 100)
    end,
    display = function(value)
      return "Vanish: " .. tostring(value) .. "%"
    end,
  },
  debug = {
    path = { "debug" },
    label = "Enable debug chat output",
  },
}

addon.uiSections = {
  { title = "Builder", kind = "builder" },
  {
    title = "Targeting",
    items = { "nearestFallback", "autoStartAttack" },
  },
  {
    title = "Stealth/Openers",
    items = { "integratedStealth", "pickPocketHumanoids" },
  },
  {
    title = "Rotation: Bleed",
    items = { "keepSliceAndDice", "bleedSliceAndDiceFirst", "guaranteeBleedDebuff" },
  },
  {
    title = "Rotation: Direct",
    items = { "directSliceAndDiceFirst", "guaranteeDirectDebuff" },
  },
  {
    title = "Defensives",
    items = { "softFeint", "softGhostlyStrike", "softFlourish" },
  },
  {
    title = "Interrupt",
    items = { "useBlind", "kidneyMinCP" },
  },
  {
    title = "Thresholds",
    items = { "executeHealthPct", "evasionPct", "vanishPct" },
  },
  { title = "Macros", kind = "macros" },
  {
    title = "Misc",
    items = { "debug" },
  },
}

addon.slashCommandDefinitions = {
  {
    command = "debug",
    type = "toggle",
    setting = "debug",
    usage = "on|off",
    success = function(value)
      return "Debug " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "fallback",
    type = "toggle",
    setting = "nearestFallback",
    usage = "on|off",
    success = function(value)
      return "Nearest fallback " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "pickpocket",
    type = "toggle",
    setting = "pickPocketHumanoids",
    usage = "on|off",
    success = function(value)
      return "Pick Pocket opener " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "snd",
    type = "toggle",
    setting = "keepSliceAndDice",
    usage = "on|off",
    success = function(value)
      return "Slice and Dice upkeep " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "bleedguarantee",
    type = "toggle",
    setting = "guaranteeBleedDebuff",
    usage = "on|off",
    success = function(value)
      return "Bleed debuff guarantee " .. (value and "enabled" or "disabled") .. "."
    end,
  },
  {
    command = "directguarantee",
    type = "toggle",
    setting = "guaranteeDirectDebuff",
    usage = "on|off",
    success = function(value)
      return "Direct debuff guarantee " .. (value and "enabled" or "disabled") .. "."
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
    command = "bleedorder",
    type = "enum",
    setting = "bleedSliceAndDiceFirst",
    usage = "snd|rupture",
    values = {
      snd = true,
      rupture = false,
    },
    success = function(value)
      return "Bleed priority now starts with " .. (value and "Slice and Dice" or "Rupture") .. "."
    end,
  },
  {
    command = "directorder",
    type = "enum",
    setting = "directSliceAndDiceFirst",
    usage = "snd|expose",
    values = {
      snd = true,
      expose = false,
    },
    success = function(value)
      return "Direct priority now starts with " .. (value and "Slice and Dice" or "Expose Armor") .. "."
    end,
  },
  {
    command = "execute",
    type = "number",
    setting = "executeHealthPct",
    usage = "<pct>",
    success = function(value)
      return "Direct finisher threshold set to " .. tostring(value) .. "%."
    end,
  },
  {
    command = "evasion",
    type = "number",
    setting = "evasionPct",
    usage = "<pct>",
    success = function(value)
      return "Evasion threshold set to " .. tostring(value) .. "%."
    end,
  },
  {
    command = "vanish",
    type = "number",
    setting = "vanishPct",
    usage = "<pct>",
    success = function(value)
      return "Vanish threshold set to " .. tostring(value) .. "%."
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
