---
phase: "36"
slug: "visual-voice-pill-component-dynamic-animations"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-21"
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness + headless Quickshell test runner (`quickshell -p`) |
| **Config file** | `scripts/phase36-voice-pill-assert.sh` (Wave 0) |
| **Quick run command** | `./scripts/phase36-voice-pill-assert.sh --syntax` |
| **Full suite command** | `./scripts/phase36-voice-pill-assert.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase36-voice-pill-assert.sh --syntax`
- **After every plan wave:** Run `./scripts/phase36-voice-pill-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | VOICE-01, VOICE-02, VOICE-06 | — | N/A | unit | `./scripts/phase36-voice-pill-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 36-01-02 | 01 | 1 | VOICE-03 | — | N/A | unit | `./scripts/phase36-voice-pill-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 36-01-03 | 01 | 1 | VOICE-04, VOICE-05 | — | N/A | integration | `./scripts/phase36-voice-pill-assert.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase36-voice-pill-assert.sh` — automated syntax, AST, and headless mock verification harness covering VOICE-01 through VOICE-06

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual aesthetic & font alignment in bar | VOICE-01 | Pixel-level visual balance against neighboring status bar pills | Launch status bar and visually inspect resting `graphic_eq` alignment |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
