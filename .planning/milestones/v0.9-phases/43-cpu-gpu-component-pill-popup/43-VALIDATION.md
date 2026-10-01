---
phase: "43"
slug: "cpu-gpu-component-pill-popup"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-26"
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness (`scripts/phase43-cpu-gpu-assert.sh`) + headless quickshell runtime (`quickshell -p`) |
| **Config file** | `scripts/phase43-cpu-gpu-assert.sh` (Wave 0 creates) |
| **Quick run command** | `./scripts/phase43-cpu-gpu-assert.sh --quick` |
| **Full suite command** | `./scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase43-cpu-gpu-assert.sh --quick`
- **After every plan wave:** Run `./scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | CPUGPU-01 | ASVS-L1 | Fail closed on root (`EUID -ne 0`) | test-harness | `bash -n scripts/phase43-cpu-gpu-assert.sh && ./scripts/phase43-cpu-gpu-assert.sh --syntax` | ❌ W0 | ⬜ pending |
| 43-01-02 | 01 | 1 | CPUGPU-01 | ASVS-L1 | Screen boundary clamping (`minX` to `maxX`) | unit-static | `./scripts/phase43-cpu-gpu-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 43-02-01 | 02 | 2 | CPUGPU-01, CPUGPU-04 | ASVS-L1 | Inert mouse handling & safe null coalescing | unit-static | `./scripts/phase43-cpu-gpu-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 43-03-01 | 03 | 3 | CPUGPU-02, CPUGPU-03, CPUGPU-04 | ASVS-L1 | Unprivileged power fallback & leak-free refcounting | unit-static | `./scripts/phase43-cpu-gpu-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 43-03-02 | 03 | 3 | CPUGPU-01 | ASVS-L1 | Stow backup preservation & zero repo drift | integration | `./scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase43-cpu-gpu-assert.sh` — automated assertion harness for Phase 43 components, syntax, layout, and integration checks

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Pill hover and cursor transit | CPUGPU-01 | Requires interactive Wayland pointer events | Hover mouse over `CpuGpuPill` on bar, transit downward into `CpuGpuPopup`, verify overlay stays open without flicker |
| Inert mouse clicks | CPUGPU-01 | Requires Wayland input device button clicks | Click left, right, and middle mouse buttons on `CpuGpuPill`, verify no click-through or action triggers |
| Visual breathing animation | CPUGPU-04 | Dynamic visual perception on Wayland layer surface | Simulate critical load (>=90%) or temp (>=85°C), verify icon pulses opacity smoothly |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verified
