---
status: complete
phase: 14-script-backed-widgets
source: [14-01-SUMMARY.md, 14-02-SUMMARY.md, 14-03-SUMMARY.md]
started: 2026-05-22T00:00:00Z
updated: 2026-05-22T12:10:00Z
completed: 2026-05-22T12:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. All 14 Widgets Visible in Groups
expected: Bar shows 14 widgets total. Left: Workspaces, Cpu, Memory, Disk, Network, Ping. Center: Weather, Clock, Forecast. Right: Music, Volume, Backlight, Notification, Tray. Each with icon + data.
result: issue
reported: "data is wrong and has errors"
severity: major

### 2. CPU Widget Color Thresholds
expected: CpuWidget shows  icon + cpuPercentFormatted. Color changes at usage thresholds (low/green, med/yellow, high/red).
result: issue
reported: "cpu is not responsive enough, it does not update instantly"
severity: minor

### 3. Memory Widget Tooltip
expected: MemoryWidget shows  icon + MemoryService.text. Hovering shows a tooltip with detailed memory info.
result: issue
reported: "2 icons, text ok, tooltip doesn't work for any widget — need to remove tooltip entirely"
severity: major

### 4. Disk Widget Opens Nautilus
expected: DiskWidget shows  icon + DiskService.text. Clicking launches nautilus file manager.
result: issue
reported: "don't like the icon, throws error"
severity: major

### 5. Network Widget Opens nmtui
expected: NetworkWidget shows icon + SSID name. Clicking opens kitty terminal with nmtui.
result: issue
reported: "shows disconnected, clicking does nothing"
severity: major

### 6. Ping Widget Color-Coded Status
expected: PingWidget shows 󰀶 icon + PingService.text. Color reflects status class (good=green, dead=red, bad=yellow, etc.).
result: issue
reported: "󰀶 icon is not needed"
severity: minor

### 7. Backlight Scroll Adjustment
expected: BacklightWidget shows  icon + brightness percentage. Scrolling up/down adjusts display brightness.
result: issue
reported: "throwing error, scrolling up/down adjustment is not needed"
severity: major

### 8. Notification Widget Click Toggles swaync
expected: NotificationWidget shows 󰂚 bell icon + notification count. Clicking toggles swaync notification center.
result: pass

### 9. Weather Widget Tooltip
expected: WeatherWidget shows WeatherService.text with conditions. Hovering shows tooltip with extended forecast details.
result: issue
reported: "weather widget is good but tooltip is not good"
severity: major

### 10. Clock Widget Colored Text
expected: ClockWidget shows time in Colours.clockColor. Text color matches the defined semantic alias.
result: issue
reported: "clock absolutely does not work, shows format string with {} brackets"
severity: major

### 11. Forecast Widget Tooltip
expected: ForecastWidget shows ForecastService.text. Hovering shows tooltip with extended forecast.
result: issue
reported: "widget works, tooltip is useless need to remove it"
severity: minor

### 12. Volume OSD on Volume Change
expected: Changing volume shows a PopupWindow overlay with a 150x8px Catppuccin-styled pill progress bar. It auto-hides after 1.5 seconds and does not steal keyboard focus.
result: issue
reported: "it does not show any popup window"
severity: major

## Summary

total: 12
passed: 1
issues: 11
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "All 14 widgets show correct data without errors"
  status: failed
  reason: "User reported: data is wrong and has errors"
  severity: major
  test: 1
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "CPU widget updates responsively with color thresholds"
  status: failed
  reason: "User reported: cpu is not responsive enough, it does not update instantly"
  severity: minor
  test: 2
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Memory widget shows correct icon and working tooltip on hover"
  status: failed
  reason: "User reported: 2 icons, text ok, tooltip doesn't work for any widget — need to remove tooltip entirely"
  severity: major
  test: 3
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Disk widget opens Nautilus on click without errors"
  status: failed
  reason: "User reported: don't like the icon, throws error"
  severity: major
  test: 4
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Network widget opens nmtui on click"
  status: failed
  reason: "User reported: shows disconnected, clicking does nothing"
  severity: major
  test: 5
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Ping icon is displayed appropriately"
  status: failed
  reason: "User reported: 󰀶 icon is not needed"
  severity: minor
  test: 6
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Backlight scroll works without errors"
  status: failed
  reason: "User reported: throwing error, scrolling up/down adjustment is not needed"
  severity: major
  test: 7
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Weather widget tooltip works on hover"
  status: failed
  reason: "User reported: weather widget is good but tooltip is not good"
  severity: major
  test: 9
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Clock widget displays formatted time in correct color"
  status: failed
  reason: "User reported: clock absolutely does not work, shows format string with {} brackets"
  severity: major
  test: 10
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Forecast tooltip works on hover"
  status: failed
  reason: "User reported: widget works, tooltip is useless need to remove it"
  severity: minor
  test: 11
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
- truth: "Volume OSD popup appears on volume change"
  status: failed
  reason: "User reported: it does not show any popup window"
  severity: major
  test: 12
  artifacts: []
  missing: []
  root_cause: ""
  debug_session: ""
