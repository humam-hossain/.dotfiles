---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 06
subsystem: config
tags: [hypr, stow, restow, git-mv, redistribution, cleanup]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 04
    provides: "docs/config-redistribution.md destination authority and initial moves"
provides:
  - "stow/hypr/ — non-colliding hypr configs (custom/env.lua, custom/execs.lua, custom/general.lua, hyprland-gui.conf, hyprpaper.conf)"
  - "restow/hypr/ — overwriting hypr configs (hypridle.conf, hyprlock.conf, hyprland/scripts/launch_first_available.sh)"
  - "complete removal of repo-root .config/ tree"
affects: [18-07, 18-09, 18-10, 18-11]

# Actuals
actuals:
  tokens: 11000
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Split configuration packages with matching names across stow/ and restow/ where collision map dictates"
    - "Repo-side only placement: no live links and no stow runs prior to central linking in plan 18-11"
    - "Vendor-match exception: retain customized repo content when live is byte-identical to upstream overwrite"

key-files:
  created:
    - stow/hypr/.config/hypr/custom/env.lua
    - stow/hypr/.config/hypr/custom/execs.lua
    - stow/hypr/.config/hypr/custom/general.lua
    - stow/hypr/.config/hypr/hyprland-gui.conf
    - stow/hypr/.config/hypr/hyprpaper.conf
    - restow/hypr/.config/hypr/hypridle.conf
    - restow/hypr/.config/hypr/hyprlock.conf
    - restow/hypr/.config/hypr/hyprland/scripts/launch_first_available.sh
  deleted:
    - .config/hypr/custom/env.lua
    - .config/hypr/custom/execs.lua
    - .config/hypr/custom/general.lua
    - .config/hypr/hypridle.conf
    - .config/hypr/hyprland-gui.conf
    - .config/hypr/hyprland/scripts/launch_first_available.sh
    - .config/hypr/hyprlock.conf
    - .config/hypr/hyprpaper.conf

key-decisions:
  - "hypr configuration split mechanically between stow/hypr/ and restow/hypr/ per collision-map.tsv"
  - "custom/execs.lua preserved in stow/hypr/ satisfying Phase 17 D-18 requirement"
  - "launch_first_available.sh placed in restow/hypr/ carrying customized repo content per D-22"
  - "hypridle.conf and hyprlock.conf placed in restow/hypr/ because auto-backup renames link on firstrun"
  - "Repo-root .config/ completely eliminated; all 12 former files accounted for across stow/, restow/, docs/archive/"
  - "Zero stow invocations and zero live symlinks created; live linking deferred to plan 18-11"

requirements-completed: [FIX-03]

coverage:
  - id: D1
    description: "hypr configs split across stow/hypr/ and restow/hypr/ matching collision map"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "All 5 non-colliding files in stow/hypr/; all 3 overwriting files in restow/hypr/"
        status: pass
      human_judgment: false
  - id: D2
    description: "Repo-root .config/ completely removed with zero untracked leftovers"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "test ! -e .config && [ -z \"$(git ls-files -- .config/)\" ]"
        status: pass
      human_judgment: false
  - id: D3
    description: "All source rows in redistribution registry resolve to existing destinations"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "All 13 tracked paths across stow/hypr, restow/hypr, restow/dolphinrc, restow/kdeglobals, docs/archive verified present on disk"
        status: pass
      human_judgment: false

# Metrics
duration: 10 min
completed: 2026-09-14
status: complete
---

# Phase 18 Plan 06: Hypr Tree Split and .config/ Retirement Summary

**Split Hyprland configurations across `stow/hypr/` and `restow/hypr/` according to `collision-map.tsv`, preserved customized repo content for `launch_first_available.sh`, and completely retired repo-root `.config/`.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-14T01:16:48Z
- **Completed:** 2026-09-14T01:17:50Z
- **Tasks:** 3
- **Files modified:** 8 moved from `.config/` to `stow/hypr/` and `restow/hypr/`; `.config/` directory removed.

## Accomplishments

- Relocated non-colliding Hyprland configs into `stow/hypr/.config/hypr/` using `git mv`:
  - `custom/env.lua`, `custom/execs.lua` (mandated by Phase 17 D-18), `custom/general.lua`, `hyprland-gui.conf`, and `hyprpaper.conf`.
  - Confirmed byte-identical match with live counterparts in `$HOME`.
- Relocated overwriting Hyprland configs into `restow/hypr/.config/hypr/` using `git mv`:
  - `hypridle.conf` and `hyprlock.conf` (assigned to `restow/` because upstream `install_file__auto_backup` renames the link away on firstrun; currently disarmed on host by `installed_true`).
  - `hyprland/scripts/launch_first_available.sh` (assigned to `restow/` with repo content retained per D-22 vendor-match exception, preserving local customizations over upstream's overwritten bytes).
- Completely eliminated repo-root `.config/`:
  - Confirmed all 12 tracked files formerly under `.config/` are safely in `stow/`, `restow/`, or `docs/archive/`.
  - Confirmed `test ! -e .config` and `git ls-files -- .config/` is completely empty.
- Adhered strictly to the repo-side only constraint: no GNU Stow commands were run and no symlinks were created under `$HOME`. Live linking is deferred to Plan 18-11 in the main worktree.

## Task Commits

1. **Task 1: Move non-colliding hypr configs to stow/hypr/** — `546abe4` (feat)
2. **Task 2: Move overwriting hypr configs to restow/hypr/** — `4ad665f` (feat)
3. **Task 3: Remove repo-root .config/** — Completed via Tasks 1 & 2 moves and cleanup; verified 13 destinations intact.

## Files Created/Modified

- `stow/hypr/.config/hypr/custom/env.lua` (renamed from `.config/...`)
- `stow/hypr/.config/hypr/custom/execs.lua` (renamed from `.config/...`)
- `stow/hypr/.config/hypr/custom/general.lua` (renamed from `.config/...`)
- `stow/hypr/.config/hypr/hyprland-gui.conf` (renamed from `.config/...`)
- `stow/hypr/.config/hypr/hyprpaper.conf` (renamed from `.config/...`)
- `restow/hypr/.config/hypr/hypridle.conf` (renamed from `.config/...`)
- `restow/hypr/.config/hypr/hyprlock.conf` (renamed from `.config/...`)
- `restow/hypr/.config/hypr/hyprland/scripts/launch_first_available.sh` (renamed from `.config/...`)
- `.config/` (removed completely)

## Decisions Made

- Preserved repo version of `launch_first_available.sh` because upstream's `install_dir__sync` destroys local customizations on install; live is byte-identical to upstream vendor.
- Avoided all live symlink operations until Plan 18-11.

## Deviations from Plan

None.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 18-06 complete. Wave 4 and Wave 5 plans executed.
- Next is Wave 6: Plan 18-07 (`capture` fixture assertions) and Plan 18-08 (`restow/starship` split and call sites).

## Self-Check: PASSED

- Mandated `custom/execs.lua` in `stow/hypr/` — FOUND
- `restow/hypr/` configs intact with launcher carrying repo content — VERIFIED
- Repo-root `.config/` gone — VERIFIED (`test ! -e .config`)
- All 13 destination files tracked and present on disk — VERIFIED
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `git status --porcelain` — clean

---
*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Completed: 2026-09-14*
