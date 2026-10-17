---
status: investigating
trigger: "popup-uneven-padding UAT gap G-54.3-1"
created: 2026-10-15T00:00:00Z
updated: 2026-10-15T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED — unanchored StyledFlickable sits at popupBackground (0,0) at implicit size while background/window are margin*2 larger, leaving the 20px surplus as a dead strip on right+bottom
test: PySide6/Qt6 offscreen geometry experiments + differential vs sibling popups + git history
expecting: done — returning ROOT CAUSE FOUND (goal is find_root_cause_only, no fix)
next_action: return ROOT CAUSE FOUND

## Symptoms

expected: Inside the popup window there is even padding on left, right, top, and bottom around the cards.
actual: User reported padding visible on right and bottom but not on left and top around card stack inside popup window
errors: None reported.
reproduction: Test 1 in .planning/phases/54.3-interactive-multi-metric-hourly-graph-component/54.3-UAT.md
started: Discovered during UAT 2026-10-15.

## Eliminated

- hypothesis: Live tree differs from repo (stale symlink / stale quickshell session)
  evidence: Live WeatherPopup.qml is a symlink to repo file; diff IDENTICAL. UAT already applied stale-session guard (restart before looking).
  timestamp: 2026-10-15
- hypothesis: Right-side gap is the StyledScrollBar gutter reservation
  evidence: Single-mechanism theory (margin*2 surplus + top-left origin) predicts right AND bottom gaps simultaneously, exactly matching report; scrollbar cannot explain the bottom strip or the missing top gap.
  timestamp: 2026-10-15
- hypothesis: Card-internal margins (WeatherBaseCard anchors.margins: 10) cause the asymmetry
  evidence: Base-card margins are symmetric (anchors.margins: 10 on all sides) and user confirms cards themselves have correct padding; asymmetry is between card stack and popup window boundary (chrome level).
  timestamp: 2026-10-15

## Evidence

- timestamp: 2026-10-15
  checked: StyledPopup.qml popupBackground (lines 149-163)
  found: margin: 10 used ONLY in implicit-size math (implicitWidth = contentItem.implicitWidth + margin*2); child placed via children: [root.contentItem] with no positioning, so the +20px surplus is never distributed as real padding
  implication: Background/window are 20px wider+taller than content by construction
- timestamp: 2026-10-15
  checked: WeatherPopup.qml full read (135 lines) + grep for anchors in file
  found: StyledFlickable has zero anchors (no anchors.* anywhere in the file); sits at popupBackground origin (0,0) at implicit size 880 x min(contentH, 85% screenH)
  implication: Cards flush to left/top edges of background; 20px dead strip on right/bottom
- timestamp: 2026-10-15
  checked: Differential vs CpuGpuPopup, MemoryStoragePopup, ClockWidgetPopup (all use anchors.centerIn: parent for content root)
  found: WeatherPopup is the ONLY popup with unanchored content; siblings center content, splitting the 20px surplus into even 10px per side
  implication: Explains why only the weather popup shows the asymmetry
- timestamp: 2026-10-15
  checked: git history of WeatherPopup.qml (created 2b81caff in 54-01, never anchored)
  found: Flickable unanchored since creation; defect predates plan 06 layout-driven sizing work
  implication: Not a 54.3 regression; latent since 54-01, exposed by stacked full-width cards
- timestamp: 2026-10-15
  checked: PySide6/Qt6 offscreen geometry experiment (unanchored Item/Rectangle/Flickable with only implicit sizes)
  found: All render AT implicit size at parent (0,0) — Flickable w=880 h=500 at x=0 y=0 inside 900x600 parent, i.e. 20px strip right, 0 left
  implication: Empirically confirms the top-left-origin + right/bottom-surplus mechanism; matches user report exactly on all four sides
- timestamp: 2026-10-15
  checked: phase54.3-weather-assert.sh for popup-chrome padding gates
  found: Harness gates canvas-level padding (Y-label anchor/gutter math) and Layout.fillWidth structure only; no assertion on popup content anchoring
  implication: Why automation is green while UAT sees the chrome-level asymmetry
- timestamp: 2026-10-15
  checked: live vs repo diff + no flickable geometry references anywhere + no QML binding-loop warnings in journal
  found: live == repo; contentWidth: width resolves cleanly at 880 (no loop)
  implication: Deterministic Bohrbug in static layout math, not environment/data dependent

## Resolution

root_cause: WeatherPopup.qml StyledFlickable is unanchored, so it renders at popupBackground origin (0,0) at implicit size, while StyledPopup.popupBackground adds margin*2 (20px) to its implicit size for the window — the full 20px surplus lands as a dead strip on the right and bottom, with cards flush to the left/top (AND-gate: needs BOTH the margin-surplus in StyledPopup AND the missing anchors in WeatherPopup; sibling popups avoid it via anchors.centerIn splitting the surplus evenly)
fix:
verification:
files_changed: []
