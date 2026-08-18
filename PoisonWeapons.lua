local addon = RogueAuto

local PROFILE_NORMAL = "normal"
local PROFILE_DISSOLVENT = "dissolvent"
local RESIST_WINDOW = 8
local RESIST_THRESHOLD = 3

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

local function targetKey()
    if not UnitExists("target") then return nil end
    local name = UnitName("target")
    if not name or name == "" then return nil end
    return lower(name)
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
    }
    self.state.poisonImmunities = self.state.poisonImmunities or {}
    self.state.poisonResistanceEvidence = self.state.poisonResistanceEvidence or {}
    return self.state.poisonWeaponSwap
end

function addon:GetEquippedPoisonWeapon(slotId)
    return identityFromLink(GetInventoryItemLink("player", slotId))
end

function addon:GetWeaponPoisonName(slotId)
    if not RogueAutoPoisonWeaponTooltip then
        CreateFrame("GameTooltip", "RogueAutoPoisonWeaponTooltip", UIParent, "GameTooltipTemplate")
        RogueAutoPoisonWeaponTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    RogueAutoPoisonWeaponTooltip:ClearLines()
    RogueAutoPoisonWeaponTooltip:SetInventoryItem("player", slotId)
    local fallback = nil
    local index
    for index = 1, 12 do
        local line = getglobal("RogueAutoPoisonWeaponTooltipTextLeft" .. index)
        local text = line and line:GetText()
        if text then
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
    return true
end

function addon:GetPoisonWeaponProfileSummary(profileId)
    local profile = self:GetPoisonWeaponSettings().profiles[profileId]
    if not profile then return "Not captured" end
    local main = profile.slots and profile.slots[16]
    local off = profile.slots and profile.slots[17]
    local mainText = main and main.link or "Empty"
    local offText = off and off.link or "Empty"
    return "Main: " .. mainText .. "\nOff: " .. offText
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
            and sameIdentity(currentMain, profile.slots[16])
            and sameIdentity(currentOff, profile.slots[17]) then
            return ids[index]
        end
    end
    return nil
end

function addon:FindPoisonWeapon(identity)
    if not identity then return nil end
    local bag
    for bag = 0, 4 do
        local slot
        for slot = 1, GetContainerNumSlots(bag) do
            local candidate = identityFromLink(GetContainerItemLink(bag, slot))
            if sameIdentity(candidate, identity) then return bag, slot end
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
        if wanted and not sameIdentity(self:GetEquippedPoisonWeapon(slotId), wanted) then
            table.insert(state.operations, { slotId = slotId, identity = wanted })
        end
    end
    state.profileId = profileId
    state.reason = reason
    state.index = 1
    state.retries = 0
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
    if sameIdentity(self:GetEquippedPoisonWeapon(operation.slotId), operation.identity) then
        state.index = state.index + 1
        state.retries = 0
        self:ProcessPoisonWeaponSwap()
        return
    end
    local bag, slot = self:FindPoisonWeapon(operation.identity)
    if bag == nil then
        state.phase = "blocked"
        state.message = "A captured " .. state.profileId .. " weapon is not in your bags."
        return
    end
    PickupContainerItem(bag, slot)
    EquipCursorItem(operation.slotId)
    state.retries = state.retries + 1
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

function addon:IsPoisonProfileImmune(profileId)
    local key = targetKey()
    local records = key and self.state and self.state.poisonImmunities and self.state.poisonImmunities[key]
    return records and records[profileId] ~= nil
end

function addon:GetUsablePoisonWeaponProfileId()
    local desired = self:GetDesiredPoisonWeaponProfileId()
    if not desired then return nil end
    if not self:IsPoisonProfileImmune(desired) then return desired end
    local alternate = desired == PROFILE_NORMAL and PROFILE_DISSOLVENT or PROFILE_NORMAL
    if self:GetPoisonWeaponSettings().profiles[alternate] and not self:IsPoisonProfileImmune(alternate) then
        return alternate
    end
    return nil
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

function addon:PreparePoisonWeaponsForBuilder()
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
end

function addon:GetPoisonWeaponStatus()
    local state = self:GetPoisonWeaponState()
    return state.phase .. " - " .. (state.message or "")
end

function addon:IsPoisonImmunitySpell(name)
    local value = lower(name)
    return string.find(value, "poison", 1, true) ~= nil or value == "envenom" or value == "noxious assault"
end

function addon:IsPositivePoisonEvidenceSpell(name)
    return self:IsPoisonImmunitySpell(name)
end

function addon:GetPoisonImmunityKey()
    return targetKey()
end

function addon:ClearTargetPoisonImmunity()
    local key = targetKey()
    if key and self.state and self.state.poisonImmunities then self.state.poisonImmunities[key] = nil end
    if self.state then self.state.poisonImmunity = nil end
    if self.UpdatePoisonImmunityFrame then self:UpdatePoisonImmunityFrame() end
end

function addon:IsCurrentTargetPoisonImmune()
    local desired = self:GetDesiredPoisonWeaponProfileId() or self:GetActivePoisonWeaponProfileId() or PROFILE_NORMAL
    if not self:IsPoisonProfileImmune(desired) then return false end
    local alternate = desired == PROFILE_NORMAL and PROFILE_DISSOLVENT or PROFILE_NORMAL
    local profiles = self:GetPoisonWeaponSettings().profiles
    return not profiles[alternate] or self:IsPoisonProfileImmune(alternate)
end

function addon:MarkCurrentTargetPoisonImmune(spellName)
    local key = targetKey()
    if not key then return end
    local profileId = self:GetActivePoisonWeaponProfileId() or self:GetDesiredPoisonWeaponProfileId() or PROFILE_NORMAL
    self:GetPoisonWeaponState()
    self.state.poisonImmunities[key] = self.state.poisonImmunities[key] or {}
    self.state.poisonImmunities[key][profileId] = { spell = spellName, time = now() }
    self.state.poisonImmunity = { target = key, spell = spellName, profile = profileId }
    if self.DebugEvent then self:DebugEvent("poison_immunity_remembered", UnitName("target") or key, spellName or "poison") end
    self:EvaluatePoisonWeaponTarget()
    if self.UpdatePoisonImmunityFrame then self:UpdatePoisonImmunityFrame() end
end

function addon:ExtractPoisonImmunityEvidence(message)
    local spell = capture(message, "Your (.-) was immune")
    if not spell then spell = capture(message, "Your (.-) is immune") end
    if spell and self:IsPoisonImmunitySpell(spell) then return spell end
    return nil
end

function addon:ExtractPositivePoisonEvidence(message)
    local spell = capture(message, "Your (.-) hits") or capture(message, "Your (.-) crits")
    if spell and self:IsPositivePoisonEvidenceSpell(spell) then return spell end
    return nil
end

function addon:RecordPoisonResistance(spellName)
    local key = targetKey()
    if not key then return false end
    local profileId = self:GetActivePoisonWeaponProfileId() or PROFILE_NORMAL
    local evidenceKey = key .. "|" .. profileId .. "|" .. lower(spellName)
    local evidence = self.state.poisonResistanceEvidence[evidenceKey]
    local current = now()
    if not evidence or current - evidence.started > RESIST_WINDOW then evidence = { count = 0, started = current } end
    evidence.count = evidence.count + 1
    self.state.poisonResistanceEvidence[evidenceKey] = evidence
    return evidence.count >= RESIST_THRESHOLD
end

function addon:ClearPoisonResistanceEvidence(spellName)
    local key = targetKey()
    if not key then return end
    local profileId = self:GetActivePoisonWeaponProfileId() or PROFILE_NORMAL
    self.state.poisonResistanceEvidence[key .. "|" .. profileId .. "|" .. lower(spellName)] = nil
end

function addon:MarkRecentPoisonAttemptImmune()
    local spell = self.state and self.state.lastPoisonAttempt
    if spell then self:MarkCurrentTargetPoisonImmune(spell) end
end

function addon:OnPoisonCombatMessage(message)
    local immuneSpell = self:ExtractPoisonImmunityEvidence(message)
    if immuneSpell then
        self:MarkCurrentTargetPoisonImmune(immuneSpell)
        return
    end
    local resistedSpell = capture(message, "Your (.-) was resisted")
    if resistedSpell and self:IsPoisonImmunitySpell(resistedSpell) and self:RecordPoisonResistance(resistedSpell) then
        self:MarkCurrentTargetPoisonImmune(resistedSpell)
        return
    end
    local positiveSpell = self:ExtractPositivePoisonEvidence(message)
    if positiveSpell then self:ClearPoisonResistanceEvidence(positiveSpell) end
end

function addon:OnPoisonUiError(message)
    if lower(message) == "immune" then self:MarkRecentPoisonAttemptImmune() end
end
