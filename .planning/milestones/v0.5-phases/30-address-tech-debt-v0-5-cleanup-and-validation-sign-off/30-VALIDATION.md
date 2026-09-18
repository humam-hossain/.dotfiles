---
phase: "30"
slug: "address-tech-debt-v0-5-cleanup-and-validation-sign-off"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-18"
validated: "2026-09-18"
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
| 30-01-01 | 01 | 1 | DEBT-05 | T-30-01 | Kitty background opacity set to 0.90 in restow and Phase 28 probe aligned | integration | `bash scripts/phase30-tech-debt-assert.sh --section 1` | ✅ | ✅ green |
| 30-01-02 | 01 | 1 | DEBT-06 | T-30-02 | Bootstrap virtualenv export and live wrapper/applycolor signaling hardened | integration | `bash scripts/phase30-tech-debt-assert.sh --section 2` | ✅ | ✅ green |
| 30-02-01 | 02 | 0 | DEBT-08 | T-30-03 | Dedicated Phase 30 assert harness scaffolded with fail-closed structure | contract | `bash scripts/phase30-tech-debt-assert.sh --help` | ✅ | ✅ green |
| 30-02-02 | 02 | 1 | DEBT-07 | T-30-03 | 29-VALIDATION.md signed off and all v0.5 phases compliant | contract | `bash scripts/phase30-tech-debt-assert.sh --section 3` | ✅ | ✅ green |
| 30-02-03 | 02 | 2 | DEBT-08 | T-30-03 | Full Phase 30 test suite and multi-phase regression sweep across Phases 25–29 | regression | `bash scripts/phase30-tech-debt-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ✅ | ✅ green |

*Status: ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase30-tech-debt-assert.sh` — Phase 30 assert harness scaffold with `--section <1-5>` dispatch, fail-closed reporting, and multi-phase regression sweep (Plan 30-02 Task 1)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | DEBT-05..08 | Fully automated | All phase deliverables have automated command assertions in `scripts/phase30-tech-debt-assert.sh` |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
