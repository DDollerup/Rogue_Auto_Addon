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

  if self:TryRotationKick() then
    return true
  end

  if self:TrySoftDefensives() then
    return true
  end

  if self:TryRiposte() then
    return true
  end

  if self:ShouldPreferExecuteFinisher(mode) then
    if self:TryExecuteFinisher(mode) then
      return true
    end
    return consumeBuilderAttempt(self)
  end

  return false
end

function addon:Bleed()
  self.state.activeRotationMode = "bleed"
  if not self:PrepareAction(true) then
    return
  end

  if self:RunDamagePreamble("bleed") then
    return
  end

  if self:TryHeuristicFinisher("bleed") then
    return
  end

  self:TryPreferredBuilder()
end

function addon:Direct()
  self.state.activeRotationMode = "direct"
  if not self:PrepareAction(true) then
    return
  end

  if self:RunDamagePreamble("direct") then
    return
  end

  if self:TryHeuristicFinisher("direct") then
    return
  end

  self:TryPreferredBuilder()
end

function addon:Interrupt()
  self.state.activeRotationMode = "interrupt"
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

  if self:TryHeuristicFinisher("interrupt") then
    return
  end
end

function addon:Defensive()
  self.state.activeRotationMode = "defensive"
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
