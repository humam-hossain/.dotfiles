---
phase: 14-script-backed-widgets
plan: 05
type: execute
wave: 1
gap_closure: true
status: complete
---

# Plan 14-05: Gap Closure — UAT Fixes

## Summary

Applied all 9 diagnosed UAT gap fixes across service and widget files.

### Service Fixes

| File | Fix | Status |
|------|-----|--------|
| BacklightService.qml | Removed `readonly` from `brightnessPercent` and `formatted` properties | ✓ |
| CpuService.qml | Added delta sampling via `__prevIdle`/`__prevTotal` properties; changed awk command to output idle+total values | ✓ |
| ClockService.qml | Replaced strftime `{:%a ...}` with Qt-compatible `ddd yyyy-MM-dd hh:mm:ss AP` | ✓ |
| AudioService.qml | Removed `readonly` from `volume`, `muted`, `volumePercent`, `sinkName`; added polling Timer (500ms) reading Pipewire API directly | ✓ |

### Widget Fixes

| Fix | Files | Status |
|-----|-------|--------|
| Removed ToolTip + HoverHandler + QtQuick.Controls import | MemoryWidget, WeatherWidget, ForecastWidget, DiskWidget, NetworkWidget, PingWidget, VolumeWidget, MusicWidget | ✓ |
| Double icon removal | MemoryWidget (removed " " prefix) | ✓ |
| Icon replacement | DiskWidget ( → ) | ✓ |
| Redundant icon removal | PingWidget (removed "󰀶 " prefix) | ✓ |
| try/catch + console.warn for startDetached() | DiskWidget, NetworkWidget | ✓ |

### Additional Pre-existing Fixes (committed together)

- Bar.qml: Component-wrapped BarContent for multi-monitor
- BarContent.qml: explicit `height: 36`
- VolumeOsd.qml: implicit width/height, anchor edges/gravity layout
- All services: readonly removal on writable properties

## Files Modified

22 files, +105/-89 lines across `.config/quickshell/`
