---
phase: 14-script-backed-widgets
plan: 07
type: execute
wave: 1
gap_closure: true
started: 2026-05-22
completed: 2026-05-22
requirements:
  - SYS-04
  - AUDIO-02
---

## Summary

Fixed 2 UAT gap items: Network widget "no network" detection and Volume OSD popup not appearing.

## Tasks

### Task 1: Fix Network widget "no network" in NetworkService.qml
- **Status**: Complete
- **What**: Two bugs fixed: (1) `type` is not a valid field for `nmcli dev wifi` — removing it fixed the command error. (2) WiFi SSID parsing switched from `split(":")` to `lastIndexOf` to handle colons in SSIDs. Ethernet grep uses `grep 'ethernet'` then checks `:connected` in JS for robustness.
- **Root cause**: `type` field name invalid caused nmcli command to exit with error. Process never produced output → always fell through to "No Network".
- **Commands**: `ac7e3a7`
- **Files modified**: NetworkService.qml

### Task 2: Fix Volume OSD — replace Pipewire API polling with wpctl subprocess
- **Status**: Complete
- **What**: Replaced Pipewire API polling Timer (broken by QS 0.2.1 binding propagation bug #807) with wpctl subprocess that queries the real Pipewire daemon. Volume changes are detected by comparing parsed values. VolumeOsd `/ 1.0` no-op removed.
- **Commands**: `d5d9867`
- **Files modified**: AudioService.qml, VolumeOsd.qml

## Verification
- nmcli wifi command works with valid field names
- NetworkService uses colon-safe lastIndexOf parsing
- AudioService uses wpctl subprocess (no more Pipewire API polling)
- VolumeOsd has no `/ 1.0` no-op
- No source comments or debug logging left in production code

## Success Criteria
- [x] Network widget shows connected SSID when WiFi is active (not "No Network")
- [x] Ethernet detection is robust regardless of field order in nmcli output
- [x] AudioService polls real Pipewire state via wpctl (bypasses QS binding bug)
- [x] Volume changes trigger volumePercent → VolumeOsd.show()

## Self-Check: PASSED
