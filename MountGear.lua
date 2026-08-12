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

local function getItemId(link)
  if not link then
    return nil
  end
  local _, _, id = string.find(link, "item:(%d+)")
  return id and tonumber(id) or nil
end

local function sameItem(link, itemId)
  return link and itemId and getItemId(link) == tonumber(itemId)
end

local function getInventoryLink(slot)
  if not GetInventoryItemLink then
    return nil
  end
  return GetInventoryItemLink("player", slot)
end

local function findBagItem(itemId)
  if not itemId or not GetContainerNumSlots or not GetContainerItemLink then
    return nil, nil
  end

  local bag
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag) or 0
    local slot
    for slot = 1, slots do
      local link = GetContainerItemLink(bag, slot)
      if sameItem(link, itemId) then
        return bag, slot
      end
    end
  end
  return nil, nil
end

local function formatItem(link, itemId)
  if link then
    return link
  end
  return "item " .. tostring(itemId or "none")
end

function addon:EnsureMountGearState()
  self.state.mountGear = self.state.mountGear or {
    phase = "idle",
    mounted = false,
    snapshot = nil,
    pending = nil,
    pendingIndex = 1,
    retryAt = 0,
    retries = 0,
    cursorOwned = false,
    lastError = nil,
    lastMessage = "Idle",
  }
  return self.state.mountGear
end

function addon:IsPlayerMountedForMountGear()
  if IsMounted and IsMounted() then
    return true
  end

  if UnitIsMounted then
    if UnitIsMounted("player") then
      return true
    end
  end

  if not UnitBuff or not self.mountGearTooltip or not self.mountGearTooltip.SetUnitBuff then
    return false
  end

  local index
  for index = 1, 32 do
    local texture, applications, buffId = UnitBuff("player", index)
    if not texture then
      break
    end

    if string.find(texture, "Mount_") then
      return true
    end

    self.mountGearTooltip:SetUnitBuff("player", index)
    local text1 = getglobal("RogueAutoMountGearTooltipTextLeft1")
    local text2 = getglobal("RogueAutoMountGearTooltipTextLeft2")
    local textValue1 = string.lower(text1 and text1:GetText() or "")
    local textValue2 = string.lower(text2 and text2:GetText() or "")
    local tooltipText = textValue1 .. " " .. textValue2
    self:TraceEvent("mount_gear_buff", index, texture, buffId or "none", textValue1, textValue2)
    if string.find(tooltipText, "riding")
      or string.find(tooltipText, "increases speed")
      or string.find(tooltipText, "speed scales")
      or string.find(tooltipText, "speed based on")
      or string.find(tooltipText, "slow and steady") then
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
    local link = getInventoryLink(slotInfo.id)
    snapshot[slotInfo.id] = {
      link = link,
      itemId = getItemId(link),
    }
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
    local entry = settings.profile[slotInfo.id]
    if entry and entry.itemId then
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
  local link = getInventoryLink(slotId)
  if not link then
    settings.profile[slotId] = nil
    return false
  end
  settings.profile[slotId] = { itemId = getItemId(link), link = link }
  return true
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

function addon:BeginMountGearSwap(mode)
  local settings = getSettings()
  local state = self:EnsureMountGearState()
  if not settings or not self:MountGearProfileReady() then
    state.lastError = "No enabled mount gear profile."
    self:MountGearMessage(state.lastError)
    return false
  end
  if self:IsCombatSessionActive() then
    state.phase = "waiting_combat"
    state.pendingMode = mode
    self:MountGearMessage("Waiting for combat to end.")
    return false
  end

  if not state.snapshot then
    state.snapshot = self:CaptureMountGearSnapshot()
  end
  state.pending = {}
  local index
  for index, slotInfo in ipairs(self.mountGearSlots) do
    local entry = settings.profile[slotInfo.id]
    if entry and entry.itemId and not sameItem(getInventoryLink(slotInfo.id), entry.itemId) then
      table.insert(state.pending, { slot = slotInfo.id, itemId = entry.itemId, label = slotInfo.name })
    end
  end
  state.pendingIndex = 1
  state.retries = 0
  state.cursorOwned = false
  state.phase = "equipping"
  state.pendingMode = mode
  self:MountGearMessage("Equipping mount gear.")
  self:ProcessMountGear()
  return true
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

  state.pending = {}
  local index
  for index, slotInfo in ipairs(self.mountGearSlots) do
    local entry = state.snapshot[slotInfo.id]
    if entry and entry.itemId and not sameItem(getInventoryLink(slotInfo.id), entry.itemId) then
      table.insert(state.pending, { slot = slotInfo.id, itemId = entry.itemId, label = slotInfo.name })
    end
  end
  state.pendingIndex = 1
  state.retries = 0
  state.cursorOwned = false
  state.phase = "restoring"
  self:MountGearMessage("Restoring original gear.")
  self:ProcessMountGear()
  return true
end

function addon:ProcessMountGearStep()
  local state = self:EnsureMountGearState()
  if not state.pending or state.pendingIndex > table.getn(state.pending) then
    if state.phase == "restoring" then
      state.snapshot = nil
      state.phase = "idle"
      self:MountGearMessage("Original gear restored.")
    elseif state.phase == "equipping" then
      state.phase = "mounted"
      self:MountGearMessage("Mount gear equipped.")
    end
    state.pending = nil
    return
  end
  if self:IsCombatSessionActive() then
    local pendingMode = state.phase == "restoring" and "restore" or "equip"
    state.phase = "waiting_combat"
    state.pendingMode = pendingMode
    return
  end
  if GetTime() < (state.retryAt or 0) then
    return
  end

  local operation = state.pending[state.pendingIndex]
  if state.cursorOwned and CursorHasItem and CursorHasItem() then
    if EquipCursorItem then
      EquipCursorItem(operation.slot)
      state.retryAt = GetTime() + 0.25
      self:TraceEvent("mount_gear_cursor", operation.label)
      return
    end
  end

  local currentLink = getInventoryLink(operation.slot)
  if sameItem(currentLink, operation.itemId) then
    state.cursorOwned = false
    state.pendingIndex = state.pendingIndex + 1
    state.retries = 0
    self:TraceEvent("mount_gear_result", operation.label, "equipped")
    return
  end

  local bag, bagSlot = findBagItem(operation.itemId)
  if not bag then
    state.lastError = operation.label .. " item is not in the bags."
    state.phase = "error"
    self:MountGearMessage(state.lastError)
    return
  end
  if not PickupContainerItem or not EquipCursorItem then
    state.lastError = "This client does not expose the required equipment API."
    state.phase = "error"
    self:MountGearMessage(state.lastError)
    return
  end

  self:TraceEvent("mount_gear_attempt", operation.label, bag, bagSlot, operation.itemId)
  PickupContainerItem(bag, bagSlot)
  state.cursorOwned = true
  EquipCursorItem(operation.slot)
  state.retries = state.retries + 1
  state.retryAt = GetTime() + 0.25
  if state.retries > 12 then
    state.lastError = "Could not equip " .. formatItem(nil, operation.itemId) .. "."
    state.phase = "error"
    self:MountGearMessage(state.lastError)
  end
end

function addon:ProcessMountGear()
  local state = self:EnsureMountGearState()
  if state.processing then
    return
  end

  state.processing = true
  local ok, errorMessage = pcall(function()
    self:ProcessMountGearStep()
  end)
  state.processing = false

  if not ok then
    state.phase = "error"
    state.lastError = tostring(errorMessage)
    self:MountGearMessage("Swap error: " .. state.lastError)
  end
end

function addon:OnMountGearEvent(eventName, arg1)
  local state = self:EnsureMountGearState()
  if eventName ~= "PLAYER_AURAS_CHANGED" and eventName ~= "PLAYER_REGEN_ENABLED" then
    self:ProcessMountGear()
    return
  end
  local mounted = self:IsPlayerMountedForMountGear()
  self:TraceEvent("mount_gear_detection", mounted and "mounted" or "not mounted", eventName)
  if mounted ~= state.mounted then
    state.mounted = mounted
    if mounted then
      self:MountGearMessage("Mounted aura detected; gear swap is paused for diagnosis.")
    elseif state.snapshot then
      self:MountGearMessage("Dismounted aura detected; gear restore is paused for diagnosis.")
    end
  end
end

function addon:UpdateMountGear()
  local state = self:EnsureMountGearState()
  if state.phase == "waiting_combat" and not self:IsCombatSessionActive() then
    if state.pendingMode == "restore" then
      self:BeginMountGearRestore()
    else
      self:BeginMountGearSwap(state.pendingMode or "equip")
    end
  end
  self:ProcessMountGear()
end

function addon:GetMountGearStatus()
  local state = self:EnsureMountGearState()
  return state.phase, state.lastMessage
end

addon.mountGearTooltip = CreateFrame("GameTooltip", "RogueAutoMountGearTooltip", UIParent, "GameTooltipTemplate")
addon.mountGearTooltip:SetOwner(UIParent, "ANCHOR_NONE")
