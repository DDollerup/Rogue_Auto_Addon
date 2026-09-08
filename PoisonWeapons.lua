local addon = RogueAuto
local coreGetWeaponPoisonName = addon.GetWeaponPoisonName

local PROFILE_NORMAL = "normal"
local PROFILE_DISSOLVENT = "dissolvent"
local TARGET_SETTLE_SECONDS = 0.20
local EQUIP_COOLDOWN_SECONDS = 1.60
local SLOT_CONFIRM_SECONDS = 1.85
local TRANSACTION_TIMEOUT_SECONDS = 8
local MAX_SLOT_ATTEMPTS = 4

local dissolventTypes = { elemental = true, giant = true, undead = true, mechanical = true }
local poisonNames = {
  "Dissolvent Poison", "Instant Poison", "Deadly Poison",
  "Crippling Poison", "Mind-numbing Poison", "Wound Poison",
}

local function lower(value) return string.lower(value or "") end
local function now() return GetTime and GetTime() or 0 end

local function identityFromLink(link)
  if not link then return nil end
  local _, _, itemId, enchantId, randomId, uniqueId = string.find(link, "item:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)")
  if not itemId then return nil end
  return {
    link = link,
    itemId = tonumber(itemId),
    enchantId = tonumber(enchantId) or 0,
    randomId = tonumber(randomId) or 0,
    uniqueId = tonumber(uniqueId) or 0,
  }
end

local function sameIdentity(left, right)
  return left and right
    and left.itemId == right.itemId
    and left.enchantId == right.enchantId
    and left.randomId == right.randomId
    and left.uniqueId == right.uniqueId
end

local function sameItem(left, right)
  return left and right and left.itemId == right.itemId
end

function addon:GetPoisonWeaponSettings()
  RogueAutoDB = RogueAutoDB or {}
  RogueAutoDB.poisonWeapons = RogueAutoDB.poisonWeapons or {}
  local settings = RogueAutoDB.poisonWeapons
  if settings.enabled == nil then settings.enabled = false end
  if settings.allowCombat == nil then settings.allowCombat = true end
  settings.profiles = settings.profiles or {}
  return settings
end

function addon:GetPoisonWeaponState()
  self.state = self.state or {}
  local state = self.state.poisonWeaponSwap
  if not state then state = {}; self.state.poisonWeaponSwap = state end
  state.phase = state.phase or "idle"
  state.message = state.message or "Ready."
  state.operations = state.operations or {}
  state.operationIndex = state.operationIndex or 1
  state.slotAttempts = state.slotAttempts or 0
  state.generation = state.generation or 0
  state.targetGeneration = state.targetGeneration or 0
  state.nextAttemptAt = state.nextAttemptAt or 0
  state.confirmDeadline = state.confirmDeadline or 0
  state.transactionDeadline = state.transactionDeadline or 0
  return state
end

function addon:GetPoisonWeaponTargetSignature()
  if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then return "none" end
  return lower(UnitName("target")) .. "|" .. lower(UnitCreatureType("target"))
end

function addon:GetEquippedPoisonWeapon(slotId)
  return identityFromLink(GetInventoryItemLink("player", slotId))
end

function addon:ReadPoisonWeaponTooltip(setTooltip)
  if not RogueAutoPoisonWeaponTooltip then
    CreateFrame("GameTooltip", "RogueAutoPoisonWeaponTooltip", UIParent, "GameTooltipTemplate")
  end
  RogueAutoPoisonWeaponTooltip:SetOwner(UIParent, "ANCHOR_NONE")
  RogueAutoPoisonWeaponTooltip:ClearLines()
  setTooltip(RogueAutoPoisonWeaponTooltip)
  RogueAutoPoisonWeaponTooltip:Show()
  local fallback = nil
  local index
  for index = 1, 12 do
    local leftLine = getglobal("RogueAutoPoisonWeaponTooltipTextLeft" .. index)
    local rightLine = getglobal("RogueAutoPoisonWeaponTooltipTextRight" .. index)
    local texts = { leftLine and leftLine:GetText() or nil, rightLine and rightLine:GetText() or nil }
    local textIndex
    for textIndex = 1, 2 do
      local text = texts[textIndex]
      local parsed = text and self.ExtractWeaponPoisonNameFromText and self:ExtractWeaponPoisonNameFromText(text)
      if parsed then return parsed end
      local normalized = lower(text)
      local poisonIndex
      for poisonIndex = 1, table.getn(poisonNames) do
        if string.find(normalized, lower(poisonNames[poisonIndex]), 1, true) then return poisonNames[poisonIndex] end
      end
      if not fallback and string.find(normalized, "poison", 1, true) then fallback = text end
    end
  end
  return fallback
end

function addon:GetWeaponPoisonName(slotId)
  if coreGetWeaponPoisonName then
    local poisonName = coreGetWeaponPoisonName(self, slotId)
    if poisonName then return poisonName end
  end
  return self:ReadPoisonWeaponTooltip(function(tooltip) tooltip:SetInventoryItem("player", slotId) end)
end

function addon:GetBagWeaponPoisonName(bag, slot)
  return self:ReadPoisonWeaponTooltip(function(tooltip) tooltip:SetBagItem(bag, slot) end)
end

function addon:PoisonWeaponSlotMatches(slotId, identity, poisonName)
  local equipped = self:GetEquippedPoisonWeapon(slotId)
  if not sameItem(equipped, identity) then return false end
  if poisonName and poisonName ~= "" then return lower(self:GetWeaponPoisonName(slotId)) == lower(poisonName) end
  return sameIdentity(equipped, identity)
end

function addon:CapturePoisonWeaponProfile(profileId)
  if profileId ~= PROFILE_NORMAL and profileId ~= PROFILE_DISSOLVENT then return false end
  local settings = self:GetPoisonWeaponSettings()
  local state = self:GetPoisonWeaponState()
  local main = self:GetEquippedPoisonWeapon(16)
  local off = self:GetEquippedPoisonWeapon(17)
  local mainPoison = self:GetWeaponPoisonName(16)
  local offPoison = self:GetWeaponPoisonName(17)
  if not main or not off then
    state.phase = "blocked"; state.message = "Equip both weapons before saving this profile."; return false
  end
  if not mainPoison or not offPoison then
    state.phase = "blocked"; state.message = "Poison must be detected on both weapons before saving."; return false
  end
  if profileId == PROFILE_DISSOLVENT
    and lower(mainPoison) ~= lower("Dissolvent Poison")
    and lower(offPoison) ~= lower("Dissolvent Poison") then
    state.phase = "blocked"; state.message = "The Dissolvent profile requires Dissolvent Poison."; return false
  end
  settings.profiles[profileId] = {
    slots = { [16] = main, [17] = off },
    poisons = { [16] = mainPoison, [17] = offPoison },
  }
  state.phase = "idle"
  state.message = "Captured " .. profileId .. " weapons."
  state.blockedSignature = nil
  state.lastObservedSignature = nil
  self:RequestPoisonWeaponProfile("capture", true)
  return true
end

function addon:GetPoisonWeaponProfileSummary(profileId)
  local profile = self:GetPoisonWeaponSettings().profiles[profileId]
  if not profile then return "Not captured" end
  local main = profile.slots and profile.slots[16]
  local off = profile.slots and profile.slots[17]
  local mainText = main and main.link or "Empty"
  local offText = off and off.link or "Empty"
  local mainPoison = profile.poisons and profile.poisons[16] or "No poison detected"
  local offPoison = profile.poisons and profile.poisons[17] or "No poison detected"
  return "Main: " .. mainText .. " - " .. mainPoison .. "\nOff: " .. offText .. " - " .. offPoison
end

function addon:GetActivePoisonWeaponProfileId()
  local settings = self:GetPoisonWeaponSettings()
  local ids = { PROFILE_NORMAL, PROFILE_DISSOLVENT }
  local index
  for index = 1, table.getn(ids) do
    local profile = settings.profiles[ids[index]]
    if profile and profile.slots
      and self:PoisonWeaponSlotMatches(16, profile.slots[16], profile.poisons and profile.poisons[16])
      and self:PoisonWeaponSlotMatches(17, profile.slots[17], profile.poisons and profile.poisons[17]) then return ids[index] end
  end
  return nil
end

function addon:FindPoisonWeapon(identity, poisonName)
  if not identity then return nil end
  local bag
  for bag = 0, 4 do
    local slot
    for slot = 1, GetContainerNumSlots(bag) do
      local candidate = identityFromLink(GetContainerItemLink(bag, slot))
      if sameItem(candidate, identity) then
        if poisonName and poisonName ~= "" then
          if lower(self:GetBagWeaponPoisonName(bag, slot)) == lower(poisonName) then return bag, slot end
        elseif sameIdentity(candidate, identity) then return bag, slot end
      end
    end
  end
  return nil
end

function addon:GetDesiredPoisonWeaponProfileId()
  local settings = self:GetPoisonWeaponSettings()
  if not settings.enabled then return nil end
  if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
    if dissolventTypes[lower(UnitCreatureType("target"))] and settings.profiles[PROFILE_DISSOLVENT] then return PROFILE_DISSOLVENT end
    if settings.profiles[PROFILE_NORMAL] then return PROFILE_NORMAL end
  end
  return nil
end

function addon:FailPoisonWeaponTransaction(message)
  local state = self:GetPoisonWeaponState()
  state.phase = "blocked"
  state.message = message
  state.blockedSignature = self:GetPoisonWeaponTargetSignature()
  state.blockedProfile = state.desiredProfile or state.transactionProfile
  state.operations = {}
  state.transactionProfile = nil
  state.waitingForConfirmation = false
end

function addon:BeginPoisonWeaponSwap(profileId, reason)
  local settings = self:GetPoisonWeaponSettings()
  local profile = settings.profiles[profileId]
  local state = self:GetPoisonWeaponState()
  state.desiredProfile = profileId
  if state.phase == "equipping" then return true end
  if not profile or not profile.slots then self:FailPoisonWeaponTransaction("Capture the " .. profileId .. " profile first."); return false end
  if UnitAffectingCombat("player") and not settings.allowCombat then
    state.phase = "waiting_combat"; state.message = "Waiting for combat to end."; return false
  end
  state.operations = {}
  local slots = { 16, 17 }
  local index
  for index = 1, table.getn(slots) do
    local slotId = slots[index]
    local identity = profile.slots[slotId]
    local poisonName = profile.poisons and profile.poisons[slotId]
    if identity and not self:PoisonWeaponSlotMatches(slotId, identity, poisonName) then
      table.insert(state.operations, { slotId = slotId, identity = identity, poisonName = poisonName, label = slotId == 16 and "main hand" or "off hand" })
    end
  end
  if table.getn(state.operations) == 0 then
    state.phase = "idle"; state.activeProfile = profileId; state.message = profileId .. " profile equipped."; return true
  end
  state.generation = state.generation + 1
  state.transactionGeneration = state.generation
  state.transactionProfile = profileId
  state.operationIndex = 1
  state.slotAttempts = 0
  state.waitingForConfirmation = false
  state.nextAttemptAt = 0
  state.confirmDeadline = 0
  state.transactionDeadline = now() + TRANSACTION_TIMEOUT_SECONDS
  state.phase = "equipping"
  state.message = "Equipping " .. profileId .. " weapons."
  self:ProcessPoisonWeaponSwap()
  return true
end

function addon:FinishPoisonWeaponTransaction()
  local state = self:GetPoisonWeaponState()
  local completedProfile = state.transactionProfile
  state.phase = "idle"
  state.activeProfile = completedProfile
  state.transactionProfile = nil
  state.operations = {}
  state.waitingForConfirmation = false
  state.message = tostring(completedProfile) .. " profile equipped."
  self:RequestPoisonWeaponProfile("transaction_complete", true)
end

function addon:ProcessPoisonWeaponSwap()
  local state = self:GetPoisonWeaponState()
  if state.processing then return end
  state.processing = true
  local success, errorMessage = pcall(function()
    if state.phase == "waiting_combat" then
      if not UnitAffectingCombat("player") and state.desiredProfile then state.phase = "idle"; self:BeginPoisonWeaponSwap(state.desiredProfile, "combat_end") end
      return
    end
    if state.phase ~= "equipping" then return end
    if now() > state.transactionDeadline then self:FailPoisonWeaponTransaction("Weapon swap timed out. Builder has been released."); return end
    if CursorHasItem and CursorHasItem() then return end
    local operation = state.operations[state.operationIndex]
    if not operation then self:FinishPoisonWeaponTransaction(); return end
    if self:PoisonWeaponSlotMatches(operation.slotId, operation.identity, operation.poisonName) then
      state.operationIndex = state.operationIndex + 1
      state.slotAttempts = 0
      state.waitingForConfirmation = false
      state.confirmDeadline = 0
      return
    end
    if state.waitingForConfirmation and now() < state.confirmDeadline then return end
    if state.waitingForConfirmation then
      state.waitingForConfirmation = false
      if state.slotAttempts >= MAX_SLOT_ATTEMPTS then self:FailPoisonWeaponTransaction("Could not equip " .. operation.label .. ". Builder has been released."); return end
    end
    if now() < state.nextAttemptAt then return end
    local bag, slot = self:FindPoisonWeapon(operation.identity, operation.poisonName)
    if bag == nil then self:FailPoisonWeaponTransaction("The saved " .. operation.label .. " weapon is not in your bags."); return end
    if not PickupContainerItem or not EquipCursorItem then self:FailPoisonWeaponTransaction("Required weapon equipment APIs are unavailable."); return end
    PickupContainerItem(bag, slot)
    EquipCursorItem(operation.slotId)
    state.slotAttempts = state.slotAttempts + 1
    state.waitingForConfirmation = true
    state.confirmDeadline = now() + SLOT_CONFIRM_SECONDS
    state.nextAttemptAt = now() + EQUIP_COOLDOWN_SECONDS
  end)
  state.processing = false
  if not success then self:FailPoisonWeaponTransaction("Weapon swap error: " .. tostring(errorMessage)) end
end

function addon:RequestPoisonWeaponProfile(source, immediate)
  local settings = self:GetPoisonWeaponSettings()
  local state = self:GetPoisonWeaponState()
  if not settings.enabled then return true end
  local signature = self:GetPoisonWeaponTargetSignature()
  local wanted = self:GetDesiredPoisonWeaponProfileId()
  state.desiredProfile = wanted
  state.desiredSignature = signature
  if not wanted then return true end
  if state.phase == "equipping" then return false end
  if state.phase == "target_settling" and not immediate then return false end
  if state.phase == "blocked" and state.blockedSignature == signature and state.blockedProfile == wanted then return true end
  if self:GetActivePoisonWeaponProfileId() == wanted then
    state.phase = "idle"; state.activeProfile = wanted; state.message = wanted .. " profile equipped."; return true
  end
  state.blockedSignature = nil
  state.blockedProfile = nil
  return self:BeginPoisonWeaponSwap(wanted, source)
end

function addon:OnPoisonWeaponTargetChanged()
  local state = self:GetPoisonWeaponState()
  state.targetGeneration = state.targetGeneration + 1
  state.pendingTargetSignature = self:GetPoisonWeaponTargetSignature()
  state.targetSettleAt = now() + TARGET_SETTLE_SECONDS
  state.desiredProfile = self:GetDesiredPoisonWeaponProfileId()
  if state.phase ~= "equipping" and state.phase ~= "waiting_combat" then
    state.phase = "target_settling"
    state.message = "Waiting for target to settle."
  end
end

function addon:OnPoisonWeaponInventoryEvent()
  local state = self:GetPoisonWeaponState()
  if state.phase == "blocked" then state.blockedSignature = nil; state.blockedProfile = nil; state.phase = "idle" end
  self:ProcessPoisonWeaponSwap()
end

function addon:PreparePoisonWeaponTransitionForBuilder()
  if not self:GetPoisonWeaponSettings().enabled then return true end
  self:RequestPoisonWeaponProfile("builder", true)
  self:ProcessPoisonWeaponSwap()
  local state = self:GetPoisonWeaponState()
  if state.phase == "blocked" then return true end
  if state.phase == "equipping" or state.phase == "waiting_combat" or state.phase == "target_settling" then return false end
  local wanted = self:GetDesiredPoisonWeaponProfileId()
  return not wanted or self:GetActivePoisonWeaponProfileId() == wanted
end

function addon:IsPoisonWeaponSwapInProgress()
  local phase = self:GetPoisonWeaponState().phase
  return phase == "equipping" or phase == "waiting_combat" or phase == "target_settling"
end

function addon:UpdatePoisonWeapons()
  local state = self:GetPoisonWeaponState()
  local signature = self:GetPoisonWeaponTargetSignature()
  if signature ~= state.lastObservedSignature then state.lastObservedSignature = signature; self:OnPoisonWeaponTargetChanged() end
  if state.phase == "target_settling" and now() >= (state.targetSettleAt or 0) then
    if signature == state.pendingTargetSignature then state.phase = "idle"; self:RequestPoisonWeaponProfile("target_settled", true)
    else self:OnPoisonWeaponTargetChanged() end
  end
  self:ProcessPoisonWeaponSwap()
end

function addon:GetPoisonWeaponStatus()
  local state = self:GetPoisonWeaponState()
  return state.phase .. " - " .. (state.message or "")
end
