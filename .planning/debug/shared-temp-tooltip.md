---
status: diagnosed
phase: 54.3-interactive-multi-metric-hourly-graph-component
gap: G-54.3-3
test: 3 (54.3-UAT.md)
symptoms_prefilled: true
goal: find_root_cause_only
---

# Debug: shared temp tooltip on every card (G-54.3-3)

## Current Focus

status: diagnosed
hypothesis: CONFIRMED (shared mechanism with G-54.3-2 finding 5 — no separate investigation needed)
finding: Tooltip pill is hardwired to the temp composite on all five instances.

## Symptoms (from UAT Test 3)

- truth: Hover-scrub tooltip on each card shows that card's own metric readout, not the temperature composite everywhere.
- actual: Every card's hover tooltip shows the same temperature/feels-like/rain readout.
- errors: None reported.

## Evidence (derived from .planning/debug/per-metric-legends-axes.md investigation)

- Tooltip pill (WeatherGraph.qml:1095-1106) binds directly to `formatTooltipTempLine` / `formatTooltipRainLine` — zero `activeMetric` references in the pill subtree.
- The per-metric `formatTooltipMetric(metricKey, slot)` helper (WeatherGraph.qml:394-495, all six metrics implemented) has ZERO QML call sites — dead code path.
- 54.3-08-SUMMARY documents this as a deliberate deferral ("per-metric tooltip readout split deliberately NOT done"), which the user has now explicitly rejected as wrong behavior — so it is a real gap, not a follow-up.
- The stacked 3-line layout and 0.75 background opacity from plan 07 are orthogonal and stay as-is; only the readout *content* needs keying off `root.activeMetric`.

## Resolution

root_cause: "Tooltip pill binds directly to formatTooltipTempLine/formatTooltipRainLine (WeatherGraph.qml:1095-1106) with no activeMetric keying, while the existing per-metric formatTooltipMetric helper (:394-495) has zero QML call sites — deliberate plan-08 deferral the user has now rejected."

## Files Involved

- restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml: tooltip pill bindings (:1095-1106) vs unused per-metric helper (:394-495)

## Suggested Fix Direction (NON-BINDING)

Wire the pill rows to per-metric line helpers fed by `formatTooltipMetric(root.activeMetric, slot)` (temp branch keeps the existing 3-line layout; other metrics get analogous per-line splits); keep the 0.75 background-only opacity untouched.
