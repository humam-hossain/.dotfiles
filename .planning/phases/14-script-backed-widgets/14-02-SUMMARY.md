---
phase: 14-script-backed-widgets
plan: 02
status: complete
requirements-completed:
  - SYS-01
  - SYS-02
  - SYS-03
  - SYS-04
  - CUST-01
  - CUST-02
  - CUST-03
  - CUST-04
  - CTRL-01
  - TRAY-02
  - TRAY-03
key-files:
  created:
    - .config/quickshell/widgets/CpuWidget.qml
    - .config/quickshell/widgets/MemoryWidget.qml
    - .config/quickshell/widgets/DiskWidget.qml
    - .config/quickshell/widgets/NetworkWidget.qml
    - .config/quickshell/widgets/PingWidget.qml
    - .config/quickshell/widgets/BacklightWidget.qml
    - .config/quickshell/widgets/NotificationWidget.qml
    - .config/quickshell/widgets/WeatherWidget.qml
    - .config/quickshell/widgets/ClockWidget.qml
    - .config/quickshell/widgets/ForecastWidget.qml
  modified:
    - .config/quickshell/widgets/qmldir (4→14 widget registrations)
---

## Wave 2 Complete: All 10 Phase 14 Widgets

### Files Created (10)
All 10 Phase 14 widgets created under `.config/quickshell/widgets/`:
- `CpuWidget.qml` —  icon + cpuPercentFormatted, color thresholds via Connections
- `MemoryWidget.qml` —  icon + MemoryService.text, color thresholds, tooltip
- `DiskWidget.qml` —  icon + DiskService.text, click→nautilus, tooltip
- `NetworkWidget.qml` — icon + ssid in Row, click→kitty -e nmtui, tooltip
- `PingWidget.qml` — 󰀶 icon + PingService.text, per-class colors (good/dead/bad/critical/dead), click→localhost:8765
- `BacklightWidget.qml` —  icon + BacklightService.formatted, scroll→adjustBrightness
- `NotificationWidget.qml` — 󰂚 bell + count, click→swaync-client -t
- `WeatherWidget.qml` — WeatherService.text, tooltip
- `ClockWidget.qml` — ClockService.text in Colours.clockColor
- `ForecastWidget.qml` — ForecastService.text, tooltip

### Files Modified (1)
- `widgets/qmldir` — 4→14 non-singleton registrations (all 10 new + 4 existing)

### Widget Count
- Phase 13: 4 widgets (Workspaces, Volume, Music, Tray)
- Phase 14 adds: 10 widgets
- Total: 14 widgets

### Deviations
None. All code follows PLAN.md specs exactly.

### Verification
All widgets: exist, import qs.services + Local, no Component.onCompleted, no direct Quickshell.Services.* imports, all Process.command arrays use static literals.
