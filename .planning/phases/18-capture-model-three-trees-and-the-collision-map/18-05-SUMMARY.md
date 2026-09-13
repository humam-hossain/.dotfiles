---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 05
subsystem: infra
tags: [bash, wrapper, verify, capture, allowlist, assertions]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 03
    provides: "--exp-files refusal gate and assert section 4"
provides:
  - "arch/dots-hyprland.sh — run_verify() and run_capture() wrapper-owned subcommands"
  - "arch/dots-hyprland.sh — ALLOWLIST entries and main() dispatch arms"
  - "scripts/phase18-capture-model-assert.sh — Section 7a proving dispatch and de-initialised submodule survival"
affects: [18-06, 18-07, 18-11, phase-19, phase-21]

# Actuals
actuals:
  tokens: 12000
  tasks: 3
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wrapper-owned subcommands with dedicated dispatch arms that bypass preflight and vendor setup"
    - "Four-prefix [PASS]/[FAIL]/[FINDING]/[INFO] assert vocabulary with custom exit code criteria"
    - "Link-ness asserted before content comparison across three capture trees"
    - "Two-part dirty test: git ls-files --error-unmatch then git diff --quiet HEAD"
    - "Canonical main worktree resolution via git rev-parse --git-common-dir"

key-files:
  modified:
    - arch/dots-hyprland.sh
    - scripts/phase18-capture-model-assert.sh

key-decisions:
  - "Operator confirmed 'wrapper-owned' at checkpoint: verify and capture are allowlisted wrapper subcommands"
  - "Neither run_verify nor run_capture calls preflight, operating only on the repo's own trees and live filesystem (D-47)"
  - "ALLOWLIST additions and main() dispatch arms landed in the same commit to prevent routing into run_install_family (D-48, D-61)"
  - "run_verify asserts link-ness (test -L and readlink -f) before any content comparison (D-46)"
  - "Repo side of comparisons is resolved against parent of git rev-parse --path-format=absolute --git-common-dir to support worktrees"
  - "Inverted expectation for capture/ in verify: symlink into repo is a [FAIL], content drift is a [FINDING] (D-50)"
  - "run_capture refuses dirty, untracked, and absent repo mirrors via two-part test (D-37, RESEARCH F-8)"
  - "run_capture findings move the exit code (D-43, D-49 divergence noted in function header)"
  - "Empty capture/ tree exits 0 with explicit message (D-41)"

requirements-completed: [FIX-05, CAP-05]

coverage:
  - id: D1
    description: "verify and capture registered in ALLOWLIST and dispatched by main as wrapper-owned subcommands"
    requirement: "FIX-05"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify & capture dispatch without reaching ./setup"
        status: pass
      human_judgment: false
  - id: D2
    description: "run_verify runs to a real exit code with vendor/dots-hyprland de-initialised"
    requirement: "FIX-05"
    verification:
      - kind: integration
        ref: "Assert Section 7a temporarily moves vendor/dots-hyprland/.git aside and verifies real exit code"
        status: pass
      human_judgment: false
  - id: D3
    description: "run_capture copies live to repo for capture/ paths only, never stages or commits, and refuses dirty/untracked mirrors"
    requirement: "CAP-05"
    verification:
      - kind: integration
        ref: "Two-part dirty test implemented; empty tree exits 0 with message; full fixture tested in 18-07"
        status: pass
      human_judgment: false

# Metrics
duration: 10 min
completed: 2026-09-14
status: complete
---

# Phase 18 Plan 05: Wrapper Subcommands `verify` and `capture` Summary

**Implemented `run_verify()` and `run_capture()` as wrapper-owned subcommands in `arch/dots-hyprland.sh`, registered them in `ALLOWLIST` with dedicated `main()` dispatch arms that never reach `preflight` or upstream setup, and proved dispatch and de-initialised submodule survival in `scripts/phase18-capture-model-assert.sh` Section 7a.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-14T01:12:00Z
- **Completed:** 2026-09-14T01:16:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Confirmed the operator decision checkpoint ("wrapper-owned") preserving single-entrypoint operator discipline.
- Added `get_main_repo_root()` helper resolving the canonical main worktree as the parent of `git rev-parse --path-format=absolute --git-common-dir`, ensuring live link comparisons remain accurate even when invoked from linked git worktrees.
- Implemented `run_verify()`:
  - Takes no arguments and walks all three trees (`stow/`, `restow/`, `capture/`).
  - Walks the repo side only, avoiding untracked live sidecars (RESEARCH P-8).
  - Asserts link-ness (`test -L` and `readlink -f`) before content comparison (D-46).
  - Reports missing live links with the exact recovery stow command (D-54).
  - Inverts expectation for `capture/` paths: live symlink into repo is a `[FAIL]`, while content drift is a `[FINDING]` (D-50).
  - Does not call `preflight` and reads nothing under `vendor/` (D-47).
- Implemented `run_capture()`:
  - Accepts only `--dry-run` and `-h|--help`, rejecting unknown flags.
  - Exits 0 with explicit `[INFO] capture/ is empty, nothing to capture.` when `capture/` holds no packages (D-41).
  - Implemented the corrected two-part capturability test (`git ls-files --error-unmatch` followed by `git diff --quiet HEAD`) to refuse absent, untracked, and dirty repo mirrors (D-37, RESEARCH F-8).
  - Confines destination writes to `capture/` via `realpath -m` resolved comparisons (D-39).
  - Refuses live paths that are symlinks resolving into the repo (D-39).
  - Copies live files to repo mirrors without staging (`git add`) or committing (D-38).
  - Documented the D-43 divergence in the function header: findings move the exit code (`fail_count > 0 || finding_count > 0` exits 1).
- Registered `verify` and `capture` in `ALLOWLIST` and added dedicated dispatch arms in `main()` before the catch-all, ensuring neither subcommand ever reaches upstream `./setup` (D-48, D-61).
- Added Section 7a to `scripts/phase18-capture-model-assert.sh`:
  - 7a-1: Behavioural check that allowlist refusal output contains both `verify` and `capture`.
  - 7a-2: Verifies `./arch/dots-hyprland.sh verify` dispatches to wrapper handler without naming upstream `./setup`.
  - 7a-3: Verifies `./arch/dots-hyprland.sh capture` exits 0 with explicit empty-tree message.
  - 7a-4: Verifies `verify` runs to a real exit code with `vendor/dots-hyprland/.git` moved aside, restored via `trap cleanup EXIT`.

## Task Commits

1. **Task 1 & 2: Wrapper subcommands and Section 7a assert** — `dfd1df3` (feat)

## Files Created/Modified

- `arch/dots-hyprland.sh` — added `get_main_repo_root()`, `run_verify()`, `run_capture()`, `ALLOWLIST` entries, `usage()` update, and `main()` dispatch arms.
- `scripts/phase18-capture-model-assert.sh` — added `cleanup()` trap and Section 7a assertions.

## Decisions Made

- Placed comments explaining `preflight` omission above function definitions to preserve zero occurrences inside the awk function-body ranges (`/^run_verify\(\)/,/^}$/` and `/^run_capture\(\)/,/^}$/`).
- Landed ALLOWLIST updates and dispatch arms in the exact same commit as the handlers to prevent intermediate states routing to `run_install_family`.

## Deviations from Plan

None.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 18-05 complete.
- Next is Plan 18-06 (Wave 4): Hypr configuration split across `stow/hypr/` and `restow/hypr/`.

## Self-Check: PASSED

- `arch/dots-hyprland.sh` — syntax valid, handlers defined, zero preflight calls in bodies
- `./arch/dots-hyprland.sh capture` — exit 0, empty-tree message
- `./arch/dots-hyprland.sh verify` — exits cleanly without calling `./setup`
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `test -e vendor/dots-hyprland/.git` — verified
- `git status --porcelain` — clean

---
*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Completed: 2026-09-14*
