---
phase: "30"
slug: "address-tech-debt-v0-5-cleanup-and-validation-sign-off"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-18"
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`scripts/phase30-tech-debt-assert.sh`) |
| **Config file** | `scripts/phase30-tech-debt-assert.sh` |
| **Quick run command** | `bash scripts/phase30-tech-debt-assert.sh --section 1` |
| **Full suite command** | `bash scripts/phase30-tech-debt-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~12 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase30-tech-debt-assert.sh --section <N>` matching the task domain (< 3s)
- **After every plan wave:** Run `bash scripts/phase30-tech-debt-assert.sh && ./arch/dots-hyprland.sh verify --strict` (< 12s)
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0 FINDINGS=0`) with zero git drift
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | DEBT-05 | T-30-01 | Kitty background opacity set to 0.90 in restow and live reload signaled | integration | `grep -q "background_opacity 0.90" restow/kitty/.config/kitty/kitty.conf && kitty +runpy "from kitty.config import load_config; opts = load_config('restow/kitty/.config/kitty/kitty.conf'); assert abs(opts.background_opacity - 0.90) <= 0.01"` | ✅ | ⬜ pending |
| 30-01-02 | 01 | 1 | DEBT-05 | T-30-01 | Phase 28 assert aligned to 0.90 opacity and Section 3 passes cleanly | regression | `bash scripts/phase28-terminal-fuzzel-assert.sh --section 3` | ✅ | ⬜ pending |
| 30-01-03 | 01 | 1 | DEBT-06 | T-30-02 | Bootstrap exports virtualenv fallback and applies idempotent sanitization | integration | `grep -q 'export ILLOGICAL_IMPULSE_VIRTUAL_ENV' bootstrap.sh && grep -q 'killall -SIGUSR1 kitty' bootstrap.sh` | ✅ | ⬜ pending |
| 30-01-04 | 01 | 1 | DEBT-06 | T-30-02 | Live applycolor.sh and KDE wrapper hardened with safe signaling and fallback | integration | `grep -q 'killall -SIGUSR1 kitty' ~/.config/quickshell/ii/scripts/colors/applycolor.sh && grep -q 'ILLOGICAL_IMPULSE_VIRTUAL_ENV:-' ~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` | ✅ | ⬜ pending |
| 30-02-01 | 02 | 0 | DEBT-08 | T-30-03 | Dedicated Phase 30 assert harness scaffolded with fail-closed structure | contract | `bash scripts/phase30-tech-debt-assert.sh --help` | ❌ W0 | ⬜ pending |
| 30-02-02 | 02 | 1 | DEBT-07 | T-30-03 | 29-VALIDATION.md signed off and all v0.5 phases compliant | contract | `grep -q 'status: validated' .planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md && grep -q 'nyquist_compliant: true' .planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md` | ✅ | ⬜ pending |
| 30-02-03 | 02 | 1 | DEBT-08 | T-30-03 | REQUIREMENTS.md and ROADMAP.md synchronized with DEBT-05..08 | contract | `grep -q 'DEBT-08' .planning/REQUIREMENTS.md && grep -q 'DEBT-08' .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 30-02-04 | 02 | 2 | DEBT-08 | T-30-03 | Full Phase 30 test suite and multi-phase regression sweep across Phases 25–29 | regression | `bash scripts/phase30-tech-debt-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase30-tech-debt-assert.sh` — Phase 30 assert harness scaffold with `--section <1-5>` dispatch, fail-closed reporting, and multi-phase regression sweep (Plan 30-02 Task 1)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | DEBT-05..08 | Fully automated | All phase deliverables have automated command assertions in `scripts/phase30-tech-debt-assert.sh` |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
