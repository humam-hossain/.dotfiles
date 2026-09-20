---
phase: 33-modular-layout-live-trial-and-error-rearrangement
plan: "01"
subsystem: ui-bar-layout
tags: [quickshell, bash, assert-harness, symlinks, multi-monitor, qml]

# Dependency graph
requires:
  - phase: 32-component-representation-formatting-customization
    provides: Component formatting overlays, Phase 32 assert script baseline, and sysTray/updates styling
provides:
  - scripts/phase33-layout-assert.sh automated test harness gating Phase 33 layout reorganization
  - Fail-closed CLI (--section 1-4) with two-phase git porcelain non-mutation invariant
  - Verified Section 1 symlink baseline and submodule cleanliness
affects: [33-02, 33-03, phase-33]

# Actuals
actuals:
  tokens: 2800
  tasks: 4
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns: [4-section assert harness architecture, two-phase git porcelain snapshot invariance, AST component order inspection, mathematical space collision defense verification]

key-files:
  created: [scripts/phase33-layout-assert.sh]
  modified: []

key-decisions:
  - "Scaffolded scripts/phase33-layout-assert.sh with mode 0755 and 4 domain-partitioned sections following Phase 32 conventions"
  - "Section 1 asserts leaf symlinks for BarContent.qml and BarGroup.qml, real non-folded ancestor directories, and clean vendor/dots-hyprland submodule"
  - "Section 2 asserts AST declaration ordering across Left, Center, and Right zones, pill wrapping in BarGroup, and presence of flexible spacers"
  - "Section 3 asserts spacing 4, Media width clamping (140/200), ClockWidget bullet absence, centerSideModuleWidth removal, and >= 180px collision safety buffer"
  - "Section 4 asserts dual-monitor detection (DP-1 and HDMI-A-1/2), Quickshell daemon responsiveness, Phase 32 regression zero-failure, and strict dots-hyprland verifier"

patterns-established:
  - "Option 1 dynamic space defense mathematical buffer verification on 1080p display"

requirements-completed: [LAYOUT-01]

# Coverage metadata
coverage:
  - id: D1
    description: "Automated test harness scripts/phase33-layout-assert.sh created with fail-closed CLI (--section 1-4) and git porcelain non-mutation invariant"
    requirement: LAYOUT-01
    verification:
      - kind: integration
        ref: "scripts/phase33-layout-assert.sh --help"
        status: pass
    human_judgment: false
  - id: D2
    description: "Section 1 verifies leaf symlinks for BarContent.qml and BarGroup.qml, ancestor directories without folding, and clean vendor submodule"
    requirement: LAYOUT-01
    verification:
      - kind: integration
        ref: "scripts/phase33-layout-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "Section 2, 3, and 4 verify component AST zone distribution, pill geometry defense, and multi-monitor runtime parity with Phase 32 & dots-hyprland compliance"
    requirement: LAYOUT-01
    verification:
      - kind: integration
        ref: "scripts/phase33-layout-assert.sh --section 4"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-09-20
status: complete
---

# Phase 33 Plan 01: Automated Validation Harness & Symlink Baseline Summary

**Delivered the foundational Nyquist-compliant test harness `scripts/phase33-layout-assert.sh` across Sections 1 to 4 with working CLI, two-phase git porcelain invariance, and green Section 1 baseline.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-20T16:12:15+06:00
- **Completed:** 2026-09-20T16:16:00+06:00
- **Tasks:** 4
- **Files modified:** 1

## Accomplishments

- Scaffolded `scripts/phase33-layout-assert.sh` with mode 0755, fail-closed CLI argument handling (`--section <1-4>`), non-root execution check, and two-phase git status porcelain snapshot check.
- Implemented Section 1 asserting leaf symlink integrity (`BarContent.qml`, `BarGroup.qml`), non-folded ancestor directories, and 100% clean `vendor/dots-hyprland` submodule.
- Implemented Section 2 asserting AST component ordering across Left, Center, and Right zones, pill wrapping in `BarGroup`, absence of inverted order (`Qt.RightToLeft`), and flexible spacers.
- Implemented Section 3 asserting `spacing: 4`, Media width clamping, Clock side-by-side formatting without bullet glyph, absence of `centerSideModuleWidth`, absence of anchor loops inside `RowLayout`, and Option 1 mathematical safety buffer (>= 180px on 1080p).
- Implemented Section 4 asserting multi-monitor runtime parity (`DP-1` 3440x1440 and `HDMI-A-1`/`HDMI-A-2`), Quickshell daemon process check, zero Phase 32 formatting regressions, and `./arch/dots-hyprland.sh verify --strict` pass with 0 findings.

## Task Commits

Each task was committed atomically:

1. **Task 33-01-01: Scaffold scripts/phase33-layout-assert.sh CLI interface and Section 1** - `4f95661` (test)
2. **Task 33-01-02: Implement Section 2 AST & Component zone partitioning assertions** - `62e4fe3` (test)
3. **Task 33-01-03: Implement Section 3 Pill boundary geometry and Option 1 collision defense assertions** - `8531ac0` (test)
4. **Task 33-01-04: Implement Section 4 Dual-monitor runtime parity and strict verification** - `f75b535` (test)

## Files Created/Modified

- `scripts/phase33-layout-assert.sh` - 4-section automated validation harness for Phase 33 layout reorganization and runtime verification.

## Decisions Made

- Enforced Option 1 dynamic space defense mathematical verification: verified that standard 1080p width (1920px) leaves at least 180px buffer between center pill cluster and max expanded right pill cluster, preventing overlap without artificial clamps.
- Bound Section 4 to query active monitors via `hyprctl monitors -j` while falling back to inspecting Hyprland configurations for secondary display definitions when only primary display is attached.
- Maintained strict isolation and zero drift: test suite verifies that git status remains 100% unchanged across assertions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Ready for Plan 33-02 (Modular Bar Content Reorganization in `BarContent.qml`).
- The automated test harness `scripts/phase33-layout-assert.sh` is immediately available to test QML changes across Sections 1, 2, 3, and 4.

---
*Phase: 33-modular-layout-live-trial-and-error-rearrangement*
*Completed: 2026-09-20*
