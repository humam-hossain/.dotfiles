---
phase: "50"
slug: "quickshell-deep-performance-optimization-overhead-reduction"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-30"
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash Assertion Harness (`scripts/phase50-opt-assert.sh`, `scripts/profile-quickshell.sh`) |
| **Config file** | `scripts/phase50-opt-assert.sh` (Wave 0 scaffold) |
| **Quick run command** | `bash scripts/phase50-opt-assert.sh -s 1` |
| **Full suite command** | `bash scripts/phase50-opt-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase50-opt-assert.sh -s 1` (or relevant section `-s <N>`)
- **After every plan wave:** Run `bash scripts/phase50-opt-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | OPT-05 | T-50-01 | Pre-flight test harness scaffold & AST assertion suite | unit | `test -x scripts/phase50-opt-assert.sh && bash -n scripts/phase50-opt-assert.sh && bash scripts/phase50-opt-assert.sh -s 1` | ❌ W0 | ⬜ pending |
| 50-01-02 | 01 | 1 | OPT-01 | T-50-02 | Quiescent idle timer coalescing & demand-gated fast polling | unit | `bash scripts/phase50-opt-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 50-02-01 | 02 | 2 | OPT-03 | T-50-03 | Subshell elimination across ResourceUsage, StorageUsage & NetworkUsage | unit | `bash scripts/phase50-opt-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 50-02-02 | 02 | 2 | OPT-03 | T-50-04 | NetworkPingPopup GPU boost lock elimination & PingService XHR throttle | integration | `bash scripts/phase50-opt-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 50-03-01 | 03 | 2 | OPT-02 | T-50-05 | PlayerControl OpacityMask & live blur elimination, cava stream gating | integration | `bash scripts/phase50-opt-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 50-03-02 | 03 | 2 | OPT-04 | T-50-06 | Popup Canvas chart redraw clamping, ClockWidget tick decoupling, shadow cache | integration | `bash scripts/phase50-opt-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 50-04-01 | 04 | 3 | OPT-05 | T-50-07 | Empirical 8-stage re-benchmarking, attribution matrix update & strict stow verification | regression | `bash scripts/phase50-opt-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase50-opt-assert.sh` — 5-section validation harness covering preconditions, subshell elimination AST checks, timer coalescing AST checks, empirical performance budgets, and repository integrity.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| MediaControls & PlayerControl Visual Aesthetics | OPT-02 | Rounded clipping and album art visual presentation | Open MediaControls popup and verify album art rendering, typography, and controls |
| Popup History Graph Visual Smoothness | OPT-04 | Visual rendering of Canvas line charts | Open CpuGpuPopup and MemoryStoragePopup and verify history graphs update cleanly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
