---
phase: 21-ii-bar-config-capture
plan: 02
subsystem: capture
tags: [systemd, timer, service, stow, hyprland, automation]

requires:
  - phase: 21-ii-bar-config-capture
    provides: capture engine validation, atomic replace, and CLI flags (Plan 21-01)
provides:
  - Systemd user service (dotfiles-capture.service) and timer (dotfiles-capture.timer) under stow/systemd/
  - Systemd timer enablement and restart wired into arch/hyprland.sh
  - Live timer activation running on 15m cadence with display passthrough
  - Phase 21 assert test harness Sections 4 and 5 verification
affects: [21-03]

tech-stack:
  added: [systemd-user-timers]
  patterns: [systemd user oneshot unit, systemd periodic timer, PassEnvironment display forwarding, unstaged git drift verification]

key-files:
  created:
    - stow/systemd/.config/systemd/user/dotfiles-capture.service
    - stow/systemd/.config/systemd/user/dotfiles-capture.timer
  modified:
    - arch/hyprland.sh
    - arch/dots-hyprland.sh
    - scripts/phase21-ii-bar-config-capture-assert.sh

key-decisions:
  - "Configured dotfiles-capture.timer with 15m active cadence, 2m post-boot delay, and Persistent=true for catching up missed wake runs (D-08)"
  - "Configured dotfiles-capture.service with Nice=19 (lowest priority), 30s timeout, and PassEnvironment for WAYLAND_DISPLAY and DBUS (D-09, D-10, D-12)"
  - "Configured SuccessExitStatus=0 1 so skipped dirty mirrors or missing live counterparts do not trigger systemd unit failure status (D-11)"
  - "Wired enable --now and restart for dotfiles-capture.timer into arch/hyprland.sh immediately after stow and daemon-reload (D-14)"
  - "Evaluated cmp -s change detection before mirror_is_capturable so byte-identical live files skip cleanly without false dirty-mirror warnings"

patterns-established:
  - "Unattended capture: background timer keeps repository mirror synchronized without operator manual invocation"
  - "Unstaged working tree review: capture updates the working tree directly while keeping the git index completely unstaged (D-38, CAP-05)"

requirements-completed: [CAP-06]

coverage:
  - id: D4
    description: "CAP-06 Systemd user timer enabled, active, stowed, and oneshot service execution"
    requirement: "CAP-06"
    verification:
      - kind: unit
        ref: "./scripts/phase21-ii-bar-config-capture-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D5
    description: "CAP-06 Drift capture drill: hand-edited live file captured to unstaged git status"
    requirement: "CAP-06"
    verification:
      - kind: unit
        ref: "./scripts/phase21-ii-bar-config-capture-assert.sh --section 5"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-15
status: complete
---

# Phase 21 Plan 02: Systemd User Capture Units & Drift Assertions Summary

**Authored and stowed systemd user units `dotfiles-capture.service` and `dotfiles-capture.timer` under `stow/systemd/`, wired timer activation into `arch/hyprland.sh`, deployed to the live user session, and verified background scheduling and live drift capture with Sections 4 and 5 of the assert harness.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-15T05:35:00Z
- **Completed:** 2026-09-15T05:39:00Z
- **Tasks:** 2 completed
- **Files modified:** 5 files (2 created, 3 modified)

## Accomplishments

- Created `stow/systemd/.config/systemd/user/dotfiles-capture.service`:
  - `Type=oneshot`, executing `arch/dots-hyprland.sh capture --quiet --notify`.
  - `Nice=19` (lowest CPU scheduling priority to avoid UI frame drops) and `TimeoutStartSec=30s`.
  - `PassEnvironment=WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS` for desktop notification dispatch.
  - `SuccessExitStatus=0 1` to accommodate legitimate skipped captures.
- Created `stow/systemd/.config/systemd/user/dotfiles-capture.timer`:
  - `OnStartupSec=2m`, `OnUnitActiveSec=15m`, `Persistent=true`, attached to `timers.target`.
- Updated `arch/hyprland.sh` to enable and restart `dotfiles-capture.timer` on graphical session setup.
- Stowed units to `~/.config/systemd/user/` and activated timer in the live user session (`is-enabled` -> `enabled`, `is-active` -> `active`).
- Implemented Section 4 in `scripts/phase21-ii-bar-config-capture-assert.sh`:
  - Verified unit syntax via `systemd-analyze --user verify`.
  - Verified stow symlink destinations for both service and timer.
  - Verified timer enablement and active status.
  - Verified oneshot service execution and journal logging.
- Implemented Section 5 in `scripts/phase21-ii-bar-config-capture-assert.sh`:
  - Verified that manual live file edits are captured to the git working tree mirror.
  - Verified that changes remain unstaged in git status (` M `) with empty git index (`git diff --cached`).
  - Verified that subsequent capture runs detect byte identity via `cmp -s` and skip as a zero-cost no-op.

## Task Commits

Each task was committed atomically:

1. **Task 1 & 2: Author capture service & timer, wire in hyprland.sh, and add assert sections 4 & 5** - `f000ef5` (feat)

## Files Created/Modified

- `stow/systemd/.config/systemd/user/dotfiles-capture.service` - User service unit executing capture oneshot.
- `stow/systemd/.config/systemd/user/dotfiles-capture.timer` - User timer unit scheduling capture every 15 minutes.
- `arch/hyprland.sh` - Graphical bootstrap script enabling and restarting the capture timer.
- `arch/dots-hyprland.sh` - Reordered `cmp -s` check before `mirror_is_capturable` for zero-cost unchanged skip.
- `scripts/phase21-ii-bar-config-capture-assert.sh` - Implemented Sections 4 and 5 assertions.

## Decisions Made

- Placed `cmp -s` check prior to `mirror_is_capturable` so that byte-identical files (e.g. captured files waiting to be committed by the user) are recognized as in-sync no-ops rather than producing false dirty-mirror warnings.
- Matched systemd unit journal entries via `Finished Capture dotfiles from live environment to repository mirror` to verify systemd service completion cleanly under quiet mode.

## Deviations from Plan

### Auto-fixed Deviations

**1. [Rule 1 - Bug] Reordered `cmp -s` before `mirror_is_capturable` in `run_capture`**
- **Found during:** Task 2 (Section 5 test)
- **Issue:** On the second capture run after a drift has been copied into the working tree, the repo mirror is modified against HEAD. `mirror_is_capturable` flagged the file as dirty against HEAD before `cmp -s` could observe that the live file and repo file were already byte-identical.
- **Fix:** Placed `cmp -s` before `mirror_is_capturable`. If files are already byte-identical, no copy is needed and the unchanged file is skipped cleanly without error.
- **Files modified:** `arch/dots-hyprland.sh`
- **Verification:** Both Section 1 (dirty repo mirror refusal when contents differ) and Section 5 (second run unchanged skip when contents match) pass 100%.
- **Commit:** `f000ef5`

## Next Phase Readiness

- Wave 2 (Plan 21-02) is complete and verified green.
- Ready for Wave 3 (Plan 21-03): Adopt live `~/.config/illogical-impulse/config.json` into `capture/ii/`, implement Section 6 (defaults-reset recovery drill), Section 3 (live wallpaper confirmation), and Section 7 (full suite gate).

---
*Phase: 21-ii-bar-config-capture*
*Completed: 2026-09-15*
