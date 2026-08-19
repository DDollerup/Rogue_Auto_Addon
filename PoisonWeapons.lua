local addon = RogueAuto
local coreGetWeaponPoisonName = addon.GetWeaponPoisonName

local PROFILE_NORMAL = "normal"
local PROFILE_DISSOLVENT = "dissolvent"

local dissolventTypes = {
    elemental = true,
    giant = true,
    undead = true,
    mechanical = true,
}

local poisonNames = {
    "Dissolvent Poison",
    "Instant Poison",
    "Deadly Poison",
    "Crippling Poison",
    "Mind-numbing Poison",
    "Wound Poison",
}

local function lower(value)
    return string.lower(value or "")
end

local function now()
    return GetTime and GetTime() or 0
end

local function capture(value, pattern)
    local _, _, result = string.find(value or "", pattern)
    return result
end

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
    if not left or not right then return false end
    return left.itemId == right.itemId
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
    if settings.restoreNormal == nil then settings.restoreNormal = true end
    settings.profiles = settings.profiles or {}
    return settings
end

function addon:GetPoisonWeaponState()
    self.state = self.state or {}
    self.state.poisonWeaponSwap = self.state.poisonWeaponSwap or {
        phase = "idle",
        message = "Ready.",
        activeProfile = nil,
        operations = {},
        index = 1,
        retries = 0,
        waitingForUnlock = false,
        retryAt = 0,
    }
    return self.state.poisonWeaponSwap
end

function addon:GetEquippedPoisonWeapon(slotId)
    return identityFromLink(GetInventoryItemLink("player", slotId))
end

function addon:ReadPoisonWeaponTooltip(setTooltip)
    if not RogueAutoPoisonWeaponTooltip then
        CreateFrame("GameTooltip", "RogueAutoPoisonWeaponTooltip", UIParent, "GameTooltipTemplate")
        RogueAutoPoisonWeaponTooltip:SetOwner(UIParent, "ANCHOR_NONE")
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
        local texts = {
            leftLine and leftLine:GetText() or nil,
            rightLine and rightLine:GetText() or nil,
        }
        local textIndex
        for textIndex = 1, 2 do
            local text = texts[textIndex]
            local parsed = text and self.ExtractWeaponPoisonNameFromText and self:ExtractWeaponPoisonNameFromText(text)
            if parsed then return parsed end
            local normalized = lower(text)
            local poisonIndex
            for poisonIndex = 1, table.getn(poisonNames) do
                if string.find(normalized, lower(poisonNames[poisonIndex]), 1, true) then
                    return poisonNames[poisonIndex]
                end
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
    return self:ReadPoisonWeaponTooltip(function(tooltip)
        tooltip:SetInventoryItem("player", slotId)
    end)
end

function addon:GetBagWeaponPoisonName(bag, slot)
    return self:ReadPoisonWeaponTooltip(function(tooltip)
        tooltip:SetBagItem(bag, slot)
    end)
end

function addon:PoisonWeaponSlotMatches(slotId, identity, poisonName)
    local equipped = self:GetEquippedPoisonWeapon(slotId)
    if not sameItem(equipped, identity) then return false end
    if poisonName and poisonName ~= "" then
        return lower(self:GetWeaponPoisonName(slotId)) == lower(poisonName)
    end
    return sameIdentity(equipped, identity)
end

function addon:CapturePoisonWeaponProfile(profileId)
    if profileId ~= PROFILE_NORMAL and profileId ~= PROFILE_DISSOLVENT then return false end
    local settings = self:GetPoisonWeaponSettings()
    local main = self:GetEquippedPoisonWeapon(16)
    local off = self:GetEquippedPoisonWeapon(17)
    if not main and not off then return false end
    settings.profiles[profileId] = {
        slots = { [16] = main, [17] = off },
        poisons = { [16] = self:GetWeaponPoisonName(16), [17] = self:GetWeaponPoisonName(17) },
    }
    self:GetPoisonWeaponState().message = "Captured " .. profileId .. " weapons."
    self:GetPoisonWeaponState().lastTargetSignature = nil
    self:EvaluatePoisonWeaponTarget()
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
    local currentMain = self:GetEquippedPoisonWeapon(16)
    local currentOff = self:GetEquippedPoisonWeapon(17)
    local ids = { PROFILE_NORMAL, PROFILE_DISSOLVENT }
    local index
    for index = 1, table.getn(ids) do
        local profile = settings.profiles[ids[index]]
        if profile and profile.slots
            and self:PoisonWeaponSlotMatches(16, profile.slots[16], profile.poisons and profile.poisons[16])
            and self:PoisonWeaponSlotMatches(17, profile.slots[17], profile.poisons and profile.poisons[17]) then
            return ids[index]
        end
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
                elseif sameIdentity(candidate, identity) then
                    return bag, slot
                end
            end
        end
    end
    return nil
end

function addon:BeginPoisonWeaponSwap(profileId, reason)
    local settings = self:GetPoisonWeaponSettings()
    local profile = settings.profiles[profileId]
    local state = self:GetPoisonWeaponState()
    if not profile or not profile.slots then
        state.message = "Capture the " .. profileId .. " profile first."
        return false
    end
    if UnitAffectingCombat("player") and not settings.allowCombat then
        state.phase = "waiting_combat"
        state.profileId = profileId
        state.reason = reason
        state.message = "Waiting for combat to end."
        return false
    end
    state.operations = {}
    local slots = { 16, 17 }
    local index
    for index = 1, table.getn(slots) do
        local slotId = slots[index]
        local wanted = profile.slots[slotId]
        local poisonName = profile.poisons and profile.poisons[slotId]
        if wanted and not self:PoisonWeaponSlotMatches(slotId, wanted, poisonName) then
            table.insert(state.operations, { slotId = slotId, identity = wanted, poisonName = poisonName })
        end
    end
    state.profileId = profileId
    state.reason = reason
    state.index = 1
    state.retries = 0
    state.waitingForUnlock = false
    state.retryAt = 0
    if table.getn(state.operations) == 0 then
        state.phase = "idle"
        state.activeProfile = profileId
        state.message = profileId .. " profile equipped."
        return true
    end
    state.phase = "equipping"
    state.message = "Equipping " .. profileId .. " weapons."
    self:ProcessPoisonWeaponSwap()
    return true
end

function addon:ProcessPoisonWeaponSwap()
    local state = self:GetPoisonWeaponState()
    if state.phase == "waiting_combat" then
        if UnitAffectingCombat("player") then return end
        self:BeginPoisonWeaponSwap(state.profileId, state.reason)
        return
    end
    if state.phase ~= "equipping" then return end
    if CursorHasItem and CursorHasItem() then return end
    local operation = state.operations[state.index]
    if not operation then
        state.phase = "idle"
        state.activeProfile = state.profileId
        state.message = state.profileId .. " profile equipped."
        return
    end
    if self:PoisonWeaponSlotMatches(operation.slotId, operation.identity, operation.poisonName) then
        state.index = state.index + 1
        state.retries = 0
        state.waitingForUnlock = false
        state.retryAt = 0
        self:ProcessPoisonWeaponSwap()
        return
    end
    if state.waitingForUnlock and now() < state.retryAt then return end
    state.waitingForUnlock = false
    local bag, slot = self:FindPoisonWeapon(operation.identity, operation.poisonName)
    if bag == nil then
        state.phase = "blocked"
        state.message = "A captured " .. state.profileId .. " weapon is not in your bags."
        return
    end
    PickupContainerItem(bag, slot)
    EquipCursorItem(operation.slotId)
    state.retries = state.retries + 1
    state.waitingForUnlock = true
    state.retryAt = now() + 0.75
    if state.retries > 3 then
        state.phase = "blocked"
        state.message = "Could not equip the " .. state.profileId .. " weapons."
    end
end

function addon:GetDesiredPoisonWeaponProfileId()
    local settings = self:GetPoisonWeaponSettings()
    if not settings.enabled then return nil end
    if UnitExists("target") and UnitCanAttack("player", "target") then
        local creatureType = lower(UnitCreatureType("target"))
        if dissolventTypes[creatureType] and settings.profiles[PROFILE_DISSOLVENT] then
            return PROFILE_DISSOLVENT
        end
    end
    if settings.restoreNormal and settings.profiles[PROFILE_NORMAL] then return PROFILE_NORMAL end
    return nil
end

function addon:GetUsablePoisonWeaponProfileId()
    return self:GetDesiredPoisonWeaponProfileId()
end

function addon:EvaluatePoisonWeaponTarget()
    local settings = self:GetPoisonWeaponSettings()
    if not settings.enabled then return true end
    local wanted = self:GetUsablePoisonWeaponProfileId()
    if not wanted then return true end
    if self:GetActivePoisonWeaponProfileId() ~= wanted then
        return self:BeginPoisonWeaponSwap(wanted, "target")
    end
    return true
end

function addon:PreparePoisonWeaponsForBuilder(context)
    local settings = self:GetPoisonWeaponSettings()
    if not settings.enabled then return true end
    self:ProcessPoisonWeaponSwap()
    local state = self:GetPoisonWeaponState()
    if state.phase == "equipping" or state.phase == "waiting_combat" then return false end
    local wanted = self:GetUsablePoisonWeaponProfileId()
    if wanted and self:GetActivePoisonWeaponProfileId() ~= wanted then
        self:BeginPoisonWeaponSwap(wanted, "builder")
        return false
    end
    return true
end

function addon:UpdatePoisonWeapons()
    self:ProcessPoisonWeaponSwap()
    local state = self:GetPoisonWeaponState()
    local signature = "none"
    if UnitExists("target") then
        signature = lower(UnitName("target")) .. "|" .. lower(UnitCreatureType("target"))
    end
    if signature ~= state.lastTargetSignature then
        state.lastTargetSignature = signature
        self:EvaluatePoisonWeaponTarget()
    end
end

function addon:GetPoisonWeaponStatus()
    local state = self:GetPoisonWeaponState()
    return state.phase .. " - " .. (state.message or "")
end
