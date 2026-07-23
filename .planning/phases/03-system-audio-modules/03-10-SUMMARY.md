---
phase: 03-system-audio-modules
plan: 10
subsystem: audio
tags: [hyprland, wpctl, pavucontrol, volume-mixer, gap-closure]

requires:
  - phase: 03-system-audio-modules
    provides: "Audio.maxVolume 1.30, volumeMixer config path, mute/mic bar handlers, VolumeDialog Details"
provides:
  - "Live + repo XF86AudioRaiseVolume use wpctl -l 1.3 (keyboard 130% ceiling)"
  - "launch_first_available.sh for apps.volumeMixer (pavucontrol-qt || pavucontrol)"
affects: [bar-audio, uat-gaps, BAR-08]

tech-stack:
  added: []
  patterns:
    - "launch_first_available.sh first-match PATH launcher for optional app binaries"
    - "Live Hyprland conf patched in place when not same inode as repo (document approach)"

key-files:
  created:
    - .config/hypr/hyprland/scripts/launch_first_available.sh
  modified: []

key-decisions:
  - "Keyboard ceiling is Hyprland wpctl -l (not Quickshell Audio.maxVolume); live hyprland.conf is a separate inode from repo — patch live in place rather than force-symlink"
  - "Ship launch_first_available.sh (not hardcode pavucontrol only) so pavucontrol-qt is preferred when present"
  - "Config.qml volumeMixer default already correct; dual-write to live config.json confirmed match — no Config.qml edit required"

patterns-established:
  - "First-available launcher script under ~/.config/hypr/hyprland/scripts/ for optional desktop tools"
  - "When live and repo hypr configs diverge by inode, verify both and document patch-in-place vs stow"

requirements-completed:
  - BAR-08

coverage:
  - id: D1
    description: "Keyboard XF86AudioRaiseVolume can raise sink volume to ~130% (wpctl -l 1.3) on live compositor config"
    requirement: "BAR-08"
    verification:
      - kind: other
        ref: "hyprctl binds shows -l 1.3; wpctl set-volume -l 1.3 reaches Volume: 1.15+"
        status: pass
    human_judgment: true
    rationale: "Physical keyboard volume wheel path still needs human UAT confirmation on the session"
  - id: D2
    description: "Middle/right mute/mic and sidebar Details open pavucontrol via volumeMixer"
    requirement: "BAR-08"
    verification:
      - kind: other
        ref: "timeout bash -c volumeMixer launches pavucontrol (rc 124 timeout after start)"
        status: pass
    human_judgment: true
    rationale: "Bar middle/right-click and sidebar Details UI path need human click confirmation"

duration: 1min
completed: 2026-07-23
status: complete
---

# Phase 03 Plan 10: UAT Gap Closure — Keyboard 130% + pavucontrol Launch Summary

**Keyboard volume ceiling raised to 130% via live Hyprland wpctl -l 1.3; volumeMixer ships launch_first_available.sh so bar/sidebar open pavucontrol**

## Performance

- **Duration:** 1 min
- **Started:** 2026-07-23T15:22:31Z
- **Completed:** 2026-07-23T15:24:00Z
- **Tasks:** 2/2
- **Files modified:** 1 created (repo); live dual-writes verified

## Accomplishments

- Confirmed repo and live `hyprland.conf` both use `wpctl set-volume -l 1.3` on XF86AudioRaiseVolume; reloaded Hyprland; active binds and `wpctl` confirm >100% volume
- Recreated `launch_first_available.sh` (prior partial commit had been reverted) and dual-wrote to live `~/.config/hypr/hyprland/scripts/`
- Verified Config.qml + live `config.json` `apps.volumeMixer` already agree; smoke-launched pavucontrol via the configured command

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply keyboard volume ceiling 130% to live Hyprland** - `(no commit — already applied)`
2. **Task 2: Fix volumeMixer launch (script + config dual-write)** - `9f3d2ae` (feat)

**Plan metadata:** `d8a6446` (docs: complete plan)

_Note: Task 1 found both repo and live already at `-l 1.3` (different inodes; live previously patched). No repo file change; `hyprctl reload` applied._

## Files Created/Modified

- `.config/hypr/hyprland/scripts/launch_first_available.sh` — first PATH-available command launcher for volumeMixer
- Live (not in git): `~/.config/hypr/hyprland.conf` — already had `-l 1.3`; reloaded
- Live (not in git): `~/.config/hypr/hyprland/scripts/launch_first_available.sh` — dual-written from repo
- Live (not in git): `~/.config/illogical-impulse/config.json` — volumeMixer already matched; no write needed
- Unchanged (already correct): `.config/hypr/hyprland.conf`, `.config/quickshell/modules/common/Config.qml`

## Decisions Made

- **Patch live Hyprland in place, do not force symlink:** Live `~/.config/hypr/hyprland.conf` and repo `.config/hypr/hyprland.conf` are different inodes (machine-managed). Approach used: verify both lines, keep separate files, reload compositor. Documented so future work does not assume stow.
- **Ship the launcher script rather than hardcoding pavucontrol:** Matches Config default and prefers `pavucontrol-qt` when installed; this host has `/usr/bin/pavucontrol` only.
- **No Config.qml edit:** Default `apps.volumeMixer` already points at the script with both binary names; live config.json already dual-written from prior phase work.

## Deviations from Plan

None - plan executed as written (Task 1 was verify/reload-only because live already had the fix from a prior partial session).

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** N/A — no scope change

## Issues Encountered

- Prior partial execution committed then reverted `launch_first_available.sh` (`f636696` → `c9fee4e`); re-executed Task 2 cleanly as `9f3d2ae`.
- Unrelated dirty working tree files (`ToolbarTabBar.qml`, `AiChat.qml`, `Anime.qml`) left unstaged per instructions.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- G-03-4 and G-03-8 production fixes in place; remaining Phase 03 UAT re-check for keyboard raise past 100% and bar/sidebar pavucontrol open
- Phase 03 plans 01–10 complete after this SUMMARY; ready for phase verification / remaining gap re-UAT

---
*Phase: 03-system-audio-modules*
*Completed: 2026-07-23*

## Self-Check: PASSED

- FOUND: 03-10-SUMMARY.md
- FOUND: launch_first_available.sh
- FOUND: commit 9f3d2ae
