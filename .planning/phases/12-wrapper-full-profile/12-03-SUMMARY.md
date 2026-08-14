---
phase: 12-wrapper-full-profile
plan: 03
subsystem: wrapper
tags: [FULL-01, D-04, D-13, usage, help]

requires:
  - phase: 12-wrapper-full-profile
    provides: 12-01 argv + 12-02 full gate
provides:
  - usage() documents --full as primary full path
  - Vendor-outside full-hypr note removed
  - Playbook + INV/DISP discoverability pointers (no process gate)
affects: [12-04, phase-14, phase-15]

actuals:
  tokens: 897
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Help documents wrapper --full as primary full path (D-04)"
    - "Discoverability pointers only — no INV/DISP runtime gate (D-13/D-10)"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh

key-decisions:
  - "D-04: removed vendor-outside full note; --full is documented primary path"
  - "D-13: help points at playbook and 10-INVENTORY / 11-DISPOSITIONS"
  - "D-01: still a meta-flag; no new allowlist subcommand"
  - "D-10: pointers only; run_install_family does not test those artifacts"

patterns-established:
  - "usage() heredoc is the FULL-01 discoverability surface"

requirements-completed: [FULL-01]

coverage:
  - id: D1
    description: help lists --full and no longer tells operators to leave the wrapper for full hypr
    requirement: FULL-01
    verification:
      - kind: other
        ref: "./arch/dots-hyprland.sh help greps for --full and negative vendor-outside note"
        status: pass
    human_judgment: false
  - id: D2
    description: help points at playbook and INV/DISP artifact paths
    requirement: FULL-01
    verification:
      - kind: other
        ref: "help greps dots-hyprland-workflow 10-INVENTORY 11-DISPOSITIONS"
        status: pass
    human_judgment: false

duration: inline
completed: 2026-08-11
status: complete
---

# Phase 12: Plan 03 Summary

**Help documents wrapper --full as the primary full path, with playbook and INV/DISP pointers, and no instruction to call vendor setup outside this wrapper.**

## Performance

- **Tasks:** 2/2
- **Commits:** `b6182a5` (feat); this SUMMARY commit
- **Files modified:** 1 (arch/dots-hyprland.sh)

## Accomplishments

- Rewrote usage() meta-flags to list --full as stripped wrapper-owned opt-in on install / install-files
- Added install --full --dry-run examples; kept safe dry-run examples
- Removed the note that full hypr install requires calling vendor setup outside this wrapper
- Added discoverability pointers to docs/dots-hyprland-workflow.md, 10-INVENTORY.md, and 11-DISPOSITIONS.md
- No runtime test of those artifact paths in run_install_family

## Task Commits

| Task | Commit | Notes |
|------|--------|-------|
| 12-03-01 usage primary path | `b6182a5` | D-04 rewrite |
| 12-03-02 playbook INV/DISP pointers | `b6182a5` | D-13 discoverability only |

## Files Created/Modified

- arch/dots-hyprland.sh — usage() heredoc only

## Decisions Made

- Wording avoided an install-full token so allowlist greps stay honest
- Playbook body not rewritten (Phase 15)

## Deviations from Plan

None — usage() only; argv/gate/protect unchanged.

## Self-Check: PASSED

Re-ran on feat commit b6182a5 / current HEAD (do not assume):

- [x] syntax check on arch/dots-hyprland.sh exits 0
- [x] help exits 0 and contains --full
- [x] help does not contain vendor-outside full note
- [x] help does not say full install must be done outside this wrapper
- [x] examples include install --full --dry-run
- [x] help does not list a new allowlist subcommand for full
- [x] help contains dots-hyprland-workflow, 10-INVENTORY, 11-DISPOSITIONS
- [x] run_install_family has no file-existence gate on those artifacts
