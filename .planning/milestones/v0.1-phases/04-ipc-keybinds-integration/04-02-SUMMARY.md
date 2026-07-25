---
phase: 04-ipc-keybinds-integration
plan: 02
subsystem: ipc
tags: [ipc-01, bar, uat, qs-ipc]

requires:
  - phase: 04-01
    provides: "phase04-ipc-reload-assert.py Wave 0 harness"
provides:
  - "IPC-01 automated open/close/toggle exit 0 + human multi-monitor UAT"
  - "04-UAT.md CLI contract for stock bar IPC"
affects:
  - 04-03 (post-reload IPC reuses same CLI)

tech-stack:
  added: []
  patterns:
    - "Stock qs ipc call bar {open,close,toggle} on default config (no -c ii)"

key-files:
  created:
    - .planning/phases/04-ipc-keybinds-integration/04-UAT.md
  modified:
    - .planning/phases/04-ipc-keybinds-integration/04-VALIDATION.md

key-decisions:
  - "No product QML edits — automated and human green on stock IpcHandler"
  - "Judge Quickshell bar only under dual Waybar run"

patterns-established:
  - "Phase 4 UAT lives in 04-UAT.md with automated evidence + human pass rows"

requirements-completed: [IPC-01]

coverage:
  - id: D1
    description: "Live bar open/close/toggle exit 0"
    requirement: IPC-01
    verification:
      - kind: other
        ref: "qs ipc call bar close/open/toggle exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Multi-monitor visual hide/show/toggle"
    requirement: IPC-01
    verification:
      - kind: other
        ref: "04-UAT.md IPC-01 human rows pass"
        status: pass
    human_judgment: true

duration: 15min
completed: 2026-07-25
status: complete
---

# Phase 4 Plan 02: IPC-01 Bar Show/Hide Summary

**Stock `qs ipc call bar {close,open,toggle}` proven automated and human-approved on all active monitors.**

## Accomplishments

- Ran Wave 0 harness green; live open/close/toggle each exit 0 against default `shell.qml` (PID 63412).
- Created `04-UAT.md` with prescriptive CLI contract (default config, bare qs, QS-only visual judgment).
- Updated VALIDATION IPC-01 automated rows to green; multi-monitor human UAT **approved** 2026-07-25.
- No Bar.qml / hyprland.conf product edits (D-13).

## Task Commits

1. **Task 1: Automated IPC-01 proof + CLI contract** — `docs(04-02): IPC-01 CLI contract UAT + automated green rows`
2. **Task 2: Human multi-monitor UAT** — `docs(04-02): record human multi-monitor IPC-01 UAT pass`

## Self-Check: PASSED

- FOUND: 04-UAT.md with ipc call bar open|close|toggle
- FOUND: human IPC-01 rows **pass**
- FOUND: single IpcHandler target bar in Bar.qml
- Live: assert + open/close/toggle exit 0
