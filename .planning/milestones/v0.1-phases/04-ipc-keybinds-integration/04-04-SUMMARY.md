---
phase: 04-ipc-keybinds-integration
plan: 04
subsystem: planning
tags: [deferred, fwk-02, ipc-02, backlog, hyprland]

requires:
  - phase: 04-01
    provides: "Phase 4 plan set and Wave 0 harness in flight"
provides:
  - "04-DEFERRED.md finishing-touch backlog (FWK-02, IPC-02, Waybar cutover, hard-restart)"
  - "ROADMAP/STATE narrowed pass acceptance notes (SC-2/SC-4 out)"
affects:
  - finishing-touch plan after milestone bar solid

tech-stack:
  added: []
  patterns:
    - "Deferred requirements packaged as explicit backlog docs (not silent omission)"

key-files:
  created:
    - .planning/phases/04-ipc-keybinds-integration/04-DEFERRED.md
  modified:
    - .planning/STATE.md
    - .planning/ROADMAP.md

key-decisions:
  - "Zero hyprland.conf product edits this pass"
  - "FWK-02/IPC-02 covered as deferred IDs via 04-DEFERRED.md"
  - "SC-1/SC-3 in-pass; SC-2/SC-4 out; SC-5 milestone gate"

patterns-established:
  - "Phase finishing-touch backlog lives beside phase plans as 0N-DEFERRED.md"

requirements-completed: [FWK-02, IPC-02]

coverage:
  - id: D1
    description: "FWK-02 and IPC-02 explicitly deferred with finishing-touch notes"
    requirement: FWK-02
    verification:
      - kind: other
        ref: "04-DEFERRED.md mentions FWK-02, IPC-02, exec-once, barToggle"
        status: pass
    human_judgment: false
  - id: D2
    description: "ROADMAP notes SC-2/SC-4 out of this pass; zero hyprland.conf diff"
    requirement: IPC-02
    verification:
      - kind: other
        ref: "rg SC-2|SC-4|04-DEFERRED ROADMAP; git diff hyprland.conf empty"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-25
status: complete
---

# Phase 4 Plan 04: Deferred Finishing-Touch Backlog Summary

**Packaged FWK-02, IPC-02, Waybar cutover, and hard-restart as explicit backlog; no Hyprland or product QML edits.**

## Performance

- **Duration:** ~5 min
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Wrote `04-DEFERRED.md` with IPC-02 keybind options (`global` barToggle vs `qs ipc call bar toggle`), undecided chord, FWK-02 default-config exec-once guidance (not `-c ii`), Waybar cutover, hard-restart notes, and explicit non-actions.
- Confirmed ROADMAP Phase 4 already lists plans 04-01..04-04 and **This pass acceptance** (SC-1/SC-3 in; SC-2/SC-4 deferred).
- Annotated STATE current focus to cite deferred packaging via `04-DEFERRED.md`.
- Verified `git diff -- .config/hypr/hyprland.conf` empty for this plan.

## Task Commits

1. **Task 1: Write 04-DEFERRED.md** — `docs(04-04): package deferred FWK-02/IPC-02 finishing-touch backlog`
2. **Task 2: Annotate ROADMAP/STATE** — `docs(04-04): annotate STATE for narrowed pass + deferred backlog` (ROADMAP already satisfied)

## Self-Check: PASSED

- FOUND: `04-DEFERRED.md` with FWK-02, IPC-02, exec-once, barToggle, Waybar, hard-restart, hyprland.conf zero-edit rule
- FOUND: ROADMAP SC-2/SC-4 out-of-pass wording + 04-0N plan list
- FOUND: no hyprland.conf product diff from this plan
