---
status: diagnosed
trigger: "Diagnose UAT gap G-54.3-2 for Phase 54.3 (interactive-multi-metric-hourly-graph-component). Goal: find_root_cause_only."
created: 2026-10-15T00:00:00Z
updated: 2026-10-15T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED — G-54.3-2 is caused by (a) zero legend constructs in WeatherGraph.qml, (b) curve/dashed/bar series reusing the same 2-3 M3 color tokens, (c) Canvas fillText calls with wrong font/alignment/clipping that overlap inside and outside the plot.
test: Code inspection of WeatherGraph.qml Canvas painting, color assignments, legend search, fillText geometry (no fix applied — diagnose-only).
expecting: N/A — root cause confirmed by direct code observation.
next_action: Return ROOT CAUSE FOUND to orchestrator (find_root_cause_only; no fix).

## Symptoms

expected: Dual-tier graph visualizations must be clear with distinct colors, explicit legends explaining what curves/bars represent, and no text overlapping outside or inside the graph (Test 2: per-tab dual-tier Canvas, upper ~70% splines + lower ~30% context bars for Temp/Rain/Wind/AQI/Baro/UV).
actual: "curves and histograms lack meaning, colors are all the same, missing legends for solid/dashed curves and histograms, and text is overlapping outside the graph making it unreadable"
errors: none (visual defect, no exceptions)
reproduction: Test 2 in 54.3-UAT.md
started: Discovered during UAT

## Eliminated

- hypothesis: Overlap is caused only by the popup card layout (WeatherPopup.qml / WeatherBaseCard.qml margins)
  evidence: WeatherPopup.qml is a plain ColumnLayout stack (880px wide, spacing 12, clip:true) and WeatherBaseCard.qml is a plain header+content card — no absolute-positioned siblings that could collide. All overlapping strings (axis labels, NOW badge, date chip, glyphs, timestamps) are painted INSIDE the single graph Canvas via fillText. Overlap originates in Canvas paint code, not card layout. Timestamp: 2026-10-15.

## Evidence

- timestamp: 2026-10-15
  checked: Searched WeatherGraph.qml + whole weather/ dir for legend constructs
  found: Zero matches for "legend/Legend" in WeatherGraph.qml (only hit in repo is unrelated WaveVisualizer.qml). File contains tab pills, one Canvas, scrub overlay — no legend row/items explaining solid vs dashed vs bars for any of the 6 metrics.
  implication: "Missing legends" is absence-of-code, not a styling bug. Nothing explains curve/bar meaning on any tab.

- timestamp: 2026-10-15
  checked: Color assignments — getActiveMetricColor() (lines 278-303), primary stroke (803), secondary dashed (817), lower bars (849/875/893), gradient fill (782-796)
  found: Primary solid uses getActiveMetricColor(); secondary dashed is HARDCODED to colSecondary for every metric (line 817); temp/rain lower bars use colPrimary (line 849) — identical token to the temp solid curve; AQI bars use colSecondary (875) — identical token to every dashed curve; UV bars use colTertiary (893). Rain primary (m3primary||colSecondary) vs rain bars (colPrimary) are near-identical M3 primary shades. Net: solid/dashed/bar series drawn from the same 2-3 tokens with no per-series distinct hues.
  implication: Directly produces "colors are all the same" — e.g. Temp tab solid curve and rain bars are both colPrimary; user cannot distinguish series by color.

- timestamp: 2026-10-15
  checked: Lower-tier bar semantics per metric (lines 831-898)
  found: Wind bars use FIXED height (lowerH*0.7, line 867) for every slot — bar height encodes no data value, only direction hue (3 colors). Cardinal directions are never painted as text though Test 2 expects "cardinal directions". Only one metric is visible at a time (activeMetric switch) with no labels on the series themselves.
  implication: Produces "lack meaning" — uniform-height wind bars look like meaningless histogram blocks; without a legend there is no way to know what any curve/bar encodes.

- timestamp: 2026-10-15
  checked: Y-axis guideline labels (lines 705-776: fillText at plotLeft-10 / plotLeft-12 with no ctx.textAlign set in those save/restore blocks)
  found: Labels ("1013 hPa", "UV 6 High", "50%", "NN°") are painted at x=2-4px with default "start" alignment, so multi-char strings extend rightward INTO the plot area over the curves; yHigh/yLow guide positions can sit near plotTop where the NOW badge/date-chip live.
  implication: Guideline text overlaps curves inside the graph and risks clipping at the canvas edge — inside-graph overlap contributor.

- timestamp: 2026-10-15
  checked: Top-margin collision — NOW badge (badgeY=plotTop-14=6, 32x14 rect, lines 628-642) vs midnight dateChip fillText at (midX, plotTop-4=16) (lines 606-611); plotTop=20 fixed
  found: Both occupy the same 0..20px strip above the plot with 9px fonts and no collision avoidance; if a midnight boundary falls within ~1 slot of slot 12, badge rect and date-chip text overlap each other and the hairline.
  implication: Outside/above-graph text overlap contributor.

- timestamp: 2026-10-15
  checked: Bottom axis band (lines 900-943) + WeatherGlyphs.getGlyph() ligature values (services/WeatherGlyphs.qml lines 95-111: "snowing_heavy" etc.)
  found: Condition glyphs are Material-Symbols ligature strings painted with ctx.font="12px sans-serif" (line 910) — Canvas has no access to the Material Symbols font, so it renders LITERAL words (e.g. "snowing_heavy", 13 chars) centered in ~32px slots (slotW=(852)/25-26), so adjacent words collide; timestamps at height-2 sit only 12px below 12px glyphs at height-14 while plotLowerBottom=height-28 reserves just 28px for two text rows.
  implication: Strongest outside-graph overlap contributor — literal icon-name words wider than their slots overlapping neighbors + timestamps, matching "text are overlapping ... outside of things ... can't see anything".

## Resolution

root_cause: "WeatherGraph.qml Canvas has (1) no legend constructs at all (zero legend code — solid/dashed/bar meaning is never explained on any tab); (2) series colors reused across series — secondary dashed hardcoded to colSecondary (L817), temp/rain lower bars painted colPrimary identical to the temp solid curve (L849 vs L803), AQI bars colSecondary identical to every dashed curve (L875), rain primary m3primary vs bars colPrimary near-identical — so curves/bars/dashes are visually indistinguishable; (3) fillText geometry defects — y-guideline labels at x=2-4px with default start-alignment run into the plot, NOW badge rect (y6..20) and midnight dateChip (y16) share one 20px strip with no avoidance, and bottom-axis Material-Symbols ligatures (e.g. 'snowing_heavy') are painted in 12px sans-serif so literal words wider than the ~32px slots collide with each other and the timestamp row 12px below in a 28px band"
fix: none (diagnose-only mode — no fix applied)
verification: none (diagnose-only; verification belongs to the fix phase — suggested checks: per-tab screenshots asserting distinct series hues, legend row present, no fillText glyph word-strings, axis labels right-aligned inside margins)
files_changed: []
