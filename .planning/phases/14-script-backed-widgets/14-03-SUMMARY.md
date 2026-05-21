---
phase: 14-script-backed-widgets
plan: 03
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
  - AUDIO-02
  - TRAY-02
  - TRAY-03
key-files:
  created:
    - .config/quickshell/popups/VolumeOsd.qml
  modified:
    - .config/quickshell/BarContent.qml
---

## Wave 3 Complete: BarContent Wiring + Volume OSD

### Files Modified (1)
- **BarContent.qml** — Final widget composition:
  - **Left BarGroup**: WorkspacesWidget, CpuWidget, MemoryWidget, DiskWidget, NetworkWidget, PingWidget
  - **Center BarGroup**: WeatherWidget, ClockWidget, ForecastWidget
  - **Right BarGroup**: MusicWidget, VolumeWidget, BacklightWidget, NotificationWidget, TrayWidget
  - Added `import "./popups/" as Popups` + `Popups.VolumeOsd { anchor.window: root }`

### Files Created (1)
- **popups/VolumeOsd.qml** — PopupWindow with:
  - WlrLayer.Overlay, WlrKeyboardFocus.None
  - 150×8px pill progress bar with Catppuccin styling
  - 1.5s auto-hide timer (AUDIO-02)
  - visible: false (P-03 compliant, not opacity:0)
  - Triggers on AudioService.volumePercent change

### Compliance
- ✓ WlrKeyboardFocus.None present on bar PanelWindow
- ✓ LockWidget (CTRL-02) and PowerWidget (CTRL-03) absent
- ✓ Volume OSD uses PopupWindow, not PanelWindow
- ✓ No opacity:0 pattern for visibility control
- ✓ No grabFocus pattern
- ✓ All Process.command arrays static literals

### Widget Count Summary
- Phase 12: 1 BarContent.qml framework
- Phase 13: 4 widgets + 3 service singletons
- Phase 14: 10 more widgets + 10 more services + Volume OSD
- Total bar: 14 widgets across 3 groups + popup
