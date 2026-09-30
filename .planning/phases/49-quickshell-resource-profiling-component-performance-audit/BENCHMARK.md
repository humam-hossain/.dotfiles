# Quickshell Performance Profile & Attribution Matrix

**Generated:** 2026-09-30T09:26:01.115624+00:00  
**Phase:** 49  
**Host:** pera-desktop (12th Gen Intel Core i7-12700K, Intel UHD Graphics 770, DP-1 3440x1440@60Hz)  
**Methodology:** Unprivileged Linux procfs/sysfs telemetry (`/proc/$PID/stat`, `smaps_rollup`, `task/*/status`, `io`, `/sys/class/drm/card1/`)  
**Cadence:** 2s stabilization warm-up, 5s steady-state sampling per stage  

---

## 1. Executive Summary & Test Environment

This report establishes empirical reference baselines for Quickshell under pure upstream `dots-hyprland` vs the verified custom overlay stack.

- **Marginal CPU Footprint:** 0.00% (delta: -0.94% over upstream 0.94%)
- **Marginal RSS Footprint:** 0.00 MB (delta: -673.08 MB over upstream 673.08 MB)
- **Process Context Switches:** 0.0/s (delta: -39.4/s over upstream 39.4/s, aggregated across all threads)
- **Read Syscall Churn:** 0.0/s (delta: -34.7/s over upstream 34.7/s)

## 2. Master Attribution Matrix

| Stage ID | Stage Name | CPU % (Avg) | CPU % (Peak) | RSS (MB) | PSS (MB) | Priv Dirty (MB) | Threads | Vol Ctxt/s | Syscr/s | Syscw/s | FDs | iGPU % | iGPU MHz |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `system_idle_no_qs` | System Idle (No Quickshell) | 0.0% | 0.0% | 0.0 | 0.0 | 0.0 | 0 | 0.0 | 0.0 | 0.0 | 0 | 6.6% | 0.0 |
| `upstream_baseline` | Upstream Baseline (Pure) | 0.94% | 1.92% | 673.08 | 416.67 | 336.41 | 62 | 39.4 | 34.7 | 26.0 | 84 | 0.0% | 0.0 |
| `popup_cpugpu` | CPU/GPU Inspector popup | 7.22% | 8.15% | 724.46 | 485.29 | 404.02 | 72 | 536.3 | 169.6 | 240.5 | 93 | 25.23% | 0.0 |
| `popup_memstorage` | Memory/Storage Breakdown popup | 12.49% | 16.36% | 724.62 | 485.44 | 404.29 | 72 | 976.7 | 249.4 | 358.8 | 93 | 23.68% | 0.0 |
| `popup_netping` | Network/Multi-Target Ping popup | 14.42% | 16.35% | 726.48 | 485.25 | 404.15 | 72 | 1132.7 | 1073.7 | 700.0 | 93 | 24.11% | 0.0 |
| `popup_clock` | Clock & Calendar popup | 5.9% | 9.61% | 720.54 | 483.58 | 402.45 | 72 | 472.8 | 207.2 | 227.6 | 93 | 9.49% | 0.0 |
| `popup_weather` | Weather extended forecast popup | 5.7% | 6.71% | 732.34 | 486.92 | 405.7 | 72 | 439.3 | 142.5 | 195.5 | 93 | 8.67% | 0.0 |
| `popup_mediacontrols` | MediaControls overlay | 22.8% | 24.06% | 734.76 | 499.48 | 417.1 | 74 | 1520.9 | 531.9 | 658.6 | 99 | 29.02% | 650.0 |
| `popup_sidebarleft` | Left Dashboard sidebar | 13.56% | 16.38% | 774.03 | 500.58 | 418.72 | 74 | 1107.8 | 277.4 | 411.8 | 95 | 30.98% | 0.0 |
| `popup_sidebarright` | Right Control sidebar | 7.25% | 10.57% | 827.27 | 533.67 | 452.17 | 72 | 520.5 | 163.1 | 227.4 | 93 | 11.64% | 0.0 |

## 3. Marginal Delta Breakdown (Over Upstream Baseline)

| Stage Layer | Added Component | Δ CPU % (Avg) | Δ RSS (MB) | Δ Priv Dirty (MB) | Δ Vol Ctxt/s | Δ Syscr/s | Δ FDs |
|---|---|---|---|---|---|---|---|
| `system_idle_no_qs` | System Idle (No Quickshell) | +-0.94% | +-673.08 MB | +-336.41 MB | +-39.4/s | +-34.7/s | +-84 |
| `popup_cpugpu` | CPU/GPU Inspector popup | +6.28% | +51.38 MB | +67.61 MB | +496.9/s | +134.9/s | +9 |
| `popup_memstorage` | Memory/Storage Breakdown popup | +11.55% | +51.54 MB | +67.88 MB | +937.3/s | +214.7/s | +9 |
| `popup_netping` | Network/Multi-Target Ping popup | +13.48% | +53.4 MB | +67.74 MB | +1093.3/s | +1039.0/s | +9 |
| `popup_clock` | Clock & Calendar popup | +4.96% | +47.46 MB | +66.04 MB | +433.4/s | +172.5/s | +9 |
| `popup_weather` | Weather extended forecast popup | +4.76% | +59.26 MB | +69.29 MB | +399.9/s | +107.8/s | +9 |
| `popup_mediacontrols` | MediaControls overlay | +21.86% | +61.68 MB | +80.69 MB | +1481.5/s | +497.2/s | +15 |
| `popup_sidebarleft` | Left Dashboard sidebar | +12.62% | +100.95 MB | +82.31 MB | +1068.4/s | +242.7/s | +11 |
| `popup_sidebarright` | Right Control sidebar | +6.31% | +154.19 MB | +115.76 MB | +481.1/s | +128.4/s | +9 |

## 4. Dual-State UI Comparison (Idle vs Active Inspector)

| Metric | Full Shell (Idle) | Full Shell (Active Popup) | Delta (Interaction Cost) |
|---|---|---|---|

## 5. Interactive Popup Attribution

| Popup Stage ID | Popup Description | Method | CPU % (Avg) | CPU % (Peak) | RSS (MB) | Vol Ctxt/s | Syscr/s | iGPU % | iGPU MHz |
|---|---|---|---|---|---|---|---|---|---|
| `popup_cpugpu` | CPU/GPU Inspector popup | hover | 7.22% | 8.15% | 724.46 | 536.3 | 169.6 | 25.23% | 0.0 |
| `popup_memstorage` | Memory/Storage Breakdown popup | hover | 12.49% | 16.36% | 724.62 | 976.7 | 249.4 | 23.68% | 0.0 |
| `popup_netping` | Network/Multi-Target Ping popup | hover | 14.42% | 16.35% | 726.48 | 1132.7 | 1073.7 | 24.11% | 0.0 |
| `popup_clock` | Clock & Calendar popup | hover | 5.9% | 9.61% | 720.54 | 472.8 | 207.2 | 9.49% | 0.0 |
| `popup_weather` | Weather extended forecast popup | hover | 5.7% | 6.71% | 732.34 | 439.3 | 142.5 | 8.67% | 0.0 |
| `popup_mediacontrols` | MediaControls overlay | ipc | 22.8% | 24.06% | 734.76 | 1520.9 | 531.9 | 29.02% | 650.0 |
| `popup_sidebarleft` | Left Dashboard sidebar | ipc | 13.56% | 16.38% | 774.03 | 1107.8 | 277.4 | 30.98% | 0.0 |
| `popup_sidebarright` | Right Control sidebar | ipc | 7.25% | 10.57% | 827.27 | 520.5 | 163.1 | 11.64% | 0.0 |

## 6. Hotspot & Syscall Driver Inventory

Static analysis of QML components identifies key sources of syscall churn and thread wakeup:
- **ResourceUsage.qml (1ms anomaly):** The polling loop was configured with `interval: 1` instead of `interval: 1000`, causing ~1,000 wakeups per second checking `/proc/stat` and `/proc/meminfo`.
- **HardwareTelemetry.qml (31 FileViews):** Continuously samples 23 hwmon sensor inputs, cpufreq frequencies, and GPU sysfs stats every 3 seconds (accelerating to 1s when popups are active).
- **Voice STT (Voice.qml):** Polls 6 tmpfs FileViews every 500ms.

## 7. Evidence-Based Optimization Roadmap (Phases 44–46)

Based on the attribution matrix, the following actionable optimizations are recommended:
1. **Phase 44 (Memory & Storage Telemetry):**
   - Resolve the 1ms timer anomaly in `ResourceUsage.qml` by aligning interval to 1000ms.
   - Consolidate memory calculation routines into a single unified telemetry pass.
2. **Phase 45 (Network & Latency Telemetry):**
   - Implement dynamic idle backoff for `PingService.qml` when network state is stable.
3. **Phase 46 (Left Zone Bar Optimization):**
   - Optimize `HardwareTelemetry` thermal sweeping by staggering individual sensor FileView reads.
