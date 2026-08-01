---
phase: 05-fork-submodule-pin
plan: 03
subsystem: infra
tags: [git-submodule, pin-commit, own-checklist, gitlink, dots-hyprland]

# Dependency graph
requires:
  - phase: 05-02
    provides: Staged vendor submodule + nested shapes + dual remotes
provides:
  - "Parent pin commit chore: pin vendor/dots-hyprland submodule (160000 gitlink)"
  - "D-12 OWN-01/02/03 checklist green and idempotent"
affects:
  - Phase 6 thin setup wrapper
  - Future clones of .dotfiles with submodule init

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Path-scoped pin: git add .gitmodules vendor/dots-hyprland only (never git add -A)"
    - "git ls-tree HEAD vendor/dots-hyprland → 160000 commit <40-hex> equals submodule HEAD"

key-files:
  created: []
  modified:
    - .gitmodules
    - vendor/dots-hyprland

key-decisions:
  - "Pin commit 9484ee2 records only .gitmodules + vendor/dots-hyprland (D-11)"
  - "Pin SHA 1a9ffb78 = fork tip at submodule-add time (D-09/D-10)"
  - "Push optional — not required for OWN success"

patterns-established:
  - "Dirty QML under .config/quickshell left unstaged during pin"
  - "Phase 5 closes on D-12 checklist, not on install"

requirements-completed: [OWN-01, OWN-02, OWN-03]

coverage:
  - id: D1
    description: "OWN-01 dual remotes origin SSH fork + upstream HTTPS end-4 inside vendor"
    requirement: OWN-01
    verification:
      - kind: other
        ref: "git -C vendor/dots-hyprland remote get-url origin|upstream"
        status: pass
    human_judgment: false
  - id: D2
    description: "OWN-02 parent gitlink mode 160000 at exact pin SHA with .gitmodules same commit"
    requirement: OWN-02
    verification:
      - kind: other
        ref: "git ls-tree HEAD vendor/dots-hyprland; git show --name-only pin commit"
        status: pass
    human_judgment: false
  - id: D3
    description: "OWN-03 recursive shapes LICENSE present; nested host end-4/rounded-polygon-qmljs"
    requirement: OWN-03
    verification:
      - kind: other
        ref: "test -f .../shapes/LICENSE; nested .gitmodules url"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-07-25
status: complete
---

# Phase 5 Plan 03: Pin Commit + OWN Checklist Summary

**Parent pin `9484ee2` records mode-160000 gitlink at `1a9ffb78`; full OWN-01/02/03 D-12 checklist green and idempotent**

## Performance

- **Duration:** ~5 min (includes commit split fix from staged-index accident)
- **Started:** 2026-07-25T13:13:30Z
- **Completed:** 2026-07-25T13:16:00Z
- **Tasks:** 2/2
- **Files modified:** 2 in pin commit (`.gitmodules`, `vendor/dots-hyprland`)

## Accomplishments

- Pre-commit OWN checklist: remotes, `.gitmodules` url, no branch auto-track, nested LICENSE, exact PIN_SHA match
- Path-scoped pin commit: `chore: pin vendor/dots-hyprland submodule` (`9484ee2`)
  - Paths: `.gitmodules`, `vendor/dots-hyprland` only (no QML)
  - `git ls-tree` → `160000 commit 1a9ffb78f0c272a45f82342587dc3bec72762233`
- Post-commit re-run of full OWN checklist + idempotent recursive update: pin unchanged
- Sibling `~/github_repo/dots-hyprland` untouched; no setup; no install wrapper

## Task Commits

1. **Task 1: Full OWN-01/02/03 checklist** — verification only (no commit)
2. **Task 2: Path-scoped parent pin commit** — `9484ee2` `chore: pin vendor/dots-hyprland submodule`

**Plan metadata:** docs commit for this SUMMARY

_Note: Pin was initially mixed into an accidental docs commit when SUMMARY was written while the index still held submodule-add staging. Fixed with soft-reset split so pin is the clean `chore:` commit with only the two pin paths._

## Files Created/Modified

| Path | Role |
|------|------|
| `.gitmodules` | Committed in pin |
| `vendor/dots-hyprland` | mode-160000 gitlink at 1a9ffb78 |

## Decisions Made

- D-11: single commit for `.gitmodules` + gitlink
- D-12: phase done only when all three OWN checks green
- Dirty tree: left unrelated `.config/quickshell/*.qml` unstaged

## Deviations from Plan

**[Rule 1 - Bugfix] Mixed SUMMARY+pin commit** — Found during: Task 2 close-out after 05-02 SUMMARY commit  
**Issue:** `git commit` after `git add SUMMARY` also took already-staged `.gitmodules` + gitlink into a `docs(05-02)` commit.  
**Fix:** `git reset --soft HEAD~1`, re-stage path-scoped pin, commit `chore: pin…`, then SUMMARY-only docs commit.  
**Files modified:** git history local only (unpushed)  
**Verification:** pin commit name-only = two paths; ls-tree 160000 matches PIN_SHA  
**Commit hash:** `9484ee2` (pin), `4363ca7` (05-02 SUMMARY)

**Total deviations:** 1 auto-fixed (index hygiene). **Impact:** none on machine or OWN outcomes; history cleaned before push.

## Verification Results

```
OWN-01 origin:  git@github.com:humam-hossain/dots-hyprland.git
OWN-01 upstream: https://github.com/end-4/dots-hyprland.git
OWN-02 url:     git@github.com:humam-hossain/dots-hyprland.git
OWN-02 gitlink: 160000 commit 1a9ffb78f0c272a45f82342587dc3bec72762233
OWN-02 pin msg: chore: pin vendor/dots-hyprland submodule
OWN-03 LICENSE: present
OWN-03 nested:  end-4/rounded-polygon-qmljs @ e31ec4cb
Idempotent:     PIN_SHA unchanged after second recursive update
Prohibitions:   no setup, no arch/dots-hyprland.sh, sibling intact
```

## Issues Encountered

Staged-index footgun when committing SUMMARY after `git submodule add` left pin paths staged — recovered by soft-reset split (see deviations).

## Next Phase Readiness

- Phase 5 OWN requirements complete
- Ready for Phase 6 thin setup wrapper (install still out of scope until that phase)
- Unrelated dirty QML remains uncommitted (intentional)

## Self-Check: PASSED

- [x] Pin commit exists with correct message
- [x] ls-tree 160000 matches submodule HEAD
- [x] Pin commit paths only `.gitmodules` + `vendor/dots-hyprland`
- [x] OWN-01/02/03 all green post-commit
- [x] No setup / sibling untouched
