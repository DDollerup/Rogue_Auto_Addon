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
