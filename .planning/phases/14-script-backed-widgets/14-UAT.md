---
status: complete
phase: 14-script-backed-widgets
source: [14-01-SUMMARY.md, 14-02-SUMMARY.md, 14-03-SUMMARY.md]
started: 2026-05-22T17:10:00Z
updated: 2026-05-22T17:28:00Z
---

## Current Test

[testing complete]

## Tests

### 1. All 14 Widgets Visible in Groups
expected: quickshell starts without errors. Bar shows 14 widgets total: Left group has Workspaces, Cpu, Memory, Disk, Network, Ping. Center group has Weather, Clock, Forecast. Right group has Music, Volume, Backlight, Notification, Tray. Each widget shows its icon and data.
result: pass
note: Non-blocking warnings (height→implicitHeight deprecation, Firefox MPRIS DBus) ignored. All 14 widgets confirmed visible.

### 2. CPU Widget Color Thresholds
expected: CpuWidget shows  icon + cpuPercentFormatted (e.g. " 15%"). Color changes at usage thresholds: green < 50%, yellow < 80%, red >= 80%. Updates every ~3s with responsive delta-sampled values.
result: pass
note: Timer changed 3000→300ms after initial UAT. Awk fixed to sum all /proc/stat fields.

### 3. Memory Widget — Single Icon, No Tooltip
expected: MemoryWidget shows MemoryService.text (icon embedded by script, no widget-side icon prefix). No tooltip on hover.
result: pass

### 4. Disk Widget — Disk Icon, Opens Nautilus
expected: DiskWidget shows  disk icon + DiskService.text. Clicking launches nautilus file manager. No tooltip on hover.
result: pass
note: Changed display from used/total to free/total per user request.

### 5. Network Widget — Opens nmtui
expected: NetworkWidget shows network icon + SSID name or status. Clicking opens kitty terminal with nmtui. No tooltip on hover.
result: pass
note: Fixed SSID parsing — firstColon/lastColon range instead of secondLast approach that broke for colons in SSIDs.

### 6. Ping Widget — Color-Coded, No Icon
expected: PingWidget shows PingService.text with no icon prefix. Color reflects status class (good=green, medium=yellow, bad=orange, critical=red, dead=red). No tooltip on hover.
result: pass

### 7. Backlight Widget — Display Only
expected: BacklightWidget shows  icon + brightness percentage. Scrolling does NOT adjust brightness. No tooltip on hover.
result: pass

### 8. Notification Widget — Click Toggles swaync
expected: NotificationWidget shows 󰂚 bell icon + notification count. Clicking toggles swaync notification center.
result: pass
note: Side-by-side count replaced with red dot badge. Poll 5s→1s.

### 9. Weather Widget — No Tooltip
expected: WeatherWidget shows WeatherService.text with weather conditions. No tooltip on hover.
result: pass

### 10. Clock Widget — Formatted Time in Color
expected: ClockWidget shows formatted time (e.g. "Thu 2026-05-22 10:30:00 AM") in Colours.clockColor. No strftime {} brackets visible.
result: pass

### 11. Forecast Widget — No Tooltip
expected: ForecastWidget shows ForecastService.text with extended weather data. No tooltip on hover.
result: pass

### 12. Volume OSD on Volume Change
expected: Changing volume (e.g. `wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5+`) shows a PopupWindow overlay with a Catppuccin-styled pill progress bar 150x8px. It auto-hides after ~1.5s and does not steal keyboard focus.
result: pass
note: Final design: 250x16px, white fill, dark text, Catppuccin moduleBg container, 12px below bar, clip:true to prevent corner bleed.

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "quickshell starts without errors, all 14 widgets load with correct data"
  status: failed
  reason: "User reported: quickshell fails to load. ERROR: StdioCollector is not a type at AudioService.qml:46"
  severity: blocker
  test: 1
  root_cause: "AudioService.qml missing `import Quickshell.Io` — StdioCollector is defined in Quickshell.Io module. All other services (CpuService, DiskService, etc.) have this import."
  artifacts:
    - path: ".config/quickshell/services/AudioService.qml"
      issue: "Missing `import Quickshell.Io` on line 3"
  missing:
    - "Add `import Quickshell.Io` to AudioService.qml"
  debug_session: ""
