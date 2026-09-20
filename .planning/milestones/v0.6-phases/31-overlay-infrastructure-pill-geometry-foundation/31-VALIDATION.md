---
phase: "31"
slug: "overlay-infrastructure-pill-geometry-foundation"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-20"
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`set -euo pipefail`) |
| **Config file** | None — self-contained executable harness (`scripts/phase31-overlay-pill-assert.sh`) |
| **Quick run command** | `./scripts/phase31-overlay-pill-assert.sh --section 1` |
| **Full suite command** | `./scripts/phase31-overlay-pill-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase31-overlay-pill-assert.sh --section <N>` matching the task domain
- **After every plan wave:** Run `./scripts/phase31-overlay-pill-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`./scripts/phase31-overlay-pill-assert.sh` and `./arch/dots-hyprland.sh verify --strict`)
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | PILL-01, PILL-02, PILL-03, PILL-04 | T-31-01 | Test harness scaffolded and failing closed against unbuilt features | test scaffold | `./scripts/phase31-overlay-pill-assert.sh` | ❌ W0 | ⬜ pending |
| 31-01-02 | 01 | 2 | PILL-01 | T-31-02 | Overlay tree established under `restow/quickshell/` and safely stowed with `--no-folding` | contract | `./scripts/phase31-overlay-pill-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 31-02-01 | 02 | 1 | PILL-02, PILL-03 | T-31-03 | Dynamic content-driven pill sizing unlocked in `BarContent.qml` without artificial clamps | unit/integration | `./scripts/phase31-overlay-pill-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 31-02-02 | 02 | 1 | PILL-03, PILL-04 | T-31-04 | Dynamic resizing animation and style fidelity preserved in `BarGroup.qml` | unit/integration | `./scripts/phase31-overlay-pill-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 31-02-03 | 02 | 2 | INTG-02 | T-31-05 | System hygiene verified (`restow/README.md` in sync, strict verify passes clean) | smoke/regression | `./scripts/phase31-overlay-pill-assert.sh --section 4` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase31-overlay-pill-assert.sh` — executable 4-section test harness covering PILL-01, PILL-02, PILL-03, PILL-04, and repository verification

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual live reload via keybind | PILL-01 | Requires active display server session | Press `Ctrl+Super+R` and verify Quickshell top bar restarts smoothly without errors |
| Fluid visual resizing | PILL-03 | Subjective animation smoothness on hardware | Observe pill width change during clock/date transition or memory usage update |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
