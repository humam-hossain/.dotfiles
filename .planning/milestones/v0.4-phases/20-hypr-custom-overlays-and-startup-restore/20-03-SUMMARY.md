---
phase: 20-hypr-custom-overlays-and-startup-restore
plan: 03
subsystem: ui
tags: [hyprland, keybinds, unbind, quickshell, cheatsheet, vim-navigation]

requires:
  - phase: 20-02
    provides: Custom application variables, window rules, env require slot, and autostart hooks
provides:
  - Repository-side keybind configuration with upstream unbinds and cheatsheet taxonomy
  - Assert Section 6 verifying all 9 unbind declarations, syntax, taxonomy, and non-duplication
affects: [20-04]

tech-stack:
  added: []
  patterns: [unbind-before-bind, category-label cheatsheet taxonomy, vim-style window navigation]

key-files:
  created: [stow/hypr/.config/hypr/custom/keybinds.lua]
  modified: [scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh]

key-decisions:
  - "Unbound 9 conflicting upstream key chords (SUPER + C, L, K, J, D, P, M, S, Minus) at the top of custom/keybinds.lua to prevent double-firing (D-06)"
  - "Mapped window close (SUPER + C), float/tile toggle (SUPER + D), fullscreen maximize (SUPER + ALT + D), pseudo-tile (SUPER + P), and split layout toggle (SUPER + Z) per D-07, D-08, D-10"
  - "Configured Vim-style directional window focus on SUPER + H/L/K/J while preserving upstream arrow keys as secondary binds (D-09)"
  - "Mapped special workspaces for social (SUPER + grave) and btop (SUPER + Minus) with corresponding shift-move binds (D-14)"
  - "Configured relative workspace cycling on CTRL + SUPER + H/L and moves on CTRL + SHIFT + SUPER + H/L (D-14)"
  - "Strictly formatted all 22 keybind descriptions in 'Category: Label' syntax ensuring clean display in Quickshell's SUPER + / cheatsheet (D-15)"

patterns-established:
  - "Explicit unbind before bind for any upstream key combinations that are reassigned in personal overlays"
  - "Category: Label description taxonomy across all Hyprland keybinding definitions"

requirements-completed: [HYPR-02]

coverage:
  - id: D1
    description: "Upstream unbind declarations in custom/keybinds.lua for 9 conflicting chords per D-06"
    requirement: "HYPR-02"
    verification:
      - kind: unit
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 6"
        status: pass
    human_judgment: false
  - id: D2
    description: "Personal window management, Vim navigation, audio, search, session, and special workspace keybindings"
    requirement: "HYPR-02"
    verification:
      - kind: unit
        ref: "luac -p stow/hypr/.config/hypr/custom/keybinds.lua"
        status: pass
    human_judgment: false
  - id: D3
    description: "Cheatsheet taxonomy format 'Category: Label' and zero duplicates across all keybindings"
    requirement: "HYPR-02"
    verification:
      - kind: unit
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 6"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-09-14
status: complete
---

# Phase 20 Plan 03: Custom Keybindings & Cheatsheet Taxonomy Summary

**Authored repository-side custom keybindings overlay (`stow/hypr/.config/hypr/custom/keybinds.lua`) with 9 upstream unbinds, Vim-style window navigation, special workspaces, and unified 'Category: Label' cheatsheet taxonomy, validated by assert Section 6.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-14T15:48:20Z
- **Completed:** 2026-09-14T15:51:20Z
- **Tasks:** 2 completed
- **Files modified:** 2 files (1 created, 1 modified)

## Accomplishments

- Authored `stow/hypr/.config/hypr/custom/keybinds.lua` with authoring header and 9 `hl.unbind` calls for upstream collisions (`SUPER + C, L, K, J, D, P, M, S, Minus`).
- Bound window management actions: close (`SUPER + C`), float toggle (`SUPER + D`), toggle maximize (`SUPER + ALT + D`), pseudo-tile (`SUPER + P`), and split layout (`SUPER + Z`).
- Bound Vim-style directional focus navigation on `SUPER + H/L/K/J`.
- Bound audio mute on `SUPER + M`, Quickshell search toggle on `SUPER + Space`, session lock on `Scroll_Lock`, and session logout on `SUPER + ALT + Scroll_Lock`.
- Configured special workspaces for social (`SUPER + grave`) and btop (`SUPER + Minus`), along with relative workspace cycling on `CTRL + SUPER + H/L` and window moves on `CTRL + SHIFT + SUPER + H/L`.
- Retained quick editing helper on `CTRL + SUPER + ALT + Slash`.
- Verified Lua syntax cleanly with `luac -p`.
- Implemented and verified Section 6 in `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`, confirming all unbinds, taxonomy compliance for all 22 binds, and zero duplicate chord bindings.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author repo-side keybinds.lua with unbinds and cheatsheet taxonomy** - `48281b0` (feat)
2. **Task 2: Wire assert section 6 for keybind unbinds and taxonomy** - `0642606` (test)

## Files Created/Modified

- `stow/hypr/.config/hypr/custom/keybinds.lua` - Personal keybinds configuration.
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` - Extended with Section 6.

## Decisions Made

- Unbind statements are executed at the top of the file before any `hl.bind` calls so the upstream dispatchers are cleared first.
- Every keybinding description adheres strictly to `"Category: Label"` so Quickshell's QML parser categorizes them accurately in the cheatsheet.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- All repository-side overlays (`variables.lua`, `rules.lua`, `env.lua`, `execs.lua`, `keybinds.lua`, and existing `general.lua`) are authored and verified.
- Ready for Wave 4 (Plan 20-04): live SAFE-01 bulk migration drill, GNU Stow link management transition, Hyprland compositor reload, and phase verification gate.

---
*Phase: 20-hypr-custom-overlays-and-startup-restore*
*Completed: 2026-09-14*
