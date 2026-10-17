---
status: investigating
trigger: "Hover-scrub tooltip is readable and compact — stacked 3-line layout (line 1: icon + time, line 2: temperature + feels-like, line 3: rain) with 70-80% background opacity so it does not block the graph"
created: 2026-10-15T00:00:00Z
updated: 2026-10-15T00:00:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: Single-row tooltipPill RowLayout + monolithic formatTooltipMetric string + opaque fill cause the over-long single-line opaque tooltip
test: Read WeatherGraph.qml tooltipPill region (lines 930-979) and formatTooltipMetric (lines 364-392); grep assert script Section 4
expecting: RowLayout with all fields inline, single concatenated metric string, opaque color token, no stacked-layout/opacity asserts
next_action: Return ROOT CAUSE FOUND (goal is find_root_cause_only)

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: Hover-scrub tooltip readable, compact stacked layout, semi-transparent background not obscuring graph
actual: "tooltip works, readable, very good — but too long single line showing hour + icon + temp + feels-like + rain all in one line. Wants stacked 3 lines: top icon+time, next temp+feels, next rain. Background should be 70-80% opacity."
errors: None reported
reproduction: Test 3 in UAT — hover-scrub across graph in weather popup, observe tooltip pill
started: Discovered during UAT 2026-10-15

## Eliminated
<!-- APPEND only - prevents re-investigating -->

(none — first hypothesis confirmed directly)

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-10-15
  checked: WeatherGraph.qml lines 930-979 (tooltipPill)
  found: Pill body is a single `RowLayout { id: tooltipRow, spacing: 6 }` holding temporal-label + "•" + glyph + "•" + one metric StyledText — all fields forced onto one horizontal line. `implicitWidth: tooltipRow.implicitWidth + 20` grows unbounded with content length.
  implication: There is no ColumnLayout / stacked-line structure in the pill; single-line layout is structural, not a data edge case.
- timestamp: 2026-10-15
  checked: WeatherGraph.qml lines 364-392 (formatTooltipMetric "temp" branch)
  found: Returns one concatenated string `t + "°C (Feels " + f + "°C) • Rain " + prob + "% (" + mm + "mm)"` — temp, feels-like, and rain fused into a single Text element.
  implication: Even a layout change alone cannot stack the lines without splitting this string (or adding per-line accessors); matches user report of "hour + icon + temp + feels-like + rain all in one line" exactly.
- timestamp: 2026-10-15
  checked: WeatherGraph.qml line 934 (pill fill) + grep for Qt.rgba/opacity in pill region
  found: `color: Appearance.m3colors.m3surfaceContainerHigh || Appearance.colors.colLayer1` — fully opaque fill; zero alpha/opacity handling anywhere in tooltipPill region (only opacity in file is the scrubOverlay fade at line 900).
  implication: Background opacity 70-80% requirement has no implementation; pill fully occludes graph beneath it.
- timestamp: 2026-10-15
  checked: scripts/phase54.3-weather-assert.sh Section 4 (lines 477-569)
  found: Section 4 asserts flip-on-Y<60, 6px edge clamping, formatTooltipMetric presence, 150ms fade, and type-size tokens (smaller/small, floor absent) — nothing asserts stacked lines or background alpha.
  implication: Explains why automated harness is green (tests 10/D4 pass) while UAT Test 3 fails — this requirement class has no gate.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: tooltipPill in WeatherGraph.qml uses a single horizontal RowLayout (tooltipRow) fed by a monolithic single-string formatTooltipMetric return, with a fully opaque surface fill — producing one over-long opaque line instead of the stacked 3-line 70-80% opacity pill
fix:
verification:
files_changed: []
