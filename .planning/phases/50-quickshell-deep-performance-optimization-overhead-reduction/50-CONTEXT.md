# Phase 50: Quickshell Deep Performance Optimization & Overhead Reduction - Context

**Gathered:** 2026-09-30T19:16:00+06:00  
**Status:** Ready for planning  

<domain>
## Phase Boundary

Phase 50 delivers targeted, deep performance optimizations across the Quickshell desktop shell stack based on empirical profiling and bottleneck attribution from Phase 49 (`BENCHMARK.md`).

The scope specifically addresses:
- Driving stationary idle CPU usage down from 5.72% towards upstream baseline 0.94% (target <= 2.0%).
- Reducing voluntary context switches from 453/s to < 100/s and read syscall churn from 169/s to < 50/s via timer coalescing and subshell elimination.
- Optimizing MediaControls active overlay overhead from 24.58% CPU / 25.53% iGPU to <= 10.0% CPU and <= 12.0% iGPU.
- Eliminating recurring subshell invocations (`bash -c`, `lscpu`) across all telemetry singletons.
- Eliminating the Intel UHD 770 1550 MHz GPU boost clock lock in `popup_netping`.
- Clamping Canvas history chart redraws in `CpuGpuPopup` and `MemoryStoragePopup` to 1s telemetry arrival intervals (no 60 FPS redraws).
- Decoupling `ClockWidgetPopup` from per-second text updates and caching `StyledPopup` drop shadows.
- Re-benchmarking all 8 popup stages + idle and publishing updated telemetry in `benchmark-latest.json` and `BENCHMARK.md`.

</domain>

<decisions>
## Implementation Decisions

### 1. Idle Sensor Polling Cadence & Wakeup Coalescing
- **D-50-01:** Implement aggressive power save mode across all telemetry singletons (`HardwareTelemetry.qml`, `ResourceUsage.qml`, `NetworkUsage.qml`, `StorageUsage.qml`, `PingService.qml`). During quiescent idle (no mouse hover on bar, no open popups), relax background sensor polling to a synchronized 5000ms heartbeat. Accelerate polling to 1000ms only when the cursor enters the status bar bounds or when an inspector popup is active. — **Reversibility:** reversible
- **D-50-02:** Completely eliminate all subshell forks (`bash -c`, `lscpu`, `curl`, `df` via shell) in recurring and initialization paths. In `ResourceUsage.qml`, replace `findCpuMaxFreqProc` (`lscpu | grep ...`) with direct sysfs reads (`/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`). In `NetworkUsage.qml`, replace `probeProcess` with sysfs file observers. — **Reversibility:** reversible

### 2. MediaControls & Multimedia Overhead Reduction
- **D-50-03:** Eliminate multi-pass `OpacityMask` and live Gaussian blurs (`StyledBlurEffect`) in `PlayerControl.qml`. Replace with native Qt Quick rounded clipping (`radius` with dark tint overlay), eliminating offscreen FBO render passes. — **Reversibility:** reversible
- **D-50-04:** Downsample `cava` frequency processing from 20 FPS to 12–15 FPS in `MediaControls.qml`, and guarantee the `cava` child process is immediately paused or killed when `mediaControlsLoader.active` becomes false. De-escalate wavy slider physics calculations when not hovered. — **Reversibility:** reversible

### 3. Popup Canvas History Graphs, Clock, and Drop Shadows
- **D-50-05:** In `CpuGpuPopup.qml` and `MemoryStoragePopup.qml`, retain the visual scrolling Canvas history graphs, but strictly clamp `Canvas.requestPaint()` to trigger only once every 1000ms when fresh telemetry data arrives (strictly no 60 FPS repaints). — **Reversibility:** reversible
- **D-50-06:** In `ClockWidgetPopup.qml`, decouple uptime and time formatting from per-second updates, updating only on minute changes. In `StyledPopup.qml`, cache `StyledRectangularShadow` so dynamic content changes inside the popup do not recompute Gaussian drop shadows on the GPU on every frame. — **Reversibility:** reversible

### 4. Network & Ping Telemetry Subshell Elimination & GPU Boost Lock
- **D-50-07:** In `NetworkUsage.qml`, eliminate `probeProcess` (`bash -c`) entirely. Read interface `operstate` and carrier directly via `FileView` from `/sys/class/net/<iface>/`. Cache static interface attributes (MAC, gateway, link speed) upon detection rather than re-probing on every popup open. — **Reversibility:** reversible
- **D-50-08:** In `PingService.qml`, cap XHR polling during popup display to 2000ms (preventing socket churn). Resolve scene graph layout churn in `NetworkPingPopup.qml` to eliminate the 1550 MHz Intel UHD 770 GPU boost clock lock. — **Reversibility:** reversible

### 5. Empirical Re-Benchmarking & Assertion Harness
- **D-50-09:** Execute complete 8-stage interactive popup and idle re-benchmarking via `scripts/profile-quickshell.sh`, assert that quiescent idle CPU is <= 2.0% and iGPU is <= 10.0%, and generate comparative attribution tables in `BENCHMARK.md`. — **Reversibility:** reversible
- **D-50-10:** Extend `scripts/phase49-audit-assert.sh` or create `scripts/phase50-opt-assert.sh` asserting zero recurring subshells, 5s idle timer configurations, and pristine GNU Stow leaf symlinks under `./arch/dots-hyprland.sh verify --strict`. — **Reversibility:** reversible

### the agent's Discretion
- Exact syntax for reading CPU max frequency from `/sys/devices/system/cpu/` vs procfs.
- Caching implementation details for `StyledRectangularShadow` (layer cache vs static pre-rendered asset).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Benchmark & Telemetry Baselines
- `.planning/phases/49-quickshell-resource-profiling-component-performance-audit/BENCHMARK.md` — Complete empirical attribution matrix, hotspot inventory, and pre/post optimization findings from Phase 49.
- `.planning/phases/49-quickshell-resource-profiling-component-performance-audit/benchmark-latest.json` — Machine-readable raw metrics for all 8 popup stages and idle baselines.

### Telemetry & Resource Singletons
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` — CPU, RAM, and swap tracking service.
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` — Hardware temperature, frequencies, and iGPU RC6 residency.
- `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml` — Throughput and network interface service.
- `restow/quickshell/.config/quickshell/ii/services/PingService.qml` — Ping daemon bridge service.
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` — Storage mount discovery and I/O tracking.

### Interactive Popups & Overlays
- `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` — MediaControls overlay and `cava` process.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml` — Album art, OpacityMask, blur, and visualizer canvas.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml` — Network and ping diagnostic inspector.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` — CPU/GPU telemetry popup and Canvas history charts.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` — Memory/Storage popup and Canvas history chart.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` — Base popup wrapper and drop shadow implementation.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml` — Clock, uptime, and todo popup.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FileView` (`Quickshell.Io`): High-performance virtual file observer with `blockLoading: true`, reading directly from `/proc` and `/sys` without subshell forks.
- `StyledPopup.qml`: Centralized popup wrapper providing hover intent delay (1000ms), screen edge clamping, and window lifecycle.

### Established Patterns
- **Demand-Gated Fast Polling:** Services run slow polling during idle and fast polling only when `isInspectorActive` or `fastPollingRequests > 0`.
- **Zero Submodule Drift:** Custom changes must remain strictly in `restow/quickshell/` and never modify `vendor/dots-hyprland`.
- **GNU Stow Leaf Symlinks:** Leaf files symlink directly into `~/.config/quickshell/` without folding parent directories.

### Integration Points
- `scripts/profile-quickshell.sh`: Main profiling engine with 8 popup stages, sustained hover keep-alive, and procfs/sysfs metrics extraction.
- `./arch/dots-hyprland.sh verify --strict`: Verification gate for stow integrity.

</code_context>

<specifics>
## Specific Ideas

- Focus on reducing the idle context switch rate (currently 453/s vs 39/s upstream) by consolidating timers so multiple services wake up together rather than continuously thrashing the CPU scheduler.
- In `PlayerControl.qml`, overriding or overlaying the file in `restow/quickshell/` allows replacing `OpacityMask` and `StyledBlurEffect` without modifying vendor files.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion strictly focused on Phase 50 deep performance optimization.

</deferred>

---

*Phase: 50-quickshell-deep-performance-optimization-overhead-reduction*  
*Context gathered: 2026-09-30T19:16:00+06:00*  
