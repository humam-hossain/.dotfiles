---
phase: 30-address-tech-debt-v0-5-cleanup-and-validation-sign-off
plan: "01"
subsystem: terminal-and-bootstrap
tags: [kitty, opacity, bootstrap, matugen, kde, signaling, virtualenv]

requires:
  - phase: 28-terminal-fuzzel-launcher-dynamic-palette
    provides: Kitty terminal dynamic Material You color palette and assert harness
  - phase: 29-theme-data-contracts-verification-bootstrap-integration
    provides: Bootstrap theming hooks and verify engine data contracts
provides:
  - Kitty background opacity aligned to 0.90 per Phase 28 UAT preference
  - Phase 28 terminal assert harness native probe aligned to 0.90
  - Live Kitty terminals signaled via killall -SIGUSR1
  - Bootstrap virtualenv fallback exported for headless executions
  - Idempotent template alignment hooks in bootstrap.sh
  - Live kde wrapper and applycolor signaling hardened
affects: [kitty, bootstrap, scripts]

actuals:
  tokens: 1250
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns: [killall-signal-dispatch, idempotent-sed-template-sanitization, parameter-expansion-virtualenv-fallback]

key-files:
  created: []
  modified:
    - restow/kitty/.config/kitty/kitty.conf
    - scripts/phase28-terminal-fuzzel-assert.sh
    - bootstrap.sh
    - /home/pera/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh
    - /home/pera/.config/quickshell/ii/scripts/colors/applycolor.sh

key-decisions:
  - "D-01: Updated Kitty background opacity from 0.85 to 0.90 in restow/kitty/.config/kitty/kitty.conf per Phase 28 UAT user preference."
  - "D-02: Harmonized native Kitty parser probe in scripts/phase28-terminal-fuzzel-assert.sh to assert 0.90 opacity within float tolerance."
  - "D-03: Signaled active Kitty windows via killall -SIGUSR1 kitty 2>/dev/null || true without dropping shell sessions."
  - "D-04: Confined visual theming adjustments strictly to Kitty opacity, leaving fonts, margins, and Fuzzel configuration unchanged."
  - "D-05: Exported ILLOGICAL_IMPULSE_VIRTUAL_ENV fallback in bootstrap.sh generate_initial_theme() before switchwall invocation."
  - "D-06: Hardened kde-material-you-colors-wrapper.sh virtualenv activation with parameter expansion fallback ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}."
  - "D-07: Replaced brittle pgrep/pidof checks in applycolor.sh with atomic killall -SIGUSR1 signaling."

patterns-established:
  - "killall -SIGUSR1 kitty 2>/dev/null || true: fail-soft terminal reload without process tree regex collisions"
  - "Idempotent template checks in bootstrap.sh: guarding stream editor substitutions against repeated execution churn"

requirements-completed: [DEBT-05, DEBT-06]

coverage:
  - id: D1
    description: "Update Kitty background opacity to 0.90 in restow and signal live windows"
    requirement: "DEBT-05"
    verification:
      - kind: unit
        ref: "scripts/phase28-terminal-fuzzel-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D2
    description: "Export virtualenv fallback in bootstrap.sh and harden live wrapper & signaling scripts"
    requirement: "DEBT-06"
    verification:
      - kind: unit
        ref: "bootstrap.sh verification grep checks"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-18
status: complete
---

# Phase 30 Plan 01 Summary

**Aligned Kitty terminal opacity to 0.90 per Phase 28 UAT preference, synchronized regression probe assertions, and hardened bootstrap and live signaling scripts.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-18T15:03:00Z
- **Completed:** 2026-09-18T15:05:30Z
- **Tasks:** 2 completed
- **Files modified:** 5

## Accomplishments

- Updated `restow/kitty/.config/kitty/kitty.conf` line 3 to `background_opacity 0.90`, fulfilling user preference documented in Phase 28 UAT.
- Aligned `scripts/phase28-terminal-fuzzel-assert.sh` native Kitty probe to expect 0.90 opacity with tolerance, verifying section 3 passes cleanly with zero regressions.
- Reloaded live running Kitty windows dynamically via `killall -SIGUSR1 kitty 2>/dev/null || true`.
- Hardened `bootstrap.sh`'s `generate_initial_theme()` to export `ILLOGICAL_IMPULSE_VIRTUAL_ENV` fallback and idempotently patch template scripts.
- Patched live `kde-material-you-colors-wrapper.sh` to use `${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}` and `applycolor.sh` to use atomic `killall -SIGUSR1`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Kitty opacity to 0.90 in restow, align phase28 assert, and reload live terminals** - `2d761cf` (feat)
2. **Task 2: Harden bootstrap.sh, applycolor.sh, and kde-material-you-colors-wrapper.sh environment fallback and signaling** - `d83cc26` (feat)

**Plan metadata:** committed in plan closeout.

## Self-Check: PASSED

- All acceptance criteria satisfied.
- Verified section 3 of `scripts/phase28-terminal-fuzzel-assert.sh` passes (FAIL=0 FINDINGS=0).
- Git status confirms all changes are committed cleanly.
