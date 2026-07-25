---
phase: 03-system-audio-modules
plan: 01
subsystem: testing
tags: [nyquist, config-assert, wave-0, stdlib-python, bar-05, bar-06, bar-07, bar-08]

requires:
  - phase: 02-core-bar-modules
    provides: phase02-config-assert.py pattern and dual-write live config layout
provides:
  - Wave 0 live-config assert script for BAR-05..08 dual-write keys
  - VALIDATION.md task map with concrete 03-01..03-08 plan/task IDs
affects:
  - 03-02 (dual-write turns assert green)
  - 03-08 (nyquist sign-off)

tech-stack:
  added: []
  patterns:
    - "stdlib Python config assert against ~/.config/illogical-impulse/config.json"
    - "Wave 0 intentionally red until dual-write plan"

key-files:
  created:
    - scripts/phase03-config-assert.py
  modified:
    - .planning/phases/03-system-audio-modules/03-VALIDATION.md

key-decisions:
  - "Split interval dual-write keys: resources.updateInterval=1000, memoryUpdateInterval=3000, diskUpdateInterval=10000"
  - "Assert maxAllowed >= 130 (floor) rather than exact equality"
  - "wave_0_complete true; nyquist_compliant remains false until 03-08"

patterns-established:
  - "Phase 3 Wave 0 harness mirrors Phase 2 phase02-config-assert.py structure"
  - "Per-plan task IDs in VALIDATION map use 03-0N-* wildcards for multi-task plans"

requirements-completed: [BAR-05, BAR-06, BAR-07, BAR-08]

coverage:
  - id: D1
    description: "phase03-config-assert.py encodes all Phase 3 dual-write predicates (thresholds, intervals, alwaysShow, maxAllowed)"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "python3 -m py_compile scripts/phase03-config-assert.py"
        status: pass
      - kind: other
        ref: "python3 scripts/phase03-config-assert.py (expect non-zero pre-dual-write)"
        status: pass
    human_judgment: false
  - id: D2
    description: "03-VALIDATION.md Wave 0 wired with concrete task IDs and documented assert command"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "rg phase03-config-assert|wave_0_complete 03-VALIDATION.md"
        status: pass
    human_judgment: false

duration: 1min
completed: 2026-07-23
status: complete
---

# Phase 3 Plan 01: Wave 0 Config Assert Harness Summary

**Stdlib Python Wave 0 harness asserts Phase 3 dual-write keys (thresholds/intervals/maxAllowed) and wires VALIDATION.md to concrete plan/task IDs — intentionally red until 03-02.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-07-23T09:35:42Z
- **Completed:** 2026-07-23T09:36:52Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Created `scripts/phase03-config-assert.py` (stdlib only) covering D-04/D-05/D-07/D-08/D-13/D-14/D-22 live keys
- Assert exits non-zero on current host config (`cpuWarningThreshold=90` vs want `40`) — red until dual-write
- Wired `03-VALIDATION.md` Per-Task map: 03-01-01/02 harness, 03-02..03-08 plan wildcards; no TBD left
- Set `wave_0_complete: true`; left `nyquist_compliant: false` and `status: draft` for plan 03-08

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 03-01-01 | Create phase03 live config assert script | d3a053f | `scripts/phase03-config-assert.py` |
| 03-01-02 | Wire Wave 0 into VALIDATION.md task map | 3be2093 | `03-VALIDATION.md` |

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None — assert is intentionally red (not a stub); it encodes real predicates and fails on pre-dual-write host values.

## Threat Flags

None beyond plan threat model. Assert mitigates T-03-01 / T-03-03 / T-03-04 baseline encoding; no new network/auth surface.

## Self-Check: PASSED

- FOUND: `scripts/phase03-config-assert.py` (84 lines, shebang, executable)
- FOUND: commit `d3a053f`
- FOUND: commit `3be2093`
- FOUND: `03-VALIDATION.md` with `wave_0_complete: true`, `nyquist_compliant: false`, no TBD task IDs
