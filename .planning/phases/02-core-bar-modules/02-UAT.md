---
status: retest
phase: 02-core-bar-modules
source: 02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md, 02-04-SUMMARY.md, 02-05-SUMMARY.md, 02-06-SUMMARY.md, 02-07-SUMMARY.md, 02-08-SUMMARY.md, 02-VERIFICATION.md
started: 2026-07-21T17:34:11Z
updated: 2026-07-21T18:33:16Z
---

## Current Test

[testing complete]

## Tests

### A1. Live config assert script encodes D-01..D-03, D-05, D-13, D-14, D-16 predicates
expected: Live config assert script encodes D-01..D-03, D-05, D-13, D-14, D-16 predicates
result: pass
source: automated
coverage_id: 02-01-D1

### A2. VALIDATION.md Wave 0 complete with task ID map and assert command
expected: VALIDATION.md Wave 0 complete with task ID map and assert command
result: pass
source: automated
coverage_id: 02-01-D2

### A3. Clock format and secondPrecision in Config + live JSON
expected: Clock format and secondPrecision in Config + live JSON
result: pass
source: automated
coverage_id: 02-02-D1

### A4. Full-color tray + pin policy dual-written
expected: Full-color tray + pin policy dual-written
result: pass
source: automated
coverage_id: 02-02-D2

### A5. Workspace appearance + weather-off locked
expected: Workspace appearance + weather-off locked
result: pass
source: automated
coverage_id: 02-02-D3

### A6. Left L→R LeftSidebar ActiveWindow Workspaces Resources
expected: Left L→R LeftSidebar ActiveWindow Workspaces Resources
result: pass
source: automated
coverage_id: 02-03-D1

### A7. Center clock with showDate false + UtilButtons
expected: Center clock with showDate false + UtilButtons
result: pass
source: automated
coverage_id: 02-03-D2

### A8. Right module order Media Battery SysTray Indicators
expected: Right module order Media Battery SysTray Indicators
result: pass
source: automated
coverage_id: 02-04-D1

### A9. Network.materialSymbol icon-only + D-19 indicator order
expected: Network.materialSymbol icon-only + D-19 indicator order
result: pass
source: automated
coverage_id: 02-04-D2

### A10. Stock workspace click/wheel dispatch (D-04); no plugin focus dispatcher
expected: Stock workspace click/wheel dispatch (D-04); no plugin focus dispatcher
result: pass
source: automated
coverage_id: 02-05-D1

### A11. ClockWidgetPopup path; showDate false; no external calendar URL
expected: ClockWidgetPopup path; showDate false; no external calendar URL
result: pass
source: automated
coverage_id: 02-05-D2

### A12. SysTray present; live tray monochrome false + pin policy
expected: SysTray present; live tray monochrome false + pin policy
result: pass
source: automated
coverage_id: 02-05-D3

### A13. Network.materialSymbol icon-only; D-19 indicator order; smoke load
expected: Network.materialSymbol icon-only; D-19 indicator order; smoke load
result: pass
source: automated
coverage_id: 02-05-D4

### 1. Click workspace switches focus
expected: Click workspace N on the bar; active Hyprland workspace changes to N
result: pass


### 2. Wheel cycles workspaces
expected: Scroll on the workspaces strip; workspace cycles with workspace r±1 behavior
result: pass


### 3. Clock updates each second
expected: Bar clock shows weekday, date, 12-hour time with seconds and AM/PM; seconds tick each second
result: pass


### 4. Clock click opens ClockWidgetPopup
expected: Click clock; popup shows date/uptime/todos — not Google Calendar
result: pending_retest
reported: "hover shows a popup with date, uptime, todo but clicking does not do anything"
severity: major
fix_plan: 02-06
fix_note: "forceActive pin + onClicked shipped — re-verify click open/pin"


### 5. Tray icons full-color + interactive
expected: Tray icons full-color (e.g. Discord/Steam); left-click activates; right-click opens menu
result: pass


### 6. Network icon state + SSID via sidebar
expected: Toggle wifi; network icon glyph changes; open right sidebar to see SSID/signal (no SSID text on bar)
result: pass


### 7. Module L→R order (D-15)
expected: Left: sidebar → workspaces → resources (no ActiveWindow); Center: clock → utils; Right: media → battery → tray → indicators
result: pending_retest
reported: "i would like to remove window, it is taking too much space and there is no need. on the indicator only network is there, after it a space only"
severity: major
fix_plan: 02-07, 02-08
fix_note: "ActiveWindow removed; always-visible indicators — re-verify layout + strip"


### 8. Indicators pill order (D-19)
expected: Indicators order left-to-right: mute → mic → xkb → Bluetooth → Network → notif
result: pending_retest
reported: "no just network"
severity: major
fix_plan: 02-08
fix_note: "Always-visible D-19 strip shipped — re-verify full pill"


### 9. Dual-monitor workspaces 1–10
expected: If HDMI attached: DP-1 shows workspaces 1–5, HDMI-A-2 shows 6–10 (skip if single monitor)
result: skipped
reason: HDMI-A-2 is not connected at the moment


## Summary

total: 22
passed: 18
issues: 0
pending_retest: 3
pending: 0
skipped: 1
blocked: 0

## Gaps

- gap_id: G-02-4
  truth: "Click clock; popup shows date/uptime/todos — not Google Calendar"
  status: pending_retest
  reason: "Code fix shipped in 02-06 (forceActive + onClicked); needs human re-UAT"
  severity: major
  test: 4
  fixed_by: 02-06
  commits: [3a852d3, 14eea6e]
  debug_session: ".planning/debug/resolved/clock-click-no-op.md"

- gap_id: G-02-7a
  truth: "Left region has no ActiveWindow; workspaces have room"
  status: pending_retest
  reason: "Code fix shipped in 02-07 (ActiveWindow removed); needs human re-UAT"
  severity: major
  test: 7
  fixed_by: 02-07
  commits: [113b10a]
  debug_session: ".planning/debug/resolved/remove-active-window.md"

- gap_id: G-02-7b
  truth: "Indicators pill shows mute → mic → xkb → Bluetooth → Network → notif (D-19)"
  status: pending_retest
  reason: "Code fix shipped in 02-08 (always-visible strip); needs human re-UAT"
  severity: major
  test: 7
  fixed_by: 02-08
  commits: [71022b9]
  debug_session: ".planning/debug/resolved/indicators-only-network.md"

- gap_id: G-02-8
  truth: "Indicators order left-to-right: mute → mic → xkb → Bluetooth → Network → notif"
  status: pending_retest
  reason: "Code fix shipped in 02-08 (same strip as G-02-7b); needs human re-UAT"
  severity: major
  test: 8
  fixed_by: 02-08
  commits: [71022b9]
  debug_session: ".planning/debug/resolved/indicators-only-network.md"

