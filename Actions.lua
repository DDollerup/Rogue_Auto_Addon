local addon = RogueAuto

local function consumeBuilderAttempt(self)
  self:TryPreferredBuilder()
  return true
end

function addon:PrepareAction(needsTarget)
  self:InitDB()
  self:RefreshKnownSpells()

  if needsTarget and not self:TargetFallback() then
    return false
  end

  if UnitExists("target") and not UnitIsDead("target") then
    self:StartAttack()
  end

  if not needsTarget then
    return true
  end

  return UnitExists("target") and not UnitIsDead("target")
end

function addon:RunDamagePreamble(mode)
  local opener = self:GetStealthOpener(mode)
  if opener and self:TryCast(opener) then
    return true
  end

  if self:TrySoftDefensives() then
    return true
  end

  if self:TryRiposte() then
    return true
  end

  if self:ShouldPreferExecuteFinisher() then
    if self:TryDirectFinisher(1) then
      return true
    end
    return consumeBuilderAttempt(self)
  end

  return false
end

function addon:TryRotationDebuffStep(name, comboThreshold, guarantee)
  if self:TryMaintainTargetDebuff(name, comboThreshold) then
    return true
  end

  if guarantee and self:ShouldForceDebuffBeforeBuff(name, comboThreshold) then
    return consumeBuilderAttempt(self)
  end

  return false
end

function addon:TryRotationStep(step)
  if step.type == "buff" then
    return self:TryMaintainBuff(step.name)
  end

  if step.type == "debuff" then
    return self:TryRotationDebuffStep(step.name, step.comboThreshold, step.guarantee)
  end

  if step.type == "finisher" then
    return self:TryDirectFinisher(step.comboThreshold)
  end

  return false
end

function addon:RunMaintenancePlan(plan)
  for _, step in ipairs(plan) do
    if self:TryRotationStep(step) then
      return true
    end
  end

  return false
end

function addon:GetBleedMaintenancePlan()
  local settings = self:GetBleedSettings()
  local ruptureStep = {
    type = "debuff",
    name = "Rupture",
    comboThreshold = 3,
    guarantee = not settings.sliceAndDiceFirst and settings.guaranteePrimaryDebuff,
  }
  local shadowStep = {
    type = "debuff",
    name = "Shadow of Death",
    comboThreshold = 5,
    guarantee = false,
  }
  local buffSteps = {
    { type = "buff", name = "Slice and Dice" },
    { type = "buff", name = "Envenom" },
  }

  if settings.sliceAndDiceFirst then
    return {
      buffSteps[1],
      buffSteps[2],
      ruptureStep,
      shadowStep,
    }
  end

  return {
    ruptureStep,
    shadowStep,
    buffSteps[1],
    buffSteps[2],
  }
end

function addon:RunDirectGuaranteeStep()
  local settings = self:GetDirectSettings()
  if settings.sliceAndDiceFirst or not settings.guaranteePrimaryDebuff then
    return false
  end

  return self:TryRotationDebuffStep("Expose Armor", 3, true)
end

function addon:GetDirectMaintenancePlan()
  local settings = self:GetDirectSettings()
  local exposeStep = {
    type = "debuff",
    name = "Expose Armor",
    comboThreshold = 3,
    guarantee = not settings.sliceAndDiceFirst and settings.guaranteePrimaryDebuff,
  }
  local shadowStep = {
    type = "debuff",
    name = "Shadow of Death",
    comboThreshold = 5,
    guarantee = false,
  }
  local buffSteps = {
    { type = "buff", name = "Slice and Dice" },
    { type = "buff", name = "Envenom" },
  }
  local finisherStep = {
    type = "finisher",
    comboThreshold = 5,
  }

  if settings.sliceAndDiceFirst then
    return {
      buffSteps[1],
      exposeStep,
      buffSteps[2],
      finisherStep,
      shadowStep,
    }
  end

  return {
    exposeStep,
    buffSteps[1],
    buffSteps[2],
    finisherStep,
    shadowStep,
  }
end

function addon:Bleed()
  if not self:PrepareAction(true) then
    return
  end

  if self:RunDamagePreamble("bleed") then
    return
  end

  if self:RunMaintenancePlan(self:GetBleedMaintenancePlan()) then
    return
  end

  self:TryPreferredBuilder()
end

function addon:Direct()
  if not self:PrepareAction(true) then
    return
  end

  if self:RunDamagePreamble("direct") then
    return
  end

  if self:RunDirectGuaranteeStep() then
    return
  end

  if self:ShouldFavorImmediateDamage() then
    if self:TryDirectFinisher(5) then
      return
    end
    if self:TryPreferredBuilder() then
      return
    end
  end

  if self:RunMaintenancePlan(self:GetDirectMaintenancePlan()) then
    return
  end

  self:TryPreferredBuilder()
end

function addon:Interrupt()
  if not self:PrepareAction(true) then
    return
  end

  local shootSpell = self:GetShootSpell()
  if self:HasSpell("Deadly Throw") and self:GetRangedWeaponType() == "Thrown" then
    local inRange = self:IsSpellInRangeSafe("Deadly Throw", "target")
    if inRange == 1 and not self:IsInMeleeRange() and self:TryCast("Deadly Throw") then
      return
    end
  end

  if shootSpell then
    local inRange = self:IsSpellInRangeSafe(shootSpell, "target")
    if inRange == 1 and not self:IsInMeleeRange() and self:TryCast(shootSpell) then
      return
    end
  end

  if self:IsInMeleeRange() and self:TryCast("Kick") then
    return
  end

  if self:HasSpell("Kidney Shot") and self:CanSpendComboPoints(RogueAutoDB.interrupt.kidneyMinCP) and self:TryCast("Kidney Shot") then
    return
  end

  if self:TryCast("Gouge") then
    return
  end

  if self:GetSetting("useBlind") then
    self:TryCast("Blind")
  end
end

function addon:Defensive()
  if not self:PrepareAction(false) then
    return
  end

  local healthPct = self:GetPlayerHealthPct()

  if self:HasSpell("Vanish") and healthPct <= self:GetSetting("vanishPct") and self:TryCast("Vanish") then
    return
  end

  if self:HasSpell("Evasion") then
    local active, remaining = self:FindPlayerBuff("Evasion")
    if (not active or remaining < 2) and healthPct <= self:GetSetting("evasionPct") and self:TryCast("Evasion") then
      return
    end
  end

  if self:HasSpell("Flourish") and self:GetComboPoints() > 0 then
    local active, remaining = self:FindPlayerBuff("Flourish")
    if (not active or remaining < 2) and self:TryCast("Flourish") then
      return
    end
  end

  if self:HasSpell("Ghostly Strike") then
    local active, remaining = self:FindPlayerBuff("Ghostly Strike")
    if (not active or remaining < 2) and self:TryCast("Ghostly Strike") then
      return
    end
  end

  self:TryCast("Feint")
end
