---
phase: 10-full-install-impact-inventory
plan: 03
subsystem: inventory
tags: [INV-03, misc, core, fish, fontconfig]

requires:
  - phase: 10-01
    provides: inventory scaffold
  - phase: 10-02
    provides: Axis A complete
provides:
  - Complete Axis B misc/--core impact tables
affects: [10-04, 10-05, phase-11]

actuals:
  tokens: 0
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns: [full misc catalog from find loop, --core SKIP expansion table]

key-files:
  created: []
  modified:
    - .planning/phases/10-full-install-impact-inventory/10-INVENTORY.md

key-decisions:
  - "Full catalog basenames from pin find, not named-four-only"
  - "quickshell explicitly independent of --core"
  - "Host PRESENT collisions called out for fish/kitty/starship/fontconfig/mpv/dolphinrc/kdeglobals"

patterns-established: []

requirements-completed: [INV-03]

coverage:
  - id: D1
    description: Full misc/--core axis with host presence
    requirement: INV-03
    verification:
      - kind: other
        ref: "./scripts/phase10-inventory-assert.sh"
        status: pass
    human_judgment: false

duration: short
completed: 2026-08-04
status: complete
---

# Phase 10: Plan 03 Summary

**Axis B (drop --core) full misc catalog + fish/fontconfig/plasmaintg with host collisions.**

## Accomplishments

- `--core` expansion from options.sh:90 documented
- Full misc basenames from dots/.config find (excl. qs/fish/hypr/fontconfig) + konsole share
- Install modes: dir sync --delete vs file cp vs fish exclude conf.d
- Host PRESENT vs ABSENT filled for catalog

## Self-Check: PASSED

`./scripts/phase10-inventory-assert.sh` exits 0
