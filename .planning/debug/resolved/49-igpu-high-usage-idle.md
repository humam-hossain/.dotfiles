---
status: resolved
updated: "2026-10-01T17:30:00+06:00"
---

# Debug Session: High iGPU Usage During Stationary Idle

**Status:** Diagnosed
**Date:** 2026-09-30
**Component:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml`
**Related:** `CpuGpuPill.qml`, `MemoryStoragePill.qml`, `PingService.qml`

## Symptoms
- User reports 20-30% active iGPU load while system is sitting at idle.
- Live measurement confirmed: `rc6_residency_ms` shows 29.12% - 32.60% GPU busy time when Quickshell is running.
- When Quickshell is paused (`kill -STOP $qs_pid`), GPU busy drops immediately to 13.43% (an 19.17% direct delta caused solely by Quickshell).
- Pristine upstream Quickshell baseline without custom overlays showed 0.00% GPU busy, proving the hotspot is inside `restow/quickshell` custom modules.

## Root Cause
In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml`:
1. `PingService.isOffline` defaults to `true` whenever the local ping daemon (`http://127.0.0.1:8765/api/status`) is not running.
2. `root.isCritical` is defined as:
   ```qml
   readonly property bool isCritical: PingService.isOffline ||
       PingService.wanStatus === "critical" || PingService.wanStatus === "dead" ||
       PingService.gatewayStatus === "critical" || PingService.gatewayStatus === "dead" ||
       PingService.homeServerStatus === "critical" || PingService.homeServerStatus === "dead"
   ```
3. `pingPulseAnimation` is bound to `running: root.isCritical` with `loops: Animation.Infinite`:
   ```qml
   SequentialAnimation {
       id: pingPulseAnimation
       running: root.isCritical
       loops: Animation.Infinite
       ParallelAnimation {
           NumberAnimation { target: wanIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
           NumberAnimation { target: wanText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
           NumberAnimation { target: gwIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
           NumberAnimation { target: gwText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
           NumberAnimation { target: srvIcon; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
           NumberAnimation { target: srvText; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
       }
       ParallelAnimation {
           NumberAnimation { target: wanIcon; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
           ...
       }
   }
   ```
4. While Plan 49-03 bounded the pulse animation in `NetworkPingPopup.qml` to 3 cycles, it missed `NetworkPingPill.qml`.
5. Because `PingService.isOffline` is constantly true on systems without the daemon active, `NetworkPingPill.qml` continuously animates 6 UI elements at 60 FPS on the status bar. This forces QtQuick scene graph to re-render and re-composite on every frame, keeping the Intel UHD 770 GPU active at 20-30% load and preventing RC6 sleep residency.

## Evidence Summary
- `card1/power/rc6_residency_ms` with QS active: ~32% busy.
- `card1/power/rc6_residency_ms` with QS paused: ~13% busy.
- `NetworkPingPill.qml:124` has `loops: Animation.Infinite` on a condition that is permanently true at normal idle.

## Files Involved
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPill.qml`: Unbounded infinite pulse animation on offline state.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` & `MemoryStoragePill.qml`: Infinite pulse loops on critical alert states that should be de-escalated to bounded cycles.

## Suggested Fix Direction
1. In `NetworkPingPill.qml`, de-escalate `pingPulseAnimation` from `loops: Animation.Infinite` to bounded `loops: 3` (or settle into static error/warning color when offline) so animations stop after notifying the user, resetting opacity to 1.0.
2. In `CpuGpuPill.qml` and `MemoryStoragePill.qml`, de-escalate pulse animations to bounded `loops: 3` so transient alerts never trigger permanent 60 FPS GPU lockups.
3. Update `scripts/phase49-audit-assert.sh` Section 4 to assert that bar pills contain zero `loops: Animation.Infinite`.
