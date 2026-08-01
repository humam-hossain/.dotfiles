---
phase: 05-fork-submodule-pin
plan: 02
subsystem: infra
tags: [git-submodule, dots-hyprland, nested-shapes, dual-remotes, vendor]

# Dependency graph
requires:
  - phase: 05-01
    provides: Public personal fork humam-hossain/dots-hyprland SSH-ready
provides:
  - ".gitmodules registering vendor/dots-hyprland → fork SSH URL (no branch auto-track)"
  - "vendor/dots-hyprland submodule checkout at fork tip 1a9ffb78"
  - "Nested shapes LICENSE via recursive init (end-4/rounded-polygon-qmljs)"
  - "Dual remotes on vendor: origin SSH fork + upstream HTTPS end-4"
affects:
  - 05-03 parent pin commit
  - Phase 6 thin setup wrapper

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland (no -b)"
    - "git submodule update --init --recursive for OWN-03 shapes"
    - "Local dual remotes inside submodule only (not parent .gitmodules)"

key-files:
  created:
    - .gitmodules
    - vendor/dots-hyprland
  modified: []

key-decisions:
  - "Accepted fork default tip 1a9ffb78 at submodule-add time (D-09/D-10; no force-reset to upstream)"
  - "Deferred parent pin commit to 05-03 (D-11 same-commit rule for .gitmodules + gitlink)"
  - "Nested shapes host left as end-4/rounded-polygon-qmljs (not rewritten)"

patterns-established:
  - "Canonical vendor path only: vendor/dots-hyprland (D-13); sibling clone untouched (D-14)"
  - "Pin-only phase: submodule materialization without ./setup (D-16)"

requirements-completed: [OWN-01, OWN-02, OWN-03]

coverage:
  - id: D1
    description: ".gitmodules registers vendor/dots-hyprland with fork SSH URL and no branch auto-track"
    requirement: OWN-02
    verification:
      - kind: other
        ref: "git config -f .gitmodules --get submodule.vendor/dots-hyprland.url; ! grep -E '^\\s*branch\\s*=' .gitmodules"
        status: pass
    human_judgment: false
  - id: D2
    description: "Outer submodule checkout at fork tip with gitfile (not plain mv)"
    requirement: OWN-02
    verification:
      - kind: other
        ref: "git submodule status vendor/dots-hyprland → 1a9ffb78…"
        status: pass
    human_judgment: false
  - id: D3
    description: "Nested shapes LICENSE present after recursive init; shapes URL end-4/rounded-polygon-qmljs"
    requirement: OWN-03
    verification:
      - kind: other
        ref: "test -f vendor/.../shapes/LICENSE; nested .gitmodules url"
        status: pass
    human_judgment: false
  - id: D4
    description: "Dual remotes inside vendor: origin SSH fork + upstream HTTPS end-4"
    requirement: OWN-01
    verification:
      - kind: other
        ref: "git -C vendor/dots-hyprland remote get-url origin|upstream"
        status: pass
    human_judgment: false

# Metrics
duration: 3min
completed: 2026-07-25
status: complete
---

# Phase 5 Plan 02: Submodule + Nested Shapes + Dual Remotes Summary

**Registered `vendor/dots-hyprland` from personal fork SSH URL, recursive-init nested shapes (LICENSE green), dual remotes configured; parent pin deferred to 05-03**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-07-25T13:10:40Z
- **Completed:** 2026-07-25T13:13:17Z
- **Tasks:** 2/2
- **Files modified:** 2 staged (`.gitmodules`, `vendor/dots-hyprland` gitlink) — not committed (D-11)

## Accomplishments

- `git submodule add git@github.com:humam-hossain/dots-hyprland.git vendor/dots-hyprland` (no `-b`)
- Pin SHA = fork tip `1a9ffb78f0c272a45f82342587dc3bec72762233` (matches 05-01 ls-remote)
- `.gitmodules` url = fork SSH; no `branch =` auto-track line
- Recursive init materialised shapes at `e31ec4cb…` with LICENSE present
- Nested URL remains `https://github.com/end-4/rounded-polygon-qmljs.git`
- Dual remotes: origin `git@github.com:humam-hossain/dots-hyprland.git`, upstream `https://github.com/end-4/dots-hyprland.git`
- Sibling `~/github_repo/dots-hyprland` untouched; no `./setup`; no `arch/dots-hyprland.sh`

## Task Commits

Each task staged artifacts only — parent pin commit is plan 05-03 (D-11):

1. **Task 1: Add vendor/dots-hyprland submodule from fork SSH URL** — staged `.gitmodules` + gitlink (uncommitted by design)
2. **Task 2: Recursive nested init, dual remotes, shapes gate** — local submodule config + nested checkout (dual remotes are local config, not parent tree)

**Plan metadata:** docs commit for this SUMMARY only

## Files Created/Modified

| Path | Role |
|------|------|
| `.gitmodules` | Parent submodule registry (staged) |
| `vendor/dots-hyprland` | Outer submodule checkout + gitlink (staged) |
| `vendor/.../shapes/` | Nested submodule (end-4/rounded-polygon-qmljs) |
| `vendor/dots-hyprland` remotes | origin + upstream (local config) |

## Decisions Made

- D-09/D-10: trusted fork tip at add time; no force-reset to end-4
- D-11: left `.gitmodules` + gitlink staged for single pin commit in 05-03
- D-04/D-07: dual remotes only inside vendor working tree
- D-16: pin-only — setup never executed

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

```
.gitmodules url = git@github.com:humam-hossain/dots-hyprland.git
no branch auto-track
submodule status: 1a9ffb78… vendor/dots-hyprland
shapes LICENSE: present
nested status: e31ec4cb… shapes (no leading -)
origin: git@github.com:humam-hossain/dots-hyprland.git
upstream: https://github.com/end-4/dots-hyprland.git
nested url: end-4/rounded-polygon-qmljs
sibling: present / untouched
setup: not run
```

## Issues Encountered

None.

## Next Phase Readiness

- Ready for 05-03: full OWN-01/02/03 checklist + path-scoped parent pin commit of `.gitmodules` + `vendor/dots-hyprland` only
- Unrelated dirty QML under `.config/quickshell/` must NOT be staged with the pin

## Self-Check: PASSED

- [x] key-files.created exist: `.gitmodules`, `vendor/dots-hyprland`
- [x] shapes LICENSE present
- [x] dual remotes correct
- [x] acceptance criteria for both tasks green
- [x] no setup / no sibling conversion
- [x] pin not half-committed (D-11 deferred)
