# Quickshell Performance Profile & Attribution Matrix

**Generated:** 2026-09-30T09:18:41.814853+00:00  
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

## 3. Marginal Delta Breakdown (Over Upstream Baseline)

| Stage Layer | Added Component | Δ CPU % (Avg) | Δ RSS (MB) | Δ Priv Dirty (MB) | Δ Vol Ctxt/s | Δ Syscr/s | Δ FDs |
|---|---|---|---|---|---|---|---|
| `system_idle_no_qs` | System Idle (No Quickshell) | +-0.94% | +-673.08 MB | +-336.41 MB | +-39.4/s | +-34.7/s | +-84 |

## 4. Dual-State UI Comparison (Idle vs Active Inspector)

| Metric | Full Shell (Idle) | Full Shell (Active Popup) | Delta (Interaction Cost) |
|---|---|---|---|

## 5. Hotspot & Syscall Driver Inventory

Static analysis of QML components identifies key sources of syscall churn and thread wakeup:
- **ResourceUsage.qml (1ms anomaly):** The polling loop was configured with `interval: 1` instead of `interval: 1000`, causing ~1,000 wakeups per second checking `/proc/stat` and `/proc/meminfo`.
- **HardwareTelemetry.qml (31 FileViews):** Continuously samples 23 hwmon sensor inputs, cpufreq frequencies, and GPU sysfs stats every 3 seconds (accelerating to 1s when popups are active).
- **Voice STT (Voice.qml):** Polls 6 tmpfs FileViews every 500ms.

## 6. Evidence-Based Optimization Roadmap (Phases 44–46)

Based on the attribution matrix, the following actionable optimizations are recommended:
1. **Phase 44 (Memory & Storage Telemetry):**
   - Resolve the 1ms timer anomaly in `ResourceUsage.qml` by aligning interval to 1000ms.
   - Consolidate memory calculation routines into a single unified telemetry pass.
2. **Phase 45 (Network & Latency Telemetry):**
   - Implement dynamic idle backoff for `PingService.qml` when network state is stable.
3. **Phase 46 (Left Zone Bar Optimization):**
   - Optimize `HardwareTelemetry` thermal sweeping by staggering individual sensor FileView reads.
