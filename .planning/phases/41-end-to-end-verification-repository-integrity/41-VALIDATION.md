---
phase: "41"
slug: "end-to-end-verification-repository-integrity"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash Assert Engine (`scripts/phase41-interactions-assert.sh`) |
| **Config file** | `scripts/phase41-interactions-assert.sh` |
| **Quick run command** | `./scripts/phase41-interactions-assert.sh --quick` |
| **Full suite command** | `./scripts/phase41-interactions-assert.sh` |
| **Estimated runtime** | ~6s quick / ~32s full |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase41-interactions-assert.sh --syntax`
- **After every plan wave:** Run `./scripts/phase41-interactions-assert.sh --quick`
- **Before `/gsd-verify-work`:** Full suite must be green (`./scripts/phase41-interactions-assert.sh`)
- **Max feedback latency:** 6 seconds (quick)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 0 | INTG-01, INTG-02, INTG-03 | T-41-01 | Root EUID check, CLI flag sanitization, signal trap cleanup | Foundation / Harness Scaffolding | `test -x scripts/phase41-interactions-assert.sh && ./scripts/phase41-interactions-assert.sh --syntax` | ❌ W0 | ⬜ pending |
| 41-01-02 | 01 | 1 | INTG-01 | T-41-02 | Leaf symlink isolation, vendor untouched | Integration | `./scripts/phase41-interactions-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 41-01-03 | 01 | 1 | INTG-02 (Power/Media) | T-41-01 | Atomic power profile restore on EXIT/INT/TERM | Integration | `./scripts/phase41-interactions-assert.sh --section 2 && ./scripts/phase41-interactions-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 41-02-01 | 02 | 2 | INTG-02 (Notif/OTP/Clock/Vol) | T-41-03 | URL scheme regex sanitization, headless AST evaluation | Integration | `./scripts/phase41-interactions-assert.sh --section 4 && ./scripts/phase41-interactions-assert.sh --section 5` | ❌ W0 | ⬜ pending |
| 41-02-02 | 02 | 2 | INTG-03 | T-41-02 | Zero porcelain drift, FAIL=0 FINDINGS=0 strict verification | E2E Integrity | `./scripts/phase41-interactions-assert.sh --section 6` | ❌ W0 | ⬜ pending |
| 41-02-03 | 02 | 3 | INTG-01, INTG-02, INTG-03 | T-41-01..03 | Full test suite passes across all sections & chained sub-harnesses | Full Milestone E2E | `./scripts/phase41-interactions-assert.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase41-interactions-assert.sh` — The milestone v0.8 integration assert harness covering INTG-01, INTG-02, INTG-03.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Transient visual notification pop | INTG-02 | Requires live display session and visual human inspection | Run `./scripts/phase41-interactions-assert.sh --live-notify` and observe 800ms popup card |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 6s (quick mode)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
