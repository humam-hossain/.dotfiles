---
phase: 46-left-zone-integration-verification-repository-integrity
plan: 02
subsystem: infra
tags: [stow, git, verification, testing, quickshell, cleanup]

requires:
  - phase: 46-01
    provides: Canonical Left zone sequence and test harness scaffold
provides:
  - Complete removal of deprecated legacy Resource.qml and Resources.qml components
  - Restored upstream stubs in live quickshell directory with zero dangling symlinks
  - Fully implemented 6-section consolidated milestone assertion suite scripts/phase46-telemetry-assert.sh
  - Strict repository verification passing with FAIL=0 FINDINGS=0
affects: [quickshell-bar, milestone-v0.9, repo-integrity]

actuals:
  tokens: 12000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [sub-harness-orchestration, arm-7-upstream-stub-restoration, zero-drift-porcelain-assertion]

key-files:
  created: []
  modified:
    - scripts/phase46-telemetry-assert.sh
  deleted:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml

key-decisions:
  - "D-08: Permanently remove legacy Resource.qml and Resources.qml from git repository and restore live .bak stubs"
  - "D-09: Ensure vendor/dots-hyprland submodule remains 100% pristine with zero git churn"
  - "D-10: Complete Sections 1, 4, 5, 6 in scripts/phase46-telemetry-assert.sh with full sub-harness orchestration"
  - "D-11: Standard CLI flags (-s, -q, -c, -h) and fail-closed exit status (FAIL=0 FINDINGS=0)"

patterns-established:
  - "Arm 7 upstream regular file stub restoration preventing dangling repo symlink failures in dots-hyprland verify"
  - "Orchestration of multi-phase regression suites into a single milestone assertion gate"

requirements-completed:
  - INTG-01
  - INTG-02
  - INTG-03

coverage:
  - id: D1
    description: "Legacy Resource.qml and Resources.qml removal and live stub restoration"
    requirement: "INTG-02"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false
  - id: D2
    description: "Complete 6-section test suite scripts/phase46-telemetry-assert.sh with sub-harness orchestration"
    requirement: "INTG-03"
    verification:
      - kind: integration
        ref: "./scripts/phase46-telemetry-assert.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Strict repository verification with zero churn in vendor/dots-hyprland"
    requirement: "INTG-02"
    verification:
      - kind: unit
        ref: "git status --porcelain vendor/dots-hyprland"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-09-29
status: complete
---

# Phase 46 Plan 02 Summary

**Permanently retired legacy Resource components, completed all 6 sections of scripts/phase46-telemetry-assert.sh with milestone sub-harness orchestration, and achieved 100% strict repository verification with zero git churn in vendor/dots-hyprland.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-29T16:52:00+06:00
- **Completed:** 2026-09-29T16:58:00+06:00
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Permanently removed legacy `Resource.qml` and `Resources.qml` from git repository and unlinked live symlinks in `~/.config/quickshell/ii/modules/ii/bar/`.
- Restored upstream `.bak` files into regular file stubs, cleanly satisfying Arm 7 in `./arch/dots-hyprland.sh verify --strict` with zero broken symlinks into the repository.
- Completed all 6 sections of `scripts/phase46-telemetry-assert.sh` including Stow leaf symlink topology, kernel sensor/daemon liveness, responsive centering invariants, and milestone sub-harness orchestration (`phase42`, `phase43.6`, `phase43-perf --quick`, `phase44`, `phase45`).
- Executed full milestone validation end-to-end: `./scripts/phase46-telemetry-assert.sh` passed with `FAIL=0 FINDINGS=0` and `./arch/dots-hyprland.sh verify --strict` passed cleanly (`=== done: FAIL=0 FINDINGS=0 ===`).
- Confirmed `vendor/dots-hyprland` submodule has 0 git churn.

## Task Commits

Each task was committed atomically:

1. **Task 1: Legacy Component Retirement & Symlink Cleanup** - `a04a3c52` (feat)
2. **Task 2: Complete Test Suite Sections 1, 4, 5, 6 (`scripts/phase46-telemetry-assert.sh`)** - `98443f7d`, `dfb12097` (feat/fix)
3. **Task 3: Full Milestone v0.9 Verification & Strict Repository Sign-Off** - verified across full suite and strict repository gate.

## Self-Check: PASSED
- `Resource.qml` and `Resources.qml` deleted from git repository.
- No dangling symlinks in live installation.
- `scripts/phase46-telemetry-assert.sh` passes 100% across all 6 sections.
- `./arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0`.
- `vendor/dots-hyprland` clean with 0 git churn.
