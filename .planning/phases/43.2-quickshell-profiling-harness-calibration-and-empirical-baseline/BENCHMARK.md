# Quickshell Performance Profile & Attribution Matrix

**Generated:** 2026-09-27T15:00:06.175166+00:00  
**Phase:** 43.2  
**Host:** pera-desktop (12th Gen Intel Core i7-12700K, Intel UHD Graphics 770, DP-1 3440x1440@60Hz)  
**Methodology:** Unprivileged Linux procfs/sysfs telemetry (`/proc/$PID/stat`, `smaps_rollup`, `task/*/status`, `io`, `/sys/class/drm/card1/`)  
**Cadence:** 2s stabilization warm-up, 5s steady-state sampling per stage  

---

## 1. Executive Summary & Test Environment

This report establishes empirical reference baselines for Quickshell under pure upstream `dots-hyprland` vs the verified custom overlay stack.

- **Marginal CPU Footprint:** 4.91% (delta: +3.76% over upstream 1.15%)
- **Marginal RSS Footprint:** 542.79 MB (delta: +26.41 MB over upstream 516.38 MB)
- **Process Context Switches:** 383.8/s (delta: +341.6/s over upstream 42.2/s, aggregated across all threads)
- **Read Syscall Churn:** 96.9/s (delta: +61.6/s over upstream 35.3/s)

## 2. Master Attribution Matrix

| Stage ID | Stage Name | CPU % (Avg) | CPU % (Peak) | RSS (MB) | PSS (MB) | Priv Dirty (MB) | Threads | Vol Ctxt/s | Syscr/s | Syscw/s | FDs | iGPU % | iGPU MHz |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `upstream_baseline` | Upstream Baseline (Pure) | 1.15% | 1.92% | 516.38 | 372.48 | 320.41 | 61 | 42.2 | 35.3 | 28.1 | 84 | 64.99% | 1450.0 |
| `full_idle` | Full Shell (Idle) | 4.91% | 7.72% | 542.79 | 413.98 | 361.63 | 74 | 383.8 | 96.9 | 156.3 | 96 | 68.21% | 1550.0 |
| `full_active_popup` | Full Shell (Active UI) | 14.96% | 18.26% | 552.97 | 423.46 | 370.99 | 78 | 1199.2 | 934.1 | 677.9 | 97 | 72.89% | 1550.0 |

## 3. Marginal Delta Breakdown (Over Upstream Baseline)

| Stage Layer | Added Component | Δ CPU % (Avg) | Δ RSS (MB) | Δ Priv Dirty (MB) | Δ Vol Ctxt/s | Δ Syscr/s | Δ FDs |
|---|---|---|---|---|---|---|---|
| `full_idle` | Full Shell (Idle) | +3.76% | +26.41 MB | +41.22 MB | +341.6/s | +61.6/s | +12 |
| `full_active_popup` | Full Shell (Active UI) | +13.81% | +36.59 MB | +50.58 MB | +1157.0/s | +898.8/s | +13 |

## 4. Dual-State UI Comparison (Idle vs Active Inspector)

| Metric | Full Shell (Idle) | Full Shell (Active Popup) | Delta (Interaction Cost) |
|---|---|---|---|
| CPU Utilization (Avg) | 4.91% | 14.96% | +10.05% |
| Memory RSS | 542.79 MB | 552.97 MB | +10.18 MB |
| Private Dirty Memory | 361.63 MB | 370.99 MB | +9.36 MB |
| Voluntary Context Switches | 383.8/s | 1199.2/s | +815.4/s |
| Read Syscalls | 96.9/s | 934.1/s | +837.2/s |
| Open File Descriptors | 96 | 97 | +1 |

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
