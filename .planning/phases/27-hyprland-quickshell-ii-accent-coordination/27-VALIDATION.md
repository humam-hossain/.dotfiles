---
phase: "27"
slug: "hyprland-quickshell-ii-accent-coordination"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-17"
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`scripts/phase27-accent-coordination-assert.sh`) |
| **Config file** | `scripts/phase27-accent-coordination-assert.sh` |
| **Quick run command** | `bash scripts/phase27-accent-coordination-assert.sh --section 1` |
| **Full suite command** | `bash scripts/phase27-accent-coordination-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase27-accent-coordination-assert.sh --section <N>` matching the task domain
- **After every plan wave:** Run `bash scripts/phase27-accent-coordination-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0`, 0 findings)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 0 | INTG-01 | T-27-01 | Guard-paths contract & fail-closed harness scaffold | contract | `bash scripts/phase27-accent-coordination-assert.sh --help` | ✅ yes | ✅ green |
| 27-01-02 | 01 | 1 | INTG-01 | T-27-01 | Template & config readiness (Matugen, colors.lua, custom purity) | unit | `bash scripts/phase27-accent-coordination-assert.sh --section 1` | ✅ yes | ✅ green |
| 27-02-01 | 02 | 2 | SHELL-01 | T-27-02 | Hyprland border token match & live compositor query | integration | `bash scripts/phase27-accent-coordination-assert.sh --section 2` | ✅ yes | ✅ green |
| 27-02-02 | 02 | 2 | SHELL-02 | T-27-02 | Quickshell M3 token schema & warning threshold integrity | integration | `bash scripts/phase27-accent-coordination-assert.sh --section 3` | ✅ yes | ✅ green |
| 27-03-01 | 03 | 3 | SHELL-03 | T-27-03 | Coordinated live reload drill & border sync | integration | `bash scripts/phase27-accent-coordination-assert.sh --section 4` | ✅ yes | ✅ green |
| 27-03-02 | 03 | 3 | INTG-02 | T-27-03 | Full 5-section suite pass & strict verification 0 findings | smoke / regression | `bash scripts/phase27-accent-coordination-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ✅ yes | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase27-accent-coordination-assert.sh` — author 5-section test harness covering SHELL-01, SHELL-02, SHELL-03, INTG-01, INTG-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual smoothness of border color transition during wallpaper change | SHELL-03 | Aesthetic inspection of live screen rendering | Trigger `switchwall.sh` and visually confirm window borders update cleanly without visible lag or redraw glitch |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated (2026-09-17)
