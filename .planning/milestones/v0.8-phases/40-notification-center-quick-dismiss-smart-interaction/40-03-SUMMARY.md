---
phase: 40-notification-center-quick-dismiss-smart-interaction
plan: 03
subsystem: ui-notifications
tags: [quickshell, qml, qv4, regex, otp, notifications, stow]

requires:
  - phase: 40-01
    provides: NotificationUtils foundation and test harness
  - phase: 40-02
    provides: NotificationGroup and NotificationItem overlays
provides:
  - QV4-compatible regex OTP extraction without lookbehinds
  - Desktop toast and sidebar 1-click 'X' close button on single notifications
  - Qt Quick 'import qs' in NotificationGroup to resolve GlobalStates ReferenceError
  - Initial mount height animation suppression eliminating toast rendering lag and surface freeze
affects: [quickshell, notifications, hyprland]

actuals:
  tokens: 14000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - QV4 engine regex boundary matching using non-capturing prefix groups instead of lookbehinds
    - Delayed initialization property (initialized flag via Qt.callLater) to prevent initial mount height animation thrash

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml
    - restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml
    - restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml
    - scripts/phase40-notification-interaction-assert.sh

key-decisions:
  - "Eliminated RegExp lookbehind syntax (?<!...) from extractOtpCode to ensure full compatibility with Qt Quick's QV4 JavaScript engine."
  - "Enabled closeButton on single desktop toasts by removing !root.popup condition, restricting expandButton to multiple notifications."
  - "Added import qs to NotificationGroup.qml to provide GlobalStates for sidebar management upon activation."
  - "Suppressed initial item implicitHeight animation from 0 using an initialized flag to prevent Wayland surface mask resizing lag and visual freeze on popup creation."

patterns-established:
  - "QV4 Regex: Replace negative lookbehinds with non-capturing prefix delimiters (?:^|[^0-9\-\/]) combined with lookaheads."
  - "QML Height Animation Safety: Gate mount-time Behavior on implicitHeight using enabled: root.initialized with Qt.callLater."

requirements-completed:
  - NOTIF-01
  - NOTIF-02
  - OTP-01
  - OTP-02
  - NAV-01
  - INTG-02

coverage:
  - id: D1
    description: "NotificationUtils.extractOtpCode operates cleanly without SyntaxError in QV4 engine"
    requirement: "OTP-01"
    verification:
      - kind: unit
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D2
    description: "Single notification 1-click 'X' close button visible on both desktop toasts and sidebar"
    requirement: "NOTIF-01"
    verification:
      - kind: automated_ui
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "Toast rendering lag eliminated without initial height animation from 0"
    requirement: "NOTIF-02"
    verification:
      - kind: automated_ui
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 2"
        status: pass
    human_judgment: false

duration: 13 min
completed: 2026-09-24
status: complete
---

# Phase 40 Plan 03: Gap Closure — Fix OTP QV4 SyntaxError, Desktop Toast 'X' Button, and Rendering Lag (G-40-10) Summary

**Resolved UAT Gap G-40-10 by converting OTP regex extraction to QV4-compatible non-lookbehind patterns, enabling 1-click 'X' dismiss on desktop toasts, fixing GlobalStates import, and eliminating initial toast height animation freeze.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-09-24T06:31:06Z
- **Completed:** 2026-09-24T06:44:11Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Refactored `NotificationUtils.extractOtpCode` to eliminate RegExp lookbehind assertions `(?<![-/0-9])` that caused Qt Quick QV4 to throw synchronous `SyntaxError: Invalid regular expression`. Tested against all 19 test cases in Quickshell headless and Node.js.
- Restored OTP pill chip rendering and 1-click copying functionality across notification popups and sidebar.
- Added `import qs` to `NotificationGroup.qml` resolving `ReferenceError: GlobalStates is not defined` during notification activation.
- Updated `closeButton.visible` to `!root.multipleNotifications` on `NotificationGroup.qml`, enabling direct 1-click dismissal on desktop toast popups.
- Eliminated 500ms initial height animation from 0 on `NotificationItem.qml` and `NotificationGroup.qml` using `enabled: root.initialized`, preventing Wayland surface mask thrashing and visual pop stutter.
- Updated `scripts/phase40-notification-interaction-assert.sh` with QV4 lookbehind syntax guard and new visibility rules, verifying full test suite and `./arch/dots-hyprland.sh verify --strict` pass with FAIL=0 FINDINGS=0.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace lookbehind regex in NotificationUtils.qml with QV4-compatible pattern (OTP-01, G-40-10)** - `2c6a062` (fix)
2. **Task 2: Fix NotificationGroup.qml and NotificationItem.qml toast close button, imports, and initial height lag (NOTIF-01, NOTIF-02, NAV-01, G-40-10)** - `f156b95` (fix)
3. **Task 3: Update assertion test harness and verify 100% pass rate (INTG-02, G-40-10)** - `169d6b1` (test)

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
