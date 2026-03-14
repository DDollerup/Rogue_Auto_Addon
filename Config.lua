local addon = RogueAuto

SLASH_ROGUEAUTO1 = "/ra"

local frame = CreateFrame("Frame", "RogueAutoConfigFrame", UIParent)
addon.configFrame = frame

frame:SetWidth(430)
frame:SetHeight(520)
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
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -10)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
  frame:Hide()
end)

local scrollFrame = CreateFrame("ScrollFrame", "RogueAutoScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -42)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 14)

local scrollChild = CreateFrame("Frame", "RogueAutoScrollChild", scrollFrame)
scrollChild:SetWidth(360)
scrollChild:SetHeight(860)
scrollFrame:SetScrollChild(scrollChild)

local scrollBar = getglobal("RogueAutoScrollFrameScrollBar")
scrollBar:SetValueStep(20)

local function updateScrollBounds()
  local visibleHeight = scrollFrame:GetHeight()
  local contentHeight = scrollChild:GetHeight()
  local maxScroll = 0

  if contentHeight > visibleHeight then
    maxScroll = contentHeight - visibleHeight
  end

  scrollBar:SetMinMaxValues(0, maxScroll)
  if scrollBar:GetValue() > maxScroll then
    scrollBar:SetValue(maxScroll)
  end

  if maxScroll > 0 then
    scrollBar:Show()
  else
    scrollBar:Hide()
  end
end

scrollBar:SetScript("OnValueChanged", function()
  scrollFrame:SetVerticalScroll(scrollBar:GetValue())
end)

local function makeLabel(parent, text, x, y, font)
  local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  label:SetText(text)
  return label
end

local function makeCheckbox(parent, text, x, y, getter, setter)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkbox:SetWidth(20)
  checkbox:SetHeight(20)
  checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  checkbox:SetScript("OnClick", function()
    setter(checkbox:GetChecked() == 1)
  end)

  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
  label:SetText(text)

  checkbox.Refresh = function()
    checkbox:SetChecked(getter() and 1 or nil)
  end

  return checkbox
end

local function makeMacroField(parent, macroText, description, x, y, width)
  local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  desc:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  desc:SetText(description)
  desc:SetWidth(width)
  desc:SetJustifyH("LEFT")

  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetWidth(width)
  box:SetHeight(20)
  box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 18)
  box:SetAutoFocus(false)
  box:SetText(macroText)
  box:SetCursorPosition(0)
  box:SetScript("OnEscapePressed", function()
    box:ClearFocus()
  end)
  box:SetScript("OnEditFocusGained", function()
    box:HighlightText()
  end)
  box:SetScript("OnEditFocusLost", function()
    box:HighlightText(0, 0)
    box:SetText(macroText)
    box:SetCursorPosition(0)
  end)

  return box, desc
end

local function makeBuilderButton(key, text, x, y)
  local button = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
  button:SetWidth(78)
  button:SetHeight(20)
  button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x, y)
  button:SetText(text)
  button.key = key
  button:SetScript("OnClick", function()
    RogueAutoDB.builder.mode = key
    addon:RefreshConfig()
  end)
  return button
end

local builderButtons = {}
local debugCheckbox

makeLabel(scrollChild, "Builder", 8, -8)
table.insert(builderButtons, makeBuilderButton("auto", "Auto", 8, -30))
table.insert(builderButtons, makeBuilderButton("sinister", "Sinister", 94, -30))
table.insert(builderButtons, makeBuilderButton("hemo", "Hemo", 180, -30))
table.insert(builderButtons, makeBuilderButton("backstab", "Backstab", 266, -30))
table.insert(builderButtons, makeBuilderButton("noxious", "Noxious", 8, -56))

makeLabel(scrollChild, "Targeting", 8, -98)
local fallbackCheckbox = makeCheckbox(scrollChild, "Nearest target fallback", 8, -120, function()
  return RogueAutoDB and RogueAutoDB.targeting.nearestFallback
end, function(value)
  RogueAutoDB.targeting.nearestFallback = value
end)

local autoAttackCheckbox = makeCheckbox(scrollChild, "Auto start attack", 8, -146, function()
  return RogueAutoDB and RogueAutoDB.targeting.autoStartAttack
end, function(value)
  RogueAutoDB.targeting.autoStartAttack = value
end)

makeLabel(scrollChild, "Stealth", 8, -188)
local stealthCheckbox = makeCheckbox(scrollChild, "Integrated stealth openers", 8, -210, function()
  return RogueAutoDB and RogueAutoDB.stealth.integrated
end, function(value)
  RogueAutoDB.stealth.integrated = value
end)

local pickPocketCheckbox = makeCheckbox(scrollChild, "Pick Pocket humanoids first", 8, -236, function()
  return RogueAutoDB and RogueAutoDB.stealth.pickPocketHumanoids
end, function(value)
  RogueAutoDB.stealth.pickPocketHumanoids = value
end)

makeLabel(scrollChild, "Buff Upkeep", 8, -278)
local sndCheckbox = makeCheckbox(scrollChild, "Maintain Slice and Dice", 8, -300, function()
  return RogueAutoDB and RogueAutoDB.core.keepSliceAndDice
end, function(value)
  RogueAutoDB.core.keepSliceAndDice = value
end)

makeLabel(scrollChild, "Soft Defensives", 8, -342)
local feintCheckbox = makeCheckbox(scrollChild, "Use Feint in DPS buttons", 8, -300, function()
  return RogueAutoDB and RogueAutoDB.core.softDefensives.feint
end, function(value)
  RogueAutoDB.core.softDefensives.feint = value
end)

feintCheckbox:ClearAllPoints()
feintCheckbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, -364)

local ghostlyCheckbox = makeCheckbox(scrollChild, "Use Ghostly Strike in DPS buttons", 8, -390, function()
  return RogueAutoDB and RogueAutoDB.core.softDefensives.ghostlyStrike
end, function(value)
  RogueAutoDB.core.softDefensives.ghostlyStrike = value
end)

local flourishCheckbox = makeCheckbox(scrollChild, "Use Flourish in DPS buttons", 8, -416, function()
  return RogueAutoDB and RogueAutoDB.core.softDefensives.flourish
end, function(value)
  RogueAutoDB.core.softDefensives.flourish = value
end)

makeLabel(scrollChild, "Interrupt", 8, -458)
local blindCheckbox = makeCheckbox(scrollChild, "Allow Blind in interrupt button", 8, -480, function()
  return RogueAutoDB and RogueAutoDB.interrupt.useBlind
end, function(value)
  RogueAutoDB.interrupt.useBlind = value
end)

local kidneyLabel = makeLabel(scrollChild, "", 8, -510, "GameFontHighlightSmall")
local kidneySlider = CreateFrame("Slider", "RogueAutoKidneySlider", scrollChild, "OptionsSliderTemplate")
kidneySlider:SetWidth(220)
kidneySlider:SetHeight(16)
kidneySlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, -526)
kidneySlider:SetMinMaxValues(1, 5)
kidneySlider:SetValueStep(1)
getglobal(kidneySlider:GetName() .. "Low"):SetText("1")
getglobal(kidneySlider:GetName() .. "High"):SetText("5")
getglobal(kidneySlider:GetName() .. "Text"):SetText("")

makeLabel(scrollChild, "Thresholds", 8, -570)
local evasionLabel = makeLabel(scrollChild, "", 8, -594, "GameFontHighlightSmall")
local vanishLabel = makeLabel(scrollChild, "", 194, -594, "GameFontHighlightSmall")

local evasionSlider = CreateFrame("Slider", "RogueAutoEvasionSlider", scrollChild, "OptionsSliderTemplate")
evasionSlider:SetWidth(160)
evasionSlider:SetHeight(16)
evasionSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, -612)
evasionSlider:SetMinMaxValues(5, 100)
evasionSlider:SetValueStep(1)
getglobal(evasionSlider:GetName() .. "Low"):SetText("5")
getglobal(evasionSlider:GetName() .. "High"):SetText("100")
getglobal(evasionSlider:GetName() .. "Text"):SetText("")

local vanishSlider = CreateFrame("Slider", "RogueAutoVanishSlider", scrollChild, "OptionsSliderTemplate")
vanishSlider:SetWidth(160)
vanishSlider:SetHeight(16)
vanishSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 194, -612)
vanishSlider:SetMinMaxValues(5, 100)
vanishSlider:SetValueStep(1)
getglobal(vanishSlider:GetName() .. "Low"):SetText("5")
getglobal(vanishSlider:GetName() .. "High"):SetText("100")
getglobal(vanishSlider:GetName() .. "Text"):SetText("")

makeLabel(scrollChild, "Misc", 8, -666)
debugCheckbox = makeCheckbox(scrollChild, "Enable debug chat output", 8, -688, function()
  return RogueAutoDB and RogueAutoDB.debug
end, function(value)
  RogueAutoDB.debug = value
end)

makeLabel(scrollChild, "Macro Setup", 8, -730)
local bleedMacroBox = makeMacroField(
  scrollChild,
  "/script RogueAuto:Bleed()",
  "Bleed: stealth opener plus rupture and Shadow of Death upkeep when available.",
  8,
  -754,
  330
)
local directMacroBox = makeMacroField(
  scrollChild,
  "/script RogueAuto:Direct()",
  "Direct: stealth opener plus Slice and Dice, Envenom, and direct finisher priority.",
  8,
  -808,
  330
)
local interruptMacroBox = makeMacroField(
  scrollChild,
  "/script RogueAuto:Interrupt()",
  "Interrupt: ranged interrupt tools first, then Kick, Kidney Shot, Gouge, and optional Blind.",
  8,
  -862,
  330
)
local defensiveMacroBox = makeMacroField(
  scrollChild,
  "/script RogueAuto:Defensive()",
  "Defensive: Vanish and Evasion at thresholds, then Flourish, Ghostly Strike, and Feint.",
  8,
  -916,
  330
)
local macroHint = makeLabel(scrollChild, "Click a macro field to highlight and copy it. Use the minimap rogue icon to reopen this window.", 8, -970, "GameFontHighlightSmall")
macroHint:SetTextColor(0.8, 0.8, 0.8)
macroHint:SetWidth(330)
macroHint:SetJustifyH("LEFT")
scrollChild:SetHeight(1030)

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

local function refreshBuilderButtons()
  if not RogueAutoDB then
    return
  end

  for _, button in ipairs(builderButtons) do
    if button.key == RogueAutoDB.builder.mode then
      button:SetAlpha(1)
    else
      button:SetAlpha(0.55)
    end
  end
end

kidneySlider:SetScript("OnValueChanged", function()
  if suspendRefresh or not RogueAutoDB then
    return
  end
  RogueAutoDB.interrupt.kidneyMinCP = clamp(math.floor(kidneySlider:GetValue() + 0.5), 1, 5)
  addon:RefreshConfig()
end)

evasionSlider:SetScript("OnValueChanged", function()
  if suspendRefresh or not RogueAutoDB then
    return
  end
  RogueAutoDB.panic.evasionPct = clamp(math.floor(evasionSlider:GetValue() + 0.5), 5, 100)
  addon:RefreshConfig()
end)

vanishSlider:SetScript("OnValueChanged", function()
  if suspendRefresh or not RogueAutoDB then
    return
  end
  RogueAutoDB.panic.vanishPct = clamp(math.floor(vanishSlider:GetValue() + 0.5), 5, 100)
  addon:RefreshConfig()
end)

function addon:RefreshConfig()
  if not RogueAutoDB then
    return
  end

  fallbackCheckbox:Refresh()
  autoAttackCheckbox:Refresh()
  stealthCheckbox:Refresh()
  pickPocketCheckbox:Refresh()
  sndCheckbox:Refresh()
  feintCheckbox:Refresh()
  ghostlyCheckbox:Refresh()
  flourishCheckbox:Refresh()
  blindCheckbox:Refresh()
  debugCheckbox:Refresh()

  refreshBuilderButtons()

  suspendRefresh = true
  kidneySlider:SetValue(RogueAutoDB.interrupt.kidneyMinCP)
  evasionSlider:SetValue(RogueAutoDB.panic.evasionPct)
  vanishSlider:SetValue(RogueAutoDB.panic.vanishPct)
  suspendRefresh = false

  kidneyLabel:SetText("Kidney Shot combo minimum: " .. tostring(RogueAutoDB.interrupt.kidneyMinCP))
  evasionLabel:SetText("Evasion: " .. tostring(RogueAutoDB.panic.evasionPct) .. "%")
  vanishLabel:SetText("Vanish: " .. tostring(RogueAutoDB.panic.vanishPct) .. "%")

  updateScrollBounds()
end

function addon:ToggleConfig()
  self:InitDB()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
    self:RefreshConfig()
    updateScrollBounds()
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
  addon:Print("/ra snd on|off")
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
    if addon.UpdateMinimapButtonPosition then
      addon:UpdateMinimapButtonPosition()
    end
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

  if command == "snd" then
    if args[2] == "on" then
      RogueAutoDB.core.keepSliceAndDice = true
    elseif args[2] == "off" then
      RogueAutoDB.core.keepSliceAndDice = false
    else
      addon:Print("Usage: /ra snd on|off")
      return
    end
    addon:RefreshConfig()
    addon:Print("Slice and Dice upkeep " .. (RogueAutoDB.core.keepSliceAndDice and "enabled" or "disabled") .. ".")
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

local minimapButton = CreateFrame("Button", "RogueAutoMinimapButton", Minimap)
addon.minimapButton = minimapButton

minimapButton:SetWidth(32)
minimapButton:SetHeight(32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")

local buttonTexture = minimapButton:CreateTexture(nil, "BACKGROUND")
buttonTexture:SetWidth(20)
buttonTexture:SetHeight(20)
buttonTexture:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
buttonTexture:SetTexture("Interface\\Icons\\Ability_Stealth")

local borderTexture = minimapButton:CreateTexture(nil, "OVERLAY")
borderTexture:SetWidth(52)
borderTexture:SetHeight(52)
borderTexture:SetPoint("TOPLEFT", minimapButton, "TOPLEFT")
borderTexture:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local highlightTexture = minimapButton:CreateTexture(nil, "HIGHLIGHT")
highlightTexture:SetWidth(24)
highlightTexture:SetHeight(24)
highlightTexture:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
highlightTexture:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
highlightTexture:SetBlendMode("ADD")

local function calculateAngleDegrees(x, y)
  if x == 0 then
    if y >= 0 then
      return 90
    end
    return 270
  end

  local angle = math.deg(math.atan(y / x))
  if x < 0 then
    angle = angle + 180
  elseif y < 0 then
    angle = angle + 360
  end

  return angle
end

local function updateMinimapButtonPosition()
  if not RogueAutoDB then
    return
  end

  local angle = math.rad(RogueAutoDB.minimap.angle or 220)
  local radius = (Minimap:GetWidth() / 2) + 5
  local x = math.cos(angle) * radius
  local y = math.sin(angle) * radius

  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function saveMinimapAngleFromCursor()
  if not RogueAutoDB then
    return
  end

  local scale = Minimap:GetEffectiveScale()
  local centerX = Minimap:GetLeft() + (Minimap:GetWidth() / 2)
  local centerY = Minimap:GetBottom() + (Minimap:GetHeight() / 2)
  local cursorX, cursorY = GetCursorPosition()
  cursorX = cursorX / scale
  cursorY = cursorY / scale

  local angle = calculateAngleDegrees(cursorX - centerX, cursorY - centerY)

  RogueAutoDB.minimap.angle = angle
  updateMinimapButtonPosition()
end

minimapButton:SetScript("OnDragStart", function()
  minimapButton.isDragging = true
end)

minimapButton:SetScript("OnDragStop", function()
  minimapButton.isDragging = false
  saveMinimapAngleFromCursor()
end)

minimapButton:SetScript("OnUpdate", function()
  if minimapButton.isDragging then
    saveMinimapAngleFromCursor()
  end
end)

minimapButton:SetScript("OnClick", function()
  addon:ToggleConfig()
end)

minimapButton:SetScript("OnEnter", function()
  GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
  GameTooltip:AddLine("RogueAuto")
  GameTooltip:AddLine("Left-click: open config", 1, 1, 1)
  GameTooltip:AddLine("Drag: move button", 1, 1, 1)
  GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

addon.UpdateMinimapButtonPosition = updateMinimapButtonPosition

local minimapInitFrame = CreateFrame("Frame")
minimapInitFrame:RegisterEvent("VARIABLES_LOADED")
minimapInitFrame:SetScript("OnEvent", function()
  addon:InitDB()
  updateMinimapButtonPosition()
  updateScrollBounds()
end)
