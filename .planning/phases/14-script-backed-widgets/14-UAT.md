---
status: diagnosed
phase: 14-script-backed-widgets
source: [14-01-SUMMARY.md, 14-02-SUMMARY.md, 14-03-SUMMARY.md]
started: 2026-05-22T00:00:00Z
updated: 2026-05-22T12:30:00Z
completed: 2026-05-22T12:30:00Z
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
  root_cause: "Multiple service defects: BacklightService uses readonly properties that throw at runtime, ClockService uses strftime syntax incompatible with Qt, CpuService lacks delta sampling, NetworkService may show stale state"
  artifacts:
    - path: ".config/quickshell/services/BacklightService.qml"
      issue: "readonly blocks brightnessPercent/formatted assignment (lines 9-10)"
    - path: ".config/quickshell/services/ClockService.qml"
      issue: "strftime format string incompatible with Qt QML (lines 8, 18)"
    - path: ".config/quickshell/services/CpuService.qml"
      issue: "No delta sampling for /proc/stat reads (line 22)"
  missing:
    - "Remove readonly from BacklightService properties"
    - "Add delta-sampling logic to CpuService"
    - "Fix ClockService format string (handled in separate gap)"
  debug_session: ".planning/debug/service-data-issues.md"

- truth: "CPU widget updates responsively with color thresholds"
  status: failed
  reason: "User reported: cpu is not responsive enough, it does not update instantly"
  severity: minor
  test: 2
  root_cause: "CpuService reads cumulative /proc/stat without delta sampling — each 3s poll shows total CPU time since boot, appearing frozen"
  artifacts:
    - path: ".config/quickshell/services/CpuService.qml"
      issue: "Cumulative /proc/stat read, no prev_idle/prev_total delta (line 22)"
  missing:
    - "Add prev_idle + prev_total properties, compute per-interval usage"
  debug_session: ".planning/debug/service-data-issues.md"

- truth: "Memory widget shows correct icon and working tooltip on hover"
  status: failed
  reason: "User reported: 2 icons, text ok, tooltip doesn't work for any widget — need to remove tooltip entirely"
  severity: major
  test: 3
  root_cause: "Double icon: memory.sh embeds  in JSON text output + widget prepends . Tooltip: QtQuick.Controls.ToolTip is incompatible with Quickshell PanelWindow (Wayland layer-surface) — no Overlay infrastructure"
  artifacts:
    - path: ".config/quickshell/widgets/MemoryWidget.qml"
      issue: "Double icon (line 21) + broken ToolTip usage"
    - path: ".config/quickshell/BarContent.qml"
      issue: "PanelWindow has no overlay for ToolTip (line 10)"
  missing:
    - "Remove one icon source from MemoryWidget"
    - "Remove ToolTip from all 8 widgets (matches user preference)"
  debug_session: ".planning/debug/icon-issues.md"

- truth: "Disk widget opens Nautilus on click without errors"
  status: failed
  reason: "User reported: don't like the icon, throws error"
  severity: major
  test: 4
  root_cause: "Disk icon  (folder) disliked — wants disk glyph. Click error: Process.startDetached() silently swallows all failures (void method), provides no error feedback"
  artifacts:
    - path: ".config/quickshell/widgets/DiskWidget.qml"
      issue: "Wrong icon (line 21) + silent startDetached() (line 33)"
  missing:
    - "Replace icon with disk glyph like  or 󰋊"
    - "Add console.warn() or error handler to startDetached()"
  debug_session: ".planning/debug/icon-issues.md"

- truth: "Network widget opens nmtui on click"
  status: failed
  reason: "User reported: shows disconnected, clicking does nothing"
  severity: major
  test: 5
  root_cause: "Shows 'disconnected' may reflect real network state (not a code bug). Click does nothing: startDetached() silently fails with no error feedback. NetworkService may need NM integration check"
  artifacts:
    - path: ".config/quickshell/widgets/NetworkWidget.qml"
      issue: "Silent startDetached() failure (line 38)"
  missing:
    - "Add console.warn() or error handler to startDetached()"
  debug_session: ".planning/debug/click-actions-issues.md"

- truth: "Ping icon is displayed appropriately"
  status: failed
  reason: "User reported: 󰀶 icon is not needed"
  severity: minor
  test: 6
  root_cause: "PingWidget icon 󰀶 is redundant with color-coded status — color alone conveys good/medium/bad/critical/dead state"
  artifacts:
    - path: ".config/quickshell/widgets/PingWidget.qml"
      issue: "Unnecessary icon prefix (line 26)"
  missing:
    - "Remove 󰀶 prefix from PingWidget text, rely on color only"
  debug_session: ".planning/debug/icon-issues.md"

- truth: "Backlight scroll works without errors"
  status: failed
  reason: "User reported: throwing error, scrolling up/down adjustment is not needed"
  severity: major
  test: 7
  root_cause: "BacklightService declares readonly properties (brightnessPercent, formatted) then assigns them at runtime — QML throws error on every data fetch. User also does not want scroll adjustment"
  artifacts:
    - path: ".config/quickshell/services/BacklightService.qml"
      issue: "readonly blocks runtime assignment (lines 9-10, 31-32)"
  missing:
    - "Change readonly property to property for brightnessPercent and formatted"
  debug_session: ".planning/debug/service-data-issues.md"

- truth: "Weather widget tooltip works on hover"
  status: failed
  reason: "User reported: weather widget is good but tooltip is not good"
  severity: major
  test: 9
  root_cause: "Same tooltip incompatibility as test 3 — QtQuick.Controls.ToolTip does not work in PanelWindow. User wants tooltip removed"
  artifacts:
    - path: ".config/quickshell/widgets/WeatherWidget.qml"
      issue: "Broken ToolTip in PanelWindow"
  missing:
    - "Remove ToolTip from WeatherWidget"
  debug_session: ".planning/debug/tooltip-issues.md"

- truth: "Clock widget displays formatted time in correct color"
  status: failed
  reason: "User reported: clock absolutely does not work, shows format string with {} brackets"
  severity: major
  test: 10
  root_cause: "ClockService uses Python strftime format string {:%a %Y-%m-%d %I:%M:%S %p} but Qt.formatDateTime() expects Qt-specific specifiers (ddd, yyyy, MM, hh, mm, ss, AP)"
  artifacts:
    - path: ".config/quickshell/services/ClockService.qml"
      issue: "strftime syntax incompatible with Qt (lines 8, 18)"
  missing:
    - "Replace strftime {:%a...} with Qt format: ddd yyyy-MM-dd hh:mm:ss AP"
  debug_session: ".planning/debug/clock-format-issue.md"

- truth: "Forecast tooltip works on hover"
  status: failed
  reason: "User reported: widget works, tooltip is useless need to remove it"
  severity: minor
  test: 11
  root_cause: "Same tooltip incompatibility as test 3 — QtQuick.Controls.ToolTip does not work in PanelWindow. User wants tooltip removed"
  artifacts:
    - path: ".config/quickshell/widgets/ForecastWidget.qml"
      issue: "Broken ToolTip in PanelWindow"
  missing:
    - "Remove ToolTip from ForecastWidget"
  debug_session: ".planning/debug/tooltip-issues.md"

- truth: "Volume OSD popup appears on volume change"
  status: failed
  reason: "User reported: it does not show any popup window"
  severity: major
  test: 12
  root_cause: "Pipewire binding propagation broken in Quickshell 0.2.1 — onVolumePercentChanged never fires because AudioService.volumePercent doesn't emit change signals. Verified by upstream issue #807"
  artifacts:
    - path: ".config/quickshell/services/AudioService.qml"
      issue: "Pipewire binding propagation broken in QS 0.2.1"
    - path: ".config/quickshell/popups/VolumeOsd.qml"
      issue: "Correct popup structure but trigger never fires"
  missing:
    - "Add direct signal connection or wpctl fallback for volume change detection"
  debug_session: ".planning/debug/click-actions-issues.md"
