local addon = RogueAuto

addon.settingDefinitions.debugEnabled = {
  path = { "debug" },
  label = "Show technical messages",
  help = "Only turn this on when an adult or addon helper asks for it.",
}

table.insert(addon.uiSections, {
  title = "9. Grown-up Help",
  kind = "debug",
  color = { 0.64, 0.68, 0.72 },
  help = "This section prints technical details used to find problems. You can safely leave it off.",
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
