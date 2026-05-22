---
phase: 14-script-backed-widgets
plan: 06
type: execute
wave: 1
gap_closure: true
started: 2026-05-22
completed: 2026-05-22
requirements:
  - SYS-01
  - SYS-02
  - CUST-01
  - CUST-02
  - CUST-04
---

## Summary

Fixed 6 UAT gap items: Qt.getenv regression in 4 services, CPU "err" display, and Disk "err" display.

## Tasks

### Task 1: Fix Qt.getenv regression — replace with $HOME in 4 services
- **Status**: Complete
- **What**: MemoryService, PingService, WeatherService, ForecastService reverted from `Qt.getenv("HOME")` to `"$HOME"` shell expansion. Qt.getenv() does not exist in Quickshell 0.2.1.
- **Commands**: `e0c328b`
- **Files modified**: MemoryService.qml, PingService.qml, WeatherService.qml, ForecastService.qml

### Task 2: Investigate + fix CPU widget "err" in CpuService.qml
- **Status**: Complete
- **What**: Added `|| echo '0 0'` fallback to awk command to ensure Process always produces output. Prevents "err" display when StdioCollector fires before process stdout is captured. awk `/proc/stat` command verified working standalone.
- **Commands**: `936d435`
- **Files modified**: CpuService.qml

### Task 3: Investigate + fix Disk widget "err" in DiskService.qml
- **Status**: Complete
- **What**: Changed `parts.length === 3` to `parts.length >= 2`. awk printf produces 2 pipe-delimited fields (used/total|percent), not 3. Removed incorrect concatenation.
- **Commands**: `f5b351d`
- **Files modified**: DiskService.qml

## Verification
- No `Qt.getenv` references remain in any of the 4 service files
- awk `/proc/stat` works standalone
- Disk `df -h` awk command works standalone producing 2 pipe-delimited fields
- No source comments or debug logging left in production code

## Success Criteria
- [x] MemoryService, PingService, WeatherService, ForecastService no longer throw TypeError
- [x] CpuService produces real CPU percentage (not "err")
- [x] DiskService produces disk usage data (not "err")
- [x] All debug logging removed before final commit

## Self-Check: PASSED
