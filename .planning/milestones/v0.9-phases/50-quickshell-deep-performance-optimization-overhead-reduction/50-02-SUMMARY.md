---
phase: "50"
plan: "50-02"
subsystem: ui-performance
tags: [quickshell, qml, performance, subshell-elimination, procfs, sysfs, ping-service]

requires:
  - phase: "50-01"
    provides: "Assertion harness scripts/phase50-opt-assert.sh and coalesced 5s idle telemetry cadence"
provides:
  - "Subshell elimination across ResourceUsage, StorageUsage, and NetworkUsage"
  - "Direct sysfs and procfs FileView observers for CPU max frequency, routes, DNS, interface states"
  - "In-flight concurrency guard and 2000ms bounded timeout for PingService"
  - "Stabilized fixed-height card geometry and decoupled layout anchors in NetworkPingPopup"
affects:
  - "50-04"

actuals:
  tokens: 1650
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Direct FileView reading of /proc/net/route, /etc/resolv.conf, and /sys/class/net/* replacing heavy bash -c subshells"
    - "Direct argument array subprocess execution without shell wrappers"
    - "Fixed 68px card geometry and non-wrapping labels eliminating scene graph resizing churn in Wayland popups"

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml
    - restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml
    - restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml
    - restow/quickshell/.config/quickshell/ii/services/PingService.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml

key-decisions:
  - "D-50-02: Eliminated recurring bash -c subshells across ResourceUsage (lscpu), StorageUsage (df), and NetworkUsage (probeProcess)"
  - "D-50-07: Implemented direct procfs route parsing and ip -j JSON parsing for network address discovery"
  - "D-50-08: Added isRequestInFlight guard to PingService and fixed NetworkPingPopup geometry to eliminate Intel UHD 770 1550 MHz GPU boost lock"

patterns-established:
  - "Procfs Little-Endian Gateway IP Conversion: parsed 32-bit hex from /proc/net/route into dotted-decimal format"
  - "Geometry decoupling: used anchors.top/left/right instead of anchors.fill inside dynamically sized containers"

requirements-completed:
  - "OPT-03"

coverage:
  - id: D1
    description: "Zero recurring subshell forks across telemetry singletons (ResourceUsage, StorageUsage, NetworkUsage)"
    requirement: "OPT-03"
    verification:
      - kind: unit
        ref: "bash scripts/phase50-opt-assert.sh -s 3"
        status: pass
    human_judgment: false
  - id: D2
    description: "PingService in-flight concurrency guard and stabilized fixed-height card geometry in NetworkPingPopup"
    requirement: "OPT-03"
    verification:
      - kind: integration
        ref: "bash scripts/phase50-opt-assert.sh -s 3"
        status: pass
    human_judgment: false

duration: 6 min
completed: 2026-09-30
status: complete
---

# Phase 50 Plan 02: Subshell Elimination Across Singletons & NetworkPingPopup GPU Boost Lock Elimination Summary

**Eliminated recurring subshell forks across telemetry singletons using native kernel FileViews and stabilized NetworkPingPopup scene graph geometry.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-09-30T19:51:00Z
- **Completed:** 2026-09-30T19:57:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Replaced `lscpu | grep ...` subshell in `ResourceUsage.qml` with direct `FileView` reading `/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`.
- Replaced `bash -c "timeout 3 df -k -P"` in `StorageUsage.qml` with direct argument array execution `["timeout", "3", "df", "-k", "-P"]`.
- Eliminated 100+ line `bash -c` probe script in `NetworkUsage.qml` in favor of direct `/proc/net/route`, `/etc/resolv.conf`, sysfs observers, and direct JSON parsing of `ip -j -4 addr show`.
- Added `isRequestInFlight` concurrency guard and 2000ms XHR timeout to `PingService.qml` to prevent socket starvation.
- Decoupled `anchors.fill: parent` layout loops in `NetworkPingPopup.qml` (`ifaceCard` and `PingDiagnosticCard`), enforced fixed 68px geometry, and disabled text wrapping on "Drops / Errors".
- Restowed `quickshell` and confirmed 100% pass rate in Section 3 of `phase50-opt-assert.sh`.

## Task Commits

1. **Task 1: Subshell Elimination across ResourceUsage, StorageUsage & NetworkUsage** - `7985927a` (feat)
2. **Task 2: PingService In-Flight Guard & NetworkPingPopup GPU Boost Lock Elimination** - `99a18a55` (feat)

**Plan metadata:** Pending docs commit

## Files Created/Modified

- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` - Direct sysfs max CPU frequency observer.
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` - Subshell-free `df` invocation.
- `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml` - Procfs/sysfs native network telemetry engine and direct `ip -j` execution.
- `restow/quickshell/.config/quickshell/ii/services/PingService.qml` - In-flight concurrency guard and 2000ms timeout.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml` - Decoupled card layout anchors and fixed card geometry.

## Decisions Made

- D-50-02: Replaced process forks with direct procfs/sysfs FileViews for zero-latency kernel property observation.
- D-50-07: Converted `/proc/net/route` hex addresses to dotted-decimal in JavaScript to avoid subshells.
- D-50-08: Stabilized `NetworkPingPopup` card geometry to eliminate continuous Wayland surface resize negotiations.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready to proceed to Plan 50-03 (Multimedia, Canvas Clamping & Popup Scenegraph Optimization).
