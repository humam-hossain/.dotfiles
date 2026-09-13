---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 02
subsystem: infra
tags: [bash, stow, restow, capture, archive, contracts, assert]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 01
    provides: "collision-map.tsv and scripts/phase18-capture-model-assert.sh sections 2 and 3"
provides:
  - "stow/README.md — contract, recovery, membership predicate, --adopt ban and replacement procedure"
  - "restow/README.md — contract, recovery per tag, membership predicate, naming notes, table placeholder"
  - "capture/README.md — contract, recovery/refresh, hand-assigned prose rule, keeps directory alive in git"
  - "docs/archive/README.md — archive contract and registry"
  - "scripts/phase18-capture-model-assert.sh — sections 1 and 5"
affects: [18-03, 18-04, 18-05, 18-06, 18-07, 18-08, 18-09, 18-10, 18-11, 19-link-aware-verify]

# Actuals
actuals:
  tokens: 9500
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tree-level READMEs establish capture contracts answerable from file location alone"
    - "Vacuity-guarded ban grep over arch/ and scripts/ excludes assert by name"

key-files:
  created:
    - stow/README.md
    - restow/README.md
    - capture/README.md
    - docs/archive/README.md
  modified:
    - scripts/phase18-capture-model-assert.sh

key-decisions:
  - "stow/ and restow/ membership predicates match collision-map.tsv two-value derived outcomes"
  - "capture/ membership is hand-assigned prose; capture/ is legitimately empty in Phase 18 and tracked via README.md with no .gitkeep"
  - "stow --adopt is strictly banned across arch/ and scripts/ with an interactive-only clean-tree single-path exception, replaced by the simulate-and-aside procedure"
  - "docs/archive/ created as flat retirement directory with prefix-based collision resolution"

patterns-established:
  - "Vacuity guard before ban-grep asserts target directories exist and contain files"
  - "Assert excludes itself by name when checking for forbidden flags"

requirements-completed: [CAP-01, CAP-07]

coverage:
  - id: D1
    description: "stow/, restow/ and capture/ each exist and each holds a README.md stating contract, recovery, and membership"
    requirement: "CAP-01"
    verification:
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 1 (1a..1e)"
        status: pass
    human_judgment: false
  - id: D2
    description: "stow --adopt is banned across arch/ and scripts/, and documented with its three-part exception and replacement procedure"
    requirement: "CAP-07"
    verification:
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 5 (5 guard, 5a, 5b)"
        status: pass
    human_judgment: false
  - id: D3
    description: "docs/archive/ exists with a README stating that nothing in it is live and nothing reads it"
    verification:
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 1e"
        status: pass
    human_judgment: false

# Metrics
duration: 8 min
completed: 2026-09-14
status: complete
---

# Phase 18 Plan 02: Three Trees and Contracts Summary

**Established `stow/`, `restow/`, `capture/`, and `docs/archive/` directories with comprehensive contract READMEs, instituted the `stow --adopt` ban with safe replacement procedures, and added assert sections 1 and 5 to `scripts/phase18-capture-model-assert.sh`.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-14T01:03:50Z
- **Completed:** 2026-09-14T01:05:25Z
- **Tasks:** 3
- **Files modified:** 5 (4 created, 1 modified)

## Accomplishments

- Created `stow/README.md` defining the installer-never-collides contract, re-linking via `stow --verbose=5 --no-folding -t ~ <pkg>`, prefix membership rules, the `install_dir__ignore_existing` directory-level short-circuit quirk, the `stow --adopt` ban, and the step-by-step simulate-and-aside replacement procedure.
- Created `restow/README.md` defining the installer-overwrites contract, `rsync-replace` and `cp-through` outcome tags with recovery commands, package naming notes (e.g. `hypr` dual-tree split and `starship`), and the machine-generated table region delimited by `BEGIN/END` markers for plan 18-10.
- Created `capture/README.md` defining the copy-based capture model for atomic renamers, refresh commands via wrapper `capture` and `--dry-run`, hand-assigned prose membership (not derived from the collision map), and documenting its initial empty-tree status without requiring `.gitkeep`.
- Created `docs/archive/README.md` defining the retirement contract (nothing live, nothing reads it, provenance tracked) with an initial empty registry and prefix-based collision rule.
- Extended `scripts/phase18-capture-model-assert.sh` with Section 1 (CAP-01) and Section 5 (CAP-07). All assertions pass cleanly with `FAIL=0 FINDINGS=0`.

## Task Commits

1. **Task 1: The three trees and their contracts** — `a8f3760` (feat)
2. **Task 2: docs/archive/ and its contract** — `b39f83c` (docs)
3. **Task 3: Assert sections 1 and 5 — the trees exist and the flag is absent** — `fdd0f0f` (feat)

## Files Created/Modified

- `stow/README.md` — contract, recovery, membership, upstream quirk, adopt ban & safe procedure.
- `restow/README.md` — contract, recovery tags, table placeholder, naming notes.
- `capture/README.md` — copy model, refresh command, hand-assigned rule, empty-tree status.
- `docs/archive/README.md` — retirement contract, collision rule, registry.
- `scripts/phase18-capture-model-assert.sh` — sections 1 and 5 added.

## Decisions Made

- Standardized `--verbose=5 --no-folding` across all trees and documentation.
- Documented the exact three-part exception to the `stow --adopt` ban: interactive use only, on a clean tree, one path at a time.
- Emitted `[INFO]` in assert section 1 noting that the `restow/` package tag table check arrives with plan 18-10.

## Deviations from Plan

None. Executed exactly as specified in `18-02-PLAN.md`.

## Issues Encountered

- In assert section 1d, grep for the two-tree acknowledgment initially failed on `restow/README.md` due to case-sensitivity ("Only two" vs "only two"). Fixed by adding case-insensitive flag `-i` to grep.

## Known Stubs

None. All contracts, documentation, and asserts are complete and active.

## User Setup Required

None.

## Next Phase Readiness

- The three trees (`stow/`, `restow/`, `capture/`) and `docs/archive/` exist with contracts defined.
- Wave 2 is complete. Ready for Wave 3 (`18-03-PLAN.md` and `18-04-PLAN.md`).

## Self-Check: PASSED

- `stow/README.md` — FOUND
- `restow/README.md` — FOUND
- `capture/README.md` — FOUND
- `docs/archive/README.md` — FOUND
- `scripts/phase18-capture-model-assert.sh` — FOUND
- Commit `a8f3760` — FOUND
- Commit `b39f83c` — FOUND
- Commit `fdd0f0f` — FOUND
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `git status --porcelain` — clean

---
*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Completed: 2026-09-14*
