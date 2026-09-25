---
phase: 40-notification-center-quick-dismiss-smart-interaction
status: clean
depth: standard
files_reviewed: 4
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
---

# Phase 40 Code Review Report

**Reviewed Files:**
- `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml`
- `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml`
- `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml`
- `scripts/phase40-notification-interaction-assert.sh`

## Executive Summary

A comprehensive code review was performed on all Phase 40 implementation files:

1. **Extraction Utilities (`NotificationUtils.qml`)**:
   - `extractOtpCode(body, summary)`: Combines summary and body, removes HTML tags, and parses 4–8 digit standalone, hyphenated, and service-prefixed codes anchored to security keywords.
   - Enforces negative lookarounds `(?<![-/0-9])` and `(?![-/0-9])` alongside bounded non-greedy quantifiers (`{0,30}?`, `{1,60}?`), eliminating ReDoS vulnerability (T-40-01) and rejecting calendar dates, timestamps, phone numbers, and counters with 100% precision.
   - `extractUrl(body)`: Efficiently parses Chromium `<a href="...">` anchors (with `&amp;` unescaping) and raw HTTP/HTTPS URLs with trailing punctuation removal.
   - Enforces strict scheme whitelisting (`http://` or `https://` only), rejecting arbitrary URI schemes (`javascript:`, `file:`, `data:`, `sh:`) (T-40-03).
   - Preserved upstream functions (`findSuitableMaterialSymbol`, `getFriendlyNotifTimeString`, `processNotificationBody`) without regression.

2. **Group Container & Quick Dismissal (`NotificationGroup.qml`)**:
   - Added an always-visible 'X' close button to `topRow` for single notifications in the sidebar (`!root.multipleNotifications && !root.popup`).
   - Clicking 'X' triggers `root.destroyWithAnimation()`, immediately dismissing the notification without requiring dropdown expansion.
   - Upstream parity strictly preserved: multi-notification groups retain the standard `NotificationGroupExpandButton` with count and chevron (D-02); desktop toast popups strictly suppress the 'X' button (`popup: true`), preserving hover/timeout dismissal (NOTIF-02, D-03).
   - Fixed background height clamping (`Math.min(80, ...)`), allowing single notification cards to expand naturally to accommodate OTP chips or longer summaries.
   - Implemented `activateNotification()` checking sending app's D-Bus `default` action before falling back to web link launching and closing `GlobalStates.sidebarRightOpen`.

3. **Notification Item & Quick Action Chip (`NotificationItem.qml`)**:
   - Implemented clean, icon-free Material 3 "Copy [Code]" pill chip in both collapsed and expanded states (`collapsedOtpChip` and `expandedOtpChip`).
   - Complied with user directive D-08 (no key or decorative icons).
   - Styled with `Appearance.colors.colSecondaryContainer` and `colOnSecondaryContainer`.
   - Clicking chip copies strictly the extracted code to `Quickshell.clipboardText` and flips text to "Copied!" for 1500ms via `Timer`. Mouse clicks are self-contained and do not trigger body activation or sidebar closure (T-40-02).
   - Body clicks via `dragManager` route to `activateNotification()` on LeftButton and `destroyWithAnimation()` on MiddleButton.

4. **Assert Harness & Integrity (`scripts/phase40-notification-interaction-assert.sh`)**:
   - Strict bash error handling (`set -euo pipefail`), non-root gate, temporary file trap, and porcelain snapshot baseline tracking.
   - 5 comprehensive verification sections (symlinks, static AST, 19-case OTP test matrix, URL & activation precedence suite, dots-hyprland strict verification).
   - All tests pass with `FAIL=0 FINDINGS=0`.
   - Submodule `vendor/dots-hyprland` remains 100% pristine with zero git diff.

## Detailed Findings

None. Zero critical, warning, or quality issues found.

## Status: clean

All code conforms to repository standards, architectural invariants, and Quickshell component guidelines.
