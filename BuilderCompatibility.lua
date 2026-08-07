local addon = RogueAuto

local function isLegacyTruthy(value)
  return value == true or value == 1
end

local function getLegacySpellUsability(self, name)
  if not IsUsableSpell then
    return true, false
  end

  local spellIndex = self:GetSpellIndex(name)
  if not spellIndex then
    return false, false
  end

  local usable, noMana = IsUsableSpell(spellIndex, BOOKTYPE_SPELL)
  return isLegacyTruthy(usable), isLegacyTruthy(noMana)
end

-- Vanilla 1.12 spellbook APIs use spell index + BOOKTYPE_SPELL. Treat nil
-- usability as false; reactive abilities must be explicitly reported usable.
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

  local usable, noMana = getLegacySpellUsability(self, name)
  return usable and not noMana
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

    local usable, noMana = getLegacySpellUsability(self, "Surprise Attack")
    if not usable or noMana then
      return false
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
-- Use the authoritative legacy event globals while retaining compatibility
-- with clients that pass event arguments to the script callback.
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

local function normalizePoisonImmunityName(self, name)
  if not name or name == "" then
    return nil
  end

  local lowerName = string.lower(name)
  for _, knownName in ipairs(self.weaponPoisonNames or {}) do
    if string.find(lowerName, string.lower(knownName), 1, true) then
      return string.lower(knownName)
    end
  end

  if string.find(lowerName, "envenom", 1, true) then
    return "envenom"
  end
  if string.find(lowerName, "noxious assault", 1, true) then
    return "noxious assault"
  end

  return lowerName
end

function addon:GetPoisonImmunityKey(targetName, poisonName)
  local targetNameKey = self:NormalizeMobLearningKey(targetName)
  local poisonKey = normalizePoisonImmunityName(self, poisonName)
  if not targetNameKey or not poisonKey then
    return nil
  end

  return targetNameKey .. "|" .. poisonKey
end

function addon:GetTargetPoisonImmunity(poisonName, targetName)
  targetName = targetName or UnitName("target")
  local immunityKey = self:GetPoisonImmunityKey(targetName, poisonName)
  if not immunityKey then
    return nil
  end

  return self.state.poisonImmunities[immunityKey]
end

function addon:IsCurrentTargetPoisonSpellImmune(poisonName)
  if not self:IsHostileTarget() then
    return false
  end

  return self:GetTargetPoisonImmunity(poisonName) ~= nil
end

function addon:ClearSpecificTargetPoisonImmunity(poisonName, reason, targetName)
  targetName = targetName or UnitName("target")
  local immunityKey = self:GetPoisonImmunityKey(targetName, poisonName)
  if not immunityKey then
    return false
  end

  local immunity = self.state.poisonImmunities[immunityKey]
  if not immunity then
    return false
  end

  self.state.poisonImmunities[immunityKey] = nil
  if self.state.poisonImmunity == immunity then
    self.state.poisonImmunity = nil
  end

  self:DebugEvent(
    "poison_immunity_cleared",
    tostring(targetName or "target"),
    tostring(reason or poisonName or "unspecified")
  )
  return true
end

-- With no poison argument this preserves the legacy meaning: clear all
-- remembered poison evidence for the named target. A poison argument clears
-- only that poison or poison-dependent ability.
function addon:ClearTargetPoisonImmunity(reason, targetName, poisonName)
  targetName = targetName or (self.state.poisonImmunity and self.state.poisonImmunity.targetName) or UnitName("target")
  if not targetName then
    self.state.poisonImmunity = nil
    return
  end

  if poisonName then
    self:ClearSpecificTargetPoisonImmunity(poisonName, reason, targetName)
  else
    local targetNameKey = self:NormalizeMobLearningKey(targetName)
    if targetNameKey then
      local prefix = targetNameKey .. "|"
      for immunityKey in pairs(self.state.poisonImmunities) do
        if string.sub(immunityKey, 1, string.len(prefix)) == prefix then
          self.state.poisonImmunities[immunityKey] = nil
        end
      end
    end
    self.state.poisonImmunity = nil
  end

  if self.poisonImmunityFrame then
    self.poisonImmunityFrame:Hide()
  end
end

-- Global physical mode is appropriate only when every identifiable active
-- weapon poison is known immune. A single immune poison no longer disables
-- another poison that still works.
function addon:IsCurrentTargetPoisonImmune()
  if not self:IsHostileTarget() then
    self.state.poisonImmunity = nil
    if self.poisonImmunityFrame then
      self.poisonImmunityFrame:Hide()
    end
    return false
  end

  local states = self:GetWeaponPoisonStates()
  local identifiedPoisons = 0
  local immunePoisons = 0
  local hasUnidentifiedEnchant = false
  local representativeImmunity = nil

  for _, state in ipairs(states or {}) do
    if state.name then
      identifiedPoisons = identifiedPoisons + 1
      local immunity = self:GetTargetPoisonImmunity(state.name)
      if immunity then
        immunePoisons = immunePoisons + 1
        representativeImmunity = representativeImmunity or immunity
      end
    else
      hasUnidentifiedEnchant = true
    end
  end

  local allActivePoisonsImmune = identifiedPoisons > 0
    and immunePoisons == identifiedPoisons
    and not hasUnidentifiedEnchant

  if not allActivePoisonsImmune then
    self.state.poisonImmunity = nil
    if self.poisonImmunityFrame then
      self.poisonImmunityFrame:Hide()
    end
    return false
  end

  self.state.poisonImmunity = representativeImmunity
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
  local normalizedSpell = normalizePoisonImmunityName(self, spellName)
  local immunityKey = self:GetPoisonImmunityKey(targetName, normalizedSpell)
  if not targetKey or not immunityKey or not normalizedSpell then
    return false
  end

  local immunity = self.state.poisonImmunities[immunityKey]
  if not immunity then
    immunity = {
      immunityKey = immunityKey,
      poisonName = normalizedSpell,
    }
    self.state.poisonImmunities[immunityKey] = immunity
  end

  immunity.targetKey = targetKey
  immunity.targetName = targetName
  immunity.spellName = spellName
  immunity.message = message
  immunity.detectedAt = GetTime()

  self:DebugEvent(
    "poison_immunity_remembered",
    tostring(targetName),
    tostring(spellName)
  )

  if self:IsCurrentTargetPoisonImmune() then
    self:UpdatePoisonImmunityFrame()
  end
  return true
end

-- Clear only the poison/ability that later succeeds. Successful Deadly Poison,
-- for example, must not erase remembered Instant Poison immunity.
function addon:OnPoisonCombatMessage(message)
  local immuneTarget, immuneSpell = self:ExtractPoisonImmunityEvidence(message)
  if immuneTarget and immuneSpell then
    self:MarkCurrentTargetPoisonImmune(immuneSpell, message, immuneTarget)
    return
  end

  local successTarget, successSpell = self:ExtractPositivePoisonEvidence(message)
  if not successTarget or not successSpell then
    return
  end

  local targetName = UnitName("target")
  if targetName and string.lower(successTarget) == string.lower(targetName) then
    self:ClearSpecificTargetPoisonImmunity(
      successSpell,
      "later poison success: " .. tostring(successSpell),
      successTarget
    )
  end
end

local originalShouldRefreshBuilderBuff = addon.ShouldRefreshBuilderBuff
function addon:ShouldRefreshBuilderBuff(spellName, comboPoints, context)
  if spellName == "Envenom" and self:IsCurrentTargetPoisonSpellImmune("Envenom") then
    return false
  end

  return originalShouldRefreshBuilderBuff(self, spellName, comboPoints, context)
end

local originalAreBuilderMainBuffsSafe = addon.AreBuilderMainBuffsSafe
function addon:AreBuilderMainBuffsSafe(minimumRemaining, context)
  if self:IsCurrentTargetPoisonSpellImmune("Envenom") then
    local state = self:GetBuilderMainBuffState()
    local safeWindow = minimumRemaining or self.builderEviscerateSafeWindow or 10
    return state.sndActive and state.sndRemaining >= safeWindow
  end

  return originalAreBuilderMainBuffsSafe(self, minimumRemaining, context)
end

local originalGetBuilderSpellScore = addon.GetBuilderSpellScore
function addon:GetBuilderSpellScore(spellName, context, modeHint)
  if self:IsPoisonImmunitySpell(spellName)
    and self:IsCurrentTargetPoisonSpellImmune(spellName) then
    return nil
  end

  return originalGetBuilderSpellScore(self, spellName, context, modeHint)
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
    reason = "All active weapon poisons are immune; scoring physical builders"
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
