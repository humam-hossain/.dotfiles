---
phase: 40-notification-center-quick-dismiss-smart-interaction
plan: 01
subsystem: ui-notifications
tags: [quickshell, qml, notifications, otp, regex, url-parsing, restow]

requires:
  - phase: 39-dynamic-media-popup-anchoring
    provides: Restow overlay pattern, 5-section test harness architecture, strict submodule verification
provides:
  - scripts/phase40-notification-interaction-assert.sh test harness with 5 sections and porcelain tracking
  - NotificationUtils.qml restow overlay exporting extractOtpCode and extractUrl
  - Complete 19-case test matrix for OTP extraction (14 positive, 5 negative)
  - Complete URL extraction test suite with HTML anchor unescaping, punctuation stripping, and scheme whitelisting
affects:
  - 40-02

actuals:
  tokens: 5200
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - Pure JavaScript regex extraction within QML Singleton overlays
    - Bounded non-greedy regex matching with negative lookaround bounds preventing ReDoS
    - Chromium HTML anchor parsing with XML entity unescaping and HTTP/HTTPS whitelist
    - 5-section test harness architecture with porcelain baseline diffing

key-files:
  created:
    - scripts/phase40-notification-interaction-assert.sh
    - restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml
  modified: []

key-decisions:
  - "D-05: Implemented extractUrl in NotificationUtils supporting Chromium HTML anchors (<a href='...'>) and standalone HTTP/HTTPS raw URLs with trailing punctuation stripping and scheme whitelisting."
  - "D-07: Implemented extractOtpCode in NotificationUtils supporting 4-8 digit standalone, hyphenated, and service-prefixed codes anchored to security keywords with negative lookarounds."
  - "D-10: Deployed NotificationUtils.qml as a leaf symlink via restow/quickshell/ leaving vendor/dots-hyprland submodule 100% pristine."

patterns-established:
  - "ReDoS-safe notification text parsing with bounded quantifiers and negative boundary lookarounds"
  - "Leaf symlink restow pattern for modules/common/functions/"

requirements-completed:
  - OTP-01
  - NAV-02

coverage:
  - id: D1
    description: "Phase 40 assertion test harness with 5 sections, CLI flags, non-root check, and porcelain baseline tracking"
    requirement: "INTG-02"
    verification:
      - kind: integration
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "NotificationUtils.extractOtpCode regex parser detecting 4-8 digit codes anchored to security keywords with zero false positives"
    requirement: "OTP-01"
    verification:
      - kind: unit
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D3
    description: "NotificationUtils.extractUrl parsing Chromium HTML anchors and raw URLs with entity unescaping and scheme whitelisting"
    requirement: "NAV-02"
    verification:
      - kind: unit
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D4
    description: "Leaf symlink deployment of NotificationUtils.qml via GNU Stow without vendor/dots-hyprland submodule drift"
    requirement: "INTG-01"
    verification:
      - kind: integration
        ref: "./scripts/phase40-notification-interaction-assert.sh --section 5"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-09-24
status: complete
---

# Phase 40 Plan 01: Notification Interaction Foundation Summary

**Established test harness foundation `scripts/phase40-notification-interaction-assert.sh` and authored `NotificationUtils.qml` restow overlay implementing robust OTP code extraction and safe URL parsing with 100% test matrix pass rate.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-09-24T09:56:00Z
- **Completed:** 2026-09-24T10:04:00Z
- **Tasks:** 2 completed
- **Files modified:** 2 files created/modified

## Accomplishments

- Established `scripts/phase40-notification-interaction-assert.sh` 5-section test harness supporting `--section <1-5>`, `--syntax`, non-root execution checks, and git porcelain baseline tracking.
- Created `NotificationUtils.qml` restow overlay preserving upstream functions while exporting `extractOtpCode(body, summary)` and `extractUrl(body)`.
- Verified `extractOtpCode` against 14 positive and 5 negative test cases (rejecting calendar dates, timestamps, phone numbers, order IDs, and counter metrics with 100% precision).
- Verified `extractUrl` against Chromium HTML anchor tags, YouTube parameters, raw URLs with trailing punctuation, and untrusted scheme rejections (`javascript:`, `file:`, `data:`).
- Deployed `NotificationUtils.qml` as a leaf symlink into `~/.config/quickshell/ii/modules/common/functions/` via GNU Stow with zero git churn in `vendor/dots-hyprland`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — Test harness foundation and restow scaffolding for NotificationUtils.qml** - `af717c6` (test)
2. **Task 2: Implement extractOtpCode and extractUrl in NotificationUtils.qml with test matrix** - `c6c2d26` (feat)

**Plan metadata:** `docs(40-01): complete notification interaction foundation plan`

## Self-Check: PASSED

- `scripts/phase40-notification-interaction-assert.sh`: PASSED (all sections 1-5)
- `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml`: Exists and is valid QML
- `~/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml`: Leaf symlink into restow
- `./arch/dots-hyprland.sh verify --strict`: PASSED (`FAIL=0 FINDINGS=0`)
- Submodule `vendor/dots-hyprland`: Pristine (0 diff)
