---
status: investigating
trigger: "Diagnose UAT gap G-54.3-3 for Phase 54.3 (interactive-multi-metric-hourly-graph-component). Goal: find_root_cause_only."
created: 2026-10-15T00:00:00Z
updated: 2026-10-15T00:00:00Z
---

## Current Focus

hypothesis: Tooltip pill text is illegible because all four StyledText items in tooltipPill use Appearance.font.pixelSize.smallest (= 10px, the absolute floor of the M3 type scale), copy-pasted from the tab-pill token where it was space-justified, with tight pill padding compounding the problem.
test: Read WeatherGraph.qml tooltipPill block + upstream Appearance.qml type scale + plan docs for font spec rationale
expecting: smallest = 10px confirmed; no plan rationale justifying smallest for the floating tooltip
next_action: Return ROOT CAUSE FOUND (diagnose-only mode, no fix)

## Symptoms

expected: Hover scrub overlay tooltip font should be legibly sized (floating tooltip pill readable while scrubbing)
actual: "yes works but the text font need to be a bit bigger" (Test 3 passes functionally, fails cosmetically)
errors: none (no crash; pure legibility complaint)
reproduction: Hover across hourly graph in weather popup (UAT Test 3), observe tooltip pill text size
started: Phase 54.3 UAT (2026-10-13)

## Eliminated

(none — first hypothesis confirmed)

## Evidence

- timestamp: 2026-10-15
  checked: restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml lines 981-1030 (tooltipPill)
  found: All 4 StyledText items (temporal label Bold, 2x "•" separators, metric readout DemiBold) use `font.pixelSize: Appearance.font.pixelSize.smallest`; glyph MaterialSymbol uses iconSize 12; pill padding is implicitHeight +8 / implicitWidth +14 with RowLayout spacing 5
  implication: Entire tooltip renders at the minimum type token with cramped padding — directly matches "text font need to be a bit bigger"

- timestamp: 2026-10-15
  checked: vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml lines 237-248 (M3 type scale)
  found: smallest=10, smaller=12, smallie=13, small=15, normal=16, large=17, larger=19, huge=22. `smallest` is the absolute floor.
  implication: Tooltip sits 2-5px below every legible peer token (smaller/small); bump of one step (12) or two steps (13-15) is the calibrated fix range

- timestamp: 2026-10-15
  checked: Phase 54.3 plans/research/context for tooltip font spec
  found: `pixelSize.smallest` was specified ONLY for the 6-pill tab row (D-54.3-02) with explicit space rationale (fit 6 pills in ~416px). No plan, decision, or assert mandates smallest for the floating tooltip — the tooltip inherited the token without justification. The phase54.3 assert only gates smallest+bold for tab pills, not the tooltip.
  implication: Tooltip's smallest usage is copy-paste inheritance, not a requirement — safe to bump without violating any design decision

- timestamp: 2026-10-15
  checked: Sibling weather cards for differential comparison (WeatherBaseCard title=smaller/12, WeatherHeroCard value=normal/16, WeatherWindCard value=normal/16)
  found: Peer readout/value text uses smaller (12) or normal (16); only static micro-labels/badges justifiably use smallest (10)
  implication: Differential debugging confirms tooltip (a dynamic readout, not a micro-label) is one class below its peer group — misclassified token

## Resolution

root_cause: tooltipPill in WeatherGraph.qml renders all text at Appearance.font.pixelSize.smallest (10px, the M3 type-scale floor), a token specified for the space-constrained 6-pill tab row (D-54.3-02) and inherited by the floating tooltip without justification; tight pill padding (+8h/+14w, spacing 5, 12px glyph) compounds illegibility. Peer readout text uses smaller (12) or larger.
fix: (diagnose-only — not applied)
verification: (diagnose-only — not verified)
files_changed: []
