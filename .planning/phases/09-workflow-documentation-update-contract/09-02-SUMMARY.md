---
phase: 09-workflow-documentation-update-contract
plan: 02
subsystem: docs
tags: [dots-hyprland, playbook, DOC-02, pin-bump, non-goals]

requires:
  - phase: 09-workflow-documentation-update-contract
    provides: 09-01 Install/Adopt playbook skeleton and DOC-01 body
provides:
  - pin-bump primary update contract
  - non-goals: exp-merge, online cache, auto-bump, cutover, hypr takeover
affects:
  - 09-03 (cross-links; full DOC suite greps)

tech-stack:
  added: []
  patterns:
    - "Pin-bump as sole primary update; experimental paths table-adjacent"

key-files:
  created: []
  modified:
    - docs/dots-hyprland-workflow.md

key-decisions:
  - "Primary update is fork fetch/merge → parent gitlink → wrapper re-run"
  - "exp-merge and ~/.cache/dots-hyprland explicitly non-primary"

patterns-established:
  - "DOC-02 non-goals as table next to pin-bump (cannot miss)"

requirements-completed: [DOC-02]

coverage:
  - id: D1
    description: "Pin-bump update: fetch upstream, git add vendor pin, re-run wrapper"
    requirement: DOC-02
    verification:
      - kind: other
        ref: "rg 'fetch upstream'; rg 'git add vendor/dots-hyprland'; rg install-files"
        status: pass
    human_judgment: false
  - id: D2
    description: "exp-merge and online cache marked non-primary"
    requirement: DOC-02
    verification:
      - kind: other
        ref: "rg exp-merge; rg non-primary; rg cache"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-08-01
status: complete
---

# Phase 09: Plan 02 — Update Contract & Non-goals Summary

**Playbook now documents pin-bump as primary update and demotes exp-merge / online cache (DOC-02).**

## Accomplishments

- §5 pin-bump: fetch upstream, merge/rebase, push origin, parent gitlink commit, re-run install/install-files with gate
- §6 non-goals table: exp-merge, online cache, auto-bump, Waybar cutover, hyprland.lua, package reimplementation, POLISH-01
- DOC-01 install greps still pass on same file

## Task Commits

| Task | Commit | Message |
|------|--------|---------|
| 1–2 Update + non-goals | `3b324e4` | docs(09-02): document pin-bump update and non-goals |

## Deviations from Plan

None material — tasks 1–2 committed together on the single playbook file (same pattern as 09-01 resume).

## Self-Check: PASSED

- `fetch upstream`, `git add vendor/dots-hyprland`, re-run `./arch/dots-hyprland.sh` — pass
- `exp-merge` + non-primary language + cache — pass
- DOC-01 markers (`install --dry-run`, `qs -c ii`) preserved — pass
