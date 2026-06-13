---
phase: 15
plan: 03
type: execute
completed_date: "2026-05-22T22:20:00.000Z"
duration_minutes: 15
task_count: 5
commit_count: 5
key_files:
  created: []
  modified:
    - .config/quickshell/services/qmldir
    - .config/quickshell/BarContent.qml
    - .config/quickshell/widgets/ClockWidget.qml
    - .config/quickshell/widgets/NetworkWidget.qml
requirements_completed: [POPUP-01, POPUP-02, POPUP-03]
---

# Phase 15 Plan 03: Wiring Summary

Popups wired into the bar:
- CalendarService registered in services/qmldir
- CalendarPopup and NetworkPopup instantiated in BarContent with single-popup management (openPopup closes current popup)
- ClockWidget gains MouseArea that opens CalendarPopup via parent traversal
- NetworkWidget click changed from nmtui to NetworkPopup (nmtui kept for footer use)
- POPUP-03 notification toggle pre-built in Phase 14 — verified

## Fix Applied: Inline Repeater delegates instead of Component { id }

Original popup files used `Component { id: cell }` / `Component { id: networkListDelegate }` as Repeater delegates, which caused the QML engine to fail loading the entire popups/ import, cascading to BarContent failure. Fixed by using inline delegate definitions inside the Repeater elements. The `WlrLayershell.layer: WlrLayer.Overlay` setting was also removed from popups to avoid layer conflicts.

## Self-Check: PASSED (pending user verification)
