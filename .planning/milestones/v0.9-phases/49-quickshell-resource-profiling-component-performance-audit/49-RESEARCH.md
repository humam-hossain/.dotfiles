# Phase 49: Quickshell Resource Profiling & Component Performance Audit - Research & Architecture

**Document ID:** `49-RESEARCH.md`  
**Phase:** 49 (quickshell-resource-profiling-component-performance-audit)  
**Status:** Complete  
**Confidence Level:** HIGH  
**Hardware Verified:** Intel Alder Lake-S GT1 (UHD Graphics 770), Intel Core i7-12700K, DP-1 3440x1440@60Hz  
**Requirements Addressed:** AUDIT-01, AUDIT-02, AUDIT-03  

---

## 1. Executive Summary

Phase 49 conducts an exhaustive, empirical resource audit (CPU, GPU, RAM, context switches, and syscall rates) of Quickshell and all top status bar components in the user's custom Hyprland desktop environment. The primary goals are to:
1. **Establish Clean Baselines:** Verify true system idle without Quickshell (confirming target $\le 10\%$ GPU load) and pure upstream `dots-hyprland` baseline without dotfile customizations [VERIFIED: empirical test tasks 82, 127, 132].
2. **Component-by-Component & Popup Profiling:** Incrementally measure resource consumption of each status bar component (Memory/Storage, CPU/GPU, Network/Ping, Clock, Workspaces, Weather, Media, Voice, Tray, Sidebars) under stationary idle and automated active cursor hover / open popup states using `ydotool` and Quickshell IPC [VERIFIED: empirical test tasks 127, 201].
3. **Identify & Eliminate Hotspots:** Pinpoint specific high-frequency polling routines, unbounded infinite animations, heavy offscreen shader effects, and process streaming bottlenecks, then implement targeted optimizations to dramatically reduce resource utilization [VERIFIED: code inspection & empirical benchmarking].

### Key Breakthrough Findings

- **Clean System Idle Without Quickshell:** When Quickshell processes are killed and external media playback is paused, system GPU active render load drops to **0.76%** (well below the $\le 10\%$ requirement ceiling) [VERIFIED: task-127].
- **Pure Upstream Baseline:** Upstream `dots-hyprland` default Quickshell consumes **0.76% CPU** and **0.00% GPU active render load** at stationary idle [VERIFIED: task-132].
- **Full Custom Quickshell Overlay (Pre-Optimization):** With current `restow/quickshell` custom overlays, idle Quickshell consumes **7.00% – 24.00% CPU** and adds **14.55% – 34.53% GPU active render load** at complete idle [VERIFIED: tasks 82, 127, 264].
- **Discovered Critical Bottleneck 1 (`cava` Process Churn in `MediaControls.qml`):** When the media popup is opened, `cava` streams spectrum ASCII data over stdout at 60 FPS. Parsing and updating QML visualizer points consumes **45.33% CPU** [VERIFIED: task-201].
- **Discovered Critical Bottleneck 2 (Infinite Opacity Pulsing in `NetworkPingPopup.qml`):** `cardPulseAnimation` loops infinitely (`loops: Animation.Infinite`) whenever ping targets are offline or status is critical, driving Quickshell CPU to **23.66%** and GPU to **64.94%** (1550 MHz max boost) [VERIFIED: task-201].
- **Discovered Critical Bottleneck 3 (Idle File Polling):** `Voice.qml` reloads 2–6 virtual/tmpfs files every 500ms continuously even when voice STT is completely idle; `StorageUsage.qml` reads `/proc/diskstats` every 1000ms continuously [VERIFIED: static audit & code review].
- **Discovered External Interference Factor:** An active YouTube tab playing in Google Chrome consumes ~30% GPU continuously via hardware video decoding, elevating system GPU load from 0.76% to ~32.7% without Quickshell. Baseline tests must explicitly check for active media playback and warn or pause to ensure unpolluted metrics [VERIFIED: tasks 82, 127].

---

## 2. Architectural Responsibility Map

```
+----------------------------------------------------------------------------------------------------+
|                                    PHASE 49 ARCHITECTURE MATRIX                                    |
+----------------------------------------------------------------------------------------------------+
| Layer                 | Component                       | Responsibilities & Profiling Role       |
+-----------------------+---------------------------------+-----------------------------------------+
| Test Harness          | scripts/profile-quickshell.sh   | - Multi-stage empirical sampling engine |
|                       |                                 | - GNU Stow baseline isolation & restore |
|                       |                                 | - Unprivileged procfs/sysfs telemetry   |
|                       |                                 | - 2x Wayland ydotool cursor navigation  |
|                       |                                 | - Quickshell IPC popup triggering       |
|                       |                                 | - Machine JSON & Markdown reporting     |
+-----------------------+---------------------------------+-----------------------------------------+
| Status Bar Components | CpuGpuPill                      | Circular meters + temp + CPU/GPU load   |
| (Stationary Idle)     | MemoryStoragePill               | Circular meters + RAM + Disk I/O        |
|                       | NetworkPingPill                 | Up/down throughput + ping status icon   |
|                       | ClockWidget & WeatherBar        | System time, uptime, weather tooltip    |
|                       | Media Pill                      | MPRIS player track/artist metadata      |
|                       | VoicePill                       | Whisper STT / Kokoro TTS visual status  |
|                       | SysTray                         | DBus status notifier items              |
+-----------------------+---------------------------------+-----------------------------------------+
| Interactive Popups    | CpuGpuPopup                     | Per-core bars, RAPL power, frequencies  |
| (Active Rendering)    | MemoryStoragePopup              | Physical/cloud storage breakdown, RAM   |
|                       | NetworkPingPopup                | Multi-target ping cards, latency read   |
|                       | MediaControls                   | Player controls, album art, cava visual |
|                       | ClockWidgetPopup                | Calendar, uptime, pending todos         |
|                       | WeatherPopup                    | Extended multi-day forecasts            |
|                       | SidebarLeft / SidebarRight      | Quick settings, dashboard, widgets      |
+-----------------------+---------------------------------+-----------------------------------------+
| Optimization Targets  | MediaControls.qml               | Throttle or gate cava 60 FPS streaming  |
|                       | NetworkPingPopup.qml            | Gate infinite opacity animation loops   |
|                       | Voice.qml                       | Relax idle poll interval (500ms -> 2s)  |
|                       | StorageUsage.qml                | Relax idle diskstats interval           |
|                       | HardwareTelemetry.qml           | Stagger hwmon reads & eliminate dupes   |
+-----------------------+---------------------------------+-----------------------------------------+
| Verification          | scripts/phase49-audit-assert.sh | Automated compliance assertion suite:   |
|                       |                                 | - Clean baseline GPU <= 10%             |
|                       |                                 | - Upstream vs Custom attribution matrix |
|                       |                                 | - Pre- vs Post-optimization deltas      |
|                       |                                 | - Zero working tree / stow link drift   |
+-----------------------+---------------------------------+-----------------------------------------+
```

---

## 3. Hardware & Profiling Environment

### 3.1 Hardware Topology & Detected Drivers
- **Host:** `pera-desktop` [VERIFIED: `uname -n`]
- **CPU:** 12th Gen Intel(R) Core(TM) i7-12700K (12 cores / 20 threads) [VERIFIED: `lscpu`]
- **GPU:** Intel Corporation Alder Lake-S GT1 [UHD Graphics 770] (`pci0000:00/0000:00:02.0`, rev 0c) [VERIFIED: `lspci | grep -E "VGA|3D"`]
- **Display Output:** `DP-1` (ROG PG348Q 3440x1440@60Hz, reserved top 40px for bar) [VERIFIED: `hyprctl monitors`]
- **Window Manager:** Hyprland 0.56.2 (Wayland compositor) [VERIFIED: `hyprctl version`]
- **Quickshell Version:** 0.2.1 (revision `7511545ee2...`, AUR `quickshell-git`) [VERIFIED: `qs -V`]
- **Qt Version:** Qt 6.11.2 (`qt6-base 6.11.2-1`) [VERIFIED: `pacman -Q qt6-base`]

### 3.2 Profiling Tooling Availability Matrix
| Tool | Path / Command | Status | Notes |
|---|---|---|---|
| Intel iGPU Residency | `/sys/class/drm/card1/gt/gt0/rc6_residency_ms` | **VERIFIED** | Unprivileged kernel DRM sysfs interface; millisecond precision [VERIFIED] |
| Intel iGPU Frequency | `/sys/class/drm/card1/gt_act_freq_mhz` | **VERIFIED** | Real-time GPU execution clock frequency [VERIFIED] |
| Linux `procfs` Stat | `/proc/$PID/stat` | **VERIFIED** | Process user + kernel CPU ticks via `SC_CLK_TCK` [VERIFIED] |
| Linux Memory Maps | `/proc/$PID/smaps_rollup` | **VERIFIED** | Exact RSS, PSS, Private Dirty memory in KB [VERIFIED] |
| Linux Thread Status | `/proc/$PID/task/*/status` | **VERIFIED** | Voluntary & non-voluntary context switch aggregation [VERIFIED] |
| Linux I/O Accounting | `/proc/$PID/io` | **VERIFIED** | Process-level `syscr`, `syscw`, `read_bytes`, `write_bytes` [VERIFIED] |
| Open File Handles | `/proc/$PID/fd/` | **VERIFIED** | Unprivileged count of open sockets, pipes, files [VERIFIED] |
| Wayland Mouse Automator | `/usr/bin/ydotool` (via `ydotoold` PID 1417) | **VERIFIED** | Active and responsive under Wayland [VERIFIED] |
| Wayland Compositor IPC | `/usr/bin/hyprctl` | **VERIFIED** | Layer inspection (`hyprctl layers`), cursorpos query [VERIFIED] |
| Quickshell IPC | `qs -c ii ipc call <target> <fn>` | **VERIFIED** | Direct control over sidebars, mediaControls, search, etc. [VERIFIED] |
| `btop` | `/usr/bin/btop` | Available | High-level interactive monitor [VERIFIED] |
| `qmlprofiler` | `/usr/bin/qmlprofiler` | Available | Qt QML profiler binary installed [VERIFIED] |
| `nvidia-smi` | N/A | Absent | Not an Nvidia system (Intel UHD 770 only) [VERIFIED] |
| `radeontop` | N/A | Absent | Not an AMD system [VERIFIED] |
| `intel_gpu_top` | N/A | Absent | Requires root capabilities; sysfs RC6 provides unprivileged equivalent [VERIFIED] |

### 3.3 Wayland 2x Coordinate Scaling Calculation
Testing with `ydotool mousemove -a -x <X> -y <Y>` and querying `hyprctl cursorpos` confirmed an exact $2\times$ coordinate relationship on this display:
$$\text{ScreenX} = 2 \cdot X_{\text{ydotool}} + 1, \quad \text{ScreenY} = 2 \cdot Y_{\text{ydotool}} + 1$$
Therefore, to target any pixel coordinate $(X, Y)$ on screen:
$$X_{\text{ydotool}} = \text{round}\left(\frac{X}{2}\right), \quad Y_{\text{ydotool}} = \text{round}\left(\frac{Y}{2}\right)$$
- **Top Bar Hover (Y = 20):** $Y_{\text{ydotool}} = 10$
- **Neutral Screen Center (X = 1720, Y = 720):** $X_{\text{ydotool}} = 860, Y_{\text{ydotool}} = 360$

---

## 4. Empirical Baselines & Initial Profiling Results

### 4.1 System Idle Baseline Without Quickshell (AUDIT-01)
- **Methodology:** Pause active media players (`playerctl pause -a`), kill all Quickshell processes (`killall qs quickshell`), allow compositor frames to settle for 2 seconds, and sample `/sys/class/drm/card1/gt/gt0/rc6_residency_ms` over a 4-second steady-state window.
- **Empirical Result:**
  - **GPU Active Render Load:** **0.76%** [VERIFIED: task-127]
  - **AUDIT-01 Assertion:** $\le 10\%$ target **PASSED** (0.76% $\ll$ 10.00%).
- **Key Insight on Interference:** If Google Chrome is actively decoding and displaying a 1080p/4K YouTube stream, system GPU load increases to ~32.7% even without Quickshell. The profiling harness must verify that background video playback is paused before executing baseline measurements.

### 4.2 Pure Upstream Quickshell Baseline (AUDIT-01)
- **Methodology:** Unstow `restow/quickshell` via `stow -D`, copy pristine vendor `.config/quickshell/ii/` files, restart `qs -c ii -d`, move cursor to neutral center, and sample 5-second steady state.
- **Empirical Result:**
  - **Quickshell CPU:** **0.76%** (peak 1.92%) [VERIFIED: task-132]
  - **Intel iGPU Active Load:** **0.00%** (clock 0 MHz) [VERIFIED: task-132]
  - **Memory RSS:** 693.59 MB (PSS: 416.70 MB, Private Dirty: 336.45 MB) [VERIFIED: task-132]
  - **Context Switches:** 42.5/s voluntary, 0.8/s non-voluntary [VERIFIED: task-132]
  - **Syscall Rate:** 35.7 reads/s, 27.2 writes/s [VERIFIED: task-132]
  - **Open File Descriptors:** 84 [VERIFIED: task-132]

### 4.3 Full Production Custom Quickshell (Current Baseline)
- **Quickshell CPU at Idle:** **7.00% – 24.00%** [VERIFIED: tasks 82, 127, 264]
- **Intel iGPU Active Load at Idle:** **14.55% – 34.53%** (isolated without external video) [VERIFIED: tasks 127, 264]
- **Conclusion:** Custom overlays currently add $+6\%$ to $+23\%$ CPU utilization and $+15\%$ to $+35\%$ continuous GPU load during stationary idle.

---

## 5. Component & Popup Empirical Attribution Matrix (AUDIT-02)

Automated testing using `ydotool` cursor positioning and Quickshell IPC produced the following live resource measurements across stationary idle and active open popup states (sampling interval 3.0s, steady state) [VERIFIED: task-201]:

| State / Target | Activation Mechanism | Layer Namespace / Surface | Quickshell CPU % | System GPU Load % | GPU Clock | Primary Bottleneck / Activity |
|---|---|---|---|---|---|---|
| **Stationary Idle** | Cursor at (1720, 720) | None (bar only) | **8.33%** | **60.57%** | 0 MHz | 5 circular progress meters, Voice STT 500ms polling, Storage 1s diskstats |
| **Memory / Storage Popup** | Hover screen X=80 (ydotool 40, 10) | `quickshell:popup` (713x334) | **10.00%** | **59.17%** | 1300 MHz | Fast telemetry polling triggered, storage mount items rendered |
| **CPU / GPU Popup** | Hover screen X=200 (ydotool 100, 10) | `quickshell:popup` (713x334) | **8.33%** | **59.57%** | 1500 MHz | Tier-2 hwmon frequency sweeping (1s cadence), per-core bars |
| **Network / Ping Popup** | Hover screen X=320 (ydotool 160, 10) | `quickshell:popup` (713x331) | **23.66%** | **64.94%** | **1550 MHz** | **HOTSPOT:** Infinite `cardPulseAnimation` opacity loop + dynamic Repeater array allocation |
| **Clock Widget Popup** | Hover screen X=1600 (ydotool 800, 10) | `quickshell:popup` (303x130) | **9.00%** | **58.74%** | 0 MHz | Calendar text layout, uptime read |
| **Weather Popup** | Hover screen X=1800 (ydotool 900, 10) | `quickshell:popup` (288x346) | **9.00%** | **60.48%** | 1550 MHz | Weather icon rendering, layout update |
| **MediaControls Popup** | IPC `mediaControls open` | `quickshell:mediaControls` (440x160) | **45.33%** | **62.21%** | **1300 MHz** | **CRITICAL HOTSPOT:** `cava` streaming raw spectrum stdout at 60 FPS parsed into QML points |
| **SidebarLeft (Dashboard)** | IPC `sidebarLeft open` | `quickshell:sidebarLeft` (760x1400) | **8.00%** | **61.01%** | 950 MHz | Complex panel layout, static widgets |
| **SidebarRight (Control)** | IPC `sidebarRight open` | `quickshell:sidebarRight` (460x1400) | **8.00%** | **60.51%** | 1300 MHz | Sliders, power profile buttons |

*(Note: During task-201, Chrome video decoding was contributing ~30% baseline to System GPU Load; the relative GPU frequencies and CPU deltas isolate the specific component impacts).*

---

## 6. Root Cause Analysis & Common Pitfalls

### 6.1 Critical Hotspot 1: Uncapped `cava` Visualizer Streaming in `MediaControls.qml`
- **Location:** `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml:56-72`
- **Mechanism:**
  ```qml
  Process {
      id: cavaProc
      running: mediaControlsLoader.active
      command: ["cava", "-p", ".../raw_output_config.txt"]
      stdout: SplitParser {
          onRead: data => {
              let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
              root.visualizerPoints = points;
          }
      }
  }
  ```
- **The Problem:** `cava` outputs semicolon-delimited frequency buckets at up to 60 FPS. Every frame, QML invokes JavaScript string splitting, float parsing, and array filtering on the main GUI thread, triggering continuous scene graph dirty-flags. This drives Quickshell CPU usage to **45.33%**.
- **Optimization Strategy:**
  - Provide a toggle or throttle for cava spectrum visualization.
  - Rate-limit visualizer points updates using a frame-skipping counter or QML `Timer` throttle (e.g., maximum 15–20 FPS instead of 60 FPS, or disabled by default unless explicitly activated).

### 6.2 Critical Hotspot 2: Infinite Opacity Pulse in `NetworkPingPopup.qml`
- **Location:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml:100-133`
- **Mechanism:**
  ```qml
  readonly property bool isCritical: card.statusClass === "critical" || card.statusClass === "dead" || PingService.isOffline
  SequentialAnimation {
      id: cardPulseAnimation
      running: card.isCritical
      loops: Animation.Infinite
      NumberAnimation { target: card; property: "opacity"; to: 0.4; duration: 600; easing.type: Easing.InOutSine }
      NumberAnimation { target: card; property: "opacity"; to: PingService.isOffline ? 0.7 : 1.0; duration: 600; easing.type: Easing.InOutSine }
  }
  ```
- **The Problem:** If any target host is offline, unreachable, or in a warning/dead state, `cardPulseAnimation` executes an infinite, uninterrupted continuous opacity animation at full refresh rate. Furthermore, lines 268–278 allocate a brand new JavaScript array for the `Repeater` model on every binding tick, forcing QML to tear down and recreate delegate items repeatedly. This spikes CPU to **23.66%** and locks GPU frequency to **1550 MHz**.
- **Optimization Strategy:**
  - Restrict breathing animations to run only when the card is hovered or limit animation loop count (e.g., 3 loops then steady indicator color).
  - Cache DNS server array so delegates are not churned every binding cycle.

### 6.3 Critical Hotspot 3: Continuous Idle File Polling in `Voice.qml` & `StorageUsage.qml`
- **Location:**
  - `restow/quickshell/.config/quickshell/ii/services/Voice.qml:253-259`:
    `interval: (root.overallState === "idle" && !typingLingerTimer.running) ? 500 : 100`
  - `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml:56`:
    `interval: 1000 // 1s continuous diskstats tracking`
- **The Problem:** `Voice.qml` polls 6 `FileView`s twice every second ($500\text{ ms}$) even when speech-to-text has not been invoked for hours. `StorageUsage.qml` reads `/proc/diskstats` every single second and periodically executes `timeout 3 df -k -P` via sub-process.
- **Optimization Strategy:**
  - Back off `Voice.qml` idle polling interval from $500\text{ ms}$ to $2500\text{ ms}$ or $3000\text{ ms}$ when `overallState === "idle"`, accelerating to $100\text{ ms}$ only when `recorder.pid` exists or recording is engaged.
  - Relax `StorageUsage.qml` diskstats interval from $1000\text{ ms}$ to $3000\text{ ms}$ or $5000\text{ ms}$ during idle.

### 6.4 Critical Hotspot 4: `ClippedFilledCircularProgress` Offscreen FBO Overhead
- **Location:** `restow/quickshell/.config/quickshell/ii/modules/common/widgets/ClippedFilledCircularProgress.qml`
- **Mechanism:**
  `Rectangle { ... layer.enabled: true; layer.smooth: true; Shape { preferredRendererType: Shape.CurveRenderer } }`
  `OpacityMask { anchors.fill: parent; source: contentItem; maskSource: textMask }`
- **The Problem:** 5 separate circular progress widgets reside on the top bar (`CpuGpuPill` x2, `MemoryStoragePill` x2, `Media` x1). Each widget uses `layer.enabled: true` and `Qt5Compat.GraphicalEffects.OpacityMask`, requiring Qt Quick to allocate offscreen Framebuffer Objects (FBOs) and execute multi-pass GPU fragment shaders whenever values update.
- **Optimization Strategy:**
  - Ensure `enableAnimation: false` is consistently enforced (confirmed in pills).
  - Quantize input values (already implemented via `quantizedCpuLoad` / `quantizedGpuLoad`) to avoid sub-percent jitter triggering unnecessary FBO redraws.

---

## 7. Structured Test Harness Design for Phase 49

The existing `scripts/profile-quickshell.sh` harness (built in Phase 43.1) provides a solid foundation with procfs/sysfs telemetry and Stow isolation. To satisfy Phase 49 requirements (AUDIT-01, AUDIT-02, AUDIT-03), the harness will be extended with:

### 7.1 Enhanced Baseline Isolation & Cleanliness Assertion (AUDIT-01)
1. **Media Playback Gate:** Before taking baseline measurements, check `playerctl status` across all players. If playing, pause players or log an explicit warning so external video decoding does not contaminate the idle assertion.
2. **Quickshell-Free System Idle Assertion:**
   - Stop Quickshell: `qs -c ii kill` and `killall -9 qs quickshell`.
   - Wait 2.0s for GPU to drop to C-states (RC6 sleep).
   - Sample RC6 residency over 4.0s.
   - Assert `gpu_busy_pct <= 10.0%`.
3. **Pure Upstream Baseline:**
   - Temporarily unstow `restow/quickshell`.
   - Restore vendor `.bak` stubs.
   - Launch `qs -c ii -d`.
   - Measure 5.0s steady state.

### 7.2 Automated Interactive Popup Profiling Loop (AUDIT-02)
Add dedicated staging modes to `scripts/profile-quickshell.sh` that programmatically exercise each interactive popup using calibrated coordinates and IPC commands:

```bash
# Declarative interactive popup suite:
# STAGE_ID | METHOD | TARGET/COORDINATES | VERIFY_LAYER
run_interactive_popup_audit() {
  # 1. CpuGpuPopup
  navigate_and_sample "popup_cpugpu" "hover" 100 10 "quickshell:popup"
  # 2. MemoryStoragePopup
  navigate_and_sample "popup_memstorage" "hover" 40 10 "quickshell:popup"
  # 3. NetworkPingPopup
  navigate_and_sample "popup_netping" "hover" 160 10 "quickshell:popup"
  # 4. ClockWidgetPopup
  navigate_and_sample "popup_clock" "hover" 800 10 "quickshell:popup"
  # 5. WeatherPopup
  navigate_and_sample "popup_weather" "hover" 900 10 "quickshell:popup"
  # 6. MediaControls
  ipc_and_sample "popup_mediacontrols" "mediaControls" "open" "close" "quickshell:mediaControls"
  # 7. SidebarLeft
  ipc_and_sample "popup_sidebarleft" "sidebarLeft" "open" "close" "quickshell:sidebarLeft"
  # 8. SidebarRight
  ipc_and_sample "popup_sidebarright" "sidebarRight" "open" "close" "quickshell:sidebarRight"
}
```

### 7.3 Output Artifacts & Comparative Reporting (AUDIT-03)
The harness exports results directly into Phase 49 directory:
- Machine-readable telemetry: `.planning/phases/49-quickshell-resource-profiling-component-performance-audit/benchmark-latest.json`
- Human-readable audit report: `.planning/phases/49-quickshell-resource-profiling-component-performance-audit/BENCHMARK.md`
- Comparative matrix tracking:
  - Baseline (No Quickshell) vs Upstream Default vs Custom Overlay
  - Pre-optimization vs Post-optimization deltas for high-utilization components (`MediaControls`, `NetworkPingPopup`, `Voice.qml`, `StorageUsage.qml`).

---

## 8. Validation Architecture & Assertion Suite

To enforce requirements systematically, an automated assertion script `scripts/phase49-audit-assert.sh` will be constructed following the pattern of `scripts/phase43-perf-assert.sh` and `scripts/phase48-right-zone-assert.sh`:

### 8.1 Assertion Suite Sections
- **Section 1: Test Harness Safety & Preconditions**
  - Check non-root execution (`EUID != 0`).
  - Verify executable permissions on `scripts/profile-quickshell.sh`.
  - Verify DRM sysfs interfaces are present and readable.
  - Verify `ydotoold` daemon and `hyprctl` are responsive.
- **Section 2: Baseline Resource Invariants (AUDIT-01)**
  - Assert system GPU idle without Quickshell $\le 10\%$.
  - Assert pure upstream Quickshell baseline exists and records CPU $\le 5\%$ and GPU $\le 10\%$.
- **Section 3: Component & Popup Audit Coverage (AUDIT-02)**
  - Verify that `benchmark-latest.json` contains entries for all required popup stages (`popup_cpugpu`, `popup_memstorage`, `popup_netping`, `popup_mediacontrols`, `popup_clock`, `popup_weather`, `popup_sidebarleft`, `popup_sidebarright`).
  - Verify that layer shell presence was confirmed during active popup sampling.
- **Section 4: Targeted Optimization Ceilings (AUDIT-03)**
  - Assert `MediaControls` active CPU does not exceed optimized threshold ($< 25\%$ vs pre-opt $45\%$).
  - Assert `NetworkPingPopup` active CPU does not exceed optimized threshold ($< 15\%$ vs pre-opt $24\%$).
  - Assert Voice STT idle polling interval $\ge 2000\text{ ms}$.
- **Section 5: Repository Integrity & Zero Stow Drift**
  - Verify GNU Stow symlink tree in `~/.config/quickshell/ii/` has zero missing or broken symlinks.
  - Verify clean working tree (`git status --porcelain`).

---

## 9. Phase 49 Implementation Plan Breakdown

Based on these empirical findings, Phase 49 should be divided into 3 focused, sequential plans:

1. **Plan 49-01: Baseline Calibration, Harness Extension & AUDIT-01 Execution**
   - Enhance `scripts/profile-quickshell.sh` with Phase 49 artifact output paths (`.planning/phases/49-*/`), media pause pre-flight check, and automated clean baseline measurement without Quickshell.
   - Execute empirical baseline measurements and record AUDIT-01 verified metrics into `benchmark-latest.json` (assert idle GPU $\le 10\%$).
   - Run pure upstream baseline isolation test via Stow and record baseline metrics.

2. **Plan 49-02: Component-by-Component & Interactive Popup Audit (AUDIT-02)**
   - Implement the automated interactive popup test loop in `profile-quickshell.sh` using calibrated coordinates (X=40, 100, 160, 800, 900) and Quickshell IPC.
   - Run the full suite across all status bar components and 8+ interactive popups.
   - Generate initial empirical benchmark report documenting all resource metrics.

3. **Plan 49-03: Targeted Optimizations, Comparative Report & Regression Assert (AUDIT-03)**
   - Apply targeted optimizations:
     - Throttle/gate `cava` 60 FPS spectrum streaming in `MediaControls.qml`.
     - De-escalate infinite `cardPulseAnimation` opacity looping in `NetworkPingPopup.qml` and cache DNS array.
     - Relax idle polling frequency in `Voice.qml` (500ms $\to$ 2000ms) and `StorageUsage.qml`.
   - Re-run benchmark harness to generate comparative pre/post optimization matrix in `BENCHMARK.md`.
   - Create and execute `scripts/phase49-audit-assert.sh` to enforce zero regressions.

---

## 10. Confidence Assessment & Open Questions

- **Confidence Assessment:** **HIGH**. The exact failure modes, GPU hardware sysfs counters, coordinate translation factors, and root cause bottlenecks (`cava`, infinite animation, file polling) have all been empirically verified on the live system.
- **Open Questions:** None blocking planning. The mechanics of ydotool Wayland coordinate scaling ($2\times$) and Quickshell IPC are fully verified and operational.
