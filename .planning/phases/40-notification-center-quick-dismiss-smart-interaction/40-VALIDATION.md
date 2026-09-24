---
phase: "40"
slug: "notification-center-quick-dismiss-smart-interaction"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-24"
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness + Node test runner (`scripts/phase40-notification-interaction-assert.sh`) |
| **Config file** | `scripts/phase40-notification-interaction-assert.sh` (Wave 0) |
| **Quick run command** | `./scripts/phase40-notification-interaction-assert.sh --syntax` |
| **Full suite command** | `./scripts/phase40-notification-interaction-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase40-notification-interaction-assert.sh --syntax` (or section targeted)
- **After every plan wave:** Run `./scripts/phase40-notification-interaction-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-01-01 | 01 | 0 | INTG-01, INTG-02 | — | Harness validates symlink integrity, submodule cleanliness, and test matrices | unit | `test -x scripts/phase40-notification-interaction-assert.sh && ./scripts/phase40-notification-interaction-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 40-01-02 | 01 | 1 | OTP-01, NAV-02 | T-40-01, T-40-03 | Regex sanitization, safe URL schema bounds, OTP security keyword anchoring | unit | `./scripts/phase40-notification-interaction-assert.sh --section 3 && ./scripts/phase40-notification-interaction-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 40-02-01 | 02 | 2 | NOTIF-01, NOTIF-02 | — | Single notification card shows 'X' button; toast popup strictly suppresses it | unit | `./scripts/phase40-notification-interaction-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 40-02-02 | 02 | 2 | NAV-01, OTP-02 | T-40-02 | Smart body click routes D-Bus default / URL fallback; OTP chip copies to clipboard with 1.5s confirmation | unit | `./scripts/phase40-notification-interaction-assert.sh` | ❌ W0 | ⬜ pending |
| 40-02-03 | 02 | 3 | INTG-01, INTG-03 | — | Leaf symlinks deployed cleanly via stow; zero diff in vendor/dots-hyprland | integration | `./scripts/phase40-notification-interaction-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase40-notification-interaction-assert.sh` — assertion harness covering 5 sections (symlink integrity, AST verification, OTP regex matrix, URL extraction, repository strict verification)
- [ ] Staging test harness in `scripts/` before implementation components

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sidebar 'X' 1-click dismiss visual flow | NOTIF-01 | Requires active compositor window display | Open right sidebar (`Super+N`), trigger single test notification (`notify-send "Test" "Single"`), click 'X' button, verify card animates closed without expanding. |
| Multi-group header parity | NOTIF-01, NOTIF-02 | Requires visual inspection of expand chevron | Trigger 2 notifications from same app (`notify-send -a "Discord" "Msg 1"`, `notify-send -a "Discord" "Msg 2"`), verify expand chevron and count display with no 'X' button. |
| Toast popup suppression | NOTIF-02 | Requires live toast overlay inspection | Trigger test notification, verify toast popup appearing on screen does NOT have an 'X' close button and dismisses on hover or timeout. |
| OTP "Copy [Code]" Chip & Visual confirmation | OTP-02 | Requires interactive clipboard and timer verification | Trigger notification with OTP (`notify-send "Bank" "Your login code is 492019"`), click "Copy [492019]", verify button changes to "Copied!" for 1.5s and clipboard has `492019`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
