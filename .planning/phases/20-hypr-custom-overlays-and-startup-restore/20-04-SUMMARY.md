---
phase: 20-hypr-custom-overlays-and-startup-restore
plan: 04
subsystem: infra
tags: [hyprland, stow, symlinks, safe-drill, escape-route, verification]

requires:
  - phase: 20-03
    provides: Custom overlay files in stow/hypr/ and assert sections 1-6
provides:
  - Live GNU Stow link-identity farm for all 6 custom overlay files in ~/.config/hypr/custom/
  - Rehearsed and verified SAFE-01 escape route on live desktop filesystem
  - Clean compositor reload and passing phase verification gate
affects: [21, 22, 23]

tech-stack:
  added: []
  patterns: [safe-bulk-stow-rehearsal, live-inode-verification, compositor-dynamic-reload]

key-files:
  created: []
  modified:
    - scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh

key-decisions:
  - "Enforced main worktree guard ensuring stow runs only from canonical repo root, preventing links to ephemeral worktrees"
  - "Captured timestamped backup at ~/.config/hypr/custom.backup.<epoch> prior to deleting any live stubs (D-20)"
  - "Executed full live escape rehearsal (stow -D, restore from backup, verify regular files, re-clean, re-stow) proving reversibility (D-21, SAFE-01)"
  - "Established individual symlink inode identity for all 6 custom overlay files without parent directory folding (HYPR-01)"
  - "Successfully reloaded Hyprland configuration dynamically via hyprctl reload without session interruption"

patterns-established:
  - "Bulk stow over live unmanaged stubs with preceding timestamped backup and live escape route drill"
  - "Verification of ~/.config/hypr/custom as a real directory preserving universal --no-folding"

requirements-completed: [HYPR-01, SAFE-01]

coverage:
  - id: D1
    description: "Live SAFE-01 migration drill and escape route rehearsal executed on live desktop session"
    requirement: "SAFE-01"
    verification:
      - kind: integration
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 1 && ./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D2
    description: "All 6 overlay files in ~/.config/hypr/custom/ are symlinks resolving to repo inodes with no parent folding"
    requirement: "HYPR-01"
    verification:
      - kind: integration
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 7"
        status: pass
    human_judgment: false
  - id: D3
    description: "arch/dots-hyprland.sh verify --strict exits 0 with FAIL=0 FINDINGS=0"
    requirement: "HYPR-01"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false
  - id: D4
    description: "Operator manual post-login verification procedure documented for fresh boot autostart and polkit prompt checks"
    requirement: "START-01"
    verification: []
    human_judgment: true
    rationale: "Compositor startup execution of workspace assignments and GUI polkit dialog prompt requires fresh graphical login"

duration: 4min
completed: 2026-09-14
status: complete
---

# Phase 20 Plan 04: Live SAFE-01 Migration Drill & Full Phase Gate Summary

**Executed live SAFE-01 migration drill and escape route rehearsal on real desktop session, established GNU Stow link-identity for all 6 custom overlay files in `~/.config/hypr/custom/`, reloaded Hyprland compositor cleanly, and gated completion behind green assert harness (all 7 sections) and `verify --strict`.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-14T15:49:30Z
- **Completed:** 2026-09-14T15:53:30Z
- **Tasks:** 2 completed
- **Files modified:** 1 file in repo, 6 symlinks updated live in `~/.config/hypr/custom/`

## Accomplishments

- Verified canonical worktree root (`git-dir` matches `git-common-dir`), preventing accidental linking into temporary worktrees.
- Created live timestamped backup `~/.config/hypr/custom.backup.1789379396` containing regular files before modifying live system state.
- Removed legacy stubs (`keybinds.lua`, `rules.lua`, `variables.lua`) and executed dry-run `stow -n -v --no-folding -t ~ hypr` confirming zero conflicts.
- Executed bulk stow establishing initial symlinks, followed immediately by the live escape rehearsal (`stow -D`, restore from backup, verify regular files restored, re-clean, re-stow) proving complete live reversibility (SAFE-01, D-21).
- Confirmed that all 6 files in `~/.config/hypr/custom/` (`env.lua`, `execs.lua`, `general.lua`, `keybinds.lua`, `rules.lua`, `variables.lua`) are valid symlinks resolving to the identical inodes in `stow/hypr/.config/hypr/custom/` with zero parent directory folding (HYPR-01).
- Reloaded Hyprland configuration via `hyprctl reload` with zero errors.
- Completed Section 7 in `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` asserting real directory status, symlink inode identity, and `./arch/dots-hyprland.sh verify --strict`.
- Validated the full suite: all 7 sections pass with `FAIL=0 FINDINGS=0`, and `verify --strict` exits 0 with `FAIL=0 FINDINGS=0`.

## Task Commits

Each task was committed atomically:

1. **Task 1 & 2: Add Section 7 asserts for link identity and verify --strict** - `4b1ab8d` (test)

## Files Created/Modified

- `~/.config/hypr/custom/{env,execs,general,rules,keybinds,variables}.lua` - Active live symlinks pointing to `stow/hypr/.config/hypr/custom/`.
- `~/.config/hypr/custom.backup.1789379396` - Timestamped pre-migration backup directory.
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` - Extended with Section 7.

## Decisions Made

- All stow commands strictly passed `--no-folding`, ensuring `~/.config/hypr/custom` remains a real directory containing individual symlinks.
- Live undo drill was executed and verified on the live system before final re-stow was applied, proving the escape route works as documented.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

### Operator Manual Post-Verification Steps (D-23, START-01)
On the next fresh graphical login to Hyprland, verify:
1. **Chrome:** Launches on workspace 1.
2. **Kitty + tmux:** Launches on workspace 1.
3. **btop:** Launches silently on special:btop (toggle with `SUPER + Minus`).
4. **Vesktop/Discord:** Launches silently on special:social (toggle with `SUPER + grave`).
5. **Polkit KDE Agent:** Administrative commands in terminal (e.g. `pkexec true`) invoke the graphical KDE authentication dialog.

## Next Phase Readiness

- Phase 20 is complete: personal overlays authored, stow link-identity layer active, autostarts restored, keybinds integrated into cheatsheet, cursor aligned, full assert suite passing.
- Ready for Phase 21 (ii bar config capture).

---
*Phase: 20-hypr-custom-overlays-and-startup-restore*
*Completed: 2026-09-14*
