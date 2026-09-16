---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 04
subsystem: infra
tags: [bash, git-mv, archive, restow, redistribution, kde]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    plan: 02
    provides: "stow/, restow/, capture/ and docs/archive contracts"
provides:
  - "docs/config-redistribution.md — canonical operator-facing registry accounting for all 12 .config/ files"
  - "docs/archive/hyprland.conf, hyprland.conf.bak — retired config files in docs/archive/"
  - "restow/dolphinrc/.config/dolphinrc — live KDE config adopted into restow/"
  - "restow/kdeglobals/.config/kdeglobals — live KDE config adopted into restow/"
affects: [18-06, 18-09, 18-11]

# Actuals
actuals:
  tokens: 9500
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-disposition git commits ensuring every move is independently revertible"
    - "Mechanical prefix reconciliation of live destinations against collision map before file moves"

key-files:
  created:
    - docs/config-redistribution.md
    - docs/archive/hyprland.conf
    - docs/archive/hyprland.conf.bak
    - restow/dolphinrc/.config/dolphinrc
    - restow/kdeglobals/.config/kdeglobals
  modified:
    - docs/archive/README.md

key-decisions:
  - "docs/config-redistribution.md reconciles all 12 tracked repo-root .config files against collision-map.tsv"
  - "hyprland.lua reconciliation note records real collision map row with no repo-root move"
  - "hyprland.conf and hyprland.conf.bak moved to docs/archive/ with retiring commit logged"
  - "dolphinrc and kdeglobals moved to restow/ with live content adopted per D-22"
  - "No live symlinks created and no stow run; live linking is owned centrally by plan 18-11"

requirements-completed: [FIX-03]

coverage:
  - id: D1
    description: "docs/config-redistribution.md reconciles all 12 tracked repo-root .config files against collision-map.tsv"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "git ls-files -- .config/ cross-checked against docs/config-redistribution.md"
        status: pass
      human_judgment: false
  - id: D2
    description: "hyprland.conf and hyprland.conf.bak archived in docs/archive/ with provenance recorded"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "test -f docs/archive/hyprland.conf && test -f docs/archive/hyprland.conf.bak"
        status: pass
      human_judgment: false
  - id: D3
    description: "dolphinrc and kdeglobals relocated to restow/ with live KDE state adopted"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "cmp -s ~/.config/dolphinrc restow/dolphinrc/.config/dolphinrc && cmp -s ~/.config/kdeglobals restow/kdeglobals/.config/kdeglobals"
        status: pass
      human_judgment: false

# Metrics
duration: 8 min
completed: 2026-09-14
status: complete
---

# Phase 18 Plan 04: Config Redistribution and Archiving Summary

**Authored `docs/config-redistribution.md` reconciling all 12 `.config/` files against `collision-map.tsv`, archived `hyprland.conf` and `hyprland.conf.bak` into `docs/archive/`, and migrated `dolphinrc` and `kdeglobals` into `restow/` with live KDE content adopted per D-22.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-14T01:07:11Z
- **Completed:** 2026-09-14T01:09:30Z
- **Tasks:** 3
- **Files modified:** 7 (5 created, 2 deleted from repo root, 1 modified)

## Accomplishments

- Created `docs/config-redistribution.md` establishing the complete migration record for all 12 files in repo-root `.config/`. Reconciled all paths against `collision-map.tsv` prefix rules, documented the D-22 content decisions, and added the reconciliation note explaining why `$XDG_CONFIG_HOME/hypr/hyprland.lua` produces a map row with no repo move.
- Archived `.config/hypr/hyprland.conf` and `.config/hypr/hyprland.conf.bak` into `docs/archive/` using `git mv` (recorded as renames in commit `00135a2`). Updated `docs/archive/README.md` with entry rows, retirement rationale, and the note explaining that live `~/.config/hypr/hyprland.conf.old` is an untracked host artifact from the Phase 14 adopt.
- Migrated `.config/dolphinrc` and `.config/kdeglobals` into `restow/dolphinrc/.config/dolphinrc` and `restow/kdeglobals/.config/kdeglobals` via `git mv`. Overwrote the repo copies with live `$HOME/.config/` bytes per decision D-22, adopting real user KDE settings into git as a reviewable diff.
- Adhered strictly to the live-linking precondition: no GNU Stow commands were run and no symlinks were created in `$HOME`, leaving live counterparts as regular files until Plan 18-11 creates links in the main worktree.

## Task Commits

1. **Task 1: Reconcile redistribution table against generated map** — `95137e1` (docs)
2. **Task 2: Archive the two files with no capture future** — `00135a2` (docs)
3. **Task 3: Move dolphinrc and kdeglobals into restow/** — `2f1d30d` (feat)

## Files Created/Modified

- `docs/config-redistribution.md` — canonical redistribution table.
- `docs/archive/hyprland.conf` — archived retired config.
- `docs/archive/hyprland.conf.bak` — archived retired backup.
- `docs/archive/README.md` — updated with table entries and Phase 14 note.
- `restow/dolphinrc/.config/dolphinrc` — restow package with live content.
- `restow/kdeglobals/.config/kdeglobals` — restow package with live content.
- `.config/dolphinrc`, `.config/kdeglobals`, `.config/hypr/hyprland.conf`, `.config/hypr/hyprland.conf.bak` — removed from repo root via `git mv`.

## Decisions Made

- Configured `git config log.follow true` so git log path limiting tracks renames reliably.
- Committed each disposition separately per D-28 to maximize revertibility.

## Deviations from Plan

None.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 18-04 complete. Wave 3 is finished.
- Next is Wave 4: Plan 18-05 (wrapper subcommands `verify` and `capture`, which has a blocking decision checkpoint) and Plan 18-06 (the hypr tree split).

## Self-Check: PASSED

- `docs/config-redistribution.md` — FOUND
- `docs/archive/hyprland.conf` — FOUND
- `docs/archive/hyprland.conf.bak` — FOUND
- `restow/dolphinrc/.config/dolphinrc` — FOUND
- `restow/kdeglobals/.config/kdeglobals` — FOUND
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `git status --porcelain` — clean

---
*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Completed: 2026-09-14*
