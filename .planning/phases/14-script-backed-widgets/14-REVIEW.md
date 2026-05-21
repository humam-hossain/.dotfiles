---
phase: 14-script-backed-widgets
status: advisory
review_date: 2026-05-21
reviewer: gsd-execute
depth: standard
---

## Code Review: Phase 14 — Script-Backed Widgets

### Summary
3 plans reviewed: 10 service singletons, 10 widgets, BarContent wiring, Volume OSD.
All files checked: QML syntax, Process command safety, pattern compliance, threat model adherence.

### Findings

| Severity | File | Issue | Status |
|----------|------|-------|--------|
| INFO | BacklightService.qml:47 | `writeProc.command` uses string interpolation for numeric `target` (clamped 0-100) | Acceptable per T-14-PROC-02. Numeric-only, no injection vector. |
| GOOD | All services | `pragma Singleton` on line 1, all follow Timer+Process+StdioCollector pattern | ✓ |
| GOOD | All widgets | `Local.ModulePill` root, `import qs.services`, `import "../" as Local` | ✓ |
| GOOD | All services/widgets | No `Component.onCompleted` (P-18 compliance) | ✓ |
| GOOD | VolumeOsd.qml | Uses `PopupWindow`, `visible: false`, `WlrKeyboardFocus.None`, no `opacity: 0` | ✓ |
| GOOD | BarContent.qml | Lock/Power absent; all 14 widgets wired correctly | ✓ |
| GOOD | Threat model | T-14-PROC-01 (injection), T-14-PROC-02 (tampering), T-14-DOS-01 (DoS), T-14-PROC-03 (parsing) all mitigated | ✓ |
