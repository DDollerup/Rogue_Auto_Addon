local addon = RogueAuto

addon.eviscerateFallbackApPerComboPoint = 0.03
addon.eviscerateLearningConfidenceSamples = 8
addon.eviscerateLearningAverageSamples = 12

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
end

local function roundDamage(value)
  return math.floor((value or 0) + 0.5)
end

local function findComboPointRange(text, comboPoints)
  if not text or comboPoints < 1 or comboPoints > 5 then
    return nil, nil
  end

  local lower = string.lower(text)
  local label = tostring(comboPoints) .. (comboPoints == 1 and " point" or " points")
  local patterns = {
    label .. "%s*:%s*(%d+)%s*%-%s*(%d+)",
    label .. "%s*:%s*(%d+)%s+to%s+(%d+)",
    label .. "%s+(%d+)%s*%-%s*(%d+)",
  }

  for _, pattern in ipairs(patterns) do
    local _, _, minDamage, maxDamage = string.find(lower, pattern)
    if minDamage and maxDamage then
      return tonumber(minDamage), tonumber(maxDamage)
    end
  end

  return nil, nil
end

function addon:GetEviscerateAttackPowerCoefficient(tooltipText)
  local lower = string.lower(tooltipText or "")
  local patterns = {
    "increased by (%d+%.?%d*)%% of your attack power per combo point",
    "(%d+%.?%d*)%% of your attack power per combo point",
    "(%d+%.?%d*)%% of attack power per combo point",
  }

  for _, pattern in ipairs(patterns) do
    local _, _, percent = string.find(lower, pattern)
    if percent then
      return (tonumber(percent) or 3) / 100, "tooltip"
    end
  end

  return self.eviscerateFallbackApPerComboPoint or 0.03, "1.12 fallback"
end

function addon:GetEviscerateBaseDamageTable()
  local spellIndex = self:GetSpellIndex("Eviscerate")
  if not spellIndex then
    return nil
  end

  local _, rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
  local tooltipText = self:GetSpellTooltipText("Eviscerate")
  if not tooltipText then
    return nil
  end

  local damageByComboPoint = {}
  for comboPoints = 1, 5 do
    local minDamage, maxDamage = findComboPointRange(tooltipText, comboPoints)
    if minDamage and maxDamage then
      damageByComboPoint[comboPoints] = {
        min = minDamage,
        max = maxDamage,
      }
    end
  end

  local coefficient, coefficientSource = self:GetEviscerateAttackPowerCoefficient(tooltipText)
  return damageByComboPoint, rank or "", coefficient, coefficientSource
end

function addon:GetCurrentAttackPower()
  if not UnitAttackPower then
    return 0
  end

  local base, positive, negative = UnitAttackPower("player")
  local attackPower = (base or 0) + (positive or 0) + (negative or 0)
  return math.max(attackPower, 0)
end

function addon:GetEviscerateTargetProfileKey()
  if not UnitExists("target") then
    return nil
  end

  local targetName = UnitName("target")
  local learningKey = self:NormalizeMobLearningKey(targetName)
  if not learningKey then
    return nil
  end

  local level = UnitLevel("target") or 0
  return learningKey .. "|level=" .. tostring(level), targetName, level
end

function addon:GetEviscerateLearningStore()
  if not RogueAutoDB then
    return nil
  end

  RogueAutoDB.learning = RogueAutoDB.learning or {}
  RogueAutoDB.learning.eviscerateDamageProfiles = RogueAutoDB.learning.eviscerateDamageProfiles or {}
  return RogueAutoDB.learning.eviscerateDamageProfiles
end

function addon:GetEviscerateProfileByKey(profileKey, targetName, level, create)
  local store = self:GetEviscerateLearningStore()
  if not store or not profileKey then
    return nil
  end

  local profile = store[profileKey]
  if not profile and create then
    profile = {
      name = targetName,
      level = level,
      samples = 0,
      effectiveMultiplier = 1,
      lastActualDamage = 0,
      lastRawMidpoint = 0,
      lastSeen = 0,
    }
    store[profileKey] = profile
  end

  return profile
end

function addon:GetEviscerateTargetProfile(create)
  local profileKey, targetName, level = self:GetEviscerateTargetProfileKey()
  return self:GetEviscerateProfileByKey(profileKey, targetName, level, create), profileKey
end

function addon:GetEviscerateLearnedMultiplier()
  local profile = self:GetEviscerateTargetProfile(false)
  if not profile or (profile.samples or 0) <= 0 then
    return 1, 0, 0
  end

  local samples = profile.samples or 0
  local confidenceSamples = self.eviscerateLearningConfidenceSamples or 8
  local confidence = clamp(samples / confidenceSamples, 0, 1)
  return profile.effectiveMultiplier or 1, confidence, samples
end

function addon:GetEstimatedEviscerateDamage(context)
  local comboPoints = context and context.comboPoints or self:GetComboPoints()
  if not comboPoints or comboPoints < 1 then
    return nil
  end
  if comboPoints > 5 then
    comboPoints = 5
  end

  local damageByComboPoint, rank, coefficient, coefficientSource = self:GetEviscerateBaseDamageTable()
  local baseDamage = damageByComboPoint and damageByComboPoint[comboPoints] or nil
  if not baseDamage then
    return nil
  end

  local attackPower = self:GetCurrentAttackPower()
  local attackPowerBonus = attackPower * coefficient * comboPoints
  local rawMin = baseDamage.min + attackPowerBonus
  local rawMax = baseDamage.max + attackPowerBonus
  local multiplier, confidence, samples = self:GetEviscerateLearnedMultiplier()
  local estimatedMin = rawMin * multiplier
  local estimatedMax = rawMax * multiplier

  return roundDamage(estimatedMin), roundDamage(estimatedMax), confidence, {
    comboPoints = comboPoints,
    rank = rank,
    attackPower = attackPower,
    attackPowerCoefficient = coefficient,
    coefficientSource = coefficientSource,
    attackPowerBonus = attackPowerBonus,
    baseMin = baseDamage.min,
    baseMax = baseDamage.max,
    rawMin = rawMin,
    rawMax = rawMax,
    learnedMultiplier = multiplier,
    learnedSamples = samples,
  }
end

function addon:TraceEviscerateEstimate(minDamage, maxDamage, confidence, details)
  if not details then
    return
  end

  local confidencePct = math.floor((confidence or 0) * 100 + 0.5)
  self:Trace(
    "Eviscerate " .. tostring(details.rank or "") ..
    " at " .. tostring(details.comboPoints) .. " CP: AP=" .. tostring(details.attackPower) ..
    ", raw=" .. tostring(roundDamage(details.rawMin)) .. "-" .. tostring(roundDamage(details.rawMax)) ..
    ", estimated=" .. tostring(minDamage) .. "-" .. tostring(maxDamage) ..
    ", learned=" .. tostring(details.learnedSamples or 0) .. " samples/" ..
    tostring(confidencePct) .. "% confidence"
  )
end

function addon:RecordEviscerateEffectiveMultiplier(actualDamage, pending)
  if not pending or not pending.rawMidpoint or pending.rawMidpoint <= 0 then
    return
  end

  local sampleMultiplier = actualDamage / pending.rawMidpoint
  if sampleMultiplier < 0.20 or sampleMultiplier > 1.50 then
    self:Trace(
      "Eviscerate learning ignored outlier: actual=" .. tostring(actualDamage) ..
      ", raw midpoint=" .. tostring(roundDamage(pending.rawMidpoint))
    )
    return
  end

  local profile = self:GetEviscerateProfileByKey(
    pending.profileKey,
    pending.targetName,
    pending.targetLevel,
    true
  )
  if not profile then
    return
  end

  local previousSamples = profile.samples or 0
  local previousMultiplier = profile.effectiveMultiplier or 1
  local averagingSamples = self.eviscerateLearningAverageSamples or 12
  local nextMultiplier

  if previousSamples < averagingSamples then
    nextMultiplier = ((previousMultiplier * previousSamples) + sampleMultiplier) / (previousSamples + 1)
  else
    nextMultiplier = (previousMultiplier * 0.85) + (sampleMultiplier * 0.15)
  end

  profile.samples = previousSamples + 1
  profile.effectiveMultiplier = clamp(nextMultiplier, 0.20, 1.50)
  profile.lastActualDamage = actualDamage
  profile.lastRawMidpoint = pending.rawMidpoint
  profile.lastSeen = time and time() or 0

  self:Trace(
    "Eviscerate learned on " .. tostring(profile.name or "target") ..
    ": actual=" .. tostring(actualDamage) ..
    ", effective multiplier=" .. string.format("%.3f", profile.effectiveMultiplier) ..
    " from " .. tostring(profile.samples) .. " samples"
  )
end

function addon:HandleEviscerateDamageMessage(message)
  local pending = self.state.pendingEviscerateEstimate
  if not pending or not message then
    return
  end

  if GetTime() > (pending.expiresAt or 0) then
    self.state.pendingEviscerateEstimate = nil
    return
  end

  local targetName, amount
  local isCrit = false
  _, _, targetName, amount = string.find(message, "^Your Eviscerate hits (.-) for (%d+)")
  if not targetName then
    _, _, targetName, amount = string.find(message, "^Your Eviscerate crits (.-) for (%d+)")
    isCrit = targetName ~= nil
  end

  if not targetName or not amount then
    return
  end

  targetName = string.gsub(targetName, "%s+$", "")
  if pending.targetName
    and string.lower(targetName) ~= string.lower(pending.targetName) then
    return
  end

  self.state.pendingEviscerateEstimate = nil
  local actualDamage = tonumber(amount)
  if not actualDamage then
    return
  end

  if isCrit then
    self:Trace("Eviscerate crit observed for " .. tostring(actualDamage) .. "; excluded from mitigation learning")
    return
  end

  local lower = string.lower(message)
  if string.find(lower, "blocked", 1, true) or string.find(lower, "absorbed", 1, true) then
    self:Trace("Eviscerate modified hit observed; excluded from mitigation learning")
    return
  end

  self:RecordEviscerateEffectiveMultiplier(actualDamage, pending)
end

local originalCast = addon.Cast
function addon:Cast(name)
  if name ~= "Eviscerate" then
    return originalCast(self, name)
  end

  local minDamage, maxDamage, confidence, details = self:GetEstimatedEviscerateDamage()
  local profileKey, targetName, targetLevel = self:GetEviscerateTargetProfileKey()
  local success = originalCast(self, name)
  if not success then
    return false
  end

  if details then
    self.state.pendingEviscerateEstimate = {
      profileKey = profileKey,
      targetName = targetName,
      targetLevel = targetLevel,
      rawMidpoint = (details.rawMin + details.rawMax) * 0.5,
      comboPoints = details.comboPoints,
      expiresAt = GetTime() + 2.5,
    }
    self:TraceEviscerateEstimate(minDamage, maxDamage, confidence, details)
  end

  return true
end

local originalOnSpellSelfDamage = addon.OnSpellSelfDamage
function addon:OnSpellSelfDamage(message)
  originalOnSpellSelfDamage(self, message)
  self:HandleEviscerateDamageMessage(message)
end
