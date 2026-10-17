---
status: investigating
trigger: "Diagnose UAT gap G-54.3-5 for Phase 54.3 (interactive-multi-metric-hourly-graph-component). Goal: find_root_cause_only."
created: 2026-10-15T07:01:24Z
updated: 2026-10-15T07:01:24Z
---

## Current Focus

hypothesis: Overlapping is caused by (A) WeatherBaseCard content-sizing collapse — anchored children contribute zero implicit size so all non-graph cards collapse to header height and overflow onto siblings — compounded by (B) bottom-axis glyph strip drawing literal Material-Symbol ligature names in sans-serif, which overlap across slots and collide with timestamps.
test: Code-level geometry/layout analysis of WeatherBaseCard.qml, WeatherGraph.qml canvas bands, WeatherGlyphs.qml values, and Phase 54 UAT history
expecting: Confirmed A as primary structural cause, B as direct Test-5 element cause
next_action: Return ROOT CAUSE FOUND (find_root_cause_only — no fixes)

## Symptoms

expected: Night shading, midnight divider with date chip, bottom axis time labels with NOW highlight, mini condition glyphs — all rendering without visual collisions or overlapping text (Test 5)
actual: "apart from graphs everything looks like hell, overlapping each other so i don't know where to even look at"
errors: none (layout/visual defect, no runtime errors)
reproduction: Open weather popup, scroll to hourly graph card and surrounding cards (Test 5 in 54.3-UAT.md)
started: Chronic — identical overlapping/spacing failure already reported in Phase 54 UAT Test 1 (pre-54.3, blocker severity), carried forward through 54.3

## Eliminated

- hypothesis: Flickable height clamping or 440px card width as the primary collision driver
  evidence: WeatherPopup.qml uses implicitWidth 880 (doubled from 440 in ea793c4f); paired cards get ~434px each — ample width. Overlap reproduces from height collapse + canvas label geometry independent of width. Width is not the binding constraint.
  timestamp: 2026-10-15T07:01:24Z

## Evidence

- timestamp: 2026-10-15T07:01:24Z
  checked: restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBaseCard.qml
  found: Content host is a bare `Item { Layout.fillWidth:true; Layout.fillHeight:true }` (lines 53-57) exposed via `default property alias content: cardContent.data`. Every consumer fills it with `anchors.fill: parent` (Hero RowLayout, Graph ColumnLayout, Atmospheric GridLayout, Wind/Aqi/Astronomy layouts).
  implication: Anchored children contribute ZERO to implicitWidth/implicitHeight; bare Item implicit size is 0x0, so `layout.implicitHeight` ≈ headerRow only and every card's `implicitHeight = layout.implicitHeight + 20` collapses to ~header height — except WeatherGraph which hardcodes `implicitHeight: 400`.

- timestamp: 2026-10-15T07:01:24Z
  checked: Rectangle clipping default + popup stacking (WeatherPopup.qml, WeatherBaseCard.qml)
  found: Card Rectangle sets no `clip: true` (defaults false). Collapsed ~50px cards contain 80-150px of inner content that paints past card bounds over adjacent cards/rows. Flickable `contentHeight: contentColumn.implicitHeight` inherits the collapsed sum, so scroll viewport also mismatches real painted height.
  implication: This is the "everything overlapping each other" mechanism — structural, affects all cards outside the graph.

- timestamp: 2026-10-15T07:01:24Z
  checked: WeatherGraph.qml bottom axis band (lines 900-943) + WeatherGlyphs.qml mapping + Weather.qml glyph assignment
  found: Glyph row draws `h.glyph` — a Material Symbol LIGATURE NAME ("partly_cloudy_day", "weather_hail", "cloudy_snowing", 6-17 chars) — with `ctx.font = "12px sans-serif"` (line 910), i.e. literal words, not icons. Slot width ≈ (860-28)/25 ≈ 33px; a 17-char word at 12px ≈ 110px wide spanning 3+ slots, drawn every 4 slots (~132px apart) → adjacent glyph labels overlap. Glyph baseline at height-14 with 12px font vs timestamp baseline at height-2 with 9px font → only ~12px separation, descenders collide; timestamp half-clips at canvas edge.
  implication: Direct hit on Test 5's own acceptance elements (axis labels + mini glyphs). User reads words piled on words.

- timestamp: 2026-10-15T07:01:24Z
  checked: WeatherGraph.qml top band — NOW badge (lines 629-642) vs midnight date chip (lines 595-614)
  found: NOW badge rect occupies y 6..20 around slot-12 center; date-chip text baseline at y=16 (plotTop-4). Rolling 25h window routinely places the midnight boundary within 1-2 slots (~33-66px) of NOW; chip (~40px wide) and badge (32px wide) then overlap.
  implication: Secondary contributor — intermittent chip/badge collision at canvas top.

- timestamp: 2026-10-15T07:01:24Z
  checked: .planning/phases/54-multi-modal-popup-inspector-interactive-graphs/54-UAT.md Test 1
  found: Phase 54 (pre-54.3) UAT already failed with blocker severity on "spacing and everything is overlapping with each other" against the same WeatherBaseCard/WeatherPopup structure; Tests 2-4 skipped, redesign deferred to phased rework (54.1-54.4).
  implication: Proves the card-collapse overlap is chronic/inherited, NOT a 54.3 regression — 54.3 added canvas content on top of an already-broken card scaffold.

## Resolution

root_cause: (A PRIMARY — code/layout) WeatherBaseCard content-sizing collapse — bare-Item content host + anchors.fill children contribute zero implicit size, so all non-graph cards collapse to header-only height and their unclipped content overflows onto siblings; Flickable contentHeight inherits the collapsed sum. (B DIRECT — code/rendering) Bottom-axis band draws multi-character Material-Symbol ligature names as literal sans-serif words (~110px in 33px slots, every 4 slots) overlapping each other and the timestamp row 12px below. (C SECONDARY — code/geometry) NOW badge rect (y6-20) collides with midnight date-chip text (baseline y16) whenever the rolling window places midnight near slot 12.
fix:
verification:
files_changed: []
