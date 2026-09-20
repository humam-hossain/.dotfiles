---
phase: 31-overlay-infrastructure-pill-geometry-foundation
plan: 01
subsystem: ui-shell
tags: [quickshell, stow, overlay, qml, status-bar, test-harness]

requires:
  - phase: 30-address-tech-debt-v0-5-cleanup-and-validation-sign-off
    provides: clean v0.5 baseline and test assert patterns
provides:
  - scripts/phase31-overlay-pill-assert.sh test harness with Section 1 implemented
  - restow/quickshell package with BarContent.qml and BarGroup.qml baseline overlays
  - restow/README.md Section 3 updated with quickshell recovery command
  - Deployed discrete leaf symlinks in ~/.config/quickshell/ii/modules/ii/bar/
affects: [31-02, phase-32, phase-33, phase-34]

tech-stack:
  added: []
  patterns: [GNU Stow --no-folding leaf overlay, two-phase porcelain snapshot harness]

key-files:
  created:
    - scripts/phase31-overlay-pill-assert.sh
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml
  modified:
    - restow/README.md

key-decisions:
  - "D-05: Maintained personal Quickshell modifications exclusively in restow/quickshell/ without touching vendor/dots-hyprland"
  - "D-06: Added quickshell to restow/README.md via ./scripts/gen-collision-map.sh --restow-table mapping to rsync-replace"
  - "D-08: Enforced two-phase porcelain snapshot invariants in scripts/phase31-overlay-pill-assert.sh"

patterns-established:
  - "Stow leaf symlink overlay: Deploy via cd restow && stow --verbose=5 --no-folding -t ~ <pkg> after removing/backing up target regular files"

requirements-completed: [PILL-01]

coverage:
  - id: D1
    description: "Phase 31 assertion harness scaffolded with --section CLI parsing and fail-closed snapshot checks"
    requirement: "PILL-01"
    verification:
      - kind: unit
        ref: "scripts/phase31-overlay-pill-assert.sh --help"
        status: pass
    human_judgment: false
  - id: D2
    description: "Quickshell overlay package established and deployed as leaf symlinks with Section 1 verification"
    requirement: "PILL-01"
    verification:
      - kind: integration
        ref: "scripts/phase31-overlay-pill-assert.sh --section 1"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-20
status: complete
---

# Phase 31: Plan 01 Summary

**Established personal Quickshell overlay infrastructure in `restow/quickshell/`, deployed discrete leaf symlinks without folding ancestor directories, updated `restow/README.md`, and validated Section 1 symlink & packaging integrity.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-20T07:02:00Z
- **Completed:** 2026-09-20T07:02:50Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Scaffolded `scripts/phase31-overlay-pill-assert.sh` with executable permissions (0755), supporting `--section <1-4>`, `-h|--help`, cleanup traps, and two-phase porcelain snapshot checks.
- Established `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` containing baseline `BarContent.qml` and `BarGroup.qml` copied from upstream `vendor/dots-hyprland`, keeping `vendor/` completely pristine.
- Updated `restow/README.md` Section 3 table via `./scripts/gen-collision-map.sh --restow-table`, verifying package `quickshell` is tagged as `rsync-replace`.
- Executed the safe replacement procedure removing live regular files (with `.bak` backup) and deploying leaf symlinks using GNU Stow `--no-folding`.
- Implemented and verified Section 1 in `scripts/phase31-overlay-pill-assert.sh`, confirming leaf symlink destinations, unfolded ancestor directories, intact siblings, and clean vendor submodule state with `FAIL=0 FINDINGS=0`.

## Task Commits

1. **Task 31-01-01: Scaffold Phase 31 overlay and pill geometry assert harness** - `3cb01f5` (feat)
2. **Task 31-01-02: Establish restow/quickshell package, regenerate restow table, deploy symlinks, and verify Section 1** - `7f886ac` (feat)

## Files Created/Modified
- `scripts/phase31-overlay-pill-assert.sh` - Automated 4-section assertion test harness for Phase 31
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` - Overlay status bar content layout component
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` - Overlay status bar pill container component
- `restow/README.md` - Generated Section 3 package recovery table containing quickshell package

## Decisions Made
- Confined personal overlay files strictly to `restow/quickshell/` to maintain 100% clean vendor tracking.
- Adhered to repository policy banning `stow --adopt`, using backup and replacement before stowing.
- Utilized `--no-folding` to ensure only the target QML files become symlinks while ancestor directories remain real directories.

## Self-Check: PASSED
- `scripts/phase31-overlay-pill-assert.sh` exists and is executable.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` and `BarGroup.qml` exist.
- `git log --oneline --all --grep="31-01"` returns 2 commits (`3cb01f5`, `7f886ac`).
- `bash scripts/phase31-overlay-pill-assert.sh --section 1` passes with FAIL=0 FINDINGS=0.
