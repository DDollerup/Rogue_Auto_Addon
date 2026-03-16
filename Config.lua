local addon = RogueAuto

SLASH_ROGUEAUTO1 = "/ra"

local frame = CreateFrame("Frame", "RogueAutoConfigFrame", UIParent)
addon.configFrame = frame

frame:SetWidth(470)
frame:SetHeight(560)
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

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
subtitle:SetText("Manual Turtle WoW rogue helper")
subtitle:SetTextColor(0.8, 0.8, 0.8)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeButton:SetWidth(76)
closeButton:SetHeight(22)
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -12)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
  frame:Hide()
end)

local scrollFrame = CreateFrame("ScrollFrame", "RogueAutoScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -56)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 16)

local scrollChild = CreateFrame("Frame", "RogueAutoScrollChild", scrollFrame)
scrollChild:SetWidth(392)
scrollChild:SetHeight(900)
scrollFrame:SetScrollChild(scrollChild)

local scrollBar = getglobal("RogueAutoScrollFrameScrollBar")
scrollBar:SetValueStep(20)

local refreshables = {}
local builderButtons = {}

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

local function createSectionHeader(parent, titleText, y)
  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
  label:SetText(titleText)

  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetWidth(344)
  line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
  line:SetTexture(1, 0.82, 0, 0.25)

  return 24
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

local function createWrappedText(parent, text, font, y, color)
  local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
  label:SetWidth(344)
  label:SetJustifyH("LEFT")
  label:SetJustifyV("TOP")
  label:SetText(text)
  if color then
    label:SetTextColor(color[1], color[2], color[3])
  end

  local height = estimateWrappedTextHeight(text, 344, font)

  return label, height
end

local function createToggleControl(parent, settingId, y)
  local definition = addon.settingDefinitions[settingId]
  local control = CreateFrame("Frame", nil, parent)
  control:SetWidth(360)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)

  local checkbox = CreateFrame("CheckButton", nil, control, "UICheckButtonTemplate")
  checkbox:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
  checkbox:SetWidth(20)
  checkbox:SetHeight(20)

  local label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 4, -4)
  label:SetWidth(332)
  label:SetJustifyH("LEFT")
  label:SetText(definition.label)

  local height = 24
  if definition.help then
    local help = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    help:SetWidth(320)
    help:SetJustifyH("LEFT")
    help:SetText(definition.help)
    help:SetTextColor(0.75, 0.75, 0.75)
    height = height + 14
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
  control:SetWidth(360)
  control:SetHeight(52)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)

  local label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
  label:SetWidth(340)
  label:SetJustifyH("LEFT")

  local sliderName = "RogueAutoSlider" .. settingId
  local slider = CreateFrame("Slider", sliderName, control, "OptionsSliderTemplate")
  slider:SetWidth(326)
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
  control:SetWidth(360)
  control:SetHeight(60)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)

  for index, option in ipairs(addon.builderOptions) do
    local row = math.floor((index - 1) / 3)
    local column = math.mod(index - 1, 3)

    local button = CreateFrame("Button", nil, control, "UIPanelButtonTemplate")
    button:SetWidth(110)
    button:SetHeight(22)
    button:SetPoint("TOPLEFT", control, "TOPLEFT", column * 116, -(row * 28))
    button:SetText(option.label)
    button.key = option.key
    button:SetScript("OnClick", function()
      addon:SetSetting("builderMode", option.key)
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
  control:SetWidth(360)
  control:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)

  local cursorY = 0
  for _, definition in ipairs(addon.macroDefinitions) do
    local description, descHeight = createWrappedText(control, definition.description, "GameFontNormal", cursorY, nil)
    description:SetWidth(332)
    local box = CreateFrame("EditBox", nil, control, "InputBoxTemplate")
    box:SetWidth(332)
    box:SetHeight(20)
    box:SetPoint("TOPLEFT", control, "TOPLEFT", 0, cursorY - descHeight - 4)
    box:SetAutoFocus(false)
    box:SetText(definition.macro)
    box:SetScript("OnEscapePressed", function()
      box:ClearFocus()
    end)
    box:SetScript("OnEditFocusGained", function()
      box:HighlightText()
    end)
    box:SetScript("OnEditFocusLost", function()
      box:HighlightText(0, 0)
      box:SetText(definition.macro)
    end)

    cursorY = cursorY - descHeight - 30
  end

  local hint, hintHeight = createWrappedText(control, "Click a macro field to highlight and copy it. Use the minimap rogue icon to reopen this window.", "GameFontHighlightSmall", cursorY, { 0.8, 0.8, 0.8 })
  hint:SetWidth(332)
  cursorY = cursorY - hintHeight

  control:SetHeight(math.abs(cursorY) + 8)
  control.Refresh = function()
  end
  registerRefreshable(control)
  return control, control:GetHeight()
end

local function buildLayout()
  local cursorY = -8

  for _, section in ipairs(addon.uiSections) do
    cursorY = cursorY - createSectionHeader(scrollChild, section.title, cursorY)

    if section.kind == "builder" then
      local _, height = createBuilderControl(scrollChild, cursorY)
      cursorY = cursorY - height - 14
    elseif section.kind == "macros" then
      local _, height = createMacroControl(scrollChild, cursorY)
      cursorY = cursorY - height - 18
    else
      for _, settingId in ipairs(section.items) do
        local definition = addon.settingDefinitions[settingId]
        local _, height
        if definition.min then
          _, height = createSliderControl(scrollChild, settingId, cursorY)
        else
          _, height = createToggleControl(scrollChild, settingId, cursorY)
        end
        cursorY = cursorY - height - 6
      end
      cursorY = cursorY - 12
    end
  end

  scrollChild:SetHeight(math.abs(cursorY) + 16)
  updateScrollBounds()
end

function addon:RefreshConfig()
  if not RogueAutoDB then
    return
  end

  for _, control in ipairs(refreshables) do
    control:Refresh()
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
  addon:Print("/ra opens config.")
  addon:Print("/ra help")
  addon:Print("/ra reset")
  for _, definition in ipairs(addon:GetSlashDefinitions()) do
    addon:Print("/ra " .. definition.command .. " " .. definition.usage)
  end
end

local function applySlashDefinition(definition, argument)
  if definition.type == "toggle" then
    if argument ~= "on" and argument ~= "off" then
      addon:Print("Usage: /ra " .. definition.command .. " " .. definition.usage)
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
      addon:Print("Usage: /ra " .. definition.command .. " " .. definition.usage)
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
      addon:Print("Usage: /ra " .. definition.command .. " " .. definition.usage)
      return
    end

    addon:SetSetting(definition.setting, value)
    local currentValue = addon:GetSetting(definition.setting)
    addon:RefreshConfig()
    addon:Print(definition.success(currentValue))
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

  for _, definition in ipairs(addon:GetSlashDefinitions()) do
    if definition.command == command then
      applySlashDefinition(definition, args[2])
      return
    end
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
