---
status: investigating
trigger: "Y-axis labels clipped on left, no top/left padding — Phase 54.3 UAT gap G-54.3-1 (goal: find_root_cause_only)"
created: 2026-10-15T00:00:00Z
updated: 2026-10-15T00:00:00Z
---

## Current Focus
hypothesis: "Y-axis guideline labels are drawn right-aligned ending at x = plotLeft - 4 = 10px, so their ~15-22px-wide glyphs extend to negative x and are clipped by the canvas/card edge — leading digit(s) cut, only trailing digit visible"
test: "grep label anchors + arithmetic gutter check + harness gate audit (done — static proof, no live repaint needed)"
expecting: "confirmed — single label path, negative origin, no harness overflow gate"
next_action: "return ROOT CAUSE FOUND (find_root_cause_only — no fix)"

## Symptoms
expected: No tab/pill selector row; title "Hourly Temperature and Rain Outlook"; solid temp spline + dashed feels-like + rain bars visible simultaneously with fully legible Y-axis labels and even canvas padding
actual: User reported — left-side Y-axis values like 35/36 are cut, only last digit visible (sees 6 not 36). Bottom and right have padding, top and left have no padding.
errors: None reported
reproduction: Test 1 in UAT — restart quickshell (`qs -c ii`), open weather popup, look at graph card left edge
started: Discovered during UAT 2026-10-15

## Eliminated
- hypothesis: Stale quickshell session showing pre-fix QML (known co-root-cause pattern)
  evidence: UAT repro explicitly restarts qs (`qs -c ii`) before looking; symptom is a stable geometric clip (leading digits cut, asymmetric padding), not stale tab chrome or missing series — all three series ARE visible per report
  timestamp: 2026-10-15

## Evidence
- timestamp: 2026-10-15
  checked: WeatherGraph.qml onPaint geometry (lines 598-599)
  found: plotLeft = 14, plotRight = width - 14 — symmetric 14px side margins; canvas anchors.fill parent so canvas x=0 IS the visible left edge
  implication: Only 14px of headroom on the left for anything anchored to plotLeft
- timestamp: 2026-10-15
  checked: Y-axis guideline label draw calls (lines 752-774)
  found: ctx.textAlign = "right"; fillText(...bounds.max-1 + "°", plotLeft - 4, ...) and fillText(...bounds.min+1 + "°", plotLeft - 4, ...) — the ONLY two Y-label sites in the file; anchor x = 14 - 4 = 10, text extends LEFT from x=10 by its full width (~15-22px for a 3-glyph "36°" at 9px sans-serif; even 5px/glyph conservative = 15px > 10px available)
  implication: Label span is roughly [-5..-12, 10] — the x<0 portion is clipped by the Canvas (which clips all painting outside its bounds; WeatherBaseCard clip:true reinforces). Visible remnant is the rightmost ~10px = last digit + degree fragment — exactly the reported "sees 6 not 36"
- timestamp: 2026-10-15
  checked: Top-edge geometry (lines 604, 667, 646)
  found: plotTop = 20; NOW badge at badgeY = plotTop - 14 = 6 (occupies y 6-20, only 6px headroom); dateChip baseline at plotTop - 4 = 16; bottom reserves 46px (plotLowerBottom = height - 46) + 8px timestamp baseline
  implication: Explains the "no top padding" half — top headroom (6px) is far tighter than bottom (46px) and sides (14px); left labels additionally go negative, so left reads as zero padding
- timestamp: 2026-10-15
  checked: Assert harness Sections 3/5 for geometry-overflow coverage
  found: Harness asserts label PRESENCE (bounds.max-1 / bounds.min+1 strings), dual-tier coords, timestamp baseline (height - 8), chipDrawX — but zero asserts on label x-position, textAlign direction, or left-gutter sufficiency (grep for plotLeft|textAlign|fillText in harness returns nothing)
  implication: Presence-only gate passes a clipped label — explains why CI was green (9/12 incl. all automated) while the visual defect shipped; process gap, not a rendering co-cause
- timestamp: 2026-10-15
  checked: Falsification test for the hypothesis
  found: Hypothesis would be WRONG if labels were left/center-aligned or anchored at plotLeft + offset (fully on-canvas). Code shows the opposite: textAlign "right" at plotLeft - 4, the only Y-label path. Scrub overlay (line 1023) and axisIconStrip (leftMargin 14) reuse the same 14px gutter consistently — the label anchor is the sole outlier
  implication: Hypothesis survives falsification; no competing label path exists

## Resolution
root_cause: Y-axis guideline labels in WeatherGraph.qml are painted right-aligned ending at x = plotLeft − 4 = 10px (lines 755/767/773) while their ~15–22px glyph width needs >10px left of the anchor — text origin goes negative and the Canvas (plus WeatherBaseCard clip:true) clips it, leaving only the trailing digit visible; top NOW badge at y=6 similarly starves top padding. Harness asserts label presence only, with no left-gutter overflow gate, so CI stayed green.
fix:
verification:
files_changed: []
