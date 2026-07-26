---
phase: 06-thin-setup-wrapper-safe-defaults
plan: 01
subsystem: infra
tags: [bash, wrapper, setup, allowlist, dry-run, preflight, dots-hyprland]

requires:
  - phase: 05-fork-submodule-pin
    provides: vendor/dots-hyprland pin with executable setup and .git submodule
provides:
  - arch/dots-hyprland.sh thin WRAP-01 entrypoint scaffold
  - four-subcommand allowlist + wrapper help
  - preflight (.git + setup +x) without auto submodule init
  - wrapper-owned --dry-run / --allow-skip-backup strip
  - array-exec path to vendor/dots-hyprland/./setup
affects:
  - 06-02 (safe defaults injection + backup gate)
  - 06-03 (full WRAP smoke)
  - Phase 7 live install via wrapper

tech-stack:
  added: []
  patterns:
    - "Thin arch wrapper: REPO_ROOT + ALLOWLIST + preflight + array-exec of vendor ./setup"
    - "Wrapper-owned meta flags stripped before setup getopt"
    - "Non-mutating smoke via --dry-run (no live install in Phase 6)"

key-files:
  created:
    - arch/dots-hyprland.sh
  modified: []

key-decisions:
  - "SAFE_DEFAULTS constant defined now; injection deferred to 06-02"
  - "--allow-skip-backup stripped and stored for 06-02 policy; not forwarded"
  - "Dry-run logs [INSTALL] argv and [CONFIG] would-exec then exits 0"

patterns-established:
  - "arch/dots-hyprland.sh structured main dispatcher (quickshell-like, no PACKAGES)"
  - "Fail-closed preflight prints stock git fix only (D-15)"

requirements-completed: [WRAP-01]

coverage:
  - id: D1
    description: "Executable arch/dots-hyprland.sh with bash -n clean syntax"
    requirement: WRAP-01
    verification:
      - kind: other
        ref: "test -x arch/dots-hyprland.sh && bash -n arch/dots-hyprland.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Bare/help|-h|--help print wrapper help and exit 0 without calling ./setup"
    requirement: WRAP-01
    verification:
      - kind: other
        ref: "./arch/dots-hyprland.sh >/tmp/w6-01-help.txt; grep install-deps|install-setups|install-files"
        status: pass
    human_judgment: false
  - id: D3
    description: "Allowlist refuses uninstall/exp-merge with pointer to vendor/./setup"
    requirement: WRAP-01
    verification:
      - kind: other
        ref: "./arch/dots-hyprland.sh uninstall; ./arch/dots-hyprland.sh exp-merge --dry-run (both non-zero)"
        status: pass
    human_judgment: false
  - id: D4
    description: "install-deps --dry-run prints ./setup install-deps argv without machine mutation; meta flags stripped"
    requirement: WRAP-01
    verification:
      - kind: other
        ref: "./arch/dots-hyprland.sh install-deps --dry-run | grep setup|install-deps; ! grep --allow-skip-backup"
        status: pass
    human_judgment: false
  - id: D5
    description: "preflight checks .git + setup +x; array-exec only (no eval)"
    requirement: WRAP-01
    verification:
      - kind: other
        ref: "static: preflight() + cmd=(./setup) + \"${cmd[@]}\" under cd II_ROOT"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-07-26
status: complete
---

# Phase 6 Plan 01: Thin Setup Wrapper Scaffold Summary

**Executable `arch/dots-hyprland.sh` WRAP-01 entrypoint: four-subcommand allowlist, preflight, dry-run strip, array-exec of vendored `./setup`**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-26T05:00:57Z
- **Completed:** 2026-07-26T05:02:48Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Created executable `arch/dots-hyprland.sh` mirroring structured `arch/quickshell.sh` style (no package arrays)
- Bare invocation and `help`/`-h`/`--help` print wrapper help documenting allowlist, future safe defaults, and backup gate
- Only `install|install-deps|install-setups|install-files` accepted; refuse `uninstall`/`exp-merge` with pointer to `vendor/dots-hyprland/./setup`
- Preflight requires submodule `.git` and executable `setup`; prints stock fix only (never auto-init)
- `--dry-run` and `--allow-skip-backup` stripped as wrapper meta; dry-run logs would-exec argv and exits 0
- Array-exec path ready for live use: `( cd "$II_ROOT" && "${cmd[@]}" )`

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold arch/dots-hyprland.sh (REPO_ROOT, help, allowlist)** - `73ddb8d` (feat)
2. **Task 2: Preflight, meta --dry-run strip, array exec of ./setup** - `4e0585f` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `arch/dots-hyprland.sh` — Thin WRAP-01 wrapper: constants, usage, allowlist, preflight, meta-flag scan, dry-run, array-exec of `vendor/dots-hyprland/./setup`

## Decisions Made

- Defined `SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)` now for 06-02 wiring; not injected in this plan
- Stored `allow_skip_backup` after strip for future D-12 policy; skip-backup refuse and backup_gate deferred to 06-02
- Dry-run emits both `[INSTALL]` full argv line and `[CONFIG] dry-run: would exec…` for clear smoke logs

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **06-02**: SAFE_DEFAULTS injection for `install`/`install-files`, hard backup gate, `--skip-backup` refuse unless `--allow-skip-backup`
- Ready for **06-03**: full WRAP-01..04 dry/help smoke suite
- Do not live-run mutating install until Phase 7

## Self-Check: PASSED

- FOUND: `arch/dots-hyprland.sh`
- FOUND: commit `73ddb8d`
- FOUND: commit `4e0585f`
- Automated verifies from plan Tasks 1–2: green
- No stub markers; no `backup_gate` (correct scope); no SAFE_DEFAULTS injection yet (correct scope)

---
*Phase: 06-thin-setup-wrapper-safe-defaults*
*Completed: 2026-07-26*
