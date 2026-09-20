---
phase: "32"
slug: "component-representation-formatting-customization"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-20"
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`set -euo pipefail`) |
| **Config file** | None — self-contained executable harness (`scripts/phase32-component-formatting-assert.sh`) |
| **Quick run command** | `./scripts/phase32-component-formatting-assert.sh --section 1` |
| **Full suite command** | `./scripts/phase32-component-formatting-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase32-component-formatting-assert.sh --section <N>` matching the task domain
- **After every plan wave:** Run `./scripts/phase32-component-formatting-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`./scripts/phase32-component-formatting-assert.sh` and `./arch/dots-hyprland.sh verify --strict`)
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | COMP-01, COMP-02, COMP-03, COMP-04, COMP-05, COMP-06, COMP-07, COMP-08, COMP-09, COMP-10 | T-32-01 | Test harness scaffolded and failing closed against unbuilt features | test scaffold | `./scripts/phase32-component-formatting-assert.sh` | ❌ W0 | ⬜ pending |
| 32-01-02 | 01 | 2 | COMP-03, COMP-05, COMP-06, COMP-09 | T-32-02 | Native JSON options aligned across capture and live config without syntax error | contract | `./scripts/phase32-component-formatting-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 32-02-01 | 02 | 1 | COMP-01, COMP-02 | T-32-03 | Definite RAM GB format, CPU icon/badge, dynamic swap, and synchronized two-tier alert coloring | unit/integration | `./scripts/phase32-component-formatting-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 32-02-02 | 02 | 1 | COMP-03, COMP-04, COMP-08, COMP-10 | T-32-04 | Clock spacer glyph removal, privacy revealers connected, media auto-collapse, no scroll | unit/integration | `./scripts/phase32-component-formatting-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 32-02-03 | 02 | 2 | COMP-07, INTG-02 | T-32-05 | Dedicated package updates pill and full repository verification pass | smoke/regression | `./scripts/phase32-component-formatting-assert.sh --section 4` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase32-component-formatting-assert.sh` — executable 4-section test harness covering COMP-01 through COMP-10 and repository verification

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual live reload via keybind | COMP-03, COMP-08 | Requires active display server session | Press `Ctrl+Super+R` and verify Quickshell top bar restarts smoothly without errors |
| Privacy microphone / screen share animation | COMP-08 | Requires PipeWire hardware / streaming source | Open recording software and verify animated Amber mic / Red screen share icon reveals in status cluster |
| Package updates terminal launch | COMP-07 | Interactive Kitty terminal window | Click on pending updates pill and verify Kitty launches `yay -Syu` in fish shell |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
