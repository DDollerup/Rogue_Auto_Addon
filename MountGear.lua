local addon = RogueAuto

addon.mountGearSlots = {
  { id = 8, name = "Feet" },
  { id = 10, name = "Hands" },
  { id = 13, name = "Trinket 1" },
  { id = 14, name = "Trinket 2" },
}

local function getSettings()
  if not RogueAutoDB then
    return nil
  end
  RogueAutoDB.mountGear = RogueAutoDB.mountGear or {}
  RogueAutoDB.mountGear.profile = RogueAutoDB.mountGear.profile or {}
  return RogueAutoDB.mountGear
end

local function getItemIdentity(link)
  if not link then
    return nil
  end

  local _, _, itemId, enchantId, suffixId, uniqueId = string.find(
    link,
    "item:(%d+):(%d+):(%d+):(%d+)"
  )
  if not itemId then
    _, _, itemId = string.find(link, "item:(%d+)")
  end
  if not itemId then
    return nil
  end

  return {
    itemId = tonumber(itemId),
    enchantId = tonumber(enchantId or 0),
    suffixId = tonumber(suffixId or 0),
    uniqueId = tonumber(uniqueId or 0),
    link = link,
  }
end

local function normalizeIdentity(entry)
  if not entry then
    return nil
  end
  if entry.itemId then
    return entry
  end
  return getItemIdentity(entry.link)
end

local function identitiesMatch(left, right)
  left = normalizeIdentity(left)
  right = normalizeIdentity(right)
  if not left or not right or tonumber(left.itemId) ~= tonumber(right.itemId) then
    return false
  end

  if left.enchantId and right.enchantId and tonumber(left.enchantId) ~= tonumber(right.enchantId) then
    return false
  end
  if left.suffixId and right.suffixId and tonumber(left.suffixId) ~= tonumber(right.suffixId) then
    return false
  end
  if left.uniqueId and right.uniqueId and tonumber(left.uniqueId) ~= tonumber(right.uniqueId) then
    return false
  end
  return true
end

local function getInventoryIdentity(slotId)
  if not GetInventoryItemLink then
    return nil
  end
  return getItemIdentity(GetInventoryItemLink("player", slotId))
end

local function findBagItem(identity)
  if not identity or not GetContainerNumSlots or not GetContainerItemLink then
    return nil, nil
  end

  local fallbackBag, fallbackSlot
  local bag
  for bag = 0, 4 do
    local slot
    for slot = 1, (GetContainerNumSlots(bag) or 0) do
      local candidate = getItemIdentity(GetContainerItemLink(bag, slot))
      if candidate and identitiesMatch(candidate, identity) then
        return bag, slot
      end
      if not fallbackBag and candidate and tonumber(candidate.itemId) == tonumber(identity.itemId) then
        fallbackBag, fallbackSlot = bag, slot
      end
    end
  end
  return fallbackBag, fallbackSlot
end

local function findEmptyBagSlot()
  if not GetContainerNumSlots or not GetContainerItemLink then
    return nil, nil
  end
  local bag
  for bag = 0, 4 do
    local slot
    for slot = 1, (GetContainerNumSlots(bag) or 0) do
      if not GetContainerItemLink(bag, slot) then
        return bag, slot
      end
    end
  end
  return nil, nil
end

function addon:EnsureMountGearState()
  self.state.mountGear = self.state.mountGear or {
    phase = "idle",
    mounted = false,
    snapshot = nil,
    operations = nil,
    operationIndex = 1,
    waitingForUnlock = false,
    retryAt = 0,
    retries = 0,
    pendingMode = nil,
    lastError = nil,
    lastMessage = "Idle",
  }
  return self.state.mountGear
end

function addon:IsPlayerMountedForMountGear()
  if IsMounted and IsMounted() then
    return true
  end
  if UnitIsMounted and UnitIsMounted("player") then
    return true
  end
  if not UnitBuff then
    return false
  end

  local index
  for index = 1, 32 do
    local texture, applications, buffId = UnitBuff("player", index)
    if not texture then
      break
    end
    if buffId and self.mountGearAuraIds and self.mountGearAuraIds[tonumber(buffId)] then
      return true
    end

    local tooltipText = ""
    if self.mountGearTooltip and self.mountGearTooltip.SetUnitBuff then
      self.mountGearTooltip:SetUnitBuff("player", index)
      local text1 = getglobal("RogueAutoMountGearTooltipTextLeft1")
      local text2 = getglobal("RogueAutoMountGearTooltipTextLeft2")
      tooltipText = string.lower((text1 and text1:GetText() or "") .. " " .. (text2 and text2:GetText() or ""))
    end

    if string.find(texture, "Mount_")
      or string.find(texture, "QirajiCrystal_")
      or string.find(tooltipText, "riding")
      or string.find(tooltipText, "increases speed")
      or string.find(tooltipText, "speed scales")
      or string.find(tooltipText, "speed based on")
      or string.find(tooltipText, "slow and steady") then
      self:TraceEvent("mount_gear_unknown", index, texture, buffId or "none")
      return true
    end
  end
  return false
end

function addon:MountGearMessage(message)
  local state = self:EnsureMountGearState()
  state.lastMessage = message
  self:TraceEvent("mount_gear_state", state.phase, message)
end

function addon:CaptureMountGearSnapshot()
  local snapshot = {}
  local index
  for index, slotInfo in ipairs(self.mountGearSlots) do
    snapshot[slotInfo.id] = getInventoryIdentity(slotInfo.id) or false
  end
  return snapshot
end

function addon:MountGearProfileReady()
  local settings = getSettings()
  if not settings or settings.enabled ~= true then
    return false
  end
  local index
  for index, slotInfo in ipairs(self.mountGearSlots) do
    if normalizeIdentity(settings.profile[slotInfo.id]) then
      return true
    end
  end
  return false
end

function addon:CaptureMountGearSlot(slotId)
  local settings = getSettings()
  if not settings then
    return false
  end
  local identity = getInventoryIdentity(slotId)
  settings.profile[slotId] = identity
  return identity ~= nil
end

function addon:CaptureMountGearProfile()
  local settings = getSettings()
  if not settings then
    return false
  end
  local captured = 0
  local index
  for index, slotInfo in ipairs(self.mountGearSlots) do
    if self:CaptureMountGearSlot(slotInfo.id) then
      captured = captured + 1
    end
  end
  self:MountGearMessage("Captured " .. tostring(captured) .. " equipped slot(s).")
  return captured > 0
end

function addon:ClearMountGearProfile()
  local settings = getSettings()
  if settings then
    settings.profile = {}
  end
  self:MountGearMessage("Profile cleared.")
end

function addon:BuildMountGearOperations(source)
  local operations = {}
  local index
  for index, slotInfo in ipairs(self.mountGearSlots) do
    local desired = source[slotInfo.id]
    if desired == false then
      desired = nil
      if getInventoryIdentity(slotInfo.id) then
        table.insert(operations, { slot = slotInfo.id, label = slotInfo.name, desired = nil })
      end
    elseif desired and not identitiesMatch(getInventoryIdentity(slotInfo.id), desired) then
      table.insert(operations, { slot = slotInfo.id, label = slotInfo.name, desired = desired })
    end
  end
  return operations
end

function addon:StartMountGearTransaction(phase, source)
  local state = self:EnsureMountGearState()
  state.operations = self:BuildMountGearOperations(source)
  state.operationIndex = 1
  state.waitingForUnlock = false
  state.retryAt = 0
  state.retries = 0
  state.phase = phase
  state.pendingMode = nil
  self:MountGearMessage(phase == "restoring" and "Restoring original gear." or "Equipping mount gear.")
  self:ProcessMountGear()
  return true
end

function addon:BeginMountGearSwap(mode)
  local settings = getSettings()
  local state = self:EnsureMountGearState()
  if not settings or not self:MountGearProfileReady() then
    state.phase = "error"
    state.lastError = "No enabled mount gear profile."
    self:MountGearMessage(state.lastError)
    return false
  end
  if self:IsCombatSessionActive() then
    state.phase = "waiting_combat"
    state.pendingMode = "equip"
    self:MountGearMessage("Waiting for combat to end.")
    return false
  end
  if not state.snapshot then
    state.snapshot = self:CaptureMountGearSnapshot()
  end
  return self:StartMountGearTransaction("equipping", settings.profile)
end

function addon:BeginMountGearRestore()
  local state = self:EnsureMountGearState()
  if not state.snapshot then
    return false
  end
  if self:IsCombatSessionActive() then
    state.phase = "waiting_combat"
    state.pendingMode = "restore"
    self:MountGearMessage("Waiting for combat to end before restoring gear.")
    return false
  end
  return self:StartMountGearTransaction("restoring", state.snapshot)
end

function addon:FinishMountGearTransaction()
  local state = self:EnsureMountGearState()
  state.operations = nil
  state.waitingForUnlock = false
  if state.phase == "restoring" then
    state.snapshot = nil
    state.phase = "idle"
    self:MountGearMessage("Original gear restored.")
  else
    state.phase = "mounted"
    self:MountGearMessage("Mount gear equipped.")
  end
end

function addon:FailMountGearTransaction(message)
  local state = self:EnsureMountGearState()
  state.phase = "error"
  state.lastError = message
  state.operations = nil
  state.waitingForUnlock = false
  self:MountGearMessage(message)
end

function addon:ProcessMountGearStep()
  local state = self:EnsureMountGearState()
  if state.phase ~= "equipping" and state.phase ~= "restoring" then
    return
  end
  if self:IsCombatSessionActive() then
    state.pendingMode = state.phase == "restoring" and "restore" or "equip"
    state.phase = "waiting_combat"
    self:MountGearMessage("Waiting for combat to end.")
    return
  end
  if CursorHasItem and CursorHasItem() then
    return
  end

  local operation = state.operations and state.operations[state.operationIndex]
  if not operation then
    self:FinishMountGearTransaction()
    return
  end

  local current = getInventoryIdentity(operation.slot)
  local complete = operation.desired and identitiesMatch(current, operation.desired) or not operation.desired and not current
  if complete then
    self:TraceEvent("mount_gear_result", operation.label, "equipped")
    state.operationIndex = state.operationIndex + 1
    state.waitingForUnlock = false
    state.retries = 0
    state.retryAt = 0
    return
  end

  if state.waitingForUnlock and GetTime() < state.retryAt then
    return
  end
  if state.waitingForUnlock then
    state.waitingForUnlock = false
    state.retries = state.retries + 1
    if state.retries > 3 then
      self:FailMountGearTransaction("Could not equip " .. operation.label .. ".")
      return
    end
  end

  if operation.desired then
    local bag, bagSlot = findBagItem(operation.desired)
    if not bag then
      self:FailMountGearTransaction(operation.label .. " item is not in the bags.")
      return
    end
    if not PickupContainerItem or not EquipCursorItem then
      self:FailMountGearTransaction("Required equipment APIs are unavailable.")
      return
    end
    self:TraceEvent("mount_gear_attempt", operation.label, bag, bagSlot, operation.slot)
    PickupContainerItem(bag, bagSlot)
    EquipCursorItem(operation.slot)
  else
    local bag, bagSlot = findEmptyBagSlot()
    if not bag or not PickupInventoryItem or not PickupContainerItem then
      self:FailMountGearTransaction("No empty bag slot is available for " .. operation.label .. ".")
      return
    end
    self:TraceEvent("mount_gear_attempt", operation.label, bag, bagSlot, operation.slot)
    PickupInventoryItem(operation.slot)
    PickupContainerItem(bag, bagSlot)
  end

  state.waitingForUnlock = true
  state.retryAt = GetTime() + 0.75
end

function addon:ProcessMountGear()
  local state = self:EnsureMountGearState()
  if state.processing then
    return
  end
  state.processing = true
  local ok, errorMessage = pcall(function() self:ProcessMountGearStep() end)
  state.processing = false
  if not ok then
    self:FailMountGearTransaction("Swap error: " .. tostring(errorMessage))
  end
end

function addon:OnMountGearEvent(eventName, arg1)
  local state = self:EnsureMountGearState()
  if eventName == "PLAYER_AURAS_CHANGED" or eventName == "PLAYER_REGEN_ENABLED" then
    local mounted = self:IsPlayerMountedForMountGear()
    self:TraceEvent("mount_gear_detection", mounted and "mounted" or "not mounted", eventName)
    if mounted ~= state.mounted then
      state.mounted = mounted
      local settings = getSettings()
      if settings and settings.enabled == true and settings.autoSwap == true then
        if mounted then
          self:BeginMountGearSwap("auto")
        elseif state.snapshot then
          self:BeginMountGearRestore()
        end
      end
    end
  end
  self:ProcessMountGear()
end

function addon:UpdateMountGear()
  local state = self:EnsureMountGearState()
  if state.phase == "waiting_combat" and not self:IsCombatSessionActive() then
    if state.pendingMode == "restore" then
      self:BeginMountGearRestore()
    else
      self:BeginMountGearSwap("auto")
    end
    return
  end
  self:ProcessMountGear()
end

function addon:GetMountGearStatus()
  local state = self:EnsureMountGearState()
  return state.phase, state.lastMessage
end

addon.mountGearTooltip = CreateFrame("GameTooltip", "RogueAutoMountGearTooltip", UIParent, "GameTooltipTemplate")
addon.mountGearTooltip:SetOwner(UIParent, "ANCHOR_NONE")
