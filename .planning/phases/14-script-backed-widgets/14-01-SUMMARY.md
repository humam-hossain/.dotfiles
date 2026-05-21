---
phase: 14-script-backed-widgets
plan: 01
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
key-files:
  created:
    - .config/quickshell/services/CpuService.qml
    - .config/quickshell/services/DiskService.qml
    - .config/quickshell/services/NetworkService.qml
    - .config/quickshell/services/ClockService.qml
    - .config/quickshell/services/MemoryService.qml
    - .config/quickshell/services/BacklightService.qml
    - .config/quickshell/services/PingService.qml
    - .config/quickshell/services/WeatherService.qml
    - .config/quickshell/services/ForecastService.qml
    - .config/quickshell/services/NotificationService.qml
  modified:
    - .config/quickshell/services/qmldir (3→13 singletons)
    - .config/quickshell/theme/Colours.qml (46 readonly property color lines)
---

## Wave 1 Complete: All 10 Service Singletons + Colour Aliases

### Files Created (10)
All 10 Phase 14 service singletons created under `.config/quickshell/services/`:
- `CpuService.qml` — /proc/stat awk parsing, 3s poll
- `MemoryService.qml` — memory.sh reuse, 5s poll
- `DiskService.qml` — df -h inline, 30s poll
- `NetworkService.qml` — nmcli WiFi + ethernet fallback, 10s poll
- `PingService.qml` — ping_status.sh reuse, 5s poll
- `WeatherService.qml` — curr_weather.sh reuse, 200s poll
- `ForecastService.qml` — forcast_weather.sh reuse, 200s poll
- `ClockService.qml` — Qt.formatDateTime Asia/Dhaka, 1s update (no Process)
- `BacklightService.qml` — ddcutil getvcp 10, 30s poll, 300ms debounced writes
- `NotificationService.qml` — swaync-client -c, 5s poll

### Files Modified (2)
- `services/qmldir` — 3→13 singleton registrations (all 10 new + 3 existing)
- `Colours.qml` — 12 new semantic aliases: diskColor, cpuColor, memoryColor, networkColor, pingGood/Medium/Bad/Critical/Dead, clockColor, backlightColor, notifColor

### Deviations
None. All code follows PLAN.md specs exactly.

### Smoke Check
Not executed (requires running `quickshell` on an Arch Linux Hyprland system).
Files verified: all 10 .qml files exist, start with `pragma Singleton`, have no `Component.onCompleted`.
