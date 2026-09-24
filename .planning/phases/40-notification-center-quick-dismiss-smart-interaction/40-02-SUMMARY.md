---
phase: 40-notification-center-quick-dismiss-smart-interaction
plan: 02
subsystem: ui-notifications
tags: [quickshell, qml, notifications, quick-dismiss, body-click, otp-chip, restow]

requires:
  - phase: 40-notification-center-quick-dismiss-smart-interaction
    provides: NotificationUtils.qml regex extraction engine and phase40 assertion test harness
provides:
  - Single-notification card header 'X' close button with smooth dismiss animation
  - Height auto-expansion for single notifications and OTP chips bypassing 80px clamping
  - Smart body click activation prioritizing D-Bus default action, URL fallback, and sidebar closure
  - Icon-free Material 3 "Copy [Code]" pill chip with 1.5s visual confirmation
  - Full 5-section assertion harness passing with 0 failures and 0 findings
affects: []

actuals:
  tokens: 6500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - RippleButton header action styling matching upstream expandButton tokens
    - D-Bus default action inspection before URL fallback dispatch
    - Material 3 container-styled icon-free action pill chip with auto-resetting Timer
    - Unclamped contentColumn dynamic height calculation in collapsed cards

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml
    - restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml
  modified:
    - scripts/phase40-notification-interaction-assert.sh

key-decisions:
  - "D-01: Added always-visible 'X' close button on single-notification sidebar cards invoking root.destroyWithAnimation()."
  - "D-02: Strictly preserved upstream expandButton for multi-notification groups without adding a group close button."
  - "D-03: Suppressed 'X' close button on toast popups (!root.popup), preserving upstream hover-to-dismiss and timeout lifecycle."
  - "D-04 & D-05 & D-06: Implemented activateNotification routing D-Bus 'default' action first, URL fallback second, card discard and GlobalStates.sidebarRightOpen = false in all pathways."
  - "D-08 & D-09: Rendered icon-free Material 3 'Copy [Code]' pill chip with 1500ms 'Copied!' confirmation."
  - "D-10: Deployed all QML overlays as leaf symlinks via GNU Stow with zero git submodule churn in vendor/dots-hyprland."

patterns-established:
  - "Smart notification activation with D-Bus action priority and browser fallback"
  - "Single-notification card quick-dismiss without accordion expansion"

requirements-completed:
  - NOTIF-01
  - NOTIF-02
  - NAV-01
  - OTP-02

coverage:
  - id: D1
    description: "Always-visible 'X' close button on single-notification card header in Right Sidebar"
    requirement: "NOTIF-01"
    verification:
      - kind: automated_ui
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Group notification headers retain expand chevron and count; toast popups suppress 'X' close button"
    requirement: "NOTIF-02"
    verification:
      - kind: automated_ui
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "Notification card body click routes D-Bus default action or URL fallback and closes right sidebar"
    requirement: "NAV-01"
    verification:
      - kind: automated_ui
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D4
    description: "Material 3 icon-free 'Copy [Code]' pill chip with 1.5s visual confirmation copying code to clipboard"
    requirement: "OTP-02"
    verification:
      - kind: automated_ui
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D5
    description: "End-to-end 5-section assertion test suite and dots-hyprland strict verification pass with zero findings"
    requirement: "INTG-02"
    verification:
      - kind: integration
        ref: "./scripts/phase40-notification-interaction-assert.sh"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-09-24
status: complete
---

# Phase 40 Plan 02: Notification Center Quick-Dismiss & Smart Interaction Summary

**Delivered single-notification 1-click 'X' close button, smart body click routing with D-Bus priority and URL fallback, and icon-free Material 3 OTP quick-action chip deployed as leaf symlinks with 100% test pass rate.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-09-24T10:06:00Z
- **Completed:** 2026-09-24T10:11:00Z
- **Tasks:** 3 completed
- **Files modified:** 3 files created/modified

## Accomplishments

- Implemented `NotificationGroup.qml` restow overlay adding an always-visible 'X' close button on single notification sidebar cards while preserving 100% upstream default UI for grouped notifications and desktop toast popups (NOTIF-01, NOTIF-02, D-01..D-03).
- Fixed card height clamping (`(root.expanded || !root.multipleNotifications) ? ... : Math.min(80, ...)`) preventing visual clipping on cards displaying OTP chips or longer summaries.
- Implemented smart body click navigation in both `NotificationGroup.qml` and `NotificationItem.qml`, invoking the sending app's D-Bus `default` action when available, falling back to browser URL launching for web/passive notifications, and closing the right sidebar in all pathways (NAV-01, D-04..D-06).
- Implemented clean, icon-free Material 3 "Copy [Code]" pill chip in `NotificationItem.qml` (collapsed and expanded views) copying the code to `Quickshell.clipboardText` and displaying "Copied!" for 1.5 seconds without closing the sidebar or navigating away (OTP-02, D-08, D-09, T-40-02).
- Finalized `scripts/phase40-notification-interaction-assert.sh` across all 5 sections, passing with 0 failures and 0 findings, and verified repository cleanliness with `./arch/dots-hyprland.sh verify --strict`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Header close button, height auto-expansion, and body click in NotificationGroup.qml** - `ae143c9` (feat)
2. **Task 2: Smart body click routing and icon-free OTP copy chip in NotificationItem.qml** - `1411ba6` (feat)
3. **Task 3: End-to-end integration and full 5-section assertion harness completion** - `0601931` (test)

**Plan metadata:** `docs(40-02): complete notification quick-dismiss and smart interaction plan`

## Self-Check: PASSED

- `NotificationGroup.qml`: Exists in restow and is deployed as leaf symlink
- `NotificationItem.qml`: Exists in restow and is deployed as leaf symlink
- `scripts/phase40-notification-interaction-assert.sh`: PASSED (all 5 sections, FAIL=0 FINDINGS=0)
- `./arch/dots-hyprland.sh verify --strict`: PASSED (FAIL=0 FINDINGS=0)
- Submodule `vendor/dots-hyprland`: Pristine (0 diff)
