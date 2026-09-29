---
status: diagnosed
phase: 47-center-zone-layout-reorganization
source: [47-VERIFICATION.md]
started: 2026-09-29T18:28:00Z
updated: 2026-09-29T22:06:40+06:00
---

## Current Test

[testing complete]

## Tests

### 1. Visual center alignment
expected: Workspaces widget appears visually centered on the bar across different screen widths
result: pass

### 2. Clock/Weather flanking
expected: Clock shows to the left and Weather to the right of Workspaces
result: pass

### 3. Sidebar toggle
expected: Click Clock area and verify right sidebar toggles
result: issue
reported: "nope it does not and it does need to do anything when i click on it"
severity: major

### 4. Responsive date collapse
expected: Narrow the window below 900px and confirm date text hides
result: pass

## Summary

total: 4
passed: 3
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-47-3
  truth: "Click Clock area and verify right sidebar toggles"
  status: failed
  reason: "User reported: nope it does not and it does need to do anything when i click on it"
  severity: major
  test: 3
  root_cause: "Event absorption in ClockWidget inner MouseArea prevented clicks reaching outer MouseArea; furthermore, user confirmed clock does not need to toggle sidebar (historical remnant from when clock was on right side)"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
      issue: "leftCenterGroup wrapped in unnecessary MouseArea with sidebarRightOpen toggle"
    - path: "scripts/phase47-center-layout-assert.sh"
      issue: "Section 2 checks for sidebarRightOpen toggle on leftCenterGroup"
  missing:
    - "Simplify leftCenterGroup in BarContent.qml to a plain BarGroup, removing MouseArea wrapper and toggle"
    - "Update test harness scripts/phase47-center-layout-assert.sh Section 2 to assert BarGroup structure without sidebar toggle"
  debug_session: .planning/debug/sidebar-toggle.md
