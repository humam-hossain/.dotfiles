---
phase: 12-wrapper-full-profile
plan: 01
subsystem: wrapper
tags: [FULL-01, FULL-02, FULL-04, SAFE_DEFAULTS, --full, dry-run]

requires:
  - phase: 11-disposition-decisions
    provides: DISP-02 drop-all-three residual contract for first full-adopt
provides:
  - Wrapper-owned --full meta-flag strip in run_install_family
  - Conditional SAFE_DEFAULTS injection (skip all three when full==1)
  - D-02 scope refuse for --full on non install/install-files
  - Dry-run argv proof: full omits residuals; default still injects triple
affects: [12-02, 12-03, 12-04, phase-14, phase-15]

actuals:
  tokens: 803
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Meta-flag strip for --full (same pattern as --dry-run / --allow-skip-backup)"
    - "needs_safe_defaults && full==0 gates SAFE_DEFAULTS injection"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh

key-decisions:
  - "D-01: --full is wrapper-owned meta, never forwarded to ./setup"
  - "D-02: --full refused on install-deps/install-setups with [FAIL]"
  - "D-03: full path injects nothing from SAFE_DEFAULTS"
  - "D-05: default path still injects --core --skip-hyprland --skip-sysupdate"

patterns-established:
  - "full=0 local + --full) case arm in run_install_family strip loop"
  - "backup_gate receives full so safe residual prose is not printed on full path"

requirements-completed: [FULL-01, FULL-02, FULL-04]

coverage:
  - id: D1
    description: install --full --dry-run would-exec omits all three SAFE_DEFAULTS residuals and strips --full
    requirement: FULL-01
    verification:
      - kind: other
        ref: "printf 'yes\\n' | ./arch/dots-hyprland.sh install --full --dry-run"
        status: pass
    human_judgment: false
  - id: D2
    description: Default install --dry-run still injects SAFE_DEFAULTS triple residual
    requirement: FULL-02
    verification:
      - kind: other
        ref: "printf 'yes\\n' | ./arch/dots-hyprland.sh install --dry-run"
        status: pass
    human_judgment: false
  - id: D3
    description: install-files --full/--dry-run parity + install-deps --full refuse
    requirement: FULL-04
    verification:
      - kind: other
        ref: "install-files --full --dry-run residual absence; install-deps --full non-zero"
        status: pass
    human_judgment: false

duration: inline
completed: 2026-08-10
status: complete
---

# Phase 12: Plan 01 Summary

**Wrapper-owned `--full` meta-flag strips before `./setup` and skips all three SAFE_DEFAULTS residuals on install/install-files dry-run, while bare install still injects the safe triple.**

## Performance

- **Tasks:** 2/2
- **Commits:** `b694052` (feat); this SUMMARY commit
- **Files modified:** 1 (`arch/dots-hyprland.sh`)

## Accomplishments

- Added `local full=0` and `--full)` strip arm in `run_install_family` (D-01); meta never reaches `cmd` / would-exec
- D-02 refuse: `install-deps --full --dry-run` exits non-zero with `[FAIL]`
- Conditional injection: `needs_safe_defaults && full==0` prepends SAFE_DEFAULTS; full path logs no-injection and builds bare `./setup install`
- FULL-02 negative control: bare `install --dry-run` and `install-files --dry-run` still show `--core`, `--skip-hyprland`, `--skip-sysupdate`
- `install-files --full --dry-run` matches install full residual-omission contract
- Minimal `backup_gate "$full"` branch so full dry-run output does not claim skip-hyprland protection (Pitfall 5); full D-07 messaging deferred to 12-02

## Task Commits

| Task | Commit | Notes |
|------|--------|-------|
| 12-01-01 End-to-end --full argv | `b694052` | strip + D-02 refuse + conditional injection + gate full arg |
| 12-01-02 FULL-02 residual control | `b694052` | verify-only; no extra code beyond Task 1 shared path |

## Files Created/Modified

- `arch/dots-hyprland.sh` — `--full` meta strip, scope refuse, conditional SAFE_DEFAULTS, full-aware gate call

## Decisions Made

- Followed plan/patterns: no new subcommand; SAFE_DEFAULTS array literal unchanged
- Minimal full gate line (no residual tokens) to satisfy FULL-01 whole-output greps without implementing full D-07 copy yet

## Deviations from Plan

### Auto-fixed Issues

**1. Gate prose leaked residual tokens into full dry-run output**
- **Found during:** Task 1 verify (`! grep --skip-hyprland` on whole output)
- **Issue:** Safe-path `backup_gate` line `Defaults include --skip-hyprland…` ran on full dry-run and failed FULL-01 automated greps even though would-exec argv was clean
- **Fix:** Pass `full` into `backup_gate`; only print residual-protection note when `full==0`; full path gets a token-free placeholder line
- **Rationale:** Plan said gate messaging is 12-02, but Task 1 automated verify greps the entire stream; minimal branch unblocks tracer without full D-07 blast-radius copy

## Self-Check: PASSED

Re-ran after production commit `b694052`:

| Check | Result |
|-------|--------|
| `bash -n arch/dots-hyprland.sh` | PASS |
| `install --full --dry-run` exit 0 + `would exec` | PASS |
| full output omits `--skip-hyprland`, `--skip-sysupdate`, standalone `--core`, `--full` | PASS |
| `install-deps --full --dry-run` non-zero + `[FAIL]` | PASS |
| bare `install --dry-run` has all three residuals | PASS |
| bare `install-files --dry-run` has `--skip-hyprland` | PASS |
| `install-files --full --dry-run` omits all three residuals | PASS |
| `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` literal | PASS |
| `git log --grep=feat(12-01)` includes `b694052` | PASS |
| key-file `arch/dots-hyprland.sh` exists | PASS |
