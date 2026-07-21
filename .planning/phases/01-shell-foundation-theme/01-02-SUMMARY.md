---
phase: 01-shell-foundation-theme
plan: 02
subsystem: infra
tags: [quickshell, provisioning, material-theme, yay, materialyoucolor]

requires:
  - phase: 01-01
    provides: Full dots-hyprland ii quickshell tree including scripts/colors/generate_colors_material.py
provides:
  - arch/quickshell.sh installs AUR package python-materialyoucolor-git via yay
  - generate_theme() writes Material colors.json for MaterialThemeLoader
  - Static dark vibrant scheme seed color #7aa2f7 at deploy time
affects: [01-03, phase-2-core-bar-modules]

tech-stack:
  added: [yay AUR install path, python-materialyoucolor-git, colors.json generation pipeline]
  patterns: [deploy-time theme generation, SCSS-stdout → snake_case JSON for MaterialThemeLoader]

key-files:
  created: []
  modified:
    - arch/quickshell.sh

key-decisions:
  - "Use yay (not sudo pacman) so AUR package python-materialyoucolor-git can install"
  - "generate_colors_material.py --cache only stores source hex; pipe SCSS stdout into JSON converter for colors.json"
  - "Scheme flag corrected to scheme-vibrant (bare 'vibrant' falls through to tonal-spot)"

patterns-established:
  - "Provisioning script owns package install + symlink + first-run theme generation"
  - "MaterialThemeLoader consumes ~/.local/state/quickshell/user/generated/colors.json (snake_case keys)"

requirements-completed: [THM-01, THM-02]

coverage:
  - id: D1
    description: "arch/quickshell.sh installs packages with yay -Sy --noconfirm --needed and includes python-materialyoucolor-git"
    requirement: THM-01
    verification:
      - kind: other
        ref: "grep -q 'yay -Sy' arch/quickshell.sh && grep -q python-materialyoucolor-git arch/quickshell.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "generate_theme produces colors.json consumable by MaterialThemeLoader (63 Material tokens)"
    requirement: THM-02
    verification:
      - kind: other
        ref: "python3 generate_colors_material.py ... | converter → ~/.local/state/quickshell/user/generated/colors.json (63 keys)"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-21
status: complete
---

# Phase 1 Plan 02: Provisioning and Material Theme Setup Summary

**Updated `arch/quickshell.sh` for AUR (`yay` + `python-materialyoucolor-git`) and deploy-time Material `colors.json` generation for MaterialThemeLoader**

## Performance

- **Duration:** ~15 min (includes rate-limit recovery / inline close-out)
- **Started:** 2026-07-21T11:02:28Z
- **Completed:** 2026-07-21T11:42:00Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Switched package install from `sudo pacman` to `yay -Sy --noconfirm --needed` and added `python-materialyoucolor-git` to `PACKAGES`
- Added `generate_theme()` called from `main()` after `symlink_config`
- Verified theme pipeline writes valid JSON (63 color keys) to `~/.local/state/quickshell/user/generated/colors.json`

## Task Commits

1. **Task 1: Update Provisioning for Theme Generation** - `0d9525a` (feat)

**Plan metadata:** (this SUMMARY commit)

## Files Created/Modified

- `arch/quickshell.sh` — yay-based install, `generate_theme()`, main() wiring

## Decisions Made

- Followed plan package/yay changes exactly
- Auto-fixed theme output path: plan said `--cache colors.json`, but the Python script only caches a source hex for wallpaper re-runs and prints SCSS to stdout. Converter maps SCSS tokens → snake_case JSON matching matugen/`MaterialThemeLoader` contract
- Used `--scheme scheme-vibrant` instead of bare `vibrant` so the vibrant scheme is selected

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule — correctness] colors.json not produced by --cache alone**
- **Found during:** Task 1 (Update Provisioning for Theme Generation)
- **Issue:** `generate_colors_material.py --cache PATH` writes only the seed hex when used with image path; with `--color` it does not write a MaterialThemeLoader-compatible JSON file. Plan acceptance required `colors.json` at the state path.
- **Fix:** Keep calling `generate_colors_material.py` with `--cache` (now `color.txt` for seed hex), pipe SCSS stdout through a small Python converter that writes snake_case `colors.json`.
- **Files modified:** `arch/quickshell.sh`
- **Verification:** Generated 63-key JSON; sample keys `background`, `on_background`, `surface`, etc.
- **Committed in:** `0d9525a`

**2. [Rule — correctness] scheme name**
- **Found during:** Task 1
- **Issue:** `--scheme vibrant` falls through to tonal-spot; script expects `scheme-vibrant`
- **Fix:** Pass `--scheme scheme-vibrant`
- **Files modified:** `arch/quickshell.sh`
- **Verification:** Generated palette uses vibrant-style tokens (seed #7aa2f7)
- **Committed in:** `0d9525a`

## Issues Encountered

- Full `yay -Sy python-materialyoucolor-git` requires sudo password (not available in non-interactive agent session). Theme generation was verified with a temporary venv that provides `materialyoucolor`. User must run `arch/quickshell.sh` once locally to install the system AUR package.
- Initial executor subagent hit free-tier rate limit mid-plan; production edit was present uncommitted and closed out inline without skipping acceptance criteria.

## Self-Check: PASSED

- [x] `grep -q "yay -Sy" arch/quickshell.sh && grep -q "generate_colors_material.py" arch/quickshell.sh`
- [x] `python-materialyoucolor-git` in PACKAGES
- [x] `generate_theme` present and called after `symlink_config`
- [x] `colors.json` created under `~/.local/state/quickshell/user/generated/`
