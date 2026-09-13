---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 07
subsystem: testing
tags: [bash, capture, fixtures, assertions, stride]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 05
    provides: "run_capture() wrapper subcommand implementation"
provides:
  - "scripts/phase18-capture-model-assert.sh — Sections 7b and 7c capture end-to-end fixture assertions"
affects: [18-10, 18-11, phase-21]

# Actuals
actuals:
  tokens: 11500
  tasks: 2
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Disposable git fixture repositories under temporary HOME directory outside repo"
    - "Multi-fixture trap cleanup discipline with zero leak into tracked repository"
    - "Negative-proof testing of dirty, untracked, missing, and symlink capture refusals"

key-files:
  modified:
    - scripts/phase18-capture-model-assert.sh

key-decisions:
  - "Fixture builds temporary git repo under mktemp -d outside repository, exercising capture with HOME re-pointed (D-44, D-45)"
  - "Tracked dirty mirror refused and uncommitted working-tree bytes preserved intact (D-36, D-37)"
  - "Untracked mirror refused with distinct reason, testing the two-part dirty check (RESEARCH F-8)"
  - "Missing live counterpart reported as [FINDING], moves exit code, and leaves repo copy intact (D-43)"
  - "Clean tracked mirror copied live content while git diff --cached remains empty (D-38)"
  - "Dry run preview verified to write nothing and leave fixture git status unchanged (D-42)"
  - "Empty capture/ tree exits 0 with explicit message on both fixture and real repository (D-41)"
  - "Live symlink resolving into repo mirror is refused rather than copied onto itself (D-39)"
  - "Scoped grep confirms run_capture contains no hardcoded /home/ and no bare ~ (D-45)"
  - "Accepted TOCTOU risk recorded as INFO"

requirements-completed: [CAP-05]

coverage:
  - id: D1
    description: "capture copies live to repo for clean tracked mirrors and leaves staged diff empty"
    requirement: "CAP-05"
    verification:
      - kind: integration
        ref: "Section 7b fixture clean mirror test; git diff --cached is empty"
        status: pass
      human_judgment: false
  - id: D2
    description: "capture refuses dirty, untracked, and absent mirrors with distinct reasons"
    requirement: "CAP-05"
    verification:
      - kind: integration
        ref: "Section 7b distinct error message matching and non-zero exit code assertion"
        status: pass
      human_judgment: false
  - id: D3
    description: "capture --dry-run previews copies without writing, and empty tree exits 0 with message"
    requirement: "CAP-05"
    verification:
      - kind: integration
        ref: "Section 7c dry-run bytes check and empty tree assertions"
        status: pass
      human_judgment: false
  - id: D4
    description: "capture refuses live symlinks into repo and adheres to $HOME portability"
    requirement: "CAP-05"
    verification:
      - kind: integration
        ref: "Section 7c symlink test and scoped grep on run_capture"
        status: pass
      human_judgment: false

# Metrics
duration: 10 min
completed: 2026-09-14
status: complete
---

# Phase 18 Plan 07: Capture Fixture Assertions (Sections 7b & 7c) Summary

**Added Sections 7b and 7c to `scripts/phase18-capture-model-assert.sh`, demonstrating end-to-end `capture` behavior against temporary repositories under `$HOME`: live-to-repo copy, empty staged diff, dry-run preview, empty-tree exit 0, and refusals for dirty, untracked, missing, and live symlink mirrors.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-14T01:18:16Z
- **Completed:** 2026-09-14T01:19:33Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added Section 7b to `scripts/phase18-capture-model-assert.sh`:
  - Built an isolated git fixture repository inside a temporary directory used as `$HOME` (D-44, D-45).
  - Clean & tracked mirror: copied live bytes over repo copy; verified `git diff --cached` is completely empty (D-38).
  - Tracked & dirty mirror: refused naming `repo mirror is dirty against HEAD`; verified working-tree modifications were preserved intact (D-36, D-37).
  - Untracked mirror: refused naming `repo mirror is untracked (no HEAD version to recover)`, proving the corrected two-part dirty check catches uncommitted work that `git diff --quiet HEAD` ignores (RESEARCH F-8).
  - Missing live counterpart: yielded `[FINDING]` naming `missing_live.conf`, preserved repo mirror file intact, and moved the exit code (D-43).
  - Verified overall run exits non-zero while clean captures in the same run succeed.
- Added Section 7c to `scripts/phase18-capture-model-assert.sh`:
  - Dry run preview (D-42): ran `capture --dry-run`; verified output announces would-copy without modifying bytes and without altering `git status`.
  - Empty tree (D-41): verified `capture` against both fixture empty tree and real repository empty tree exits 0 with explicit `[INFO] capture/ is empty, nothing to capture.` message.
  - Symlink refusal (D-39): created live path as a symbolic link pointing to its repo mirror; verified `capture` refuses with symlink reason rather than copying onto itself.
  - Portability check (D-45): verified with scoped `awk` grep that `run_capture()` in `arch/dots-hyprland.sh` contains no hardcoded `/home/` and no bare `~`.
  - Recorded accepted TOCTOU gap in `[INFO]`.
- All temporary fixtures registered in `cleanup()` trap; zero residue in tracked repository.

## Task Commits

1. **Task 1 & 2: Sections 7b and 7c capture assertions** — `609bee0` (test)

## Files Created/Modified

- `scripts/phase18-capture-model-assert.sh` — added Sections 7b and 7c, updated `cleanup()` trap and self-check loop.

## Decisions Made

- Ran the wrapper from the fixture repository root using subshell `(cd "$FIX_REPO" && HOME="$FIX_HOME" ./arch/dots-hyprland.sh capture)` to ensure both `REPO_ROOT` and working directory resolve to the fixture repository.
- Registered fixture directories in `cleanup()` so any interrupted run cleanly removes temporary directories from `/tmp`.

## Deviations from Plan

None.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 18-07 complete.
- Next is Plan 18-08 (Wave 6): `restow/starship` split, three new stow call sites, and the one authorized constant.

## Self-Check: PASSED

- Section 7b assertions — PASSED
- Section 7c assertions — PASSED
- `./arch/dots-hyprland.sh capture` — exit 0
- `./arch/dots-hyprland.sh capture --dry-run` — exit 0
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `capture/` holds only `README.md` — VERIFIED
- `git status --porcelain` — clean

---
*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Completed: 2026-09-14*
