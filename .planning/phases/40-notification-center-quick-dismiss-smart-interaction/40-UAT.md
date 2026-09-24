---
status: complete
phase: 40-notification-center-quick-dismiss-smart-interaction
source:
  - 40-01-SUMMARY.md
  - 40-02-SUMMARY.md
  - 40-03-SUMMARY.md
started: 2026-09-24T10:16:35+06:00
updated: 2026-09-24T14:25:00+06:00
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Phase 40 assertion test harness with 5 sections, CLI flags, non-root check, and porcelain baseline tracking
expected: Phase 40 assertion test harness with 5 sections, CLI flags, non-root check, and porcelain baseline tracking
result: pass
source: automated
coverage_id: 40-01-D1

### 2. NotificationUtils.extractOtpCode regex parser detecting 4-8 digit codes anchored to security keywords with zero false positives
expected: NotificationUtils.extractOtpCode regex parser detecting 4-8 digit codes anchored to security keywords with zero false positives
result: pass
source: automated
coverage_id: 40-01-D2

### 3. NotificationUtils.extractUrl parsing Chromium HTML anchors and raw URLs with entity unescaping and scheme whitelisting
expected: NotificationUtils.extractUrl parsing Chromium HTML anchors and raw URLs with entity unescaping and scheme whitelisting
result: pass
source: automated
coverage_id: 40-01-D3

### 4. Leaf symlink deployment of NotificationUtils.qml via GNU Stow without vendor/dots-hyprland submodule drift
expected: Leaf symlink deployment of NotificationUtils.qml via GNU Stow without vendor/dots-hyprland submodule drift
result: pass
source: automated
coverage_id: 40-01-D4

### 5. Always-visible 'X' close button on single-notification card header in Right Sidebar
expected: Always-visible 'X' close button on single-notification card header in Right Sidebar
result: pass
source: automated
coverage_id: 40-02-D1

### 6. Group notification headers retain expand chevron and count; toast popups suppress 'X' close button
expected: Group notification headers retain expand chevron and count; toast popups suppress 'X' close button
result: pass
source: automated
coverage_id: 40-02-D2

### 7. Notification card body click routes D-Bus default action or URL fallback and closes right sidebar
expected: Notification card body click routes D-Bus default action or URL fallback and closes right sidebar
result: pass
source: automated
coverage_id: 40-02-D3

### 8. Material 3 icon-free 'Copy [Code]' pill chip with 1.5s visual confirmation copying code to clipboard
expected: Material 3 icon-free 'Copy [Code]' pill chip with 1.5s visual confirmation copying code to clipboard
result: pass
source: automated
coverage_id: 40-02-D4

### 9. End-to-end 5-section assertion test suite and dots-hyprland strict verification pass with zero findings
expected: End-to-end 5-section assertion test suite and dots-hyprland strict verification pass with zero findings
result: pass
source: automated
coverage_id: 40-02-D5

### 10. Notification Quick-Dismiss & Smart Interaction Verification
expected: |
  1. Desktop toasts and sidebar notifications render with interactive controls.
  2. Single and group notification cards display side-by-side 'X' close and expand chevron buttons.
  3. Single notifications remain collapsed by default with manual expansion.
  4. Grouped notifications list items collapsed, each with independent expand and close controls.
  5. Notifications with verification codes show prominent OTP pill chips copying codes to clipboard.
  6. Clicking notification body copies content to clipboard and routes D-Bus or web URLs.
result: pass

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0

## Gaps

- gap_id: G-40-10
  truth: "Single and group notifications display both 'X' dismiss and expand buttons; single notifications start collapsed; group items expand individually; body click copies to clipboard"
  status: resolved
  resolved_by: "40-03-PLAN.md"
  resolved_at: "2026-09-24"
  reason: "User reported: its not smooth there is a moment freeze in the animation. X close button works, clicking to web link works. couple of problem when i click on body of notification whether its a web link or not it should copy to clipboard, even when it goes through D-Bus. I would like to verify otp stuff by multiple types of otp. In addition, expand button was missing on single notifications and group items did not expand individually."
  severity: major
  test: 10
  root_cause: "1) Mutual exclusivity in NotificationGroup header hid expandButton on single notifications and closeButton on group headers; 2) Bypassing height clamp forced single notifications expanded by default; 3) All items in group inherited root.expanded at once; 4) activateNotification lacked Quickshell.clipboardText assignment."
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml"
      issue: "groupExpanded vs itemExpanded separation, summaryRow item expand/close buttons, clipboard copying in activateNotification"
    - path: "restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml"
      issue: "Side-by-side expandButton and closeButton, height clamp restored, delegate property bindings"
    - path: "scripts/phase40-notification-interaction-assert.sh"
      issue: "Updated AST checks for side-by-side controls and root.expanded"
  missing:
    - "Side-by-side expand and close controls in NotificationGroup.qml"
    - "Per-item expand and close controls in NotificationItem.qml"
    - "Clipboard copying on notification body activation"
