local addon = RogueAuto

addon.roleplayGlobalCooldown = 8
addon.roleplayEventCooldown = 20

addon.roleplaySpellEvents = {
  ["ambush"] = "ambush",
  ["blind"] = "blind",
  ["cheap shot"] = "cheap_shot",
  ["envenom"] = "envenom",
  ["eviscerate"] = "eviscerate",
  ["garrote"] = "garrote",
  ["gouge"] = "gouge",
  ["sap"] = "sap",
  ["shoot"] = "ranged",
  ["shoot bow"] = "ranged",
  ["shoot crossbow"] = "ranged",
  ["shoot gun"] = "ranged",
  ["throw"] = "ranged",
}

addon.roleplayPhrases = {
  silent = {
    pick_success = {
      "relieves {target} of an unnecessary burden.",
      "leaves {target}'s purse lighter without disturbing the silence.",
      "makes a quiet inventory of {target}'s valuables.",
    },
    pick_empty = {
      "searches {target} with practiced discretion and finds only disappointment.",
      "withdraws an empty hand from {target}'s thoroughly unremarkable pockets.",
      "finds that {target} carries nothing worth stealing.",
    },
    pick_failure = {
      "withdraws a hand as though nothing happened.",
      "abandons the attempt with an unreadable expression.",
      "steps away from {target}'s pockets without a word.",
    },
    envenom = {
      "draws a sickly sheen across the blade before striking {target}.",
      "delivers a carefully measured dose to {target}.",
      "lets the poison finish the sentence.",
    },
    eviscerate = {
      "strikes precisely where {target}'s guard parts.",
      "finds the shortest path through {target}'s defenses.",
      "ends the exchange with a single measured cut.",
    },
    kick = {
      "silences {target} with economical force.",
      "cuts {target}'s incantation short.",
      "allows {target}'s spell no final word.",
    },
    gouge = {
      "steals {target}'s attention with a vicious feint.",
      "leaves {target} clutching at a suddenly useless eye.",
      "buys a quiet moment at {target}'s expense.",
    },
    blind = {
      "casts dust across {target}'s sight and disappears from focus.",
      "leaves {target} staring into sudden darkness.",
      "removes {target}'s vision from the equation.",
    },
    ambush = {
      "steps from nowhere and strikes {target} without warning.",
      "turns a patch of shadow into a blade at {target}'s back.",
      "makes the first cut before {target} knows the fight has begun.",
    },
    garrote = {
      "draws a silent line across {target}'s throat.",
      "closes a wire around {target}'s voice.",
      "emerges behind {target} with a cord already drawn tight.",
    },
    cheap_shot = {
      "opens the engagement where {target} is least prepared.",
      "strikes {target} before honor has time to object.",
      "uses surprise with clinical efficiency.",
    },
    vanish = {
      "folds into the shadows and is simply gone.",
      "leaves only an uncertain movement in the dark.",
      "steps out of sight as though the world forgot to watch.",
    },
    sap = {
      "eases {target} into an inconvenient sleep.",
      "puts {target}'s awareness gently out of service.",
      "leaves {target} standing, breathing, and entirely absent.",
    },
    ranged = {
      "sends a precise warning across the distance to {target}.",
      "measures the range once and strikes {target} cleanly.",
      "places a shot exactly where {target} left an opening.",
    },
    victory = {
      "cleans the blade and lets the silence return.",
      "regards the fallen foe, then quietly moves on.",
      "leaves the final word to the settling dust.",
    },
  },
  scoundrel = {
    pick_success = {
      "checks {target}'s pockets for loose morals.",
      "helps {target} travel a little lighter.",
      "borrows something from {target} with no tedious paperwork.",
      "performs an unsolicited audit of {target}'s pockets and pockets the findings.",
      "upgrades {target} to the lighter, more aerodynamic model.",
      "removes several coins from {target} in the interest of public safety.",
      "borrows from {target} under extremely flexible repayment terms.",
    },
    pick_empty = {
      "finds {target}'s pockets as empty as their prospects.",
      "searches {target} and looks personally insulted by the results.",
      "discovers that {target} has already spent the interesting money.",
      "searches {target} and discovers that even the lint has moved out.",
      "finds an IOU addressed to 'the next thief.'",
      "returns {target}'s lint out of professional courtesy.",
      "checks the other pocket in case poverty was merely asymmetrical.",
    },
    pick_failure = {
      "looks deeply offended that {target} noticed.",
      "snatches the hand back and whistles innocently.",
      "insists the whole thing was merely a tailoring inspection.",
      "withdraws a hand holding a note that reads, 'This could have been a robbery.'",
      "claims to have been measuring {target} for emergency trousers.",
      "looks appalled to discover that {target} considers pockets private property.",
      "whistles innocently with all the confidence of someone who cannot whistle.",
    },
    envenom = {
      "adds a little something special before introducing the blade to {target}.",
      "serves {target} a house blend with a poisonous finish.",
      "gives {target} a taste of the expensive poison.",
      "seasons the blade and assures {target} that the ingredients are locally sourced.",
      "applies a poison labelled 'Probably Fine.'",
      "offers {target} a complimentary tasting of the house venom.",
      "mentions that the antidote is available in the considerably more expensive package.",
    },
    eviscerate = {
      "collects a particularly personal debt from {target}.",
      "demonstrates the sharp end of a very short negotiation.",
      "offers {target} a close look at expert knife work.",
      "installs an additional ventilation opening in {target}.",
      "submits {target}'s resignation in triplicate, using a knife.",
      "demonstrates the important distinction between cutpurse and purse-cutter.",
      "concludes negotiations with the traditional aggressive punctuation.",
    },
    kick = {
      "objects to {target}'s speech with a well-placed boot.",
      "cancels {target}'s magical performance without requesting a refund.",
      "reminds {target} that casting requires uninterrupted concentration.",
      "delivers an expedited cancellation notice to {target}'s spell.",
      "denies {target} planning permission for further magic.",
      "reminds {target} that uninterrupted casting was never included in the contract.",
      "returns {target}'s spell to the sender, unfinished and slightly dented.",
    },
    gouge = {
      "wins the staring contest rather decisively.",
      "gives {target} something new to complain about.",
      "points out a flaw in {target}'s eye protection.",
      "attempts to steal {target}'s eye and settles for the attention.",
      "performs an unscheduled warranty check on {target}'s depth perception.",
      "points out something fascinating immediately behind {target}'s eyeball.",
      "temporarily reduces {target}'s available viewing options.",
    },
    blind = {
      "throws a little mystery directly into {target}'s eyes.",
      "temporarily removes {target} from the audience.",
      "leaves {target} wondering where everyone went.",
      "enrolls {target} in a complimentary trial of premium darkness.",
      "deploys a carefully curated selection of artisanal pocket dust.",
      "turns down the brightness on {target} without asking.",
      "helps {target} appreciate the fight from an entirely audio-based perspective.",
    },
    ambush = {
      "appears behind {target} right on the punchline.",
      "introduces {target} to the unpleasant side of surprise.",
      "arrives unannounced and immediately overstays the welcome.",
      "enters the conversation through the rear entrance.",
      "appears behind {target} for a surprise performance review.",
      "arrives without an appointment and immediately begins the examination.",
      "demonstrates that personal space is mostly a matter of opinion.",
    },
    garrote = {
      "helps {target} keep the next complaint brief.",
      "tightens the conversation around {target}'s throat.",
      "suggests that {target} save their breath.",
      "adjusts {target}'s collar to formal combat standards.",
      "helps {target} discover a much quieter indoor voice.",
      "tightens the discussion until {target} runs out of counterarguments.",
      "offers {target} a necklace from the extremely limited strangulation collection.",
    },
    cheap_shot = {
      "fights dirty because clean fighting costs extra.",
      "strikes {target} below both the belt and expectations.",
      "demonstrates why rules are best treated as suggestions.",
      "fights at a price everyone can afford.",
      "delivers a blow with no visible fees, only hidden ones.",
      "proves that honor is simply another unnecessary operating expense.",
      "strikes below both the belt and the recommended retail price.",
    },
    vanish = {
      "remembers an urgent appointment somewhere less dangerous.",
      "disappears before anyone can discuss the bill.",
      "steps behind a convenient piece of nowhere.",
      "remembers an urgent appointment on another continent.",
      "demonstrates the advanced technique of becoming someone else's problem.",
      "leaves abruptly, pursued by consequences and several unpaid invoices.",
      "disappears before anyone can assign blame correctly.",
    },
    sap = {
      "invites {target} to take an unscheduled nap.",
      "puts {target}'s thoughts on a brief holiday.",
      "politely switches {target} off for a moment.",
      "schedules {target} for an immediate and mandatory nap.",
      "conducts a surprise pillow inspection without providing a pillow.",
      "places {target} on temporary leave, minus the pay.",
      "switches {target} off and looks around for the instruction manual.",
    },
    ranged = {
      "sends {target} a sharp little note by air mail.",
      "makes a long-distance introduction to {target}.",
      "throws good manners and sharp objects at {target} from afar.",
      "sends {target} a strongly worded projectile.",
      "files a complaint with {target} by air mail.",
      "participates in the violence remotely.",
      "sends {target} something sharp with postage due.",
    },
    victory = {
      "checks the fallen foe for a gratuity.",
      "takes a bow for an audience that may not have asked.",
      "dusts off both hands as though that settled everything.",
      "checks the fallen foe for a receipt, because surely this can be returned.",
      "marks the matter 'Resolved' on an imaginary clipboard.",
      "bows to an audience that has become noticeably less responsive.",
      "dusts off both hands and announces absolutely nothing, professionally.",
    },
  },
  venom = {
    pick_success = {
      "leaves {target} lighter and none the wiser.",
      "takes payment from {target} before the poison is mixed.",
      "harvests a small tribute from {target}'s pockets.",
    },
    pick_empty = {
      "finds nothing in {target}'s pockets worth contaminating.",
      "searches {target} and finds only the stale scent of poverty.",
      "withdraws an empty hand and a colder expression.",
    },
    pick_failure = {
      "regards {target} with cold, offended silence.",
      "withdraws slowly, already considering a more toxic approach.",
      "lets the failed theft become a quiet promise.",
    },
    envenom = {
      "coaxes venom down the blade in glistening threads.",
      "feeds {target} a patient and carefully cultured toxin.",
      "lets poison bloom beneath {target}'s skin.",
    },
    eviscerate = {
      "opens a final red smile across {target}.",
      "carves through {target} with pitiless precision.",
      "draws the blade deep and leaves the wound to speak.",
    },
    kick = {
      "crushes the breath from {target}'s unfinished spell.",
      "breaks {target}'s incantation with a brutal interruption.",
      "turns {target}'s final syllable into a gasp.",
    },
    gouge = {
      "rakes across {target}'s vision with deliberate cruelty.",
      "leaves pain burning behind {target}'s eyes.",
      "marks {target}'s face with a sudden, vicious lesson.",
    },
    blind = {
      "casts a burning veil across {target}'s eyes.",
      "drowns {target}'s sight in stinging darkness.",
      "leaves {target} alone with the dark and the poisoner's breath.",
    },
    ambush = {
      "uncoils from the darkness at {target}'s back.",
      "lets the shadows bite deeply into {target}.",
      "erupts from hiding with the blade already descending.",
    },
    garrote = {
      "draws the cord tight and drinks in {target}'s failing breath.",
      "winds silence around {target}'s throat.",
      "leaves a dark pressure blooming beneath {target}'s jaw.",
    },
    cheap_shot = {
      "strikes where pain arrives before understanding.",
      "folds {target} around a merciless opening blow.",
      "turns surprise into agony without hesitation.",
    },
    vanish = {
      "dissolves into shadow like poison into blood.",
      "leaves the darkness holding an empty shape.",
      "fades from sight while danger lingers behind.",
    },
    sap = {
      "presses {target}'s awareness down into dreamless dark.",
      "steals the waking world from {target} for a moment.",
      "leaves {target}'s mind drifting beyond reach.",
    },
    ranged = {
      "sends a sharpened omen hissing toward {target}.",
      "reaches across the distance to mark {target} for pain.",
      "lets steel carry a dark promise to {target}.",
    },
    victory = {
      "watches the last breath fade with quiet satisfaction.",
      "wipes the blade clean while the poison finishes its work.",
      "stands over the fallen as still as gathering shadow.",
    },
  },
}

local function normalizeName(name)
  if not name or name == "" then
    return nil
  end
  return string.lower(name)
end

function addon:GetRoleplayState()
  self.state.roleplay = self.state.roleplay or {}
  self.state.roleplay.lastEventAt = self.state.roleplay.lastEventAt or {}
  self.state.roleplay.lastPhraseIndex = self.state.roleplay.lastPhraseIndex or {}
  return self.state.roleplay
end

function addon:GetRoleplayTargetName(preferred)
  if preferred and preferred ~= "" then
    return preferred
  end
  return UnitName("target") or "the mark"
end

function addon:FormatRoleplayPhrase(text, context)
  local targetName = self:GetRoleplayTargetName(context and context.targetName)
  local formatted = string.gsub(text or "", "{target}", targetName)
  if string.len(formatted) > 255 then
    formatted = string.sub(formatted, 1, 252) .. "..."
  end
  return formatted
end

function addon:ChooseRoleplayPhrase(personality, eventKey)
  local pack = self.roleplayPhrases[personality] or self.roleplayPhrases.silent
  local phrases = pack and pack[eventKey]
  if not phrases or table.getn(phrases) == 0 then
    return nil
  end

  local state = self:GetRoleplayState()
  local phraseKey = personality .. ":" .. eventKey
  local previous = state.lastPhraseIndex[phraseKey]
  local index = math.random(table.getn(phrases))
  if table.getn(phrases) > 1 and index == previous then
    index = math.mod(index, table.getn(phrases)) + 1
  end
  state.lastPhraseIndex[phraseKey] = index
  return phrases[index]
end

function addon:SendRoleplayMessage(message, reportResult)
  if not SendChatMessage then
    if reportResult then
      self:Print("Roleplay send failed: SendChatMessage is unavailable.")
    end
    return false
  end

  local success, errorMessage = pcall(SendChatMessage, message, "EMOTE")
  if not success then
    self:Print("Roleplay send failed: " .. tostring(errorMessage or "unknown client error"))
    return false
  end

  if reportResult then
    self:Print("Roleplay test emote was passed to the EMOTE channel.")
  end
  return true
end

function addon:TryRoleplayEmote(eventKey, context, guaranteed)
  local settings = RogueAutoDB and RogueAutoDB.roleplay
  if not settings or not settings.enabled or not SendChatMessage then
    return false
  end

  local state = self:GetRoleplayState()
  local now = GetTime()
  if state.lastEmoteAt and state.lastEmoteAt > 0
    and now - state.lastEmoteAt < (self.roleplayGlobalCooldown or 8) then
    return false
  end
  if state.lastEventAt[eventKey] and state.lastEventAt[eventKey] > 0
    and now - state.lastEventAt[eventKey] < (self.roleplayEventCooldown or 20) then
    return false
  end

  if not guaranteed then
    local frequency = settings.frequency or 35
    if math.random(100) > frequency then
      return false
    end
  end

  local phrase = self:ChooseRoleplayPhrase(settings.personality or "silent", eventKey)
  if not phrase then
    return false
  end

  local message = self:FormatRoleplayPhrase(phrase, context)
  if not message or message == "" then
    return false
  end

  if not self:SendRoleplayMessage(message, false) then
    return false
  end
  state.lastEmoteAt = now
  state.lastEventAt[eventKey] = now
  return true
end

function addon:PreviewRoleplayEmote()
  self:Print("Running Roleplay emote test...")
  local settings = RogueAutoDB and RogueAutoDB.roleplay
  if not settings or not settings.enabled then
    self:Print("Roleplay emotes are Off. Select On before testing.")
    return false
  end
  local phrase = self:ChooseRoleplayPhrase(settings.personality or "silent", "victory")
  local message = self:FormatRoleplayPhrase(phrase, { targetName = UnitName("target") or "the mark" })
  if not message or message == "" then
    self:Print("No preview phrase is available for the selected personality.")
    return false
  end

  return self:SendRoleplayMessage(message, true)
end

function addon:ExtractRoleplaySpellResult(message)
  if not message or message == "" then
    return nil, nil
  end

  local _, _, spellName, targetName = string.find(message, "^Your (.-) hits (.-) for ")
  if not spellName then
    _, _, spellName, targetName = string.find(message, "^Your (.-) crits (.-) for ")
  end
  if not spellName then
    _, _, spellName, targetName = string.find(message, "^Your (.-) hits (.-)%.?$")
  end
  if not spellName then
    _, _, spellName, targetName = string.find(message, "^Your (.-) crits (.-)%.?$")
  end
  if not spellName then
    _, _, spellName, targetName = string.find(message, "^Your (.-) causes (.-) %d+")
  end
  if spellName then
    return spellName, targetName
  end

  _, _, targetName, spellName = string.find(message, "^(.-) is afflicted by (.-)%.?$")
  return spellName, targetName
end

function addon:OnRoleplayCombatMessage(message)
  if not message or message == "" then
    return
  end

  local lower = string.lower(message)
  local state = self:GetRoleplayState()
  state.lastObservedMessage = message
  if string.find(lower, "your kick", 1, true) and string.find(lower, "interrupt", 1, true) then
    local targetName = UnitName("target")
    local _, _, interruptedTarget = string.find(message, "[Ii]nterrupts (.-)'s ")
    self:TryRoleplayEmote("kick", { targetName = interruptedTarget or targetName }, false)
    return
  end

  local _, _, meleeTarget = string.find(message, "^You hit (.-) for ")
  if not meleeTarget then
    _, _, meleeTarget = string.find(message, "^You crit (.-) for ")
  end
  if not meleeTarget then
    _, _, meleeTarget = string.find(message, "^(.-) suffers %d+ .- damage from your ")
  end
  if meleeTarget then
    state.lastDamageTarget = meleeTarget
    state.lastDamageAt = GetTime()
  end

  local spellName, targetName = self:ExtractRoleplaySpellResult(message)
  local normalizedSpell = normalizeName(spellName)
  if not normalizedSpell then
    local lastAttempt = self.state.lastSpellAttempt
    local recentAttempt = lastAttempt
      and lastAttempt.name
      and lastAttempt.at
      and GetTime() - lastAttempt.at <= 1.5
    local attemptedSpell = recentAttempt and string.lower(lastAttempt.name) or nil
    if attemptedSpell and string.find(lower, attemptedSpell, 1, true) then
      normalizedSpell = attemptedSpell
      targetName = lastAttempt.targetName or targetName
    end
  end
  if normalizedSpell == "kick" then
    local lastAttempt = self.state.lastSpellAttempt
    local recentRotationKick = lastAttempt
      and lastAttempt.name == "Kick"
      and lastAttempt.at
      and GetTime() - lastAttempt.at <= 1.5
    if recentRotationKick then
      state.lastMatchedEvent = "kick"
      self:TryRoleplayEmote("kick", { targetName = targetName or lastAttempt.targetName }, false)
    end
    return
  end
  local eventKey = normalizedSpell and self.roleplaySpellEvents[normalizedSpell]
  if targetName then
    state.lastDamageTarget = targetName
    state.lastDamageAt = GetTime()
  end
  if not eventKey then
    return
  end
  state.lastMatchedEvent = eventKey
  self:TryRoleplayEmote(eventKey, { targetName = targetName }, false)
end

function addon:OnRoleplaySelfBuffMessage(message)
  local lower = string.lower(message or "")
  if string.find(lower, "vanish", 1, true) then
    self:TryRoleplayEmote("vanish", nil, false)
    return
  end

  local lastAttempt = self.state.lastSpellAttempt
  local recentVanishAttempt = lastAttempt
    and lastAttempt.name == "Vanish"
    and lastAttempt.at
    and GetTime() - lastAttempt.at <= 1.5
  local activeCombat = self.IsCombatSessionActive and self:IsCombatSessionActive()
  if string.find(lower, "stealth", 1, true) and (recentVanishAttempt or activeCombat) then
    self:TryRoleplayEmote("vanish", nil, false)
  end
end

function addon:OnRoleplayPickPocketSuccess(wasEmpty, targetName)
  self:TryRoleplayEmote(wasEmpty and "pick_empty" or "pick_success", { targetName = targetName }, true)
end

function addon:OnRoleplayPickPocketFailure(message)
  local lastAttempt = self.state.lastSpellAttempt
  if not self.state.pendingPickPocketTarget
    or not lastAttempt
    or lastAttempt.name ~= "Pick Pocket"
    or not lastAttempt.at
    or GetTime() - lastAttempt.at > 2 then
    return
  end

  local lower = string.lower(message or "")
  if string.find(lower, "out of range", 1, true)
    or string.find(lower, "too far away", 1, true)
    or string.find(lower, "line of sight", 1, true)
    or string.find(lower, "closer", 1, true)
    or string.find(lower, "not enough energy", 1, true)
    or string.find(lower, "not ready", 1, true) then
    return
  end

  self:TryRoleplayEmote("pick_failure", { targetName = lastAttempt.targetName }, true)
end

function addon:ExtractRoleplayDeathTarget(message)
  if not message then
    return nil
  end
  local _, _, targetName = string.find(message, "^(.-) dies%.?$")
  if targetName then
    return targetName
  end
  _, _, targetName = string.find(message, "^You have slain (.-)!?$")
  return targetName
end

function addon:OnRoleplayHostileDeath(message)
  local targetName = self:ExtractRoleplayDeathTarget(message)
  if not targetName then
    return
  end

  local currentTargetName = UnitName("target")
  local state = self:GetRoleplayState()
  local recentlyDamaged = state.lastDamageTarget
    and string.lower(state.lastDamageTarget) == string.lower(targetName)
    and GetTime() - (state.lastDamageAt or 0) <= 2
  local currentTargetDied = currentTargetName and string.lower(currentTargetName) == string.lower(targetName)
  if recentlyDamaged or currentTargetDied then
    self:TryRoleplayEmote("victory", { targetName = targetName }, true)
  end
end

function addon:OnRoleplayCombatEnded()
  if UnitExists("target") and UnitIsDead("target") then
    self:TryRoleplayEmote("victory", { targetName = UnitName("target") }, true)
  end
end
