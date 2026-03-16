RogueAuto = RogueAuto or {}

local addon = RogueAuto

addon.version = "1.0.0"
addon.refreshWindow = {
  playerBuff = 2,
  targetDebuff = 3,
}
addon.observedDebuffDurations = {
  ["Rupture"] = 10,
  ["Shadow of Death"] = 8,
  ["Expose Armor"] = 20,
}
addon.closeRangeSpells = {
  "Kick",
  "Sinister Strike",
  "Hemorrhage",
  "Backstab",
  "Noxious Assault",
  "Cheap Shot",
  "Garrote",
  "Eviscerate",
  "Rupture",
}

addon.defaults = {
  targeting = {
    nearestFallback = true,
    autoStartAttack = true,
    autoAssist = false,
  },
  stealth = {
    integrated = true,
    pickPocketHumanoids = false,
  },
  builder = {
    mode = "auto",
  },
  core = {
    keepSliceAndDice = true,
    bleedSliceAndDiceFirst = true,
    directSliceAndDiceFirst = false,
    executeHealthPct = 20,
    softDefensives = {
      feint = true,
      ghostlyStrike = true,
      flourish = true,
    },
  },
  panic = {
    evasionPct = 45,
    vanishPct = 20,
  },
  interrupt = {
    kidneyMinCP = 1,
    useBlind = false,
  },
  minimap = {
    angle = 220,
  },
  debug = false,
}

addon.state = {
  knownSpells = {},
  lastEnergy = nil,
  firstEnergyTick = nil,
  riposteReadyUntil = 0,
  behindBlockedUntil = 0,
  lastUiError = nil,
  trackedDebuffs = {},
  pickPocketedTargets = {},
  pickPocketAttempts = {},
  pendingPickPocketTarget = nil,
  pendingPickPocketExpires = 0,
  attackSlot = nil,
  warnedMissingAttackSlot = false,
  targetSerial = 0,
  currentTargetKey = nil,
}

addon.buffAliases = {
  snd = "Slice and Dice",
  envenom = "Envenom",
  stealth = "Stealth",
  evasion = "Evasion",
  vanish = "Vanish",
  flourish = "Flourish",
  ghostlyStrike = "Ghostly Strike",
}

addon.buffTextures = {
  ["Slice and Dice"] = "ability_rogue_slicedice",
}

addon.dotBaseDurations = {
  ["Rupture"] = 6,
}

addon.dotPerPointDurations = {
  ["Rupture"] = 2,
}

addon.targetDebuffTextures = {
  ["Rupture"] = "ability_rogue_rupture",
}

addon.builderModes = {
  sinister = "Sinister Strike",
  hemo = "Hemorrhage",
  backstab = "Backstab",
  noxious = "Noxious Assault",
}

local frame = CreateFrame("Frame", "RogueAutoFrame", UIParent)
addon.frame = frame

local tooltip = CreateFrame("GameTooltip", "RogueAutoTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
addon.tooltip = tooltip

local function deepCopy(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, item in pairs(value) do
    copy[key] = deepCopy(item)
  end
  return copy
end

local function mergeDefaults(target, defaults)
  if type(defaults) ~= "table" then
    return target
  end

  if type(target) ~= "table" then
    target = {}
  end

  for key, value in pairs(defaults) do
    if type(value) == "table" then
      target[key] = mergeDefaults(target[key], value)
    elseif target[key] == nil then
      target[key] = value
    end
  end

  return target
end

function addon:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99RogueAuto:|r " .. message)
end

function addon:Debug(message)
  if RogueAutoDB and RogueAutoDB.debug then
    self:Print(message)
  end
end

function addon:InitDB()
  RogueAutoDB = mergeDefaults(RogueAutoDB, deepCopy(self.defaults))
end

function addon:ResetDB()
  RogueAutoDB = deepCopy(self.defaults)
  self:RefreshKnownSpells()
  self:Print("Settings reset to defaults.")
end

function addon:RefreshKnownSpells()
  self.state.knownSpells = {}

  for spellIndex = 1, 200 do
    local name = GetSpellName(spellIndex, BOOKTYPE_SPELL)
    if not name then
      break
    end
    self.state.knownSpells[name] = spellIndex
  end
end

function addon:HasSpell(name)
  return self.state.knownSpells[name] ~= nil
end

function addon:GetSpellIndex(name)
  return self.state.knownSpells[name]
end

function addon:IsSpellReady(name)
  local spellIndex = self:GetSpellIndex(name)
  if not spellIndex then
    return false
  end

  local startTime, duration = GetSpellCooldown(spellIndex, BOOKTYPE_SPELL)
  if not startTime or not duration then
    return true
  end

  return duration == 0
end

function addon:GetComboPoints()
  return GetComboPoints() or 0
end

function addon:GetEnergy()
  return UnitMana("player") or 0
end

function addon:GetPlayerHealthPct()
  local maxHealth = UnitHealthMax("player")
  if not maxHealth or maxHealth == 0 then
    return 100
  end
  return (UnitHealth("player") / maxHealth) * 100
end

function addon:GetTargetHealthPct()
  if not UnitExists("target") or UnitIsDead("target") then
    return 0
  end

  local maxHealth = UnitHealthMax("target")
  if not maxHealth or maxHealth == 0 then
    return 100
  end

  return (UnitHealth("target") / maxHealth) * 100
end

function addon:IsStealthed()
  local icon, name, active = GetShapeshiftFormInfo(1)
  if active == 1 then
    return true
  end

  local isActive = self:FindPlayerBuff(self.buffAliases.stealth)
  return isActive
end

function addon:IsBehindBlocked()
  return GetTime() < (self.state.behindBlockedUntil or 0)
end

function addon:MarkBehindBlocked()
  self.state.behindBlockedUntil = GetTime() + 1.5
end

function addon:IsSpellInRangeSafe(name, unit)
  if not IsSpellInRange then
    return nil
  end

  local spellIndex = self:GetSpellIndex(name)
  if spellIndex then
    local okByIndex, resultByIndex = pcall(IsSpellInRange, spellIndex, BOOKTYPE_SPELL, unit)
    if okByIndex and resultByIndex ~= nil then
      return resultByIndex
    end
  end

  local okByNameBook, resultByNameBook = pcall(IsSpellInRange, name, BOOKTYPE_SPELL, unit)
  if okByNameBook and resultByNameBook ~= nil then
    return resultByNameBook
  end

  local okByName, resultByName = pcall(IsSpellInRange, name, unit)
  if okByName and resultByName ~= nil then
    return resultByName
  end

  return nil
end

function addon:IsInMeleeRange()
  if not UnitExists("target") then
    return false
  end

  if CheckInteractDistance("target", 3) == 1 then
    return true
  end

  local kickRange = self:IsSpellInRangeSafe("Kick", "target")
  if kickRange == 1 then
    return true
  end

  return false
end

function addon:IsInCloseSpellRange()
  local sawOutOfRange = false

  for _, spellName in ipairs(self.closeRangeSpells) do
    if self:HasSpell(spellName) then
      local inRange = self:IsSpellInRangeSafe(spellName, "target")
      if inRange == 1 then
        return true
      end
      if inRange == 0 then
        sawOutOfRange = true
      end
    end
  end

  if sawOutOfRange then
    return false
  end

  return nil
end

function addon:GetAttackActionSlot()
  local cachedSlot = self.state.attackSlot
  if cachedSlot and IsAttackAction(cachedSlot) then
    return cachedSlot
  end

  self.state.attackSlot = nil
  for slot = 1, 120 do
    if IsAttackAction(slot) then
      self.state.attackSlot = slot
      return slot
    end
  end

  if RogueAutoDB and RogueAutoDB.debug and not self.state.warnedMissingAttackSlot then
    self.state.warnedMissingAttackSlot = true
    self:Print("Could not find the Attack action on any action bar slot. Auto-attack detection may be unreliable until Attack is placed on a bar.")
  end

  return nil
end

function addon:IsAutoAttacking()
  local attackSlot = self:GetAttackActionSlot()
  if not attackSlot then
    return nil
  end

  return IsCurrentAction(attackSlot) == 1
end

function addon:IsPickPocketRange()
  local spellRange = self:IsSpellInRangeSafe("Pick Pocket", "target")
  if spellRange == 1 then
    return true
  end
  if spellRange == 0 then
    return false
  end

  -- Some classic/Turtle client setups do not return a stable spell-range
  -- result for Pick Pocket. Only fall back to other close-range rogue spells,
  -- not the broader interaction-distance heuristic, to avoid burning attempts
  -- while still out of true melee range. If the client gives us no useful
  -- range data at all, allow the manual keypress and let UI-error handling
  -- roll back the attempt instead of suppressing Pick Pocket entirely.
  local closeRange = self:IsInCloseSpellRange()
  if closeRange == false then
    return false
  end

  return true
end

function addon:GetRangedWeaponType()
  local link = GetInventoryItemLink("player", 18)
  if not link or not GetItemInfo then
    return nil
  end

  local _, _, _, _, _, itemType, subType = GetItemInfo(link)
  if itemType ~= "Weapon" then
    return nil
  end

  return subType
end

function addon:IsDaggerEquipped()
  local mainHand = GetInventoryItemLink("player", 16)
  if not mainHand or not GetItemInfo then
    return false
  end

  local _, _, _, _, _, _, subType = GetItemInfo(mainHand)
  return subType == "Daggers"
end

function addon:CanAttemptBehindAction()
  if not UnitExists("target") then
    return false
  end

  if self:IsBehindBlocked() then
    return false
  end

  if UnitExists("targettarget") and UnitIsUnit("targettarget", "player") then
    return false
  end

  return true
end

function addon:FindPlayerBuff(name)
  for index = 0, 31 do
    local buffIndex = GetPlayerBuff(index, "HELPFUL")
    if buffIndex < 0 then
      break
    end

    local expectedTexture = self.buffTextures[name]
    if expectedTexture and GetPlayerBuffTexture then
      local texture = GetPlayerBuffTexture(buffIndex)
      if texture then
        local normalized = string.lower(string.gsub(texture, ".*\\", ""))
        if normalized == expectedTexture then
          return true, GetPlayerBuffTimeLeft(buffIndex) or 0
        end
      end
    end

    self.tooltip:ClearLines()
    self.tooltip:SetPlayerBuff(buffIndex)
    local text = RogueAutoTooltipTextLeft1 and RogueAutoTooltipTextLeft1:GetText()
    if text == name then
      return true, GetPlayerBuffTimeLeft(buffIndex) or 0
    end
  end

  return false, 0
end

function addon:FindUnitDebuffByName(unit, name)
  if not UnitExists(unit) then
    return false
  end

  for index = 1, 16 do
    local texture = UnitDebuff(unit, index)
    if not texture then
      break
    end

    self.tooltip:ClearLines()
    self.tooltip:SetUnitDebuff(unit, index)
    local text = RogueAutoTooltipTextLeft1 and RogueAutoTooltipTextLeft1:GetText()
    if text == name then
      return true
    end
  end

  return false
end

function addon:BuildTargetFingerprint()
  if not UnitExists("target") then
    return nil
  end

  local name = UnitName("target") or "unknown"
  local level = UnitLevel("target") or -1
  local maxHealth = UnitHealthMax("target") or 0
  local classification = UnitClassification and UnitClassification("target") or "normal"
  local creatureType = UnitCreatureType("target") or "unknown"

  return string.format("%s:%s:%s:%s:%s", name, tostring(level), tostring(maxHealth), tostring(classification), tostring(creatureType))
end

function addon:EnsureCurrentTargetKey()
  if not UnitExists("target") then
    self.state.currentTargetKey = nil
    return nil
  end

  if self.state.currentTargetKey then
    return self.state.currentTargetKey
  end

  self.state.targetSerial = (self.state.targetSerial or 0) + 1
  local fingerprint = self:BuildTargetFingerprint() or "unknown"
  self.state.currentTargetKey = fingerprint .. "#" .. tostring(self.state.targetSerial)
  return self.state.currentTargetKey
end

function addon:GetTargetKey()
  return self:EnsureCurrentTargetKey()
end

function addon:PrunePickPocketTargets()
  local now = GetTime()
  for key, expiry in pairs(self.state.pickPocketedTargets) do
    if expiry <= now then
      self.state.pickPocketedTargets[key] = nil
    end
  end
end

function addon:PrunePickPocketAttempts()
  local now = GetTime()
  for key, info in pairs(self.state.pickPocketAttempts) do
    if not info.expires or info.expires <= now then
      self.state.pickPocketAttempts[key] = nil
    end
  end
end

function addon:MarkTargetPickPocketed(targetKey)
  targetKey = targetKey or self:GetTargetKey()
  if not targetKey then
    return
  end

  -- Suppress repeated Pick Pocket attempts on the same target long enough
  -- for the next keypress to advance into an actual stealth opener.
  self.state.pickPocketedTargets[targetKey] = GetTime() + 10
  self.state.pickPocketAttempts[targetKey] = nil
end

function addon:HasRecentlyPickPocketedTarget()
  self:PrunePickPocketTargets()

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return false
  end

  local expiry = self.state.pickPocketedTargets[targetKey]
  return expiry and expiry > GetTime()
end

function addon:GetPickPocketAttemptCount()
  self:PrunePickPocketAttempts()

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return 0
  end

  local info = self.state.pickPocketAttempts[targetKey]
  if not info then
    return 0
  end

  return info.count or 0
end

function addon:BeginPickPocketAttempt()
  local targetKey = self:GetTargetKey()
  if not targetKey then
    return
  end

  local info = self.state.pickPocketAttempts[targetKey] or { count = 0, expires = 0 }
  info.count = info.count + 1
  info.expires = GetTime() + 15
  self.state.pickPocketAttempts[targetKey] = info

  self.state.pendingPickPocketTarget = targetKey
  self.state.pendingPickPocketExpires = GetTime() + 2
end

function addon:ClearPendingPickPocketAttempt()
  self.state.pendingPickPocketTarget = nil
  self.state.pendingPickPocketExpires = 0
end

function addon:RevertPendingPickPocketAttempt()
  local targetKey = self.state.pendingPickPocketTarget
  if targetKey then
    local info = self.state.pickPocketAttempts[targetKey]
    if info then
      info.count = math.max((info.count or 1) - 1, 0)
      if info.count <= 0 then
        self.state.pickPocketAttempts[targetKey] = nil
      else
        info.expires = GetTime() + 5
      end
    end
  end

  self:ClearPendingPickPocketAttempt()
end

function addon:PrunePendingPickPocketAttempt()
  if self.state.pendingPickPocketTarget and GetTime() > (self.state.pendingPickPocketExpires or 0) then
    self:ClearPendingPickPocketAttempt()
  end
end

function addon:CanAttemptPickPocket()
  if not RogueAutoDB.stealth.pickPocketHumanoids or not self:HasSpell("Pick Pocket") then
    return false
  end

  if UnitCreatureType("target") ~= "Humanoid" then
    return false
  end

  if self:HasRecentlyPickPocketedTarget() then
    return false
  end

  if self:GetPickPocketAttemptCount() >= 3 then
    return false
  end

  return self:IsPickPocketRange()
end

function addon:TrackTargetDebuff(name, duration)
  self:PruneTrackedDebuffs()

  local targetKey = self:GetTargetKey()
  if not targetKey or not duration then
    return
  end

  self.state.trackedDebuffs[targetKey] = self.state.trackedDebuffs[targetKey] or {}
  self.state.trackedDebuffs[targetKey][name] = GetTime() + duration
end

function addon:PruneTrackedDebuffs()
  local now = GetTime()

  for targetKey, targetDebuffs in pairs(self.state.trackedDebuffs) do
    local hasActiveDebuff = false

    for name, expiresAt in pairs(targetDebuffs) do
      if not expiresAt or expiresAt <= now then
        targetDebuffs[name] = nil
      else
        hasActiveDebuff = true
      end
    end

    if not hasActiveDebuff then
      self.state.trackedDebuffs[targetKey] = nil
    end
  end
end

function addon:SeedObservedTargetDebuff(name)
  local fallbackDuration = self.observedDebuffDurations[name]
  if not fallbackDuration then
    return 0
  end

  self:TrackTargetDebuff(name, fallbackDuration)
  return fallbackDuration
end

function addon:GetTrackedDebuffRemaining(name)
  self:PruneTrackedDebuffs()

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return 0
  end

  local targetDebuffs = self.state.trackedDebuffs[targetKey]
  if not targetDebuffs or not targetDebuffs[name] then
    return 0
  end

  local remaining = targetDebuffs[name] - GetTime()
  if remaining < 0 then
    targetDebuffs[name] = nil
    return 0
  end

  return remaining
end

function addon:IsTargetDebuffActive(name)
  if not UnitExists("target") then
    return false, 0
  end

  if self:FindUnitDebuffByName("target", name) then
    local remaining = self:GetTrackedDebuffRemaining(name)
    if remaining <= 0 then
      remaining = self:SeedObservedTargetDebuff(name)
    end
    return true, remaining
  end

  local trackedRemaining = self:GetTrackedDebuffRemaining(name)
  if trackedRemaining > 0 then
    return true, trackedRemaining
  end

  local expectedTexture = self.targetDebuffTextures[name]
  if expectedTexture then
    for index = 1, 16 do
      local texture = UnitDebuff("target", index)
      if not texture then
        break
      end

      local normalized = string.lower(string.gsub(texture, ".*\\", ""))
      if normalized == expectedTexture then
        if trackedRemaining <= 0 then
          trackedRemaining = self:SeedObservedTargetDebuff(name)
        end
        return true, trackedRemaining
      end
    end
  end

  return false, 0
end

function addon:TrackComboDebuff(name, comboPoints)
  local base = self.dotBaseDurations[name]
  local perPoint = self.dotPerPointDurations[name]
  if not base or not perPoint then
    return
  end

  local duration = base + (comboPoints * perPoint)
  self:TrackTargetDebuff(name, duration)
end

function addon:CanSpendComboPoints(minComboPoints)
  return self:GetComboPoints() >= (minComboPoints or 1)
end

function addon:TargetFallback()
  local hasTarget = UnitExists("target")
  local targetDead = hasTarget and UnitIsDead("target")

  if targetDead then
    ClearTarget()
    hasTarget = false
  end

  if hasTarget then
    return true
  end

  if not RogueAutoDB.targeting.nearestFallback then
    return false
  end

  TargetNearestEnemy()
  return UnitExists("target") and not UnitIsDead("target")
end

function addon:StartAttack()
  if not RogueAutoDB.targeting.autoStartAttack then
    return
  end

  -- Never break stealth before the opener logic gets a chance to run.
  if RogueAutoDB.stealth.integrated and self:IsStealthed() then
    return
  end

  if not UnitExists("target") or UnitIsDead("target") then
    return
  end

  local autoAttacking = self:IsAutoAttacking()
  if autoAttacking == false or autoAttacking == nil then
    AttackTarget()
  end
end

function addon:IsTargetTargetingPlayer()
  return UnitExists("targettarget") and UnitIsUnit("targettarget", "player")
end

function addon:CanCast(name)
  if not self:HasSpell(name) then
    return false
  end

  if name == "Pick Pocket" then
    if not self:IsPickPocketRange() then
      return false
    end
  end

  if not self:IsSpellReady(name) then
    return false
  end

  if IsUsableSpell then
    local usable, noMana = IsUsableSpell(name)
    if usable == nil then
      return true
    end
    return usable and not noMana
  end

  return true
end

function addon:Cast(name)
  if not self:CanCast(name) then
    return false
  end

  self:Debug("Casting " .. name)
  CastSpellByName(name)

  if name == "Pick Pocket" then
    self:BeginPickPocketAttempt()
  end

  return true
end

function addon:TryCast(name)
  if self:Cast(name) then
    return true
  end
  return false
end

function addon:TryCastWithComboTracking(name, comboPoints)
  if self:Cast(name) then
    if name == "Rupture" then
      self:TrackComboDebuff(name, comboPoints)
    elseif name == "Expose Armor" then
      self:TrackTargetDebuff(name, 30)
    elseif name == "Shadow of Death" then
      self:TrackTargetDebuff(name, 12)
    end
    return true
  end

  return false
end

function addon:GetPreferredBuilder()
  local mode = RogueAutoDB.builder.mode
  local forcedSpell = self.builderModes[mode]
  if forcedSpell and self:HasSpell(forcedSpell) then
    if forcedSpell == "Backstab" and (not self:IsDaggerEquipped() or self:IsBehindBlocked()) then
      return self:HasSpell("Sinister Strike") and "Sinister Strike" or forcedSpell
    end
    return forcedSpell
  end

  local preferredSpells = {
    "Noxious Assault",
    "Hemorrhage",
    "Backstab",
    "Sinister Strike",
  }

  for _, spellName in ipairs(preferredSpells) do
    if self:HasSpell(spellName) then
      if spellName == "Backstab" then
        if self:IsDaggerEquipped() and not self:IsBehindBlocked() then
          return spellName
        end
      else
        return spellName
      end
    end
  end

  if self:HasSpell("Sinister Strike") then
    return "Sinister Strike"
  end

  return nil
end

function addon:GetStealthOpener(mode)
  if not RogueAutoDB.stealth.integrated or not self:IsStealthed() then
    return nil
  end

  if self:CanAttemptPickPocket() then
    return "Pick Pocket"
  end

  if mode == "bleed" then
    if self:HasSpell("Garrote") and self:CanAttemptBehindAction() then
      return "Garrote"
    end
    if self:HasSpell("Cheap Shot") then
      return "Cheap Shot"
    end
    return nil
  end

  if self:HasSpell("Ambush") and self:IsDaggerEquipped() and self:CanAttemptBehindAction() then
    return "Ambush"
  end
  if self:HasSpell("Cheap Shot") then
    return "Cheap Shot"
  end

  return nil
end

function addon:TrySoftDefensives()
  if not self:IsTargetTargetingPlayer() then
    return false
  end

  if RogueAutoDB.core.softDefensives.feint and self:HasSpell("Feint") and self:TryCast("Feint") then
    return true
  end

  if RogueAutoDB.core.softDefensives.ghostlyStrike and self:HasSpell("Ghostly Strike") then
    local active, remaining = self:FindPlayerBuff(self.buffAliases.ghostlyStrike)
    if (not active or remaining < 2) and self:TryCast("Ghostly Strike") then
      return true
    end
  end

  if RogueAutoDB.core.softDefensives.flourish and self:HasSpell("Flourish") and self:GetComboPoints() > 0 then
    local active, remaining = self:FindPlayerBuff(self.buffAliases.flourish)
    if (not active or remaining < 2) and self:TryCast("Flourish") then
      return true
    end
  end

  return false
end

function addon:TryRiposte()
  if not self:HasSpell("Riposte") then
    return false
  end

  if GetTime() > (self.state.riposteReadyUntil or 0) then
    return false
  end

  if self:TryCast("Riposte") then
    self.state.riposteReadyUntil = 0
    return true
  end

  return false
end

function addon:TryMaintainBuff(name)
  if not self:HasSpell(name) then
    return false
  end

  if name == "Slice and Dice" and not RogueAutoDB.core.keepSliceAndDice then
    return false
  end

  if self:GetComboPoints() <= 0 then
    return false
  end

  local active, remaining = self:FindPlayerBuff(name)
  if (not active or remaining < self.refreshWindow.playerBuff) and self:TryCast(name) then
    return true
  end

  return false
end

function addon:TryMaintainTargetDebuff(name, comboThreshold)
  if not self:HasSpell(name) then
    return false
  end

  if self:GetComboPoints() < (comboThreshold or 1) then
    return false
  end

  local active, remaining = self:IsTargetDebuffActive(name)
  if active and remaining == 0 then
    return false
  end

  if (not active or remaining < self.refreshWindow.targetDebuff) then
    return self:TryCastWithComboTracking(name, self:GetComboPoints())
  end

  return false
end

function addon:ShouldPreferExecuteFinisher()
  if not self:HasSpell("Eviscerate") then
    return false
  end

  if self:GetComboPoints() <= 0 then
    return false
  end

  return self:GetTargetHealthPct() <= RogueAutoDB.core.executeHealthPct
end

function addon:ShouldFavorImmediateDamage()
  if not UnitExists("target") or UnitIsDead("target") then
    return false
  end

  if UnitClassification and UnitClassification("target") ~= "normal" then
    return false
  end

  return self:GetTargetHealthPct() <= math.max(RogueAutoDB.core.executeHealthPct, 60)
end

function addon:TryPreferredBuilder()
  local builder = self:GetPreferredBuilder()
  if builder then
    return self:TryCast(builder)
  end

  return false
end

function addon:TryDirectFinisher(minComboPoints)
  if not self:HasSpell("Eviscerate") then
    return false
  end

  if self:GetComboPoints() < (minComboPoints or 5) then
    return false
  end

  return self:TryCast("Eviscerate")
end

function addon:GetShootSpell()
  local weaponType = self:GetRangedWeaponType()
  if weaponType == "Thrown" then
    return "Throw"
  end
  if weaponType == "Bows" then
    return "Shoot Bow"
  end
  if weaponType == "Crossbows" then
    return "Shoot Crossbow"
  end
  if weaponType == "Guns" then
    return "Shoot Gun"
  end
  if weaponType == "Wands" then
    return "Shoot"
  end
  return nil
end

function addon:OnVariablesLoaded()
  self:InitDB()
end

function addon:OnPlayerLogin()
  self:RefreshKnownSpells()
  self:Debug("Loaded version " .. self.version)
end

function addon:OnSpellbookChanged()
  self:RefreshKnownSpells()
end

function addon:OnEnergyChanged(unit)
  if unit ~= "player" then
    return
  end

  local currentEnergy = self:GetEnergy()
  if self.state.lastEnergy and currentEnergy == self.state.lastEnergy + 20 then
    self.state.firstEnergyTick = GetTime()
  end
  self.state.lastEnergy = currentEnergy
end

function addon:OnCombatMiss(message)
  if not message then
    return
  end

  local lower = string.lower(message)
  if string.find(lower, "parry") then
    self.state.riposteReadyUntil = GetTime() + 5
  end
end

function addon:OnUiError(message)
  self.state.lastUiError = message
  if not message then
    return
  end

  local lower = string.lower(message)
  if string.find(lower, "behind your target") or string.find(lower, "must be behind") then
    self:MarkBehindBlocked()
  end

  if self.state.pendingPickPocketTarget then
    if string.find(lower, "too far away") or string.find(lower, "out of range") or string.find(lower, "line of sight") or string.find(lower, "closer") then
      self:RevertPendingPickPocketAttempt()
    end
  end
end

function addon:OnLootOpened()
  self:PrunePendingPickPocketAttempt()
  if self.state.pendingPickPocketTarget then
    self:MarkTargetPickPocketed(self.state.pendingPickPocketTarget)
    self:ClearPendingPickPocketAttempt()
  end
end

function addon:OnTargetChanged()
  self:PruneTrackedDebuffs()
  self.state.currentTargetKey = nil
  self:ClearPendingPickPocketAttempt()
end

frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_ENERGY")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

frame:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    addon:OnVariablesLoaded()
  elseif event == "PLAYER_LOGIN" then
    addon:OnPlayerLogin()
  elseif event == "UNIT_ENERGY" then
    addon:OnEnergyChanged(arg1)
  elseif event == "LEARNED_SPELL_IN_TAB" or event == "CHARACTER_POINTS_CHANGED" then
    addon:OnSpellbookChanged()
  elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
    addon:OnCombatMiss(arg1)
  elseif event == "UI_ERROR_MESSAGE" then
    addon:OnUiError(arg1)
  elseif event == "LOOT_OPENED" then
    addon:OnLootOpened()
  elseif event == "PLAYER_TARGET_CHANGED" then
    addon:OnTargetChanged()
  end
end)
