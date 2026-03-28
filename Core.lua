RogueAuto = RogueAuto or {}

local addon = RogueAuto

addon.version = "1.0.0"
addon.refreshWindow = {
  playerBuff = 2,
  targetDebuff = 3,
}
addon.observedDebuffDurations = {
  ["Rupture"] = 10,
  ["Shadow of Death"] = 12,
  ["Expose Armor"] = 30,
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
    bleed = {
      sliceAndDiceFirst = true,
      guaranteePrimaryDebuff = true,
    },
    direct = {
      sliceAndDiceFirst = false,
      guaranteePrimaryDebuff = true,
    },
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
    useBlind = false,
  },
  minimap = {
    angle = 220,
  },
  notifications = {
    highlightDuration = 8,
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
  lastEnergy = nil,
  firstEnergyTick = nil,
  riposteReadyUntil = 0,
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
  attackSlot = nil,
  warnedMissingAttackSlot = false,
  targetSerial = 0,
  currentTargetKey = nil,
  learnedTargetKey = nil,
  learningFight = nil,
  combatSession = nil,
  pickPocketLootSession = nil,
  activeNotices = {},
  cachedPlayerCritChance = nil,
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
  melee = "Interface\\Icons\\INV_Sword_04",
  poisonDirect = "Interface\\Icons\\Ability_Poisons",
  bleedDot = "Interface\\Icons\\Ability_Rogue_Rupture",
  poisonDot = "Interface\\Icons\\INV_Potion_19",
  misc = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
}

addon.noticeAnchorInsetPct = 0.15
addon.noticeDefaultY = -120
addon.pickPocketFallbackTexture = "Interface\\Icons\\INV_Misc_Bag_10"
addon.coinTexture = "Interface\\Icons\\INV_Misc_Coin_01"
addon.pickPocketTitleTexture = "Interface\\Icons\\INV_Misc_Bag_10"
addon.playerStatUpdateInterval = 0.25

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

addon.dotBaseDurations = {
  ["Rupture"] = 6,
}

addon.dotPerPointDurations = {
  ["Rupture"] = 2,
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

local frame = CreateFrame("Frame", "RogueAutoFrame", UIParent)
addon.frame = frame

local tooltip = CreateFrame("GameTooltip", "RogueAutoTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
addon.tooltip = tooltip

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

  noticeFrame.categoryRows = {}

  for index, categoryKey in ipairs(addon.damageCategoryOrder) do
    local row = CreateFrame("Frame", nil, noticeFrame)
    row:SetWidth(312)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", totalRow, "BOTTOMLEFT", 0, -6 - ((index - 1) * 20))
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
  self:MigrateSettings()
end

function addon:ResetDB()
  RogueAutoDB = deepCopy(self.defaults)
  self:RefreshKnownSpells()
  self:Print("Settings reset to defaults.")
end

function addon:MigrateSettings()
  if not RogueAutoDB or not RogueAutoDB.core then
    return
  end

  local core = RogueAutoDB.core
  core.bleed = mergeDefaults(core.bleed, deepCopy(self.defaults.core.bleed))
  core.direct = mergeDefaults(core.direct, deepCopy(self.defaults.core.direct))
  RogueAutoDB.notifications = mergeDefaults(RogueAutoDB.notifications, deepCopy(self.defaults.notifications))
  RogueAutoDB.learning = mergeDefaults(RogueAutoDB.learning, deepCopy(self.defaults.learning))

  if core.bleedSliceAndDiceFirst ~= nil then
    core.bleed.sliceAndDiceFirst = core.bleedSliceAndDiceFirst
    core.bleedSliceAndDiceFirst = nil
  end

  if core.guaranteeBleedDebuff ~= nil then
    core.bleed.guaranteePrimaryDebuff = core.guaranteeBleedDebuff
    core.guaranteeBleedDebuff = nil
  end

  if core.directSliceAndDiceFirst ~= nil then
    core.direct.sliceAndDiceFirst = core.directSliceAndDiceFirst
    core.directSliceAndDiceFirst = nil
  end

  if core.guaranteeDirectDebuff ~= nil then
    core.direct.guaranteePrimaryDebuff = core.guaranteeDirectDebuff
    core.guaranteeDirectDebuff = nil
  end
end

function addon:IsTargetDebuffPresent(name)
  local active = self:IsTargetDebuffActive(name)
  return active == true
end

function addon:ShouldSwitchToDirectDamageDealer(mode)
  if mode == "direct" then
    return self:IsTargetDebuffPresent("Expose Armor")
  end

  if mode == "bleed" then
    return self:IsTargetDebuffPresent("Rupture")
  end

  return false
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

local function formatPlayerStatPct(value)
  if not value then
    return nil
  end

  return string.format("%.1f%%", value)
end

function addon:EnsurePlayerStatFrame()
  if self.playerStatFrame then
    return self.playerStatFrame
  end

  if not PlayerFrameManaBar then
    return nil
  end

  local statFrame = CreateFrame("Frame", "RogueAutoPlayerStatFrame", UIParent)
  statFrame:SetHeight(12)
  statFrame:SetPoint("BOTTOMLEFT", PlayerFrameManaBar, "BOTTOMLEFT", 0, -18)
  statFrame:SetWidth(100)
  local statusBar = CreateFrame("StatusBar", nil, statFrame, "TextStatusBar")
  statusBar:SetAllPoints(statFrame)
  statusBar:SetMinMaxValues(0, 1)
  statusBar:SetValue(1)
  statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  statusBar:SetStatusBarColor(0, 0, 0, 0)
  statFrame.statusBar = statusBar

  local bg = statusBar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(statusBar)
  bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bg:SetVertexColor(0, 0, 0, 0)
  statusBar.bg = bg

  local border = statusBar:CreateTexture(nil, "OVERLAY")
  border:SetWidth(120)
  border:SetHeight(18)
  border:SetPoint("TOPLEFT", statusBar, "TOPLEFT", -12, 0)
  border:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
  border:SetTexCoord(0.0234375, 0.6875, 1.0, 0.0)
  statFrame.border = border

  local label = statFrame:CreateFontString(nil, "OVERLAY")
  label:SetPoint("CENTER", statFrame, "CENTER", 0, 0)
  label:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
  label:SetTextColor(1, 1, 1)
  label:SetJustifyH("CENTER")
  statFrame.label = label

  self.playerStatFrame = statFrame
  return statFrame
end

function addon:UpdatePlayerStatFrame(force)
  local now = GetTime()
  if not force and self.state.nextPlayerStatUpdate and now < self.state.nextPlayerStatUpdate then
    return
  end

  self.state.nextPlayerStatUpdate = now + (self.playerStatUpdateInterval or 0.25)

  local statFrame = self:EnsurePlayerStatFrame()
  if not statFrame then
    return
  end

  local dodgeChance = GetDodgeChance and GetDodgeChance() or nil

  if not dodgeChance then
    statFrame:Hide()
    return
  end

  statFrame.label:SetText("Dodge Chance " .. (formatPlayerStatPct(dodgeChance) or "--"))
  statFrame:Show()
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

  noticeFrame:SetHeight(176)
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
  table.insert(lines, self.damageCategories.melee .. ": " .. tostring(totals.melee or 0))
  table.insert(lines, self.damageCategories.poisonDirect .. ": " .. tostring(totals.poisonDirect or 0))
  table.insert(lines, self.damageCategories.bleedDot .. ": " .. tostring(totals.bleedDot or 0))
  table.insert(lines, self.damageCategories.poisonDot .. ": " .. tostring(totals.poisonDot or 0))
  table.insert(lines, self.damageCategories.misc .. ": " .. tostring(totals.misc or 0))

  return table.concat(lines, "\n"), totalDamage
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
  local amount = self:ExtractDamageAmount(message)
  if amount then
    self:RecordDamageEvent("melee", nil, "Physical", amount)
  end
end

function addon:OnSpellSelfDamage(message)
  if not message then
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
  self.state.pickPocketLootSession = {
    entries = {},
    seen = {},
    finishAt = GetTime() + 3,
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

  local entries = session.entries
  if not session.seen[normalized] then
    local entry = {
      text = normalized,
      icon = texture or inferPickPocketEntryTexture(normalized),
    }
    table.insert(entries, entry)
    session.seen[normalized] = entry
  elseif texture and session.seen[normalized] and (not session.seen[normalized].icon or session.seen[normalized].icon == self.pickPocketFallbackTexture) then
    session.seen[normalized].icon = texture
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
  if table.getn(entries) == 0 then
    table.insert(entries, {
      text = "Nothing",
      icon = self.pickPocketFallbackTexture,
    })
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

function addon:GetRotationSettings(mode)
  if not RogueAutoDB or not RogueAutoDB.core then
    return nil
  end

  return RogueAutoDB.core[mode]
end

function addon:GetBleedSettings()
  return self:GetRotationSettings("bleed")
end

function addon:GetDirectSettings()
  return self:GetRotationSettings("direct")
end

function addon:RefreshKnownSpells()
  self.state.knownSpells = {}
  self.state.spellEnergyCosts = {}

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
      lastSeen = 0,
    }
    bucket[learningKey] = entry
  end

  return entry
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
end

function addon:IsHostileTarget()
  if not UnitExists("target") or UnitIsDead("target") then
    return false
  end

  if UnitCanAttack then
    return UnitCanAttack("player", "target") == 1
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

function addon:GetExpectedTargetMaxHealth(profile)
  local liveMaxHealth = UnitHealthMax("target") or 0
  local learnedMaxHealth = profile and profile.avgMaxHealth or 0
  if not self:IsUsableLearnedHealth(learnedMaxHealth) then
    learnedMaxHealth = 0
  end

  if liveMaxHealth > 0 and learnedMaxHealth > 0 then
    return math.floor(((liveMaxHealth * 3) + learnedMaxHealth) / 4 + 0.5)
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

  if baselineHealth and baselineHealth > 0 and expectedMaxHealth and expectedMaxHealth > 0 then
    estimatedDuration = baselineDuration * (expectedMaxHealth / baselineHealth)
  end

  local learnedDuration = profile and profile.avgFightDuration or 0
  if not self:IsUsableLearnedDuration(learnedDuration) then
    learnedDuration = 0
  end

  if learnedDuration > 0 then
    if estimatedDuration > 0 then
      return (learnedDuration * 0.7) + (estimatedDuration * 0.3)
    end
    return learnedDuration
  end

  return estimatedDuration
end

function addon:GetTargetDurabilityScore()
  if not self:IsHostileTarget() then
    return nil
  end

  local profile = self:GetMobLearningProfile()
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
  local score, _, _ = self:GetTargetDurabilityScore()
  local tier = self:GetDurabilityTier(score, self:GetTargetClassification())
  if tier == "low" then
    return "trash_short"
  elseif tier == "high" then
    return "durable"
  end
  return "normal"
end

function addon:ShouldInvestInPrimaryDebuff(mode, profile)
  profile = profile or self:GetFightProfile()
  return profile ~= "trash_short"
end

function addon:ShouldInvestInSliceAndDice(profile)
  profile = profile or self:GetFightProfile()
  return profile ~= "trash_short"
end

function addon:ShouldForceImmediateDamage(profile)
  profile = profile or self:GetFightProfile()
  return profile == "trash_short"
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

function addon:GetPrimaryDebuffName(mode)
  if mode == "bleed" then
    return "Rupture"
  end

  if mode == "direct" then
    return "Expose Armor"
  end

  return nil
end

function addon:GetSliceAndDiceComboThreshold(context)
  if not context or context.durabilityTier == "low" then
    return 99
  end

  if context.durabilityTier == "medium" then
    if context.remainingFightDuration < 10 then
      return 99
    end
    if context.comboPoints >= 3 then
      return 99
    end
    return 2
  end

  if context.remainingFightDuration < 12 then
    return 99
  end

  if context.comboPoints >= 4 and context.remainingFightDuration < 18 then
    return 99
  end

  return 2
end

function addon:GetPrimaryDebuffComboThreshold(mode, context)
  if not context then
    return 99
  end

  if mode == "bleed" then
    if context.durabilityTier == "medium" and context.remainingFightDuration >= 3 then
      return 2
    elseif context.durabilityTier == "high" and context.remainingFightDuration >= 5 then
      return 3
    end
    return 99
  end

  if mode == "direct" then
    if context.durabilityTier == "high" and context.remainingFightDuration >= 5 then
      return 3
    elseif context.durabilityTier == "medium" and context.targetHealthPct > 45 and context.remainingFightDuration >= 4.5 then
      return 3
    end
  end

  return 99
end

function addon:GetFinisherComboThreshold(context)
  if not context then
    return 5
  end

  if context.durabilityTier == "low" then
    if context.targetHealthPct <= 45 then
      return 2
    end
    return 3
  end

  if context.durabilityTier == "medium" then
    if context.targetHealthPct <= 55 or context.remainingFightDuration < 8 then
      return 3
    end
    return 4
  end

  if context.targetHealthPct <= 40 or context.remainingFightDuration < 10 then
    return 4
  end

  return 5
end

function addon:ShouldAttemptPrimaryDebuff(mode, context)
  if not context then
    return false
  end

  if mode == "bleed" then
    return context.durabilityTier ~= "low" and context.remainingFightDuration >= 3
  end

  if mode == "direct" then
    return (context.durabilityTier == "high" and context.remainingFightDuration >= 5)
      or (context.durabilityTier == "medium" and context.targetHealthPct > 45 and context.remainingFightDuration >= 4.5)
  end

  return false
end

function addon:GetBestDirectFinisherSpell(context)
  if self:HasSpell("Envenom")
    and context
    and context.durabilityTier ~= "low"
    and context.comboPoints >= 4
    and context.remainingFightDuration >= 5
    and context.poisonReliable then
    return "Envenom"
  end

  if self:HasSpell("Eviscerate") then
    return "Eviscerate"
  end

  if self:HasSpell("Envenom") then
    return "Envenom"
  end

  return nil
end

function addon:ShouldUseSliceAndDice(context)
  if not context or not RogueAutoDB.core.keepSliceAndDice or context.durabilityTier == "low" then
    return false
  end

  if context.sndThreshold >= 99 then
    return false
  end

  if context.comboPoints < context.sndThreshold then
    return false
  end

  if context.primarySpell
    and self:ShouldAttemptPrimaryDebuff(context.mode, context)
    and context.comboPoints >= context.primaryThreshold
    and (not context.primaryActive or context.primaryRemaining < self.refreshWindow.targetDebuff) then
    return false
  end

  if context.durabilityTier == "medium" then
    if not context.sndActive then
      return context.remainingFightDuration >= 15 and context.comboPoints <= 2
    end

    if context.sndRemaining >= self.refreshWindow.playerBuff then
      return false
    end

    return context.sndRemaining < 1.5 and context.remainingFightDuration >= 11 and context.comboPoints <= 2
  end

  if not context.sndActive then
    return context.remainingFightDuration >= 16 and context.comboPoints <= 2
  end

  if context.sndRemaining >= self.refreshWindow.playerBuff then
    return false
  end

  if context.comboPoints >= 4 and context.remainingFightDuration < 18 then
    return false
  end

  return context.remainingFightDuration >= 12 and context.sndRemaining < 1.5 and context.comboPoints <= 3
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
    lastHealthPct = self:GetTargetHealthPct(),
    maxHealth = UnitHealthMax("target") or 0,
    maxComboPointsSeen = self:GetComboPoints() or 0,
  }
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

    return (fight.maxComboPointsSeen or 0) >= 2
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
end

function addon:GetComboPointContext(mode)
  self:MaybeBeginLearningFight()

  local comboPoints = self:GetComboPoints()
  local classification = self:GetTargetClassification()
  local score, learningProfile, expectedMaxHealth, baselineHealth = self:GetTargetDurabilityScore()
  local durabilityTier = self:GetDurabilityTier(score, classification)
  local fightProfile = self:GetFightProfile()
  local targetHealthPct = self:GetTargetHealthPct()
  local expectedFightDuration = self:GetExpectedFightDuration(learningProfile, expectedMaxHealth, classification)
  local remainingFightDuration = expectedFightDuration * (targetHealthPct / 100)
  local sndActive, sndRemaining = self:FindPlayerBuff("Slice and Dice")
  local primaryName = self:GetPrimaryDebuffName(mode)
  local primaryActive, primaryRemaining = false, 0
  if primaryName then
    primaryActive, primaryRemaining = self:IsTargetDebuffActive(primaryName)
  end
  local shadowActive, shadowRemaining = self:IsTargetDebuffActive("Shadow of Death")

  local context = {
    mode = mode,
    comboPoints = comboPoints,
    classification = classification,
    durabilityScore = score,
    durabilityTier = durabilityTier,
    fightProfile = fightProfile,
    targetHealthPct = targetHealthPct,
    learningProfile = learningProfile,
    expectedMaxHealth = expectedMaxHealth,
    baselineHealth = baselineHealth,
    expectedFightDuration = expectedFightDuration,
    remainingFightDuration = remainingFightDuration,
    poisonReliable = self:HasReliablePoisonStateOnTarget(),
    sndActive = sndActive,
    sndRemaining = sndRemaining,
    primarySpell = primaryName,
    primaryActive = primaryActive,
    primaryRemaining = primaryRemaining,
    shadowActive = shadowActive,
    shadowRemaining = shadowRemaining,
  }

  context.sndThreshold = self:GetSliceAndDiceComboThreshold(context)
  context.primaryThreshold = self:GetPrimaryDebuffComboThreshold(mode, context)

  return context
end

function addon:GetComboPointDecision(mode, context)
  if not context or context.comboPoints <= 0 then
    return nil
  end

  if mode == "interrupt" then
    if self:HasSpell("Kidney Shot") and context.comboPoints >= 1 then
      return "Kidney Shot"
    end
    return nil
  end

  local settings = mode == "bleed" and self:GetBleedSettings() or self:GetDirectSettings()
  local sndNeedsRefresh = self:ShouldUseSliceAndDice(context)
  local shouldUsePrimary = self:ShouldAttemptPrimaryDebuff(mode, context)
  local primaryNeedsRefresh = shouldUsePrimary
    and context.primarySpell
    and (not context.primaryActive or context.primaryRemaining < self.refreshWindow.targetDebuff)
  local primaryMissing = shouldUsePrimary and context.primarySpell and not context.primaryActive

  if settings
    and settings.guaranteePrimaryDebuff
    and not settings.sliceAndDiceFirst
    and primaryMissing
    and context.comboPoints < context.primaryThreshold then
    return nil
  end

  if settings and settings.sliceAndDiceFirst then
    if sndNeedsRefresh and context.comboPoints >= context.sndThreshold then
      return "Slice and Dice"
    end
    if primaryNeedsRefresh and context.comboPoints >= context.primaryThreshold then
      return context.primarySpell
    end
  else
    if primaryNeedsRefresh and context.comboPoints >= context.primaryThreshold then
      return context.primarySpell
    end
    if sndNeedsRefresh and context.comboPoints >= context.sndThreshold then
      return "Slice and Dice"
    end
  end

  if self:HasSpell("Shadow of Death")
    and context.durabilityTier == "high"
    and context.remainingFightDuration >= 12
    and context.primaryActive
    and (not context.shadowActive or context.shadowRemaining < self.refreshWindow.targetDebuff)
    and context.comboPoints >= 5 then
    return "Shadow of Death"
  end

  local finisherSpell = self:GetBestDirectFinisherSpell(context)
  local finisherThreshold = self:GetFinisherComboThreshold(context)
  if finisherSpell and context.comboPoints >= finisherThreshold then
    return finisherSpell
  end

  return nil
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

  self:Debug("Casting " .. name)
  self.state.lastSpellAttempt = {
    name = name,
    targetKey = self:GetTargetKey(),
    at = GetTime(),
  }
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

function addon:GetPreferredBuilder()
  local mode = RogueAutoDB.builder.mode
  local forcedSpell = self.builderModes[mode]
  if forcedSpell and self:HasSpell(forcedSpell) then
    if forcedSpell == "Backstab" and (not self:IsDaggerEquipped() or self:IsBehindBlocked()) then
      if self:HasSpell("Hemorrhage") then
        return "Hemorrhage"
      end
      return self:HasSpell("Sinister Strike") and "Sinister Strike" or forcedSpell
    end
    return forcedSpell
  end

  if self:HasSpell("Backstab") and self:IsDaggerEquipped() and not self:IsBehindBlocked() then
    return "Backstab"
  end

  local preferredSpells = {
    "Noxious Assault",
    "Hemorrhage",
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
    if self:GetComboPoints() == 0 and (not active or remaining < 2) and self:TryCast("Ghostly Strike") then
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

  if name == "Slice and Dice" and not self:ShouldInvestInSliceAndDice() then
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

function addon:ShouldForceDebuffBeforeBuff(name, comboThreshold)
  if not self:HasSpell(name) then
    return false
  end

  local active = self:IsTargetDebuffActive(name)
  if active then
    return false
  end

  return self:GetComboPoints() < (comboThreshold or 1)
end

function addon:ShouldPreferExecuteFinisher(mode)
  local context = self:GetComboPointContext(mode or "direct")
  local finisherSpell = self:GetBestDirectFinisherSpell(context)
  if not finisherSpell then
    return false
  end

  if not context or context.comboPoints <= 0 then
    return false
  end

  if context.durabilityTier == "low" then
    return context.targetHealthPct <= 50
  end

  if context.durabilityTier == "medium" then
    return context.targetHealthPct <= 30
  end

  return context.targetHealthPct <= 20
end

function addon:ShouldFavorImmediateDamage()
  return self:ShouldForceImmediateDamage(self:GetFightProfile())
end

function addon:TryPreferredBuilder()
  local builderMode = RogueAutoDB and RogueAutoDB.builder and RogueAutoDB.builder.mode
  local shouldTryBackstab = self:HasSpell("Backstab")
    and self:IsDaggerEquipped()
    and not self:IsBehindBlocked()
    and (builderMode == "backstab" or builderMode == "auto")
  if shouldTryBackstab and self:TryCast("Backstab") then
    return true
  end

  if RogueAutoDB.core.softDefensives.ghostlyStrike and self:HasSpell("Ghostly Strike") then
    local active, remaining = self:FindPlayerBuff(self.buffAliases.ghostlyStrike)
    if self:GetComboPoints() < 5 and (not active or remaining < 2) and self:TryCast("Ghostly Strike") then
      return true
    end
  end

  local builder = self:GetPreferredBuilder()
  if builder then
    return self:TryCast(builder)
  end

  return false
end

function addon:TryExecuteFinisher(mode)
  local context = self:GetComboPointContext(mode or "direct")
  local finisherSpell = self:GetBestDirectFinisherSpell(context)
  if not finisherSpell then
    return false
  end

  if not context or context.comboPoints <= 0 then
    return false
  end

  return self:TryCast(finisherSpell)
end

function addon:TryDirectFinisher(minComboPoints)
  local context = self:GetComboPointContext("direct")
  local finisherSpell = self:GetBestDirectFinisherSpell(context)
  if not finisherSpell then
    return false
  end

  if not context or context.comboPoints < (minComboPoints or 5) then
    return false
  end

  return self:TryCast(finisherSpell)
end

function addon:TryHeuristicFinisher(mode)
  local context = self:GetComboPointContext(mode)
  local spellName = self:GetComboPointDecision(mode, context)
  if not spellName then
    return false
  end

  if spellName == "Rupture" or spellName == "Expose Armor" or spellName == "Shadow of Death" then
    return self:TryCastWithComboTracking(spellName, context.comboPoints)
  end

  return self:TryCast(spellName)
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
  self:UpdatePlayerStatFrame(true)
  self:Debug("Loaded version " .. self.version)
end

function addon:OnCombatStarted()
  if not self:IsCombatSessionActive() then
    self:StartCombatSession()
  end

  self:MaybeBeginLearningFight()
end

function addon:OnCombatEnded()
  self:FinalizeLearningFight("combat_end")
  self:FinishCombatSession()
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
  local lastAttempt = self.state.lastSpellAttempt
  local recentAttempt = lastAttempt and lastAttempt.at and (GetTime() - lastAttempt.at) <= 1

  if recentAttempt and (string.find(lower, "behind your target") or string.find(lower, "must be behind")) then
    if lastAttempt.name == "Backstab" or lastAttempt.name == "Garrote" or lastAttempt.name == "Ambush" then
      self:MarkBehindBlocked(lastAttempt.targetKey)
    end
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
  if self.state.pendingPickPocketTarget then
    self:MarkTargetPickPocketed(self.state.pendingPickPocketTarget)
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

function addon:OnTargetChanged()
  self:PruneTrackedDebuffs()
  self:PrunePendingTargetDebuffs()
  self:PruneSuppressedTargetSpells()
  self:FinalizeLearningFight("target_change")
  self.state.currentTargetKey = nil
  self.state.learnedTargetKey = nil
  self.state.lastSpellAttempt = nil
  self:ClearPendingPickPocketAttempt()
end

frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("UNIT_ENERGY")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_CLOSED")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("CHAT_MSG_MONEY")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

frame:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    addon:OnVariablesLoaded()
  elseif event == "PLAYER_LOGIN" then
    addon:OnPlayerLogin()
  elseif event == "PLAYER_REGEN_DISABLED" then
    addon:OnCombatStarted()
  elseif event == "PLAYER_REGEN_ENABLED" then
    addon:OnCombatEnded()
  elseif event == "UNIT_ENERGY" then
    addon:OnEnergyChanged(arg1)
  elseif event == "LEARNED_SPELL_IN_TAB" or event == "CHARACTER_POINTS_CHANGED" then
    addon:OnSpellbookChanged()
  elseif event == "CHAT_MSG_COMBAT_SELF_HITS" then
    addon:OnCombatSelfHit(arg1)
  elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
    addon:OnCombatMiss(arg1)
  elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
    addon:OnSpellSelfDamage(arg1)
  elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" or event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" then
    addon:OnSpellPeriodicDamage(arg1)
  elseif event == "UI_ERROR_MESSAGE" then
    addon:OnUiError(arg1)
  elseif event == "LOOT_OPENED" then
    addon:OnLootOpened()
  elseif event == "LOOT_CLOSED" then
    addon:OnLootClosed()
  elseif event == "CHAT_MSG_LOOT" then
    addon:OnChatLoot(arg1)
  elseif event == "CHAT_MSG_MONEY" then
    addon:OnChatMoney(arg1)
  elseif event == "PLAYER_TARGET_CHANGED" then
    addon:OnTargetChanged()
  end
end)

frame:SetScript("OnUpdate", function()
  addon:UpdateNoticeFrames()
  addon:UpdatePlayerStatFrame(false)
end)
