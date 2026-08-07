local addon = RogueAuto

addon.settingDefinitions.debugEnabled = {
  path = { "debug" },
  label = "Show debug traces",
  help = "Prints RogueAuto debug and Builder trace messages to chat. Leave disabled for normal gameplay.",
}

table.insert(addon.uiSections, {
  title = "Debug",
  kind = "debug",
  help = "Diagnostic output for troubleshooting RogueAuto behavior.",
  items = { "debugEnabled" },
})

-- Debug() already respects RogueAutoDB.debug. Keep Trace/TraceEvent on the
-- same flag so Builder priority traces never leak into normal gameplay.
function addon:Trace(message)
  if not (RogueAutoDB and RogueAutoDB.debug) then
    return
  end

  self:Debug(message)
end
