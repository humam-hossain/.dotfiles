---
status: investigating
trigger: "UAT gap G-54.3-2: per-metric legends/axes — all graph cards show same temp-composite legend, missing Y-axis values on UV/AQI/wind, clipped pressure labels"
created: 2026-10-15T00:00:00Z
updated: 2026-10-15T00:00:00Z
---

## Current Focus
hypothesis: CONFIRMED — five distinct mechanisms, all in WeatherGraph.qml; paint branches keyed off activeMetric but legend/axis-icons/tooltip bindings are not; wind/aqi/uv guideline absence is deliberate per D-54.3-15
test: none remaining — diagnosis complete
expecting: n/a
next_action: return ROOT CAUSE FOUND (diagnose-only mode, no fix)

## Symptoms
expected: Each stacked graph card shows its own per-metric legend, Y-axis labels, and tooltip readout matching its metric
actual: All cards show same temp-composite legend/icons; UV/AQI/wind cards have no Y-axis values; pressure labels clipped to 2 digits
errors: None reported.
reproduction: Test 2 in .planning/phases/54.3-interactive-multi-metric-hourly-graph-component/54.3-UAT.md
started: Discovered during UAT 2026-10-15.

## Eliminated
- hypothesis: per-instance activeMetric bindings missing or wrong in WeatherPopup.qml
  evidence: WeatherPopup.qml lines 55-96 show exactly 5 instances with correct locked bindings (temp/wind/aqi/baro/uv) and per-card title overrides — bindings are correct
  timestamp: 2026-10-15

## Evidence
- timestamp: 2026-10-15
  checked: WeatherGraph.qml legendRow (lines 503-589)
  found: Three static entries "Actual temp" / "Feels-like" / "Rain chance (darker = heavier)" with zero references to root.activeMetric anywhere in the legend subtree
  implication: Every card renders the temp-composite legend regardless of metric — mechanism 1
- timestamp: 2026-10-15
  checked: WeatherGraph.qml canvas guideline branches (lines 761, 787); grep for activeMetric in file
  found: Only two guideline branches exist — temp (line 761) and baro (line 787). No wind/aqi/uv branch. 54.3-08-PLAN.md line 118 explicitly ordered "Add no guideline branches for wind, aqi, or uv; their fixed or zero-anchored scales need none per D-54.3-15"
  implication: Missing Y-axis values on wind/AQI/UV cards are deliberate per D-54.3-15, not an oversight — mechanism 2, and the decision contradicts the UAT Test 2 truth requiring per-card Y-axis labels
- timestamp: 2026-10-15
  checked: WeatherGraph.qml baro guideline labels (lines 797-810) + plotLeft gutter (line 610)
  found: Baro labels render full "NNNN hPa" strings right-aligned ending at plotLeft-4 = x30px; gutter is 34px since plan 07. A 4-digit "1013 hPa" string at 9px sans exceeds ~30px available, so leading digits clip — matches "only 2 digits visible". Temp labels ("23°") fit the same gutter, which is why only baro clips
  implication: Baro clipping is a width/fit defect, distinct from the missing-branch mechanism — mechanism 3
- timestamp: 2026-10-15
  checked: WeatherGraph.qml axisIconStrip (lines 1111-1140)
  found: Repeater delegate always renders modelData.glyph (weather condition icon) with visibility gated only on axisStride; no reference to root.activeMetric and no per-metric icon mapping exists
  implication: All five cards show identical condition icons — mechanism 4
- timestamp: 2026-10-15
  checked: WeatherGraph.qml tooltip pill bindings (lines 1095-1106) vs formatTooltipMetric helper (lines 394-495)
  found: Pill binds directly to formatTooltipTempLine + formatTooltipRainLine. The per-metric formatTooltipMetric(metricKey, slot) helper handles all six metrics but is never called from QML — dead code path. Matches 54.3-08-SUMMARY note "per-metric tooltip readout split deliberately NOT done" (also gap G-54.3-3)
  implication: Every card's tooltip shows temp/rain readout — mechanism 5, a deliberate deferral now user-visible

## Resolution
root_cause: "(1) Legend row hardwired to temp composite — legendRow subtree (WeatherGraph.qml:503-589) contains only static 'Actual temp'/'Feels-like'/'Rain chance' entries with zero activeMetric references, while canvas paint branches ARE keyed; (2) No Y-axis guideline branches for wind/aqi/uv — deliberate per D-54.3-15 (54.3-08-PLAN.md:118 ordered none for fixed/zero-anchored scales), which directly contradicts the UAT Test 2 truth requiring per-card Y-axis labels; (3) Baro 'NNNN hPa' labels drawn right-aligned into the 34px gutter (WeatherGraph.qml:797-810, plotLeft=34) exceed available width so leading digits clip — a fit defect distinct from (2); (4) Axis icon strip (WeatherGraph.qml:1111-1140) always renders condition glyph with no activeMetric keying and no per-metric icon mapping; (5) Tooltip pill (WeatherGraph.qml:1095-1106) binds directly to formatTooltipTempLine/formatTooltipRainLine while the existing per-metric formatTooltipMetric helper (lines 394-495) is never called — deliberate deferral per 54.3-08-SUMMARY, also covering G-54.3-3"
fix:
verification:
files_changed: []
