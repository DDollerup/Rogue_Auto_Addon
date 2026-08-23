RogueAuto = RogueAuto or {}

local addon = RogueAuto

addon.version = "1.0.4"
addon.refreshWindow = {
  playerBuff = 2,
  targetDebuff = 3,
}
addon.builderBuffEarlyRefreshWindow = 4
addon.builderBuffEmergencyRefreshWindow = 1.5
addon.builderBuffHighPointRefreshWindow = 6
addon.builderEviscerateSafeWindow = 10
addon.builderEviscerateShockWindow = 7
addon.builderEviscerateArmTimeout = 5
addon.envenomMinimumRemainingFightDuration = 3
addon.pickPocketActionDelay = 0.35
addon.pickPocketResetDuration = 600
addon.messageInterruptFallbackWindow = 2.5
addon.mindFlayChannelFallbackWindow = 3.5
addon.observedDebuffDurations = {
  ["Rupture"] = 10,
  ["Shadow of Death"] = 12,
  ["Expose Armor"] = 30,
}
addon.closeRangeSpells = {
  "Kick",
  "Surprise Attack",
  "Sinister Strike",
  "Hemorrhage",
  "Backstab",
  "Noxious Assault",
  "Cheap Shot",
  "Garrote",
  "Eviscerate",
  "Rupture",
}

addon.kickInterruptSpells = {
  ["shadow bolt"] = true,
  ["shadow bolt volley"] = true,
  ["fireball"] = true,
  ["frostbolt"] = true,
  ["arcane bolt"] = true,
  ["lightning bolt"] = true,
  ["chain lightning"] = true,
  ["wrath"] = true,
  ["starfire"] = true,
  ["smite"] = true,
  ["holy fire"] = true,
  ["mind blast"] = true,
  ["mind flay"] = true,
  ["venom spit"] = true,
  ["curse of thorns"] = true,
  ["flame buffet"] = true,
  ["mana burn"] = true,
  ["immolate"] = true,
  ["corruption"] = true,
  ["searing pain"] = true,
  ["soul fire"] = true,
  ["pyroblast"] = true,
  ["flamestrike"] = true,
  ["blizzard"] = true,
  ["rain of fire"] = true,
  ["fear"] = true,
  ["polymorph"] = true,
  ["sleep"] = true,
  ["banish"] = true,
  ["lesser heal"] = true,
  ["heal"] = true,
  ["greater heal"] = true,
  ["flash heal"] = true,
  ["prayer of healing"] = true,
  ["healing touch"] = true,
  ["regrowth"] = true,
  ["holy light"] = true,
  ["flash of light"] = true,
  ["healing wave"] = true,
  ["lesser healing wave"] = true,
  ["chain heal"] = true,
  ["dark mending"] = true,
}

addon.castStoppingControlSpells = {
  ["bash"] = true,
  ["blackout"] = true,
  ["blind"] = true,
  ["cheap shot"] = true,
  ["concussion blow"] = true,
  ["counterspell - silenced"] = true,
  ["death coil"] = true,
  ["fear"] = true,
  ["freezing trap effect"] = true,
  ["gouge"] = true,
  ["hammer of justice"] = true,
  ["impact"] = true,
  ["improved concussive shot"] = true,
  ["intercept stun"] = true,
  ["intimidating shout"] = true,
  ["kidney shot"] = true,
  ["polymorph"] = true,
  ["pounce"] = true,
  ["psychic scream"] = true,
  ["repentance"] = true,
  ["sap"] = true,
  ["scatter shot"] = true,
  ["seduction"] = true,
  ["silence"] = true,
  ["silenced"] = true,
  ["spell lock"] = true,
  ["war stomp"] = true,
  ["wyvern sting"] = true,
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
    useGhostlyStrike = false,
    useFlourish = false,
    useFeint = true,
    priorityOrder = nil,
  },
  mountGear = {
    enabled = false,
    autoSwap = false,
    profile = {},
  },
  minimap = {
    angle = 235,
  },
  ui = {
    comboPoints = {
      enabled = true,
      unlocked = false,
      x = 0,
      y = 58,
    },
    pickPocketStats = {
      enabled = true,
      unlocked = false,
      x = 0,
      y = -80,
    },
  },
  notifications = {
    highlightDuration = 8,
  },
  stats = {
    pickPocket = {
      lifetimeCopper = 0,
    },
  },
  roleplay = {
    enabled = false,
    personality = "silent",
    frequency = 35,
  },
  learning = {
    normalMobs = {},
    eliteMobs = {},
  },
  debug = false,
}

addon.state = {
  knownSpells = {},
  spellEnergyCosts = {},
  spellTooltipText = {},
  lastEnergy = nil,
  firstEnergyTick = nil,
  riposteReadyUntil = 0,
  surpriseAttackReadyUntil = 0,
  surpriseAttackTargetKey = nil,
  behindBlockedUntil = 0,
  behindBlockedTargetKey = nil,
  lastUiError = nil,
  lastSpellAttempt = nil,
  trackedDebuffs = {},
  pendingDebuffs = {},
  suppressedTargetSpells = {},
  pickPocketedTargets = {},
  pickPocketAttempts = {},
  pendingPickPocketTarget = nil,
  pendingPickPocketExpires = 0,
  pickPocketActionBlockedUntil = 0,
  attackSlot = nil,
  warnedMissingAttackSlot = false,
  targetSerial = 0,
  currentTargetKey = nil,
  learnedTargetKey = nil,
  learningFight = nil,
  activeEnemyCast = nil,
  suppressedEnemyCastBar = nil,
  pendingKidneyShotCheck = nil,
  builderEviscerateIntent = nil,
  activeRotationMode = nil,
  activeOpenerHint = nil,
  combatSession = nil,
  pickPocketLootSession = nil,
  activeNotices = {},
  pickPocketGold = {
    sessionStart = 0,
    sessionCopper = 0,
  },
  pickPocketRunTimer = {
    remaining = 600,
    startedAt = nil,
    running = false,
  },
  pickPocketMoneyTracking = nil,
  cachedPlayerCritChance = nil,
  selfBuffTimeline = {},
  trackedPlayerBuffs = {},
  pendingPlayerBuffs = {},
  lastExplicitEnergyGainAt = 0,
  lastExplicitEnergyGainMessage = nil,
  roleplay = {
    lastEmoteAt = 0,
    lastEventAt = {},
    lastPhraseIndex = {},
    lastDamageTarget = nil,
    lastDamageAt = 0,
  },
  variablesLoaded = false,
  playerLoginHandled = false,
  lastDebugMessage = nil,
}

addon.BuilderRuleResult = {
  CAST = "cast",
  CONTINUE = "continue",
  RESERVE_CONTINUE = "reserve_continue",
  BLOCKED_STOP = "blocked_stop",
}

addon.BuilderPriorityOrder = {
  "interrupts",
  "eviscerate_armed",
  "eviscerate_forced",
  "eviscerate_shock",
  "combat_buff_maintenance",
  "flourish_maintenance",
  "feint",
  "riposte",
  "eviscerate_arm",
  "preferred_builder",
}

addon.BuilderRules = {}

function addon:RegisterBuilderRule(rule)
  if rule and rule.id then
    self.BuilderRules[rule.id] = rule
  end
end

function addon:SetBuilderPriorityOrder(order)
  if type(order) ~= "table" then
    return false
  end

  local nextOrder = {}
  local seen = {}
  for _, ruleId in ipairs(order) do
    if self.BuilderRules[ruleId] and not seen[ruleId] then
      table.insert(nextOrder, ruleId)
      seen[ruleId] = true
    end
  end

  for _, ruleId in ipairs(self.BuilderPriorityOrder) do
    if self.BuilderRules[ruleId] and not seen[ruleId] then
      table.insert(nextOrder, ruleId)
      seen[ruleId] = true
    end
  end

  self.BuilderPriorityOrder = nextOrder
  return true
end

function addon:LoadBuilderPriorityOrder()
  if RogueAutoDB and RogueAutoDB.builder and type(RogueAutoDB.builder.priorityOrder) == "table" then
    self:SetBuilderPriorityOrder(RogueAutoDB.builder.priorityOrder)
  end
end

function addon:SaveBuilderPriorityOrder()
  if not RogueAutoDB or not RogueAutoDB.builder then
    return
  end

  RogueAutoDB.builder.priorityOrder = {}
  for _, ruleId in ipairs(self.BuilderPriorityOrder) do
    table.insert(RogueAutoDB.builder.priorityOrder, ruleId)
  end
end

function addon:MoveBuilderPriority(ruleId, direction)
  local order = self.BuilderPriorityOrder
  local index = nil
  for position, currentId in ipairs(order) do
    if currentId == ruleId then
      index = position
      break
    end
  end

  if not index then
    return false
  end

  local target = index + direction
  if target < 1 or target > table.getn(order) then
    return false
  end

  order[index], order[target] = order[target], order[index]
  return true
end

function addon:RunBuilderPriority(context)
  for _, ruleId in ipairs(self.BuilderPriorityOrder) do
    local rule = self.BuilderRules[ruleId]
    if rule and (not rule.when or rule.when(self, context)) then
      local result = rule.execute(self, context)
      local shouldStop = result == self.BuilderRuleResult.CAST or result == self.BuilderRuleResult.BLOCKED_STOP
      if shouldStop then
        if rule.trace then
          self:TraceEvent(rule.trace)
        end
        return result
      end
      if result == self.BuilderRuleResult.RESERVE_CONTINUE and rule.trace then
        self:TraceEvent(rule.trace)
      end
    end
  end

  return self.BuilderRuleResult.CONTINUE
end

addon.DebugEvents = {
  ["mount_gear_state"] = "Mount gear: %s - %s",
  ["mount_gear_attempt"] = "Mount gear transaction: %s from bag %s slot %s to %s",
  ["mount_gear_result"] = "Mount gear result: %s - %s",
  ["mount_gear_detection"] = "Mount gear detection: %s on %s",
  ["mount_gear_unknown"] = "Mount gear fallback matched aura %s: texture=%s id=%s",
  ["builder_rule_emergency_preamble"] = "Builder rule: emergency kick/riposte/interrupt preamble",
  ["builder_rule_feint"] = "Builder rule: feint",
  ["builder_rule_riposte"] = "Builder rule: riposte",
  ["builder_rule_armed_eviscerate_5cp"] = "Builder rule: armed Eviscerate at 5 CP",
  ["builder_cold_blood_armed_eviscerate"] = "Cold Blood: using for armed 5 CP Eviscerate",
  ["builder_rule_forced_eviscerate_5cp"] = "Builder rule: forced Eviscerate at 5 CP",
  ["builder_rule_combat_buff_upkeep"] = "Builder rule: combat buff upkeep",
  ["builder_rule_flourish_upkeep"] = "Builder rule: flourish upkeep",
  ["builder_rule_arm_eviscerate_4cp"] = "Builder rule: arm eviscerate at 4 CP",
  ["builder_rule_shock_eviscerate"] = "Builder rule: shock eviscerate",
  ["builder_rule_preferred_builder_fallback"] = "Builder rule: preferred builder fallback",
  ["builder_shock_eviscerate_armed"] = function(shockWindow)
    return "Shock Eviscerate path: arming at 4 CP with SnD/Envenom >= " .. tostring(shockWindow) .. "s"
  end,
  ["eviscerate_blocked_urgent"] = "Urgent Eviscerate blocked: %s",
  ["eviscerate_blocked_armed"] = "Armed Eviscerate blocked: %s",
  ["eviscerate_blocked_unarmed"] = "Eviscerate blocked: %s",
  ["eviscerate_cast_failed"] = "Eviscerate cast failed after passing checks",
  ["active_enemy_cast_cleared"] = "Clearing enemy cast %s (%s)",
  ["enemy_cast_tracking"] = "Tracking enemy cast %s from %s",
  ["builder_poison_check"] = "Builder poison check: equipped=%s, targetImmune=%s, rotation=%s, reason=%s",
  ["interrupt_decision"] = "Interrupt %s: source=%s, age=%s, remaining=%s, energy=%s/%s, melee=%s, kickReady=%s, decision=%s",
  ["casting_spell"] = "Casting %s",
  ["loaded_version"] = "Loaded version %s",
}

addon.damageCategories = {
  melee = "Melee",
  poisonDirect = "Poison Direct",
  bleedDot = "Bleeding (Phys DoT)",
  poisonDot = "Poison (DoT)",
  misc = "Misc",
}

addon.damageCategoryOrder = {
  "melee",
  "poisonDirect",
  "bleedDot",
  "poisonDot",
  "misc",
}

addon.damageCategoryTextures = {
  total = "Interface\\Icons\\Ability_CriticalStrike",
  energy = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
  melee = "Interface\\Icons\\INV_Sword_04",
  poisonDirect = "Interface\\Icons\\Ability_Poisons",
  bleedDot = "Interface\\Icons\\Ability_Rogue_Rupture",
  poisonDot = "Interface\\Icons\\INV_Potion_19",
  misc = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
}

addon.cooldownTrackedSpells = {
  "Kick",
  "Ghostly Strike",
  "Riposte",
  "Sprint",
  "Evasion",
  "Vanish",
  "Blind",
  "Blade Flurry",
  "Adrenaline Rush",
  "Cold Blood",
  "Preparation",
  "Premeditation",
}

addon.weaponPoisonFallbackTexture = "Interface\\Icons\\Ability_Poisons"
addon.weaponPoisonWarningTextures = {
  topLeft = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningCornerTopLeft",
  topRight = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningCornerTopRight",
  bottomLeft = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningCornerBottomLeft",
  bottomRight = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningCornerBottomRight",
  top = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningEdgeTop",
  bottom = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningEdgeBottom",
  left = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningEdgeLeft",
  right = "Interface\\AddOns\\RogueAuto\\Assets\\PoisonWarningEdgeRight",
}
addon.weaponPoisonLowCharges = 12
addon.weaponPoisonLowTimeMs = 5 * 60 * 1000
addon.weaponPoisonNames = {
  "Deadly Poison",
  "Instant Poison",
  "Crippling Poison",
  "Mind-numbing Poison",
  "Wound Poison",
  "Anesthetic Poison",
  "Numbing Poison",
  "Atrophic Poison",
  "Occult Poison",
}

addon.noticeAnchorInsetPct = 0.15
addon.noticeDefaultY = -120
addon.pickPocketFallbackTexture = "Interface\\Icons\\INV_Misc_Bag_10"
addon.coinTexture = "Interface\\Icons\\INV_Misc_Coin_01"
addon.pickPocketTitleTexture = "Interface\\Icons\\INV_Misc_Bag_10"

addon.bleedSpells = {
  ["Garrote"] = true,
  ["Rupture"] = true,
  ["Shadow of Death"] = true,
}

addon.poisonDirectSpells = {
  ["Envenom"] = true,
  ["Instant Poison"] = true,
  ["Noxious Assault"] = true,
  ["Wound Poison"] = true,
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

addon.selfBuffTimelineTrackedSpells = {
  "Slice and Dice",
  "Envenom",
  "Ghostly Strike",
  "Sprint",
  "Evasion",
  "Blade Flurry",
  "Adrenaline Rush",
  "Cold Blood",
  "Vanish",
}

addon.dotBaseDurations = {
  ["Rupture"] = 6,
}

addon.dotPerPointDurations = {
  ["Rupture"] = 2,
}

addon.comboBuffBaseDurations = {
  ["Slice and Dice"] = 6,
  ["Envenom"] = 8,
}

addon.comboBuffPerPointDurations = {
  ["Slice and Dice"] = 3,
  ["Envenom"] = 4,
}

addon.targetDebuffTextures = {
  ["Rupture"] = "ability_rogue_rupture",
}

addon.debuffTrackingPolicy = {
  ["Rupture"] = "strictTracked",
  ["Expose Armor"] = "sharedPresence",
  ["Shadow of Death"] = "strictTracked",
}

addon.targetDebuffSpellIds = {}

addon.builderModes = {
  sinister = "Sinister Strike",
  hemo = "Hemorrhage",
  backstab = "Backstab",
  noxious = "Noxious Assault",
}

addon.pickPocketTargetWhitelist = {
  ["Black Ooze"] = true,
}

addon.comboPointCount = 5
addon.comboPointInactiveColor = { 0.58, 0.52, 0.22, 0.5 }
addon.comboPointActiveColor = { 1, 0.82, 0.1, 1 }
addon.comboPointFadeDuration = 0.35
addon.comboPointIdleAlpha = 0
addon.comboPointUnlockedAlpha = 0.35
addon.comboPointBulletOffsets = {
  { -44, 0 },
  { -22, 15 },
  { 0, 22 },
  { 22, 15 },
  { 44, 0 },
}

local frame = CreateFrame("Frame", "RogueAutoFrame", UIParent)
addon.frame = frame

local tooltip = CreateFrame("GameTooltip", "RogueAutoTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
addon.tooltip = tooltip

local inventoryTooltip = CreateFrame("GameTooltip", "RogueAutoInventoryTooltip", UIParent, "GameTooltipTemplate")
inventoryTooltip:SetOwner(UIParent, "ANCHOR_NONE")
addon.inventoryTooltip = inventoryTooltip

function addon:EnsureComboPointFrame()
  if self.comboPointFrame then
    return self.comboPointFrame
  end

  local comboFrame = CreateFrame("Frame", "RogueAutoComboPointFrame", UIParent)
  comboFrame:SetWidth(120)
  comboFrame:SetHeight(46)
  comboFrame:SetFrameStrata("HIGH")
  comboFrame:SetFrameLevel(65)
  comboFrame:SetClampedToScreen(true)
  comboFrame:SetMovable(true)
  comboFrame:EnableMouse(false)
  comboFrame:RegisterForDrag("LeftButton")
  comboFrame:SetAlpha(0)
  comboFrame.points = {}
  comboFrame.isPositionInitialized = false
  comboFrame.currentAlpha = 0
  comboFrame.targetAlpha = 0

  for index = 1, self.comboPointCount do
    local point = comboFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    point:SetFont(STANDARD_TEXT_FONT, 26, "OUTLINE")
    point:SetText("o")
    point:SetJustifyH("CENTER")
    point:SetJustifyV("MIDDLE")

    local offset = self.comboPointBulletOffsets[index]
    point:SetPoint("CENTER", comboFrame, "CENTER", offset[1], offset[2])
    comboFrame.points[index] = point
  end

  comboFrame:SetScript("OnDragStart", function()
    if not RogueAutoDB or not RogueAutoDB.ui or not RogueAutoDB.ui.comboPoints or not RogueAutoDB.ui.comboPoints.unlocked then
      return
    end

    comboFrame:StartMoving()
  end)

  comboFrame:SetScript("OnDragStop", function()
    if not RogueAutoDB or not RogueAutoDB.ui or not RogueAutoDB.ui.comboPoints or not RogueAutoDB.ui.comboPoints.unlocked then
      comboFrame:StopMovingOrSizing()
      return
    end

    comboFrame:StopMovingOrSizing()
    local centerX, centerY = UIParent:GetCenter()
    local frameCenterX, frameCenterY = comboFrame:GetCenter()
    if centerX and centerY and frameCenterX and frameCenterY then
      RogueAutoDB.ui.comboPoints.x = frameCenterX - centerX
      RogueAutoDB.ui.comboPoints.y = frameCenterY - centerY
    end
    comboFrame.isPositionInitialized = true
    self:PositionComboPointFrame(true)
  end)

  self.comboPointFrame = comboFrame
  return comboFrame
end

function addon:PositionComboPointFrame(force)
  local comboFrame = self:EnsureComboPointFrame()
  if not comboFrame then
    return nil
  end

  local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.comboPoints
  if not settings or settings.enabled == false then
    return comboFrame
  end

  comboFrame:EnableMouse(settings.unlocked == true)

  if not settings.unlocked or force or not comboFrame.isPositionInitialized then
    comboFrame:ClearAllPoints()
    comboFrame:SetPoint("CENTER", UIParent, "CENTER", settings.x or 0, settings.y or 58)
    comboFrame.isPositionInitialized = true
  end

  return comboFrame
end

function addon:GetComboPointFrameTargetAlpha()
  local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.comboPoints
  if not settings or settings.enabled == false then
    return 0
  end

  if self:IsCombatSessionActive() then
    return 1
  end

  if settings.unlocked then
    return self.comboPointUnlockedAlpha
  end

  return self.comboPointIdleAlpha
end

function addon:UpdateComboPointFrameVisibility(force)
  local comboFrame = self:EnsureComboPointFrame()
  if not comboFrame then
    return
  end

  local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.comboPoints
  if not settings or settings.enabled == false then
    comboFrame.targetAlpha = 0
    comboFrame.currentAlpha = 0
    comboFrame.fadeStartAt = nil
    comboFrame.fadeFrom = nil
    comboFrame.fadeTo = nil
    comboFrame:SetAlpha(0)
    comboFrame:Hide()
    return
  end

  local now = GetTime()
  local targetAlpha = self:GetComboPointFrameTargetAlpha()
  local currentAlpha = comboFrame.currentAlpha
  if currentAlpha == nil then
    currentAlpha = comboFrame:GetAlpha() or 0
  end

  if force or comboFrame.targetAlpha ~= targetAlpha or comboFrame.fadeStartAt == nil then
    comboFrame.fadeStartAt = now
    comboFrame.fadeFrom = currentAlpha
    comboFrame.fadeTo = targetAlpha
    comboFrame.targetAlpha = targetAlpha
  end

  local alpha = targetAlpha
  local fadeFrom = comboFrame.fadeFrom or currentAlpha
  local fadeTo = comboFrame.fadeTo or targetAlpha
  local fadeDuration = self.comboPointFadeDuration or 0.35

  if fadeDuration > 0 and fadeFrom ~= nil and fadeTo ~= nil and fadeFrom ~= fadeTo then
    local progress = (now - (comboFrame.fadeStartAt or now)) / fadeDuration
    if progress < 0 then
      progress = 0
    elseif progress > 1 then
      progress = 1
    end
    alpha = fadeFrom + ((fadeTo - fadeFrom) * progress)
  end

  if alpha < 0 then
    alpha = 0
  elseif alpha > 1 then
    alpha = 1
  end

  comboFrame.currentAlpha = alpha
  comboFrame:SetAlpha(alpha)

  if alpha > 0 or targetAlpha > 0 then
    comboFrame:Show()
  else
    comboFrame:Hide()
  end
end

function addon:UpdateComboPointFrame(force)
  local now = GetTime()
  self:PositionComboPointFrame(force)
  self:UpdateComboPointFrameVisibility(force)

  local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.comboPoints
  if not settings or settings.enabled == false then
    return
  end

  if not force and self.state.nextComboPointUpdate and now < self.state.nextComboPointUpdate then
    return
  end

  self.state.nextComboPointUpdate = now + 0.08

  local comboFrame = self.comboPointFrame or self:EnsureComboPointFrame()
  if not comboFrame then
    return
  end

  local comboPoints = self:GetComboPoints()
  for index, point in ipairs(comboFrame.points) do
    if index <= comboPoints then
      point:SetTextColor(self.comboPointActiveColor[1], self.comboPointActiveColor[2], self.comboPointActiveColor[3], self.comboPointActiveColor[4])
    else
      point:SetTextColor(self.comboPointInactiveColor[1], self.comboPointInactiveColor[2], self.comboPointInactiveColor[3], self.comboPointInactiveColor[4])
    end
  end
end

local function createNoticeFrame(name, point, relativePoint, xOffset, yOffset)
  local noticeFrame = CreateFrame("Frame", name, UIParent)
  noticeFrame:SetWidth(340)
  noticeFrame:SetHeight(116)
  noticeFrame:SetPoint(point, UIParent, relativePoint, xOffset, yOffset)
  noticeFrame.anchorPoint = point
  noticeFrame.relativePoint = relativePoint
  noticeFrame.defaultYOffset = yOffset
  noticeFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
  })
  noticeFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
  noticeFrame:SetBackdropBorderColor(1, 0.82, 0, 0.85)
  noticeFrame:Hide()

  local noticeTitle = noticeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  noticeTitle:SetPoint("TOPLEFT", noticeFrame, "TOPLEFT", 14, -14)
  noticeTitle:SetPoint("TOPRIGHT", noticeFrame, "TOPRIGHT", -14, -14)
  noticeTitle:SetJustifyH("LEFT")
  noticeTitle:SetTextColor(1, 0.9, 0.35)
  noticeFrame.title = noticeTitle

  local titleIcon = noticeFrame:CreateTexture(nil, "ARTWORK")
  titleIcon:SetWidth(20)
  titleIcon:SetHeight(20)
  titleIcon:SetPoint("TOPLEFT", noticeFrame, "TOPLEFT", 14, -14)
  titleIcon:Hide()
  noticeFrame.titleIcon = titleIcon

  local divider = noticeFrame:CreateTexture(nil, "ARTWORK")
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", noticeTitle, "BOTTOMLEFT", 0, -8)
  divider:SetPoint("TOPRIGHT", noticeFrame, "TOPRIGHT", -14, 0)
  divider:SetTexture(1, 0.82, 0, 0.24)
  divider:Hide()
  noticeFrame.divider = divider

  local noticeBody = noticeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  noticeBody:SetPoint("TOPLEFT", noticeTitle, "BOTTOMLEFT", 0, -12)
  noticeBody:SetPoint("TOPRIGHT", noticeFrame, "TOPRIGHT", -14, 0)
  noticeBody:SetJustifyH("LEFT")
  noticeBody:SetJustifyV("TOP")
  noticeBody:SetTextColor(0.92, 0.92, 0.92)
  noticeFrame.body = noticeBody

  local totalRow = CreateFrame("Frame", nil, noticeFrame)
  totalRow:SetWidth(312)
  totalRow:SetHeight(20)
  totalRow:SetPoint("TOPLEFT", noticeTitle, "BOTTOMLEFT", 0, -14)
  totalRow:Hide()

  local totalIcon = totalRow:CreateTexture(nil, "ARTWORK")
  totalIcon:SetWidth(16)
  totalIcon:SetHeight(16)
  totalIcon:SetPoint("LEFT", totalRow, "LEFT", 0, 0)
  totalRow.icon = totalIcon

  local totalLabel = totalRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  totalLabel:SetPoint("LEFT", totalIcon, "RIGHT", 6, 0)
  totalLabel:SetJustifyH("LEFT")
  totalRow.label = totalLabel

  local totalValue = totalRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  totalValue:SetPoint("RIGHT", totalRow, "RIGHT", 0, 0)
  totalValue:SetJustifyH("RIGHT")
  totalValue:SetTextColor(1, 0.95, 0.65)
  totalRow.value = totalValue
  noticeFrame.totalRow = totalRow

  local energyRow = CreateFrame("Frame", nil, noticeFrame)
  energyRow:SetWidth(312)
  energyRow:SetHeight(18)
  energyRow:SetPoint("TOPLEFT", totalRow, "BOTTOMLEFT", 0, -6)
  energyRow:Hide()

  local energyIcon = energyRow:CreateTexture(nil, "ARTWORK")
  energyIcon:SetWidth(14)
  energyIcon:SetHeight(14)
  energyIcon:SetPoint("LEFT", energyRow, "LEFT", 1, 0)
  energyRow.icon = energyIcon

  local energyLabel = energyRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  energyLabel:SetPoint("LEFT", energyIcon, "RIGHT", 6, 0)
  energyLabel:SetJustifyH("LEFT")
  energyLabel:SetTextColor(0.92, 0.92, 0.92)
  energyRow.label = energyLabel

  local energyValue = energyRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  energyValue:SetPoint("RIGHT", energyRow, "RIGHT", 0, 0)
  energyValue:SetJustifyH("RIGHT")
  energyValue:SetTextColor(1, 1, 1)
  energyRow.value = energyValue
  noticeFrame.energyRow = energyRow

  noticeFrame.categoryRows = {}

  for index, categoryKey in ipairs(addon.damageCategoryOrder) do
    local row = CreateFrame("Frame", nil, noticeFrame)
    row:SetWidth(312)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", energyRow, "BOTTOMLEFT", 0, -6 - ((index - 1) * 20))
    row:Hide()

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(14)
    icon:SetHeight(14)
    icon:SetPoint("LEFT", row, "LEFT", 1, 0)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.92, 0.92, 0.92)
    row.label = label

    local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    value:SetJustifyH("RIGHT")
    value:SetTextColor(1, 1, 1)
    row.value = value

    noticeFrame.categoryRows[categoryKey] = row
  end

  noticeFrame.lootRows = {}

  for index = 1, 6 do
    local row = CreateFrame("Frame", nil, noticeFrame)
    row:SetWidth(312)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", noticeFrame, "TOPLEFT", 16, -52 - ((index - 1) * 22))
    row:Hide()

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(16)
    icon:SetHeight(16)
    icon:SetPoint("LEFT", row, "LEFT", 1, 0)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.96, 0.96, 0.96)
    row.label = label

    noticeFrame.lootRows[index] = row
  end

  return noticeFrame
end

local function setNoticeTitleLayout(noticeFrame, useIcon)
  if not noticeFrame or not noticeFrame.title then
    return
  end

  noticeFrame.title:ClearAllPoints()
  if useIcon then
    noticeFrame.title:SetPoint("TOPLEFT", noticeFrame, "TOPLEFT", 42, -14)
  else
    noticeFrame.title:SetPoint("TOPLEFT", noticeFrame, "TOPLEFT", 14, -14)
  end
  noticeFrame.title:SetPoint("TOPRIGHT", noticeFrame, "TOPRIGHT", -14, -14)
end

addon.noticeFrames = {
  combat = createNoticeFrame("RogueAutoCombatNoticeFrame", "TOPLEFT", "TOPLEFT", 24, addon.noticeDefaultY),
  pickPocket = createNoticeFrame("RogueAutoPickPocketNoticeFrame", "TOPRIGHT", "TOPRIGHT", -24, addon.noticeDefaultY),
}

addon.noticeFadeDuration = 0.35

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

local function trim(text)
  if not text then
    return ""
  end

  local _, _, stripped = string.find(text, "^%s*(.-)%s*$")
  return stripped or text
end

local function normalizeSpellName(name)
  if not name then
    return ""
  end

  local normalized = trim(name)
  normalized = string.gsub(normalized, "%s+[IVXLCM]+$", "")
  return normalized
end

local function isNatureSchool(school)
  if not school then
    return false
  end

  return string.lower(school) == "nature"
end

local function getFontStringHeight(region)
  if not region then
    return 0
  end

  if region.GetStringHeight then
    return region:GetStringHeight()
  end

  if region.GetHeight then
    return region:GetHeight()
  end

  return 0
end

local function normalizeLootEntry(text)
  if not text then
    return nil
  end

  local normalized = trim(text)
  normalized = string.gsub(normalized, "|c%x%x%x%x%x%x%x%x", "")
  normalized = string.gsub(normalized, "|H.-|h%[(.-)%]|h", "%1")
  normalized = string.gsub(normalized, "|H.-|h(.-)|h", "%1")
  normalized = string.gsub(normalized, "|h", "")
  normalized = string.gsub(normalized, "|r", "")
  normalized = string.gsub(normalized, "^%[(.-)%]$", "%1")
  normalized = string.gsub(normalized, "%.+$", "")
  normalized = trim(normalized)
  if normalized == "" then
    return nil
  end

  return normalized
end

local function inferPickPocketEntryTexture(text)
  local normalized = normalizeLootEntry(text)
  if not normalized then
    return addon.pickPocketFallbackTexture
  end

  if string.find(normalized, "Copper") or string.find(normalized, "Silver") or string.find(normalized, "Gold") then
    return addon.coinTexture
  end

  return addon.pickPocketFallbackTexture
end

local function normalizeTextureName(texture)
  if not texture or texture == "" then
    return nil
  end

  local normalized = string.lower(texture)
  normalized = string.gsub(normalized, ".*\\", "")
  normalized = string.gsub(normalized, ".*%/", "")
  normalized = string.gsub(normalized, "%.blp$", "")
  normalized = string.gsub(normalized, "%.tga$", "")
  if normalized == "" then
    return nil
  end

  return normalized
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

function addon:FormatDebugEvent(eventName, arg1, arg2, arg3, arg4)
  local eventDefinition = self.DebugEvents and self.DebugEvents[eventName]
  if not eventDefinition then
    return tostring(eventName)
  end

  if type(eventDefinition) == "function" then
    return eventDefinition(arg1, arg2, arg3, arg4)
  end

  if type(eventDefinition) == "string" then
    if string.find(eventDefinition, "%%") then
      local ok, formatted = pcall(string.format, eventDefinition, arg1, arg2, arg3, arg4)
      if ok then
        return formatted
      end
      return eventDefinition
    end
    return eventDefinition
  end

  if type(eventDefinition) == "table" and eventDefinition.template then
    if type(eventDefinition.template) == "function" then
      return eventDefinition.template(arg1, arg2, arg3, arg4)
    end
    local ok, formatted = pcall(string.format, eventDefinition.template, arg1, arg2, arg3, arg4)
    if ok then
      return formatted
    end
    return eventDefinition.template
  end

  return tostring(eventName)
end

function addon:Debug(message)
  if not (RogueAutoDB and RogueAutoDB.debug) then
    return
  end

  local text = tostring(message)
  if self.state.lastDebugMessage == text then
    return
  end

  self.state.lastDebugMessage = text
  self:Print(text)
end

function addon:DebugEvent(eventName, arg1, arg2, arg3, arg4)
  if not (RogueAutoDB and RogueAutoDB.debug) then
    return
  end

  self:Debug(self:FormatDebugEvent(eventName, arg1, arg2, arg3, arg4))
end

function addon:Trace(message)
  if RogueAutoDB and RogueAutoDB.debug then
    self:Debug(message)
    return
  end

  local text = "TRACE: " .. tostring(message)
  if self.state.lastDebugMessage == text then
    return
  end

  self.state.lastDebugMessage = text
  self:Print(text)
end

function addon:TraceEvent(eventName, arg1, arg2, arg3, arg4)
  local traceText = self:FormatDebugEvent(eventName, arg1, arg2, arg3, arg4)
  if traceText then
    self:Trace(traceText)
  end
end

function addon:IsSuppressedUiErrorMessage(message)
  if not message or message == "" then
    return false
  end

  if ERR_OUT_OF_ENERGY and message == ERR_OUT_OF_ENERGY then
    return true
  end

  if ERR_OUT_OF_RANGE and message == ERR_OUT_OF_RANGE then
    return true
  end

  if ERR_SPELL_COOLDOWN and message == ERR_SPELL_COOLDOWN then
    return true
  end

  if SPELL_FAILED_NOT_READY and message == SPELL_FAILED_NOT_READY then
    return true
  end

  local lower = string.lower(message)
  return lower == "not enough energy"
    or lower == "out of range."
    or lower == "out of range"
    or lower == "ability is not ready yet."
    or lower == "ability is not ready yet"
end

function addon:InstallUiErrorFilter()
  if self.uiErrorFilterInstalled or not UIErrorsFrame or not UIErrorsFrame.AddMessage then
    return
  end

  self.uiErrorFilterInstalled = true
  local originalAddMessage = UIErrorsFrame.AddMessage

  UIErrorsFrame.AddMessage = function(frame, message, r, g, b, id, holdTime)
    if addon:IsSuppressedUiErrorMessage(message) then
      return
    end

    return originalAddMessage(frame, message, r, g, b, id, holdTime)
  end
end

function addon:InitDB()
  RogueAutoDB = mergeDefaults(RogueAutoDB, deepCopy(self.defaults))
  self:MigrateSettings()
end

function addon:ResetDB()
  RogueAutoDB = deepCopy(self.defaults)
  self:ResetPickPocketGoldSession()
  self:RefreshKnownSpells()
  self:Print("Settings reset to defaults.")
end

function addon:MigrateSettings()
  if not RogueAutoDB or not RogueAutoDB.builder then
    return
  end

  local mode = RogueAutoDB.builder.mode
  if mode == nil or mode == "" then
    RogueAutoDB.builder.mode = "auto"
  end

  if RogueAutoDB.builder.useFlourish == nil then
    RogueAutoDB.builder.useFlourish = false
  end

  if RogueAutoDB.builder.useFeint == nil then
    RogueAutoDB.builder.useFeint = true
  end

  if type(RogueAutoDB.mountGear) ~= "table" then
    RogueAutoDB.mountGear = deepCopy(self.defaults.mountGear)
  else
    if RogueAutoDB.mountGear.enabled == nil then
      RogueAutoDB.mountGear.enabled = false
    end
    if RogueAutoDB.mountGear.autoSwap == nil then
      RogueAutoDB.mountGear.autoSwap = false
    end
    if type(RogueAutoDB.mountGear.profile) ~= "table" then
      RogueAutoDB.mountGear.profile = {}
    end
  end

  local roleplay = RogueAutoDB.roleplay
  if roleplay then
    if roleplay.personality ~= "silent"
      and roleplay.personality ~= "scoundrel"
      and roleplay.personality ~= "venom" then
      roleplay.personality = "silent"
    end
    roleplay.frequency = math.max(10, math.min(tonumber(roleplay.frequency) or 35, 100))
  end

  if not RogueAutoDB.stats then
    RogueAutoDB.stats = {}
  end

  if RogueAutoDB.minimap and RogueAutoDB.minimap.angle == 220 then
    RogueAutoDB.minimap.angle = self.defaults.minimap.angle
  end

  if not RogueAutoDB.stats.pickPocket then
    RogueAutoDB.stats.pickPocket = { lifetimeCopper = 0 }
  elseif type(RogueAutoDB.stats.pickPocket) ~= "table" then
    RogueAutoDB.stats.pickPocket = { lifetimeCopper = 0 }
  elseif type(RogueAutoDB.stats.pickPocket.lifetimeCopper) ~= "number" then
    RogueAutoDB.stats.pickPocket.lifetimeCopper = tonumber(RogueAutoDB.stats.pickPocket.lifetimeCopper) or 0
  end
end

function addon:GetHighlightDuration()
  local notifications = RogueAutoDB and RogueAutoDB.notifications
  local duration = notifications and notifications.highlightDuration
  if not duration or duration < 1 then
    return self.defaults.notifications.highlightDuration
  end

  return duration
end

function addon:GetNoticeFadeDuration()
  return self.noticeFadeDuration or 0.35
end

local function addHeuristicReason(reasons, text)
  if not text or text == "" then
    return
  end

  for _, existing in ipairs(reasons) do
    if existing == text then
      return
    end
  end

  if table.getn(reasons) < 3 then
    table.insert(reasons, text)
  end
end

local function formatShortSeconds(value)
  if not value or value <= 0 then
    return nil
  end

  return string.format("%.1fs", value)
end

local function formatCopperToMoneyString(copper)
  if not copper or copper < 0 then
    copper = 0
  end

  copper = math.floor(copper + 0.5)
  local gold = math.floor(copper / 10000)
  local silver = math.floor(math.mod(copper, 10000) / 100)
  local remainingCopper = math.mod(copper, 100)
  return tostring(gold) .. "g " .. tostring(silver) .. "s " .. tostring(remainingCopper) .. "c"
end

local function formatPickPocketRunTimer(seconds)
  local rounded = math.max(0, math.floor((seconds or 0) + 0.5))
  local minutes = math.floor(rounded / 60)
  local remainingSeconds = math.mod(rounded, 60)
  return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function parseCopperFromLootText(message)
  if not message then
    return nil
  end

  local cleaned = trim(message)
  cleaned = string.lower(cleaned)
  cleaned = string.gsub(cleaned, ",", "")
  cleaned = string.gsub(cleaned, "|c%x%x%x%x%x%x%x%x", "")
  cleaned = string.gsub(cleaned, "|r", "")
  cleaned = string.gsub(cleaned, "and", " ")

  local totalCopper = 0
  local hasAmount = false
  for amountText, currencyText in string.gfind(cleaned, "(%d+)%s*([a-z]+)") do
    local amount = tonumber(amountText)
    if amount then
      local normalizedCurrency = string.gsub(currencyText, "[^a-z]", "")
      if string.find(normalizedCurrency, "gold") or normalizedCurrency == "g" then
        totalCopper = totalCopper + (amount * 10000)
        hasAmount = true
      elseif string.find(normalizedCurrency, "silver") or normalizedCurrency == "s" then
        totalCopper = totalCopper + (amount * 100)
        hasAmount = true
      elseif string.find(normalizedCurrency, "copper") or normalizedCurrency == "c" then
        totalCopper = totalCopper + amount
        hasAmount = true
      end
    end
  end

  if not hasAmount then
    return nil
  end

  return totalCopper
end

function addon:GetPickPocketGoldStats()
  if not RogueAutoDB then
    return nil
  end

  if not RogueAutoDB.stats then
    RogueAutoDB.stats = {}
  end
  if not RogueAutoDB.stats.pickPocket then
    RogueAutoDB.stats.pickPocket = { lifetimeCopper = 0 }
  end

  local pickPocketStats = RogueAutoDB.stats.pickPocket
  if type(pickPocketStats.lifetimeCopper) ~= "number" then
    pickPocketStats.lifetimeCopper = tonumber(pickPocketStats.lifetimeCopper) or 0
  end

  return pickPocketStats
end

function addon:EnsurePickPocketGoldSessionState()
  if not self.state.pickPocketGold then
    self.state.pickPocketGold = {
      sessionStart = 0,
      sessionCopper = 0,
    }
  end

  if self.state.pickPocketGold.sessionStart == nil then
    self.state.pickPocketGold.sessionStart = 0
  end
  if self.state.pickPocketGold.sessionCopper == nil then
    self.state.pickPocketGold.sessionCopper = 0
  end
end

function addon:InitializePickPocketGoldStats()
  self:EnsurePickPocketGoldSessionState()
  self.state.pickPocketGold.sessionStart = GetTime()
  if self.state.pickPocketGold.sessionCopper == nil then
    self.state.pickPocketGold.sessionCopper = 0
  end
end

function addon:ResetPickPocketGoldSession()
  self:EnsurePickPocketGoldSessionState()
  self.state.pickPocketGold.sessionStart = GetTime()
  self.state.pickPocketGold.sessionCopper = 0
end

function addon:ResetPickPocketGoldStats()
  local stats = self:GetPickPocketGoldStats()
  if not stats then
    return
  end

  stats.lifetimeCopper = 0
  self:ResetPickPocketGoldSession()
  self:UpdatePickPocketGoldStatsFrame(true)
end

function addon:ParsePickPocketMoneyAmount(message)
  return parseCopperFromLootText(message)
end

function addon:RecordPickPocketGold(amountCopper)
  if not amountCopper or amountCopper <= 0 then
    return
  end

  local stats = self:GetPickPocketGoldStats()
  if not stats then
    return
  end

  self:EnsurePickPocketGoldSessionState()
  local rounded = math.floor(tonumber(amountCopper) + 0.5)
  if rounded <= 0 then
    return
  end

  stats.lifetimeCopper = (stats.lifetimeCopper or 0) + rounded
  self.state.pickPocketGold.sessionCopper = (self.state.pickPocketGold.sessionCopper or 0) + rounded
  if self.state.pickPocketGold.sessionStart <= 0 then
    self.state.pickPocketGold.sessionStart = GetTime()
  end
end

function addon:GetPickPocketGoldPerHour()
  self:EnsurePickPocketGoldSessionState()
  if self.state.pickPocketGold.sessionStart <= 0 or self.state.pickPocketGold.sessionCopper <= 0 then
    return 0
  end

  local elapsed = GetTime() - self.state.pickPocketGold.sessionStart
  if elapsed <= 0 then
    return 0
  end

  return (self.state.pickPocketGold.sessionCopper / elapsed) * 3600
end

function addon:GetPickPocketRunTimerRemaining()
  local timer = self.state.pickPocketRunTimer
  if not timer then
    timer = { remaining = self.pickPocketResetDuration or 600, startedAt = nil, running = false }
    self.state.pickPocketRunTimer = timer
  end

  if timer.running and timer.startedAt then
    local remaining = (timer.remaining or 0) - (GetTime() - timer.startedAt)
    if remaining <= 0 then
      timer.remaining = 0
      timer.startedAt = nil
      timer.running = false
      return 0
    end
    return remaining
  end

  return timer.remaining or (self.pickPocketResetDuration or 600)
end

function addon:IsPickPocketRunTimerRunning()
  self:GetPickPocketRunTimerRemaining()
  return self.state.pickPocketRunTimer and self.state.pickPocketRunTimer.running == true
end

function addon:StartPickPocketRunTimer()
  local remaining = self:GetPickPocketRunTimerRemaining()
  local timer = self.state.pickPocketRunTimer
  if remaining <= 0 then
    timer.remaining = self.pickPocketResetDuration or 600
  else
    timer.remaining = remaining
  end
  timer.startedAt = GetTime()
  timer.running = true
end

function addon:StopPickPocketRunTimer()
  local remaining = self:GetPickPocketRunTimerRemaining()
  local timer = self.state.pickPocketRunTimer
  timer.remaining = remaining
  timer.startedAt = nil
  timer.running = false
end

function addon:ResetPickPocketRunTimer()
  self.state.pickPocketRunTimer = {
    remaining = self.pickPocketResetDuration or 600,
    startedAt = nil,
    running = false,
  }
end

function addon:EnsurePickPocketGoldStatsFrame()
  if self.pickPocketGoldStatsFrame then
    return self.pickPocketGoldStatsFrame
  end

  local frame = CreateFrame("Frame", "RogueAutoPickPocketGoldStatsFrame", UIParent)
  frame:SetWidth(250)
  frame:SetHeight(116)
  frame:SetFrameStrata("MEDIUM")
  frame:SetFrameLevel(70)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(false)
  frame:RegisterForDrag("LeftButton")
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.06, 0.06, 0.08, 0.86)
  frame:SetBackdropBorderColor(0.75, 0.58, 0.12, 0.6)
  frame:SetAlpha(0.9)
  frame.isPositionInitialized = false

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
  title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
  title:SetJustifyH("LEFT")
  title:SetText("Pick Pocket Gold")
  title:SetTextColor(1, 0.9, 0.35)

  local function createTimerIconButton(texture, tooltip, xOffset, onClick)
    local button = CreateFrame("Button", nil, frame)
    button:SetWidth(18)
    button:SetHeight(18)
    button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", xOffset, -7)
    button:SetNormalTexture(texture)
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    button:SetScript("OnClick", function()
      onClick()
      self:UpdatePickPocketGoldStatsFrame(true)
      if self.RefreshConfig then
        self:RefreshConfig()
      end
    end)
    button:SetScript("OnEnter", function()
      GameTooltip:SetOwner(button, "ANCHOR_TOP")
      GameTooltip:SetText(tooltip)
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    return button
  end

  createTimerIconButton("Interface\\Icons\\Ability_Rogue_Sprint", "Start run timer", -55, function()
    self:StartPickPocketRunTimer()
  end)
  createTimerIconButton("Interface\\Icons\\Ability_Rogue_Feint", "Stop run timer", -34, function()
    self:StopPickPocketRunTimer()
  end)
  createTimerIconButton("Interface\\Icons\\INV_Misc_PocketWatch_01", "Reset run timer", -13, function()
    self:ResetPickPocketRunTimer()
  end)

  local timerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  timerLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -34)
  timerLabel:SetWidth(90)
  timerLabel:SetHeight(14)
  timerLabel:SetJustifyH("LEFT")
  timerLabel:SetText("Run Timer:")
  timerLabel:SetTextColor(0.9, 0.9, 0.9)

  local timerValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  timerValue:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -34)
  timerValue:SetWidth(150)
  timerValue:SetHeight(14)
  timerValue:SetJustifyH("RIGHT")
  timerValue:SetJustifyV("TOP")

  local divider = frame:CreateTexture(nil, "ARTWORK")
  divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 9, -55)
  divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -55)
  divider:SetHeight(1)
  divider:SetTexture(1, 0.82, 0.25, 0.28)

  local lifetimeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  lifetimeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -64)
  lifetimeLabel:SetText("Lifetime:")
  lifetimeLabel:SetWidth(90)
  lifetimeLabel:SetJustifyH("LEFT")
  lifetimeLabel:SetTextColor(0.9, 0.9, 0.9)

  local lifetimeValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  lifetimeValue:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -64)
  lifetimeValue:SetWidth(135)
  lifetimeValue:SetHeight(14)
  lifetimeValue:SetJustifyH("RIGHT")
  lifetimeValue:SetJustifyV("TOP")
  lifetimeValue:SetTextColor(1, 1, 1)

  local hourlyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hourlyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -88)
  hourlyLabel:SetText("Per Hour:")
  hourlyLabel:SetWidth(90)
  hourlyLabel:SetJustifyH("LEFT")
  hourlyLabel:SetTextColor(0.9, 0.9, 0.9)

  local hourlyValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  hourlyValue:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -88)
  hourlyValue:SetWidth(135)
  hourlyValue:SetHeight(14)
  hourlyValue:SetJustifyH("RIGHT")
  hourlyValue:SetJustifyV("TOP")
  hourlyValue:SetTextColor(1, 0.95, 0.6)

  frame.lifetimeValue = lifetimeValue
  frame.hourlyValue = hourlyValue
  frame.timerValue = timerValue
  frame.title = title

  frame:SetScript("OnDragStart", function()
    local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.pickPocketStats
    if not settings or not settings.unlocked then
      return
    end

    frame:StartMoving()
  end)

  frame:SetScript("OnDragStop", function()
    local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.pickPocketStats
    if not settings then
      frame:StopMovingOrSizing()
      return
    end

    frame:StopMovingOrSizing()
    if not settings.unlocked then
      return
    end

    local centerX, centerY = UIParent:GetCenter()
    local frameCenterX, frameCenterY = frame:GetCenter()
    if centerX and centerY and frameCenterX and frameCenterY then
      settings.x = frameCenterX - centerX
      settings.y = frameCenterY - centerY
    end
    frame.isPositionInitialized = true
    self:PositionPickPocketGoldStatsFrame(true)
  end)

  self.pickPocketGoldStatsFrame = frame
  return frame
end

function addon:PositionPickPocketGoldStatsFrame(force)
  local frame = self:EnsurePickPocketGoldStatsFrame()
  if not frame then
    return nil
  end

  local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.pickPocketStats
  if not settings then
    return frame
  end

  frame:EnableMouse(settings.unlocked == true)

  if not settings.unlocked or force or not frame.isPositionInitialized then
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.x or 0, settings.y or -80)
    frame.isPositionInitialized = true
  end

  return frame
end

function addon:UpdatePickPocketGoldStatsFrame(force)
  local settings = RogueAutoDB and RogueAutoDB.ui and RogueAutoDB.ui.pickPocketStats
  if not settings or settings.enabled == false then
    if self.pickPocketGoldStatsFrame then
      self.pickPocketGoldStatsFrame:Hide()
    end
    return
  end

  local frame = self:EnsurePickPocketGoldStatsFrame()
  if not frame then
    return
  end

  self:PositionPickPocketGoldStatsFrame(force)
  local stats = self:GetPickPocketGoldStats() or {}
  local lifetimeCopper = 0
  if type(stats.lifetimeCopper) == "number" then
    lifetimeCopper = stats.lifetimeCopper
  end

  local perHourCopper = self:GetPickPocketGoldPerHour()
  local timerRemaining = self:GetPickPocketRunTimerRemaining()
  local timerRunning = self:IsPickPocketRunTimerRunning()
  frame.timerValue:SetText(formatPickPocketRunTimer(timerRemaining) .. (timerRunning and "  Running" or "  Stopped"))
  if timerRunning then
    frame.timerValue:SetTextColor(1, 0.9, 0.3)
  else
    frame.timerValue:SetTextColor(0.7, 0.7, 0.7)
  end
  frame.lifetimeValue:SetText(formatCopperToMoneyString(lifetimeCopper))
  frame.hourlyValue:SetText(string.format("%.2f g/h", perHourCopper / 10000))
  frame:Show()
end

function addon:UpdateNoticeFramePositions()
  local uiWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1024
  local inset = math.floor(uiWidth * (self.noticeAnchorInsetPct or 0.15))

  for kind, noticeFrame in pairs(self.noticeFrames) do
    local xOffset = inset
    if kind == "pickPocket" then
      xOffset = -inset
    end

    noticeFrame:ClearAllPoints()
    noticeFrame:SetPoint(noticeFrame.anchorPoint, UIParent, noticeFrame.relativePoint, xOffset, noticeFrame.defaultYOffset or self.noticeDefaultY)
  end
end

function addon:GetCombatTotalDamage(totals)
  local totalDamage = 0

  for _, key in ipairs(self.damageCategoryOrder) do
    totalDamage = totalDamage + (totals[key] or 0)
  end

  return totalDamage
end

function addon:ConfigureTextNoticeFrame(noticeFrame, body)
  setNoticeTitleLayout(noticeFrame, false)
  noticeFrame.body:SetText(body or "")
  noticeFrame.body:Show()
  if noticeFrame.titleIcon then
    noticeFrame.titleIcon:Hide()
  end
  if noticeFrame.divider then
    noticeFrame.divider:Hide()
  end

  if noticeFrame.totalRow then
    noticeFrame.totalRow:Hide()
  end

  if noticeFrame.energyRow then
    noticeFrame.energyRow:Hide()
  end

  if noticeFrame.categoryRows then
    for _, row in pairs(noticeFrame.categoryRows) do
      row:Hide()
    end
  end

  if noticeFrame.lootRows then
    for _, row in ipairs(noticeFrame.lootRows) do
      row:Hide()
    end
  end

  local height = getFontStringHeight(noticeFrame.title) + getFontStringHeight(noticeFrame.body) + 44
  noticeFrame:SetHeight(math.max(84, height))
end

function addon:ConfigureCombatNoticeFrame(noticeFrame, totals)
  setNoticeTitleLayout(noticeFrame, false)
  noticeFrame.body:Hide()
  if noticeFrame.titleIcon then
    noticeFrame.titleIcon:Hide()
  end
  if noticeFrame.divider then
    noticeFrame.divider:Show()
  end

  if noticeFrame.lootRows then
    for _, row in ipairs(noticeFrame.lootRows) do
      row:Hide()
    end
  end

  local totalDamage = self:GetCombatTotalDamage(totals)

  if noticeFrame.totalRow then
    noticeFrame.totalRow.icon:SetTexture(self.damageCategoryTextures.total)
    noticeFrame.totalRow.label:SetText("Total Damage")
    noticeFrame.totalRow.value:SetText(tostring(totalDamage))
    noticeFrame.totalRow:Show()
  end

  if noticeFrame.energyRow then
    noticeFrame.energyRow.icon:SetTexture(self.damageCategoryTextures.energy)
    noticeFrame.energyRow.label:SetText("Energy Gained")
    noticeFrame.energyRow.value:SetText(tostring(totals.energyGained or 0))
    noticeFrame.energyRow:Show()
  end

  if noticeFrame.categoryRows then
    for _, categoryKey in ipairs(self.damageCategoryOrder) do
      local row = noticeFrame.categoryRows[categoryKey]
      if row then
        row.icon:SetTexture(self.damageCategoryTextures[categoryKey])
        row.label:SetText(self.damageCategories[categoryKey])
        row.value:SetText(tostring(totals[categoryKey] or 0))
        row:Show()
      end
    end
  end

  noticeFrame:SetHeight(202)
end

function addon:ConfigurePickPocketNoticeFrame(noticeFrame, entries)
  setNoticeTitleLayout(noticeFrame, true)
  noticeFrame.body:Hide()
  if noticeFrame.titleIcon then
    noticeFrame.titleIcon:SetTexture(self.pickPocketTitleTexture)
    noticeFrame.titleIcon:Show()
  end
  if noticeFrame.divider then
    noticeFrame.divider:Show()
  end

  if noticeFrame.totalRow then
    noticeFrame.totalRow:Hide()
  end

  if noticeFrame.energyRow then
    noticeFrame.energyRow:Hide()
  end

  if noticeFrame.categoryRows then
    for _, row in pairs(noticeFrame.categoryRows) do
      row:Hide()
    end
  end

  local visibleRows = 0
  if noticeFrame.lootRows then
    for index, row in ipairs(noticeFrame.lootRows) do
      local entry = entries[index]
      if entry then
        if entry.text and (string.find(entry.text, "Copper") or string.find(entry.text, "Silver") or string.find(entry.text, "Gold")) then
          row.icon:SetTexture(self.coinTexture)
        else
          row.icon:SetTexture(entry.icon or self.pickPocketFallbackTexture)
        end
        row.label:SetText(entry.text or "")
        row:Show()
        visibleRows = index
      else
        row:Hide()
      end
    end
  end

  local rowCount = math.max(visibleRows, 1)
  noticeFrame:SetHeight(66 + (rowCount * 22))
end

function addon:ShowNotice(kind, title, body)
  local noticeFrame = self.noticeFrames[kind]
  if not noticeFrame then
    return
  end

  self:UpdateNoticeFramePositions()
  self.state.activeNotices[kind] = true
  noticeFrame.title:SetText(title or "RogueAuto")

  if kind == "combat" and type(body) == "table" then
    self:ConfigureCombatNoticeFrame(noticeFrame, body)
  elseif kind == "pickPocket" and type(body) == "table" then
    self:ConfigurePickPocketNoticeFrame(noticeFrame, body)
  else
    self:ConfigureTextNoticeFrame(noticeFrame, body)
  end

  noticeFrame.showAt = GetTime()
  noticeFrame.hideAt = noticeFrame.showAt + self:GetHighlightDuration()
  noticeFrame.endAt = noticeFrame.hideAt + self:GetNoticeFadeDuration()
  noticeFrame:SetAlpha(0)
  noticeFrame:Show()
end

function addon:HideNotice(kind)
  local noticeFrame = self.noticeFrames[kind]
  if not noticeFrame then
    return
  end

  self.state.activeNotices[kind] = nil
  noticeFrame.showAt = nil
  noticeFrame.hideAt = nil
  noticeFrame.endAt = nil
  noticeFrame:SetAlpha(1)
  noticeFrame:Hide()
end

function addon:UpdateNoticeFrames()
  for kind, noticeFrame in pairs(self.noticeFrames) do
    if self.state.activeNotices[kind] and noticeFrame.hideAt then
      local now = GetTime()
      local fadeDuration = self:GetNoticeFadeDuration()

      if noticeFrame.endAt and now >= noticeFrame.endAt then
        self:HideNotice(kind)
      else
        local alpha = 1

        if noticeFrame.showAt and now < (noticeFrame.showAt + fadeDuration) then
          alpha = (now - noticeFrame.showAt) / fadeDuration
        elseif now >= noticeFrame.hideAt then
          alpha = 1 - ((now - noticeFrame.hideAt) / fadeDuration)
        end

        if alpha < 0 then
          alpha = 0
        elseif alpha > 1 then
          alpha = 1
        end

        noticeFrame:SetAlpha(alpha)
      end
    end
  end

  self:UpdatePickPocketLootSession()
end

local function createCombatTotals()
  return {
    energyGained = 0,
    melee = 0,
    poisonDirect = 0,
    bleedDot = 0,
    poisonDot = 0,
    misc = 0,
  }
end

function addon:StartCombatSession()
  self.state.combatSession = {
    startedAt = GetTime(),
    totals = createCombatTotals(),
  }
end

function addon:IsCombatSessionActive()
  return self.state.combatSession ~= nil
end

function addon:EnsureCombatSession()
  if not self.state.combatSession then
    self:StartCombatSession()
  end

  return self.state.combatSession
end

function addon:IsBleedSpell(name)
  local normalized = normalizeSpellName(name)
  return self.bleedSpells[normalized] == true
end

function addon:IsPoisonDirectSpell(name)
  local normalized = normalizeSpellName(name)
  if self.poisonDirectSpells[normalized] then
    return true
  end

  return string.find(normalized, "Poison") ~= nil
end

function addon:ClassifyDamageEvent(sourceType, spellName, school)
  if sourceType == "melee" then
    return "melee"
  end

  if sourceType == "periodic" then
    if self:IsBleedSpell(spellName) or school == "Physical" then
      return "bleedDot"
    end
    if self:IsPoisonDirectSpell(spellName) or isNatureSchool(school) then
      return "poisonDot"
    end
    return "misc"
  end

  if self:IsPoisonDirectSpell(spellName) or isNatureSchool(school) then
    return "poisonDirect"
  end

  if school == nil or school == "" or school == "Physical" then
    return "melee"
  end

  return "misc"
end

function addon:AddCombatDamage(category, amount)
  local session = self:EnsureCombatSession()
  if not session or not amount or amount <= 0 then
    return
  end

  session.totals[category] = (session.totals[category] or 0) + amount
end

function addon:RecordDamageEvent(sourceType, spellName, school, amount)
  if not amount or amount <= 0 then
    return
  end

  local category = self:ClassifyDamageEvent(sourceType, spellName, school)
  self:AddCombatDamage(category, amount)
end

function addon:BuildCombatSummaryText(totals)
  local lines = {}
  local totalDamage = self:GetCombatTotalDamage(totals)

  table.insert(lines, "Total: " .. tostring(totalDamage))
  table.insert(lines, "Energy Gained: " .. tostring(totals.energyGained or 0))
  table.insert(lines, self.damageCategories.melee .. ": " .. tostring(totals.melee or 0))
  table.insert(lines, self.damageCategories.poisonDirect .. ": " .. tostring(totals.poisonDirect or 0))
  table.insert(lines, self.damageCategories.bleedDot .. ": " .. tostring(totals.bleedDot or 0))
  table.insert(lines, self.damageCategories.poisonDot .. ": " .. tostring(totals.poisonDot or 0))
  table.insert(lines, self.damageCategories.misc .. ": " .. tostring(totals.misc or 0))

  return table.concat(lines, "\n"), totalDamage
end

function addon:AddCombatEnergyGain(amount)
  local session = self:EnsureCombatSession()
  if not session or not amount or amount <= 0 then
    return
  end

  session.totals.energyGained = (session.totals.energyGained or 0) + amount
end

function addon:ExtractCombatEnergyGain(message)
  if not message then
    return nil
  end

  local _, _, amount = string.find(message, "[Yy]ou gain (%d+) [Ee]nergy")
  if amount then
    return tonumber(amount)
  end

  return nil
end

function addon:OnCombatEnergyMessage(message)
  local amount = self:ExtractCombatEnergyGain(message)
  if not amount or amount <= 0 then
    return false
  end

  local now = GetTime()
  local lastMessage = self.state.lastExplicitEnergyGainMessage
  if lastMessage
    and lastMessage.text == message
    and lastMessage.at
    and (now - lastMessage.at) <= 0.2 then
    self.state.lastExplicitEnergyGainAt = now
    return true
  end

  self.state.lastExplicitEnergyGainAt = now
  self.state.lastExplicitEnergyGainMessage = {
    text = message,
    at = now,
  }
  if self:IsCombatSessionActive() then
    self:AddCombatEnergyGain(amount)
  end

  return true
end

function addon:FinishCombatSession()
  local session = self.state.combatSession
  self.state.combatSession = nil

  if not session then
    return
  end

  local _, totalDamage = self:BuildCombatSummaryText(session.totals)
  if totalDamage <= 0 then
    return
  end

  self:ShowNotice("combat", "Combat Summary", session.totals)
end

function addon:ExtractDamageAmount(message)
  if not message then
    return nil
  end

  local _, _, amount = string.find(message, "for (%d+)")
  if amount then
    return tonumber(amount)
  end

  _, _, amount = string.find(message, "suffers (%d+)")
  if amount then
    return tonumber(amount)
  end

  _, _, amount = string.find(message, "causes .- (%d+) damage")
  if amount then
    return tonumber(amount)
  end

  _, _, amount = string.find(message, "drains (%d+)")
  if amount then
    return tonumber(amount)
  end

  return nil
end

function addon:ExtractSpellSchool(message)
  if not message then
    return nil
  end

  local _, _, school = string.find(message, "for %d+ ([A-Za-z]+) damage")
  if school then
    return school
  end

  _, _, school = string.find(message, "suffers %d+ ([A-Za-z]+) damage")
  if school then
    return school
  end

  return nil
end

function addon:OnCombatSelfHit(message)
  if self.OnRoleplayCombatMessage then
    self:OnRoleplayCombatMessage(message)
  end

  local amount = self:ExtractDamageAmount(message)
  if amount then
    self:RecordDamageEvent("melee", nil, "Physical", amount)
  end
end

function addon:OnSpellSelfDamage(message)
  if not message then
    return
  end

  if self.OnPoisonCombatMessage then
    self:OnPoisonCombatMessage(message)
  end

  if self.OnRoleplayCombatMessage then
    self:OnRoleplayCombatMessage(message)
  end
  self:OnFriendlySpellMessage(message)

  if self:OnCombatEnergyMessage(message) then
    return
  end

  local selfBuffGain = self:ExtractSelfBuffGainName(message)
  if selfBuffGain then
    self:OnSelfBuffMessage(message)
    return
  end

  local selfBuffFade = self:ExtractSelfBuffFadeName(message)
  if selfBuffFade then
    self:OnSelfBuffFade(message)
    return
  end

  local amount = self:ExtractDamageAmount(message)
  if not amount then
    return
  end

  local spellName = nil
  local _, _, directSpell = string.find(message, "^Your (.-) hits ")
  if directSpell then
    spellName = directSpell
  end

  if not spellName then
    _, _, directSpell = string.find(message, "^Your (.-) crits ")
    if directSpell then
      spellName = directSpell
    end
  end

  if not spellName then
    _, _, directSpell = string.find(message, "^Your (.-) causes ")
    if directSpell then
      spellName = directSpell
    end
  end

  if not spellName then
    _, _, directSpell = string.find(message, "^Your (.-) drains ")
    if directSpell then
      spellName = directSpell
    end
  end

  self:RecordDamageEvent("direct", spellName, self:ExtractSpellSchool(message), amount)
end

function addon:OnSpellPeriodicDamage(message)
  if not message then
    return
  end

  if self.OnPoisonCombatMessage then
    self:OnPoisonCombatMessage(message)
  end

  if self.OnRoleplayCombatMessage then
    self:OnRoleplayCombatMessage(message)
  end

  local amount = self:ExtractDamageAmount(message)
  if not amount then
    return
  end

  local _, _, spellName = string.find(message, "from your (.-)%.?$")
  if not spellName then
    return
  end

  self:RecordDamageEvent("periodic", spellName, self:ExtractSpellSchool(message), amount)
end

function addon:BeginPickPocketLootSession()
  local lastAttempt = self.state.lastSpellAttempt
  self.state.pickPocketLootSession = {
    entries = {},
    seen = {},
    finishAt = GetTime() + 3,
    targetName = lastAttempt and lastAttempt.name == "Pick Pocket" and lastAttempt.targetName or UnitName("target"),
  }
end

function addon:HasActivePickPocketLootSession()
  return self.state.pickPocketLootSession ~= nil
end

function addon:AddPickPocketLootEntry(text, texture)
  if not self.state.pickPocketLootSession or not text or text == "" then
    return
  end

  local session = self.state.pickPocketLootSession
  local normalized = normalizeLootEntry(text)
  if not normalized then
    return
  end

  local inferredTexture = texture or inferPickPocketEntryTexture(normalized)
  local entries = session.entries
  if not session.seen[normalized] then
    local moneyAmount = self:ParsePickPocketMoneyAmount(normalized)
    if moneyAmount and not session.moneyRecorded then
      inferredTexture = self.coinTexture
      session.moneyRecorded = true
      if self.state.pickPocketMoneyTracking then
        self.state.pickPocketMoneyTracking.recorded = true
      end
      self:RecordPickPocketGold(moneyAmount)
      self:UpdatePickPocketGoldStatsFrame(true)
    end

    local entry = {
      text = normalized,
      icon = inferredTexture,
    }
    table.insert(entries, entry)
    session.seen[normalized] = entry
  elseif inferredTexture and session.seen[normalized] and (not session.seen[normalized].icon or session.seen[normalized].icon == self.pickPocketFallbackTexture) then
    session.seen[normalized].icon = inferredTexture
  end

  session.finishAt = GetTime() + 0.5
end

function addon:ExtractLootText(message)
  if not message then
    return nil
  end

  local _, _, lootText = string.find(message, "^You receive loot: (.+)%.?$")
  if lootText then
    return lootText
  end

  _, _, lootText = string.find(message, "^You loot (.+)%.?$")
  if lootText then
    return lootText
  end

  return message
end

function addon:FinishPickPocketLootSession()
  local session = self.state.pickPocketLootSession
  self.state.pickPocketLootSession = nil

  if not session then
    return
  end

  local entries = session.entries
  local wasEmpty = table.getn(entries) == 0
  if table.getn(entries) == 0 then
    table.insert(entries, {
      text = "Nothing",
      icon = self.pickPocketFallbackTexture,
    })
  end

  if self.OnRoleplayPickPocketSuccess then
    self:OnRoleplayPickPocketSuccess(wasEmpty, session.targetName)
  end

  self:ShowNotice("pickPocket", "Pick Pocket", entries)
end

function addon:SchedulePickPocketLootSessionFinish(delay)
  if not self.state.pickPocketLootSession then
    return
  end

  self.state.pickPocketLootSession.finishAt = GetTime() + (delay or 0.5)
end

function addon:UpdatePickPocketLootSession()
  local session = self.state.pickPocketLootSession
  if not session or not session.finishAt then
    return
  end

  if GetTime() >= session.finishAt then
    self:FinishPickPocketLootSession()
  end
end

function addon:CapturePickPocketLootWindow()
  if not self.state.pickPocketLootSession or not GetNumLootItems or not GetLootSlotInfo then
    return
  end

  local lootItems = GetNumLootItems() or 0
  for slot = 1, lootItems do
    local texture, itemName, quantity = GetLootSlotInfo(slot)
    local text = itemName

    if LootSlotIsCoin and LootSlotIsCoin(slot) == 1 then
      text = itemName or text
    elseif text and quantity and quantity > 1 then
      text = text .. " x" .. tostring(quantity)
    end

    if text and text ~= "" then
      self:AddPickPocketLootEntry(text, texture)
    end
  end
end

function addon:RefreshKnownSpells()
  self.state.knownSpells = {}
  self.state.spellEnergyCosts = {}
  self.state.spellTooltipText = {}

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

  if duration == 0 or startTime == 0 then
    return true
  end

  return (startTime + duration) <= GetTime()
end

function addon:GetSpellCooldownInfo(name)
  local spellIndex = self:GetSpellIndex(name)
  if not spellIndex then
    return nil
  end

  local startTime, duration = GetSpellCooldown(spellIndex, BOOKTYPE_SPELL)
  if not startTime or not duration or duration <= 1.5 then
    return nil
  end

  local remaining = (startTime + duration) - GetTime()
  if remaining <= 0 then
    return nil
  end

  return remaining, duration, GetSpellTexture and GetSpellTexture(spellIndex, BOOKTYPE_SPELL) or nil
end

function addon:EnsureCooldownListFrame()
  if self.cooldownListFrame then
    return self.cooldownListFrame
  end

  if not PlayerFrameManaBar then
    return nil
  end

  local listFrame = CreateFrame("Frame", "RogueAutoCooldownListFrame", UIParent)
  listFrame:SetWidth(116)
  listFrame:SetHeight(76)
  listFrame:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", 20, -8)
  listFrame.rows = {}

  for index = 1, 4 do
    local row = CreateFrame("Frame", nil, listFrame)
    row:SetWidth(116)
    row:SetHeight(16)
    row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -((index - 1) * 18))
    row:Hide()

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(16)
    icon:SetHeight(16)
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.icon = icon

    local barHost = CreateFrame("Frame", nil, row)
    barHost:SetWidth(94)
    barHost:SetHeight(10)
    barHost:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    row.barHost = barHost

    local bgBar = barHost:CreateTexture(nil, "BACKGROUND")
    bgBar:SetAllPoints(barHost)
    bgBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bgBar:SetVertexColor(0, 0, 0, 0.22)
    row.bgBar = bgBar

    local fillBar = barHost:CreateTexture(nil, "ARTWORK")
    fillBar:SetPoint("TOPRIGHT", barHost, "TOPRIGHT", 0, 0)
    fillBar:SetPoint("BOTTOMRIGHT", barHost, "BOTTOMRIGHT", 0, 0)
    fillBar:SetWidth(94)
    fillBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    fillBar:SetVertexColor(0, 0, 0, 0.52)
    row.fillBar = fillBar

    local timeText = row:CreateFontString(nil, "OVERLAY")
    timeText:SetPoint("CENTER", barHost, "CENTER", 0, 0)
    timeText:SetFont(STANDARD_TEXT_FONT, 7, "OUTLINE")
    timeText:SetTextColor(1, 1, 1)
    timeText:SetJustifyH("CENTER")
    row.timeText = timeText

    listFrame.rows[index] = row
  end

  self.cooldownListFrame = listFrame
  return listFrame
end

function addon:EnsureSelfBuffTimelineFrame()
  if self.selfBuffTimelineFrame then
    if self.selfBuffTimelineFrame.title then
      self.selfBuffTimelineFrame.title:Hide()
    end
    if self.selfBuffTimelineFrame.SetBackdrop then
      self.selfBuffTimelineFrame:SetBackdrop(nil)
      self.selfBuffTimelineFrame:SetBackdropColor(0, 0, 0, 0)
      self.selfBuffTimelineFrame:SetBackdropBorderColor(0, 0, 0, 0)
    end
    return self.selfBuffTimelineFrame
  end

  local timelineFrame = CreateFrame("Frame", "RogueAutoSelfBuffTimelineFrame", UIParent)
  timelineFrame:SetWidth(176)
  timelineFrame:SetHeight(62)
  timelineFrame:SetFrameStrata("HIGH")
  timelineFrame:SetFrameLevel((PlayerFrame and PlayerFrame:GetFrameLevel() or 1) + 12)
  timelineFrame:SetClampedToScreen(true)
  timelineFrame.rows = {}

  for index = 1, 4 do
    local row = CreateFrame("Frame", nil, timelineFrame)
    row:SetWidth(152)
    row:SetHeight(12)
    row:SetPoint("TOPLEFT", timelineFrame, "TOPLEFT", 12, -9 - ((index - 1) * 11))
    row:Hide()
    row.trackWidth = 112

    local track = row:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(row.trackWidth)
    track:SetHeight(2)
    track:SetPoint("LEFT", row, "LEFT", 0, 0)
    track:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    track:SetVertexColor(0.72, 0.72, 0.72, 0.14)
    row.track = track

    local progress = row:CreateTexture(nil, "ARTWORK")
    progress:SetHeight(2)
    progress:SetPoint("LEFT", track, "LEFT", 0, 0)
    progress:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progress:SetVertexColor(0.78, 0.82, 0.36, 0.72)
    row.progress = progress

    local iconHolder = CreateFrame("Frame", nil, row)
    iconHolder:SetWidth(10)
    iconHolder:SetHeight(10)
    iconHolder:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.iconHolder = iconHolder

    local icon = iconHolder:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(iconHolder)
    row.icon = icon

    local border = iconHolder:CreateTexture(nil, "BORDER")
    border:SetAllPoints(iconHolder)
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    row.iconBorder = border

    local glow = iconHolder:CreateTexture(nil, "ARTWORK")
    glow:SetWidth(14)
    glow:SetHeight(14)
    glow:SetPoint("CENTER", iconHolder, "CENTER", 0, 0)
    glow:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    glow:SetVertexColor(0.82, 0.86, 0.4, 0.08)
    row.glow = glow

    local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("LEFT", track, "RIGHT", 8, 0)
    timeText:SetWidth(30)
    timeText:SetJustifyH("RIGHT")
    timeText:SetTextColor(0.82, 0.82, 0.82)
    row.timeText = timeText

    timelineFrame.rows[index] = row
  end

  self.selfBuffTimelineFrame = timelineFrame
  return timelineFrame
end

function addon:EnsureWeaponPoisonFrame()
  if self.weaponPoisonFrame then
    return self.weaponPoisonFrame
  end

  local poisonFrame = CreateFrame("Frame", "RogueAutoWeaponPoisonFrame", UIParent)
  poisonFrame:SetWidth(46)
  poisonFrame:SetHeight(22)
  poisonFrame:SetFrameStrata("HIGH")
  poisonFrame:SetFrameLevel((PlayerFrame and PlayerFrame:GetFrameLevel() or 1) + 14)
  poisonFrame:SetClampedToScreen(true)
  poisonFrame.slots = {}

  for index = 1, 2 do
    local slotFrame = CreateFrame("Frame", nil, poisonFrame)
    slotFrame:SetWidth(20)
    slotFrame:SetHeight(20)
    slotFrame:SetPoint("TOPLEFT", poisonFrame, "TOPLEFT", (index - 1) * 22, 0)
    slotFrame:Hide()

    local icon = slotFrame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(16)
    icon:SetHeight(16)
    icon:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 2, -2)
    slotFrame.icon = icon

    local border = slotFrame:CreateTexture(nil, "BORDER")
    border:SetAllPoints(slotFrame)
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetVertexColor(0.65, 0.65, 0.65, 0.85)
    slotFrame.border = border

    local countText = slotFrame:CreateFontString(nil, "OVERLAY")
    countText:SetPoint("BOTTOMRIGHT", slotFrame, "BOTTOMRIGHT", -1, 1)
    countText:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    countText:SetTextColor(1, 1, 1)
    countText:SetJustifyH("RIGHT")
    slotFrame.countText = countText

    poisonFrame.slots[index] = slotFrame
  end

  self.weaponPoisonFrame = poisonFrame
  return poisonFrame
end

function addon:EnsurePoisonImmunityFrame()
  if self.poisonImmunityFrame then
    return self.poisonImmunityFrame
  end

  local parent = TargetFrame or UIParent
  local immunityFrame = CreateFrame("Frame", "RogueAutoPoisonImmunityFrame", parent)
  immunityFrame:SetWidth(20)
  immunityFrame:SetHeight(20)
  immunityFrame:SetFrameStrata("HIGH")
  immunityFrame:SetFrameLevel((TargetFrame and TargetFrame:GetFrameLevel() or 1) + 14)
  immunityFrame:SetClampedToScreen(true)
  immunityFrame:EnableMouse(true)

  local icon = immunityFrame:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(16)
  icon:SetHeight(16)
  icon:SetPoint("TOPLEFT", immunityFrame, "TOPLEFT", 2, -2)
  icon:SetTexture(self.weaponPoisonFallbackTexture)
  immunityFrame.icon = icon

  local border = immunityFrame:CreateTexture(nil, "BORDER")
  border:SetAllPoints(immunityFrame)
  border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  border:SetVertexColor(0.65, 0.65, 0.65, 0.85)
  immunityFrame.border = border

  local blocked = immunityFrame:CreateFontString(nil, "OVERLAY")
  blocked:SetPoint("CENTER", immunityFrame, "CENTER", 0, 0)
  blocked:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
  blocked:SetText("X")
  blocked:SetTextColor(1, 0.08, 0.08, 1)
  blocked:SetShadowColor(0, 0, 0, 1)
  blocked:SetShadowOffset(1, -1)
  immunityFrame.blocked = blocked

  immunityFrame:SetScript("OnEnter", function()
    local immunity = addon.state.poisonImmunity
    GameTooltip:SetOwner(immunityFrame, "ANCHOR_RIGHT")
    GameTooltip:SetText("Poison Immune", 1, 0.2, 0.2)
    if immunity and immunity.spellName then
      GameTooltip:AddLine("Detected by: " .. tostring(immunity.spellName), 1, 0.82, 0.2)
    end
    GameTooltip:AddLine("Builder skips Envenom and Noxious Assault.", 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine("Using Slice and Dice, Sinister Strike, and Eviscerate.", 0.65, 1, 0.65, true)
    GameTooltip:Show()
  end)
  immunityFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  immunityFrame:Hide()
  self.poisonImmunityFrame = immunityFrame
  return immunityFrame
end

function addon:PositionPoisonImmunityFrame()
  local immunityFrame = self:EnsurePoisonImmunityFrame()
  if not immunityFrame then
    return nil
  end

  immunityFrame:ClearAllPoints()
  if TargetFrame and TargetFrame.IsShown and TargetFrame:IsShown() then
    immunityFrame:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", 12, -4)
    return immunityFrame
  end

  immunityFrame:Hide()
  return nil
end

function addon:UpdatePoisonImmunityFrame()
  if not self.IsCurrentTargetPoisonImmune or not self:IsCurrentTargetPoisonImmune() then
    if self.poisonImmunityFrame then
      self.poisonImmunityFrame:Hide()
    end
    return
  end

  local immunity = self.state.poisonImmunity
  local immunityFrame = self:PositionPoisonImmunityFrame()
  if immunityFrame then
    local poisonStates = self:GetWeaponPoisonStates()
    local poisonState = poisonStates and poisonStates[1] or nil
    immunityFrame.icon:SetTexture(
      poisonState and poisonState.texture or self.weaponPoisonFallbackTexture
    )
    immunityFrame:Show()
  end
end

function addon:SizeWeaponPoisonWarningFrame(warningFrame)
  if not warningFrame then
    return
  end

  local uiScale = UIParent:GetScale() or 1
  if uiScale <= 0 then
    uiScale = 1
  end

  warningFrame:ClearAllPoints()
  warningFrame:SetScale(1 / uiScale)
  warningFrame:SetWidth(UIParent:GetWidth() or 0)
  warningFrame:SetHeight(UIParent:GetHeight() or 0)
  warningFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
  warningFrame.uiParentScale = uiScale
end

function addon:RebuildWeaponPoisonWarningBorder(warningFrame)
  if not warningFrame then
    return
  end

  for _, edge in ipairs(warningFrame.edges or {}) do
    edge:Hide()
  end
  warningFrame.edges = {}

  local width = warningFrame:GetWidth() or 0
  local height = warningFrame:GetHeight() or 0
  if width <= 0 or height <= 0 then
    return
  end

  local textures = self.weaponPoisonWarningTextures
  local cornerSize = 92
  local edgeThickness = 30
  local tileLength = 120

  local function createTexture(texturePath, layer, textureWidth, textureHeight)
    local texture = warningFrame:CreateTexture(nil, layer or "ARTWORK")
    texture:SetTexture(texturePath)
    texture:SetWidth(textureWidth)
    texture:SetHeight(textureHeight)
    table.insert(warningFrame.edges, texture)
    return texture
  end

  local horizontalSpan = math.max(width - (cornerSize * 2), 1)
  local horizontalTiles = math.max(1, math.ceil(horizontalSpan / tileLength))
  local horizontalTileWidth = horizontalSpan / horizontalTiles
  for index = 1, horizontalTiles do
    local x = cornerSize + ((index - 1) * horizontalTileWidth)
    local top = createTexture(textures.top, "ARTWORK", horizontalTileWidth, edgeThickness)
    top:SetPoint("TOPLEFT", warningFrame, "TOPLEFT", x, 0)

    local bottom = createTexture(textures.bottom, "ARTWORK", horizontalTileWidth, edgeThickness)
    bottom:SetPoint("BOTTOMLEFT", warningFrame, "BOTTOMLEFT", x, 0)
  end

  local verticalSpan = math.max(height - (cornerSize * 2), 1)
  local verticalTiles = math.max(1, math.ceil(verticalSpan / tileLength))
  local verticalTileHeight = verticalSpan / verticalTiles
  for index = 1, verticalTiles do
    local y = cornerSize + ((index - 1) * verticalTileHeight)
    local left = createTexture(textures.left, "ARTWORK", edgeThickness, verticalTileHeight)
    left:SetPoint("TOPLEFT", warningFrame, "TOPLEFT", 0, -y)

    local right = createTexture(textures.right, "ARTWORK", edgeThickness, verticalTileHeight)
    right:SetPoint("TOPRIGHT", warningFrame, "TOPRIGHT", 0, -y)
  end

  local topLeft = createTexture(textures.topLeft, "OVERLAY", cornerSize, cornerSize)
  topLeft:SetPoint("TOPLEFT", warningFrame, "TOPLEFT", 0, 0)

  local topRight = createTexture(textures.topRight, "OVERLAY", cornerSize, cornerSize)
  topRight:SetPoint("TOPRIGHT", warningFrame, "TOPRIGHT", 0, 0)

  local bottomLeft = createTexture(textures.bottomLeft, "OVERLAY", cornerSize, cornerSize)
  bottomLeft:SetPoint("BOTTOMLEFT", warningFrame, "BOTTOMLEFT", 0, 0)

  local bottomRight = createTexture(textures.bottomRight, "OVERLAY", cornerSize, cornerSize)
  bottomRight:SetPoint("BOTTOMRIGHT", warningFrame, "BOTTOMRIGHT", 0, 0)

  warningFrame.borderWidth = width
  warningFrame.borderHeight = height
end

function addon:EnsureWeaponPoisonWarningFrame()
  if self.weaponPoisonWarningFrame then
    return self.weaponPoisonWarningFrame
  end

  local warningFrame = CreateFrame("Frame", "RogueAutoWeaponPoisonWarningFrame", UIParent)
  warningFrame:SetFrameStrata("FULLSCREEN")
  warningFrame:SetFrameLevel(1)
  warningFrame:EnableMouse(false)
  warningFrame.edges = {}
  self:SizeWeaponPoisonWarningFrame(warningFrame)
  self:RebuildWeaponPoisonWarningBorder(warningFrame)

  warningFrame:Hide()
  self.weaponPoisonWarningFrame = warningFrame
  return warningFrame
end

function addon:PositionSelfBuffTimelineFrame()
  local timelineFrame = self:EnsureSelfBuffTimelineFrame()
  if not timelineFrame then
    return nil
  end

  timelineFrame:ClearAllPoints()

  if PlayerFrame and PlayerFrame.IsShown and PlayerFrame:IsShown() then
    timelineFrame:SetPoint("BOTTOMLEFT", PlayerFrame, "TOPLEFT", 38, 10)
  elseif PlayerFrameManaBar and PlayerFrameManaBar.IsShown and PlayerFrameManaBar:IsShown() then
    timelineFrame:SetPoint("BOTTOMLEFT", PlayerFrameManaBar, "TOPLEFT", 10, 14)
  else
    timelineFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 146, 168)
  end

  return timelineFrame
end

function addon:PositionWeaponPoisonFrame()
  local poisonFrame = self:EnsureWeaponPoisonFrame()
  if not poisonFrame then
    return nil
  end

  poisonFrame:ClearAllPoints()

  if PlayerFrame and PlayerFrame.IsShown and PlayerFrame:IsShown() then
    poisonFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -12, -4)
  elseif PlayerFrameManaBar and PlayerFrameManaBar.IsShown and PlayerFrameManaBar:IsShown() then
    poisonFrame:SetPoint("TOPLEFT", PlayerFrameManaBar, "TOPLEFT", -8, -10)
  else
    poisonFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 100, 154)
  end

  return poisonFrame
end

function addon:GetKnownWeaponPoisonNames()
  local names = {}

  for _, name in ipairs(self.weaponPoisonNames) do
    names[name] = true
  end

  for spellName in pairs(self.state.knownSpells) do
    local normalized = normalizeSpellName(spellName)
    if normalized ~= "" and string.find(string.lower(normalized), "poison", 1, true) then
      names[normalized] = true
    end
  end

  return names
end

function addon:ExtractWeaponPoisonNameFromText(text)
  if not text or text == "" then
    return nil
  end

  local lowerText = string.lower(text)
  local poisonNames = self:GetKnownWeaponPoisonNames()

  for poisonName in pairs(poisonNames) do
    if string.find(lowerText, string.lower(poisonName), 1, true) then
      return poisonName
    end
  end

  return nil
end

function addon:GetWeaponPoisonTexture(name)
  local normalizedName = normalizeSpellName(name)
  if normalizedName ~= "" then
    local spellIndex = self:GetSpellIndex(normalizedName)
    if spellIndex and GetSpellTexture then
      return GetSpellTexture(spellIndex, BOOKTYPE_SPELL)
    end
  end

  return self.weaponPoisonFallbackTexture
end

function addon:GetWeaponPoisonName(slot)
  if not self.inventoryTooltip or not self.inventoryTooltip.SetInventoryItem then
    return nil
  end

  self.inventoryTooltip:ClearLines()
  self.inventoryTooltip:SetInventoryItem("player", slot)

  for index = 2, 12 do
    local leftLine = _G["RogueAutoInventoryTooltipTextLeft" .. tostring(index)]
    local rightLine = _G["RogueAutoInventoryTooltipTextRight" .. tostring(index)]
    local leftText = leftLine and leftLine:GetText() or nil
    local rightText = rightLine and rightLine:GetText() or nil
    local poisonName = self:ExtractWeaponPoisonNameFromText(leftText)
    if poisonName then
      return poisonName
    end

    poisonName = self:ExtractWeaponPoisonNameFromText(rightText)
    if poisonName then
      return poisonName
    end
  end

  return nil
end

function addon:GetWeaponPoisonStates()
  if not GetWeaponEnchantInfo then
    return {}
  end

  local hasMainHand, mainHandExpiration, mainHandCharges, hasOffHand, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
  local states = {}
  local mainHandActive = hasMainHand == true or hasMainHand == 1
  local offHandActive = hasOffHand == true or hasOffHand == 1

  if mainHandActive then
    local poisonName = self:GetWeaponPoisonName(16)
    table.insert(states, {
      hand = "main",
      charges = mainHandCharges or 0,
      expiration = mainHandExpiration or 0,
      name = poisonName,
      texture = self:GetWeaponPoisonTexture(poisonName),
    })
  end

  if offHandActive then
    local poisonName = self:GetWeaponPoisonName(17)
    table.insert(states, {
      hand = "off",
      charges = offHandCharges or 0,
      expiration = offHandExpiration or 0,
      name = poisonName,
      texture = self:GetWeaponPoisonTexture(poisonName),
    })
  end

  return states
end

function addon:HasAnyWeaponPoison()
  local states = self:GetWeaponPoisonStates()
  local hasUnidentifiedActiveEnchant = false

  for _, state in ipairs(states or {}) do
    if state.name
      and string.find(string.lower(normalizeSpellName(state.name)), "poison", 1, true) then
      return true, tostring(state.hand or "weapon") .. " weapon has " ..
        tostring(state.name)
    end
    if not state.name then
      hasUnidentifiedActiveEnchant = true
    end
  end

  if hasUnidentifiedActiveEnchant then
    return true, "active weapon enchant reported; poison name unavailable"
  end

  if table.getn(states or {}) > 0 then
    return false, "active weapon enchant is not identified as poison"
  end
  return false, "no active weapon poison"
end

function addon:ShouldUsePhysicalBuilderRotation(context)
  return false
end

function addon:GetWeaponPoisonWarningStrength(states)
  local bestStrength = 0

  for _, state in ipairs(states) do
    local chargeStrength = 0
    local timeStrength = 0

    if state.charges and state.charges > 0 and state.charges <= self.weaponPoisonLowCharges then
      chargeStrength = (self.weaponPoisonLowCharges - state.charges + 1) / self.weaponPoisonLowCharges
    end

    if state.expiration and state.expiration > 0 and state.expiration <= self.weaponPoisonLowTimeMs then
      timeStrength = (self.weaponPoisonLowTimeMs - state.expiration + 1) / self.weaponPoisonLowTimeMs
    end

    local strength = math.max(chargeStrength, timeStrength)
    if strength > bestStrength then
      bestStrength = strength
    end
  end

  if bestStrength < 0 then
    return 0
  end
  if bestStrength > 1 then
    return 1
  end

  return bestStrength
end

function addon:UpdateWeaponPoisonFrame(force)
  local now = GetTime()
  if not force and self.state.nextWeaponPoisonUpdate and now < self.state.nextWeaponPoisonUpdate then
    return
  end

  self.state.nextWeaponPoisonUpdate = now + 0.2

  local poisonFrame = self:PositionWeaponPoisonFrame()
  if not poisonFrame then
    return
  end

  local states = self:GetWeaponPoisonStates()
  if table.getn(states) == 0 then
    poisonFrame:Hide()
    return
  end

  local visibleSlots = 0
  for index, slotFrame in ipairs(poisonFrame.slots) do
    local state = states[index]
    if state then
      slotFrame.icon:SetTexture(state.texture or self.weaponPoisonFallbackTexture)
      if state.charges and state.charges > 0 then
        slotFrame.countText:SetText(tostring(state.charges))
      else
        slotFrame.countText:SetText("")
      end
      slotFrame:Show()
      visibleSlots = index
    else
      slotFrame:Hide()
    end
  end

  poisonFrame:SetWidth(math.max(20, (visibleSlots * 22) - 2))
  poisonFrame:Show()
end

function addon:UpdateWeaponPoisonWarningFrame(force)
  local now = GetTime()
  if not force and self.state.nextWeaponPoisonWarningUpdate and now < self.state.nextWeaponPoisonWarningUpdate then
    return
  end

  self.state.nextWeaponPoisonWarningUpdate = now + 0.05

  local warningFrame = self:EnsureWeaponPoisonWarningFrame()
  if not warningFrame then
    return
  end

  local states = self:GetWeaponPoisonStates()
  local strength = self:GetWeaponPoisonWarningStrength(states)
  if strength <= 0 then
    warningFrame:Hide()
    return
  end

  local width = UIParent:GetWidth() or 0
  local height = UIParent:GetHeight() or 0
  local uiScale = UIParent:GetScale() or 1
  if math.abs(width - (warningFrame.borderWidth or 0)) > 0.5
    or math.abs(height - (warningFrame.borderHeight or 0)) > 0.5
    or math.abs(uiScale - (warningFrame.uiParentScale or 0)) > 0.001 then
    self:SizeWeaponPoisonWarningFrame(warningFrame)
    self:RebuildWeaponPoisonWarningBorder(warningFrame)
  end

  local pulse = (math.sin(now * 4) + 1) * 0.5
  local alpha = (0.18 + (strength * 0.22)) + (pulse * (0.12 + (strength * 0.18)))

  for _, edge in ipairs(warningFrame.edges) do
    edge:SetAlpha(alpha)
  end

  warningFrame:Show()
end

function addon:GetSelfBuffTimelineIcon(name, fallbackTexture)
  if fallbackTexture then
    return fallbackTexture
  end

  local spellIndex = self:GetSpellIndex(name)
  if spellIndex and GetSpellTexture then
    return GetSpellTexture(spellIndex, BOOKTYPE_SPELL)
  end

  local textureName = self.buffTextures[name]
  if textureName then
    return "Interface\\Icons\\" .. textureName
  end

  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function addon:PruneTrackedPlayerBuffs()
  local now = GetTime()

  for buffName, expiresAt in pairs(self.state.trackedPlayerBuffs) do
    if not expiresAt or expiresAt <= now then
      self.state.trackedPlayerBuffs[buffName] = nil
    end
  end
end

function addon:PrunePendingPlayerBuffs()
  local now = GetTime()

  for buffName, info in pairs(self.state.pendingPlayerBuffs) do
    if not info or not info.expiresAt or info.expiresAt <= now then
      self.state.pendingPlayerBuffs[buffName] = nil
    end
  end
end

function addon:QueuePendingPlayerBuff(name, duration)
  if not name then
    return
  end

  self.state.pendingPlayerBuffs[name] = {
    duration = duration,
    expiresAt = GetTime() + 1.5,
  }
end

function addon:GetPendingPlayerBuffInfo(name)
  self:PrunePendingPlayerBuffs()
  return self.state.pendingPlayerBuffs[name]
end

function addon:ClearPendingPlayerBuff(name)
  if not name then
    return
  end

  self.state.pendingPlayerBuffs[name] = nil
end

function addon:TrackPlayerBuff(name, duration)
  if not name or not duration or duration <= 0 then
    return
  end

  self.state.trackedPlayerBuffs[name] = GetTime() + duration
  self.state.pendingPlayerBuffs[name] = nil
end

function addon:GetTrackedPlayerBuffRemaining(name)
  self:PruneTrackedPlayerBuffs()

  local expiresAt = self.state.trackedPlayerBuffs[name]
  if not expiresAt then
    return 0
  end

  local remaining = expiresAt - GetTime()
  if remaining <= 0 then
    self.state.trackedPlayerBuffs[name] = nil
    return 0
  end

  return remaining
end

function addon:ConfirmTrackedPlayerBuff(name, duration)
  if not name then
    return
  end

  local pending = self:GetPendingPlayerBuffInfo(name)
  local trackedDuration = duration
  if (not trackedDuration or trackedDuration <= 0) and pending and pending.duration and pending.duration > 0 then
    trackedDuration = pending.duration
  end

  self:ClearPendingPlayerBuff(name)
  if trackedDuration and trackedDuration > 0 then
    self:TrackPlayerBuff(name, trackedDuration)
  end
end

function addon:IsLocallyTrackedPlayerBuff(name)
  return name == "Slice and Dice" or name == "Envenom" or name == "Flourish"
end

function addon:ExtractSelfBuffGainName(message)
  if not message then
    return nil
  end

  local _, _, buffName = string.find(message, "^You gain (.-)%.?$")
  if buffName then
    return normalizeSpellName(buffName)
  end

  return nil
end

function addon:ExtractSelfBuffFadeName(message)
  if not message then
    return nil
  end

  local _, _, buffName = string.find(message, "^(.-) fades from you%.?$")
  if buffName then
    return normalizeSpellName(buffName)
  end

  _, _, buffName = string.find(message, "^Your (.-) fades%.?$")
  if buffName then
    return normalizeSpellName(buffName)
  end

  return nil
end

function addon:OnSelfBuffMessage(message)
  self:OnCombatEnergyMessage(message)

  local buffName = self:ExtractSelfBuffGainName(message)
  if not buffName or not self:IsLocallyTrackedPlayerBuff(buffName) then
    return
  end

  self:ConfirmTrackedPlayerBuff(buffName)
end

function addon:OnSelfBuffFade(message)
  local buffName = self:ExtractSelfBuffFadeName(message)
  if buffName == "Mind Flay" then
    local activeCast = self.state.activeEnemyCast
    if activeCast and self:NormalizeInterruptSpellKey(activeCast.spellName) == "mind flay" then
      self:ClearActiveEnemyCast("Mind Flay faded")
    end
  end

  if not buffName or not self:IsLocallyTrackedPlayerBuff(buffName) then
    return
  end

  self.state.trackedPlayerBuffs[buffName] = nil
  self.state.pendingPlayerBuffs[buffName] = nil
end

function addon:GetTrackedPlayerBuffStates()
  local trackedNames = {}
  local trackedTextures = {}
  for _, spellName in ipairs(self.selfBuffTimelineTrackedSpells) do
    trackedNames[normalizeSpellName(spellName)] = spellName
    local textureName = normalizeTextureName(self:GetSelfBuffTimelineIcon(spellName))
    if textureName then
      trackedTextures[textureName] = spellName
    end
  end

  local activeBuffs = {}
  for index = 0, 31 do
    local buffIndex = GetPlayerBuff(index, "HELPFUL")
    if buffIndex < 0 then
      break
    end

    local remaining = GetPlayerBuffTimeLeft(buffIndex) or 0
    local texture = GetPlayerBuffTexture and GetPlayerBuffTexture(buffIndex) or nil

    self.tooltip:ClearLines()
    self.tooltip:SetPlayerBuff(buffIndex)
    local name = RogueAutoTooltipTextLeft1 and RogueAutoTooltipTextLeft1:GetText() or nil
    local normalizedName = normalizeSpellName(name)
    local trackedName = normalizedName and trackedNames[normalizedName] or nil
    if not trackedName then
      trackedName = trackedTextures[normalizeTextureName(texture)]
    end

    if trackedName and remaining > 0 then
      activeBuffs[trackedName] = {
        name = trackedName,
        remaining = remaining,
        texture = texture,
      }
    end
  end

  for spellName, expiresAt in pairs(self.state.trackedPlayerBuffs) do
    local remaining = expiresAt - GetTime()
    if remaining > 0 and not activeBuffs[spellName] then
      activeBuffs[spellName] = {
        name = spellName,
        remaining = remaining,
        texture = self:GetSelfBuffTimelineIcon(spellName),
      }
    end
  end

  return activeBuffs
end

function addon:GetVisibleSelfBuffTimelineEntries()
  local activeBuffs = self:GetTrackedPlayerBuffStates()
  local now = GetTime()
  local visible = {}

  for spellName, info in pairs(activeBuffs) do
    local record = self.state.selfBuffTimeline[spellName] or {}
    if not record.totalDuration
      or info.remaining > (record.lastRemaining or 0) + 0.4
      or info.remaining > record.totalDuration + 0.4 then
      record.totalDuration = info.remaining
      record.startedAt = now
    end

    record.lastRemaining = info.remaining
    record.lastSeenAt = now
    record.texture = self:GetSelfBuffTimelineIcon(spellName, info.texture)
    self.state.selfBuffTimeline[spellName] = record

    table.insert(visible, {
      name = spellName,
      remaining = info.remaining,
      duration = record.totalDuration or info.remaining,
      texture = record.texture,
    })
  end

  for spellName, record in pairs(self.state.selfBuffTimeline) do
    if not activeBuffs[spellName] or (record.lastSeenAt and (now - record.lastSeenAt) > 0.3) then
      self.state.selfBuffTimeline[spellName] = nil
    end
  end

  table.sort(visible, function(a, b)
    if a.remaining == b.remaining then
      return a.name < b.name
    end
    return a.remaining < b.remaining
  end)

  return visible
end

function addon:UpdateSelfBuffTimelineFrame(force)
  local now = GetTime()
  if not force and self.state.nextSelfBuffTimelineUpdate and now < self.state.nextSelfBuffTimelineUpdate then
    return
  end

  self.state.nextSelfBuffTimelineUpdate = now + 0.05

  local timelineFrame = self:PositionSelfBuffTimelineFrame()
  if not timelineFrame then
    return
  end

  local visible = self:GetVisibleSelfBuffTimelineEntries()
  if table.getn(visible) == 0 then
    timelineFrame:Hide()
    return
  end

  local visibleRows = math.min(table.getn(visible), table.getn(timelineFrame.rows))
  timelineFrame:SetHeight(10 + (visibleRows * 11))

  for index, row in ipairs(timelineFrame.rows) do
    local buff = visible[index]
    if buff then
      local duration = buff.duration or buff.remaining
      if duration <= 0 then
        duration = buff.remaining
      end

      local ratio = duration > 0 and (buff.remaining / duration) or 0
      if ratio < 0 then
        ratio = 0
      elseif ratio > 1 then
        ratio = 1
      end

      local progress = 1 - ratio
      local iconSize = math.floor((11 + (progress * 9)) + 0.5)
      local maxOffset = math.max(0, row.trackWidth - iconSize)
      local xOffset = math.floor((maxOffset * progress) + 0.5)
      local progressWidth = math.max(1, math.floor(xOffset + (iconSize * 0.5)))

      row.progress:SetWidth(progressWidth)
      row.iconHolder:ClearAllPoints()
      row.iconHolder:SetPoint("LEFT", row.track, "LEFT", xOffset, 0)
      row.iconHolder:SetWidth(iconSize)
      row.iconHolder:SetHeight(iconSize)
      row.glow:SetWidth(iconSize + 8)
      row.glow:SetHeight(iconSize + 8)
      row.icon:SetTexture(buff.texture)
      if row.timeText then
        row.timeText:SetText(formatShortSeconds(buff.remaining) or "")
      end

      local glowAlpha = 0.1 + (progress * 0.18)
      row.glow:SetVertexColor(1, 0.9, 0.2, glowAlpha)
      row:Show()
    else
      if row.timeText then
        row.timeText:SetText("")
      end
      row:Hide()
    end
  end

  timelineFrame:Show()
end

function addon:GetTrackedCooldowns()
  local cooldowns = {}

  for _, spellName in ipairs(self.cooldownTrackedSpells) do
    if self:HasSpell(spellName) then
      local remaining, duration, texture = self:GetSpellCooldownInfo(spellName)
      if remaining and duration then
        table.insert(cooldowns, {
          name = spellName,
          remaining = remaining,
          duration = duration,
          texture = texture,
        })
      end
    end
  end

  table.sort(cooldowns, function(a, b)
    if a.remaining == b.remaining then
      return a.name < b.name
    end
    return a.remaining < b.remaining
  end)

  return cooldowns
end

function addon:UpdateCooldownListFrame(force)
  local now = GetTime()
  if not force and self.state.nextCooldownListUpdate and now < self.state.nextCooldownListUpdate then
    return
  end

  self.state.nextCooldownListUpdate = now + 0.1

  local listFrame = self:EnsureCooldownListFrame()
  if not listFrame then
    return
  end

  local cooldowns = self:GetTrackedCooldowns()
  if table.getn(cooldowns) == 0 then
    listFrame:Hide()
    return
  end

  local visibleRows = math.min(table.getn(cooldowns), table.getn(listFrame.rows))
  listFrame:SetHeight((visibleRows * 18) - 2)

  for index, row in ipairs(listFrame.rows) do
    local cooldown = cooldowns[index]
    if cooldown then
      local ratio = cooldown.duration > 0 and (cooldown.remaining / cooldown.duration) or 0
      if ratio < 0 then
        ratio = 0
      elseif ratio > 1 then
        ratio = 1
      end

      local fillWidth = math.max(1, math.floor(94 * ratio + 0.5))
      row.icon:SetTexture(cooldown.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.fillBar:SetWidth(fillWidth)
      row.timeText:SetText(string.format("%.1f", cooldown.remaining))
      row:Show()
    else
      row:Hide()
    end
  end

  listFrame:Show()
end

function addon:GetComboPoints()
  return GetComboPoints() or 0
end

function addon:GetEnergy()
  return UnitMana("player") or 0
end

function addon:GetSpellEnergyCost(name)
  local cached = self.state.spellEnergyCosts[name]
  if cached ~= nil then
    if cached == false then
      return nil
    end
    return cached
  end

  local spellIndex = self:GetSpellIndex(name)
  if not spellIndex or not self.tooltip.SetSpell then
    self.state.spellEnergyCosts[name] = false
    return nil
  end

  self.tooltip:ClearLines()
  self.tooltip:SetSpell(spellIndex, BOOKTYPE_SPELL)

  for index = 2, 10 do
    local leftLine = _G["RogueAutoTooltipTextLeft" .. tostring(index)]
    local rightLine = _G["RogueAutoTooltipTextRight" .. tostring(index)]
    local leftText = leftLine and leftLine:GetText()
    local rightText = rightLine and rightLine:GetText()
    local costText = leftText or rightText
    if leftText and string.find(string.lower(leftText), "energy") then
      costText = leftText
    elseif rightText and string.find(string.lower(rightText), "energy") then
      costText = rightText
    end

    if costText then
      local _, _, amount = string.find(costText, "(%d+)%s+[Ee]nergy")
      if amount then
        local cost = tonumber(amount)
        self.state.spellEnergyCosts[name] = cost or false
        return cost
      end
    end
  end

  self.state.spellEnergyCosts[name] = false
  return nil
end

function addon:GetSpellTooltipText(name)
  local cached = self.state.spellTooltipText[name]
  if cached ~= nil then
    if cached == false then
      return nil
    end
    return cached
  end

  local spellIndex = self:GetSpellIndex(name)
  if not spellIndex or not self.tooltip.SetSpell then
    self.state.spellTooltipText[name] = false
    return nil
  end

  self.tooltip:ClearLines()
  self.tooltip:SetSpell(spellIndex, BOOKTYPE_SPELL)

  local lines = {}
  for index = 2, 10 do
    local leftLine = _G["RogueAutoTooltipTextLeft" .. tostring(index)]
    local rightLine = _G["RogueAutoTooltipTextRight" .. tostring(index)]
    local leftText = leftLine and leftLine:GetText()
    local rightText = rightLine and rightLine:GetText()

    if leftText and leftText ~= "" then
      table.insert(lines, leftText)
    end
    if rightText and rightText ~= "" then
      table.insert(lines, rightText)
    end
  end

  if table.getn(lines) == 0 then
    self.state.spellTooltipText[name] = false
    return nil
  end

  local text = table.concat(lines, "\n")
  self.state.spellTooltipText[name] = text
  return text
end

function addon:SpellTooltipRequiresTargetDodge(name)
  local tooltipText = self:GetSpellTooltipText(name)
  if not tooltipText then
    return false
  end

  return string.find(string.lower(tooltipText), "after the target dodges") ~= nil
end

function addon:IsSurpriseAttackReady(targetKey)
  if GetTime() >= (self.state.surpriseAttackReadyUntil or 0) then
    self.state.surpriseAttackTargetKey = nil
    return false
  end

  targetKey = targetKey or self:GetTargetKey()
  if self.state.surpriseAttackTargetKey and targetKey and self.state.surpriseAttackTargetKey ~= targetKey then
    return false
  end

  return true
end

function addon:MarkSurpriseAttackReady(targetKey, duration)
  self.state.surpriseAttackTargetKey = targetKey or self:GetTargetKey()
  self.state.surpriseAttackReadyUntil = GetTime() + (duration or 5)
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
      local usable = IsUsableSpell("Surprise Attack")
      if usable == false then
        return false
      end
    end
  end

  return true
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

function addon:IsDurableClassification(classification)
  return classification and classification ~= "normal"
end

function addon:GetTargetClassification()
  return UnitClassification and UnitClassification("target") or "normal"
end

function addon:GetLegacyFightProfile()
  if not UnitExists("target") or UnitIsDead("target") then
    return "normal"
  end

  local classification = self:GetTargetClassification()
  if self:IsDurableClassification(classification) then
    return "durable"
  end

  if self:GetTargetHealthPct() <= 60 then
    return "trash_short"
  end

  return "normal"
end

function addon:GetMobLearningBucket(classification)
  if not RogueAutoDB or not RogueAutoDB.learning then
    return nil
  end

  if self:IsDurableClassification(classification) then
    return RogueAutoDB.learning.eliteMobs
  end

  return RogueAutoDB.learning.normalMobs
end

function addon:NormalizeMobLearningKey(name)
  if not name then
    return nil
  end

  local normalized = trim(string.lower(name))
  if normalized == "" then
    return nil
  end

  return normalized
end

function addon:IsValidLearningObservation(maxHealth, level)
  if not maxHealth or maxHealth <= 1 then
    return false
  end

  if level and level >= 10 and maxHealth <= (level * 2) then
    return false
  end

  return true
end

function addon:IsUsableLearnedHealth(avgMaxHealth)
  return avgMaxHealth and avgMaxHealth >= 50
end

function addon:IsUsableLearnedDuration(avgFightDuration)
  return avgFightDuration and avgFightDuration >= 1.5
end

function addon:GetMobLearningEntry(classification, learningKey)
  local bucket = self:GetMobLearningBucket(classification)
  if not bucket or not learningKey then
    return nil
  end

  return bucket[learningKey]
end

function addon:EnsureMobLearningEntry(classification, learningKey, name, creatureType, level)
  local bucket = self:GetMobLearningBucket(classification)
  if not bucket or not learningKey then
    return nil
  end

  local entry = bucket[learningKey]
  if not entry then
    entry = {
      name = name,
      creatureType = creatureType or "unknown",
      samples = 0,
      durationSamples = 0,
      avgMaxHealth = 0,
      avgFightDuration = 0,
      minFightDuration = 0,
      maxFightDuration = 0,
      minLevel = level,
      maxLevel = level,
      avgLevel = level,
      avgSnDLeftover = 0,
      sndWasteSamples = 0,
      avgPrimaryLeftover = 0,
      primaryWasteSamples = 0,
      primaryOpportunityCount = 0,
      primaryOpportunityMisses = 0,
      setupAttempts = 0,
      abandonedSetups = 0,
      healthConfidence = 0,
      durationConfidence = 0,
      confidence = 0,
      wastePenalty = 0,
      lastSeen = 0,
    }
    bucket[learningKey] = entry
  end

  if entry.durationSamples == nil then
    entry.durationSamples = 0
  end
  if entry.avgSnDLeftover == nil then
    entry.avgSnDLeftover = 0
  end
  if entry.sndWasteSamples == nil then
    entry.sndWasteSamples = 0
  end
  if entry.avgPrimaryLeftover == nil then
    entry.avgPrimaryLeftover = 0
  end
  if entry.primaryWasteSamples == nil then
    entry.primaryWasteSamples = 0
  end
  if entry.primaryOpportunityCount == nil then
    entry.primaryOpportunityCount = 0
  end
  if entry.primaryOpportunityMisses == nil then
    entry.primaryOpportunityMisses = 0
  end
  if entry.setupAttempts == nil then
    entry.setupAttempts = 0
  end
  if entry.abandonedSetups == nil then
    entry.abandonedSetups = 0
  end
  if entry.healthConfidence == nil then
    entry.healthConfidence = 0
  end
  if entry.durationConfidence == nil then
    entry.durationConfidence = 0
  end
  if entry.confidence == nil then
    entry.confidence = 0
  end
  if entry.wastePenalty == nil then
    entry.wastePenalty = 0
  end

  self:UpdateLearningDerivedFields(entry)

  return entry
end

function addon:ClampUnitValue(value)
  if not value or value < 0 then
    return 0
  end
  if value > 1 then
    return 1
  end
  return value
end

function addon:UpdateRollingAverage(entry, avgKey, sampleKey, value)
  if not entry or value == nil then
    return
  end

  local samples = entry[sampleKey] or 0
  local newSamples = samples + 1
  entry[sampleKey] = newSamples
  entry[avgKey] = ((entry[avgKey] or 0) * samples + value) / newSamples
end

function addon:GetLearningRecencyFactor(entry)
  if not entry or not entry.lastSeen or entry.lastSeen <= 0 or not time then
    return 0.7
  end

  local ageSeconds = math.max((time() or 0) - entry.lastSeen, 0)
  local ageDays = ageSeconds / 86400
  if ageDays <= 1 then
    return 1
  end
  if ageDays <= 7 then
    return 0.85
  end
  if ageDays <= 30 then
    return 0.65
  end
  return 0.45
end

function addon:UpdateLearningDerivedFields(entry)
  if not entry then
    return
  end

  local healthConfidence = self:ClampUnitValue((entry.samples or 0) / 8)
  local durationConfidence = self:ClampUnitValue((entry.durationSamples or 0) / 6)
  local recencyFactor = self:GetLearningRecencyFactor(entry)
  local primaryMissRate = 0
  if (entry.primaryOpportunityCount or 0) > 0 then
    primaryMissRate = (entry.primaryOpportunityMisses or 0) / entry.primaryOpportunityCount
  end
  local abandonedRate = 0
  if (entry.setupAttempts or 0) > 0 then
    abandonedRate = (entry.abandonedSetups or 0) / entry.setupAttempts
  end
  local sndWastePenalty = math.min((entry.avgSnDLeftover or 0) / 12, 1)
  local primaryWastePenalty = math.min((entry.avgPrimaryLeftover or 0) / 10, 1)
  local wastePenalty = self:ClampUnitValue(
    (sndWastePenalty * 0.30) +
    (primaryWastePenalty * 0.25) +
    (primaryMissRate * 0.30) +
    (abandonedRate * 0.15)
  )

  entry.healthConfidence = healthConfidence
  entry.durationConfidence = durationConfidence
  entry.wastePenalty = wastePenalty
  entry.confidence = self:ClampUnitValue(
    (healthConfidence * 0.40) +
    (durationConfidence * 0.45) +
    (recencyFactor * 0.15) -
    (wastePenalty * 0.20)
  )
end

function addon:UpdateMobLearningHealth(entry, maxHealth, level, name, creatureType)
  if not entry or not self:IsValidLearningObservation(maxHealth, level) then
    return
  end

  local oldSamples = entry.samples or 0
  local newSamples = oldSamples + 1
  entry.name = name or entry.name
  entry.creatureType = creatureType or entry.creatureType
  entry.samples = newSamples
  entry.avgMaxHealth = ((entry.avgMaxHealth or 0) * oldSamples + maxHealth) / newSamples

  if level and level > 0 then
    local oldAvgLevel = entry.avgLevel or level
    entry.avgLevel = (oldAvgLevel * oldSamples + level) / newSamples
    if not entry.minLevel or level < entry.minLevel then
      entry.minLevel = level
    end
    if not entry.maxLevel or level > entry.maxLevel then
      entry.maxLevel = level
    end
  end

  entry.lastSeen = time and time() or 0
  self:UpdateLearningDerivedFields(entry)
end

function addon:UpdateMobLearningFightDuration(entry, duration)
  if not entry or not duration or duration < 1.5 or duration > 120 then
    return
  end

  local durationSamples = entry.durationSamples or 0
  local newDurationSamples = durationSamples + 1
  entry.durationSamples = newDurationSamples
  entry.avgFightDuration = ((entry.avgFightDuration or 0) * durationSamples + duration) / newDurationSamples

  if not entry.minFightDuration or entry.minFightDuration == 0 or duration < entry.minFightDuration then
    entry.minFightDuration = duration
  end

  if not entry.maxFightDuration or duration > entry.maxFightDuration then
    entry.maxFightDuration = duration
  end

  entry.lastSeen = time and time() or 0
  self:UpdateLearningDerivedFields(entry)
end

function addon:UpdateMobLearningWasteMetrics(entry, fight, reason)
  if not entry or not fight then
    return
  end

  local likelyCompletedFight = reason == "combat_end"
    or (fight.lastHealthPct and fight.lastHealthPct <= 20)

  if likelyCompletedFight and fight.lastSnDRemaining and fight.lastSnDRemaining > 0 then
    self:UpdateRollingAverage(entry, "avgSnDLeftover", "sndWasteSamples", fight.lastSnDRemaining)
  end

  if likelyCompletedFight
    and fight.castPrimary
    and fight.lastPrimaryRemaining
    and fight.lastPrimaryRemaining > 0 then
    self:UpdateRollingAverage(entry, "avgPrimaryLeftover", "primaryWasteSamples", fight.lastPrimaryRemaining)
  end

  if fight.primaryOpportunitySeen then
    entry.primaryOpportunityCount = (entry.primaryOpportunityCount or 0) + 1
    if not fight.castPrimary then
      entry.primaryOpportunityMisses = (entry.primaryOpportunityMisses or 0) + 1
    end
  end

  if fight.setupStarted then
    entry.setupAttempts = (entry.setupAttempts or 0) + 1
    if reason == "target_change" and fight.lastHealthPct and fight.lastHealthPct > 35 then
      entry.abandonedSetups = (entry.abandonedSetups or 0) + 1
    end
  end

  entry.lastSeen = time and time() or 0
  self:UpdateLearningDerivedFields(entry)
end

function addon:GetLearningConfidence(entry)
  if not entry then
    return 0
  end

  if entry.confidence == nil then
    self:UpdateLearningDerivedFields(entry)
  end

  return entry.confidence or 0
end

function addon:GetLearningWastePenalty(entry)
  if not entry then
    return 0
  end

  if entry.wastePenalty == nil then
    self:UpdateLearningDerivedFields(entry)
  end

  return entry.wastePenalty or 0
end

function addon:GetLearningReferenceLevel(entry)
  if not entry then
    return 0
  end

  if entry.avgLevel and entry.avgLevel > 0 then
    return entry.avgLevel
  end

  if entry.maxLevel and entry.maxLevel > 0 then
    return entry.maxLevel
  end

  if entry.minLevel and entry.minLevel > 0 then
    return entry.minLevel
  end

  return 0
end

function addon:IsFamilyLearningMatch(entry, creatureType, level)
  if not entry then
    return false
  end

  local entryCreatureType = entry.creatureType or "unknown"
  if creatureType
    and creatureType ~= "unknown"
    and entryCreatureType ~= "unknown"
    and entryCreatureType ~= creatureType then
    return false
  end

  local entryLevel = self:GetLearningReferenceLevel(entry)
  if level and level > 0 and entryLevel > 0 and math.abs(entryLevel - level) > 3 then
    return false
  end

  return true
end

function addon:MergeInterruptSpellLearning(targetMap, sourceMap, weight)
  if not targetMap or not sourceMap or not weight or weight <= 0 then
    return
  end

  for spellKey, sourceEntry in pairs(sourceMap) do
    local targetEntry = targetMap[spellKey] or {
      name = sourceEntry.name,
      count = 0,
      outcomeSamples = 0,
      harmfulCount = 0,
      benignCount = 0,
      damageEvents = 0,
      controlEvents = 0,
      drainEvents = 0,
      healEvents = 0,
      buffEvents = 0,
      totalDamage = 0,
      dangerTotal = 0,
      avgDanger = 0,
      maxDanger = 0,
      lastSeen = 0,
    }

    targetEntry.name = sourceEntry.name or targetEntry.name
    targetEntry.count = (targetEntry.count or 0) + ((sourceEntry.count or 0) * weight)
    targetEntry.outcomeSamples = (targetEntry.outcomeSamples or 0) + ((sourceEntry.outcomeSamples or 0) * weight)
    targetEntry.harmfulCount = (targetEntry.harmfulCount or 0) + ((sourceEntry.harmfulCount or 0) * weight)
    targetEntry.benignCount = (targetEntry.benignCount or 0) + ((sourceEntry.benignCount or 0) * weight)
    targetEntry.damageEvents = (targetEntry.damageEvents or 0) + ((sourceEntry.damageEvents or 0) * weight)
    targetEntry.controlEvents = (targetEntry.controlEvents or 0) + ((sourceEntry.controlEvents or 0) * weight)
    targetEntry.drainEvents = (targetEntry.drainEvents or 0) + ((sourceEntry.drainEvents or 0) * weight)
    targetEntry.healEvents = (targetEntry.healEvents or 0) + ((sourceEntry.healEvents or 0) * weight)
    targetEntry.buffEvents = (targetEntry.buffEvents or 0) + ((sourceEntry.buffEvents or 0) * weight)
    targetEntry.totalDamage = (targetEntry.totalDamage or 0) + ((sourceEntry.totalDamage or 0) * weight)

    local sourceOutcomeSamples = sourceEntry.outcomeSamples or 0
    local sourceDangerTotal = sourceEntry.dangerTotal
    if sourceDangerTotal == nil then
      sourceDangerTotal = (sourceEntry.avgDanger or 0) * sourceOutcomeSamples
    end
    targetEntry.dangerTotal = (targetEntry.dangerTotal or 0) + (sourceDangerTotal * weight)
    targetEntry.maxDanger = math.max(targetEntry.maxDanger or 0, sourceEntry.maxDanger or sourceEntry.avgDanger or 0)
    targetEntry.lastSeen = math.max(targetEntry.lastSeen or 0, sourceEntry.lastSeen or 0)

    if (targetEntry.outcomeSamples or 0) > 0 then
      targetEntry.avgDanger = (targetEntry.dangerTotal or 0) / targetEntry.outcomeSamples
    end

    targetMap[spellKey] = targetEntry
  end
end

function addon:BuildFamilyLearningProfile(classification, learningKey, creatureType, level)
  local bucket = self:GetMobLearningBucket(classification)
  if not bucket then
    return nil
  end

  local totalWeight = 0
  local profile = {
    name = "Family Profile",
    creatureType = creatureType or "unknown",
    samples = 0,
    durationSamples = 0,
    avgMaxHealth = 0,
    avgFightDuration = 0,
    avgLevel = 0,
    avgSnDLeftover = 0,
    sndWasteSamples = 0,
    avgPrimaryLeftover = 0,
    primaryWasteSamples = 0,
    primaryOpportunityCount = 0,
    primaryOpportunityMisses = 0,
    setupAttempts = 0,
    abandonedSetups = 0,
    castSamples = 0,
    stunImmuneSamples = 0,
    stunSuccessSamples = 0,
    lastSeen = 0,
    lastCastSeen = 0,
    castSpells = {},
    familyMembers = 0,
    isFamilyProfile = true,
  }

  for key, entry in pairs(bucket) do
    if key ~= learningKey and self:IsFamilyLearningMatch(entry, creatureType, level) then
      local confidence = self:GetLearningConfidence(entry)
      local sampleLoad = math.max(entry.samples or 0, entry.durationSamples or 0, entry.castSamples or 0)
      if confidence >= 0.12 or sampleLoad >= 2 then
        local entryLevel = self:GetLearningReferenceLevel(entry)
        local levelWeight = 1
        if level and level > 0 and entryLevel > 0 then
          levelWeight = math.max(0.35, 1 - (math.abs(entryLevel - level) * 0.18))
        end

        local weight = (0.25 + (confidence * 0.75))
          * math.max(0.35, math.min(sampleLoad, 6) / 6)
          * levelWeight

        if weight > 0 then
          totalWeight = totalWeight + weight
          profile.familyMembers = profile.familyMembers + 1
          profile.samples = profile.samples + ((entry.samples or 0) * weight)
          profile.durationSamples = profile.durationSamples + ((entry.durationSamples or 0) * weight)
          profile.avgMaxHealth = profile.avgMaxHealth + ((entry.avgMaxHealth or 0) * weight)
          profile.avgFightDuration = profile.avgFightDuration + ((entry.avgFightDuration or 0) * weight)
          profile.avgLevel = profile.avgLevel + ((self:GetLearningReferenceLevel(entry) or 0) * weight)
          profile.avgSnDLeftover = profile.avgSnDLeftover + ((entry.avgSnDLeftover or 0) * weight)
          profile.sndWasteSamples = profile.sndWasteSamples + ((entry.sndWasteSamples or 0) * weight)
          profile.avgPrimaryLeftover = profile.avgPrimaryLeftover + ((entry.avgPrimaryLeftover or 0) * weight)
          profile.primaryWasteSamples = profile.primaryWasteSamples + ((entry.primaryWasteSamples or 0) * weight)
          profile.primaryOpportunityCount = profile.primaryOpportunityCount + ((entry.primaryOpportunityCount or 0) * weight)
          profile.primaryOpportunityMisses = profile.primaryOpportunityMisses + ((entry.primaryOpportunityMisses or 0) * weight)
          profile.setupAttempts = profile.setupAttempts + ((entry.setupAttempts or 0) * weight)
          profile.abandonedSetups = profile.abandonedSetups + ((entry.abandonedSetups or 0) * weight)
          profile.castSamples = profile.castSamples + ((entry.castSamples or 0) * weight)
          profile.stunImmuneSamples = profile.stunImmuneSamples + ((entry.stunImmuneSamples or 0) * weight)
          profile.stunSuccessSamples = profile.stunSuccessSamples + ((entry.stunSuccessSamples or 0) * weight)
          profile.lastSeen = math.max(profile.lastSeen or 0, entry.lastSeen or 0)
          profile.lastCastSeen = math.max(profile.lastCastSeen or 0, entry.lastCastSeen or 0)
          self:MergeInterruptSpellLearning(profile.castSpells, entry.castSpells, weight)
        end
      end
    end
  end

  if totalWeight <= 0 then
    return nil
  end

  profile.avgMaxHealth = profile.avgMaxHealth / totalWeight
  profile.avgFightDuration = profile.avgFightDuration / totalWeight
  profile.avgLevel = profile.avgLevel / totalWeight
  profile.avgSnDLeftover = profile.avgSnDLeftover / totalWeight
  profile.avgPrimaryLeftover = profile.avgPrimaryLeftover / totalWeight
  profile.samples = profile.samples / totalWeight
  profile.durationSamples = profile.durationSamples / totalWeight
  profile.castSamples = profile.castSamples / totalWeight
  profile.sndWasteSamples = profile.sndWasteSamples / totalWeight
  profile.primaryWasteSamples = profile.primaryWasteSamples / totalWeight
  profile.primaryOpportunityCount = profile.primaryOpportunityCount / totalWeight
  profile.primaryOpportunityMisses = profile.primaryOpportunityMisses / totalWeight
  profile.setupAttempts = profile.setupAttempts / totalWeight
  profile.abandonedSetups = profile.abandonedSetups / totalWeight
  profile.stunImmuneSamples = profile.stunImmuneSamples / totalWeight
  profile.stunSuccessSamples = profile.stunSuccessSamples / totalWeight
  profile.stunImmuneConfidence = self:GetStunImmunityConfidence(profile)
  self:UpdateLearningDerivedFields(profile)
  profile.confidence = self:ClampUnitValue((profile.confidence or 0) * 0.82)
  return profile
end

function addon:BuildEffectiveLearningProfile(exactProfile, familyProfile)
  if not exactProfile then
    return familyProfile
  end

  if not familyProfile then
    return exactProfile
  end

  local exactConfidence = self:GetLearningConfidence(exactProfile)
  if exactConfidence >= 0.62
    and (exactProfile.samples or 0) >= 2
    and (exactProfile.durationSamples or 0) >= 1 then
    return exactProfile
  end

  local familyConfidence = self:GetLearningConfidence(familyProfile)
  local exactWeight = math.max(0.35, exactConfidence + 0.15)
  local familyWeight = math.max(0.2, familyConfidence * 0.9)
  local totalWeight = exactWeight + familyWeight

  local profile = {
    name = exactProfile.name or familyProfile.name,
    creatureType = exactProfile.creatureType or familyProfile.creatureType or "unknown",
    avgMaxHealth = (((exactProfile.avgMaxHealth or 0) * exactWeight) + ((familyProfile.avgMaxHealth or 0) * familyWeight)) / totalWeight,
    avgFightDuration = (((exactProfile.avgFightDuration or 0) * exactWeight) + ((familyProfile.avgFightDuration or 0) * familyWeight)) / totalWeight,
    avgLevel = (((self:GetLearningReferenceLevel(exactProfile) or 0) * exactWeight) + ((self:GetLearningReferenceLevel(familyProfile) or 0) * familyWeight)) / totalWeight,
    avgSnDLeftover = (((exactProfile.avgSnDLeftover or 0) * exactWeight) + ((familyProfile.avgSnDLeftover or 0) * familyWeight)) / totalWeight,
    avgPrimaryLeftover = (((exactProfile.avgPrimaryLeftover or 0) * exactWeight) + ((familyProfile.avgPrimaryLeftover or 0) * familyWeight)) / totalWeight,
    samples = (((exactProfile.samples or 0) * exactWeight) + ((familyProfile.samples or 0) * familyWeight)) / totalWeight,
    durationSamples = (((exactProfile.durationSamples or 0) * exactWeight) + ((familyProfile.durationSamples or 0) * familyWeight)) / totalWeight,
    castSamples = (((exactProfile.castSamples or 0) * exactWeight) + ((familyProfile.castSamples or 0) * familyWeight)) / totalWeight,
    sndWasteSamples = (((exactProfile.sndWasteSamples or 0) * exactWeight) + ((familyProfile.sndWasteSamples or 0) * familyWeight)) / totalWeight,
    primaryWasteSamples = (((exactProfile.primaryWasteSamples or 0) * exactWeight) + ((familyProfile.primaryWasteSamples or 0) * familyWeight)) / totalWeight,
    primaryOpportunityCount = (((exactProfile.primaryOpportunityCount or 0) * exactWeight) + ((familyProfile.primaryOpportunityCount or 0) * familyWeight)) / totalWeight,
    primaryOpportunityMisses = (((exactProfile.primaryOpportunityMisses or 0) * exactWeight) + ((familyProfile.primaryOpportunityMisses or 0) * familyWeight)) / totalWeight,
    setupAttempts = (((exactProfile.setupAttempts or 0) * exactWeight) + ((familyProfile.setupAttempts or 0) * familyWeight)) / totalWeight,
    abandonedSetups = (((exactProfile.abandonedSetups or 0) * exactWeight) + ((familyProfile.abandonedSetups or 0) * familyWeight)) / totalWeight,
    stunImmuneSamples = (((exactProfile.stunImmuneSamples or 0) * exactWeight) + ((familyProfile.stunImmuneSamples or 0) * familyWeight)) / totalWeight,
    stunSuccessSamples = (((exactProfile.stunSuccessSamples or 0) * exactWeight) + ((familyProfile.stunSuccessSamples or 0) * familyWeight)) / totalWeight,
    lastSeen = math.max(exactProfile.lastSeen or 0, familyProfile.lastSeen or 0),
    lastCastSeen = math.max(exactProfile.lastCastSeen or 0, familyProfile.lastCastSeen or 0),
    castSpells = {},
    blendedProfile = true,
  }

  self:MergeInterruptSpellLearning(profile.castSpells, familyProfile.castSpells, familyWeight)
  self:MergeInterruptSpellLearning(profile.castSpells, exactProfile.castSpells, exactWeight)
  profile.stunImmuneConfidence = self:GetStunImmunityConfidence(profile)
  self:UpdateLearningDerivedFields(profile)
  profile.confidence = self:ClampUnitValue(((exactConfidence * exactWeight) + (familyConfidence * familyWeight)) / totalWeight)
  return profile
end

function addon:NormalizeInterruptSpellKey(name)
  if not name or name == "" then
    return nil
  end

  return string.lower(trim(name))
end

function addon:IsStaticKickInterruptSpell(name)
  local spellKey = self:NormalizeInterruptSpellKey(name)
  return spellKey and self.kickInterruptSpells and self.kickInterruptSpells[spellKey] == true
end

function addon:EnsureInterruptSpellLearningEntry(entry, spellName)
  if not entry then
    return nil
  end

  local spellKey = self:NormalizeInterruptSpellKey(spellName)
  if not spellKey then
    return nil
  end

  entry.castSpells = entry.castSpells or {}
  local spellEntry = entry.castSpells[spellKey]
  if not spellEntry then
    spellEntry = {
      name = spellName,
      count = 0,
      outcomeSamples = 0,
      harmfulCount = 0,
      benignCount = 0,
      damageEvents = 0,
      controlEvents = 0,
      drainEvents = 0,
      healEvents = 0,
      buffEvents = 0,
      totalDamage = 0,
      dangerTotal = 0,
      avgDanger = 0,
      maxDanger = 0,
      lastSeen = 0,
    }
    entry.castSpells[spellKey] = spellEntry
  end

  return spellEntry, spellKey
end

function addon:GetInterruptLearningConfidence(entry)
  if not entry then
    return 0
  end

  local castSamples = entry.castSamples or 0
  if castSamples <= 0 then
    return 0
  end

  local sampleFactor = self:ClampUnitValue(castSamples / 4)
  local recencyFactor = 0
  if entry.lastCastSeen and entry.lastCastSeen > 0 and time then
    local age = math.max(time() - entry.lastCastSeen, 0)
    recencyFactor = self:ClampUnitValue(1 - (age / (7 * 24 * 60 * 60)))
  end

  return self:ClampUnitValue((sampleFactor * 0.8) + (recencyFactor * 0.2))
end

function addon:UpdateMobInterruptLearning(entry, spellName)
  if not entry then
    return
  end

  entry.castSamples = (entry.castSamples or 0) + 1
  entry.lastCastSeen = time and time() or 0

  local spellEntry = self:EnsureInterruptSpellLearningEntry(entry, spellName)
  if spellEntry then
    spellEntry.name = spellName or spellEntry.name
    spellEntry.count = (spellEntry.count or 0) + 1
    spellEntry.lastSeen = time and time() or 0
  end

  self:UpdateLearningDerivedFields(entry)
end

function addon:UpdateInterruptSpellOutcome(entry, spellName, outcomeType, amount, targetName)
  local spellEntry = self:EnsureInterruptSpellLearningEntry(entry, spellName)
  if not spellEntry then
    return
  end

  local targetText = string.lower(trim(targetName or ""))
  local playerName = string.lower(UnitName("player") or "")
  local targetNameLower = string.lower(UnitName("target") or "")
  local targetIsPlayer = targetText == "you" or targetText == playerName
  local targetIsEnemy = targetText ~= "" and (targetText == targetNameLower)

  local score = 0.35
  if outcomeType == "damage" then
    local playerMaxHealth = UnitHealthMax("player") or 0
    local damageRatio = 0
    if amount and amount > 0 and playerMaxHealth > 0 and targetIsPlayer then
      damageRatio = math.min(amount / playerMaxHealth, 0.55)
    elseif amount and amount > 0 then
      damageRatio = math.min(amount / 800, 0.25)
    end
    score = (targetIsPlayer and 0.45 or 0.25) + damageRatio
    spellEntry.damageEvents = (spellEntry.damageEvents or 0) + 1
    spellEntry.totalDamage = (spellEntry.totalDamage or 0) + (amount or 0)
  elseif outcomeType == "drain" then
    score = targetIsPlayer and 0.72 or 0.52
    spellEntry.drainEvents = (spellEntry.drainEvents or 0) + 1
  elseif outcomeType == "heal" then
    score = targetIsEnemy and 0.72 or 0.48
    spellEntry.healEvents = (spellEntry.healEvents or 0) + 1
  elseif outcomeType == "buff" then
    score = targetIsEnemy and 0.66 or 0.44
    spellEntry.buffEvents = (spellEntry.buffEvents or 0) + 1
  elseif outcomeType == "control" then
    score = targetIsPlayer and 0.82 or 0.62
    spellEntry.controlEvents = (spellEntry.controlEvents or 0) + 1
  end

  spellEntry.outcomeSamples = (spellEntry.outcomeSamples or 0) + 1
  spellEntry.harmfulCount = (spellEntry.harmfulCount or 0) + 1
  spellEntry.dangerTotal = (spellEntry.dangerTotal or 0) + score
  spellEntry.avgDanger = spellEntry.dangerTotal / spellEntry.outcomeSamples
  spellEntry.maxDanger = math.max(spellEntry.maxDanger or 0, score)
  spellEntry.lastSeen = time and time() or 0
  entry.lastCastSeen = spellEntry.lastSeen
  self:UpdateLearningDerivedFields(entry)
end

function addon:GetInterruptSpellLearningEntry(entry, spellName)
  if not entry or not entry.castSpells then
    return nil
  end

  local spellKey = self:NormalizeInterruptSpellKey(spellName)
  if not spellKey then
    return nil
  end

  return entry.castSpells[spellKey]
end

function addon:GetInterruptSpellDangerScore(spellEntry)
  if not spellEntry then
    return 0, 0
  end

  local castCount = spellEntry.count or 0
  local outcomeSamples = spellEntry.outcomeSamples or 0
  local avgDanger = spellEntry.avgDanger or 0
  if outcomeSamples > 0 and spellEntry.dangerTotal then
    avgDanger = spellEntry.dangerTotal / outcomeSamples
  end

  local harmfulRate = 0
  if castCount > 0 then
    harmfulRate = (spellEntry.harmfulCount or 0) / castCount
  end

  local sampleFactor = self:ClampUnitValue((castCount + outcomeSamples) / 6)
  local maxDanger = spellEntry.maxDanger or avgDanger
  local score = self:ClampUnitValue(
    (avgDanger * 0.55) +
    (maxDanger * 0.20) +
    (harmfulRate * 0.15) +
    (sampleFactor * 0.10)
  )

  return score, sampleFactor
end

function addon:GetInterruptPressureScore(entry)
  if not entry or not entry.castSpells then
    return 0
  end

  local bestScore = 0
  for _, spellEntry in pairs(entry.castSpells) do
    local dangerScore, confidence = self:GetInterruptSpellDangerScore(spellEntry)
    local combined = dangerScore * math.max(confidence, 0.35)
    if combined > bestScore then
      bestScore = combined
    end
  end

  -- Cast-count alone is useful for interrupt reservation even when we have
  -- not yet observed a landing outcome for the spell.
  local casterPresence = self:ClampUnitValue((entry.castSamples or 0) / 6) * 0.36
  return math.max(bestScore, casterPresence)
end

function addon:GetInterruptLearningProfile()
  local entry = self:GetEffectiveMobLearningProfile()
  if not entry then
    return nil, 0
  end

  return entry, self:GetInterruptLearningConfidence(entry)
end

function addon:GetStunImmunityConfidence(entry)
  if not entry then
    return 0
  end

  local immuneSamples = entry.stunImmuneSamples or 0
  local successSamples = entry.stunSuccessSamples or 0
  local totalSamples = immuneSamples + successSamples
  if totalSamples <= 0 then
    return 0
  end

  local ratio = immuneSamples / totalSamples
  local sampleFactor = self:ClampUnitValue(totalSamples / 3)
  local score = ratio * sampleFactor
  if immuneSamples > 0 and successSamples == 0 then
    score = math.max(score, 0.8)
  end

  return self:ClampUnitValue(score)
end

function addon:RecordKidneyShotLearning(result, sample)
  if not sample then
    return
  end

  local entry = self:EnsureMobLearningEntry(
    sample.classification,
    sample.learningKey,
    sample.name,
    sample.creatureType,
    sample.level
  )
  if not entry then
    return
  end

  if result == "immune" then
    entry.stunImmuneSamples = (entry.stunImmuneSamples or 0) + 1
    entry.lastStunImmuneSeen = time and time() or 0
  elseif result == "success" then
    entry.stunSuccessSamples = (entry.stunSuccessSamples or 0) + 1
    entry.lastStunSuccessSeen = time and time() or 0
  else
    return
  end

  entry.stunImmuneConfidence = self:GetStunImmunityConfidence(entry)
  self:UpdateLearningDerivedFields(entry)
end

function addon:BuildCurrentTargetLearningSample()
  if not self:IsHostileTarget() then
    return nil
  end

  local name = UnitName("target")
  local learningKey = self:NormalizeMobLearningKey(name)
  if not learningKey then
    return nil
  end

  return {
    targetKey = self:GetTargetKey(),
    learningKey = learningKey,
    classification = self:GetTargetClassification(),
    name = name,
    creatureType = UnitCreatureType("target") or "unknown",
    level = UnitLevel("target") or 0,
  }
end

function addon:BeginPendingKidneyShotCheck()
  local sample = self:BuildCurrentTargetLearningSample()
  if not sample then
    self.state.pendingKidneyShotCheck = nil
    return
  end

  sample.expiresAt = GetTime() + 1.0
  self.state.pendingKidneyShotCheck = sample
end

function addon:ClearPendingKidneyShotCheck()
  self.state.pendingKidneyShotCheck = nil
end

function addon:UpdatePendingKidneyShotCheck()
  local pending = self.state.pendingKidneyShotCheck
  if not pending then
    return
  end

  if pending.targetKey ~= self:GetTargetKey() then
    self.state.pendingKidneyShotCheck = nil
    return
  end

  if self:FindUnitDebuffByName("target", "Kidney Shot") then
    self:RecordKidneyShotLearning("success", pending)
    self.state.pendingKidneyShotCheck = nil
    return
  end

  if pending.expiresAt and GetTime() >= pending.expiresAt then
    self.state.pendingKidneyShotCheck = nil
  end
end

function addon:PruneActiveEnemyCast()
  local castInfo = self.state.activeEnemyCast
  if not castInfo then
    return
  end

  if castInfo.expiresAt and castInfo.expiresAt <= GetTime() then
    if castInfo.source == "castbar" then
      self.state.suppressedEnemyCastBar = {
        targetKey = castInfo.targetKey,
        spellName = castInfo.spellName,
      }
    end
    self:ClearActiveEnemyCast("timeout")
    return
  end

  local targetKey = self:GetTargetKey()
  if castInfo.targetKey and targetKey and castInfo.targetKey ~= targetKey then
    self:ClearActiveEnemyCast("target changed")
  end
end

function addon:ClearActiveEnemyCast(reason)
  local activeCast = self.state.activeEnemyCast
  if activeCast then
    self:DebugEvent(
      "active_enemy_cast_cleared",
      tostring(activeCast.spellName or "unknown"),
      tostring(reason or "unspecified")
    )
  end
  self.state.activeEnemyCast = nil
end

function addon:GetInterruptibleEnemyCast()
  local activeCast = self:GetActiveEnemyCast()
  if not activeCast then
    return nil
  end

  local now = GetTime()
  if activeCast.source == "message"
    and (now - (activeCast.startedAt or now)) > self.messageInterruptFallbackWindow then
    self:ClearActiveEnemyCast("message fallback expired")
    return nil
  end

  activeCast.remaining = math.max((activeCast.expiresAt or now) - now, 0)
  if activeCast.remaining <= 0.15 then
    self:ClearActiveEnemyCast("too little cast time remaining")
    return nil
  end

  return activeCast
end

function addon:HasReliableNoActiveTargetCast()
  if not self:IsHostileTarget() then
    return true
  end

  local authoritativeChecked = false
  local authoritativeCast = false

  if UnitCastingInfo then
    authoritativeChecked = true
    local name = UnitCastingInfo("target")
    if name and name ~= "" then
      authoritativeCast = true
    end
  end

  if UnitChannelInfo then
    authoritativeChecked = true
    local name = UnitChannelInfo("target")
    if name and name ~= "" then
      authoritativeCast = true
    end
  end

  if authoritativeChecked then
    return not authoritativeCast
  end

  if TargetFrameSpellBar then
    return not TargetFrameSpellBar:IsShown()
  end

  return false
end

function addon:GetLiveTargetCastInfo()
  if not self:IsHostileTarget() then
    return nil
  end

  local spellName = nil
  local endTime = nil
  local authoritativeChecked = false
  local castBarRemaining = nil

  if UnitCastingInfo then
    authoritativeChecked = true
    local name, _, _, _, castEndTimeMs = UnitCastingInfo("target")
    if name and name ~= "" then
      spellName = name
      if castEndTimeMs then
        endTime = castEndTimeMs / 1000
      end
    end
  end

  if (not spellName or spellName == "") and UnitChannelInfo then
    authoritativeChecked = true
    local name, _, _, _, channelEndTimeMs = UnitChannelInfo("target")
    if name and name ~= "" then
      spellName = name
      if channelEndTimeMs then
        endTime = channelEndTimeMs / 1000
      end
    end
  end

  if authoritativeChecked and (not spellName or spellName == "") then
    return nil, true
  end

  local source = "api"
  if not authoritativeChecked and TargetFrameSpellBar and TargetFrameSpellBar:IsShown() then
    local text = nil
    if TargetFrameSpellBarText and TargetFrameSpellBarText.GetText then
      text = TargetFrameSpellBarText:GetText()
    elseif TargetFrameSpellBar.Text and TargetFrameSpellBar.Text.GetText then
      text = TargetFrameSpellBar.Text:GetText()
    end

    if text and text ~= "" then
      spellName = text
      source = "castbar"

      if TargetFrameSpellBar.GetMinMaxValues and TargetFrameSpellBar.GetValue then
        local minimum, maximum = TargetFrameSpellBar:GetMinMaxValues()
        local value = TargetFrameSpellBar:GetValue()
        if type(minimum) == "number" and type(maximum) == "number" and type(value) == "number" then
          if TargetFrameSpellBar.channeling then
            castBarRemaining = value - minimum
          else
            castBarRemaining = maximum - value
          end
          if castBarRemaining <= 0 or castBarRemaining > 60 then
            castBarRemaining = nil
          end
        end
      end
    end
  end

  if not spellName or spellName == "" then
    return nil, authoritativeChecked
  end

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return nil
  end

  if source == "castbar" then
    local suppressed = self.state.suppressedEnemyCastBar
    if suppressed
      and suppressed.targetKey == targetKey
      and suppressed.spellName == spellName then
      return nil, false
    end
    self.state.suppressedEnemyCastBar = nil
  end

  local now = GetTime()
  local expiresAt = endTime
  if source == "castbar" then
    local current = self.state.activeEnemyCast
    if current
      and current.source == "castbar"
      and current.targetKey == targetKey
      and current.spellName == spellName then
      expiresAt = current.expiresAt
    else
      expiresAt = now + (castBarRemaining or 1.5)
    end
  end

  return {
    targetKey = targetKey,
    casterName = UnitName("target"),
    spellName = spellName,
    startedAt = now,
    expiresAt = expiresAt or (now + 1.5),
    source = source,
  }, authoritativeChecked
end

function addon:RefreshActiveEnemyCast()
  local liveCast, authoritativeChecked = self:GetLiveTargetCastInfo()
  if authoritativeChecked then
    if liveCast then
      self.state.activeEnemyCast = liveCast
    elseif self.state.activeEnemyCast
      and self.state.activeEnemyCast.source == "affliction"
      and self:NormalizeInterruptSpellKey(self.state.activeEnemyCast.spellName) == "mind flay"
      and self.state.activeEnemyCast.channelVictimUnit
      and self:FindUnitDebuffByName(
        self.state.activeEnemyCast.channelVictimUnit,
        "Mind Flay"
      ) then
      return
    else
      self:ClearActiveEnemyCast("authoritative no-cast")
    end
    return
  end

  if not liveCast then
    if TargetFrameSpellBar and not TargetFrameSpellBar:IsShown() then
      self.state.suppressedEnemyCastBar = nil
    end
    if self.state.activeEnemyCast
      and self.state.activeEnemyCast.source == "castbar"
      and self:HasReliableNoActiveTargetCast() then
      self:ClearActiveEnemyCast("cast bar hidden")
    end
    return
  end

  local current = self.state.activeEnemyCast
  self.state.activeEnemyCast = liveCast
  if not current
    or current.targetKey ~= liveCast.targetKey
    or current.spellName ~= liveCast.spellName
    or current.source ~= liveCast.source then
    self:DebugEvent(
      "enemy_cast_tracking",
      tostring(liveCast.spellName),
      tostring(liveCast.source)
    )
  end
end

function addon:GetActiveEnemyCast()
  self:PruneActiveEnemyCast()
  self:RefreshActiveEnemyCast()
  return self.state.activeEnemyCast
end

function addon:TrackHostileCastFromMessage(casterName, spellName)
  if not casterName or casterName == "" then
    return
  end

  if not self:IsHostileTarget() then
    return
  end

  local targetName = UnitName("target")
  if not targetName or string.lower(targetName) ~= string.lower(casterName) then
    return
  end

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return
  end

  self.state.suppressedEnemyCastBar = nil

  self.state.activeEnemyCast = {
    targetKey = targetKey,
    casterName = targetName,
    spellName = spellName,
    startedAt = GetTime(),
    expiresAt = GetTime() + self.messageInterruptFallbackWindow,
    source = "message",
  }

  local fight = self.state.learningFight
  if fight and fight.targetKey == targetKey then
    fight.castSeen = true
  end
end

function addon:ExtractHostileCastFromMessage(message)
  if not message or message == "" then
    return nil, nil
  end

  local _, _, casterName, spellName = string.find(message, "^(.-) begins to cast (.-)%.?$")
  if casterName and spellName then
    return trim(casterName), trim(spellName)
  end

  _, _, casterName, spellName = string.find(message, "^(.-) begins to perform (.-)%.?$")
  if casterName and spellName then
    return trim(casterName), trim(spellName)
  end

  _, _, casterName, spellName = string.find(message, "^(.-) begins to channel (.-)%.?$")
  if casterName and spellName then
    return trim(casterName), trim(spellName)
  end

  return nil, nil
end

function addon:ExtractHostileOutcomeFromMessage(message)
  if not message or message == "" then
    return nil
  end

  local casterName, spellName, targetName, amount

  _, _, casterName, spellName, targetName, amount = string.find(message, "^(.-)'s (.-) hits (.-) for (%d+)")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      amount = tonumber(amount),
      outcomeType = "damage",
    }
  end

  _, _, casterName, spellName, targetName, amount = string.find(message, "^(.-)'s (.-) crits (.-) for (%d+)")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      amount = tonumber(amount),
      outcomeType = "damage",
    }
  end

  _, _, casterName, spellName, targetName, amount = string.find(message, "^(.-)'s (.-) drains (.-) for (%d+)")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      amount = tonumber(amount),
      outcomeType = "drain",
    }
  end

  _, _, casterName, spellName, targetName, amount = string.find(message, "^(.-)'s (.-) heals (.-) for (%d+)")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      amount = tonumber(amount),
      outcomeType = "heal",
    }
  end

  _, _, casterName, spellName, targetName, amount = string.find(message, "^(.-)'s (.-) critically heals (.-) for (%d+)")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      amount = tonumber(amount),
      outcomeType = "heal",
    }
  end

  _, _, casterName, spellName, targetName = string.find(message, "^(.-)'s (.-) misses (.-)%.?$")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      outcomeType = "miss",
    }
  end

  _, _, casterName, spellName, targetName = string.find(message, "^(.-)'s (.-) was resisted by (.-)%.?$")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      outcomeType = "resist",
    }
  end

  _, _, casterName, spellName = string.find(message, "^You resist (.-)'s (.-)%.?$")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = "you",
      outcomeType = "resist",
    }
  end

  _, _, targetName, casterName, spellName = string.find(message, "^(.-) is immune to (.-)'s (.-)%.?$")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      outcomeType = "immune",
    }
  end

  _, _, casterName, spellName, targetName = string.find(message, "^(.-)'s (.-) is absorbed by (.-)%.?$")
  if casterName and spellName then
    return {
      casterName = trim(casterName),
      spellName = trim(spellName),
      targetName = trim(targetName or ""),
      outcomeType = "absorb",
    }
  end

  _, _, targetName, spellName = string.find(message, "^(.-) gains (.-)%.?$")
  if targetName and spellName then
    return {
      casterName = trim(targetName),
      spellName = trim(spellName),
      targetName = trim(targetName),
      outcomeType = "buff",
    }
  end

  _, _, targetName, spellName = string.find(message, "^(.-) is afflicted by (.-)%.?$")
  if targetName and spellName then
    return {
      spellName = trim(spellName),
      targetName = trim(targetName),
      outcomeType = "control",
    }
  end

  return nil
end

function addon:RecordHostileSpellOutcome(outcome)
  if not outcome or not outcome.spellName then
    return
  end

  local activeCast = self.state.activeEnemyCast
  local targetName = UnitName("target")
  local casterName = outcome.casterName

  if (not casterName or casterName == "") and activeCast then
    local activeSpellKey = self:NormalizeInterruptSpellKey(activeCast.spellName)
    local outcomeSpellKey = self:NormalizeInterruptSpellKey(outcome.spellName)
    if activeSpellKey and outcomeSpellKey and activeSpellKey == outcomeSpellKey then
      casterName = activeCast.casterName
    end
  end

  if not casterName or casterName == "" or not targetName then
    return
  end

  if string.lower(casterName) ~= string.lower(targetName) then
    return
  end

  local sample = self:BuildCurrentTargetLearningSample()
  if not sample then
    return
  end

  local entry = self:EnsureMobLearningEntry(
    sample.classification,
    sample.learningKey,
    sample.name,
    sample.creatureType,
    sample.level
  )
  self:UpdateInterruptSpellOutcome(entry, outcome.spellName, outcome.outcomeType, outcome.amount, outcome.targetName)

  local activeSpellKey = activeCast and self:NormalizeInterruptSpellKey(activeCast.spellName) or nil
  local outcomeSpellKey = self:NormalizeInterruptSpellKey(outcome.spellName)
  if activeCast and activeSpellKey and outcomeSpellKey and activeSpellKey == outcomeSpellKey then
    self.state.activeEnemyCast = nil
  end
end

function addon:OnHostileSpellCastMessage(message)
  local casterName, spellName = self:ExtractHostileCastFromMessage(message)
  if not casterName or not spellName then
    return
  end

  self:TrackHostileCastFromMessage(casterName, spellName)
end

function addon:OnHostileSpellOutcomeMessage(message)
  local outcome = self:ExtractHostileOutcomeFromMessage(message)
  if not outcome then
    return
  end

  local activeCast = self.state.activeEnemyCast
  if not activeCast then
    return
  end

  local activeSpellKey = self:NormalizeInterruptSpellKey(activeCast.spellName)
  local outcomeSpellKey = self:NormalizeInterruptSpellKey(outcome.spellName)
  if not activeSpellKey or activeSpellKey ~= outcomeSpellKey then
    return
  end
  if activeCast.source == "affliction"
    and activeSpellKey == "mind flay"
    and outcome.outcomeType == "control" then
    return
  end

  local targetName = string.lower(UnitName("target") or "")
  local casterName = string.lower(trim(outcome.casterName or ""))
  if casterName ~= "" and casterName ~= targetName then
    return
  end

  self:ClearActiveEnemyCast("spell completed")
end

function addon:IsCastStoppingControlSpell(spellName)
  local spellKey = self:NormalizeInterruptSpellKey(spellName)
  return spellKey and self.castStoppingControlSpells[spellKey] == true
end

function addon:MessageConfirmsCurrentTargetCastStopped(message)
  local activeCast = self.state.activeEnemyCast
  if not activeCast or not message or message == "" then
    return false
  end

  local targetName = string.lower(UnitName("target") or "")
  if targetName == "" then
    return false
  end

  local lower = string.lower(message)
  local activeSpellKey = self:NormalizeInterruptSpellKey(activeCast.spellName)
  if string.find(lower, "interrupt", 1, true)
    and string.find(lower, targetName, 1, true)
    and (not activeSpellKey or string.find(lower, activeSpellKey, 1, true)) then
    return true
  end

  local outcome = self:ExtractHostileOutcomeFromMessage(message)
  if outcome and outcome.outcomeType == "control" then
    local controlledTarget = string.lower(trim(outcome.targetName or ""))
    if controlledTarget == targetName and self:IsCastStoppingControlSpell(outcome.spellName) then
      return true
    end
  end

  local spellName, controlledTarget
  _, _, spellName, controlledTarget = string.find(message, "^Your (.-) hits (.-) for ")
  if not spellName then
    _, _, spellName, controlledTarget = string.find(message, "^Your (.-) hits (.-)%.?$")
  end
  if not spellName then
    _, _, _, spellName, controlledTarget = string.find(message, "^(.-)'s (.-) hits (.-) for ")
  end
  if not spellName then
    _, _, _, spellName, controlledTarget = string.find(message, "^(.-)'s (.-) hits (.-)%.?$")
  end

  return spellName
    and string.lower(trim(controlledTarget or "")) == targetName
    and self:IsCastStoppingControlSpell(spellName)
end

function addon:OnFriendlySpellMessage(message)
  self:TrackMindFlayFromAfflictionMessage(message)

  if self:MessageConfirmsCurrentTargetCastStopped(message) then
    self:ClearActiveEnemyCast("interrupted or controlled")
  end
end

function addon:TrackMindFlayFromAfflictionMessage(message)
  if not message or message == "" or not self:IsHostileTarget() then
    return false
  end

  local victimName, spellName
  _, _, spellName = string.find(message, "^You are afflicted by (.-)%.?$")
  if spellName then
    victimName = "you"
  else
    _, _, victimName, spellName = string.find(message, "^(.-) is afflicted by (.-)%.?$")
  end

  spellName = normalizeSpellName(spellName)
  if self:NormalizeInterruptSpellKey(spellName) ~= "mind flay" then
    return false
  end

  local targetName = UnitName("target")
  local targetTargetName = UnitName("targettarget")
  if not targetName or not targetTargetName then
    return false
  end

  local victimUnit = "targettarget"
  if string.lower(victimName or "") == "you" then
    local playerName = UnitName("player")
    if not playerName or string.lower(targetTargetName) ~= string.lower(playerName) then
      return false
    end
    victimUnit = "player"
  elseif string.lower(targetTargetName) ~= string.lower(victimName or "") then
    return false
  end

  self:TrackHostileCastFromMessage(targetName, spellName)
  local activeCast = self.state.activeEnemyCast
  if activeCast and self:NormalizeInterruptSpellKey(activeCast.spellName) == "mind flay" then
    activeCast.source = "affliction"
    activeCast.channelVictimUnit = victimUnit
    activeCast.expiresAt = GetTime() + (self.mindFlayChannelFallbackWindow or 3.5)
    return true
  end

  return false
end

function addon:IsHostileTarget()
  if not UnitExists("target") or UnitIsDead("target") then
    return false
  end

  if UnitCanAttack then
    local canAttack = UnitCanAttack("player", "target")
    return canAttack == 1 or canAttack == true
  end

  return true
end

function addon:ObserveCurrentTargetLearning()
  if not self:IsHostileTarget() then
    return nil
  end

  local targetKey = self:GetTargetKey()
  if not targetKey or self.state.learnedTargetKey == targetKey then
    return nil
  end

  local maxHealth = UnitHealthMax("target")
  local level = UnitLevel("target") or 0
  if not self:IsValidLearningObservation(maxHealth, level) then
    return nil
  end

  local name = UnitName("target")
  local learningKey = self:NormalizeMobLearningKey(name)
  if not learningKey then
    return nil
  end

  local classification = self:GetTargetClassification()
  local creatureType = UnitCreatureType("target") or "unknown"
  local entry = self:EnsureMobLearningEntry(classification, learningKey, name, creatureType, level)
  self:UpdateMobLearningHealth(entry, maxHealth, level, name, creatureType)
  self.state.learnedTargetKey = targetKey
  return entry
end

function addon:GetMobLearningProfile()
  if not self:IsHostileTarget() then
    return nil
  end

  self:ObserveCurrentTargetLearning()

  local name = UnitName("target")
  local learningKey = self:NormalizeMobLearningKey(name)
  if not learningKey then
    return nil
  end

  local bucket = self:GetMobLearningBucket(self:GetTargetClassification())
  if not bucket then
    return nil
  end

  return bucket[learningKey]
end

function addon:GetEffectiveMobLearningProfile()
  if not self:IsHostileTarget() then
    return nil
  end

  self:ObserveCurrentTargetLearning()

  local name = UnitName("target")
  local learningKey = self:NormalizeMobLearningKey(name)
  if not learningKey then
    return nil
  end

  local classification = self:GetTargetClassification()
  local creatureType = UnitCreatureType("target") or "unknown"
  local level = UnitLevel("target") or 0
  local exactProfile = self:GetMobLearningProfile()
  local familyProfile = self:BuildFamilyLearningProfile(classification, learningKey, creatureType, level)
  return self:BuildEffectiveLearningProfile(exactProfile, familyProfile)
end

function addon:GetComboBuffDuration(name, comboPoints)
  local base = self.comboBuffBaseDurations[name]
  local perPoint = self.comboBuffPerPointDurations[name]
  if not base or not perPoint then
    return nil
  end

  local points = comboPoints or 0
  if points < 1 then
    points = 1
  elseif points > 5 then
    points = 5
  end

  return base + (points * perPoint)
end

function addon:GetCurrentGroupSize()
  local partyMembers = GetNumPartyMembers and GetNumPartyMembers() or 0
  local raidMembers = GetNumRaidMembers and GetNumRaidMembers() or 0
  return math.max(partyMembers, raidMembers)
end

function addon:GetEncounterType(classification)
  local inInstance = false
  if IsInInstance then
    local result = IsInInstance()
    inInstance = result == 1 or result == true
  end

  if inInstance then
    if self:IsDurableClassification(classification) then
      return "dungeon_elite"
    end
    return "dungeon_trash"
  end

  if self:GetCurrentGroupSize() > 0 then
    return "party_world"
  end

  return "solo_world"
end

function addon:GetLiveFightRemainingDuration(targetHealthPct)
  local fight = self.state.learningFight
  if not fight or not fight.startedAt or not fight.targetKey then
    return nil
  end

  local currentTargetKey = self:GetTargetKey()
  if currentTargetKey ~= fight.targetKey then
    return nil
  end

  local elapsed = GetTime() - fight.startedAt
  if elapsed < 2 then
    return nil
  end

  local startHealthPct = fight.startHealthPct or 100
  local currentHealth = targetHealthPct or self:GetTargetHealthPct()
  local healthRemoved = startHealthPct - currentHealth
  if healthRemoved < 12 then
    return nil
  end

  return elapsed * (currentHealth / healthRemoved)
end

function addon:GetExpectedTargetMaxHealth(profile)
  local liveMaxHealth = UnitHealthMax("target") or 0
  local learnedMaxHealth = profile and profile.avgMaxHealth or 0
  local confidence = self:GetLearningConfidence(profile)
  if not self:IsUsableLearnedHealth(learnedMaxHealth) then
    learnedMaxHealth = 0
  end

  if liveMaxHealth > 0 and learnedMaxHealth > 0 then
    local learnedWeight = 0.10 + (confidence * 0.15)
    return math.floor((liveMaxHealth * (1 - learnedWeight)) + (learnedMaxHealth * learnedWeight) + 0.5)
  end

  if liveMaxHealth > 0 then
    return liveMaxHealth
  end

  if learnedMaxHealth > 0 then
    return learnedMaxHealth
  end

  return 0
end

function addon:GetMobLearningHealthBaseline(classification)
  local bucket = self:GetMobLearningBucket(classification)
  if not bucket then
    return 0
  end

  local totalWeight = 0
  local totalHealth = 0

  for _, entry in pairs(bucket) do
    if entry and self:IsUsableLearnedHealth(entry.avgMaxHealth) then
      local weight = math.min(entry.samples or 1, 10)
      totalWeight = totalWeight + weight
      totalHealth = totalHealth + (entry.avgMaxHealth * weight)
    end
  end

  if totalWeight <= 0 then
    return 0
  end

  return totalHealth / totalWeight
end

function addon:GetMobLearningDurationBaseline(classification)
  local bucket = self:GetMobLearningBucket(classification)
  if not bucket then
    return self:IsDurableClassification(classification) and 16 or 8
  end

  local totalWeight = 0
  local totalDuration = 0

  for _, entry in pairs(bucket) do
    if entry and self:IsUsableLearnedDuration(entry.avgFightDuration) then
      local weight = math.min(entry.durationSamples or entry.samples or 1, 10)
      totalWeight = totalWeight + weight
      totalDuration = totalDuration + (entry.avgFightDuration * weight)
    end
  end

  if totalWeight <= 0 then
    return self:IsDurableClassification(classification) and 16 or 8
  end

  return totalDuration / totalWeight
end

function addon:GetExpectedFightDuration(profile, expectedMaxHealth, classification)
  local baselineDuration = self:GetMobLearningDurationBaseline(classification)
  local baselineHealth = self:GetMobLearningHealthBaseline(classification)
  local estimatedDuration = baselineDuration
  local confidence = self:GetLearningConfidence(profile)

  if baselineHealth and baselineHealth > 0 and expectedMaxHealth and expectedMaxHealth > 0 then
    estimatedDuration = baselineDuration * (expectedMaxHealth / baselineHealth)
  end

  local learnedDuration = profile and profile.avgFightDuration or 0
  if not self:IsUsableLearnedDuration(learnedDuration) then
    learnedDuration = 0
  end

  if learnedDuration > 0 then
    if estimatedDuration > 0 then
      local learnedWeight = 0.25 + (confidence * 0.55)
      return (learnedDuration * learnedWeight) + (estimatedDuration * (1 - learnedWeight))
    end
    return learnedDuration
  end

  return estimatedDuration
end

function addon:GetTargetDurabilityScore()
  if not self:IsHostileTarget() then
    return nil
  end

  local profile = self:GetEffectiveMobLearningProfile()
  local classification = self:GetTargetClassification()
  local expectedMaxHealth = self:GetExpectedTargetMaxHealth(profile)
  if expectedMaxHealth <= 0 then
    return nil, profile, expectedMaxHealth, 0
  end

  local baselineHealth = self:GetMobLearningHealthBaseline(classification)
  local score = expectedMaxHealth
  if baselineHealth and baselineHealth > 0 then
    score = expectedMaxHealth / baselineHealth
  else
    local playerMaxHealth = UnitHealthMax("player") or 0
    if playerMaxHealth > 0 then
      score = expectedMaxHealth / playerMaxHealth
    else
      score = expectedMaxHealth / 1000
    end
  end

  if self:IsDurableClassification(classification) then
    score = score + 0.35
  end

  if profile and (profile.samples or 0) >= 3 then
    score = score + 0.08
  end

  local targetHealthPct = self:GetTargetHealthPct()
  if targetHealthPct <= 30 then
    score = score - 0.3
  elseif targetHealthPct <= 50 then
    score = score - 0.12
  end

  if score < 0 then
    score = 0
  end

  return score, profile, expectedMaxHealth, baselineHealth
end

function addon:GetDurabilityTier(score, classification)
  if not score then
    local legacy = self:GetLegacyFightProfile()
    if legacy == "trash_short" then
      return "low"
    elseif legacy == "durable" then
      return "high"
    end
    return "medium"
  end

  if self:IsDurableClassification(classification) then
    if score >= 1.15 then
      return "high"
    end
    return "medium"
  end

  if score < 0.95 then
    return "low"
  end

  if score < 1.12 then
    return "medium"
  end

  return "high"
end

function addon:GetFightProfile()
  local classification = self:GetTargetClassification()
  local score, _, _ = self:GetTargetDurabilityScore()
  local tier = self:GetDurabilityTier(score, classification)
  local encounterType = self:GetEncounterType(classification)
  if encounterType == "dungeon_elite" or tier == "high" then
    return "durable"
  end
  if tier == "low" then
    return "trash_short"
  end
  return "normal"
end

function addon:HasReliablePoisonStateOnTarget()
  if not UnitExists("target") then
    return false
  end

  for index = 1, 16 do
    local texture = UnitDebuff("target", index)
    if not texture then
      break
    end

    local debuffName = self:GetDebuffTooltipName("target", index)
    if debuffName and string.find(string.lower(debuffName), "poison") then
      return true
    end
  end

  return false
end

function addon:MaybeBeginLearningFight()
  if not self:IsHostileTarget() then
    return
  end

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return
  end

  local name = UnitName("target")
  local learningKey = self:NormalizeMobLearningKey(name)
  if not learningKey then
    return
  end

  local classification = self:GetTargetClassification()
  local creatureType = UnitCreatureType("target") or "unknown"
  local level = UnitLevel("target") or 0

  if self.state.learningFight and self.state.learningFight.targetKey == targetKey then
    local fight = self.state.learningFight
    fight.lastObservedAt = GetTime()
    fight.lastHealthPct = self:GetTargetHealthPct()
    fight.lastSeenTargetKey = targetKey
    fight.maxHealth = UnitHealthMax("target") or fight.maxHealth or 0
    if level and level > 0 then
      fight.level = level
    end
    if self:GetComboPoints() > (fight.maxComboPointsSeen or 0) then
      fight.maxComboPointsSeen = self:GetComboPoints()
    end
    return
  end

  self.state.learningFight = {
    targetKey = targetKey,
    learningKey = learningKey,
    classification = classification,
    name = name,
    creatureType = creatureType,
    level = level,
    startedAt = GetTime(),
    lastObservedAt = GetTime(),
    startHealthPct = self:GetTargetHealthPct(),
    lastHealthPct = self:GetTargetHealthPct(),
    maxHealth = UnitHealthMax("target") or 0,
    maxComboPointsSeen = self:GetComboPoints() or 0,
    maxHealthLossPct = 0,
    primaryOpportunitySeen = false,
    castPrimary = false,
    castSnD = false,
    setupStarted = false,
    lastSnDRemaining = 0,
    lastPrimaryRemaining = 0,
    mode = nil,
    encounterType = self:GetEncounterType(classification),
  }
end

function addon:UpdateLearningFightFromContext(context)
  local fight = self.state.learningFight
  if not fight or not context then
    return
  end

  fight.mode = context.mode or fight.mode
  fight.encounterType = context.encounterType or fight.encounterType
  fight.lastObservedAt = GetTime()
  fight.lastHealthPct = context.targetHealthPct or fight.lastHealthPct
  fight.lastSnDRemaining = context.sndRemaining or 0
  fight.lastPrimaryRemaining = context.primaryRemaining or 0
  if context.primarySpell then
    fight.primarySpell = context.primarySpell
  end

  local healthLoss = (fight.startHealthPct or 100) - (context.targetHealthPct or 100)
  if healthLoss > (fight.maxHealthLossPct or 0) then
    fight.maxHealthLossPct = healthLoss
  end

  if context.primaryPayoff and context.primaryPayoff > 0 and context.comboPoints >= context.primaryThreshold then
    fight.primaryOpportunitySeen = true
  end
end

function addon:MarkLearningSetupCast(name)
  local fight = self.state.learningFight
  if not fight then
    return
  end

  if name == "Slice and Dice" then
    fight.castSnD = true
    fight.setupStarted = true
  elseif name == "Rupture" or name == "Expose Armor" then
    fight.castPrimary = true
    fight.primarySpell = name
    fight.setupStarted = true
  elseif name == "Shadow of Death" then
    fight.setupStarted = true
  end
end

function addon:ShouldRecordLearningFight(fight, reason)
  if not fight or not fight.startedAt then
    return false
  end

  local endedAt = reason == "combat_end" and GetTime() or (fight.lastObservedAt or GetTime())
  local duration = endedAt - fight.startedAt
  if duration < 1.5 or duration > 120 then
    return false
  end

  local meaningfulEngagement = (fight.maxHealthLossPct or 0) >= 15
    or (fight.maxComboPointsSeen or 0) >= 2
    or fight.setupStarted
  if not meaningfulEngagement then
    return false
  end

  if reason == "combat_end" then
    return true
  end

  if reason == "target_change" then
    if fight.lastHealthPct and fight.lastHealthPct <= 35 then
      return true
    end

    if duration >= 6 then
      return true
    end

    if (fight.maxComboPointsSeen or 0) >= 2 then
      return true
    end

    return (fight.maxHealthLossPct or 0) >= 20
  end

  return true
end

function addon:FinalizeLearningFight(reason)
  local fight = self.state.learningFight
  self.state.learningFight = nil

  if not fight or not fight.startedAt then
    return
  end

  if not self:ShouldRecordLearningFight(fight, reason) then
    return
  end

  local endedAt = reason == "combat_end" and GetTime() or (fight.lastObservedAt or GetTime())
  local duration = endedAt - fight.startedAt
  if duration < 1.5 or duration > 120 then
    return
  end

  local entry = self:EnsureMobLearningEntry(
    fight.classification,
    fight.learningKey,
    fight.name,
    fight.creatureType,
    fight.level
  )

  self:UpdateMobLearningFightDuration(entry, duration)
  self:UpdateMobLearningWasteMetrics(entry, fight, reason)
end

function addon:GetComboPointContext(mode)
  self:MaybeBeginLearningFight()

  local comboPoints = self:GetComboPoints()
  local classification = self:GetTargetClassification()
  local encounterType = self:GetEncounterType(classification)
  local groupSize = self:GetCurrentGroupSize()
  local score, learningProfile, expectedMaxHealth, baselineHealth = self:GetTargetDurabilityScore()
  local durabilityTier = self:GetDurabilityTier(score, classification)
  local fightProfile = self:GetFightProfile()
  local targetHealthPct = self:GetTargetHealthPct()
  local expectedFightDuration = self:GetExpectedFightDuration(learningProfile, expectedMaxHealth, classification)
  local remainingFightDuration = expectedFightDuration * (targetHealthPct / 100)
  local liveRemainingFightDuration = self:GetLiveFightRemainingDuration(targetHealthPct)
  local interruptConfidence = self:GetInterruptLearningConfidence(learningProfile)
  local poisonImmune = self.IsCurrentTargetPoisonImmune and self:IsCurrentTargetPoisonImmune() or false
  local hasWeaponPoison, weaponPoisonReason = self:HasAnyWeaponPoison()
  if liveRemainingFightDuration and liveRemainingFightDuration > 0 then
    if liveRemainingFightDuration < (remainingFightDuration * 0.75) then
      remainingFightDuration = (liveRemainingFightDuration * 0.75) + (remainingFightDuration * 0.25)
    else
      remainingFightDuration = (liveRemainingFightDuration * 0.45) + (remainingFightDuration * 0.55)
    end
  end
  local context = {
    mode = mode,
    comboPoints = comboPoints,
    classification = classification,
    encounterType = encounterType,
    groupSize = groupSize,
    durabilityScore = score,
    durabilityTier = durabilityTier,
    fightProfile = fightProfile,
    targetHealthPct = targetHealthPct,
    learningProfile = learningProfile,
    profileConfidence = self:GetLearningConfidence(learningProfile),
    wastePenalty = self:GetLearningWastePenalty(learningProfile),
    interruptConfidence = interruptConfidence,
    expectedMaxHealth = expectedMaxHealth,
    baselineHealth = baselineHealth,
    expectedFightDuration = expectedFightDuration,
    remainingFightDuration = remainingFightDuration,
    liveRemainingFightDuration = liveRemainingFightDuration,
    poisonReliable = self:HasReliablePoisonStateOnTarget(),
    poisonImmune = poisonImmune,
    hasWeaponPoison = hasWeaponPoison,
    weaponPoisonReason = weaponPoisonReason,
    physicalBuilderRotation = false,
  }
  self:DebugEvent(
    "builder_poison_check",
    tostring(context.hasWeaponPoison),
    tostring(context.poisonImmune),
    "poison",
    tostring(context.weaponPoisonReason)
  )
  context.activeEnemyCast = self:GetInterruptibleEnemyCast()
  context.interruptResponse, context.activeEnemyCast,
    context.interruptDangerScore, context.activeCastInterruptConfidence =
    self:GetInterruptResponseForActiveCast(context, context.activeEnemyCast, true)
  context.reserveKick = self:ShouldReserveKickEnergy(context)

  self.state.activeRotationMode = mode
  self:UpdateLearningFightFromContext(context)

  return context
end

function addon:GetKickEnergyCost()
  return self:GetSpellEnergyCost("Kick") or 25
end

function addon:CanUseKickInterrupt()
  if not self:HasSpell("Kick") then
    return false
  end

  if not self:IsInMeleeRange() then
    return false
  end

  if not self:IsSpellReady("Kick") then
    return false
  end

  return self:GetEnergy() >= self:GetKickEnergyCost()
end

function addon:SeedInterruptLearningFromLiveCast(liveCast)
  -- Interrupt decisions are driven by addon.kickInterruptSpells, not per-mob cast learning.
end

function addon:GetActiveCastInterruptScore(activeCast)
  if not activeCast then
    return 0, 0
  end

  if self:IsStaticKickInterruptSpell(activeCast.spellName) then
    return 1, 1
  end

  return 0, 0
end

function addon:DebugInterruptDecision(activeCast, decision, reason)
  if not activeCast then
    return
  end

  local now = GetTime()
  local age = math.max(now - (activeCast.startedAt or now), 0)
  local remaining = math.max((activeCast.expiresAt or now) - now, 0)
  local kickReady = self:HasSpell("Kick") and self:IsSpellReady("Kick")
  local melee = self:IsInMeleeRange()
  local decisionText = tostring(decision or "ignore")
  if reason then
    decisionText = decisionText .. ", reason=" .. tostring(reason)
  end

  self:DebugEvent(
    "interrupt_decision",
    tostring(activeCast.spellName or "unknown"),
    tostring(activeCast.source or "unknown"),
    string.format("%.2f", age) .. "s",
    string.format("%.2f", remaining) .. "s",
    tostring(self:GetEnergy()),
    tostring(self:GetKickEnergyCost()),
    tostring(melee),
    tostring(kickReady),
    decisionText
  )
end

function addon:GetKickUnavailableReason()
  if not self:HasSpell("Kick") then
    return "Kick not learned"
  end

  if not self:IsInMeleeRange() then
    return "outside melee range"
  end

  if not self:IsSpellReady("Kick") then
    return "Kick not ready"
  end

  if self:GetEnergy() < self:GetKickEnergyCost() then
    return "not enough energy"
  end

  return "Kick unavailable"
end

function addon:GetInterruptResponseForActiveCast(context, activeCast, castWasResolved)
  if context and context.interruptResponse then
    return context.interruptResponse, context.activeEnemyCast,
      context.interruptDangerScore or 0, context.activeCastInterruptConfidence or 0
  end

  if not castWasResolved then
    activeCast = self:GetInterruptibleEnemyCast()
  end
  if not activeCast then
    return "ignore", nil, 0, 0
  end

  local dangerScore, confidence = self:GetActiveCastInterruptScore(activeCast)
  if dangerScore <= 0 then
    self:DebugInterruptDecision(activeCast, "ignore", "spell not in interrupt list")
    return "ignore", activeCast, dangerScore, confidence
  end

  if self:CanUseKickInterrupt() then
    self:DebugInterruptDecision(activeCast, "kick")
    return "kick", activeCast, dangerScore, confidence
  end

  local kickUnavailableReason = self:GetKickUnavailableReason()
  if context
    and self:GetSetting("interruptKidneyShot") == true
    and context.comboPoints > 0
    and self:HasSpell("Kidney Shot")
    and self:IsInMeleeRange()
    and not self:IsTargetStunImmune(context)
    and self:CanCast("Kidney Shot") then
    self:DebugInterruptDecision(activeCast, "kidney", kickUnavailableReason)
    return "kidney", activeCast, dangerScore, confidence
  end

  if self:GetSetting("interruptBlind") == true
    and self:HasSpell("Blind")
    and self:CanCast("Blind")
    and dangerScore >= 0.82 then
    self:DebugInterruptDecision(activeCast, "blind", kickUnavailableReason)
    return "blind", activeCast, dangerScore, confidence
  end

  self:DebugInterruptDecision(activeCast, "ignore", kickUnavailableReason)
  return "ignore", activeCast, dangerScore, confidence
end

function addon:ShouldKickCurrentTarget(context)
  if not self:HasSpell("Kick") then
    return false
  end

  local response = self:GetInterruptResponseForActiveCast(context)
  return response == "kick"
end

function addon:ShouldReserveKickEnergy(context)
  if not context then
    return false
  end

  if self:ShouldKickCurrentTarget(context) then
    return true
  end

  if not self:IsInMeleeRange() then
    return false
  end

  local activeCast = context.activeEnemyCast
  if activeCast and self:IsStaticKickInterruptSpell(activeCast.spellName) then
    return self:HasSpell("Kick") and self:IsSpellReady("Kick")
  end

  if context.targetHealthPct <= 22 or context.remainingFightDuration <= 3 then
    return false
  end

  return false
end

function addon:ShouldConservativelyBlockKidneyShot(context)
  if not context then
    return false
  end

  if context.classification == "worldboss" then
    return true
  end

  if context.encounterType == "dungeon_elite" then
    local baseline = context.baselineHealth or 0
    local expected = context.expectedMaxHealth or 0
    if expected >= 6000 then
      return true
    end
    if baseline > 0 and expected >= (baseline * 2.5) then
      return true
    end
    if (context.expectedFightDuration or 0) >= 40 then
      return true
    end
  end

  return false
end

function addon:IsTargetStunImmune(context)
  context = context or self:GetComboPointContext(self.state.activeRotationMode or "finisher")
  local entry = context and context.learningProfile or self:GetEffectiveMobLearningProfile()
  if entry then
    local immuneSamples = entry.stunImmuneSamples or 0
    local successSamples = entry.stunSuccessSamples or 0
    if successSamples > immuneSamples and successSamples > 0 then
      return false
    end
    if immuneSamples > 0 then
      return self:GetStunImmunityConfidence(entry) >= 0.6
    end
  end

  return self:ShouldConservativelyBlockKidneyShot(context)
end

function addon:CanUseKidneyShotInterrupt(context)
  if self:GetSetting("interruptKidneyShot") ~= true then
    return false
  end

  if not context or context.comboPoints <= 0 then
    return false
  end

  if self:GetInterruptResponseForActiveCast(context) ~= "kidney" then
    return false
  end

  if not self:HasSpell("Kidney Shot") or not self:IsInMeleeRange() then
    return false
  end

  if self:CanCast("Kick") then
    return false
  end

  if self:IsTargetStunImmune(context) then
    return false
  end

  return self:CanCast("Kidney Shot")
end

function addon:CanUseBlindInterrupt(context)
  if self:GetSetting("interruptBlind") ~= true then
    return false
  end

  if self:GetInterruptResponseForActiveCast(context) ~= "blind" then
    return false
  end

  return self:HasSpell("Blind") and self:CanCast("Blind")
end

function addon:CanCastWithoutBreakingKickReserve(name, context)
  if not name or name == "Kick" or name == "Kidney Shot" or name == "Blind" then
    return true
  end

  if not self:ShouldReserveKickEnergy(context) then
    return true
  end

  local energyCost = self:GetSpellEnergyCost(name)
  if not energyCost then
    return true
  end

  return (self:GetEnergy() - energyCost) >= self:GetKickEnergyCost()
end

function addon:IsShortFightContext(context)
  if not context then
    return false
  end

  if context.remainingFightDuration and context.remainingFightDuration <= 6 then
    return true
  end

  if context.durabilityTier == "low" and (context.profileConfidence or 0) >= 0.35 then
    return true
  end

  if context.targetHealthPct and context.targetHealthPct <= 35 and (context.expectedFightDuration or 0) <= 10 then
    return true
  end

  return false
end

function addon:IsLongFightContext(context)
  if not context then
    return false
  end

  if context.remainingFightDuration and context.remainingFightDuration >= 12 then
    return true
  end

  if context.durabilityTier == "high" and (context.expectedFightDuration or 0) >= 10 then
    return true
  end

  return false
end

function addon:ShouldUseBuilderGhostlyStrike(context)
  if not RogueAutoDB.builder.useGhostlyStrike or not self:HasSpell("Ghostly Strike") then
    return false
  end

  if self:GetComboPoints() >= 5 then
    return false
  end

  local active, remaining = self:FindPlayerBuff(self.buffAliases.ghostlyStrike)
  if active and remaining >= 2 then
    return false
  end

  if context and not self:CanCastWithoutBreakingKickReserve("Ghostly Strike", context) then
    return false
  end

  if context and self:IsShortFightContext(context) then
    return false
  end

  if context and (context.profileConfidence or 0) >= 0.5 and (context.wastePenalty or 0) >= 0.25 then
    return false
  end

  return self:CanCast("Ghostly Strike")
end

function addon:ShouldBuilderUseFlourish()
  return RogueAutoDB and RogueAutoDB.builder and RogueAutoDB.builder.useFlourish == true
end

function addon:ShouldMaintainBuilderFlourish(comboPoints, context)
  if not self:ShouldBuilderUseFlourish() or not self:HasSpell("Flourish") or comboPoints <= 0 then
    return false
  end

  local remainingFightDuration = context and context.remainingFightDuration or 0
  if remainingFightDuration > 0 and remainingFightDuration < 5 then
    return false
  end

  local active, remaining = self:FindPlayerBuff("Flourish")
  if not active then
    return true
  end

  if (remaining or 0) <= (self.refreshWindow.playerBuff or 2) then
    return comboPoints >= 4 or (self:IsLongFightContext(context) and comboPoints >= 3)
  end

  return false
end

function addon:GetPlayerBuffRemaining(name)
  local active, remaining = self:FindPlayerBuff(name)
  if not active then
    return 0
  end

  return remaining or 0
end

function addon:ShouldRefreshBuilderBuff(spellName, comboPoints, context)
  if not spellName or comboPoints <= 0 or not self:HasSpell(spellName) then
    return false
  end

  if spellName == "Envenom" and self:ShouldUsePhysicalBuilderRotation(context) then
    return false
  end

  if not self:CanCast(spellName) or not self:CanCastWithoutBreakingKickReserve(spellName, context) then
    return false
  end

  local remainingFightDuration = context and context.remainingFightDuration or 0
  local active, remaining = self:FindPlayerBuff(spellName)
  remaining = remaining or 0
  local earlyRefreshWindow = self.builderBuffEarlyRefreshWindow or 4
  local emergencyRefreshWindow = self.builderBuffEmergencyRefreshWindow or 1.5
  local highPointRefreshWindow = self.builderBuffHighPointRefreshWindow or 6

  if spellName == "Slice and Dice" then
    if not active then
      return comboPoints >= 1
    end

    if remaining <= emergencyRefreshWindow then
      return comboPoints >= 1
    end

    if remaining <= earlyRefreshWindow then
      return comboPoints >= 2
    end

    if remaining <= highPointRefreshWindow then
      return comboPoints >= 4
    end

    return false
  end

  if spellName == "Envenom" then
    local minimumRemainingFightDuration = self.envenomMinimumRemainingFightDuration or 3
    if remainingFightDuration > 0 and remainingFightDuration < minimumRemainingFightDuration then
      return false
    end

    if not active then
      return comboPoints >= 1
    end

    if remaining <= emergencyRefreshWindow then
      return comboPoints >= 1
    end

    if remaining <= earlyRefreshWindow then
      return comboPoints >= 2
    end

    if remaining <= highPointRefreshWindow then
      return comboPoints >= 4
    end

    return false
  end

  if spellName == "Flourish" then
    return self:ShouldMaintainBuilderFlourish(comboPoints, context)
  end

  return false
end

function addon:GetBuilderCombatBuffUpkeepSpell(context)
  context = context or self:GetComboPointContext(self.state.activeRotationMode or "builder")
  local comboPoints = context and context.comboPoints or self:GetComboPoints()
  local shouldRefreshSnD = self:ShouldRefreshBuilderBuff("Slice and Dice", comboPoints, context)
  local shouldRefreshEnvenom = self:ShouldRefreshBuilderBuff("Envenom", comboPoints, context)

  if shouldRefreshEnvenom then
    return "Envenom"
  end

  if shouldRefreshSnD then
    return "Slice and Dice"
  end

  return nil
end

function addon:TryBuilderCombatBuffUpkeep(context)
  local spellName = self:GetBuilderCombatBuffUpkeepSpell(context)
  if not spellName then
    return false
  end

  return self:TryCast(spellName)
end

function addon:GetBuilderMainBuffState()
  local sndActive, sndRemaining = self:FindPlayerBuff("Slice and Dice")
  local envenomActive, envenomRemaining = self:FindPlayerBuff("Envenom")
  return {
    sndActive = sndActive == true,
    sndRemaining = sndRemaining or 0,
    envenomActive = envenomActive == true,
    envenomRemaining = envenomRemaining or 0,
  }
end

function addon:AreBuilderMainBuffsSafe(minimumRemaining, context)
  local state = self:GetBuilderMainBuffState()
  local safeWindow = minimumRemaining or self.builderEviscerateSafeWindow or 10
  if self:ShouldUsePhysicalBuilderRotation(context) then
    return state.sndActive and state.sndRemaining >= safeWindow
  end

  return state.sndActive
    and state.envenomActive
    and state.sndRemaining >= safeWindow
    and state.envenomRemaining >= safeWindow
end

function addon:ClearBuilderEviscerateArm()
  self.state.builderEviscerateIntent = nil
end

function addon:ClearBuilderEviscerateUrgent()
  self:ClearBuilderEviscerateArm()
end

function addon:HasBuilderEviscerateShockWindow(context)
  local minimumRemaining = self.builderEviscerateShockWindow or 7
  local state = self:GetBuilderMainBuffState()
  return state.sndActive
    and state.envenomActive
    and state.sndRemaining >= minimumRemaining
    and state.envenomRemaining >= minimumRemaining
end

function addon:GetBuilderEviscerateIntent(context)
  local intent = self.state.builderEviscerateIntent
  if not intent or not context then
    return nil
  end

  local targetKey = self:GetTargetKey()
  if not targetKey or intent.targetKey ~= targetKey or context.comboPoints < 4 then
    self:ClearBuilderEviscerateArm()
    return nil
  end

  if GetTime() > (intent.expiresAt or 0) then
    self:ClearBuilderEviscerateArm()
    return nil
  end

  if intent.requireShockWindow and not self:HasBuilderEviscerateShockWindow(context) then
    self:ClearBuilderEviscerateArm()
    return nil
  end

  return intent
end

function addon:ArmBuilderEviscerate(context, requireShockWindow)
  if not context or context.comboPoints ~= 4 or not self:HasSpell("Eviscerate") then
    return false
  end

  if requireShockWindow then
    if not self:HasBuilderEviscerateShockWindow(context) then
      return false
    end
  elseif not self:AreBuilderMainBuffsSafe(nil, context) then
    return false
  end

  if self:ShouldMaintainBuilderFlourish(context.comboPoints, context) then
    return false
  end

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return false
  end

  self.state.builderEviscerateIntent = {
    targetKey = targetKey,
    armedAt = GetTime(),
    expiresAt = GetTime() + (self.builderEviscerateArmTimeout or 5),
    shockWindow = requireShockWindow == true,
    requireShockWindow = requireShockWindow == true,
  }
  return true
end

function addon:CanUseBuilderEviscerate(context, allowArmed, allowUnsafe, ignoreKickReserve)
  local intent = allowArmed and self:GetBuilderEviscerateIntent(context)
  local armed = intent ~= nil
  local minimumComboPoints = armed and 4 or 5
  if not context or context.comboPoints < minimumComboPoints or not self:HasSpell("Eviscerate") then
    return false, "invalid context, combo points, or missing Eviscerate"
  end

  if not armed and not allowUnsafe and not self:AreBuilderMainBuffsSafe(nil, context) then
    return false, "main buffs unsafe for unarmed Eviscerate"
  end

  local inRange = self:IsSpellInRangeSafe("Eviscerate", "target")
  if inRange == 0 then
    return false, "Eviscerate out of range"
  end

  local energyCost = self:GetSpellEnergyCost("Eviscerate")
  local currentEnergy = self:GetEnergy()
  if energyCost and currentEnergy < energyCost then
    return false, "Eviscerate blocked by energy: have " .. currentEnergy .. ", need " .. energyCost
  end

  if not self:CanCast("Eviscerate") then
    return false, "Eviscerate not ready"
  end

  local shouldIgnoreKickReserve = ignoreKickReserve == true or armed == true

  if not shouldIgnoreKickReserve and not self:CanCastWithoutBreakingKickReserve("Eviscerate", context) then
    return false, "Eviscerate blocked by kick reserve"
  end

  return true
end

function addon:TryBuilderEviscerate(context, allowArmed, allowUnsafe, ignoreKickReserve)
  local canUse, reason = self:CanUseBuilderEviscerate(context, allowArmed, allowUnsafe, ignoreKickReserve)
  if not canUse then
    if allowUnsafe and not allowArmed then
      self:TraceEvent("eviscerate_blocked_urgent", tostring(reason))
    elseif allowArmed then
      self:TraceEvent("eviscerate_blocked_armed", tostring(reason))
    else
      self:TraceEvent("eviscerate_blocked_unarmed", tostring(reason))
    end
    return false
  end

  local success = self:TryCast("Eviscerate")
  if success then
    self:ClearBuilderEviscerateArm()
    self:ClearBuilderEviscerateUrgent()
    return success
  end

  self:TraceEvent("eviscerate_cast_failed")
  return false
end

function addon:TryBuilderFlourishUpkeep(context)
  context = context or self:GetComboPointContext(self.state.activeRotationMode or "builder")

  local comboPoints = context and context.comboPoints or self:GetComboPoints()
  if comboPoints <= 0 then
    return false
  end

  if not self:ShouldRefreshBuilderBuff("Flourish", comboPoints, context) then
    return false
  end

  return self:TryCast("Flourish")
end

function addon:IsStealthed()
  local icon, name, active = GetShapeshiftFormInfo(1)
  if active == 1 then
    return true
  end

  local isActive = self:FindPlayerBuff(self.buffAliases.stealth)
  return isActive
end

function addon:IsBehindBlocked(targetKey)
  if GetTime() >= (self.state.behindBlockedUntil or 0) then
    self.state.behindBlockedTargetKey = nil
    return false
  end

  targetKey = targetKey or self:GetTargetKey()
  if self.state.behindBlockedTargetKey and targetKey and self.state.behindBlockedTargetKey ~= targetKey then
    return false
  end

  return true
end

function addon:MarkBehindBlocked(targetKey, duration)
  self.state.behindBlockedTargetKey = targetKey or self:GetTargetKey()
  self.state.behindBlockedUntil = GetTime() + (duration or 1.5)
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

function addon:IsDaggerEquipped()
  local mainHand = GetInventoryItemLink("player", 16)
  if not mainHand or not GetItemInfo then
    return false
  end

  local _, _, _, _, _, _, subType = GetItemInfo(mainHand)
  if not subType then
    return false
  end

  local normalizedSubType = string.lower(subType)
  return string.find(normalizedSubType, "dagger") ~= nil
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
  local normalizedExpectedName = normalizeSpellName(name)
  local normalizedExpectedTexture = normalizeTextureName(self:GetSelfBuffTimelineIcon(name))
  local trackedRemaining = self:GetTrackedPlayerBuffRemaining(name)
  local pending = self:GetPendingPlayerBuffInfo(name)

  for index = 0, 31 do
    local buffIndex = GetPlayerBuff(index, "HELPFUL")
    if buffIndex < 0 then
      break
    end

    local texture = GetPlayerBuffTexture and GetPlayerBuffTexture(buffIndex) or nil
    local normalizedTexture = normalizeTextureName(texture)
    if normalizedExpectedTexture and normalizedTexture and normalizedTexture == normalizedExpectedTexture then
      local remaining = GetPlayerBuffTimeLeft(buffIndex) or 0
      if remaining > 0 then
        self:ConfirmTrackedPlayerBuff(name, remaining)
      elseif pending and pending.duration and pending.duration > 0 then
        self:ConfirmTrackedPlayerBuff(name, pending.duration)
        remaining = pending.duration
      end
      if remaining <= 0 and trackedRemaining > 0 then
        remaining = trackedRemaining
      end
      return true, remaining
    end

    self.tooltip:ClearLines()
    self.tooltip:SetPlayerBuff(buffIndex)
    local text = RogueAutoTooltipTextLeft1 and RogueAutoTooltipTextLeft1:GetText()
    if normalizeSpellName(text) == normalizedExpectedName then
      local remaining = GetPlayerBuffTimeLeft(buffIndex) or 0
      if remaining > 0 then
        self:ConfirmTrackedPlayerBuff(name, remaining)
      elseif pending and pending.duration and pending.duration > 0 then
        self:ConfirmTrackedPlayerBuff(name, pending.duration)
        remaining = pending.duration
      end
      if remaining <= 0 and trackedRemaining > 0 then
        remaining = trackedRemaining
      end
      return true, remaining
    end
  end

  if trackedRemaining > 0 then
    return true, trackedRemaining
  end

  if pending and pending.expiresAt and pending.expiresAt > GetTime() then
    local pendingRemaining = pending.expiresAt - GetTime()
    if pendingRemaining > 0 then
      return true, math.min(pendingRemaining, 1.5)
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

function addon:HasTargetArmorReductionDebuff()
  if not UnitExists("target") then
    return false
  end

  if self:FindUnitDebuffByName("target", "Sunder Armor") then
    return true, "Sunder Armor"
  end

  if self:FindUnitDebuffByName("target", "Expose Armor") then
    return true, "Expose Armor"
  end

  return false, nil
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

function addon:GetStableUnitIdentity(unit)
  if not unit or not UnitExists(unit) then
    return nil
  end

  if UnitGUID then
    local guid = UnitGUID(unit)
    if type(guid) == "string" and guid ~= "" then
      return guid
    end
  end

  local existsValue = UnitExists(unit)
  if type(existsValue) == "string" and existsValue ~= "" and existsValue ~= "1" then
    return existsValue
  end

  if type(existsValue) == "number" and existsValue ~= 1 then
    return tostring(existsValue)
  end

  return nil
end

function addon:EnsureCurrentTargetKey()
  if not UnitExists("target") then
    self.state.currentTargetKey = nil
    return nil
  end

  if self.state.currentTargetKey then
    return self.state.currentTargetKey
  end

  local stableIdentity = self:GetStableUnitIdentity("target")
  if stableIdentity then
    self.state.currentTargetKey = stableIdentity
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

function addon:PruneSuppressedTargetSpells()
  local now = GetTime()

  for targetKey, spells in pairs(self.state.suppressedTargetSpells) do
    local hasActiveSuppression = false

    for spellName, expiresAt in pairs(spells) do
      if not expiresAt or expiresAt <= now then
        spells[spellName] = nil
      else
        hasActiveSuppression = true
      end
    end

    if not hasActiveSuppression then
      self.state.suppressedTargetSpells[targetKey] = nil
    end
  end
end

function addon:SuppressTargetSpell(spellName, duration, targetKey)
  targetKey = targetKey or self:GetTargetKey()
  if not targetKey or not spellName then
    return
  end

  self.state.suppressedTargetSpells[targetKey] = self.state.suppressedTargetSpells[targetKey] or {}
  self.state.suppressedTargetSpells[targetKey][spellName] = GetTime() + (duration or 3)
end

function addon:IsTargetSpellSuppressed(spellName, targetKey)
  self:PruneSuppressedTargetSpells()

  targetKey = targetKey or self:GetTargetKey()
  if not targetKey or not spellName then
    return false
  end

  local spells = self.state.suppressedTargetSpells[targetKey]
  local expiresAt = spells and spells[spellName]
  return expiresAt and expiresAt > GetTime()
end

function addon:MarkTargetPickPocketed(targetKey)
  targetKey = targetKey or self:GetTargetKey()
  if not targetKey then
    return
  end

  -- Suppress repeated Pick Pocket attempts on the same target until the
  -- target pocket timer expires.
  self.state.pickPocketedTargets[targetKey] = GetTime() + (self.pickPocketResetDuration or 600)
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

function addon:GetPickPocketResetTimerForCurrentTarget()
  self:PrunePickPocketTargets()

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return nil
  end

  local expiry = self.state.pickPocketedTargets[targetKey]
  if not expiry then
    return 0
  end

  local remaining = expiry - GetTime()
  if remaining <= 0 then
    return 0
  end

  return remaining
end

function addon:BeginPickPocketAttempt()
  local targetKey = self:GetTargetKey()
  if not targetKey then
    return
  end

  self.state.pickPocketMoneyTracking = {
    before = GetMoney and GetMoney() or 0,
    expires = GetTime() + 5,
  }

  local info = self.state.pickPocketAttempts[targetKey] or { count = 0, expires = 0 }
  info.count = info.count + 1
  info.expires = GetTime() + 15
  self.state.pickPocketAttempts[targetKey] = info

  self.state.pendingPickPocketTarget = targetKey
  self.state.pendingPickPocketExpires = GetTime() + 2
  self.state.pickPocketActionBlockedUntil = GetTime() + (self.pickPocketActionDelay or 0.35)
end

function addon:IsPickPocketActionBlocked()
  return GetTime() < (self.state.pickPocketActionBlockedUntil or 0)
end

function addon:ClearPickPocketActionBlockOnResist(message)
  if not message or not string.find(string.lower(message), "resist") then
    return
  end

  local lastAttempt = self.state.lastSpellAttempt
  if lastAttempt
    and lastAttempt.name == "Pick Pocket"
    and lastAttempt.at
    and GetTime() - lastAttempt.at <= 1 then
    self.state.pickPocketActionBlockedUntil = 0
  end
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
  self.state.pickPocketMoneyTracking = nil
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

  if self:IsTargetSpellSuppressed("Pick Pocket") then
    return false
  end

  local targetName = UnitName("target")
  local creatureType = UnitCreatureType("target")
  local isWhitelisted = targetName and self.pickPocketTargetWhitelist and self.pickPocketTargetWhitelist[targetName]
  local isCreatureTypeWhitelisted = creatureType == "Undead"

  if creatureType ~= "Humanoid" and not isWhitelisted and not isCreatureTypeWhitelisted then
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

function addon:GetDebuffTrackingPolicy(name)
  return self.debuffTrackingPolicy[name] or "sharedPresence"
end

function addon:GetTrackedDebuffRecord(name, targetKey)
  targetKey = targetKey or self:GetTargetKey()
  if not targetKey then
    return nil
  end

  local targetDebuffs = self.state.trackedDebuffs[targetKey]
  return targetDebuffs and targetDebuffs[name] or nil
end

function addon:GetPendingDebuffRecord(name, targetKey)
  targetKey = targetKey or self:GetTargetKey()
  if not targetKey then
    return nil
  end

  local targetDebuffs = self.state.pendingDebuffs[targetKey]
  return targetDebuffs and targetDebuffs[name] or nil
end

function addon:TrackTargetDebuff(name, duration, targetKey, metadata)
  self:PruneTrackedDebuffs()

  targetKey = targetKey or self:GetTargetKey()
  if not targetKey or not duration or duration <= 0 then
    return
  end

  self.state.trackedDebuffs[targetKey] = self.state.trackedDebuffs[targetKey] or {}
  self.state.trackedDebuffs[targetKey][name] = {
    expiresAt = GetTime() + duration,
    confirmedAt = GetTime(),
    source = metadata and metadata.source or "local",
    spellId = metadata and metadata.spellId or nil,
  }
end

function addon:QueuePendingTargetDebuff(name, duration, targetKey, metadata)
  targetKey = targetKey or self:GetTargetKey()
  if not targetKey or not duration or duration <= 0 then
    return
  end

  self.state.pendingDebuffs[targetKey] = self.state.pendingDebuffs[targetKey] or {}
  self.state.pendingDebuffs[targetKey][name] = {
    duration = duration,
    expires = GetTime() + 2.5,
    queuedAt = GetTime(),
    source = metadata and metadata.source or "pending",
    spellId = metadata and metadata.spellId or nil,
  }
end

function addon:PrunePendingTargetDebuffs()
  local now = GetTime()

  for targetKey, targetDebuffs in pairs(self.state.pendingDebuffs) do
    local hasPendingDebuff = false

    for name, info in pairs(targetDebuffs) do
      if not info or not info.expires or info.expires <= now then
        targetDebuffs[name] = nil
      else
        hasPendingDebuff = true
      end
    end

    if not hasPendingDebuff then
      self.state.pendingDebuffs[targetKey] = nil
    end
  end
end

function addon:ConsumePendingTargetDebuffDuration(name)
  self:PrunePendingTargetDebuffs()

  local targetKey = self:GetTargetKey()
  if not targetKey then
    return 0
  end

  local targetDebuffs = self.state.pendingDebuffs[targetKey]
  if not targetDebuffs then
    return 0
  end

  local info = targetDebuffs[name]
  if not info or not info.duration then
    return 0
  end

  targetDebuffs[name] = nil
  if not next(targetDebuffs) then
    self.state.pendingDebuffs[targetKey] = nil
  end

  return info.duration
end

function addon:PruneTrackedDebuffs()
  local now = GetTime()

  for targetKey, targetDebuffs in pairs(self.state.trackedDebuffs) do
    local hasActiveDebuff = false

    for name, record in pairs(targetDebuffs) do
      local expiresAt = record and record.expiresAt or nil
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

function addon:SeedObservedTargetDebuff(name, targetKey, spellId)
  local fallbackDuration = self.observedDebuffDurations[name]
  if not fallbackDuration then
    return 0
  end

  self:TrackTargetDebuff(name, fallbackDuration, targetKey, {
    source = "observed",
    spellId = spellId,
  })
  return fallbackDuration
end

function addon:GetComboDebuffDuration(name, comboPoints)
  local base = self.dotBaseDurations[name]
  local perPoint = self.dotPerPointDurations[name]
  if not base or not perPoint then
    return nil
  end

  return base + (comboPoints * perPoint)
end

function addon:GetTrackedDebuffRemaining(name)
  self:PruneTrackedDebuffs()

  local record = self:GetTrackedDebuffRecord(name)
  if not record or not record.expiresAt then
    return 0
  end

  local remaining = record.expiresAt - GetTime()
  if remaining < 0 then
    return 0
  end

  return remaining
end

function addon:GetPendingDebuffRemaining(name, targetKey)
  self:PrunePendingTargetDebuffs()

  local record = self:GetPendingDebuffRecord(name, targetKey)
  if not record or not record.duration then
    return 0
  end

  return record.duration
end

function addon:ClearPendingTargetDebuff(name, targetKey)
  targetKey = targetKey or self:GetTargetKey()
  if not targetKey then
    return
  end

  local targetDebuffs = self.state.pendingDebuffs[targetKey]
  if not targetDebuffs then
    return
  end

  targetDebuffs[name] = nil
  if not next(targetDebuffs) then
    self.state.pendingDebuffs[targetKey] = nil
  end
end

function addon:ConfirmPendingTargetDebuff(name, targetKey, spellId)
  local pending = self:GetPendingDebuffRecord(name, targetKey)
  if not pending or not pending.duration or pending.duration <= 0 then
    return 0
  end

  self:TrackTargetDebuff(name, pending.duration, targetKey, {
    source = "pendingConfirm",
    spellId = spellId or pending.spellId,
  })
  self:ClearPendingTargetDebuff(name, targetKey)
  return pending.duration
end

function addon:GetDebuffTooltipName(unit, index)
  if not self.tooltip or not self.tooltip.SetUnitDebuff then
    return nil
  end

  self.tooltip:ClearLines()
  self.tooltip:SetUnitDebuff(unit, index)
  return RogueAutoTooltipTextLeft1 and RogueAutoTooltipTextLeft1:GetText() or nil
end

function addon:ScanTargetDebuff(name)
  if not UnitExists("target") then
    return nil
  end

  local expectedTexture = self.targetDebuffTextures[name]
  local knownSpellId = self.targetDebuffSpellIds[name]
  local textureMatch = nil

  for index = 1, 16 do
    local texture, applications, debuffType, duration, expirationTime, caster, isStealable, shouldConsolidate, spellId = UnitDebuff("target", index)
    if not texture then
      break
    end

    local tooltipName = self:GetDebuffTooltipName("target", index)
    if tooltipName == name then
      if spellId then
        self.targetDebuffSpellIds[name] = spellId
      end
      return {
        found = true,
        spellId = spellId,
        texture = texture,
        matchType = "name",
      }
    end

    if knownSpellId and spellId and knownSpellId == spellId then
      return {
        found = true,
        spellId = spellId,
        texture = texture,
        matchType = "spellId",
      }
    end

    if expectedTexture then
      local normalized = string.lower(string.gsub(texture, ".*\\", ""))
      if normalized == expectedTexture and not textureMatch then
        textureMatch = {
          found = true,
          spellId = spellId,
          texture = texture,
          matchType = "texture",
        }
      end
    end
  end

  return textureMatch
end

function addon:IsTargetDebuffActive(name)
  self:PrunePendingTargetDebuffs()

  if not UnitExists("target") then
    return false, 0
  end

  if name == "Expose Armor" then
    local armorReduced, sourceName = self:HasTargetArmorReductionDebuff()
    if armorReduced then
      if sourceName == "Sunder Armor" then
        return true, self.refreshWindow.targetDebuff + 1
      end
    end
  end

  local targetKey = self:GetTargetKey()
  local policy = self:GetDebuffTrackingPolicy(name)
  local auraMatch = self:ScanTargetDebuff(name)
  local trackedRemaining = self:GetTrackedDebuffRemaining(name)
  local pendingRemaining = self:GetPendingDebuffRemaining(name, targetKey)

  if auraMatch and auraMatch.matchType ~= "texture" then
    if trackedRemaining > 0 then
      return true, trackedRemaining
    end

    local confirmedDuration = self:ConfirmPendingTargetDebuff(name, targetKey, auraMatch.spellId)
    if confirmedDuration > 0 then
      return true, confirmedDuration
    end

    if policy == "sharedPresence" then
      local observedDuration = self:SeedObservedTargetDebuff(name, targetKey, auraMatch.spellId)
      if observedDuration > 0 then
        return true, observedDuration
      end
      return true, self.refreshWindow.targetDebuff + 1
    end

    return false, 0
  end

  if trackedRemaining > 0 then
    return true, trackedRemaining
  end

  if pendingRemaining > 0 then
    return true, pendingRemaining
  end

  if auraMatch and auraMatch.matchType == "texture" then
    local confirmedDuration = self:ConfirmPendingTargetDebuff(name, targetKey, auraMatch.spellId)
    if confirmedDuration > 0 then
      return true, confirmedDuration
    end

    if policy == "sharedPresence" then
      local observedDuration = self:SeedObservedTargetDebuff(name, targetKey, auraMatch.spellId)
      if observedDuration > 0 then
        return true, observedDuration
      end
      return true, self.refreshWindow.targetDebuff + 1
    end
  end

  return false, 0
end

function addon:TrackComboDebuff(name, comboPoints)
  local duration = self:GetComboDebuffDuration(name, comboPoints)
  if not duration then
    return
  end

  self:TrackTargetDebuff(name, duration, nil, {
    source = "combo",
  })
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

  if hasTarget and self:IsHostileTarget() then
    return true
  end

  if not RogueAutoDB.targeting.nearestFallback then
    return false
  end

  if hasTarget then
    ClearTarget()
  end

  TargetNearestEnemy()
  return self:IsHostileTarget()
end

function addon:StartAttack()
  if not RogueAutoDB.targeting.autoStartAttack then
    return
  end

  if self:IsStealthed() then
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

function addon:DoesTargetAppearToBeOnPlayer()
  if self:IsTargetTargetingPlayer() then
    return true
  end

  if not UnitExists("target") then
    return false
  end

  local playerName = UnitName("player")
  local targetTargetName = UnitName("targettarget")
  if playerName and targetTargetName and string.lower(playerName) == string.lower(targetTargetName) then
    return true
  end

  return false
end

function addon:ShouldUseBuilderFeint()
  if not RogueAutoDB or not RogueAutoDB.builder or RogueAutoDB.builder.useFeint == false then
    return false
  end

  if self:GetCurrentGroupSize() <= 0 then
    return false
  end

  if not self:DoesTargetAppearToBeOnPlayer() then
    return false
  end

  return self:CanCast("Feint")
end

function addon:TryBuilderFeint()
  if not self:ShouldUseBuilderFeint() then
    return false
  end

  return self:TryCast("Feint")
end

function addon:CanCast(name)
  if not self:HasSpell(name) then
    return false
  end

  if name == "Surprise Attack" and not self:CanUseSurpriseAttack() then
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

  local energyCost = self:GetSpellEnergyCost(name)
  if energyCost and self:GetEnergy() < energyCost then
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

  local comboPoints = self:GetComboPoints()
  self:DebugEvent("casting_spell", tostring(name))
  self.state.lastSpellAttempt = {
    name = name,
    targetKey = self:GetTargetKey(),
    targetName = UnitName("target"),
    at = GetTime(),
  }
  if name == "Pick Pocket" then
    self:BeginPickPocketAttempt()
  end

  CastSpellByName(name)

  if name == "Kick" then
    self.state.activeEnemyCast = nil
  elseif name == "Kidney Shot" then
    self:BeginPendingKidneyShotCheck()
  elseif name == "Slice and Dice" or name == "Envenom" or name == "Flourish" then
    local duration = self:GetComboBuffDuration(name, comboPoints)
    self:QueuePendingPlayerBuff(name, duration)
  end

  self:MarkLearningSetupCast(name)

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
      self:QueuePendingTargetDebuff(name, self:GetComboDebuffDuration(name, comboPoints), nil, {
        source = "comboPending",
      })
    elseif name == "Expose Armor" then
      self:QueuePendingTargetDebuff(name, 30, nil, {
        source = "sharedPending",
      })
    elseif name == "Shadow of Death" then
      self:QueuePendingTargetDebuff(name, 12, nil, {
        source = "strictPending",
      })
    end
    return true
  end

  return false
end

function addon:GetPreferredBuilder(context)
  local mode = RogueAutoDB.builder.mode
  context = context or self:GetComboPointContext(self.state.activeRotationMode or "builder")
  local modeHint = context and context.mode or self.state.activeRotationMode or "builder"
  local candidateSpells = {
    "Backstab",
    "Surprise Attack",
    "Noxious Assault",
    "Hemorrhage",
    "Sinister Strike",
  }

  local function buildReasons(bestSpell, preferredSpell)
    local reasons = {}
    if context and context.reserveKick then
      addHeuristicReason(reasons, "Holding enough energy to answer a cast")
    end
    if context and self:IsShortFightContext(context) then
      addHeuristicReason(reasons, "Known short fight favors front-loaded damage")
    elseif context and self:IsLongFightContext(context) then
      addHeuristicReason(reasons, "Known durable fight favors sustained builder value")
    end
    if preferredSpell and bestSpell == preferredSpell then
      addHeuristicReason(reasons, "Selected primary builder is legal")
    elseif preferredSpell then
      addHeuristicReason(reasons, "Selected primary builder was unavailable or weak here")
    end
    if bestSpell == "Backstab" then
      addHeuristicReason(reasons, "Behind target with dagger")
      addHeuristicReason(reasons, "Backstab is the strongest front-loaded builder")
    elseif bestSpell == "Surprise Attack" then
      addHeuristicReason(reasons, "Target dodge window enables Surprise Attack")
      addHeuristicReason(reasons, "Surprise Attack beats Sinister Strike when ready")
    elseif bestSpell == "Noxious Assault" then
      addHeuristicReason(reasons, "Poison-synergy builder wins")
    elseif bestSpell == "Hemorrhage" then
      addHeuristicReason(reasons, "Hemorrhage is the best sustained fallback")
    elseif bestSpell == "Sinister Strike" then
      addHeuristicReason(reasons, "Reliable front-facing fallback")
      if context and context.durabilityTier == "low" then
        addHeuristicReason(reasons, "Low-durability target favors immediate damage")
      end
    end

    return reasons
  end

  if self:ShouldUsePhysicalBuilderRotation(context) then
    local sinisterScore = self:GetBuilderSpellScore("Sinister Strike", context, modeHint)
    if sinisterScore then
      return "Sinister Strike", {
        reasons = buildReasons("Sinister Strike", "Sinister Strike"),
      }
    end

    local bestPhysicalSpell = nil
    local bestPhysicalScore = nil
    local physicalFallbacks = {
      "Backstab",
      "Surprise Attack",
      "Hemorrhage",
    }
    for _, spellName in ipairs(physicalFallbacks) do
      local score = self:GetBuilderSpellScore(spellName, context, modeHint)
      if score and (not bestPhysicalScore or score > bestPhysicalScore) then
        bestPhysicalScore = score
        bestPhysicalSpell = spellName
      end
    end

    if bestPhysicalSpell then
      return bestPhysicalSpell, {
        reasons = buildReasons(bestPhysicalSpell, "Sinister Strike"),
      }
    end

    return nil
  end

  if mode == "auto" then
    local bestSpell = nil
    local bestScore = nil

    for _, spellName in ipairs(candidateSpells) do
      local score = self:GetBuilderSpellScore(spellName, context, modeHint)
      if score and (not bestScore or score > bestScore) then
        bestScore = score
        bestSpell = spellName
      end
    end

    if bestSpell then
      return bestSpell, {
        reasons = buildReasons(bestSpell, nil),
      }
    end

    return nil
  end

  local preferredSpell = self.builderModes[mode]
  local bestSpell = nil
  local bestScore = nil

  if preferredSpell then
    local preferredScore = self:GetBuilderSpellScore(preferredSpell, context, modeHint)
    if preferredScore then
      bestSpell = preferredSpell
      bestScore = preferredScore
    end
  end

  if not bestSpell then
    for _, spellName in ipairs(candidateSpells) do
      if spellName ~= preferredSpell then
        local score = self:GetBuilderSpellScore(spellName, context, modeHint)
        if score and (not bestScore or score > bestScore) then
          bestScore = score
          bestSpell = spellName
        end
      end
    end
  end

  if bestSpell == "Sinister Strike" and self:GetBuilderSpellScore("Surprise Attack", context, modeHint) then
    bestSpell = "Surprise Attack"
  end

  if bestSpell then
    return bestSpell, {
      reasons = buildReasons(bestSpell, preferredSpell),
    }
  end

  return nil
end

function addon:GetBuilderSpellScore(spellName, context, modeHint)
  if spellName == "Noxious Assault" and self:ShouldUsePhysicalBuilderRotation(context) then
    return nil
  end

  if not self:CanCast(spellName) then
    return nil
  end

  if not self:CanCastWithoutBreakingKickReserve(spellName, context) then
    return nil
  end

  local inRange = self:IsSpellInRangeSafe(spellName, "target")
  if inRange == 0 then
    return nil
  end

  local shortFight = self:IsShortFightContext(context)
  local longFight = self:IsLongFightContext(context)
  local reliableProfile = context and (context.profileConfidence or 0) >= 0.55
  local wastePenalty = context and (context.wastePenalty or 0) or 0

  if spellName == "Surprise Attack" then
    if not self:CanUseSurpriseAttack() then
      return nil
    end

    local score = 4.45
    if modeHint == "direct" then
      score = score + 0.45
    elseif modeHint == "builder" then
      score = score + 0.15
    end
    if shortFight then
      score = score + 0.35
    end
    if reliableProfile and wastePenalty >= 0.2 then
      score = score + 0.1
    end
    return score
  end

  if spellName == "Backstab" then
    if not self:IsDaggerEquipped() or not self:CanAttemptBehindAction() then
      return nil
    end

    local score = 4.8
    if modeHint == "direct" then
      score = score + 0.5
    elseif modeHint == "bleed" then
      score = score + 0.15
    elseif modeHint == "builder" then
      score = score + 0.2
    end
    if shortFight then
      score = score + 0.35
    end
    if context and context.encounterType == "dungeon_elite" then
      score = score + 0.3
    end
    if reliableProfile and wastePenalty >= 0.2 then
      score = score + 0.15
    end
    return score
  end

  if spellName == "Noxious Assault" then
    local score = 3.45
    if modeHint == "direct" then
      score = score + 0.45
    end
    if context and context.poisonReliable then
      score = score + 0.45
    end
    if context and context.durabilityTier == "high" then
      score = score + 0.25
    end
    if longFight then
      score = score + 0.15
    end
    if shortFight then
      score = score - 0.35
    end
    if reliableProfile and wastePenalty >= 0.2 then
      score = score - 0.15
    end
    return score
  end

  if spellName == "Hemorrhage" then
    local score = 3.2
    if modeHint == "bleed" then
      score = score + 0.6
    end
    if context and context.durabilityTier == "high" then
      score = score + 0.2
    end
    if longFight then
      score = score + 0.15
    end
    if shortFight then
      score = score - 0.25
    end
    if reliableProfile and wastePenalty >= 0.2 then
      score = score - 0.1
    end
    return score
  end

  if spellName == "Sinister Strike" then
    local score = 3.3
    if context and context.durabilityTier == "low" then
      score = score + 0.15
    end
    if shortFight then
      score = score + 0.35
    end
    if context and context.reserveKick then
      score = score + 0.1
    end
    if reliableProfile and wastePenalty >= 0.2 then
      score = score + 0.1
    end
    return score
  end

  return nil
end

function addon:ResolveOpenerHint(hint)
  if hint == nil then
    return nil
  end
  if type(hint) ~= "string" then
    hint = tostring(hint)
  end

  local normalized = string.lower(trim(hint))
  if normalized == "pick pocket" or normalized == "pickpocket" then
    return "Pick Pocket"
  elseif normalized == "garrote" then
    return "Garrote"
  elseif normalized == "ambush" then
    return "Ambush"
  elseif normalized == "cheap shot" or normalized == "cheapshot" then
    return "Cheap Shot"
  end

  return nil
end

function addon:CanAttemptSpecificOpener(name)
  if not name or not self:IsStealthed() then
    return false
  end

  if name == "Pick Pocket" then
    return self:CanAttemptPickPocket()
  end

  if not self:HasSpell(name) then
    return false
  end

  if name == "Garrote" then
    return self:CanAttemptBehindAction()
  end

  if name == "Ambush" then
    return self:IsDaggerEquipped() and self:CanAttemptBehindAction()
  end

  if name == "Cheap Shot" then
    return true
  end

  return false
end

function addon:TryOpenerHint(hint)
  local opener = self:ResolveOpenerHint(hint)
  if not opener then
    return false
  end

  if not self:IsStealthed() then
    return false
  end

  if opener == "Pick Pocket" then
    if self:CanAttemptSpecificOpener(opener) then
      self.state.activeOpenerHint = opener
      return self:TryCast(opener)
    end
    return false
  end

  if RogueAutoDB.stealth.pickPocketHumanoids and self:CanAttemptPickPocket() then
    self.state.activeOpenerHint = opener
    if self:TryCast("Pick Pocket") then
      return true
    end
  end

  if not self:CanAttemptSpecificOpener(opener) then
    return false
  end

  self.state.activeOpenerHint = opener
  return self:TryCast(opener)
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

function addon:TryRotationKick(context)
  if not self:ShouldKickCurrentTarget(context) then
    return false
  end

  if self:TryCast("Kick") then
    self.state.activeEnemyCast = nil
    return true
  end

  return false
end

function addon:TryEmergencyKidneyInterrupt(context)
  if not self:CanUseKidneyShotInterrupt(context) then
    return false
  end

  return self:TryCast("Kidney Shot")
end

function addon:TryEmergencyBlindInterrupt(context)
  if not self:CanUseBlindInterrupt(context) then
    return false
  end

  return self:TryCast("Blind")
end

function addon:TryPreferredBuilder(context)
  context = context or self:GetComboPointContext(self.state.activeRotationMode or "builder")
  local mode = RogueAutoDB.builder.mode

  if mode == "auto"
    and not self:ShouldUsePhysicalBuilderRotation(context)
    and self:ShouldUseBuilderGhostlyStrike(context) then
    if self:TryCast("Ghostly Strike") then
      return true
    end
  end

  local builder = self:GetPreferredBuilder(context)
  if builder then
    return self:TryCast(builder)
  end

  return false
end

function addon:OnVariablesLoaded()
  self:InitDB()
  self.state.variablesLoaded = true
end

function addon:OnPlayerLogin()
  if self.state.playerLoginHandled then
    return
  end
  self.state.playerLoginHandled = true
  if not self.state.variablesLoaded then
    self:OnVariablesLoaded()
  end
  self:InstallUiErrorFilter()
  self:RefreshKnownSpells()
  self:InitializePickPocketGoldStats()
  self:UpdateComboPointFrame(true)
  self:UpdateCooldownListFrame(true)
  self:UpdateSelfBuffTimelineFrame(true)
  self:UpdateWeaponPoisonFrame(true)
  self:UpdateWeaponPoisonWarningFrame(true)
  self:UpdatePickPocketGoldStatsFrame(true)
  self:DebugEvent("loaded_version", tostring(self.version))
end

function addon:OnCombatStarted()
  self:ClearBuilderEviscerateArm()
  self:ClearBuilderEviscerateUrgent()
  if not self:IsCombatSessionActive() then
    self:StartCombatSession()
  end

  self.state.lastEnergy = self:GetEnergy()
  self:UpdateComboPointFrame(true)
  self:MaybeBeginLearningFight()
end

function addon:OnCombatEnded()
  if self.OnRoleplayCombatEnded then
    self:OnRoleplayCombatEnded()
  end
  self.state.activeEnemyCast = nil
  self.state.suppressedEnemyCastBar = nil
  self:ClearPendingKidneyShotCheck()
  self:ClearBuilderEviscerateArm()
  self:ClearBuilderEviscerateUrgent()
  self:FinalizeLearningFight("combat_end")
  self:FinishCombatSession()
  self:UpdateComboPointFrame(true)
end

function addon:OnSpellbookChanged()
  self:RefreshKnownSpells()
end

function addon:OnEnergyChanged(unit)
  if unit ~= "player" then
    return
  end

  local currentEnergy = self:GetEnergy()
  local previousEnergy = self.state.lastEnergy
  local now = GetTime()

  if previousEnergy and currentEnergy > previousEnergy then
    local delta = currentEnergy - previousEnergy
    local gainedFromSkills = 0
    local recentExplicitGain = self.state.lastExplicitEnergyGainAt and (now - self.state.lastExplicitEnergyGainAt) <= 0.35

    if recentExplicitGain then
      local expectedTickAt = self.state.firstEnergyTick and (self.state.firstEnergyTick + 2) or nil
      if delta >= 20 and expectedTickAt and math.abs(now - expectedTickAt) <= 0.35 then
        self.state.firstEnergyTick = now
      end
    elseif delta <= 20 then
      self.state.firstEnergyTick = now
    elseif delta > 20 then
      local expectedTickAt = self.state.firstEnergyTick and (self.state.firstEnergyTick + 2) or nil
      if expectedTickAt and math.abs(now - expectedTickAt) <= 0.35 then
        self.state.firstEnergyTick = now
        gainedFromSkills = delta - 20
      else
        gainedFromSkills = delta
      end
    else
      gainedFromSkills = delta
    end

    if self:IsCombatSessionActive() and gainedFromSkills > 0 then
      self:AddCombatEnergyGain(gainedFromSkills)
    end
  end
  self.state.lastEnergy = currentEnergy
end

function addon:OnCombatMiss(message)
  if not message then
    return
  end

  if self.OnPoisonCombatMessage then
    self:OnPoisonCombatMessage(message)
  end
  self:ClearPickPocketActionBlockOnResist(message)

  local lower = string.lower(message)
  if string.find(lower, "parry") then
    self.state.riposteReadyUntil = GetTime() + 5
  end

  local lastAttempt = self.state.lastSpellAttempt
  local recentAttempt = lastAttempt and lastAttempt.at and (GetTime() - lastAttempt.at) <= 1
  if string.find(lower, "dodge") then
    local targetKey = self:GetTargetKey()
    if recentAttempt and lastAttempt.targetKey then
      targetKey = lastAttempt.targetKey
    end
    self:MarkSurpriseAttackReady(targetKey, 5)
  end

  if recentAttempt and lastAttempt.name == "Kidney Shot" and string.find(lower, "immune") then
    self:RecordKidneyShotLearning("immune", self.state.pendingKidneyShotCheck or self:BuildCurrentTargetLearningSample())
    self:ClearPendingKidneyShotCheck()
  end
end

function addon:OnUiError(message)
  self.state.lastUiError = message
  if not message then
    return
  end

  if self.OnPoisonUiError then
    self:OnPoisonUiError(message)
  end
  self:ClearPickPocketActionBlockOnResist(message)

  local lower = string.lower(message)
  local lastAttempt = self.state.lastSpellAttempt
  local recentAttempt = lastAttempt and lastAttempt.at and (GetTime() - lastAttempt.at) <= 1

  if self.OnRoleplayPickPocketFailure then
    self:OnRoleplayPickPocketFailure(message)
  end

  if recentAttempt and (string.find(lower, "behind your target") or string.find(lower, "must be behind")) then
    if lastAttempt.name == "Backstab" or lastAttempt.name == "Garrote" or lastAttempt.name == "Ambush" then
      self:MarkBehindBlocked(lastAttempt.targetKey)
    end
  end

  if recentAttempt and lastAttempt.name == "Kidney Shot" and string.find(lower, "immune") then
    self:RecordKidneyShotLearning("immune", self.state.pendingKidneyShotCheck or self:BuildCurrentTargetLearningSample())
    self:ClearPendingKidneyShotCheck()
  end

  if recentAttempt and self:IsLocallyTrackedPlayerBuff(lastAttempt.name) then
    self:ClearPendingPlayerBuff(lastAttempt.name)
  end

  if recentAttempt and lastAttempt.name == "Pick Pocket" and self.state.pendingPickPocketTarget then
    if string.find(lower, "too far away") or string.find(lower, "out of range") or string.find(lower, "line of sight") or string.find(lower, "closer") then
      self:RevertPendingPickPocketAttempt()
    else
      self:SuppressTargetSpell("Pick Pocket", 10, lastAttempt.targetKey)
      self:ClearPendingPickPocketAttempt()
    end
  end
end

function addon:OnLootOpened()
  self:PrunePendingPickPocketAttempt()
  local targetKey = self.state.pendingPickPocketTarget
  if not targetKey and UnitExists("target") and not UnitIsDead("target") then
    targetKey = self:GetTargetKey()
    self.state.pickPocketMoneyTracking = {
      before = GetMoney and GetMoney() or 0,
      expires = GetTime() + 5,
    }
  end

  if targetKey then
    self:MarkTargetPickPocketed(targetKey)
    self:BeginPickPocketLootSession()
    self:CapturePickPocketLootWindow()
    self:ClearPendingPickPocketAttempt()
  end
end

function addon:OnLootClosed()
  if self:HasActivePickPocketLootSession() then
    self:SchedulePickPocketLootSessionFinish(0.75)
  end
end

function addon:OnChatLoot(message)
  if not self:HasActivePickPocketLootSession() then
    return
  end

  local entry = self:ExtractLootText(message)
  if entry and entry ~= "" then
    self:AddPickPocketLootEntry(entry)
  end
end

function addon:OnChatMoney(message)
  if not self:HasActivePickPocketLootSession() then
    return
  end

  if message and message ~= "" then
    self:AddPickPocketLootEntry(message)
  end
end

function addon:OnPlayerMoney()
  local tracking = self.state.pickPocketMoneyTracking
  if not tracking then
    return
  end

  if GetTime() > (tracking.expires or 0) then
    self.state.pickPocketMoneyTracking = nil
    return
  end

  local currentMoney = GetMoney and GetMoney() or 0
  local gainedCopper = currentMoney - (tracking.before or currentMoney)
  if gainedCopper > 0 then
    if not tracking.recorded then
      self:RecordPickPocketGold(gainedCopper)
      self:UpdatePickPocketGoldStatsFrame(true)
    end
    self.state.pickPocketMoneyTracking = nil
  end
end

function addon:OnHostileSpellMessage(message)
  self:TrackMindFlayFromAfflictionMessage(message)
  self:OnHostileSpellCastMessage(message)
  self:OnHostileSpellOutcomeMessage(message)
end

function addon:OnSpellFailedLocalPlayer(message)
  if self.OnPoisonCombatMessage then
    self:OnPoisonCombatMessage(message)
  end
  if self.OnPoisonUiError then
    self:OnPoisonUiError(message)
  end
  self:ClearPickPocketActionBlockOnResist(message)

  if self.OnRoleplayPickPocketFailure then
    self:OnRoleplayPickPocketFailure(message)
  end
end

function addon:OnHostileDeath(message)
  if self.OnRoleplayHostileDeath then
    self:OnRoleplayHostileDeath(message)
  end
end

function addon:OnTargetChanged()
  self:PruneTrackedDebuffs()
  self:PrunePendingTargetDebuffs()
  self:PruneSuppressedTargetSpells()
  self:FinalizeLearningFight("target_change")
  self:UpdateComboPointFrame(true)
  self.state.activeEnemyCast = nil
  self.state.suppressedEnemyCastBar = nil
  self:ClearPendingKidneyShotCheck()
  self:ClearBuilderEviscerateArm()
  self:ClearBuilderEviscerateUrgent()
  self.state.currentTargetKey = nil
  self.state.learnedTargetKey = nil
  self.state.lastSpellAttempt = nil
  self.state.activeOpenerHint = nil
  self:ClearPendingPickPocketAttempt()
  self:UpdatePoisonImmunityFrame()
  if self.EvaluatePoisonWeaponTarget then
    self:EvaluatePoisonWeaponTarget()
  end
end

function addon:OnComboPointsChanged(unit)
  if unit and unit ~= "player" then
    return
  end

  local currentComboPoints = self:GetComboPoints()
  if currentComboPoints < 4 then
    self:ClearBuilderEviscerateArm()
  end

  self:UpdateComboPointFrame(true)
end

frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_AURAS_CHANGED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("ITEM_LOCK_CHANGED")
frame:RegisterEvent("UNIT_ENERGY")
frame:RegisterEvent("UNIT_COMBO_POINTS")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
frame:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PET_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
frame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
frame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_CLOSED")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("CHAT_MSG_MONEY")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

local function resolveEventArgs(selfOrEvent, eventOrArg1, eventPayload)
  if type(selfOrEvent) == "string" then
    return selfOrEvent, eventOrArg1
  end

  if type(eventOrArg1) == "string" then
    return eventOrArg1, eventPayload
  end

  if type(event) == "string" then
    return event, arg1
  end

  return nil, nil
end

frame:SetScript("OnEvent", function(selfOrEvent, eventOrArg1, eventPayload)
  local eventName, arg1 = resolveEventArgs(selfOrEvent, eventOrArg1, eventPayload)
  if eventName == "VARIABLES_LOADED" then
    addon:OnVariablesLoaded()
  elseif eventName == "PLAYER_LOGIN" then
    addon:OnPlayerLogin()
  elseif eventName == "PLAYER_REGEN_DISABLED" then
    addon:OnCombatStarted()
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    addon:OnCombatEnded()
    if addon.OnMountGearEvent then
      addon:OnMountGearEvent(eventName, arg1)
    end
  elseif eventName == "PLAYER_AURAS_CHANGED" then
    if addon.OnMountGearEvent then
      addon:OnMountGearEvent(eventName, arg1)
    end
  elseif eventName == "UNIT_INVENTORY_CHANGED" then
    if addon.OnMountGearEvent and (not arg1 or arg1 == "player") then
      addon:OnMountGearEvent(eventName, arg1)
    end
  elseif eventName == "BAG_UPDATE" then
    if addon.OnMountGearEvent then
      addon:OnMountGearEvent(eventName, arg1)
    end
  elseif eventName == "ITEM_LOCK_CHANGED" then
    if addon.ProcessMountGear then
      addon:ProcessMountGear()
    end
    if addon.ProcessPoisonWeaponSwap then
      addon:ProcessPoisonWeaponSwap()
    end
  elseif eventName == "UNIT_ENERGY" then
    addon:OnEnergyChanged(arg1)
  elseif eventName == "UNIT_COMBO_POINTS" then
    addon:OnComboPointsChanged(arg1)
  elseif eventName == "LEARNED_SPELL_IN_TAB" or eventName == "CHARACTER_POINTS_CHANGED" then
    addon:OnSpellbookChanged()
  elseif eventName == "CHAT_MSG_COMBAT_SELF_HITS" then
    addon:OnCombatSelfHit(arg1)
  elseif eventName == "CHAT_MSG_COMBAT_SELF_MISSES" then
    addon:OnCombatMiss(arg1)
  elseif eventName == "CHAT_MSG_SPELL_SELF_DAMAGE" then
    addon:OnSpellSelfDamage(arg1)
  elseif eventName == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
    addon:OnSpellPeriodicDamage(arg1)
    addon:OnFriendlySpellMessage(arg1)
  elseif eventName == "CHAT_MSG_SPELL_SELF_BUFF" then
    addon:OnSelfBuffMessage(arg1)
    addon:OnFriendlySpellMessage(arg1)
    if addon.OnRoleplaySelfBuffMessage then
      addon:OnRoleplaySelfBuffMessage(arg1)
    end
  elseif eventName == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER" then
    addon:OnSpellFailedLocalPlayer(arg1)
  elseif eventName == "CHAT_MSG_SPELL_PARTY_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_PARTY_BUFF"
    or eventName == "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF"
    or eventName == "CHAT_MSG_SPELL_PET_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_PET_BUFF"
    or eventName == "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE" then
    addon:OnFriendlySpellMessage(arg1)
  elseif eventName == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
    addon:OnSelfBuffMessage(arg1)
    if addon.OnRoleplaySelfBuffMessage then
      addon:OnRoleplaySelfBuffMessage(arg1)
    end
  elseif eventName == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
    addon:OnSelfBuffFade(arg1)
  elseif eventName == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"
    or eventName == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF"
    or eventName == "CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF"
    or eventName == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE"
    or eventName == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF" then
    addon:OnHostileSpellMessage(arg1)
  elseif eventName == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" or eventName == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" then
    addon:OnSpellPeriodicDamage(arg1)
  elseif eventName == "UI_ERROR_MESSAGE" then
    addon:OnUiError(arg1)
  elseif eventName == "LOOT_OPENED" then
    addon:OnLootOpened()
  elseif eventName == "LOOT_CLOSED" then
    addon:OnLootClosed()
  elseif eventName == "CHAT_MSG_LOOT" then
    addon:OnChatLoot(arg1)
  elseif eventName == "CHAT_MSG_MONEY" then
    addon:OnChatMoney(arg1)
  elseif eventName == "PLAYER_MONEY" then
    addon:OnPlayerMoney()
  elseif eventName == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
    addon:OnHostileDeath(arg1)
  elseif eventName == "PLAYER_TARGET_CHANGED" then
    addon:OnTargetChanged()
  end
end)

local function bootstrapPlayerLoginIfReady()
  if addon.state.playerLoginHandled then
    return
  end

  if IsLoggedIn and not IsLoggedIn() then
    return
  end

  addon:OnPlayerLogin()
end

frame:SetScript("OnUpdate", function()
  bootstrapPlayerLoginIfReady()
  addon:UpdateNoticeFrames()
  addon:UpdatePendingKidneyShotCheck()
  addon:UpdateCooldownListFrame(false)
  addon:UpdateSelfBuffTimelineFrame(false)
  addon:UpdateComboPointFrame(false)
  addon:UpdatePickPocketGoldStatsFrame(false)
  if addon.UpdateMountGear then
    addon:UpdateMountGear()
  end
  if addon.UpdatePoisonWeapons then
    addon:UpdatePoisonWeapons()
  end
  addon:UpdateWeaponPoisonFrame(false)
  addon:UpdateWeaponPoisonWarningFrame(false)
end)
