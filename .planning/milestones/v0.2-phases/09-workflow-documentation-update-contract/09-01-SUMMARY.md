---
phase: 09-workflow-documentation-update-contract
plan: 01
subsystem: docs
tags: [dots-hyprland, playbook, DOC-01, install, dual-run]

requires:
  - phase: 05-fork-submodule-pin
    provides: vendor/dots-hyprland pin + recursive clone contract
  - phase: 06-thin-setup-wrapper-safe-defaults
    provides: arch/dots-hyprland.sh safe defaults + backup gate
  - phase: 07-install-session-hooks-dual-run-verify
    provides: hypr hooks + dual-run expectations
  - phase: 08-retire-local-quickshell-product
    provides: retired arch/quickshell.sh and in-repo QS product
provides:
  - docs/dots-hyprland-workflow.md Install/Adopt SoT (DOC-01)
  - clone → recursive submodule → wrapper install → hooks → dual-run narrative
affects:
  - 09-02 (update/non-goals sections on same playbook)
  - 09-03 (README/PROJECT discovery links)

tech-stack:
  added: []
  patterns:
    - "Single canonical playbook under docs/; wrapper help stays flag SoT"
    - "Procedural bash-block style matching arch/README.md"

key-files:
  created:
    - docs/dots-hyprland-workflow.md
  modified: []

key-decisions:
  - "Canonical playbook path docs/dots-hyprland-workflow.md"
  - "Update/Non-goals left as stubs for 09-02"
  - "arch/quickshell.sh mentioned only as retired"

patterns-established:
  - "DOC-01 install chain as copy-paste bash + short warnings"
  - "DRY flags via ./arch/dots-hyprland.sh help pointer"

requirements-completed: [DOC-01]

coverage:
  - id: D1
    description: "Playbook exists with vendor path + wrapper entry"
    requirement: DOC-01
    verification:
      - kind: other
        ref: "test -f docs/dots-hyprland-workflow.md; rg vendor/dots-hyprland; rg arch/dots-hyprland.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Recursive clone/submodule init documented"
    requirement: DOC-01
    verification:
      - kind: other
        ref: "rg recurse-submodules; rg 'submodule update --init --recursive'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Wrapper dry-run/install, safe defaults, backup gate, hooks, dual-run"
    requirement: DOC-01
    verification:
      - kind: other
        ref: "rg install --dry-run; skip-hyprland; ILLOGICAL_IMPULSE; qs -c ii; waybar; backup"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-08-01
status: complete
---

# Phase 09: Plan 01 — Install/Adopt Playbook Summary

**Canonical operator playbook now documents cold-machine install through dual-run (DOC-01).**

## Performance

- **Duration:** ~15 min (resume after rate-limited subagent; Task 1 already committed)
- **Tasks:** 3/3
- **Files modified:** 1 created

## Accomplishments

- Created `docs/dots-hyprland-workflow.md` with purpose, prerequisites, canonical path
- Documented clone `--recurse-submodules` and repair `git submodule update --init --recursive`
- Documented remotes/pin verify, dry-run → live install, backup gate, hypr hooks, dual-run with waybar

## Task Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 Skeleton | `b507155` | docs(09-01): create dots-hyprland workflow playbook skeleton |
| 2–3 Install body | `e08adbd` | docs(09-01): document clone, wrapper install, hooks, dual-run |

## Deviations from Plan

**[Rule — resume combine] Tasks 2 and 3 single commit** — Found during: resume after rate-limited executor. Task 1 was already committed; remaining section fills were written together and committed once. Content still satisfies all Task 2 and Task 3 acceptance greps.

**Total deviations:** 1 (commit atomicity combine). **Impact:** none on DOC-01 content.

## Self-Check: PASSED

- `test -f docs/dots-hyprland-workflow.md` — pass
- `rg` DOC-01 greps (recurse, dry-run, skip-hyprland, hooks, waybar, backup) — pass
- `arch/quickshell.sh` only in retired framing — pass
- `git log --grep=09-01` includes plan commits — pass
