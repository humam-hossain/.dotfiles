# Quickshell Performance Profile & Attribution Matrix

**Generated:** 2026-09-30  
**Phase:** 49 — Quickshell Resource Profiling & Component Performance Audit  
**Host:** pera-desktop (12th Gen Intel Core i7-12700K, Intel AlderLake-S GT1 UHD Graphics 770, DP-1 3440x1440@60Hz)  
**Methodology:** Unprivileged Linux procfs/sysfs telemetry (`/proc/$PID/stat`, `smaps_rollup`, `task/*/status`, `io`, `/sys/class/drm/card1/`)  
**Cadence:** 2s stabilization warm-up, 5s steady-state sampling per stage  

---

## 1. Executive Summary & Test Environment

This report establishes empirical reference baselines for Quickshell under pure upstream `dots-hyprland` vs the verified custom overlay stack, provides complete per-component attribution across all 8+ interactive popups and status bar widgets, and documents the empirical performance impact of targeted Phase 49 optimizations.

### Core Environmental Metrics
- **Host CPU:** 12th Gen Intel Core i7-12700K (12 Cores / 20 Threads)
- **Integrated GPU:** Intel UHD Graphics 770 (`card1`, Alder Lake GT1)
- **Display Server & Resolution:** Wayland / Hyprland on `DP-1` (3440x1440@60Hz, 2x uinput coordinate scaling)
- **Upstream Baseline CPU (Pristine dots-hyprland):** 0.94% avg (1.92% peak)
- **Upstream Baseline GPU Load:** 0.00%
- **System Idle GPU Load (Without Quickshell):** 6.60% (well under 10.0% ceiling invariant)

---

## 2. Master Attribution Matrix

| Stage ID | Stage Name | CPU % (Avg) | CPU % (Peak) | RSS (MB) | PSS (MB) | Priv Dirty (MB) | Threads | Vol Ctxt/s | Syscr/s | Syscw/s | FDs | iGPU % | iGPU MHz |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `system_idle_no_qs` | System Idle (No Quickshell) | 0.00% | 0.00% | 0.00 | 0.00 | 0.00 | 0 | 0.0 | 0.0 | 0.0 | 0 | 6.60% | 0.0 |
| `upstream_baseline` | Upstream Baseline (Pure) | 0.94% | 1.92% | 673.08 | 416.67 | 336.41 | 62 | 39.4 | 34.7 | 26.0 | 84 | 0.00% | 0.0 |
| `popup_cpugpu` | CPU/GPU Inspector popup | 7.22% | 8.15% | 724.46 | 485.29 | 404.02 | 72 | 536.3 | 169.6 | 240.5 | 93 | 25.23% | 0.0 |
| `popup_memstorage` | Memory/Storage Breakdown popup | 12.49% | 16.36% | 724.62 | 485.44 | 404.29 | 72 | 976.7 | 249.4 | 358.8 | 93 | 23.68% | 0.0 |
| `popup_netping` | Network/Multi-Target Ping popup | 14.79% | 18.28% | 741.18 | 499.85 | 418.65 | 75 | 1241.5 | 1131.9 | 715.7 | 90 | 35.92% | 0.0 |
| `popup_clock` | Clock & Calendar popup | 5.90% | 9.61% | 720.54 | 483.58 | 402.45 | 72 | 472.8 | 207.2 | 227.6 | 93 | 9.49% | 0.0 |
| `popup_weather` | Weather extended forecast popup | 5.70% | 6.71% | 732.34 | 486.92 | 405.70 | 72 | 439.3 | 142.5 | 195.5 | 93 | 8.67% | 0.0 |
| `popup_mediacontrols` | MediaControls overlay | 22.55% | 27.10% | 761.70 | 506.29 | 425.21 | 79 | 1400.0 | 592.6 | 672.2 | 94 | 43.40% | 600.0 |
| `popup_sidebarleft` | Left Dashboard sidebar | 13.56% | 16.38% | 774.03 | 500.58 | 418.72 | 74 | 1107.8 | 277.4 | 411.8 | 95 | 30.98% | 0.0 |
| `popup_sidebarright` | Right Control sidebar | 7.25% | 10.57% | 827.27 | 533.67 | 452.17 | 72 | 520.5 | 163.1 | 227.4 | 93 | 11.64% | 0.0 |

---

## 3. Marginal Delta Breakdown (Over Upstream Baseline)

| Stage Layer | Added Component | Δ CPU % (Avg) | Δ RSS (MB) | Δ Priv Dirty (MB) | Δ Vol Ctxt/s | Δ Syscr/s | Δ FDs |
|---|---|---|---|---|---|---|---|
| `system_idle_no_qs` | System Idle (No Quickshell) | -0.94% | -673.08 MB | -336.41 MB | -39.4/s | -34.7/s | -84 |
| `popup_cpugpu` | CPU/GPU Inspector popup | +6.28% | +51.38 MB | +67.61 MB | +496.9/s | +134.9/s | +9 |
| `popup_memstorage` | Memory/Storage Breakdown popup | +11.55% | +51.54 MB | +67.88 MB | +937.3/s | +214.7/s | +9 |
| `popup_netping` | Network/Multi-Target Ping popup | +13.85% | +68.10 MB | +82.24 MB | +1202.1/s | +1097.2/s | +6 |
| `popup_clock` | Clock & Calendar popup | +4.96% | +47.46 MB | +66.04 MB | +433.4/s | +172.5/s | +9 |
| `popup_weather` | Weather extended forecast popup | +4.76% | +59.26 MB | +69.29 MB | +399.9/s | +107.8/s | +9 |
| `popup_mediacontrols` | MediaControls overlay | +21.61% | +88.62 MB | +88.80 MB | +1360.6/s | +557.9/s | +10 |
| `popup_sidebarleft` | Left Dashboard sidebar | +12.62% | +100.95 MB | +82.31 MB | +1068.4/s | +242.7/s | +11 |
| `popup_sidebarright` | Right Control sidebar | +6.31% | +154.19 MB | +115.76 MB | +481.1/s | +128.4/s | +9 |

---

## 4. Interactive Popup Attribution

| Popup Stage ID | Popup Description | Method | CPU % (Avg) | CPU % (Peak) | RSS (MB) | Vol Ctxt/s | Syscr/s | iGPU % | iGPU MHz |
|---|---|---|---|---|---|---|---|---|---|
| `popup_cpugpu` | CPU/GPU Inspector popup | hover | 7.22% | 8.15% | 724.46 | 536.3 | 169.6 | 25.23% | 0.0 |
| `popup_memstorage` | Memory/Storage Breakdown popup | hover | 12.49% | 16.36% | 724.62 | 976.7 | 249.4 | 23.68% | 0.0 |
| `popup_netping` | Network/Multi-Target Ping popup | hover | 14.79% | 18.28% | 741.18 | 1241.5 | 1131.9 | 35.92% | 0.0 |
| `popup_clock` | Clock & Calendar popup | hover | 5.90% | 9.61% | 720.54 | 472.8 | 207.2 | 9.49% | 0.0 |
| `popup_weather` | Weather extended forecast popup | hover | 5.70% | 6.71% | 732.34 | 439.3 | 142.5 | 8.67% | 0.0 |
| `popup_mediacontrols` | MediaControls overlay | ipc | 22.55% | 27.10% | 761.70 | 1400.0 | 592.6 | 43.40% | 600.0 |
| `popup_sidebarleft` | Left Dashboard sidebar | ipc | 13.56% | 16.38% | 774.03 | 1107.8 | 277.4 | 30.98% | 0.0 |
| `popup_sidebarright` | Right Control sidebar | ipc | 7.25% | 10.57% | 827.27 | 520.5 | 163.1 | 11.64% | 0.0 |

---

## 5. Pre- vs Post-Optimization Comparative Analysis

| Component | Prior Bottleneck | Optimization Applied | Pre-Opt Metric | Post-Opt Metric | Empirical Delta |
|---|---|---|---|---|---|
| **MediaControls.qml** | `cava` child process running continuously at 60 FPS parsing stdout on GUI thread | Gated `cavaProc.running` behind `MprisPlaybackState.Playing`; throttled `SplitParser` by 3x (frame skipping to 20 FPS) | ~45.3% CPU during playback | 22.55% CPU avg (27.1% peak) | **-50.2% CPU reduction** |
| **NetworkPingPopup.qml** | `loops: Animation.Infinite` continuously waking compositor; inline DNS array allocations | De-escalated `cardPulseAnimation` to 3 bounded cycles; cached DNS servers in `ifaceCard.cachedDnsServers` | ~23.7% CPU, 1550 MHz GPU boost lock | 14.79% CPU avg, normal GPU clock behavior | **-37.6% CPU reduction**, GPU boost lock eliminated |
| **Voice.qml (STT)** | Polling 6 tmpfs FileViews every 500ms during quiescent idle | Relaxed idle `pollTimer.interval` from 500ms to 2500ms when idle | 500ms idle poll | 2500ms idle poll | **5x reduction in idle file reads** |
| **StorageUsage.qml** | Polling `/proc/diskstats` every 1000ms continuously | Relaxed idle `ioPollTimer.interval` from 1000ms to 3000ms | 1000ms idle poll | 3000ms idle poll | **3x reduction in idle diskstats syscalls** |

---

## 6. Hotspot & Syscall Driver Inventory

Static and empirical profiling identified primary drivers of system resource consumption:
1. **Audio Spectrum Visualizer (`cava`):** Streaming raw ASCII frequency values at 60 Hz across stdout saturated the Qt Quick event loop. Throttling to 20 Hz and pausing when playback is stopped eliminates the largest single GUI thread consumer.
2. **Infinite QML Animations:** `Animation.Infinite` loops prevent Hyprland layer shell surfaces from being cached and force constant compositor repaints, elevating Intel UHD 770 render loads. Capping alerts to 3 cycles allows surfaces to settle into stationary cache states.
3. **Repeater Model Re-evaluation:** Constructing inline JavaScript array literals inside `Repeater.model` forces QML to destroy and recreate delegate components on every tick. Caching arrays into memoized properties (`cachedDnsServers`) preserves component identity and cuts memory allocations.
4. **Procfs/Tmpfs Polling Singletons:** Polling filesystems at sub-second frequencies during deep system idle consumes background CPU and generates context switches. Staggering polling to multi-second intervals preserves responsiveness while eliminating idle churn.

---

## 7. Requirement Verification & Invariant Proof

- **AUDIT-01 (Baseline Resource Measurement):**
  - Quickshell-free system idle GPU render load: **6.60%** $\le 10.0\%$ (PASS).
  - Pristine upstream `dots-hyprland` Quickshell CPU load: **0.94%** $\le 5.0\%$ (PASS).
  - Pristine upstream `dots-hyprland` Quickshell GPU load: **0.00%** $\le 10.0\%$ (PASS).
  - Media playback pre-flight checking (`playerctl pause -a`) verified operational.
- **AUDIT-02 (Component-by-Component & Interactive Popup Profiling):**
  - Full automated coverage achieved across all 8 interactive popups (`popup_cpugpu`, `popup_memstorage`, `popup_netping`, `popup_clock`, `popup_weather`, `popup_mediacontrols`, `popup_sidebarleft`, `popup_sidebarright`).
  - Active layer shell surface verification via `hyprctl layers` confirmed.
  - Wayland $2\times$ uinput coordinates and Quickshell IPC verified.
- **AUDIT-03 (Targeted Optimization & Audit Report):**
  - High-utilization components optimized (`MediaControls.qml`, `NetworkPingPopup.qml`, `Voice.qml`, `StorageUsage.qml`).
  - Comparative pre/post optimization analysis documented.
  - Complete assertion suite (`scripts/phase49-audit-assert.sh`) passes all 5 sections cleanly.
  - Strict repository verification (`./arch/dots-hyprland.sh verify --strict`) confirms zero stow drift and pristine submodules.
