---
phase: 21-ii-bar-config-capture
plan: 03
subsystem: capture
tags: [quickshell, illogical-impulse, bar, theme, switchwall, verify, testing]

requires:
  - phase: 21-ii-bar-config-capture
    provides: capture engine enhancements (Plan 21-01) and systemd timer capture (Plan 21-02)
provides:
  - Deliberate personal bar configuration resident at capture/ii/.config/illogical-impulse/config.json
  - Full 7-section Phase 21 assertion suite (scripts/phase21-ii-bar-config-capture-assert.sh)
  - Strict link-aware verification pass across stow/, restow/, and capture/ trees
affects: [22-kde-gtk-theme-capture]

tech-stack:
  added: []
  patterns: [defaults-reset recovery drill, live wallpaper switch plain-file verification, clean theme revert, link-aware strict verification]

key-files:
  created:
    - capture/ii/.config/illogical-impulse/config.json
  modified:
    - scripts/phase21-ii-bar-config-capture-assert.sh

key-decisions:
  - "Adopted live ~/.config/illogical-impulse/config.json settings into capture/ii/ locking top horizontal bar, spark icon, Dhaka weather, 5 workspaces, and mic/snip toggles (D-15, D-16, BAR-02)"
  - "Excluded upstream installer state flags (installed_listfile, installed_true) and actions/ directories from the repository (D-17)"
  - "Proved that switchwall.sh live wallpaper execution leaves config.json a plain file and capture --quiet synchronizes it cleanly without error (D-19, D-20)"
  - "Implemented defaults-reset recovery drill with timestamped backup, zero-state write, and repo restoration verified byte-identical (D-18)"
  - "Scoped theme revert in assert Section 3 to specific theme directories (restow/kdeglobals/, stow/hypr/, restow/hypr/) to prevent unintended working tree resets"

patterns-established:
  - "Inverted capture verification: verify --strict asserts live capture paths are plain files, never symlinks into the repo"
  - "Defaults-reset recovery: bar configuration can be restored from repository mirror to recover from corrupt or reset state"

requirements-completed: [BAR-01, BAR-02, CAP-06]

coverage:
  - id: D3
    description: "BAR-01 Live wallpaper switch confirmation and theme revert drill"
    requirement: "BAR-01"
    verification:
      - kind: unit
        ref: "./scripts/phase21-ii-bar-config-capture-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D6
    description: "BAR-02 Personal bar settings baseline check and defaults-reset recovery drill"
    requirement: "BAR-02"
    verification:
      - kind: unit
        ref: "./scripts/phase21-ii-bar-config-capture-assert.sh --section 6"
        status: pass
    human_judgment: false
  - id: D7
    description: "Full suite integration gate and strict link check"
    requirement: "BAR-01, BAR-02, CAP-06"
    verification:
      - kind: integration
        ref: "./scripts/phase21-ii-bar-config-capture-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-15
status: complete
---

# Phase 21 Plan 03: Bar Baseline Adoption & Full Suite Verification Summary

**Adopted the deliberate personal bar configuration baseline into `capture/ii/.config/illogical-impulse/config.json`, completed Sections 3, 6, and 7 of `scripts/phase21-ii-bar-config-capture-assert.sh`, proved defaults-reset recovery and live wallpaper resilience, and passed strict link-aware verification with zero defects.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-15T05:37:00Z
- **Completed:** 2026-09-15T05:42:00Z
- **Tasks:** 2 completed
- **Files modified:** 2 files (1 created, 1 modified)

## Accomplishments

- Adopted deliberate personal bar settings into `capture/ii/.config/illogical-impulse/config.json` adhering to `capture/<pkg>/<rel_to_home>` stow-relative layout (D-15, D-16, BAR-02):
  - `bar.bottom == false` (top bar)
  - `bar.topLeftIcon == "spark"`
  - `bar.weather.city == "Dhaka"`
  - `bar.workspaces.shown == 5`
  - `bar.utilButtons.showMicToggle == true`
  - `bar.utilButtons.showScreenSnip == true`
  - Excluded installer state artifacts (`installed_true`, `installed_listfile`) and runtime directories (D-17).
- Implemented Section 6 in `scripts/phase21-ii-bar-config-capture-assert.sh`:
  - Verified presence and tracking of `capture/ii/.config/illogical-impulse/config.json`.
  - Verified all personal bar preference values via `jq -e`.
  - Executed defaults-reset recovery drill (timestamped backup, simulated empty `{}` reset, mirror restoration, byte identity verification via `cmp -s`, and `qs -c ii` reload).
- Implemented Section 3 in `scripts/phase21-ii-bar-config-capture-assert.sh`:
  - Executed non-disruptive live wallpaper switcher (`switchwall.sh` with active wallpaper `55192173787_b8322b1190_o.jpg`).
  - Confirmed `~/.config/illogical-impulse/config.json` is a plain file (`test -f && ! -L`).
  - Verified that `./arch/dots-hyprland.sh capture --quiet` succeeds.
  - Cleanly reverted generated theme modifications.
- Implemented Section 7 full-suite gate running all 7 sections sequentially.
- Passed full test suite `./scripts/phase21-ii-bar-config-capture-assert.sh` with `FAIL=0 FINDINGS=0`.
- Passed strict link-aware verification `./arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Adopt personal bar baseline in capture/ii/** - `ce6a82d` (feat)
2. **Task 2: Complete assert sections 3, 6, 7 and strict verify gate** - `d8f9eba` (feat)

## Files Created/Modified

- `capture/ii/.config/illogical-impulse/config.json` - Personal Quickshell bar configuration mirror.
- `scripts/phase21-ii-bar-config-capture-assert.sh` - Completed Phase 21 assertion harness with all 7 sections.

## Decisions Made

- Scoped git checkout in Section 3 to specific generated theme directories (`restow/kdeglobals/`, `stow/hypr/`, `restow/hypr/`) rather than a global `git checkout -- .`, protecting assert script modifications and other unstaged files from accidental reset.
- Verified that `qs -c ii` process running under PID 1503 correctly reloads after live configuration restoration.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- All 3 plans in Phase 21 are complete and verified.
- Repository mirror at `capture/ii/.config/illogical-impulse/config.json` is actively tracked.
- Systemd user timer `dotfiles-capture.timer` is enabled and active in the live desktop session.
- Ready for Phase 21 verification and completion gates.

---
*Phase: 21-ii-bar-config-capture*
*Completed: 2026-09-15*
