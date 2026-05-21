---
status: resolved
phase: 14-script-backed-widgets
source: [14-01-SUMMARY.md, 14-02-SUMMARY.md, 14-03-SUMMARY.md]
started: 2026-05-21T00:00:00Z
updated: 2026-05-21T20:29:00Z
---

## Current Test

[gap closure applied — import QtQuick.Controls added to 6 widgets; quickshell should now load. Re-run UAT tests to verify.]

## Tests

### 1. All 14 Widgets Visible in Groups
expected: Bar shows 14 widgets total. Left: Workspaces, Cpu, Memory, Disk, Network, Ping. Center: Weather, Clock, Forecast. Right: Music, Volume, Backlight, Notification, Tray. Each with icon + data.
result: pending
reported: "Root cause fixed — import QtQuick.Controls added to all 6 widgets. Requires re-test on target hardware."
severity: blocker

### 2. CPU Widget Color Thresholds
expected: CpuWidget shows  icon + cpuPercentFormatted. Color changes at usage thresholds (low/green, med/yellow, high/red).
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 3. Memory Widget Tooltip
expected: MemoryWidget shows  icon + MemoryService.text. Hovering shows a tooltip with detailed memory info.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 4. Disk Widget Opens Nautilus
expected: DiskWidget shows  icon + DiskService.text. Clicking launches nautilus file manager.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 5. Network Widget Opens nmtui
expected: NetworkWidget shows icon + SSID name. Clicking opens kitty terminal with nmtui.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 6. Ping Widget Color-Coded Status
expected: PingWidget shows 󰀶 icon + PingService.text. Color reflects status class (good=green, dead=red, bad=yellow, etc.).
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 7. Backlight Scroll Adjustment
expected: BacklightWidget shows  icon + brightness percentage. Scrolling up/down adjusts display brightness.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 8. Notification Widget Click Toggles swaync
expected: NotificationWidget shows 󰂚 bell icon + notification count. Clicking toggles swaync notification center.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 9. Weather Widget Tooltip
expected: WeatherWidget shows WeatherService.text with conditions. Hovering shows tooltip with extended forecast details.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 10. Clock Widget Colored Text
expected: ClockWidget shows time in Colours.clockColor. Text color matches the defined semantic alias.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 11. Forecast Widget Tooltip
expected: ForecastWidget shows ForecastService.text. Hovering shows tooltip with extended forecast.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

### 12. Volume OSD on Volume Change
expected: Changing volume shows a PopupWindow overlay with a 150×8px Catppuccin-styled pill progress bar. It auto-hides after 1.5 seconds and does not steal keyboard focus.
result: pending
blocked_by: ""
reason: "Import fix applied — requires re-test on target hardware"

## Summary

total: 12
passed: 0
issues: 0
pending: 12
skipped: 0
blocked: 0

## Gaps

- truth: "All 14 widgets load without errors and display on the bar"
  status: resolved
  reason: "User reported: quickshell fails to load with 'Non-existent attached object' at MemoryWidget.qml:23"
  severity: blocker
  test: 1
  root_cause: "6 Phase 14 widgets use ToolTip attached property from QtQuick.Controls but lack `import QtQuick.Controls`. Phase 13 widgets (MusicWidget, VolumeWidget) have the import and work."
  fix: "import QtQuick.Controls added to all 6 widgets in 14-04 (gap closure)"
  artifacts:
    - path: ".config/quickshell/widgets/MemoryWidget.qml"
      issue: "Missing `import QtQuick.Controls` — ToolTip.visible reference fails"
    - path: ".config/quickshell/widgets/DiskWidget.qml"
      issue: "Missing `import QtQuick.Controls`"
    - path: ".config/quickshell/widgets/NetworkWidget.qml"
      issue: "Missing `import QtQuick.Controls`"
    - path: ".config/quickshell/widgets/PingWidget.qml"
      issue: "Missing `import QtQuick.Controls`"
    - path: ".config/quickshell/widgets/WeatherWidget.qml"
      issue: "Missing `import QtQuick.Controls`"
    - path: ".config/quickshell/widgets/ForecastWidget.qml"
      issue: "Missing `import QtQuick.Controls`"
  missing:
    - "Add `import QtQuick.Controls` to MemoryWidget.qml"
    - "Add `import QtQuick.Controls` to DiskWidget.qml"
    - "Add `import QtQuick.Controls` to NetworkWidget.qml"
    - "Add `import QtQuick.Controls` to PingWidget.qml"
    - "Add `import QtQuick.Controls` to WeatherWidget.qml"
    - "Add `import QtQuick.Controls` to ForecastWidget.qml"

