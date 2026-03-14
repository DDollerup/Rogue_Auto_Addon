local addon = RogueAuto

SLASH_ROGUEAUTO1 = "/ra"

local frame = CreateFrame("Frame", "RogueAutoConfigFrame", UIParent)
addon.configFrame = frame

frame:SetWidth(360)
frame:SetHeight(420)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function()
  frame:StartMoving()
end)
frame:SetScript("OnDragStop", function()
  frame:StopMovingOrSizing()
end)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -12)
title:SetText("RogueAuto")

local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeButton:SetWidth(70)
closeButton:SetHeight(20)
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
  frame:Hide()
end)

local function makeLabel(text, x, y)
  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  label:SetText(text)
  return label
end

local function makeCheckbox(text, x, y, getter, setter)
  local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  checkbox:SetWidth(20)
  checkbox:SetHeight(20)
  checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  checkbox:SetScript("OnClick", function()
    setter(checkbox:GetChecked() == 1)
  end)

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
  label:SetText(text)

  checkbox.Refresh = function()
    checkbox:SetChecked(getter() and 1 or nil)
  end

  return checkbox
end

local function makeBuilderButton(key, text, x, y)
  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetWidth(74)
  button:SetHeight(18)
  button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  button:SetText(text)
  button:SetScript("OnClick", function()
    RogueAutoDB.builder.mode = key
    addon:RefreshConfig()
  end)
  return button
end

local builderTitle = makeLabel("Builder", 16, -50)
local builderButtons = {
  makeBuilderButton("auto", "Auto", 16, -66),
  makeBuilderButton("sinister", "Sinister", 94, -66),
  makeBuilderButton("hemo", "Hemo", 172, -66),
  makeBuilderButton("backstab", "Backstab", 250, -66),
  makeBuilderButton("noxious", "Noxious", 16, -90),
}

local targetingTitle = makeLabel("Targeting", 16, -128)
local fallbackCheckbox = makeCheckbox("Nearest target fallback", 16, -144, function()
  return RogueAutoDB and RogueAutoDB.targeting.nearestFallback
end, function(value)
  RogueAutoDB.targeting.nearestFallback = value
end)
local autoAttackCheckbox = makeCheckbox("Auto start attack", 16, -168, function()
  return RogueAutoDB and RogueAutoDB.targeting.autoStartAttack
end, function(value)
  RogueAutoDB.targeting.autoStartAttack = value
end)

local stealthTitle = makeLabel("Stealth", 16, -206)
local stealthCheckbox = makeCheckbox("Integrated stealth openers", 16, -222, function()
  return RogueAutoDB and RogueAutoDB.stealth.integrated
end, function(value)
  RogueAutoDB.stealth.integrated = value
end)
local pickPocketCheckbox = makeCheckbox("Pick Pocket humanoids first", 16, -246, function()
  return RogueAutoDB and RogueAutoDB.stealth.pickPocketHumanoids
end, function(value)
  RogueAutoDB.stealth.pickPocketHumanoids = value
end)

local coreTitle = makeLabel("Soft Defensives", 16, -284)
local feintCheckbox = makeCheckbox("Use Feint in DPS buttons", 16, -300, function()
  return RogueAutoDB and RogueAutoDB.core.softDefensives.feint
end, function(value)
  RogueAutoDB.core.softDefensives.feint = value
end)
local ghostlyCheckbox = makeCheckbox("Use Ghostly Strike in DPS buttons", 16, -324, function()
  return RogueAutoDB and RogueAutoDB.core.softDefensives.ghostlyStrike
end, function(value)
  RogueAutoDB.core.softDefensives.ghostlyStrike = value
end)
local flourishCheckbox = makeCheckbox("Use Flourish in DPS buttons", 16, -348, function()
  return RogueAutoDB and RogueAutoDB.core.softDefensives.flourish
end, function(value)
  RogueAutoDB.core.softDefensives.flourish = value
end)

local thresholdsTitle = makeLabel("Thresholds", 16, -386)

local evasionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
evasionLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -404)

local vanishLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
vanishLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 190, -404)

local function refreshBuilderButtons()
  if not RogueAutoDB then
    return
  end

  local active = RogueAutoDB.builder.mode
  for _, button in ipairs(builderButtons) do
    local alpha = 0.55
    if string.lower(button:GetText()) == string.lower(active) then
      alpha = 1
    elseif button:GetText() == "Auto" and active == "auto" then
      alpha = 1
    elseif button:GetText() == "Sinister" and active == "sinister" then
      alpha = 1
    elseif button:GetText() == "Hemo" and active == "hemo" then
      alpha = 1
    elseif button:GetText() == "Backstab" and active == "backstab" then
      alpha = 1
    elseif button:GetText() == "Noxious" and active == "noxious" then
      alpha = 1
    end
    button:SetAlpha(alpha)
  end
end

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
end

local suspendRefresh = false

local evasionSlider = CreateFrame("Slider", "RogueAutoEvasionSlider", frame, "OptionsSliderTemplate")
evasionSlider:SetWidth(140)
evasionSlider:SetHeight(16)
evasionSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -420)
evasionSlider:SetMinMaxValues(5, 100)
evasionSlider:SetValueStep(1)
getglobal(evasionSlider:GetName() .. "Low"):SetText("5")
getglobal(evasionSlider:GetName() .. "High"):SetText("100")
getglobal(evasionSlider:GetName() .. "Text"):SetText("")
evasionSlider:SetScript("OnValueChanged", function()
  if suspendRefresh then
    return
  end
  if RogueAutoDB then
    RogueAutoDB.panic.evasionPct = clamp(math.floor(evasionSlider:GetValue() + 0.5), 5, 100)
    addon:RefreshConfig()
  end
end)

local vanishSlider = CreateFrame("Slider", "RogueAutoVanishSlider", frame, "OptionsSliderTemplate")
vanishSlider:SetWidth(140)
vanishSlider:SetHeight(16)
vanishSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 190, -420)
vanishSlider:SetMinMaxValues(5, 100)
vanishSlider:SetValueStep(1)
getglobal(vanishSlider:GetName() .. "Low"):SetText("5")
getglobal(vanishSlider:GetName() .. "High"):SetText("100")
getglobal(vanishSlider:GetName() .. "Text"):SetText("")
vanishSlider:SetScript("OnValueChanged", function()
  if suspendRefresh then
    return
  end
  if RogueAutoDB then
    RogueAutoDB.panic.vanishPct = clamp(math.floor(vanishSlider:GetValue() + 0.5), 5, 100)
    addon:RefreshConfig()
  end
end)

function addon:RefreshConfig()
  if not RogueAutoDB then
    return
  end

  fallbackCheckbox:Refresh()
  autoAttackCheckbox:Refresh()
  stealthCheckbox:Refresh()
  pickPocketCheckbox:Refresh()
  feintCheckbox:Refresh()
  ghostlyCheckbox:Refresh()
  flourishCheckbox:Refresh()

  refreshBuilderButtons()

  suspendRefresh = true
  evasionSlider:SetValue(RogueAutoDB.panic.evasionPct)
  vanishSlider:SetValue(RogueAutoDB.panic.vanishPct)
  suspendRefresh = false

  evasionLabel:SetText("Evasion: " .. tostring(RogueAutoDB.panic.evasionPct) .. "%")
  vanishLabel:SetText("Vanish: " .. tostring(RogueAutoDB.panic.vanishPct) .. "%")
end

local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 18)
footer:SetText("/script RogueAuto:Bleed()  /script RogueAuto:Direct()")

local footer2 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
footer2:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 6)
footer2:SetText("/script RogueAuto:Interrupt()  /script RogueAuto:Defensive()")

function addon:ToggleConfig()
  self:InitDB()
  if frame:IsShown() then
    frame:Hide()
  else
    self:RefreshConfig()
    frame:Show()
  end
end

local function setDebug(value)
  RogueAutoDB.debug = value
  addon:Print("Debug " .. (value and "enabled" or "disabled") .. ".")
end

local function printHelp()
  addon:Print("/ra opens config.")
  addon:Print("/ra help")
  addon:Print("/ra reset")
  addon:Print("/ra debug on|off")
  addon:Print("/ra builder auto|sinister|hemo|backstab|noxious")
  addon:Print("/ra fallback on|off")
  addon:Print("/ra pickpocket on|off")
  addon:Print("/ra evasion <pct>")
  addon:Print("/ra vanish <pct>")
end

SlashCmdList.ROGUEAUTO = function(message)
  addon:InitDB()

  if not message or message == "" then
    addon:ToggleConfig()
    return
  end

  local args = {}
  for token in string.gfind(message, "%S+") do
    table.insert(args, string.lower(token))
  end

  local command = args[1]
  if command == "help" then
    printHelp()
    return
  end

  if command == "reset" then
    addon:ResetDB()
    addon:RefreshConfig()
    return
  end

  if command == "debug" then
    if args[2] == "on" then
      setDebug(true)
    elseif args[2] == "off" then
      setDebug(false)
    else
      addon:Print("Usage: /ra debug on|off")
    end
    return
  end

  if command == "builder" then
    if addon.builderModes[args[2]] or args[2] == "auto" then
      RogueAutoDB.builder.mode = args[2]
      addon:RefreshConfig()
      addon:Print("Builder set to " .. args[2] .. ".")
    else
      addon:Print("Usage: /ra builder auto|sinister|hemo|backstab|noxious")
    end
    return
  end

  if command == "fallback" then
    if args[2] == "on" then
      RogueAutoDB.targeting.nearestFallback = true
    elseif args[2] == "off" then
      RogueAutoDB.targeting.nearestFallback = false
    else
      addon:Print("Usage: /ra fallback on|off")
      return
    end
    addon:RefreshConfig()
    addon:Print("Nearest fallback " .. (RogueAutoDB.targeting.nearestFallback and "enabled" or "disabled") .. ".")
    return
  end

  if command == "pickpocket" then
    if args[2] == "on" then
      RogueAutoDB.stealth.pickPocketHumanoids = true
    elseif args[2] == "off" then
      RogueAutoDB.stealth.pickPocketHumanoids = false
    else
      addon:Print("Usage: /ra pickpocket on|off")
      return
    end
    addon:RefreshConfig()
    addon:Print("Pick Pocket opener " .. (RogueAutoDB.stealth.pickPocketHumanoids and "enabled" or "disabled") .. ".")
    return
  end

  if command == "evasion" then
    local value = tonumber(args[2])
    if not value then
      addon:Print("Usage: /ra evasion <pct>")
      return
    end
    RogueAutoDB.panic.evasionPct = clamp(math.floor(value + 0.5), 5, 100)
    addon:RefreshConfig()
    addon:Print("Evasion threshold set to " .. tostring(RogueAutoDB.panic.evasionPct) .. "%.")
    return
  end

  if command == "vanish" then
    local value = tonumber(args[2])
    if not value then
      addon:Print("Usage: /ra vanish <pct>")
      return
    end
    RogueAutoDB.panic.vanishPct = clamp(math.floor(value + 0.5), 5, 100)
    addon:RefreshConfig()
    addon:Print("Vanish threshold set to " .. tostring(RogueAutoDB.panic.vanishPct) .. "%.")
    return
  end

  addon:Print("Unknown command. Use /ra help")
end
