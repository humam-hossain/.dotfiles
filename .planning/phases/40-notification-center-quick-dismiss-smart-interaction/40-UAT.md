---
status: diagnosed
phase: 40-notification-center-quick-dismiss-smart-interaction
source:
  - 40-01-SUMMARY.md
  - 40-02-SUMMARY.md
started: 2026-09-24T10:16:35+06:00
updated: 2026-09-24T10:45:00+06:00
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

### 10. Notification Quick-Dismiss & Smart Interaction Deliverables Confirmation
expected: Confirm all automated deliverables match expectations.
result: issue
reported: "d-bus works now if i click works, but there is no cancel notification button \"X\" and no otp copy button or either clicking the body does not copy the number. Adding to that also now there is a lag in toast before rendering, like before when the notify send message is sent by using notify send when I am testing it it's instant before now there is a lag the notification toast is small but stops after couple of seconds it comes up so this is distracting and annoying like it's visually doesn't feel like smooth so that is the issue we need to diagnose this"
severity: major

## Summary

total: 10
passed: 9
issues: 1
pending: 0
skipped: 0

## Gaps

- gap_id: G-40-10
  truth: "Single notification shows 'X' cancel button, OTP copy pill button copies code, body click behaves correctly without toast rendering lag"
  status: failed
  reason: "User reported: d-bus works now if i click works, but there is no cancel notification button \"X\" and no otp copy button or either clicking the body does not copy the number. Adding to that also now there is a lag in toast before rendering, like before when the notify send message is sent by using notify send when I am testing it it's instant before now there is a lag the notification toast is small but stops after couple of seconds it comes up so this is distracting and annoying like it's visually doesn't feel like smooth so that is the issue we need to diagnose this"
  severity: major
  test: 10
  root_cause: "1) Qt Quick QV4 JS engine throws SyntaxError on (?<!...) lookbehinds in NotificationUtils.extractOtpCode preventing OTP chip rendering; 2) NotificationGroup.qml closeButton suppressed on popups (!root.popup) and missing 'import qs' causes ReferenceError on GlobalStates; 3) Unconstrained Behavior on implicitHeight in NotificationItem/NotificationGroup animates from 0 on creation, continuously resizing layer-shell surface mask causing toast lag/freeze."
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"
      issue: "RegExp lookbehind syntax (?<!...) incompatible with Qt Quick QV4 JS engine"
    - path: "restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml"
      issue: "closeButton suppressed on popups (!root.popup), missing import qs, initial height animation enabled"
    - path: "restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml"
      issue: "implicitHeight Behavior animates from 0 on initial creation"
    - path: "scripts/phase40-notification-interaction-assert.sh"
      issue: "Harness tested regex in Node.js instead of Quickshell QV4 runtime"
  missing:
    - "Replace RegExp lookbehinds with QV4-compatible non-lookbehind regex in NotificationUtils.qml"
    - "Add import qs and enable closeButton on single notification popups in NotificationGroup.qml"
    - "Disable initial height animation on component creation in NotificationItem.qml and NotificationGroup.qml"
    - "Update test harness to validate regex using Quickshell execution"
  debug_session: ".planning/debug/notification-interaction-gaps.md"
