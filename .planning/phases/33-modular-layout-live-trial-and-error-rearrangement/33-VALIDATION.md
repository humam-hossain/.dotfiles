---
phase: "33"
slug: "modular-layout-live-trial-and-error-rearrangement"
status: ready
nyquist_compliant: true
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
| 33-01-01 | 01 | 1 | LAYOUT-01 | T-33-01, T-33-02 | fail-closed CLI | test scaffold | `test -x scripts/phase33-layout-assert.sh && bash scripts/phase33-layout-assert.sh --help \| grep -q -- '--section <1-4>' && bash scripts/phase33-layout-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 33-01-02 | 01 | 1 | LAYOUT-01 | T-33-01 | syntax & AST logic | ast/layout | `bash -n scripts/phase33-layout-assert.sh && grep -q 'Section 2: Component AST & Section Distribution' scripts/phase33-layout-assert.sh && grep -q 'leftSectionRowLayout' scripts/phase33-layout-assert.sh && grep -q 'rightSectionRowLayout' scripts/phase33-layout-assert.sh` | ❌ W0 | ⬜ pending |
| 33-01-03 | 01 | 1 | LAYOUT-01, LAYOUT-03 | T-33-04 | geometry invariant | geometry/buffer | `bash -n scripts/phase33-layout-assert.sh && grep -q 'Section 3: Pill Geometry, Anchors & Space Defense' scripts/phase33-layout-assert.sh && grep -q 'centerSideModuleWidth' scripts/phase33-layout-assert.sh` | ❌ W0 | ⬜ pending |
| 33-01-04 | 01 | 1 | LAYOUT-01 | T-33-01 | non-destructive scan | multi-monitor | `bash -n scripts/phase33-layout-assert.sh && grep -q 'Section 4: Dual-Monitor Runtime Parity' scripts/phase33-layout-assert.sh && bash scripts/phase33-layout-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 33-02-01 | 02 | 2 | LAYOUT-01 | T-33-05 | anchor isolation | ast/layout | `grep -q 'resourcesGroup' restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml && grep -q 'utilButtonsGroup' restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml && grep -q 'Layout.leftMargin: Appearance.rounding.screenRounding' restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | ❌ W0 | ⬜ pending |
| 33-02-02 | 02 | 2 | LAYOUT-01 | T-33-04 | strict center anchoring | ast/layout | `grep -q 'weatherGroup' restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml && grep -q 'anchors.horizontalCenter: parent.horizontalCenter' restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml && ! grep -q 'VerticalBarSeparator' restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | ❌ W0 | ⬜ pending |
| 33-02-03 | 02 | 2 | LAYOUT-01, LAYOUT-03 | T-33-04, T-33-07 | width clamping & elision | ast/layout | `bash scripts/phase33-layout-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 33-02-04 | 02 | 2 | LAYOUT-01, LAYOUT-03 | T-33-01..10 | integrated assert sweep | full integration | `bash scripts/phase33-layout-assert.sh --section 1 && bash scripts/phase33-layout-assert.sh --section 2 && bash scripts/phase33-layout-assert.sh --section 3 && bash scripts/phase32-component-formatting-assert.sh` | ❌ W0 | ⬜ pending |
| 33-03-01 | 03 | 3 | LAYOUT-02, LAYOUT-03 | T-33-03 | runtime monitor probe | multi-monitor | `bash scripts/phase33-layout-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 33-03-02 | 03 | 3 | LAYOUT-02 | T-33-08 | operator sign-off | visual evaluation | `bash scripts/phase33-layout-assert.sh` | ❌ W0 | ⬜ pending |
| 33-03-03 | 03 | 3 | LAYOUT-02, LAYOUT-03 | T-33-09, T-33-10 | zero drift verifier | system strict | `bash scripts/phase33-layout-assert.sh && bash scripts/phase32-component-formatting-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase33-layout-assert.sh` — 4-section assertion harness covering symlinks, AST component partitioning, pill geometry/space defense, and multi-monitor runtime parity

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live visual appeal, balance, and user trial-and-error confirmation | LAYOUT-02 | Visual aesthetics, spacing perception, and subjective preference on physical screens cannot be asserted solely via AST parsing | Trigger `Ctrl+Super+R` in Hyprland, inspect bar on `DP-1` (3440x1440) and `HDMI-A-1`/`HDMI-A-2` (1920x1080), verify visual balance of pills |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready
