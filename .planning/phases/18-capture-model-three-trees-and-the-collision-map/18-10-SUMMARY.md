---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 10
subsystem: config
tags: [stow, restow, collision-map, assert, placement]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 08
    provides: "restow/starship package and canonical call sites"
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 09
    provides: "clean repo-root .config removal and reader retargeting"
provides:
  - "scripts/gen-collision-map.sh --restow-table mode emitting stdout markdown table"
  - "restow/README.md machine-generated package recovery table"
  - "scripts/phase18-capture-model-assert.sh section 1f (tag check & table diff)"
  - "scripts/phase18-capture-model-assert.sh section 3d (placement check & mis-filed fixture refusal)"
  - "Phase 18 closing summary naming all 7 ROADMAP criteria and covering sections"
affects: [18-11]

# Actuals
actuals:
  tokens: 22000
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Generator-owned marked markdown region regenerated and diffed by assert"
    - "Placement check deriving tree from collision-map.tsv outcome columns"
    - "Self-cleaning fixture pattern: trap 'rm -rf ...; cleanup' EXIT with cleanup return 0"
    - "Unified phase verdict with 7-criteria summary"

key-files:
  created: []
  modified:
    - scripts/gen-collision-map.sh
    - restow/README.md
    - scripts/phase18-capture-model-assert.sh

key-decisions:
  - "Derive package recovery tag from outcome columns: symlink DESTROYED -> rsync-replace; repo OVERWRITTEN -> cp-through (D-09, D-12)"
  - "Emit restow table in LC_ALL=C sorted package order to stdout without in-place writing (D-59)"
  - "Assert restow table region against fresh generation from gen-collision-map.sh --restow-table (D-12, D-31)"
  - "Placement check derives tree from collision-map.tsv and checks real packages with 0 contradictions and mis-filed fixture with exactly 1 contradiction (D-56)"
  - "Fixture uses trap for robust cleanup on EXIT and verifies zero filesystem leak"

requirements-completed: [CAP-01, CAP-03]

coverage:
  - id: D1
    description: "Every restow/ package tagged and listed in restow/README.md table with exact recovery command"
    requirement: "CAP-01"
    verification:
      - kind: automated
        ref: "scripts/phase18-capture-model-assert.sh:186-228"
  - id: D2
    description: "Placement check reports zero contradictions on real trees and exits non-zero on mis-filed fixture"
    requirement: "CAP-03"
    verification:
      - kind: automated
        ref: "scripts/phase18-capture-model-assert.sh:395-502"
---

# Phase 18 Plan 10 Summary

**Completed the generated restow tag table in `restow/README.md`, added `--restow-table` mode to `scripts/gen-collision-map.sh`, and implemented Section 1f and Section 3d in `scripts/phase18-capture-model-assert.sh` covering tag validation, table diff, and placement contradiction detection with a self-cleaning mis-filed fixture.**

## Key Accomplishments

1. **Table Generation Mode (`scripts/gen-collision-map.sh --restow-table`)**:
   - Added `--restow-table` mode to `scripts/gen-collision-map.sh` that derives each package's recovery class (`rsync-replace` or `cp-through`) and exact recovery command directly from the collision map's outcome columns (D-09, D-12, D-13).
   - Emits markdown rows sorted by `LC_ALL=C` without modifying the generator's default stdout output (`collision-map.tsv` diff remains clean and byte-identical).

2. **Populated `restow/README.md` Generator Region**:
   - Inserted the machine-generated recovery table for all 4 `restow/` packages (`dolphinrc`, `hypr`, `kdeglobals`, `starship`) between `<!-- BEGIN generated: gen-collision-map.sh --restow-table -->` and `<!-- END generated: ... -->` comments.

3. **Assert Section 1f (Tag Validation & Table Regenerate-and-Diff)**:
   - Verifies all packages in `restow/` have valid non-empty tags (`rsync-replace` or `cp-through`).
   - Regenerates the table using `./scripts/gen-collision-map.sh --restow-table` and diffs against the committed region in `restow/README.md`.

4. **Assert Section 3d (Tree Placement & Mis-Filed Fixture Check)**:
   - Implemented `check_tree_placement()` function that prefix-matches package paths to `collision-map.tsv` rows and verifies package location against the derived `tree` column.
   - Asserted 0 contradictions across real packages in the repository.
   - Asserted exactly 1 contradiction when a throwaway fixture (`stow/p18-misfiled-fixture/.config/hypr/hyprland/fixture.conf`) is placed in `stow/` despite mapping to a destroying row (`$XDG_CONFIG_HOME/hypr/hyprland`).
   - Ensured robust cleanup using `trap 'rm -rf "$MISFILED_FIXTURE"; cleanup' EXIT` with explicit return 0 safety.

5. **Phase 18 Closing Summary (D-57)**:
   - Added a closing summary reporting all seven ROADMAP criteria and their covering sections (Sections 1 through 7) for a single unified verdict.

## Verification

- `bash -n scripts/gen-collision-map.sh`: OK
- `./scripts/gen-collision-map.sh | diff -u collision-map.tsv -`: Clean (exit 0)
- `./scripts/phase18-capture-model-assert.sh`: Clean (`FAIL=0 FINDINGS=0`)
- `git status --porcelain`: Clean
- Closed asserts (`phase13-d19-assert.sh`, `phase14-verify.sh`): All PASS
