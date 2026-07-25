---
phase: 04-ipc-keybinds-integration
plan: 01
subsystem: testing
tags: [ipc, soft-reload, qs, wave0, assert-harness, nyquist]

requires:
  - phase: 03-system-metrics-audio
    provides: "Bar shell running on default quickshell/shell.qml with stock IpcHandler"
provides:
  - "scripts/phase04-ipc-reload-assert.py Wave 0 harness (static + live IPC + soft-reload)"
  - "04-VALIDATION.md Wave 0 complete with concrete 04-0N task IDs"
affects:
  - 04-02 (IPC-01 live UAT consumes harness)
  - 04-03 (IPC-03 soft-reload UAT consumes harness)
  - 04-04 (deferred packaging only)

tech-stack:
  added: []
  patterns:
    - "Python 3 stdlib Wave 0 assert (subprocess + pathlib + sys) for live qs CLI"
    - "Mandatory content-change soft-reload probe with try/finally restore + same-PID"

key-files:
  created:
    - scripts/phase04-ipc-reload-assert.py
  modified:
    - .planning/phases/04-ipc-keybinds-integration/04-VALIDATION.md

key-decisions:
  - "Assert-only plan: stock bar IPC + file-watch soft reload; no product QML or hyprland.conf edits"
  - "Soft reload via content append (not mtime-only, not invented qs reload CLI)"
  - "Prefer qs list -j for instance selection; pin --pid only when multiple instances"

patterns-established:
  - "Phase 4 assert success line: ipc/reload asserts OK; fail prefix: ipc/reload assert FAIL"
  - "Section C soft-reload is mandatory before success print"

requirements-completed: [IPC-01, IPC-03]

coverage:
  - id: D1
    description: "Wave 0 assert script encodes static bar IPC + silent reload + barOpen gates"
    requirement: IPC-01
    verification:
      - kind: other
        ref: "python3 -m py_compile scripts/phase04-ipc-reload-assert.py"
        status: pass
      - kind: other
        ref: "python3 scripts/phase04-ipc-reload-assert.py"
        status: pass
    human_judgment: false
  - id: D2
    description: "Live qs ipc show/call bar open + mandatory same-PID soft-reload probe"
    requirement: IPC-03
    verification:
      - kind: other
        ref: "python3 scripts/phase04-ipc-reload-assert.py (Sections B+C)"
        status: pass
    human_judgment: false
  - id: D3
    description: "VALIDATION.md Wave 0 wired with concrete 04-0N task IDs"
    verification:
      - kind: other
        ref: "rg wave_0_complete / 04-0[1-4] in 04-VALIDATION.md"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-07-24
status: complete
---

# Phase 4 Plan 01: IPC + Soft-Reload Wave 0 Harness Summary

**Python stdlib Wave 0 harness proves stock `bar` IPC and same-PID soft reload; VALIDATION.md mapped to concrete 04-0N task IDs.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-07-24T12:28:45Z
- **Completed:** 2026-07-24T12:32:00Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Created `scripts/phase04-ipc-reload-assert.py` with static gates (IpcHandler `bar` + typed void toggle/open/close, `QS_NO_RELOAD_POPUP=1`, `property bool barOpen`), live `qs list` / `qs ipc show` / `qs ipc call bar open`, and mandatory content-change soft-reload probe (same PID + restore + post-reload IPC).
- Live run on host printed `ipc/reload asserts OK` (exit 0) with PID unchanged; probe line fully restored.
- Wired `04-VALIDATION.md`: `wave_0_complete: true`, concrete 04-01..04-04 task map, deferred IPC-02/FWK-02 retained; `nyquist_compliant: false` until later plans + UAT.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create phase04 IPC + soft-reload assert script** - `0b32eb6` (feat)
2. **Task 2: Wire Wave 0 into VALIDATION.md task map** - `209ad93` (docs)

## Files Created/Modified

- `scripts/phase04-ipc-reload-assert.py` — Wave 0 Nyquist harness (static + live + soft-reload)
- `.planning/phases/04-ipc-keybinds-integration/04-VALIDATION.md` — Wave 0 complete + concrete task IDs

## Decisions Made

- Followed plan as specified: assert-only, stock `bar` IPC, no reload CLI invention, no hyprland.conf / product QML edits.
- Used `qs list -j` when available for reliable PID/config path parsing; bare `qs ipc` when single default instance.
- Soft-reload log poll optional; same-PID + restore + post-reload `bar open` always required.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None beyond plan threat model (T-04-01..T-04-04, T-04-SC). Harness only reads QML and briefly probes `shell.qml` with try/finally restore; no new IPC targets or package installs.

## Self-Check: PASSED

- FOUND: `scripts/phase04-ipc-reload-assert.py`
- FOUND: `.planning/phases/04-ipc-keybinds-integration/04-VALIDATION.md`
- FOUND: commit `0b32eb6`
- FOUND: commit `209ad93`
- Live verify: `python3 scripts/phase04-ipc-reload-assert.py` → exit 0 / `ipc/reload asserts OK`
