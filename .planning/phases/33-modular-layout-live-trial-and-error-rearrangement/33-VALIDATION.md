---
phase: "33"
slug: "modular-layout-live-trial-and-error-rearrangement"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-20"
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash assertion test harness (`scripts/phase33-layout-assert.sh`) + `arch/dots-hyprland.sh verify --strict` |
| **Config file** | `scripts/phase33-layout-assert.sh` |
| **Quick run command** | `bash scripts/phase33-layout-assert.sh --section 2` |
| **Full suite command** | `bash scripts/phase33-layout-assert.sh` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase33-layout-assert.sh --section 2` (or relevant section)
- **After every plan wave:** Run `bash scripts/phase33-layout-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | LAYOUT-01 | — | N/A | test scaffold | `test -x scripts/phase33-layout-assert.sh && bash scripts/phase33-layout-assert.sh --help | grep -q -- '--section <1-4>'` | ❌ W0 | ⬜ pending |
| 33-01-02 | 01 | 1 | LAYOUT-01 | — | N/A | unit/syntax | `bash scripts/phase33-layout-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 33-02-01 | 02 | 2 | LAYOUT-01 | — | N/A | ast/layout | `bash scripts/phase33-layout-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 33-02-02 | 02 | 2 | LAYOUT-03 | — | N/A | geometry/buffer | `bash scripts/phase33-layout-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 33-02-03 | 02 | 2 | LAYOUT-02 | — | N/A | multi-monitor | `bash scripts/phase33-layout-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 33-02-04 | 02 | 2 | LAYOUT-01, LAYOUT-02, LAYOUT-03 | — | N/A | full integration | `bash scripts/phase33-layout-assert.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase33-layout-assert.sh` — 4-section assertion harness covering symlinks, AST component partitioning, pill geometry/space defense, and multi-monitor runtime parity

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live visual appeal, balance, and user trial-and-error confirmation | LAYOUT-02 | Visual aesthetics, spacing perception, and subjective preference on physical screens cannot be asserted solely via AST parsing | Trigger `Ctrl+Super+R` in Hyprland, inspect bar on `DP-1` (3440x1440) and `HDMI-A-1` (1920x1080), verify visual balance of pills |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
