---
phase: "50"
plan: "50-01"
subsystem: ui-performance
tags: [quickshell, qml, performance, telemetry, idle-coalescing, timers]

requires:
  - phase: "49"
    provides: "Resource profiling harness scripts/profile-quickshell.sh and empirical audit ceilings"
provides:
  - "Phase 50 5-section validation harness scripts/phase50-opt-assert.sh"
  - "Coalesced 5000ms quiescent idle telemetry cadence across ResourceUsage, HardwareTelemetry, and StorageUsage"
  - "Central bar hover and inspector rate coordination bridge in GlobalStates and BarContent"
affects:
  - "50-02"
  - "50-03"
  - "50-04"

actuals:
  tokens: 1250
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Centralized fastTelemetryRate boolean bridge in GlobalStates driven by HoverHandler and inspector counter"
    - "5000ms idle / 1000ms active dual-cadence timer pattern across telemetry singletons"

key-files:
  created:
    - scripts/phase50-opt-assert.sh
  modified:
    - restow/quickshell/.config/quickshell/ii/GlobalStates.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
    - restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml
    - restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml
    - restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml

key-decisions:
  - "D-50-01: Coalesced background telemetry polling to 5000ms during stationary quiescent idle, demand-gated to 1000ms on bar hover or active inspector popup"
  - "D-50-10: Created scripts/phase50-opt-assert.sh supporting 5 sections, non-root fail-close guard, AST checks, and porcelain drift detection"

patterns-established:
  - "Fast-telemetry rate coordination: GlobalStates.fastTelemetryRate evaluates barHovered || activeInspectorCount > 0"

requirements-completed:
  - "OPT-01"
  - "OPT-05"

coverage:
  - id: D1
    description: "Wave 0 phase50-opt-assert.sh assertion harness scaffolded with 5 sections and fail-closed non-root checks"
    requirement: "OPT-05"
    verification:
      - kind: unit
        ref: "bash scripts/phase50-opt-assert.sh -s 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Coalesced 5000ms quiescent idle telemetry cadence and bar hover coordination in GlobalStates, BarContent, HardwareTelemetry, ResourceUsage, and StorageUsage"
    requirement: "OPT-01"
    verification:
      - kind: unit
        ref: "bash scripts/phase50-opt-assert.sh -s 2"
        status: pass
    human_judgment: false

duration: 5 min
completed: 2026-09-30
status: complete
---

# Phase 50 Plan 01: Assertion Test Harness Scaffold & Quiescent Idle Footprint / Coalesced 5s Heartbeat Summary

**Coalesced 5000ms quiescent idle telemetry cadence with demand-gated 1000ms bar hover acceleration and Wave 0 automated assertion harness.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-09-30T19:46:00Z
- **Completed:** 2026-09-30T19:51:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Implemented `scripts/phase50-opt-assert.sh` supporting 5 sections, non-root fail-closed verification, AST greps, and porcelain integrity checks.
- Established coordinated `barHovered`, `activeInspectorCount`, and `fastTelemetryRate` in `GlobalStates.qml`.
- Integrated `HoverHandler` in `BarContent.qml` to drive `GlobalStates.barHovered`.
- Coalesced idle timers to 5000ms across `HardwareTelemetry.qml` (1000ms active / 5000ms idle), `ResourceUsage.qml` (1000ms active / 5000ms idle), and `StorageUsage.qml` (5000ms idle diskstats).
- Restowed `quickshell` cleanly with GNU Stow and passed Section 1 and Section 2 assertions.

## Task Commits

1. **Task 1: Wave 0 Assertion Suite Scaffold (scripts/phase50-opt-assert.sh)** - `c11b9a27` (feat)
2. **Task 2: Coordinated Idle Telemetry Cadence & Bar Hover Handler** - `7e6a73d2` (feat)

**Plan metadata:** Pending docs commit

## Files Created/Modified

- `scripts/phase50-opt-assert.sh` - 5-section validation harness enforcing Phase 50 performance ceilings, timer coalescing, and AST invariants.
- `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` - Added `barHovered`, `activeInspectorCount`, and `fastTelemetryRate`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` - Added top status bar `HoverHandler`.
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` - Coalesced 5000ms idle timer and bound `fastPolling` to `GlobalStates.fastTelemetryRate`.
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` - Coalesced 5000ms idle timer and bound `Connections` to `GlobalStates.fastTelemetryRate`.
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` - Coalesced `ioPollTimer` to 5000ms.

## Decisions Made

- D-50-01: Coalesced quiescent background telemetry polling to 5000ms to eliminate uncoordinated wakeups and enable CPU C-states, switching dynamically to 1000ms only when hovered or an inspector is open.
- D-50-10: Created `scripts/phase50-opt-assert.sh` mirroring `scripts/phase49-audit-assert.sh` structure for fail-closed regression enforcement.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 50-01 is complete; ready to proceed to Wave 2 (Plans 50-02 and 50-03).
