---
phase: 20-hypr-custom-overlays-and-startup-restore
plan: 02
subsystem: ui
tags: [hyprland, overlays, variables, rules, env, execs, autostart, gtk, xsettingsd, cursor]

requires:
  - phase: 20-01
    provides: Phase 20 assert harness with section runner and SAFE-01 drill fixtures
provides:
  - Repository-side custom overlay configurations for variables, rules, env, and execs
  - Unified Bibata-Modern-Classic 24 cursor theme across GTK-3 and XSettings
  - Assert Sections 3, 4, and 5 verifying application preferences, autostarts, and cursor alignment
affects: [20-03, 20-04]

tech-stack:
  added: []
  patterns: [overlay single-source-of-truth headers, single-fire startup hook encapsulation, toolkit cursor parity]

key-files:
  created:
    - stow/hypr/.config/hypr/custom/variables.lua
    - stow/hypr/.config/hypr/custom/rules.lua
  modified:
    - stow/hypr/.config/hypr/custom/env.lua
    - stow/hypr/.config/hypr/custom/execs.lua
    - /home/pera/.config/gtk-3.0/settings.ini
    - /home/pera/.config/xsettingsd/xsettingsd.conf
    - scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh

key-decisions:
  - "Explicitly defined primary application variables in custom/variables.lua bypassing launch_first_available.sh loops without vendor modifications (HYPR-03, D-16)"
  - "Restored Polkit KDE agent, workspace 1 Chrome and kitty+tmux, and special workspace btop and discord inside hl.on('hyprland.start', ...) single-fire hook (START-01, D-01, D-02)"
  - "Preserved Phase 17 screen-share service start in execs.lua (D-05) while omitting wl-clip-persist in favor of cliphist (D-03)"
  - "Aligned GTK-3.0 and xsettingsd cursor settings to Bibata-Modern-Classic 24, eliminating Catppuccin cursor pop after login (D-04)"

patterns-established:
  - "Single-source-of-truth authoring comment header on all custom overlay Lua files"
  - "Strict placement of former exec-once commands inside hl.on('hyprland.start', ...) to prevent process duplication on config reload"

requirements-completed: [HYPR-03, START-01]

coverage:
  - id: D1
    description: "Application preferences in custom/variables.lua locked per D-16 with clean submodule"
    requirement: "HYPR-03"
    verification:
      - kind: integration
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D2
    description: "Python GUI tool floating window rules defined in custom/rules.lua per D-17"
    requirement: "HYPR-03"
    verification:
      - kind: unit
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Environment overlay require slot configured in custom/env.lua per D-18"
    requirement: "HYPR-01"
    verification:
      - kind: unit
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D4
    description: "Pre-adopt autostart applications restored in custom/execs.lua inside single-fire startup hook"
    requirement: "START-01"
    verification:
      - kind: integration
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D5
    description: "Cursor theme settings unified to Bibata-Modern-Classic 24 in GTK-3.0 and xsettingsd"
    requirement: "START-01"
    verification:
      - kind: unit
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 5"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-14
status: complete
---

# Phase 20 Plan 02: Custom Overlay Configurations & Cursor Alignment Summary

**Authored repository-side custom overlay Lua files for variables, rules, env, and autostarts, unified desktop cursor settings to Bibata-Modern-Classic 24 across toolkits, and validated with assert sections 3, 4, and 5.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-14T15:47:00Z
- **Completed:** 2026-09-14T15:51:00Z
- **Tasks:** 3 completed
- **Files modified:** 7 files (2 created in repo, 2 modified in repo, 2 modified live in home, 1 assert script extended)

## Accomplishments

- Authored `stow/hypr/.config/hypr/custom/variables.lua` defining primary application preferences (`terminal = "kitty"`, `browser = "google-chrome-stable"`, `fileManager = "dolphin"`, `textEditor = "kitty -e nvim"`, `taskManager = "kitty --class btop -e btop"`, `officeSoftware = "libreoffice"`, `workspaceGroupSize = 10`, `hl.env("qsConfig", "ii")`), completely avoiding vendor modifications in `vendor/dots-hyprland`.
- Authored `stow/hypr/.config/hypr/custom/rules.lua` restoring window floating rules for `main.py` and `python3` from the pre-adopt configuration.
- Authored `stow/hypr/.config/hypr/custom/env.lua` as a documented require slot for user environment additions.
- Updated `stow/hypr/.config/hypr/custom/execs.lua` restoring the Polkit KDE authentication agent, workspace 1 Chrome and kitty+tmux autostarts, and special workspace btop and discord autostarts inside `hl.on("hyprland.start", ...)`.
- Replaced legacy `catppuccin-mocha-blue-cursors` with `Bibata-Modern-Classic` (size 24) in `~/.config/gtk-3.0/settings.ini` and `~/.config/xsettingsd/xsettingsd.conf`.
- Wired and verified Sections 3, 4, and 5 in `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author repo-side variables, rules, and env overlays** - `bc45aae` (feat)
2. **Task 2: Restore autostart applications in execs.lua** - `ee43add` (feat)
3. **Task 3: Align cursor settings and wire assert sections 3, 4, and 5** - `c0b40e3` (feat)

## Files Created/Modified

- `stow/hypr/.config/hypr/custom/variables.lua` - Application preference definitions.
- `stow/hypr/.config/hypr/custom/rules.lua` - Python GUI floating rules.
- `stow/hypr/.config/hypr/custom/env.lua` - Custom environment require slot.
- `stow/hypr/.config/hypr/custom/execs.lua` - Single-fire startup applications hook.
- `~/.config/gtk-3.0/settings.ini` - GTK cursor theme aligned to Bibata-Modern-Classic 24.
- `~/.config/xsettingsd/xsettingsd.conf` - XSettings cursor theme aligned to Bibata-Modern-Classic 24.
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` - Extended with Sections 3, 4, and 5.

## Decisions Made

- Verified that `vendor/dots-hyprland` remains 100% clean (`git diff --exit-code vendor/dots-hyprland` passes).
- Retained `systemctl --user start hyprland-session.service` in `custom/execs.lua` preserving screen-share bootstrap capability.
- Autostarts are strictly quarantined within `hl.on("hyprland.start", ...)` so that subsequent `hyprctl reload` commands do not spawn runaway processes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Overlay files are prepared in `stow/hypr/`.
- Ready for Wave 3 (Plan 20-03): authoring custom keybinding configuration with unbinds and cheatsheet taxonomy.

---
*Phase: 20-hypr-custom-overlays-and-startup-restore*
*Completed: 2026-09-14*
