---
phase: "37"
slug: "bar-layout-integration-dual-monitor-verification-strict-pack"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-21"
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash Multi-Section Assertion Suite (`scripts/phase37-voice-pill-assert.sh`) |
| **Config file** | None — self-contained executable harness |
| **Quick run command** | `./scripts/phase37-voice-pill-assert.sh -s 1` |
| **Full suite command** | `./scripts/phase37-voice-pill-assert.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase37-voice-pill-assert.sh -s 1` (or relevant section)
- **After every plan wave:** Run `./scripts/phase37-voice-pill-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0 FINDINGS=0`)
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | INTG-01, INTG-02, INTG-04 | — | N/A | harness scaffold & layout | `./scripts/phase37-voice-pill-assert.sh -s 1` | ❌ W0 | ⬜ pending |
| 37-01-02 | 01 | 1 | INTG-01, INTG-02 | — | N/A | event isolation & geometry | `./scripts/phase37-voice-pill-assert.sh -s 2 && ./scripts/phase37-voice-pill-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 37-01-03 | 01 | 1 | INTG-03, INTG-04 | — | N/A | theme audit & strict gate | `./scripts/phase37-voice-pill-assert.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase37-voice-pill-assert.sh` — 5-section test harness covering INTG-01, INTG-02, INTG-03, INTG-04

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | All phase behaviors have automated verification via `scripts/phase37-voice-pill-assert.sh`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
