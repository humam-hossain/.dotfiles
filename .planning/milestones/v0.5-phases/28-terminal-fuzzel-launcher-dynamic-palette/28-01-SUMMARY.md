---
phase: 28-terminal-fuzzel-launcher-dynamic-palette
plan: 28-01
subsystem: ui
tags: [terminal, kitty, fuzzel, wayland, matugen, material-you, stow]

requires:
  - phase: 27-hyprland-quickshell-ii-accent-coordination
    provides: Matugen template pipeline, guard-paths.tsv conventions, and fail-closed assert harness patterns
provides:
  - Phase 28 assert harness scripts/phase28-terminal-fuzzel-assert.sh with Section 1 passing
  - Stow package stow/fuzzel/.config/fuzzel/fuzzel.ini deployed to ~/.config/fuzzel/
  - Upgraded stow/kitty/.config/kitty/kitty.conf with theme include, opacity 0.85, and shell zsh
  - Claimed helper kittens search.py and scroll_mark.py stowed under stow/kitty/
affects: [terminal, fuzzel, matugen, quickshell]

actuals:
  tokens: 14200
  tasks: 2
  commits: 2

tech-stack:
  added: [fuzzel, kitty]
  patterns: [fail-closed assert harness, safe stow deployment without --adopt, dynamic palette inclusion]

key-files:
  created:
    - scripts/phase28-terminal-fuzzel-assert.sh
    - stow/fuzzel/.config/fuzzel/fuzzel.ini
    - stow/kitty/.config/kitty/search.py
    - stow/kitty/.config/kitty/scroll_mark.py
  modified:
    - stow/kitty/.config/kitty/kitty.conf

key-decisions:
  - "Preserved user login shell 'shell zsh' instead of upstream fish per D-02"
  - "Preserved personal cursor trail settings in kitty.conf (trail 3, decay 0.1 0.4, threshold 2) per D-08"
  - "Unlinked regular host files prior to stow invocation without using --adopt per CAP-07"
  - "Allowed single- and double-quote parsing for output_path in matugen config.toml in Section 1"

patterns-established:
  - "Single-instance Kitty runner terminal=kitty -1 in fuzzel.ini per D-15"
  - "Zero-unclaimed-stub hygiene: both search.py and scroll_mark.py claimed into stow/kitty package"

requirements-completed: [INTG-01, TERM-01, TERM-02]

coverage:
  - id: D1
    description: "Fail-closed assertion harness scripts/phase28-terminal-fuzzel-assert.sh scaffolding"
    requirement: "INTG-01"
    verification:
      - kind: unit
        ref: "scripts/phase28-terminal-fuzzel-assert.sh --help"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fuzzel package deployment with dynamic theme include and kitty -1 terminal"
    requirement: "TERM-01"
    verification:
      - kind: integration
        ref: "scripts/phase28-terminal-fuzzel-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "Kitty package upgrade with dynamic theme include, opacity 0.85, shell zsh, and claimed helper kittens"
    requirement: "TERM-02"
    verification:
      - kind: integration
        ref: "scripts/phase28-terminal-fuzzel-assert.sh --section 1"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-17
status: complete
---

# Phase 28: Plan 28-01 Summary

**Scaffolded the Phase 28 assertion harness, authored the Fuzzel launcher stow package, upgraded Kitty configuration with dynamic theme inclusion and zsh shell, claimed upstream kittens, and verified Section 1 passing.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-17T18:25:35Z
- **Completed:** 2026-09-17T18:28:05Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Scaffolded `scripts/phase28-terminal-fuzzel-assert.sh` with 0755 permissions, fail-closed CLI argument handling (`--section <1-5>`), cleanup traps, and two-phase git porcelain snapshots.
- Authored `stow/fuzzel/.config/fuzzel/fuzzel.ini` declaring dynamic theme inclusion `~/.config/fuzzel/fuzzel_theme.ini`, font `Google Sans Flex:weight=medium`, `terminal=kitty -1`, squircle radius 17, and overlay layer.
- Upgraded `stow/kitty/.config/kitty/kitty.conf` adopting upstream dots-hyprland layout with dynamic `include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`, `background_opacity 0.85`, `shell zsh`, margin `21.75`, and personal cursor trails.
- Claimed upstream helper kittens `search.py` and `scroll_mark.py` into `stow/kitty/.config/kitty/`, converting unclaimed stubs to managed symlinks.
- Safely deployed both packages via GNU Stow without `--adopt` and verified Section 1 passes with `FAIL=0 FINDINGS=0`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold Phase 28 terminal & Fuzzel launcher assertion harness** - `65dfc2f` (feat)
2. **Task 2: Author stow/fuzzel package, upgrade stow/kitty with upstream layout and claimed kittens, link via GNU Stow, and verify Section 1** - `505744d` (feat)

## Files Created/Modified
- `scripts/phase28-terminal-fuzzel-assert.sh` - Automated test harness for Phase 28 with Sections 1-5 and Section 1 implemented.
- `stow/fuzzel/.config/fuzzel/fuzzel.ini` - Main configuration for Fuzzel application launcher.
- `stow/kitty/.config/kitty/kitty.conf` - Upgraded Kitty terminal configuration.
- `stow/kitty/.config/kitty/search.py` - Claimed upstream search kitten.
- `stow/kitty/.config/kitty/scroll_mark.py` - Claimed upstream scroll mark kitten.

## Decisions Made
- Maintained `shell zsh` instead of upstream `shell fish` to protect user interactive shell environment (D-02).
- Retained personal cursor trail parameters (`cursor_trail 3`, `cursor_trail_decay 0.1 0.4`, `cursor_trail_start_threshold 2`) (D-08).
- Unlinked regular host files prior to stow invocation without using `--adopt` to maintain strict repository integrity (CAP-07).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Quote-tolerant TOML parsing for matugen output_path**
- **Found during:** Task 2 (Section 1 verification)
- **Issue:** `~/.config/matugen/config.toml` uses single quotes (`'~/.config/fuzzel/fuzzel_theme.ini'`), causing double-quote grep in assert script to fail.
- **Fix:** Updated regex to accept either single or double quotes around the path: `output_path = ["']~/\.config/fuzzel/fuzzel_theme\.ini["']`.
- **Files modified:** `scripts/phase28-terminal-fuzzel-assert.sh`
- **Verification:** `bash scripts/phase28-terminal-fuzzel-assert.sh --section 1` passed with `FAIL=0`.
- **Committed in:** `505744d` (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor regex robustness fix; no scope creep.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Section 1 verified on disk.
- Ready for Plan 28-02: Fuzzel and Kitty theme syntax assertions, native options probe, and configuration tuning.

---
*Phase: 28-terminal-fuzzel-launcher-dynamic-palette*
*Completed: 2026-09-17*
