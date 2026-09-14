---
phase: 21-ii-bar-config-capture
plan: 01
subsystem: capture
tags: [capture, quickshell, illogical-impulse, json, bash, testing]

requires:
  - phase: 20-hypr-custom-overlays-and-startup-restore
    provides: assert harness conventions, trap cleanup, and scratch isolation patterns
provides:
  - Core capture engine enhancements with JSON validation, atomic rename, and cmp -s change detection
  - CLI flags --quiet and --notify for ./arch/dots-hyprland.sh capture
  - Phase 21 assert test harness foundation (scripts/phase21-ii-bar-config-capture-assert.sh) with Sections 1 & 2
affects: [21-02, 21-03]

tech-stack:
  added: []
  patterns: [jq validation with non-zero size check, atomic temp-file replace, cmp -s change detection, desktop notification via notify-send, scratch fixture isolation]

key-files:
  created: [scripts/phase21-ii-bar-config-capture-assert.sh]
  modified: [arch/dots-hyprland.sh]

key-decisions:
  - "Enhanced run_capture with format-generic JSON validation (jq empty paired with [[ -s ]]) and atomic temp file replace (D-01, D-03, D-05)"
  - "Added cmp -s change detection to run_capture as a zero-cost early skip preventing unnecessary disk writes (D-02)"
  - "Added --quiet and --notify flags to capture CLI; quiet suppresses [PASS]/[INFO] lines without short-circuit return issues under set -e (D-12, D-13)"
  - "Proved in isolated scratch XDG drill that switchwall.sh:147 mv severs symlinks to plain files and capture synchronizes them (D-19)"

patterns-established:
  - "Fail-closed ingest validation: 0-byte or corrupted JSON is rejected without touching the repo mirror"
  - "Atomic mirror updates: files are written to tmp and atomically replaced via mv -f"

requirements-completed: [BAR-01]

coverage:
  - id: D1
    description: "BAR-01 Ingest validation, atomic copy, symlink refusal, and dirty repo mirror skip"
    requirement: "BAR-01"
    verification:
      - kind: unit
        ref: "./scripts/phase21-ii-bar-config-capture-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "BAR-01 Isolated fixture wallpaper switch symlink destruction and capture recovery drill"
    requirement: "BAR-01"
    verification:
      - kind: unit
        ref: "./scripts/phase21-ii-bar-config-capture-assert.sh --section 2"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-09-15
status: complete
---

# Phase 21 Plan 01: Capture Engine Ingest Validation & Assert Harness Foundation Summary

**Enhanced `run_capture` in `arch/dots-hyprland.sh` with fail-closed JSON validation, `cmp -s` change detection, atomic temp-file replacement, and `--quiet`/`--notify` flags, verified by Phase 21 assert harness Sections 1 and 2 in isolated scratch fixtures.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-15T05:33:00Z
- **Completed:** 2026-09-15T05:36:00Z
- **Tasks:** 2 completed
- **Files modified:** 2 files (1 created, 1 modified)

## Accomplishments

- Enhanced `arch/dots-hyprland.sh` `run_capture` with:
  - `--quiet` (suppressing `[PASS]` and `[INFO]` lines cleanly under `set -e`) and `--notify` (desktop notification via `notify-send` when updates are written).
  - Pre-copy change detection using `cmp -s -- "$live" "$repo_file"` to skip identical files as zero-cost no-ops.
  - Fail-closed JSON validation for `*.json` checking both non-zero file size (`[[ -s "$live" ]]`) and syntax correctness (`jq empty "$live"`), protecting the git tree against empty or corrupt files.
  - Atomic working tree updates via temporary file copy (`cp -p -- "$live" "$tmp_repo"`) and rename (`mv -f -- "$tmp_repo" "$repo_file"`).
  - Updated synopsis and usage documentation for `arch/dots-hyprland.sh capture [--dry-run] [--quiet] [--notify]`.
- Created executable `scripts/phase21-ii-bar-config-capture-assert.sh` complying with the dotfiles test harness contract (`set -euo pipefail`, four standard log prefixes, `FAIL`/`FINDINGS` counters, `--section <1-7>` CLI parser, and dynamic EXIT trap cleanup).
- Implemented Section 1 verifying all 6 ingest invariants in an isolated `/tmp` fixture:
  1. Valid JSON update captured into repo mirror.
  2. Unchanged file skipped via `cmp -s`.
  3. 0-byte file refused with non-zero exit code.
  4. Corrupt syntax refused with non-zero exit code.
  5. Live symlink resolving into repo refused.
  6. Dirty repo mirror skipped with `[FINDING]` without overwrite.
- Implemented Section 2 proving in an isolated scratch XDG drill that `switchwall.sh:147`'s `mv` command destroys symbolic links by replacing them with plain files, and that `run_capture` recovers and synchronizes the plain file into the repo mirror.

## Task Commits

Each task was committed atomically:

1. **Task 1 & 2: Enhance capture engine and scaffold assert harness sections 1 & 2** - `6bd3639` (feat)

## Files Created/Modified

- `arch/dots-hyprland.sh` - Enhanced `run_capture` and usage documentation with validation, atomic replace, change detection, and CLI flags.
- `scripts/phase21-ii-bar-config-capture-assert.sh` - Phase 21 test harness with trap cleanup, section routing, and Sections 1 & 2 assertions.

## Decisions Made

- Enforced `[[ ! -s "$live" ]] || ! jq empty "$live"` to handle jq's behavior of treating empty input as valid empty streams (D-03).
- Implemented logging helpers as explicit `if ((quiet == 0)); then ...; fi` blocks to prevent `&&` short-circuit non-zero exit code issues under `set -e` (D-13).
- Verified that `run_capture` contains no hardcoded `/home/` paths and no bare `~` expansions, ensuring absolute portability in isolated test fixtures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Wave 1 (Plan 21-01) is complete and verified green.
- Ready for Wave 2 (Plan 21-02): Author and stow systemd user capture units (`dotfiles-capture.service` and `dotfiles-capture.timer`), wire their enablement into `arch/hyprland.sh`, and implement assert Sections 4 and 5.

---
*Phase: 21-ii-bar-config-capture*
*Completed: 2026-09-15*
