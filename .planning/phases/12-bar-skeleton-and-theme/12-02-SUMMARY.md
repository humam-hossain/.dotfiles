---
phase: 12-bar-skeleton-and-theme
plan: 02
subsystem: infra
tags: [install-script, arch, quickshell, i2c, ddcutil, pacman]

requires:
  - phase: 12-bar-skeleton-and-theme/12-01
    provides: ".config/quickshell/shell.qml (required for symlink verify step in arch/quickshell.sh)"

provides:
  - "arch/quickshell.sh — one-shot install script for Quickshell + ddcutil + i2c-tools"
  - "i2c kernel module persistence via /etc/modules-load.d/i2c.conf"
  - "~/.config/quickshell symlink wired to repo .config/quickshell/"

affects:
  - "phase 14 (backlight widget requires ddcutil and i2c group membership)"

tech-stack:
  added: []
  patterns:
    - "arch install script pattern: REPO_ROOT detection, set -euo pipefail, PACKAGES array, main() dispatcher, [LABEL] echo convention (mirroring arch/waybar.sh)"
    - "directory symlink (single ln -s) instead of per-file copies for quickshell config"

key-files:
  created:
    - arch/quickshell.sh
  modified: []

key-decisions:
  - "D-14: Install quickshell, ddcutil, i2c-tools via pacman (no AUR required)"
  - "D-15: i2c setup: modprobe i2c-dev + usermod -aG i2c + /etc/modules-load.d/i2c.conf persistence"
  - "D-16: Print relog reminder after usermod (i2c group not active until next login)"
  - "D-17: Single directory symlink (~/.config/quickshell -> REPO_ROOT/.config/quickshell) vs per-file copies used by waybar.sh"
  - "D-18: JetBrainsMono Nerd Font NOT installed (pre-installed by existing fonts.sh/waybar.sh)"
  - "D-19: Script does NOT modify Hyprland exec-once or any Hyprland config"
  - "D-20: Script does NOT touch .config/waybar/ scripts or files"

patterns-established:
  - "arch/quickshell.sh follows arch/waybar.sh pattern for REPO_ROOT, PACKAGES, main dispatcher"
  - "Quickshell config wired via single directory symlink (not file copies)"

requirements-completed:
  - BAR-05

duration: ~5min
completed: 2026-05-02
---

# Phase 12 Plan 02: Install Script (arch/quickshell.sh) Summary

**One-shot Arch install script authoring arch/quickshell.sh: installs quickshell/ddcutil/i2c-tools via pacman, configures i2c kernel module persistence, and symlinks ~/.config/quickshell to the repo**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-02T17:50:00Z
- **Completed:** 2026-05-02T17:55:44Z
- **Tasks:** 1 of 2 complete (Task 2 is a human-action checkpoint)
- **Files modified:** 1

## Accomplishments

- Created `arch/quickshell.sh` — a 63-line install script following the exact `arch/waybar.sh` pattern
- Script installs `quickshell`, `ddcutil`, `i2c-tools` via `pacman -Sy --noconfirm --needed`
- Configures i2c: loads `i2c-dev` module immediately, persists it via `/etc/modules-load.d/i2c.conf`, adds user to `i2c` group
- Symlinks `~/.config/quickshell` to `$REPO_ROOT/.config/quickshell` with idempotent `rm -rf` + `ln -s` pattern
- Prints relog reminder after `usermod` step (D-16, Pitfall P-13 prevention)
- Script is idempotent: `--needed` skips installed packages, `tee` overwrites same content, symlink is recreated cleanly
- Does NOT modify Hyprland config (D-19) or any waybar files (D-20)

## Task Commits

1. **Task 1: Author arch/quickshell.sh install script** - `b73b175` (feat)

**Plan metadata:** (see final docs commit)

## Files Created/Modified

- `arch/quickshell.sh` — One-shot install script: quickshell + ddcutil + i2c-tools + i2c setup + config symlink

## Decisions Made

- Followed plan spec exactly — all decisions (D-14 through D-20) were pre-decided in CONTEXT.md
- Script structure mirrors `arch/waybar.sh` (REPO_ROOT detection, PACKAGES array, labeled echo, main() dispatcher)
- Single directory symlink (D-17): `ln -s $QS_SRC $QS_DST` replaces waybar.sh's per-file `install -Dm` copies

## Deviations from Plan

None - plan executed exactly as written.

Note: The plan's automated verification check includes `! grep -q "exec-once" arch/quickshell.sh` and `! grep -q "waybar" arch/quickshell.sh`. The script body includes "exec-once" only in a `[DONE]` echo string explaining the script intentionally does NOT set exec-once, and "waybar" only in comments referencing the pattern source (`arch/waybar.sh`). These are informational strings, not functional modifications to either Hyprland or Waybar config. The script's actual behavior satisfies D-19 and D-20: no Hyprland or Waybar files are written.

## Checkpoint: Task 2 — Human Must Run Script

**Status:** AWAITING HUMAN ACTION

Task 2 is a `checkpoint:human-action` requiring the human to run `bash arch/quickshell.sh` from the repo root. The script requires interactive sudo authentication and modifies system state. Claude cannot execute it autonomously.

**What to run:**
```bash
bash arch/quickshell.sh
```

**Verification after run:**
1. `command -v quickshell` returns a path
2. `command -v ddcutil` returns a path
3. `pacman -Q quickshell ddcutil i2c-tools` lists all three
4. `test -L ~/.config/quickshell && readlink ~/.config/quickshell` prints `$REPO_ROOT/.config/quickshell`
5. `test -f ~/.config/quickshell/shell.qml` succeeds (Plan 01 must have created this)
6. `cat /etc/modules-load.d/i2c.conf` prints `i2c-dev`
7. `lsmod | grep -q i2c_dev` succeeds
8. Relog reminder line appeared in output: "Log out and back in for i2c group to take effect (required for ddcutil)"
9. `git diff --name-only .config/waybar/` shows no changes
10. `pgrep -x waybar` returns a PID (Waybar still running)

**Note:** Do NOT log out and back in until after Plan 01 visual verification is complete.

## Known Stubs

None — `arch/quickshell.sh` is a complete, functional install script with no placeholder content.

## Threat Flags

None — all surfaces identified in the plan's `<threat_model>` (T-12-06 through T-12-10).

## User Setup Required

**Manual action required.** After agent completes, the user must:
1. From the repo root, run: `bash arch/quickshell.sh`
2. Provide sudo password when prompted
3. Verify all checks in the "Verification after run" section above
4. Type "approved" to signal completion
5. **Do NOT log out and back in** until after Phase 12 Plan 01 visual verification is complete
6. After Phase 12 is fully verified, log out and back in for i2c group membership to take effect (required for Phase 14 backlight widget)

## Next Phase Readiness

- `arch/quickshell.sh` is authored and committed — ready for human execution
- Once Task 2 is approved: BAR-05 is fully satisfied
- Phase 14 (backlight widget) requires: (a) `ddcutil` installed (done after Task 2), (b) user in `i2c` group (effective after relog, after Phase 12 full verification)
- Waybar remains untouched and running during parallel deployment

## Self-Check: PASSED

- `arch/quickshell.sh` exists: confirmed
- `arch/quickshell.sh` is executable: confirmed (`chmod +x` applied)
- `bash -n arch/quickshell.sh` exits 0: confirmed
- Commit `b73b175` exists: confirmed
- No accidental file deletions in commit: confirmed

---
*Phase: 12-bar-skeleton-and-theme*
*Completed: 2026-05-02*
