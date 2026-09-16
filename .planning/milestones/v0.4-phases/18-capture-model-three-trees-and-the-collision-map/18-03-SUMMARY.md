---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 03
subsystem: infra
tags: [bash, flags, wrapper, refusal, assert, pitfalls]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 02
    provides: "stow/, restow/, capture/ contracts and assert sections 1 and 5"
provides:
  - "arch/dots-hyprland.sh — main() refusal gate for --exp-files with exit 2 naming collision-map.tsv"
  - "scripts/phase18-capture-model-assert.sh — section 4 covering exit code, stderr output, position, '='-spelling, and substring safety"
  - ".planning/research/PITFALLS.md — Q15 experimental primitives section and split install_dir row"
affects: [18-05, 18-11]

# Actuals
actuals:
  tokens: 9000
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "main() prologue gate checks arguments before allowlist dispatch to protect all subcommands"
    - "Behavioral assert verifies real exit code, stderr message, and absence of upstream invocation"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh
    - scripts/phase18-capture-model-assert.sh
    - .planning/research/PITFALLS.md

key-decisions:
  - "--exp-files refused in main() before allowlist check, exiting 2 with message naming collision-map.tsv (D-30..D-33)"
  - "Only --exp-files refused; fontset, via-nix, core and skip flags continue to route normally with fontset accepted as coverage gap (D-32)"
  - "PITFALLS.md conflated install_dir row split into bare install_dir (rsync-replace) and install_dir__ignore_existing (stow)"

patterns-established:
  - "Multi-line [FAIL] refusal naming specific files and architectural reason"
  - "Dry-run flag pairing in behavioural asserts to safeguard against gate regressions"

requirements-completed: [CAP-08]
requirements_completed: [CAP-08]

coverage:
  - id: D1
    description: "arch/dots-hyprland.sh rejects --exp-files with exit 2 and names collision-map.tsv"
    requirement: "CAP-08"
    verification:
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 4 (4a..4d)"
        status: pass
    human_judgment: false
  - id: D2
    description: "PITFALLS.md documents experimental primitive set as deliberately unmodelled and splits the conflated install_dir row"
    verification:
      - kind: integration
        ref: "git diff HEAD~1 -- .planning/research/PITFALLS.md"
        status: pass
    human_judgment: false

# Metrics
duration: 7 min
completed: 2026-09-14
status: complete
---

# Phase 18 Plan 03: Refuse Experimental Files Flag Summary

**Added a strict prologue refusal gate in `arch/dots-hyprland.sh` for `--exp-files` exiting 2 and naming `collision-map.tsv`, implemented comprehensive behavioural assert coverage in section 4 of `scripts/phase18-capture-model-assert.sh`, and documented the experimental primitive set and corrected the `install_dir` row in `PITFALLS.md`.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-14T01:05:45Z
- **Completed:** 2026-09-14T01:06:55Z
- **Tasks:** 3
- **Files modified:** 3 (0 created, 3 modified)

## Accomplishments

- Inserted a refusal gate in `main()` in `arch/dots-hyprland.sh` after the help arm and before allowlist checking. Any invocation containing `--exp-files` or `--exp-files=*` immediately prints a descriptive error to stderr naming `3.files-exp.sh`, `3.files-exp.yaml`, and `collision-map.tsv`, and terminates with exit status 2 without invoking `./setup`.
- Added Section 4 to `scripts/phase18-capture-model-assert.sh` proving:
  - Real execution exits 2, prints `collision-map.tsv`, and never outputs `./setup`.
  - Position independence: flag after other arguments is caught identically.
  - `=`-suffixed argument `--exp-files=...` is caught.
  - Substrings like `--exp-files-not` do not trigger the gate and proceed to allowlist checking.
  - `[INFO]` emitted for accepted coverage gap D-32.
- Updated `.planning/research/PITFALLS.md`:
  - Split conflated `install_dir` row into bare `install_dir` (`rsync_dir`, DESTROYED/rsync-replace) and `install_dir__ignore_existing` (no-op/stow).
  - Added subsection `D-1a` detailing the seven experimental primitives, YAML destination routing, and conclusion that the experimental path voids the collision map.

## Task Commits

1. **Task 1: Refuse the experimental files flag in main()'s prologue** — `64f9d67` (feat)
2. **Task 2: Assert section 4 — prove the gate fires, not that its text exists** — `1ecb8d2` (feat)
3. **Task 3: Write Q15 finding into research record and split primitive row** — `17a72e7` (docs)

## Files Created/Modified

- `arch/dots-hyprland.sh` — added `--exp-files` refusal loop in `main()`.
- `scripts/phase18-capture-model-assert.sh` — added Section 4 (CAP-08).
- `.planning/research/PITFALLS.md` — split `install_dir` row and added `D-1a`.

## Decisions Made

- Placed gate in `main()` before allowlist to ensure all subcommands (including uninstall and future subcommands) are covered uniformly.
- Exit code 2 chosen deliberately to differentiate usage rejection from general runtime error (1).

## Deviations from Plan

None.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 18-03 complete. Ready for Plan 18-04 (`docs/config-redistribution.md`, archiving `hyprland.conf`, and moving dolphinrc/kdeglobals into `restow/`).

## Self-Check: PASSED

- `arch/dots-hyprland.sh` — gate present
- `scripts/phase18-capture-model-assert.sh` — Section 4 present
- `.planning/research/PITFALLS.md` — D-1a and split rows present
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `git status --porcelain` — clean

---
*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Completed: 2026-09-14*
