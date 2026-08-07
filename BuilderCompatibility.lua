local addon = RogueAuto

local function isLegacyTruthy(value)
  return value == true or value == 1
end

-- Vanilla 1.12 returns nil from IsUsableSpell when an ability is not usable.
-- Treat only true/1 as usable so reactive abilities cannot falsely succeed.
function addon:CanCast(name)
  if not self:HasSpell(name) then
    return false
  end

  if name == "Surprise Attack" and not self:CanUseSurpriseAttack() then
    return false
  end

  if name == "Pick Pocket" and not self:IsPickPocketRange() then
    return false
  end

  if not self:IsSpellReady(name) then
    return false
  end

  local energyCost = self:GetSpellEnergyCost(name)
  if energyCost and self:GetEnergy() < energyCost then
    return false
  end

  if IsUsableSpell then
    local usable, noMana = IsUsableSpell(name)
    return isLegacyTruthy(usable) and not isLegacyTruthy(noMana)
  end

  return true
end

function addon:CanUseSurpriseAttack()
  if not self:HasSpell("Surprise Attack") then
    return false
  end

  local requiresTargetDodge = self:SpellTooltipRequiresTargetDodge("Surprise Attack")
  if requiresTargetDodge then
    if not self:IsSurpriseAttackReady() then
      return false
    end

    if IsUsableSpell then
      local usable, noMana = IsUsableSpell("Surprise Attack")
      if not isLegacyTruthy(usable) or isLegacyTruthy(noMana) then
        return false
      end
    end
  end

  return true
end

-- The old combat-miss path sees attacks made by the rogue. If the target
-- parries one of those attacks, it must not arm Riposte.
local originalOnCombatMiss = addon.OnCombatMiss
function addon:OnCombatMiss(message)
  local previousRiposteReadyUntil = self.state.riposteReadyUntil or 0
  originalOnCombatMiss(self, message)

  if message and string.find(string.lower(message), "parry", 1, true) then
    self.state.riposteReadyUntil = previousRiposteReadyUntil
  end
end

-- UNIT_COMBAT reports PARRY for the unit that actually performed the parry.
-- Use that authoritative 1.12 signal to arm Riposte when the player parries.
local riposteEventFrame = CreateFrame("Frame")
riposteEventFrame:RegisterEvent("UNIT_COMBAT")
riposteEventFrame:SetScript("OnEvent", function(selfOrEvent, eventOrUnit, unitOrAction, actionOrDamage)
  local eventName = nil
  local unit = nil
  local action = nil

  if type(selfOrEvent) == "string" then
    eventName = selfOrEvent
    unit = eventOrUnit
    action = unitOrAction
  elseif type(eventOrUnit) == "string" then
    eventName = eventOrUnit
    unit = unitOrAction
    action = actionOrDamage
  elseif type(event) == "string" then
    eventName = event
    unit = arg1
    action = arg2
  end

  if eventName == "UNIT_COMBAT" and unit == "player" and action == "PARRY" then
    addon.state.riposteReadyUntil = GetTime() + 5
  end
end)

local function normalizePoisonLoadoutName(name)
  if not name or name == "" then
    return nil
  end
  return string.lower(name)
end

function addon:GetWeaponPoisonLoadoutKey()
  local states = self:GetWeaponPoisonStates()
  local mainHand = "none"
  local offHand = "none"
  local reliable = true

  for _, state in ipairs(states or {}) do
    local poisonName = normalizePoisonLoadoutName(state.name)
    if not poisonName then
      poisonName = "unknown"
      reliable = false
    end

    if state.hand == "main" then
      mainHand = poisonName
    elseif state.hand == "off" then
      offHand = poisonName
    end
  end

  return "mh=" .. mainHand .. ";oh=" .. offHand, reliable
end

-- Poison immunity is specific to the current poison loadout. If the client
-- cannot identify an active poison by name, keep the memory target-instance
-- local instead of incorrectly carrying it across weapon/poison swaps.
function addon:GetPoisonImmunityKey(targetName)
  local targetNameKey = self:NormalizeMobLearningKey(targetName)
  if not targetNameKey then
    return nil
  end

  local loadoutKey, reliable = self:GetWeaponPoisonLoadoutKey()
  if reliable then
    return targetNameKey .. "|" .. loadoutKey
  end

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return nil
  end

  return targetNameKey .. "|unknown|" .. tostring(targetKey)
end

function addon:ClearTargetPoisonImmunity(reason, targetName)
  local immunity = self.state.poisonImmunity
  local computedKey = self:GetPoisonImmunityKey(
    targetName or (immunity and immunity.targetName) or UnitName("target")
  )

  if immunity then
    self:DebugEvent(
      "poison_immunity_cleared",
      tostring(immunity.targetName or "target"),
      tostring(reason or "unspecified")
    )
  end

  if immunity and immunity.immunityKey then
    self.state.poisonImmunities[immunity.immunityKey] = nil
  end
  if computedKey then
    self.state.poisonImmunities[computedKey] = nil
  end

  self.state.poisonImmunity = nil
  if self.poisonImmunityFrame then
    self.poisonImmunityFrame:Hide()
  end
end

function addon:IsCurrentTargetPoisonImmune()
  if not self:IsHostileTarget() then
    self.state.poisonImmunity = nil
    if self.poisonImmunityFrame then
      self.poisonImmunityFrame:Hide()
    end
    return false
  end

  local targetName = UnitName("target")
  local immunityKey = self:GetPoisonImmunityKey(targetName)
  local targetKey = self:GetTargetKey()
  if not immunityKey or not targetKey then
    self.state.poisonImmunity = nil
    return false
  end

  local immunity = self.state.poisonImmunities[immunityKey]
  if not immunity then
    self.state.poisonImmunity = nil
    if self.poisonImmunityFrame then
      self.poisonImmunityFrame:Hide()
    end
    return false
  end

  immunity.targetKey = targetKey
  immunity.targetName = targetName
  self.state.poisonImmunity = immunity
  return true
end

function addon:MarkCurrentTargetPoisonImmune(spellName, message, observedTargetName)
  if not self:IsHostileTarget() or not self:IsPoisonImmunitySpell(spellName) then
    return false
  end

  local targetName = UnitName("target")
  if not targetName or targetName == "" then
    return false
  end

  if observedTargetName
    and observedTargetName ~= ""
    and string.lower(observedTargetName) ~= string.lower(targetName) then
    return false
  end

  local targetKey = self:GetTargetKey()
  local immunityKey = self:GetPoisonImmunityKey(targetName)
  if not targetKey or not immunityKey then
    return false
  end

  local normalizedSpell = spellName
  local current = self.state.poisonImmunities[immunityKey]
  if current then
    current.targetKey = targetKey
    current.targetName = targetName
    current.spellName = normalizedSpell
    current.message = message
    current.detectedAt = GetTime()
    self.state.poisonImmunity = current
    self:UpdatePoisonImmunityFrame()
    return true
  end

  local immunity = {
    immunityKey = immunityKey,
    targetKey = targetKey,
    targetName = targetName,
    spellName = normalizedSpell,
    message = message,
    detectedAt = GetTime(),
  }
  self.state.poisonImmunities[immunityKey] = immunity
  self.state.poisonImmunity = immunity
  self:DebugEvent(
    "poison_immunity_remembered",
    tostring(targetName),
    tostring(normalizedSpell)
  )
  self:UpdatePoisonImmunityFrame()
  return true
end

local originalGetPreferredBuilder = addon.GetPreferredBuilder
function addon:GetPreferredBuilder(context)
  context = context or self:GetComboPointContext(self.state.activeRotationMode or "builder")

  if not self:ShouldUsePhysicalBuilderRotation(context) then
    return originalGetPreferredBuilder(self, context)
  end

  local modeHint = context and context.mode or self.state.activeRotationMode or "builder"
  local candidates = {
    "Backstab",
    "Surprise Attack",
    "Hemorrhage",
    "Sinister Strike",
  }
  local bestSpell = nil
  local bestScore = nil

  for _, spellName in ipairs(candidates) do
    local score = self:GetBuilderSpellScore(spellName, context, modeHint)
    if score and (not bestScore or score > bestScore) then
      bestSpell = spellName
      bestScore = score
    end
  end

  if not bestSpell then
    return nil
  end

  local reason = "Highest-scoring legal physical builder"
  if context and context.poisonImmune then
    reason = "Poison-immune target; scoring physical builders"
  elseif context and context.hasWeaponPoison == false then
    reason = "No active weapon poison; scoring physical builders"
  end

  return bestSpell, {
    reasons = {
      reason,
      "Selected by the existing Builder spell scores",
    },
  }
end
