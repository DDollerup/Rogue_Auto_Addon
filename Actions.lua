local addon = RogueAuto

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

function addon:Bleed()
  if not self:PrepareAction(true) then
    return
  end

  local opener = self:GetStealthOpener("bleed")
  if opener and self:TryCast(opener) then
    return
  end

  if self:TrySoftDefensives() then
    return
  end

  if self:TryRiposte() then
    return
  end

  local preferExecute = self:ShouldPreferExecuteFinisher()
  if preferExecute and self:TryDirectFinisher(1) then
    return
  end

  if preferExecute then
    self:TryPreferredBuilder()
    return
  end

  if RogueAutoDB.core.bleedSliceAndDiceFirst then
    if self:TryMaintainBuff("Slice and Dice") then
      return
    end

    if self:TryMaintainBuff("Envenom") then
      return
    end

    if self:TryMaintainTargetDebuff("Rupture", 3) then
      return
    end

    if self:TryMaintainTargetDebuff("Shadow of Death", 5) then
      return
    end
  else
    if self:TryMaintainTargetDebuff("Rupture", 3) then
      return
    end

    if self:ShouldForceDebuffBeforeBuff("Rupture", 3) then
      self:TryPreferredBuilder()
      return
    end

    if self:TryMaintainTargetDebuff("Shadow of Death", 5) then
      return
    end

    if self:TryMaintainBuff("Slice and Dice") then
      return
    end

    if self:TryMaintainBuff("Envenom") then
      return
    end
  end

  self:TryPreferredBuilder()
end

function addon:Direct()
  if not self:PrepareAction(true) then
    return
  end

  local opener = self:GetStealthOpener("direct")
  if opener and self:TryCast(opener) then
    return
  end

  if self:TrySoftDefensives() then
    return
  end

  if self:TryRiposte() then
    return
  end

  local preferExecute = self:ShouldPreferExecuteFinisher()
  if preferExecute and self:TryDirectFinisher(1) then
    return
  end

  if preferExecute then
    self:TryPreferredBuilder()
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

  if RogueAutoDB.core.directSliceAndDiceFirst then
    if self:TryMaintainBuff("Slice and Dice") then
      return
    end

    if self:TryMaintainTargetDebuff("Expose Armor", 3) then
      return
    end

    if self:TryMaintainBuff("Envenom") then
      return
    end

    if self:TryDirectFinisher() then
      return
    end

    if self:TryMaintainTargetDebuff("Shadow of Death", 5) then
      return
    end
  else
    if self:TryMaintainTargetDebuff("Expose Armor", 3) then
      return
    end

    if self:ShouldForceDebuffBeforeBuff("Expose Armor", 3) then
      self:TryPreferredBuilder()
      return
    end

    if self:TryMaintainBuff("Slice and Dice") then
      return
    end

    if self:TryMaintainBuff("Envenom") then
      return
    end

    if self:TryDirectFinisher() then
      return
    end

    if self:TryMaintainTargetDebuff("Shadow of Death", 5) then
      return
    end
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

  if RogueAutoDB.interrupt.useBlind then
    self:TryCast("Blind")
  end
end

function addon:Defensive()
  if not self:PrepareAction(false) then
    return
  end

  local healthPct = self:GetPlayerHealthPct()

  if self:HasSpell("Vanish") and healthPct <= RogueAutoDB.panic.vanishPct and self:TryCast("Vanish") then
    return
  end

  if self:HasSpell("Evasion") then
    local active, remaining = self:FindPlayerBuff("Evasion")
    if (not active or remaining < 2) and healthPct <= RogueAutoDB.panic.evasionPct and self:TryCast("Evasion") then
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
