---
phase: 20-hypr-custom-overlays-and-startup-restore
plan: 05
subsystem: config
tags: [hyprland, rules, keybinds, uat-gap-closure, discord, mute]
gap_closure: true

requires:
  - phase: 20-04
    provides: Live GNU Stow link-identity farm and passing phase verification gate
provides:
  - Persistent window rule for Discord and Vesktop windows routing to special:social silent
  - Complete unbinding of upstream duplicate binds (SUPER+Q, SUPER+Left/Right/Up/Down, SUPER+ALT+M, SUPER+SHIFT+M)
  - Microphone mute toggle on SUPER+M and volume mute toggle on SUPER+ALT+M
  - Extended assert harness covering window rules and all 16 unbinds
  - Clean compositor reload and passing phase assertion suite
affects: [21, 22, 23]

tech-stack:
  added: []
  patterns: [persistent-social-window-rule, upstream-chord-unbinding, audio-source-sink-mute-split]

key-files:
  created: []
  modified:
    - stow/hypr/.config/hypr/custom/rules.lua
    - stow/hypr/.config/hypr/custom/keybinds.lua
    - scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh

key-decisions:
  - "Added persistent window rule hl.window_rule({ match = { class = '^(discord|vesktop)$' }, workspace = 'special:social silent' }) to ensure newly created windows always land in special:social (G-20-1)"
  - "Explicitly unbound upstream SUPER+Q, SUPER+Left/Right/Up/Down, SUPER+ALT+M, and SUPER+SHIFT+M in custom/keybinds.lua to prevent conflicting dual bindings (G-20-2)"
  - "Configured SUPER+M to mic mute (@DEFAULT_AUDIO_SOURCE@) and SUPER+ALT+M to audio sink mute (@DEFAULT_AUDIO_SINK@) per operator specifications (G-20-2)"
  - "Extended Section 3 and Section 6 of phase 20 assert script to validate the persistent window rule and all 16 unbind declarations"

patterns-established:
  - "Pairing exec startup rules with persistent window rules for special workspaces"
  - "Full upstream keybind neutralization via unbind before re-assigning chord subsets"

requirements-completed: [HYPR-02, START-01]

coverage:
  - id: G-20-1
    description: "Discord/Vesktop windows pinned to special:social silent via persistent window rule"
    requirement: "START-01"
    verification:
      - kind: integration
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: G-20-2
    description: "Upstream keybind duplicates unbound and audio mute binds assigned"
    requirement: "HYPR-02"
    verification:
      - kind: integration
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh --section 6"
        status: pass
    human_judgment: false
  - id: ALL-SECTIONS
    description: "Full Phase 20 assert harness passes with FAIL=0 FINDINGS=0"
    requirement: "SAFE-01"
    verification:
      - kind: integration
        ref: "./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh"
        status: pass
    human_judgment: false
  - id: STRICT-VERIFY
    description: "arch/dots-hyprland.sh verify --strict exits 0 with FAIL=0 FINDINGS=0"
    requirement: "HYPR-01"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-09-14
status: complete
---

# Phase 20 Plan 05: UAT Gap Closure Summary

**Closed UAT gaps G-20-1 (Discord window routing) and G-20-2 (upstream keybinding duplicates and inverted mic/volume mute), reloaded Hyprland compositor dynamically, and verified all 7 sections of the assert harness.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-14T16:24:30Z
- **Completed:** 2026-09-14T16:27:00Z
- **Tasks:** 2 completed
- **Files modified:** 3 files

## Accomplishments

- Added persistent window rule in `stow/hypr/.config/hypr/custom/rules.lua` matching `class = "^(discord|vesktop)$"` to `special:social silent`. New and subsequent Discord windows now consistently route into the social special workspace.
- Added unbinds for upstream duplicate shortcuts in `stow/hypr/.config/hypr/custom/keybinds.lua`:
  - `SUPER + Q` (upstream close window, replaced by `SUPER + C`)
  - `SUPER + Left/Right/Up/Down` (upstream directional focus, replaced by `SUPER + H/J/K/L`)
  - `SUPER + ALT + M` and `SUPER + SHIFT + M` (upstream media mute shortcuts)
- Updated audio control bindings:
  - `SUPER + M` -> `@DEFAULT_AUDIO_SOURCE@` (microphone mute toggle)
  - `SUPER + ALT + M` -> `@DEFAULT_AUDIO_SINK@` (speaker volume mute toggle)
- Updated assert harness (`scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`):
  - Section 3 checks discord/vesktop special:social silent window rule
  - Section 6 checks all 16 unbind declarations and audio source/sink mute mappings
- Dynamically reloaded live Hyprland compositor (`hyprctl reload`) without interrupting the desktop session.
- Executed full test suite: all 7 assert sections passed (`FAIL=0 FINDINGS=0`) and `./arch/dots-hyprland.sh verify --strict` passed cleanly (`FAIL=0 FINDINGS=0`).

## Task Commits

1. **Task 1: Add persistent Discord/Vesktop special:social window rule and assert** - `fba71a3` (feat)
2. **Task 2: Unbind upstream duplicate keys, reverse audio mute binds, and update assert** - `24e49df` (feat)

## Files Created/Modified

- `stow/hypr/.config/hypr/custom/rules.lua` - Appended Discord/Vesktop `special:social silent` rule.
- `stow/hypr/.config/hypr/custom/keybinds.lua` - Added upstream unbinds and re-wired audio mute keybinds.
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` - Extended Section 3 and Section 6 test assertions.

## Self-Check: PASSED

- `stow/hypr/.config/hypr/custom/rules.lua` exists and passes `luac -p`
- `stow/hypr/.config/hypr/custom/keybinds.lua` exists and passes `luac -p`
- Commits `fba71a3` and `24e49df` present in git log
- `./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` passes all 7 sections
- `./arch/dots-hyprland.sh verify --strict` passes with FAIL=0 FINDINGS=0

---
*Phase: 20-hypr-custom-overlays-and-startup-restore*
*Completed: 2026-09-14*
