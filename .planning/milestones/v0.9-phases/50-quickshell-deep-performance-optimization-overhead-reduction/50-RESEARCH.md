# Phase 50: Quickshell Deep Performance Optimization & Overhead Reduction - Research

**Date:** 2026-09-30T19:30:00+06:00  
**Phase:** 50-quickshell-deep-performance-optimization-overhead-reduction  
**Status:** Complete  
**Traceability:** Enforces OPT-01, OPT-02, OPT-03, OPT-04, OPT-05  

---

## Summary

Phase 50 executes targeted, deep performance optimizations across the Quickshell desktop shell stack to close the remaining efficiency delta identified in Phase 49 (`BENCHMARK.md`). In Phase 49, empirical baseline measurements proved that while upstream `dots-hyprland` idles at 0.94% CPU with 39.4 context switches/s and 34.7 read syscalls/s [VERIFIED: `BENCHMARK.md:25`], the custom production shell idles at 5.72% CPU (+4.78% delta), generating 453.0 context switches/s (+413.6/s) and 169.3 read syscalls/s (+134.6/s) [VERIFIED: `BENCHMARK.md:15-18, 34`]. Furthermore, specific component bottlenecks were empirically isolated:
1. **MediaControls Overlay:** Consumes 24.58% CPU and 25.53% Intel UHD 770 iGPU load during display [VERIFIED: `BENCHMARK.md:31`], driven by multi-pass `OpacityMask` and Gaussian blurs (`StyledBlurEffect`) in `PlayerControl.qml` [VERIFIED: `PlayerControl.qml:107-135, 159-166`], un-throttled 60 FPS `FrameAnimation` loops in `StyledSlider.qml` [VERIFIED: `StyledSlider.qml:159-164`], and high-frequency `cava` ASCII streaming [VERIFIED: `MediaControls.qml:67-75`].
2. **Network/Ping Telemetry & GPU Boost Lock:** `popup_netping` pegs voluntary context switches at 1,191.5/s, read syscalls at 1,047.5/s, and locks the Intel UHD 770 GPU clock at its maximum boost frequency of 1550.0 MHz [VERIFIED: `BENCHMARK.md:28, benchmark-latest.json:87-93`]. This is caused by recurring `bash -c` subshells in `NetworkUsage.qml` [VERIFIED: `NetworkUsage.qml:186-288`] and scene graph layout thrashing (`anchors.fill: parent` feedback loop inside dynamic height cards with text wrapping) in `NetworkPingPopup.qml` [VERIFIED: `NetworkPingPopup.qml:240-256, 307-311`].
3. **Recurring Subshell Invocations:** Spawning subshells on telemetry paths (`bash -c lscpu` in `ResourceUsage.qml:136`, `bash -c timeout 3 df` in `StorageUsage.qml:168`, `bash -c curl` in `PlayerControl.qml:80`, `bash -c ifc...` in `NetworkUsage.qml:193`) thrashes the kernel process table, forks unnecessary binaries, and inflates voluntary context switches [VERIFIED: in-repo file inspection].
4. **Desynchronized Polling Cadences:** Multiple telemetry singletons running disjoint timers (1s, 2s, 3s) continuously wake up CPU cores, preventing Alder Lake P/E cores from settling into deep C-states [VERIFIED: `ResourceUsage.qml:119`, `HardwareTelemetry.qml:26`, `NetworkUsage.qml:68`, `StorageUsage.qml:56`].

This research maps out the exact architectural solutions required to achieve:
- Quiescent stationary idle CPU usage $\le 2.0\%$ (delta $\le +1.0\%$ over upstream baseline 0.94%) [VERIFIED: `REQUIREMENTS.md:71`].
- Context switches $< 100$/s and read syscalls $< 50$/s [VERIFIED: `REQUIREMENTS.md:71`].
- MediaControls overlay CPU $\le 10.0\%$ and iGPU $\le 12.0\%$ [VERIFIED: `REQUIREMENTS.md:72`].
- Complete elimination of recurring subshells across all telemetry singletons [VERIFIED: `50-CONTEXT.md:28`].
- Elimination of the 1550 MHz GPU boost clock lock in `popup_netping` [VERIFIED: `REQUIREMENTS.md:73`].
- Clamping Canvas history graphs to max 10 FPS / 1000ms intervals [VERIFIED: `REQUIREMENTS.md:74`].
- Pristine GNU Stow leaf symlink architecture with zero submodule drift under `./arch/dots-hyprland.sh verify --strict` [VERIFIED: `./arch/dots-hyprland.sh:742-747`].

---

## User Constraints (from CONTEXT.md)

The following decisions were locked during `/gsd-discuss-phase` and recorded in `50-CONTEXT.md` [VERIFIED: `50-CONTEXT.md:23-50`]:

- **D-50-01 (Idle Sensor Polling Cadence & Wakeup Coalescing):** Implement aggressive power save mode across all telemetry singletons (`HardwareTelemetry.qml`, `ResourceUsage.qml`, `NetworkUsage.qml`, `StorageUsage.qml`, `PingService.qml`). During quiescent idle (no mouse hover on bar, no open popups), relax background sensor polling to a synchronized 5000ms heartbeat. Accelerate polling to 1000ms only when the cursor enters the status bar bounds or when an inspector popup is active.
- **D-50-02 (Subshell Elimination in Singletons):** Completely eliminate all subshell forks (`bash -c`, `lscpu`, `curl`, `df` via shell) in recurring and initialization paths. In `ResourceUsage.qml`, replace `findCpuMaxFreqProc` (`lscpu | grep ...`) with direct sysfs reads (`/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`). In `NetworkUsage.qml`, replace `probeProcess` with sysfs file observers.
- **D-50-03 (MediaControls FBO & Blur Elimination):** Eliminate multi-pass `OpacityMask` and live Gaussian blurs (`StyledBlurEffect`) in `PlayerControl.qml`. Replace with native Qt Quick rounded clipping (`radius` with dark tint overlay), eliminating offscreen FBO render passes.
- **D-50-04 (Audio Spectrum Downsampling & Wave Physics De-escalation):** Downsample `cava` frequency processing from 20 FPS to 12–15 FPS in `MediaControls.qml`, and guarantee the `cava` child process is immediately paused or killed when `mediaControlsLoader.active` becomes false. De-escalate wavy slider physics calculations when not hovered.
- **D-50-05 (Canvas History Graph Clamping):** In `CpuGpuPopup.qml` and `MemoryStoragePopup.qml`, retain the visual scrolling Canvas history graphs, but strictly clamp `Canvas.requestPaint()` to trigger only once every 1000ms when fresh telemetry data arrives (strictly no 60 FPS repaints).
- **D-50-06 (Clock Popup Decoupling & Drop Shadow Caching):** In `ClockWidgetPopup.qml`, decouple uptime and time formatting from per-second updates, updating only on minute changes. In `StyledPopup.qml`, cache `StyledRectangularShadow` so dynamic content changes inside the popup do not recompute Gaussian drop shadows on the GPU on every frame.
- **D-50-07 (Network Sysfs Direct Reading & Attribute Caching):** In `NetworkUsage.qml`, eliminate `probeProcess` (`bash -c`) entirely. Read interface `operstate` and carrier directly via `FileView` from `/sys/class/net/<iface>/`. Cache static interface attributes (MAC, gateway, link speed) upon detection rather than re-probing on every popup open.
- **D-50-08 (Ping Polling Capping & Layout Churn Elimination):** In `PingService.qml`, cap XHR polling during popup display to 2000ms (preventing socket churn). Resolve scene graph layout churn in `NetworkPingPopup.qml` to eliminate the 1550 MHz Intel UHD 770 GPU boost clock lock.
- **D-50-09 (Empirical Re-Benchmarking):** Execute complete 8-stage interactive popup and idle re-benchmarking via `scripts/profile-quickshell.sh`, assert that quiescent idle CPU is $\le 2.0\%$ and iGPU is $\le 10.0\%$, and generate comparative attribution tables in `BENCHMARK.md`.
- **D-50-10 (Automated Test Harness):** Extend `scripts/phase49-audit-assert.sh` or create `scripts/phase50-opt-assert.sh` asserting zero recurring subshells, 5s idle timer configurations, and pristine GNU Stow leaf symlinks under `./arch/dots-hyprland.sh verify --strict`.
- **Agent's Discretion:**
  - Exact syntax for reading CPU max frequency from `/sys/devices/system/cpu/` vs procfs.
  - Caching implementation details for `StyledRectangularShadow` (layer cache vs static pre-rendered asset).

---

## Phase Requirements

| ID | Category | Scope & Objective | Success Metric / Verification Rule |
|---|---|---|---|
| **OPT-01** | Idle Footprint & Timer Coalescing | Drive stationary idle CPU usage from 5.72% down to $\le 2.0\%$ (delta $\le +1.0\%$ over upstream 0.94%), reducing voluntary context switches from 453/s to $< 100$/s and read syscall churn from 169/s to $< 50$/s via timer alignment, sub-process elimination, and demand-gated sensor sweeping [VERIFIED: `REQUIREMENTS.md:71`]. | Measured in `custom_idle` stage via `scripts/profile-quickshell.sh`; asserted by `scripts/phase50-opt-assert.sh` Section 4. |
| **OPT-02** | Multimedia & Audio Spectrum Optimization | Reduce MediaControls active overlay CPU from 24.58% to $\le 10.0\%$ and iGPU from 25.53% to $\le 12.0\%$ by eliminating offscreen `OpacityMask` and Gaussian blurs in `PlayerControl.qml`, throttling/gating `cava` frequency stream, and de-escalating wavy slider animation loops [VERIFIED: `REQUIREMENTS.md:72`]. | Measured in `popup_mediacontrols` stage via `scripts/profile-quickshell.sh`; AST check in `phase50-opt-assert.sh` Section 2. |
| **OPT-03** | Network & Ping Telemetry Churn Elimination | Eliminate recurring subshell executions in `NetworkUsage.qml`, cache static interface attributes, throttle `/proc/net/dev` rate sampling, and eliminate the 1550 MHz GPU boost clock lock in `popup_netping` [VERIFIED: `REQUIREMENTS.md:73`]. | Measured in `popup_netping` stage (`gpu_act_freq_mhz == 0.0`); AST check verifies zero `bash -c` in `NetworkUsage.qml`. |
| **OPT-04** | Canvas, Graphing & Scenegraph Throttling | Clamp interactive popup Canvas chart repainting to max 10 FPS, decouple Clock/Date and Todo re-evaluations from second ticks, and ensure all 8 popups maintain iGPU load $\le 15.0\%$ [VERIFIED: `REQUIREMENTS.md:74`]. | Measured across all 8 popup stages in `BENCHMARK.md`; AST check confirms repaint throttle in `Graph.qml` and minute gating in `ClockWidgetPopup.qml`. |
| **OPT-05** | Empirical Re-Benchmarking & Comprehensive Report | Execute full multi-stage benchmarking suite via `scripts/profile-quickshell.sh`, verify all optimization invariants with an automated test harness, and update `BENCHMARK.md` with pre- vs post-optimization attribution matrices [VERIFIED: `REQUIREMENTS.md:75`]. | Complete execution of `profile-quickshell.sh`, generating updated `BENCHMARK.md` and `benchmark-latest.json`; `phase50-opt-assert.sh` PASS=0 FAIL=0. |

---

## Architectural Responsibility Map

The optimization changes are strictly partitioned across singletons, modules, widgets, and harnesses to prevent coupling regressions:

```
                            +-----------------------------------------+
                            |       GlobalStates.qml (Singleton)      |
                            | - barHovered: bool                      |
                            | - activeInspectorCount: int             |
                            | - fastTelemetryRate: bool (coordinated) |
                            +--------------------+--------------------+
                                                 |
         +--------------------+------------------+------------------+--------------------+
         |                    |                                     |                    |
         v                    v                                     v                    v
+------------------+ +------------------+                 +------------------+ +------------------+
| HardwareTelemetry| |  ResourceUsage   |                 |   NetworkUsage   | |   PingService    |
| - 5000ms idle    | | - 5000ms idle    |                 | - 5000ms idle    | | - 5000ms idle    |
| - 1000ms active  | | - 1000ms active  |                 | - 1000ms active  | | - 2000ms active  |
| - Tier 1 & Tier 2| | - sysfs max freq |                 | - sysfs FileView | | - XHR guard      |
|   segregation    | | - no subshells   |                 | - zero subshells | | - no socket leak |
+------------------+ +------------------+                 +------------------+ +------------------+
         |                    |                                     |                    |
         +--------------------+------------------+------------------+--------------------+
                                                 |
                                                 v
                            +-----------------------------------------+
                            |          Interactive Popups             |
                            | - CpuGpuPopup.qml: finite loops: 3      |
                            | - MemoryStoragePopup.qml: loops: 3      |
                            | - NetworkPingPopup.qml: fixed heights,  |
                            |   stable layout, no anchor loop         |
                            | - ClockWidgetPopup.qml: minute cadence  |
                            | - StyledPopup.qml: layer.enabled shadow |
                            +--------------------+--------------------+
                                                 |
                                                 v
                            +-----------------------------------------+
                            |       Media & Audio Subsystem           |
                            | - MediaControls.qml: cava downsample    |
                            |   to 12-15 FPS, strict process kill     |
                            | - PlayerControl.qml: native clip/tint,  |
                            |   zero OpacityMask, zero FBO blurs,     |
                            |   unhovered wavy slider paused          |
                            | - Graph.qml: clamped Canvas (10 FPS)    |
                            +-----------------------------------------+
```

### File Distribution & Ownership

| Component Path | Tree Ownership | Primary Architectural Responsibilities |
|---|---|---|
| `restow/quickshell/.../ii/GlobalStates.qml` | `restow/quickshell` | Centralizes `barHovered`, `activeInspectorCount`, and `fastTelemetryRate` coordinate bridge [VERIFIED: `GlobalStates.qml:1-57`]. |
| `restow/quickshell/.../ii/services/ResourceUsage.qml` | `restow/quickshell` | 5000ms idle / 1000ms active timer; sysfs max frequency observer; eliminates `findCpuMaxFreqProc` subshell [VERIFIED: `ResourceUsage.qml:118-144`]. |
| `restow/quickshell/.../ii/services/HardwareTelemetry.qml` | `restow/quickshell` | 5000ms idle / 1000ms active cadence bound to `GlobalStates.fastTelemetryRate`; two-tier sensor sweeping [VERIFIED: `HardwareTelemetry.qml:24-30`]. |
| `restow/quickshell/.../ii/services/NetworkUsage.qml` | `restow/quickshell` | 5000ms idle / 1000ms active; sysfs `operstate`/`carrier` FileViews; cached static interface config; eliminates `probeProcess` [VERIFIED: `NetworkUsage.qml:67-72, 186-288`]. |
| `restow/quickshell/.../ii/services/PingService.qml` | `restow/quickshell` | Demand-gated 2000ms active / 5000ms idle polling; XHR socket concurrency guard [VERIFIED: `PingService.qml:34-40`]. |
| `restow/quickshell/.../ii/services/StorageUsage.qml` | `restow/quickshell` | 5000ms idle diskstats; direct `["timeout", "3", "df", "-k", "-P"]` array exec without `bash -c` [VERIFIED: `StorageUsage.qml:54-60, 167-168`]. |
| `restow/quickshell/.../ii/modules/ii/bar/BarContent.qml` | `restow/quickshell` | `HoverHandler` binding `GlobalStates.barHovered` to top bar pointer occupancy [VERIFIED: `BarContent.qml:13-16`]. |
| `restow/quickshell/.../ii/modules/ii/bar/StyledPopup.qml` | `restow/quickshell` | Adds `layer.enabled: true` and `layer.smooth: true` to `StyledRectangularShadow` [VERIFIED: `StyledPopup.qml:129-131`]. |
| `restow/quickshell/.../ii/modules/ii/bar/CpuGpuPopup.qml` | `restow/quickshell` | De-escalates `popupCriticalPulse` from `Animation.Infinite` to `loops: 3` [VERIFIED: `CpuGpuPopup.qml:137-140`]. |
| `restow/quickshell/.../ii/modules/ii/bar/MemoryStoragePopup.qml` | `restow/quickshell` | De-escalates `popupCriticalPulse` from `Animation.Infinite` to `loops: 3` [VERIFIED: `MemoryStoragePopup.qml:148-151`]. |
| `restow/quickshell/.../ii/modules/ii/bar/NetworkPingPopup.qml` | `restow/quickshell` | Fixes card implicit heights; eliminates `anchors.fill: parent` feedback loop inside card layout; stabilizes text wrapping; de-escalates pulse [VERIFIED: `NetworkPingPopup.qml:103-138, 240-256, 307-311`]. |
| `restow/quickshell/.../ii/modules/ii/bar/ClockWidgetPopup.qml` | New in `restow/` | Overrides upstream; gates evaluation on `root.active`; decouples uptime and formatting to minute updates [VERIFIED: `ClockWidgetPopup.qml:7-13`]. |
| `restow/quickshell/.../ii/modules/ii/mediaControls/MediaControls.qml` | `restow/quickshell` | Downsamples `cava` split parser (skips 3 out of 4 or 4 out of 5 frames $\rightarrow$ 12–15 FPS); kills process on inactive [VERIFIED: `MediaControls.qml:58-75`]. |
| `restow/quickshell/.../ii/modules/ii/mediaControls/PlayerControl.qml` | New in `restow/` | Overrides upstream; removes `OpacityMask` and `StyledBlurEffect` FBO passes; pauses wavy slider when unhovered [VERIFIED: `PlayerControl.qml:107-135, 159-166`]. |
| `restow/quickshell/.../ii/modules/common/widgets/Graph.qml` | New in `restow/` | Overrides upstream; throttles `requestPaint()` to 100ms interval (max 10 FPS) [VERIFIED: `Graph.qml:19`]. |
| `scripts/phase50-opt-assert.sh` | New test harness | Enforces AST rules, subshell absence, timer intervals, benchmark ceilings, and strict stow integrity [VERIFIED: `50-CONTEXT.md:44`]. |

---

## Standard Stack

| Layer | Component / Tool | Version / Standard | Role & Contract |
|---|---|---|---|
| **Compositor & Shell** | Hyprland | 0.47.2+ | Wayland compositor managing layer surfaces (`quickshell:bar`, `quickshell:popup`, `quickshell:mediaControls`) [VERIFIED: `profile-quickshell.sh:380`]. |
| **GUI Framework** | Quickshell (Qt 6.8+ / QtQuick) | Git Master (latest) | Declarative desktop shell host with C++ native `FileView`, `Process`, and Wayland layer shell integration [VERIFIED: `BENCHMARK.md:5-7`]. |
| **Kernel Telemetry Interfaces** | Linux sysfs / procfs | Linux 6.16.x | Unprivileged virtual filesystem nodes (`/proc/stat`, `/proc/net/dev`, `/proc/net/route`, `/sys/class/net/`, `/sys/devices/system/cpu/`, `/sys/class/drm/card1/`) [VERIFIED: host verification]. |
| **Hardware Environment** | Intel Alder Lake-S GT1 | Intel UHD Graphics 770 | Integrated GPU with hardware RC6 sleep state and dynamic RPS render clock (0–1550 MHz) [VERIFIED: `BENCHMARK.md:5, 28`]. |
| **Deployment Layer** | GNU Stow | 2.4.1+ | Non-folding leaf symlink manager maintaining personal overrides in `restow/quickshell/` [VERIFIED: `bootstrap.sh:570`]. |
| **Verification & Profiling** | `profile-quickshell.sh` | Custom (Phase 49) | Empirical 8-stage resource profiling harness collecting procfs/sysfs metrics and generating comparative reports [VERIFIED: `profile-quickshell.sh:1-1314`]. |

---

## Architecture Patterns

### Pattern 1: Coalesced Heartbeat Polling & Demand-Gated Acceleration

**Problem:** Multiple singletons running individual timers at 1s, 2s, 3s intervals trigger constant CPU scheduler interrupts. The CPU cannot enter package C-states when wakeups occur 5–10 times every second.

**Pattern Implementation:**
1. `GlobalStates.qml` provides the single shared telemetry state:
   - `property bool barHovered: false`
   - `property int activeInspectorCount: 0`
   - `readonly property bool fastTelemetryRate: barHovered || activeInspectorCount > 0`
2. `BarContent.qml` embeds a root `HoverHandler`:
   ```qml
   HoverHandler {
       id: barHoverHandler
       onHoveredChanged: GlobalStates.barHovered = hovered
   }
   ```
3. Whenever an inspector popup (`CpuGpuPopup`, `MemoryStoragePopup`, `NetworkPingPopup`) opens, it increments `GlobalStates.activeInspectorCount` in `onActiveChanged`, and decrements on close or `Component.onDestruction`.
4. All singletons bind their primary timer interval to `GlobalStates.fastTelemetryRate`:
   - Quiescent Idle: `interval: 5000` (synchronized 5s heartbeat across all 5 singletons).
   - Active Demand: `interval: 1000` (or 2000ms for network/ping).
5. Immediate Sync: When `fastTelemetryRate` transitions to `true`, the singletons immediately call `pollMetrics()` or `pollTier2()` so the UI has zero latency on cursor entry.

### Pattern 2: Subshell Elimination via Direct Sysfs & Procfs Virtual Observers

**Problem:** Spawning `["bash", "-c", "lscpu ..."]`, `["bash", "-c", "timeout 3 df ..."]`, or `["bash", "-c", "for ifc in ...; jq -n"]` forks bash, spawns pipelines of coreutils, generates dozens of context switches per invocation, and leaks file descriptors under rapid toggling.

**Pattern Implementation:**
1. CPU Max Frequency:
   - File: `/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq` [VERIFIED: on-disk value `4800000` kHz].
   - Direct `FileView`:
     ```qml
     FileView {
         id: fileCpuMaxFreq
         path: "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
         printErrors: false
         blockLoading: true
     }
     ```
   - Parsing: `(parseInt(fileCpuMaxFreq.text().trim(), 10) / 1000000).toFixed(0) + " GHz"`.
2. Storage Mounts Discovery:
   - Instead of `["bash", "-c", "timeout 3 df -k -P"]`, invoke the binary directly as an argument array:
     ```qml
     Process {
         id: dfProc
         command: ["timeout", "3", "df", "-k", "-P"]
         ...
     }
     ```
     This executes `timeout` directly via `execve`, eliminating `bash` entirely.
3. Network Interface Telemetry:
   - Active Interface & Carrier: Read `/sys/class/net/<iface>/operstate` and `/sys/class/net/<iface>/carrier` via `FileView`.
   - Default Route & Gateway: Parse `/proc/net/route` directly. The default route destination is `00000000`; the gateway is hex-encoded little-endian IP [VERIFIED: `/proc/net/route` output].
   - MAC Address: Read `/sys/class/net/<iface>/address` via `FileView`.
   - Link Speed & Duplex: Read `/sys/class/net/<iface>/speed` and `/sys/class/net/<iface>/duplex` via `FileView`.
   - DNS Servers: Read `/etc/resolv.conf` via `FileView`.
   - Local IP Address: Execute one-shot `["ip", "-j", "-4", "addr", "show"]` only when the active interface transitions or at startup, parsing the resulting native JSON directly with JavaScript `JSON.parse()`.

### Pattern 3: Zero-FBO Clipping & Live Blur Elimination in Multimedia

**Problem:** `PlayerControl.qml` uses `layer.effect: OpacityMask` on `background` and `artBackground`, and `layer.effect: StyledBlurEffect` on `blurredArt` [VERIFIED: `PlayerControl.qml:107-135, 159-166`]. In Qt Quick, `OpacityMask` and `StyledBlurEffect` require separate offscreen framebuffer objects (FBOs) and multi-pass shader blurs every time the visualizer or wavy slider repaints (up to 60 FPS), saturating the Intel UHD 770 GPU compositing pipeline.

**Pattern Implementation:**
1. Replace `OpacityMask` on containers with native Qt Quick rounded clipping:
   - Set `clip: true` and `radius: root.radius` on the `Rectangle` container.
   - For album art background: Use `clip: true` on `Rectangle { id: artBackground; radius: ... }` with `Image { fillMode: Image.PreserveAspectCrop }`. Qt Quick clips the child image to the rectangle's boundary in hardware without creating an auxiliary offscreen FBO.
2. Replace `StyledBlurEffect` on background:
   - Instead of computing a real-time Gaussian blur of the high-res cover art on every frame, use a softly tinted semi-opaque dark backing:
     ```qml
     Rectangle {
         anchors.fill: parent
         color: ColorUtils.applyAlpha(blendedColors.colLayer0, 0.85)
         radius: root.radius
     }
     ```
   - If cover art tint is desired, render `Image { opacity: 0.15; fillMode: Image.PreserveAspectCrop }` beneath the tint layer without any `MultiEffect` or `StyledBlurEffect` filter pass.
3. Pause Wavy Slider Animation:
   - In `StyledSlider.qml` / `StyledProgressBar.qml`, `FrameAnimation` repaints `WavyLine` every display frame (60 FPS) when `animateWave` is true [VERIFIED: `StyledSlider.qml:159-164`].
   - In `PlayerControl.qml`, pass `animateWave: root.player?.isPlaying && sliderMouseArea.containsMouse`. When the user is not actively hovering or scrubbing the slider, `animateWave` evaluates to `false`, instantly suspending the 60 FPS `FrameAnimation` loop!

### Pattern 4: Scene Graph Stabilization & Fixed-Height Card Geometry

**Problem:** In `NetworkPingPopup.qml`, `ifaceCard` and `PingDiagnosticCard` declare `implicitHeight: cardContent.implicitHeight + 16` while the inner `ColumnLayout` declares `anchors.fill: parent` [VERIFIED: `NetworkPingPopup.qml:240-256`]. Furthermore, dynamic text (`Drops / Errors` with `allowWrap: true`) and pulsating animations cause the card layout to fluctuate on every 1000ms tick. In Wayland, when a layer shell surface changes size, Hyprland must reallocate surface textures and reconfigure scene graph geometry, which triggers the Intel GPU governor to boost to 1550 MHz.

**Pattern Implementation:**
1. Decouple Card Height from Inner Anchors:
   - Never use `anchors.fill: parent` on a layout whose parent's height is derived from that layout's implicit height.
   - Anchor `ColumnLayout` to `anchors.left`, `anchors.right`, `anchors.top` with `margins: 8`.
2. Fix Diagnostic Card Heights:
   - The 3 ping diagnostic cards have fixed visual structure: Header row (icon + title + quality pill) and Readout row (IP badge + latency).
   - Set an explicit, immutable `implicitHeight: 68` on `PingDiagnosticCard`.
3. Eliminate Dynamic Text Wrap Jitter:
   - In `NetworkDetailRow`, set `elide: Text.ElideRight` and `wrapMode: Text.NoWrap` for `Drops / Errors`. Formatted strings (`Rx: 0d / 0e  Tx: 0d / 0e`) remain single-line, preventing vertical layout thrashing.
4. Bound Pulse Animations:
   - Ensure `cardPulseAnimation` has `loops: 3` and strictly halts when finished, resetting opacity to `1.0`.

### Pattern 5: Canvas History Graph Repaint Throttling

**Problem:** Upstream `Graph.qml` connects `onValuesChanged: root.requestPaint()` [VERIFIED: `Graph.qml:19`]. If telemetry arrays update or if values are bound to frequent signals, `requestPaint()` executes un-throttled.

**Pattern Implementation:**
1. Override `Graph.qml` in `restow/quickshell/.config/quickshell/ii/modules/common/widgets/Graph.qml`.
2. Introduce a repaint throttle timer:
   ```qml
   property real lastPaintTime: 0
   property bool paintPending: false

   Timer {
       id: paintThrottleTimer
       interval: 100 // 10 FPS cap
       repeat: false
       onTriggered: {
           root.paintPending = false;
           root.requestPaint();
       }
   }

   onValuesChanged: {
       const now = Date.now();
       if (now - lastPaintTime >= 100) {
           lastPaintTime = now;
           root.requestPaint();
       } else if (!paintPending) {
           paintPending = true;
           paintThrottleTimer.restart();
       }
   }
   ```
   This guarantees that no matter how frequently `values` updates, the 2D HTML5 canvas context cannot repaint faster than 10 FPS (100ms interval).

---

## Don't Hand-Roll

| Problem Area | What NOT to Do (Anti-Pattern) | What to Use Instead (Standard Pattern) | Rationale |
|---|---|---|---|
| **CPU Max Frequency Discovery** | Spawning `Process { command: ["bash", "-c", "lscpu \| ..."] }` | `FileView { path: "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq" }` | Eliminates bash fork, lscpu execution, grep, awk pipelines, and context switches [VERIFIED: `50-CONTEXT.md:28`]. |
| **Storage Discovery** | Spawning `Process { command: ["bash", "-c", "timeout 3 df -k -P"] }` | `Process { command: ["timeout", "3", "df", "-k", "-P"] }` | Invokes the coreutils binary directly via `execve`, eliminating subshell overhead [VERIFIED: `50-CONTEXT.md:28`]. |
| **Network Interface & Route Discovery** | Parsing network state via a 70-line shell script running `ip route`, `ip addr`, `iw`, `jq` every 30s | Native procfs/sysfs `FileView` on `/proc/net/route`, `/sys/class/net/`, and one-shot `ip -j` JSON parse | Eliminates recurring process churn; provides sub-millisecond in-memory telemetry [VERIFIED: `50-CONTEXT.md:39`]. |
| **Card & Corner Clipping** | `layer.enabled: true` with `layer.effect: OpacityMask` | `Rectangle { radius: ...; clip: true }` | Native Qt Quick rounded clipping runs directly in vertex shaders without auxiliary offscreen FBO passes [VERIFIED: `50-CONTEXT.md:31`]. |
| **Wave Animation Loops** | Continuous `FrameAnimation` running at 60 FPS on stationary sliders | Gating `animateWave` behind `containsMouse` or hover state | Eliminates continuous GPU rendering and canvas repainting when the user is not actively interacting [VERIFIED: `50-CONTEXT.md:32`]. |
| **Drop Shadow Computation** | Un-cached dynamic `StyledRectangularShadow` tracking a resizing container | `layer.enabled: true; layer.smooth: true` on shadow Item | Caches the blurred Gaussian drop shadow texture in GPU VRAM, preventing per-frame shader recomputation [VERIFIED: `50-CONTEXT.md:36`]. |
| **Alert Pulses** | `loops: Animation.Infinite` on popup alert states | Finite `loops: 3` with guaranteed reset to `opacity: 1.0` | Infinite loops force constant 60 FPS repaints, elevating Intel iGPU render clocks [VERIFIED: `BENCHMARK.md:73-74`]. |

---

## Common Pitfalls

### Pitfall 1: Dynamic Layout Reflow Triggering GPU Boost Lock (1550 MHz)
**Root Cause:** In Wayland, when a layer shell surface (`WlrLayershell`) changes size, the client destroys the old Wayland buffer and commits a new buffer of different dimensions. If dynamic text wrapping (`allowWrap: true`) or loose layout anchors cause the window height to jitter between 412px and 430px every second, the Intel UHD 770 GPU frequency governor (`i915` / `xe`) interprets this continuous surface recreation as intensive rendering activity and locks the clock at 1550 MHz [VERIFIED: `BENCHMARK.md:28, 76`].  
**Prevention:**
1. Fix card heights explicitly (`PingDiagnosticCard { implicitHeight: 68 }`).
2. Anchor layouts with `anchors.top`, `anchors.left`, `anchors.right` rather than `anchors.fill: parent`.
3. Eliminate `allowWrap: true` on rapidly updating strings (`Drops / Errors`), enforcing `elide: Text.ElideRight`.

### Pitfall 2: OpacityMask & StyledBlurEffect Multi-Pass FBO Saturation
**Root Cause:** `PlayerControl.qml` wraps the background and art container with `OpacityMask` and `StyledBlurEffect`. For a single media card, Qt Quick creates 3 offscreen FBOs. Combined with a 60 FPS `WaveVisualizer` and `WavyLine` animation, the GPU must render 3 FBO blurs every 16ms, driving iGPU load to 25.53% [VERIFIED: `BENCHMARK.md:31`].  
**Prevention:** Remove `OpacityMask` and `StyledBlurEffect` completely. Use native Qt Quick `clip: true` on rounded rectangles, and use dark alpha tinting (`ColorUtils.applyAlpha(...)`) instead of live Gaussian blurring.

### Pitfall 3: Timer Drift and Desynchronized CPU Wakeups
**Root Cause:** When 5 telemetry singletons have separate timers running at 1000ms, 2000ms, 3000ms, their ticks drift across time. Instead of waking the CPU once every 5 seconds, the CPU is awakened 453 times per second across all threads, destroying energy efficiency [VERIFIED: `BENCHMARK.md:17`].  
**Prevention:** Coalesce all background singletons to a synchronized 5000ms heartbeat driven by a single coordinated signal or aligned interval during quiescent idle. Accelerate to 1000ms only during bar hover or active inspector popup.

### Pitfall 4: Submodule Working Tree Drift
**Root Cause:** Modifying files inside `vendor/dots-hyprland/` creates git churn in the submodule, violating the repository's zero-drift rule and failing `./arch/dots-hyprland.sh verify --strict` [VERIFIED: `./arch/dots-hyprland.sh:381-386`].  
**Prevention:** NEVER touch `vendor/dots-hyprland/`. Author all overrides and new components in `restow/quickshell/`. Use GNU Stow leaf symlinks to overlay them into `~/.config/quickshell/`.

### Pitfall 5: GNU Stow Directory Folding
**Root Cause:** Running `stow` without `--no-folding` can cause GNU Stow to replace entire directories (e.g. `~/.config/quickshell/ii/modules/ii/bar/`) with a single symlink, breaking other upstream files located in that directory [VERIFIED: `STATE.md:241, 285`].  
**Prevention:** Always invoke `stow` with `--no-folding` and ensure parent directories exist before creating leaf symlinks.

---

## Code Examples

### Example 1: Eliminating Subshell in `ResourceUsage.qml`

```qml
// restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml

// Direct sysfs FileView reading CPU max frequency (replaces findCpuMaxFreqProc bash -c)
FileView {
    id: fileCpuMaxFreq
    path: "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
    printErrors: false
    blockLoading: true
}

Component.onCompleted: {
    root.pollMetrics();
    fileCpuMaxFreq.reload();
    const rawKhz = parseInt(fileCpuMaxFreq.text().trim(), 10);
    if (!isNaN(rawKhz) && rawKhz > 0) {
        root.maxAvailableCpuString = (rawKhz / 1000000).toFixed(0) + " GHz";
    }
}

// Coalesced 5000ms idle / 1000ms active polling cadence
Timer {
    id: pollTimer
    interval: (root.isInspectorActive || GlobalStates.fastTelemetryRate) ? 1000 : 5000
    running: true
    repeat: true
    onTriggered: root.pollMetrics()
}
```

### Example 2: Eliminating Subshell & Caching in `NetworkUsage.qml`

```qml
// restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml

FileView { id: fileRoute; path: "/proc/net/route"; printErrors: false; blockLoading: true }
FileView { id: fileResolv; path: "/etc/resolv.conf"; printErrors: false; blockLoading: true }
FileView { id: fileIfaceOperstate; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/operstate` : ""; printErrors: false; blockLoading: true }
FileView { id: fileIfaceCarrier; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/carrier` : ""; printErrors: false; blockLoading: true }
FileView { id: fileIfaceMac; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/address` : ""; printErrors: false; blockLoading: true }
FileView { id: fileIfaceSpeed; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/speed` : ""; printErrors: false; blockLoading: true }

function refreshConfig() {
    fileRoute.reload();
    const textRoute = fileRoute.text();
    if (textRoute) {
        const lines = textRoute.trim().split("\n");
        for (let i = 1; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length >= 3 && parts[1] === "00000000") { // Default route
                root.activeInterface = parts[0];
                const hexGw = parts[2];
                // Parse little-endian hex IP
                root.gatewayIp = `${parseInt(hexGw.slice(6, 8), 16)}.${parseInt(hexGw.slice(4, 6), 16)}.${parseInt(hexGw.slice(2, 4), 16)}.${parseInt(hexGw.slice(0, 2), 16)}`;
                break;
            }
        }
    }

    if (root.activeInterface) {
        fileIfaceMac.reload();
        root.macAddress = fileIfaceMac.text().trim() || "--";
        fileIfaceSpeed.reload();
        const spd = fileIfaceSpeed.text().trim();
        root.linkSpeed = (spd && spd !== "-1") ? `${spd} Mbps` : "--";
        root.isEthernet = root.activeInterface.startsWith("en") || root.activeInterface.startsWith("eth");
        root.isWireless = root.activeInterface.startsWith("wl");
        root.connectionType = root.isEthernet ? "Ethernet" : (root.isWireless ? "Wi-Fi" : "Connected");
    }

    fileResolv.reload();
    const textResolv = fileResolv.text();
    if (textResolv) {
        const matches = [...textResolv.matchAll(/^nameserver\s+(\S+)/gm)].map(m => m[1]);
        root.dnsServers = matches.join(", ") || "--";
    }

    // Trigger one-shot IP discovery via direct array exec (zero bash subshell)
    if (!ipAddrProc.running) ipAddrProc.running = true;
}

Process {
    id: ipAddrProc
    command: ["ip", "-j", "-4", "addr", "show"]
    stdout: StdioCollector {
        onStreamFinished: {
            try {
                const data = JSON.parse(text);
                for (const item of data) {
                    if (item.ifname === root.activeInterface && item.addr_info?.length > 0) {
                        root.ipAddress = item.addr_info[0].local || "--";
                        root.isConnected = true;
                        break;
                    }
                }
            } catch (e) {}
        }
    }
}
```

### Example 3: Zero-FBO Rounded Clipping in `PlayerControl.qml`

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml

Rectangle { // Background with native rounded clipping (NO OpacityMask FBO)
    id: background
    anchors.fill: parent
    anchors.margins: Appearance.sizes.elevationMargin
    color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
    radius: root.radius
    clip: true // Hardware clipping, zero FBO passes

    // Soft album art tint without live Gaussian blur
    StyledImage {
        id: coverTint
        anchors.fill: parent
        source: root.displayedArtFilePath
        fillMode: Image.PreserveAspectCrop
        opacity: 0.15
        cache: true
        asynchronous: true
    }

    Rectangle { // Dark tint overlay
        anchors.fill: parent
        color: ColorUtils.transparentize(blendedColors.colLayer0, 0.4)
        radius: root.radius
    }

    // De-escalate wavy slider physics when not hovered
    Loader {
        id: sliderLoader
        anchors.fill: parent
        active: root.player?.canSeek ?? false
        sourceComponent: StyledSlider {
            configuration: StyledSlider.Configuration.Wavy
            animateWave: root.player?.isPlaying && sliderMouseArea.containsMouse
            highlightColor: blendedColors.colPrimary
            trackColor: blendedColors.colSecondaryContainer
            handleColor: blendedColors.colPrimary
            value: root.player?.position / root.player?.length
            onMoved: root.player.position = value * root.player.length
        }
    }
}
```

### Example 4: Clamped Canvas History Graph Repainting in `Graph.qml`

```qml
// restow/quickshell/.config/quickshell/ii/modules/common/widgets/Graph.qml

Canvas {
    id: root

    required property list<real> values
    property int points: values.length
    property color color: Appearance.colors.colPrimary
    property real fillOpacity: 0.5

    // Throttled requestPaint (max 10 FPS / 100ms deadband)
    property real lastPaintTime: 0
    property bool paintPending: false

    Timer {
        id: paintThrottleTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.paintPending = false;
            root.requestPaint();
        }
    }

    onValuesChanged: {
        const now = Date.now();
        if (now - lastPaintTime >= 100) {
            lastPaintTime = now;
            root.requestPaint();
        } else if (!paintPending) {
            paintPending = true;
            paintThrottleTimer.restart();
        }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (!root.values || root.values.length < 2) return;
        // ... paint logic preserved ...
    }
}
```

---

## Environment Availability

The target environment is verified on host `pera-desktop` [VERIFIED: `BENCHMARK.md:5-8`]:
- **CPU:** 12th Gen Intel Core i7-12700K (12 Cores / 20 Threads: 8 P-Cores, 4 E-Cores).
- **GPU:** Intel UHD Graphics 770 (`/sys/class/drm/card1/`).
- **Sysfs Interfaces Available & Verified:**
  - `/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq` (returns `4800000` kHz).
  - `/sys/class/net/enp4s0/` and `/sys/class/net/wlp0s20f0u7/` (`operstate`, `carrier`, `address`, `speed`).
  - `/proc/net/route` and `/proc/net/dev`.
  - `/sys/class/drm/card1/gt/gt0/rc6_residency_ms`.
  - `/sys/class/drm/card1/gt_act_freq_mhz`.
- **System Monitoring Bridge:** Local daemon active at `http://127.0.0.1:8765/api/status` [VERIFIED: curl test].
- **CLI Utilities Available in PATH:** `qs`, `ydotool`, `hyprctl`, `stow`, `jq`, `awk`, `timeout`, `ip`.
- **Repository Verification:** `./arch/dots-hyprland.sh verify --strict` passed cleanly (`FAIL=0 FINDINGS=0`) [VERIFIED: task-148 execution transcript].

---

## Validation Architecture (Nyquist)

Phase 50 will implement an automated, 5-section test harness: `scripts/phase50-opt-assert.sh`. The harness validates all architectural invariants, AST rules, and empirical benchmark budgets.

### Nyquist Assertion Map

| Section | Focus Area | Checks & Assertions | Pass Criteria |
|---|---|---|---|
| **Section 1** | Preconditions & Safety | Bash syntax validation (`bash -n`), non-root execution check, tool availability (`stow`, `jq`, `hyprctl`), sysfs readability. | All tools present; non-root; `FAIL=0`. |
| **Section 2** | Subshell Elimination Audit | AST grep ensuring ZERO recurring subshells (`bash -c`, `lscpu`, `curl`, `df` via shell) in `restow/quickshell/ii/services/` and `ii/modules/`. | Zero banned shell invocations in QML service files; `FAIL=0`. |
| **Section 3** | Timer Coalescing & Scenegraph Rules | Grep enforcing 5000ms idle timer configuration in `HardwareTelemetry.qml`, `ResourceUsage.qml`, `NetworkUsage.qml`, `StorageUsage.qml`. Enforce ZERO `loops: Animation.Infinite` across all pills and popups. Enforce `layer.enabled: true` in `StyledPopup.qml`. | All AST rules satisfied; `FAIL=0`. |
| **Section 4** | Empirical Benchmark Ceilings | Reads `benchmark-latest.json` after full run: <br>- Quiescent Idle CPU $\le 2.0\%$ (`custom_idle`)<br>- Quiescent Idle iGPU $\le 10.0\%$<br>- Voluntary Context Switches $< 100$/s<br>- Read Syscalls $< 50$/s<br>- MediaControls CPU $\le 10.0\%$, iGPU $\le 12.0\%$<br>- NetPing GPU boost clock $== 0.0$ MHz (no 1550 MHz boost lock). | All stages within performance budgets; `FAIL=0`. |
| **Section 5** | Strict Repository & Stow Integrity | Executes `./arch/dots-hyprland.sh verify --strict`; checks `git status --porcelain vendor/dots-hyprland` for zero submodule drift. | Verification passes cleanly; zero uncommitted vendor churn; `FAIL=0`. |

---

## Security Domain

- **Root Privilege Guard:** The assertion harness `scripts/phase50-opt-assert.sh` enforces `EUID != 0` immediately upon startup, conforming to ASVS L1.
- **Subprocess Security:** Replacing raw shell strings (`bash -c "..."`) with structured argument arrays (`["ip", "-j", "-4", "addr", "show"]`, `["timeout", "3", "df", "-k", "-P"]`) prevents shell metacharacter expansion and command injection vulnerabilities.
- **File Access Security:** All virtual file observers (`FileView`) are strictly scoped to well-known Linux kernel pseudo-filesystems (`/sys/`, `/proc/`, `/etc/resolv.conf`).
- **Secret Protection:** Strict adherence to project boundaries: Never access, read, or print any `rclone.conf` or cloud credential files.

---

## Sources

### In-Repo Primary Files
- `50-CONTEXT.md` [VERIFIED: lines 1–116] — Phase scope, boundary decisions D-50-01 through D-50-10.
- `REQUIREMENTS.md` [VERIFIED: lines 69–76] — Formal requirements OPT-01 through OPT-05.
- `STATE.md` [VERIFIED: lines 1–326] — Architectural state, carried decisions, and phase progression.
- `.planning/phases/49-quickshell-resource-profiling-component-performance-audit/BENCHMARK.md` [VERIFIED: lines 1–118] — Empirical baseline metrics, attribution matrix, and prior bottlenecks.
- `.planning/phases/49-quickshell-resource-profiling-component-performance-audit/benchmark-latest.json` [VERIFIED: lines 1–202] — Machine-readable raw performance telemetry.
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` [VERIFIED: lines 1–146] — Polling timer, FileViews, `findCpuMaxFreqProc` subshell.
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` [VERIFIED: lines 1–599] — Two-tier sweeping, fastPollingRequests, thermals, frequencies.
- `restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml` [VERIFIED: lines 1–339] — Throughput, `probeProcess` shell script, configTimer.
- `restow/quickshell/.config/quickshell/ii/services/PingService.qml` [VERIFIED: lines 1–92] — Daemon bridge, XHR polling.
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` [VERIFIED: lines 1–239] — Diskstats timer, `dfProc` subshell.
- `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` [VERIFIED: lines 1–271] — `cava` child process, SplitParser, mediaLoader.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml` [VERIFIED: lines 1–311] — `OpacityMask`, `StyledBlurEffect`, wavy slider.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml` [VERIFIED: lines 1–509] — Dual column layout, card layout, pulse animation.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` [VERIFIED: lines 1–338] — Header, meter rows, `popupCriticalPulse`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml` [VERIFIED: lines 1–427] — Multi-segment bar, drive rows, `popupCriticalPulse`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` [VERIFIED: lines 1–182] — Popup window, margins, `StyledRectangularShadow`.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml` [VERIFIED: lines 1–71] — Date, uptime, and todo formatting.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml` [VERIFIED: lines 1–52] — Canvas 2D line graph rendering.
- `scripts/profile-quickshell.sh` [VERIFIED: lines 1–1314] — Automated multi-stage profiling harness.
- `scripts/phase49-audit-assert.sh` [VERIFIED: lines 1–413] — Reference 5-section audit assertion script.

---

## Metadata

- **Generated:** 2026-09-30T19:30:00+06:00
- **Author:** GSD Phase Researcher
- **Phase Status:** Ready for Planning (`/gsd-plan-phase 50`)
- **Nyquist Compliance:** Designed for full compliance via `scripts/phase50-opt-assert.sh`
- **Submodule Drift Risk:** 0 (all changes authored in `restow/quickshell/` and `scripts/`)
