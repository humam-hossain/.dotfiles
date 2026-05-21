---
plan: 14-04
phase: 14-script-backed-widgets
type: gap_closure
wave: 1
status: complete
tasks_completed: 1
requirements_completed: SYS-01, SYS-02, SYS-03, SYS-04, CUST-01, CUST-02, CUST-03, CUST-04
commits:
  - fix(14-04): add import QtQuick.Controls to 6 ToolTip widgets
---

## Summary

Added missing `import QtQuick.Controls` to all 6 Phase 14 widgets that use ToolTip attached properties (ToolTip.visible, ToolTip.text). This fixes the `quickshell` startup crash `"Non-existent attached object" at MemoryWidget.qml:23` that blocked all 12 UAT tests.

## Files Modified

| File | Change |
|------|--------|
| `.config/quickshell/widgets/MemoryWidget.qml` | Added `import QtQuick.Controls` after line 1 |
| `.config/quickshell/widgets/DiskWidget.qml` | Added `import QtQuick.Controls` after line 1 |
| `.config/quickshell/widgets/NetworkWidget.qml` | Added `import QtQuick.Controls` after line 1 |
| `.config/quickshell/widgets/PingWidget.qml` | Added `import QtQuick.Controls` after line 1 |
| `.config/quickshell/widgets/WeatherWidget.qml` | Added `import QtQuick.Controls` after line 1 |
| `.config/quickshell/widgets/ForecastWidget.qml` | Added `import QtQuick.Controls` after line 1 |

## Verification

- ✓ All 6 files have `import QtQuick.Controls` on line 2
- ✓ All 6 files retain `ToolTip.visible` and `ToolTip.text` references
- ✓ All 6 files retain `import QtQuick` on line 1 unchanged

## Deviations

None.

## Issues

None.
