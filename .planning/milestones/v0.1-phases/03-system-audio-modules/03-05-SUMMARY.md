---
phase: 03-system-audio-modules
plan: 05
subsystem: services
tags: [ResourceUsage, disk, df, multi-rate, formatBytes, BAR-05, BAR-06, BAR-07, D-08, D-14, D-15]

requires:
  - phase: 03-system-audio-modules
    provides: Config.qml resources intervals (updateInterval/memoryUpdateInterval/diskUpdateInterval) from 03-02
provides:
  - ResourceUsage diskTotal/diskAvail/diskUsed/diskUsedPercentage for root /
  - formatBytes + memoryUsedTotalString/diskFreeTotalString capacity labels
  - Multi-rate poll CPU ~1s / RAM ~3s / disk ~10s without df spam
affects:
  - 03-06 (Resources strip binds disk + capacity strings)
  - 03-08 (nyquist verification of service props)

tech-stack:
  added: []
  patterns:
    - "Process argv + LANG=C + StdioCollector for df -B1 metrics"
    - "Single base Timer with elapsed counters for multi-rate CPU/RAM/disk"

key-files:
  created: []
  modified:
    - .config/quickshell/services/ResourceUsage.qml

key-decisions:
  - "df argv form [\"df\",\"-B1\",\"--output=size,used,avail,pcent\",\"/\"] (no bash -c); host verified"
  - "diskUsed set from df used column (not total-avail) for accurate reserved-block used%"
  - "Elapsed-counter multi-rate on one Timer rather than three Timers"

patterns-established:
  - "refreshDisk toggles Process.running false→true to re-exec df"
  - "History updates only on the metric that refreshed (CPU vs memory/swap)"

requirements-completed: [BAR-05, BAR-06, BAR-07]

coverage:
  - id: D1
    description: "diskTotal/diskAvail/diskUsed/diskUsedPercentage for root / via df Process"
    requirement: BAR-07
    verification:
      - kind: other
        ref: "rg -n 'diskUsedPercentage|df |diskTotal|diskAvail' .config/quickshell/services/ResourceUsage.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: "formatBytes auto G/T + RAM/disk capacity strings for bar labels"
    requirement: BAR-06
    verification:
      - kind: other
        ref: "rg -n 'formatBytes|memoryUsedTotalString|diskFreeTotalString' .config/quickshell/services/ResourceUsage.qml"
        status: pass
    human_judgment: false
  - id: D3
    description: "Multi-rate poll updateInterval/memoryUpdateInterval/diskUpdateInterval; df not every 1s"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "rg -n 'memoryUpdateInterval|diskUpdateInterval|updateInterval|diskElapsedMs' .config/quickshell/services/ResourceUsage.qml"
        status: pass
    human_judgment: false
  - id: D4
    description: "Quickshell loads ResourceUsage with disk + multi-rate without hard errors"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "timeout 4 quickshell → Configuration Loaded"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-07-23
status: complete
---

# Phase 03 Plan 05: ResourceUsage Disk + Multi-rate Summary

**ResourceUsage singleton exposes root-/ disk metrics via df -B1, formatBytes G/T labels, and multi-rate CPU~1s / RAM~3s / disk~10s polling**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-23T10:25:33Z
- **Completed:** 2026-07-23T10:27:33Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Disk props (`diskTotal`, `diskAvail`, `diskUsed`, `diskUsedPercentage`) for root `/` only
- `Process` `df -B1 --output=size,used,avail,pcent /` with `LANG=C` / `LC_ALL=C` argv form
- `formatBytes` auto human G/T; `memoryUsedTotalString` and `diskFreeTotalString` for bar
- Multi-rate timer: CPU every `updateInterval` (~1s), RAM every `memoryUpdateInterval` (~3s), disk every `diskUpdateInterval` (~10s)
- Swap props retained for future detail UI (bar strip hides later)

## Task Commits

Each task was committed atomically:

1. **Task 1: Disk properties + df Process for root /** - `b68103c` (feat)
2. **Task 2: Multi-rate poll (CPU ~1s, RAM ~3s, disk ~10s)** - `5a9bd66` (feat)

**Plan metadata:** `6317f5e` (docs: complete plan)

## Files Created/Modified
- `.config/quickshell/services/ResourceUsage.qml` - Disk metrics, formatBytes, multi-rate poll

## Decisions Made
- Prefer argv `["df","-B1","--output=size,used,avail,pcent","/"]` over bash -c (works on host; matches Network.qml Process pattern)
- Store `diskUsed` from df used column so reserved blocks do not inflate ring percentage
- Single Timer + elapsed counters for multi-rate (D-08/D-14) instead of three Timers

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None during planned work. Pre-existing `ToolbarTabBar.qml` TypeError warnings on quickshell smoke are out of scope (unrelated dirty files).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ResourceUsage ready for 03-06 Resources strip to bind CPU/RAM/Disk rings + free/total labels
- Interval keys already dual-written by 03-02

## Self-Check: PASSED
- FOUND: `.config/quickshell/services/ResourceUsage.qml` with diskUsedPercentage, formatBytes, df, multi-rate keys
- FOUND: commits `b68103c`, `5a9bd66`
- FOUND: Configuration Loaded on smoke

---
*Phase: 03-system-audio-modules*
*Completed: 2026-07-23*
