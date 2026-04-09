# RogueAuto Gameplay Optimization Research

Date: 2026-03-28

## Goal

Build a prioritized gameplay-optimization backlog for RogueAuto around a general all-rounder Turtle WoW rogue playstyle, using the current addon behavior as the baseline and Turtle-specific patch/class sources as the research anchor.

This pass is intentionally about gameplay logic, not UI expansion.

## Sources

### Primary sources

1. Turtle WoW official homepage:
   https://turtle-wow.org/
2. Turtle WoW official homepage mirror:
   https://turtle-wow.org/home/
3. SA forum patch notes index showing `Patch 1.18.1 — Pesadillas de Ursol`:
   https://saforum.turtle-wow.org/viewforum.php?f=9
4. Official `1.18.0` patch notes:
   https://forum.turtle-wow.org/viewtopic.php?t=17688
5. Turtle WoW Rogue class page:
   https://turtle-wow.org/rogue

### Evidence quality rules used here

- `Direct evidence`: explicit in official patch/class material.
- `Inferred from official sources`: not stated as a rogue rotation rule, but strongly implied by official patch direction or API changes.
- `Code baseline evidence`: directly observed in `Actions.lua`, `Core.lua`, `Settings.lua`, and `Config.lua`.
- Community discussion was not used to overrule official sources.

## Source-backed Findings

### Direct evidence

- Turtle continues to frame rogue changes as additive rather than transformational: the class should gain toolkit support without losing its baseline feel.
- `1.18.0` introduced stronger addon-facing data through aura and unit API improvements. For RogueAuto, the relevant takeaway is that target/debuff identity can be tracked with better primitives than pure name/texture heuristics.
- `1.18.0` also raises the general durability baseline of encounters through broader health and difficulty tuning, especially on bosses and tuned content.
- `1.18.1` is the newest patch anchor in the official patch forum, but the publicly visible material is more useful as a recency/context marker than as a rogue-specific mechanics source.

### Inferred from official sources

- Because Turtle is adding content depth without replacing rogue fundamentals, the correct addon direction is not “invent a new rotation”; it is “make the existing rotation more context-aware and less brittle.”
- Longer and more durable encounters increase the value of correctly deciding when to set up `Slice and Dice`, `Rupture`, and `Expose Armor`, instead of using one static rule for every target.
- Better aura/unit identity data should reduce the need for mixed local timers, texture guesses, and ownership assumptions.

## Current Addon Baseline

### Macro entrypoints

- `Bleed()` in `Actions.lua`
  - stealth opener via `Pick Pocket` if eligible
  - then `Garrote` if possible
  - damage preamble via soft defensives, `Riposte`, and execute check
  - maintenance path for `Rupture`, `Shadow of Death`, `Slice and Dice`, `Envenom`
  - once `Rupture` is considered active, it switches into the direct-damage dealer loop
- `Direct()` in `Actions.lua`
  - stealth opener via `Pick Pocket` if eligible
  - then `Ambush` or `Cheap Shot`
  - same damage preamble
  - maintenance path for `Expose Armor`, `Slice and Dice`, `Envenom`, direct finisher
  - once `Expose Armor` is considered active, it switches into the direct-damage dealer loop
- `Interrupt()` in `Actions.lua`
  - ranged stop tools first, then melee interrupt chain
- `Defensive()` in `Actions.lua`
  - panic cooldowns first, then softer mitigation/value tools

### Builder and finisher behavior

- Builder modes exist for `auto`, `sinister`, `hemo`, `backstab`, and `noxious`.
- `TryPreferredBuilder()` in `Core.lua` currently:
  - attempts `Ghostly Strike` ahead of standard builders when enabled
  - attempts `Backstab` directly in `auto` and `backstab` mode when the addon does not believe the player is position-blocked
  - otherwise falls through to `Noxious Assault`, `Hemorrhage`, or `Sinister Strike`
- `runDirectDamageDealer()` in `Actions.lua` currently:
  - refreshes `Slice and Dice`
  - uses the selected direct finisher at `5` combo points
  - otherwise builds combo points

### Debuff, target, and opener state

- Target debuffs are currently inferred from a mix of:
  - unit debuff name lookup
  - tracked local timers
  - pending local casts
  - texture matching fallback
- `Direct()` and `Bleed()` therefore depend heavily on the quality of `IsTargetDebuffActive()`.
- Pick Pocket routing is currently gated by:
  - the existing stealth toggle
  - `Humanoid`
  - whitelisted names
  - whitelisted creature type `Undead`
- The combat summary was already tightened to count periodic damage from the player only when the combat log explicitly attributes it to the player.

## Known Friction Areas

- `Backstab` priority is still limited by inferred behind-state and client rejection timing.
- `Expose Armor` transition quality is only as good as debuff detection quality.
- Generic target debuff presence can still make the macro behave as though another rogue's debuff is “good enough” when that may not be what the user wants in solo play.
- `auto` builder mode still behaves like a fixed preference order, not a contextual decision.
- Pick Pocket logic is eligibility-aware, but not value-aware.
- Setup logic is still too static for the current spread of short solo fights versus longer tuned fights.

## Prioritized Backlog

### Tier 1

1. **Rebuild target-debuff tracking around Turtle's stronger aura and unit identity data**
   - Category: Reliability/state tracking
   - Evidence: direct evidence from `1.18.0` addon API improvements, plus code baseline evidence
   - Impact: High
   - Confidence: High
   - Effort: Medium
   - Regression risk: Medium
   - Rationale: `Direct()` and `Bleed()` both depend on reliable debuff identity. This is the most foundational improvement.

2. **Add target-durability heuristics for setup versus immediate damage**
   - Category: Rotation correctness
   - Evidence: inferred from `1.18.0` encounter-durability direction, plus code baseline evidence
   - Impact: High
   - Confidence: High
   - Effort: Medium
   - Regression risk: Medium
   - Rationale: the addon currently applies one broad setup philosophy to targets with very different time-to-live.

3. **Implement a real Backstab-first failure model**
   - Category: Context awareness
   - Evidence: code baseline evidence
   - Impact: High
   - Confidence: High
   - Effort: Medium
   - Regression risk: Low
   - Rationale: this is one of the most visible feel problems in live play and has already required repeated manual tuning.

4. **Split debuff-trust policy between solo and grouped play**
   - Category: Reliability/state tracking
   - Evidence: inferred from official class direction plus code baseline evidence
   - Impact: High
   - Confidence: Medium
   - Effort: Medium
   - Regression risk: Medium
   - Rationale: solo play and grouped play want different answers to “does any rogue debuff count?”

### Tier 2

5. **Make `auto` builder mode truly contextual**
   - Category: Rotation correctness
   - Evidence: code baseline evidence
   - Impact: Medium
   - Confidence: High
   - Effort: Medium
   - Regression risk: Low
   - Rationale: `auto` should choose between `Backstab`, `Noxious Assault`, `Hemorrhage`, and `Sinister Strike` based on position, weapon, and fight context, not a fixed fallback chain.

6. **Refine `Ghostly Strike` timing by fight state**
   - Category: Survivability/control
   - Evidence: code baseline evidence, inferred from Turtle's “same class feel, broader toolkit” direction
   - Impact: Medium
   - Confidence: Medium
   - Effort: Low
   - Regression risk: Low
   - Rationale: the addon should value the early dodge benefit in solo play without repeatedly delaying higher-value finishers or setup in short fights.

7. **Add short-fight and long-fight finisher thresholds**
   - Category: Rotation correctness
   - Evidence: inferred from official encounter tuning, plus code baseline evidence
   - Impact: Medium
   - Confidence: Medium
   - Effort: Low
   - Regression risk: Low
   - Rationale: one execute-style threshold is too coarse for all content.

8. **Improve stealth-opener failure recovery**
   - Category: Reliability/state tracking
   - Evidence: code baseline evidence
   - Impact: Medium
   - Confidence: High
   - Effort: Medium
   - Regression risk: Low
   - Rationale: failed `Pick Pocket`, `Garrote`, `Ambush`, or `Backstab` attempts should route immediately into the best post-failure line instead of wasting multiple presses.

9. **Make Pick Pocket value-aware, not only eligibility-aware**
   - Category: Throughput/downtime
   - Evidence: code baseline evidence
   - Impact: Medium
   - Confidence: Medium
   - Effort: Medium
   - Regression risk: Low
   - Rationale: some valid pickpocket targets are not worth delaying the opener, especially in high-density or low-value pulls.

### Tier 3

10. **Weight soft defensives by elite status and incoming pressure**
    - Category: Survivability/control
    - Evidence: inferred from encounter tuning plus code baseline evidence
    - Impact: Medium
    - Confidence: Medium
    - Effort: Medium
    - Regression risk: Medium
    - Rationale: `targettarget == player` is too thin as the only defensive signal.

11. **Tune interrupt routing for group discipline**
    - Category: Survivability/control
    - Evidence: code baseline evidence
    - Impact: Low-Medium
    - Confidence: Medium
    - Effort: Medium
    - Regression risk: Low
    - Rationale: group play values predictable lockouts and clean target discipline more than opportunistic filler control.

12. **Add poison-aware direct-finisher guidance**
    - Category: Rotation correctness
    - Evidence: code baseline evidence, low-confidence class-context inference
    - Impact: Low-Medium
    - Confidence: Low-Medium
    - Effort: Medium
    - Regression risk: Medium
    - Rationale: the current finisher choice is manual and static; better context may help, but this should stay behind stronger baseline fixes.

## Top 3 Recommended First Implementations

### 1. Spell-ID and GUID-aware debuff tracking

- Current problem:
  - `Expose Armor`, `Rupture`, and related state transitions still rely on mixed heuristics.
  - The macro can over-refresh or trust the wrong target state.
- Intended behavior:
  - use Turtle's stronger aura identity and target identity data as the first-class source
  - keep local timers as fallback only
- Why it matters:
  - this directly improves `Direct()`, `Bleed()`, setup switching, refresh timing, and later encounter heuristics
- Likely files:
  - `Core.lua`
- Acceptance checks:
  - a target already carrying another rogue's debuff
  - a target switch during combo building
  - refresh behavior near debuff expiry
  - `Direct()` should stop reapplying `Expose Armor` once it is truly active for the intended trust policy

### 2. Target-durability setup heuristics

- Current problem:
  - setup is currently driven by static thresholds and broad fallback rules
- Intended behavior:
  - estimate whether the target is worth `Expose Armor`, `Rupture`, `Slice and Dice`, or immediate direct damage
  - use target classification, current health, max health, and possibly recent damage pace
- Why it matters:
  - this prevents over-setup on disposable mobs while preserving maintenance value on elites and longer fights
- Likely files:
  - `Actions.lua`
  - `Core.lua`
  - possibly `Settings.lua` if any threshold becomes configurable
- Acceptance checks:
  - a normal quest mob should not eat unnecessary setup
  - an elite or boss target should enter and maintain the correct setup path
  - `Bleed()` and `Direct()` should diverge only when the fight context justifies it

### 3. Backstab-first failure memory and recovery

- Current problem:
  - `Backstab` behavior still depends too much on inferred behind-state and can burn presses before falling back
- Intended behavior:
  - try `Backstab` aggressively when selected and physically plausible
  - record cast rejection briefly
  - fall back cleanly to `Hemorrhage` or `Sinister Strike`
  - clear the suppression as soon as movement or new target context makes `Backstab` plausible again
- Why it matters:
  - this is a high-visibility gameplay feel issue and directly affects the usefulness of `auto` and `backstab` builder modes
- Likely files:
  - `Core.lua`
  - `Actions.lua`
- Acceptance checks:
  - behind the target with a dagger should cast `Backstab`
  - front-of-target should fail once and then recover quickly into fallback builders
  - moving behind the target again should restore `Backstab` priority promptly

## Acceptance Scenario Matrix

Use the following scenarios to validate any implementation from this backlog:

- solo stealth opener on a normal quest mob
- short solo fight where setup may be overkill
- sustained single-target fight where maintenance matters
- dagger plus behind-target case where `Backstab` should win
- target already carrying rogue debuffs from another player
- grouped fight where threat or control matters more than raw throughput
- pickpocketable undead or named whitelist non-humanoid target
- opener failure or behind-position failure recovery

## Recommended Implementation Order

1. Rebuild debuff tracking.
2. Add target-durability setup heuristics.
3. Harden `Backstab` routing and recovery.
4. Revisit solo versus group debuff trust once the stronger debuff-state layer exists.

## Conclusion

The addon does not need a new rotation identity. The main gains are in making the existing rotation trustworthy under Turtle's current content profile: better debuff truth, better setup judgment, and better recovery from positional failure.

## Defaults and Assumptions

- Research remains gameplay-logic-focused, not UI-focused.
- `1.18.1` is usable as a primary source, but only as a preliminary patch source.
- `1.18.0` provides the strongest concrete addon-facing evidence because it exposes API changes and global encounter-length changes.
- The most useful near-term work is heuristic and state-tracking improvement, not adding many new menu options.
