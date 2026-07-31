local addon = RogueAuto

SLASH_ROGUEAUTO1 = "/rogueauto"
SLASH_ROGUEAUTO2 = "/rga"
SLASH_ROGUEMENU1 = "/roguemenu"
SLASH_ROGUEMENU2 = "/rgaopen"

local primarySlashCommand = "/rga"

local frame = CreateFrame("Frame", "RogueAutoConfigFrame", UIParent)
addon.configFrame = frame

frame:SetWidth(540)
frame:SetHeight(620)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
frame:SetBackdropColor(0.03, 0.03, 0.03, 0.96)
frame:SetBackdropBorderColor(1, 0.82, 0, 0.9)
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

local headerGlow = frame:CreateTexture(nil, "BACKGROUND")
headerGlow:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
headerGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
headerGlow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
headerGlow:SetHeight(70)
headerGlow:SetVertexColor(0.85, 0.6, 0.12, 0.12)

local titleIcon = frame:CreateTexture(nil, "ARTWORK")
titleIcon:SetWidth(22)
titleIcon:SetHeight(22)
titleIcon:SetPoint("TOP", frame, "TOP", -54, -16)
titleIcon:SetTexture("Interface\\Icons\\Ability_Stealth")

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
title:SetText("RogueAuto")
title:SetTextColor(1, 0.9, 0.35)

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
subtitle:SetText("Manual Turtle WoW rogue helper")
subtitle:SetTextColor(0.82, 0.82, 0.82)

local headerLine = frame:CreateTexture(nil, "ARTWORK")
headerLine:SetHeight(1)
headerLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -56)
headerLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -56)
headerLine:SetTexture(1, 0.82, 0, 0.28)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeButton:SetWidth(76)
closeButton:SetHeight(22)
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -16)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
  frame:Hide()
end)

local contentPanel = CreateFrame("Frame", "RogueAutoConfigContentPanel", frame)
contentPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -68)
contentPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
contentPanel:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
contentPanel:SetBackdropColor(0.07, 0.07, 0.07, 0.9)
contentPanel:SetBackdropBorderColor(0.75, 0.58, 0.12, 0.6)

local scrollFrame = CreateFrame("ScrollFrame", "RogueAutoScrollFrame", contentPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 12, -12)
scrollFrame:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -28, 12)

local scrollChild = CreateFrame("Frame", "RogueAutoScrollChild", scrollFrame)
scrollChild:SetWidth(464)
scrollChild:SetHeight(1200)
scrollFrame:SetScrollChild(scrollChild)

local scrollBar = getglobal("RogueAutoScrollFrameScrollBar")
scrollBar:SetValueStep(20)

local refreshables = {}
local builderButtons = {}
local optionButtonGroups = {}
local cardWidth = 424
local controlWidth = 392
local textWidth = 372
local buttonWidth = 122
local buttonSpacing = 130
local pickPocketResetMenuControl = nil

local sectionIcons = {
  builder = "Interface\\Icons\\INV_Sword_04",
  roleplay = "Interface\\Icons\\INV_Misc_Mask_01",
  ["Builder"] = "Interface\\Icons\\INV_Sword_04",
  ["Openers"] = "Interface\\Icons\\Ability_Stealth",
  ["Finisher"] = "Interface\\Icons\\Ability_Rogue_Eviscerate",
  ["Defensives"] = "Interface\\Icons\\Spell_Shadow_ShadowWard",
  ["Thresholds"] = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
  ["Highlights"] = "Interface\\Icons\\INV_Misc_Spyglass_02",
  ["Roleplay"] = "Interface\\Icons\\INV_Misc_Mask_01",
  ["Macros"] = "Interface\\Icons\\INV_Misc_Note_01",
  ["Misc"] = "Interface\\Icons\\INV_Misc_Gear_01",
  macros = "Interface\\Icons\\INV_Misc_Note_01",
  ["Targeting"] = "Interface\\Icons\\Ability_Hunter_SniperShot",
}

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

local function registerRefreshable(control)
  table.insert(refreshables, control)
end

local function createSectionHeader(parent, section)
  local iconTexture = sectionIcons[section.kind or section.title] or "Interface\\Icons\\INV_Misc_Gear_01"

  local icon = parent:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(18)
  icon:SetHeight(18)
  icon:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -12)
  icon:SetTexture(iconTexture)

  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  label:SetText(section.title)
  label:SetTextColor(1, 0.9, 0.35)

  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -34)
  line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -34)
  line:SetTexture(1, 0.82, 0, 0.22)

  return 38
end

local function estimateWrappedTextHeight(text, width, font)
  local lineHeight = 14
  local averageCharWidth = 6

  if font == "GameFontNormal" or font == "GameFontNormalLarge" then
    lineHeight = 16
    averageCharWidth = 7
  end

  local charsPerLine = math.floor(width / averageCharWidth)
  if charsPerLine < 12 then
    charsPerLine = 12
  end

  local lineCount = 0
  for line in string.gfind((text or "") .. "\n", "([^\n]*)\n") do
    local length = string.len(line)
    local wrapped = math.floor(length / charsPerLine)
    if math.mod(length, charsPerLine) ~= 0 then
      wrapped = wrapped + 1
    end
    if wrapped < 1 then
      wrapped = 1
    end
    lineCount = lineCount + wrapped
  end

  if lineCount < 1 then
    lineCount = 1
  end

  return lineCount * lineHeight
end

local function getFontStringHeight(label, fallbackHeight)
  if label and label.GetStringHeight then
    local height = label:GetStringHeight()
    if height and height > 0 then
      return height
    end
  end

  if label and label.GetHeight then
    local height = label:GetHeight()
    if height and height > 0 then
      return height
    end
  end

  return fallbackHeight or 14
end

local function createWrappedText(parent, text, font, y, color, width)
  width = width or textWidth
  local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
  label:SetWidth(width)
  label:SetJustifyH("LEFT")
  label:SetJustifyV("TOP")
  label:SetText(text)
  if color then
    label:SetTextColor(color[1], color[2], color[3])
  end

  local height = getFontStringHeight(label, estimateWrappedTextHeight(text, width, font))

  return label, height
end

local function formatPickPocketMenuTimer(seconds)
  if seconds == nil then
    return "No target selected"
  end

  if seconds <= 0 then
    return "Ready"
  end

  local rounded = math.floor(seconds + 0.5)
  local minutes = math.floor(rounded / 60)
  local remainingSeconds = rounded % 60
  if minutes > 0 then
    return string.format("%dm %02ds", minutes, remainingSeconds)
  end

  return string.format("%ds", remainingSeconds)
end

local function createPickPocketResetTimerControl(parent, y)
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(controlWidth)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
  control:SetHeight(52)

  local title = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
  title:SetWidth(textWidth)
  title:SetJustifyH("LEFT")
  title:SetText("Current target Pick Pocket reset")
  title:SetTextColor(1, 0.82, 0.12)

  local value = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  value:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  value:SetWidth(textWidth)
  value:SetJustifyH("LEFT")
  value:SetTextColor(1, 0.95, 0.6)

  local help = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  help:SetPoint("TOPLEFT", value, "BOTTOMLEFT", 0, -4)
  help:SetWidth(textWidth)
  help:SetJustifyH("LEFT")
  help:SetText("Shows countdown to when this target can be Pick Pocketed again.")
  help:SetTextColor(0.75, 0.75, 0.75)

  control.Refresh = function()
    if not addon.GetPickPocketResetTimerForCurrentTarget then
      value:SetText("Unavailable")
      return
    end

    local remaining = addon:GetPickPocketResetTimerForCurrentTarget()
    value:SetText(formatPickPocketMenuTimer(remaining))
  end

  registerRefreshable(control)
  pickPocketResetMenuControl = control
  return control, 52
end

local function createToggleControl(parent, settingId, y)
  local definition = addon.settingDefinitions[settingId]
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(controlWidth)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

  local checkbox = CreateFrame("CheckButton", nil, control, "UICheckButtonTemplate")
  checkbox:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
  checkbox:SetWidth(20)
  checkbox:SetHeight(20)

  local label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 4, -4)
  label:SetWidth(textWidth - 20)
  label:SetJustifyH("LEFT")
  label:SetText(definition.label)

  local height = 24
  if definition.help then
    local help = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    help:SetWidth(textWidth)
    help:SetJustifyH("LEFT")
    help:SetText(definition.help)
    help:SetTextColor(0.75, 0.75, 0.75)
    height = height + getFontStringHeight(help, 14) + 2
  end

  checkbox:SetScript("OnClick", function()
    addon:SetSetting(settingId, checkbox:GetChecked() == 1)
    addon:RefreshConfig()
  end)

  control.Refresh = function()
    checkbox:SetChecked(addon:GetSetting(settingId) and 1 or nil)
  end

  control:SetHeight(height)
  registerRefreshable(control)
  return control, height
end

local function createSliderControl(parent, settingId, y)
  local definition = addon.settingDefinitions[settingId]
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(controlWidth)
  control:SetHeight(52)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

  local label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
  label:SetWidth(textWidth)
  label:SetJustifyH("LEFT")

  local sliderName = "RogueAutoSlider" .. settingId
  local slider = CreateFrame("Slider", sliderName, control, "OptionsSliderTemplate")
  slider:SetWidth(356)
  slider:SetHeight(16)
  slider:SetPoint("TOPLEFT", control, "TOPLEFT", 0, -16)
  slider:SetMinMaxValues(definition.min, definition.max)
  slider:SetValueStep(definition.step or 1)
  getglobal(sliderName .. "Low"):SetText(tostring(definition.min))
  getglobal(sliderName .. "High"):SetText(tostring(definition.max))
  getglobal(sliderName .. "Text"):SetText("")

  slider:SetScript("OnValueChanged", function()
    if control.suspendRefresh then
      return
    end
    addon:SetSetting(settingId, slider:GetValue())
    addon:RefreshConfig()
  end)

  control.Refresh = function()
    local value = addon:GetSetting(settingId)
    control.suspendRefresh = true
    slider:SetValue(value)
    control.suspendRefresh = false
    if definition.display then
      label:SetText(definition.display(value))
    else
      label:SetText(definition.label .. ": " .. tostring(value))
    end
  end

  registerRefreshable(control)
  return control, 52
end

local function refreshOptionButtons(settingId)
  local currentValue = addon:GetSetting(settingId)
  local buttons = optionButtonGroups[settingId] or {}

  for _, button in ipairs(buttons) do
    if button.key == currentValue then
      button:SetAlpha(1)
    else
      button:SetAlpha(0.55)
    end
  end
end

local function createOptionButtonsControl(parent, settingId, y)
  local definition = addon.settingDefinitions[settingId]
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(controlWidth)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

  local label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
  label:SetWidth(textWidth)
  label:SetJustifyH("LEFT")
  label:SetText(definition.label)

  optionButtonGroups[settingId] = optionButtonGroups[settingId] or {}

  for index, option in ipairs(definition.options or {}) do
    local row = math.floor((index - 1) / 3)
    local column = math.mod(index - 1, 3)
    local optionKey = option.key
    local optionLabel = option.label

    local button = CreateFrame("Button", nil, control, "UIPanelButtonTemplate")
    button:SetWidth(buttonWidth)
    button:SetHeight(22)
    button:SetPoint("TOPLEFT", control, "TOPLEFT", column * buttonSpacing, -(20 + (row * 28)))
    button:SetText(optionLabel)
    button.key = optionKey
    button:SetScript("OnClick", function()
      addon:SetSetting(settingId, optionKey)
      addon:RefreshConfig()
    end)
    table.insert(optionButtonGroups[settingId], button)
  end

  local rowCount = math.ceil(table.getn(definition.options or {}) / 3)
  if rowCount < 1 then
    rowCount = 1
  end

  local height = 20 + (rowCount * 28)
  if definition.help then
    local _, helpHeight = createWrappedText(control, definition.help, "GameFontHighlightSmall", -(20 + (rowCount * 28)), { 0.75, 0.75, 0.75 }, textWidth)
    height = height + helpHeight + 4
  end

  control:SetHeight(height)
  control.Refresh = function()
    refreshOptionButtons(settingId)
  end

  registerRefreshable(control)
  return control, control:GetHeight()
end

local function refreshBuilderButtons()
  local currentMode = addon:GetSetting("builderMode")
  for _, button in ipairs(builderButtons) do
    if button.key == currentMode then
      button:SetAlpha(1)
    else
      button:SetAlpha(0.55)
    end
  end
end

local function createBuilderControl(parent, y)
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(controlWidth)
  control:SetHeight(60)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

  for index, option in ipairs(addon.builderOptions) do
    local row = math.floor((index - 1) / 3)
    local column = math.mod(index - 1, 3)
    local optionKey = option.key
    local optionLabel = option.label

    local button = CreateFrame("Button", nil, control, "UIPanelButtonTemplate")
    button:SetWidth(buttonWidth)
    button:SetHeight(22)
    button:SetPoint("TOPLEFT", control, "TOPLEFT", column * buttonSpacing, -(row * 28))
    button:SetText(optionLabel)
    button.key = optionKey
    button:SetScript("OnClick", function()
      addon:SetSetting("builderMode", optionKey)
      addon:RefreshConfig()
    end)
    table.insert(builderButtons, button)
  end

  control.Refresh = refreshBuilderButtons
  registerRefreshable(control)
  return control, 60
end

local function createMacroControl(parent, y)
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(controlWidth)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

  local cursorY = 0
  for _, definition in ipairs(addon.macroDefinitions) do
    local macroText = definition.macro
    local descriptionText = definition.description
    local description, descHeight = createWrappedText(control, descriptionText, "GameFontNormal", cursorY, nil, textWidth)
    description:SetWidth(textWidth)
    local box = CreateFrame("EditBox", nil, control, "InputBoxTemplate")
    local editBox = box
    box:SetWidth(textWidth)
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", control, "TOPLEFT", 0, cursorY - descHeight - 10)
    box:SetAutoFocus(false)
    box:SetText(macroText)
    box:SetScript("OnEscapePressed", function()
      editBox:ClearFocus()
    end)
    box:SetScript("OnEditFocusGained", function()
      editBox:HighlightText()
    end)
    box:SetScript("OnEditFocusLost", function()
      editBox:HighlightText(0, 0)
      editBox:SetText(macroText)
    end)

    cursorY = cursorY - descHeight - 36
  end

  local hint, hintHeight = createWrappedText(control, "Click a macro field to highlight and copy it. Use the minimap rogue icon to reopen this window.", "GameFontHighlightSmall", cursorY, { 0.8, 0.8, 0.8 }, textWidth)
  hint:SetWidth(textWidth)
  cursorY = cursorY - hintHeight - 4

  control:SetHeight(math.abs(cursorY) + 8)
  control.Refresh = function()
  end
  registerRefreshable(control)
  return control, control:GetHeight()
end

local function runRoleplayTest()
  addon:Print("Roleplay test control activated.")
  if type(addon.PreviewRoleplayEmote) ~= "function" then
    addon:Print("Roleplay test failed: Roleplay.lua is not loaded.")
    return false
  end

  local success, result = pcall(function()
    return addon:PreviewRoleplayEmote()
  end)
  if not success then
    addon:Print("Roleplay test failed with a Lua error: " .. tostring(result))
    return false
  end
  return result == true
end

local function createRoleplayTestControl(parent, y)
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(controlWidth)
  control:SetHeight(30)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

  local button = CreateFrame("Button", nil, control, "UIPanelButtonTemplate")
  button:SetWidth(180)
  button:SetHeight(24)
  button:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
  button:SetText("Send Test Emote")
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp")
  button:SetScript("OnClick", function()
    runRoleplayTest()
  end)

  return control, 30
end

local function createSectionCard(parent, section, y)
  local card = CreateFrame("Frame", nil, parent)
  card:SetWidth(cardWidth)
  card:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
  card:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  card:SetBackdropColor(0.08, 0.08, 0.08, 0.84)
  card:SetBackdropBorderColor(0.75, 0.58, 0.12, 0.45)

  local cursorY = -10
  cursorY = cursorY - createSectionHeader(card, section)

  if section.help then
    local _, helpHeight = createWrappedText(card, section.help, "GameFontHighlightSmall", cursorY, { 0.78, 0.78, 0.78 }, textWidth)
    cursorY = cursorY - helpHeight - 10
  end

  if section.kind == "builder" then
    local _, height = createBuilderControl(card, cursorY)
    cursorY = cursorY - height - 12
    for _, settingId in ipairs(section.items or {}) do
      local definition = addon.settingDefinitions[settingId]
      local _, itemHeight
      if definition.min then
        _, itemHeight = createSliderControl(card, settingId, cursorY)
      elseif definition.options then
        _, itemHeight = createOptionButtonsControl(card, settingId, cursorY)
      else
        _, itemHeight = createToggleControl(card, settingId, cursorY)
      end
      cursorY = cursorY - itemHeight - 6
    end
    cursorY = cursorY - 10
  elseif section.kind == "pickPocketGold" then
    for _, settingId in ipairs(section.items or {}) do
      local definition = addon.settingDefinitions[settingId]
      local _, itemHeight
      if definition.min then
        _, itemHeight = createSliderControl(card, settingId, cursorY)
      elseif definition.options then
        _, itemHeight = createOptionButtonsControl(card, settingId, cursorY)
      else
        _, itemHeight = createToggleControl(card, settingId, cursorY)
      end
      cursorY = cursorY - itemHeight - 6
    end

    local _, timerHeight = createPickPocketResetTimerControl(card, cursorY)
    cursorY = cursorY - timerHeight - 6
    cursorY = cursorY - 10
  elseif section.kind == "macros" then
    local _, height = createMacroControl(card, cursorY)
    cursorY = cursorY - height - 12
  else
    for _, settingId in ipairs(section.items) do
      local definition = addon.settingDefinitions[settingId]
      local _, height
      if definition.min then
        _, height = createSliderControl(card, settingId, cursorY)
      elseif definition.options then
        _, height = createOptionButtonsControl(card, settingId, cursorY)
      else
        _, height = createToggleControl(card, settingId, cursorY)
      end
      cursorY = cursorY - height - 6
    end
    if section.kind == "roleplay" then
      local _, testHeight = createRoleplayTestControl(card, cursorY)
      cursorY = cursorY - testHeight - 6
    end
    cursorY = cursorY - 10
  end

  card:SetHeight(math.abs(cursorY) + 12)
  return card, card:GetHeight()
end

local function buildLayout()
  local cursorY = -8

  for _, section in ipairs(addon.uiSections) do
    local _, height = createSectionCard(scrollChild, section, cursorY)
    cursorY = cursorY - height - 12
  end

  scrollChild:SetHeight(math.abs(cursorY) + 24)
  updateScrollBounds()
end

function addon:RefreshConfig()
  if not RogueAutoDB then
    return
  end

  for _, control in ipairs(refreshables) do
    control:Refresh()
  end

  if addon.UpdateComboPointFrame then
    addon:UpdateComboPointFrame(true)
  end
  if addon.UpdatePickPocketGoldStatsFrame then
    addon:UpdatePickPocketGoldStatsFrame(true)
  end

  updateScrollBounds()
end

function addon:ToggleConfig()
  self:InitDB()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
    self:RefreshConfig()
  end
end

local function printHelp()
  addon:Print(primarySlashCommand .. " opens config.")
  addon:Print("/roguemenu | /rgaopen opens config.")
  addon:Print(primarySlashCommand .. " help")
  addon:Print(primarySlashCommand .. " reset")
  addon:Print(primarySlashCommand .. " rptest")
  for _, definition in ipairs(addon:GetSlashDefinitions()) do
    addon:Print(primarySlashCommand .. " " .. definition.command .. " " .. definition.usage)
  end
end

local menuTimerUpdateAccumulator = 0
frame:SetScript("OnUpdate", function(_, elapsed)
  if not frame:IsShown() then
    menuTimerUpdateAccumulator = 0
    return
  end

  if not pickPocketResetMenuControl then
    return
  end

  menuTimerUpdateAccumulator = menuTimerUpdateAccumulator + elapsed
  if menuTimerUpdateAccumulator < 0.5 then
    return
  end

  menuTimerUpdateAccumulator = 0
  if pickPocketResetMenuControl.Refresh then
    pickPocketResetMenuControl.Refresh()
  end
end)

local function applySlashDefinition(definition, argument)
  if definition.type == "toggle" then
    if argument ~= "on" and argument ~= "off" then
      addon:Print("Usage: " .. primarySlashCommand .. " " .. definition.command .. " " .. definition.usage)
      return
    end

    local value = argument == "on"
    addon:SetSetting(definition.setting, value)
    addon:RefreshConfig()
    addon:Print(definition.success(value))
    return
  end

  if definition.type == "enum" then
    local mappedValue = definition.values[argument]
    if mappedValue == nil then
      addon:Print("Usage: " .. primarySlashCommand .. " " .. definition.command .. " " .. definition.usage)
      return
    end

    addon:SetSetting(definition.setting, mappedValue)
    addon:RefreshConfig()
    addon:Print(definition.success(mappedValue))
    return
  end

  if definition.type == "number" then
    local value = tonumber(argument)
    if not value then
      addon:Print("Usage: " .. primarySlashCommand .. " " .. definition.command .. " " .. definition.usage)
      return
    end

    addon:SetSetting(definition.setting, value)
    local currentValue = addon:GetSetting(definition.setting)
    addon:RefreshConfig()
    addon:Print(definition.success(currentValue))
    return
  end

  if definition.type == "action" then
    if argument ~= definition.usage then
      addon:Print("Usage: " .. primarySlashCommand .. " " .. definition.command .. " " .. definition.usage)
      return
    end

    if definition.action then
      local message = definition.action(argument)
      if message then
        addon:Print(message)
      end
      addon:RefreshConfig()
      return
    end
  end
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

  if command == "rptest" then
    runRoleplayTest()
    return
  end

  for _, definition in ipairs(addon:GetSlashDefinitions()) do
    if definition.command == command then
      applySlashDefinition(definition, args[2])
      return
    end
  end

  addon:Print("Unknown command. Use " .. primarySlashCommand .. " help")
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

  local angle = math.rad(RogueAutoDB.minimap.angle or 235)
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

  RogueAutoDB.minimap.angle = calculateAngleDegrees(cursorX - centerX, cursorY - centerY)
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

buildLayout()

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
  addon:InitDB()
  updateMinimapButtonPosition()
  addon:RefreshConfig()
end)
