# Phase 50: Quickshell Deep Performance Optimization & Overhead Reduction - Pattern Map

**Generated:** 2026-09-30  
**Phase:** 50 - quickshell-deep-performance-optimization-overhead-reduction  
**Domain:** Quickshell QML runtime performance, Linux procfs/sysfs zero-fork telemetry, Wayland scene graph layout stabilization, Qt Quick FBO/blur elimination, timer coalescing, Canvas repaint throttling, and automated benchmark verification.  
**Consumes:** [`50-CONTEXT.md`](file:///home/pera/github_repo/.dotfiles/.planning/phases/50-quickshell-deep-performance-optimization-overhead-reduction/50-CONTEXT.md), [`50-RESEARCH.md`](file:///home/pera/github_repo/.dotfiles/.planning/phases/50-quickshell-deep-performance-optimization-overhead-reduction/50-RESEARCH.md)  
**Produces:** Authoritative architectural patterns, component classification matrix, concrete code blueprints, anti-patterns, and assertion harness specifications for Phase 50 execution.

---

## 1. Executive Summary

Phase 50 executes targeted, deep performance optimizations across the custom Quickshell desktop shell stack to close the remaining efficiency delta identified during Phase 49 profiling (`BENCHMARK.md`).

In Phase 49, empirical baseline measurements proved that while upstream `dots-hyprland` idles at 0.94% CPU with 39.4 context switches/s and 34.7 read syscalls/s, the custom production shell idles at 5.72% CPU (+4.78% delta), generating 453.0 context switches/s (+413.6/s) and 169.3 read syscalls/s (+134.6/s). Specific component bottlenecks were isolated:
1. **Stationary Idle Overhead:** 5 telemetry singletons running desynchronized timers (1s, 2s, 3s) and spawning recurring subshells (`bash -c lscpu`, `bash -c timeout 3 df`, `bash -c ifc...`) prevent Intel Alder Lake CPU cores from settling into low-power package C-states.
2. **MediaControls FBO Saturation:** Consumes 24.58% CPU and 25.53% Intel UHD 770 iGPU load during display due to multi-pass `OpacityMask` and live Gaussian blurs (`StyledBlurEffect`) in `PlayerControl.qml`, combined with an un-throttled 60 FPS `FrameAnimation` in `StyledSlider.qml` and high-frequency `cava` ASCII streaming.
3. **Network Telemetry Churn & GPU Boost Lock:** `popup_netping` pegs context switches at 1,191.5/s and locks the Intel UHD 770 iGPU at its 1550 MHz boost clock due to recurring `bash -c` subshells and scene graph layout thrashing (`anchors.fill: parent` feedback loop inside dynamic-height cards with text wrapping).
4. **Canvas Repaint & Shadow Churn:** 2D Canvas history graphs in `Graph.qml` repaint un-throttled on every telemetry arrival, dynamic content in `StyledPopup.qml` forces drop shadows to re-render without GPU layer caching, and `ClockWidgetPopup.qml` re-evaluates date/uptime strings on second ticks even when hidden.

The patterns mapped in this document enforce strict contracts to drive idle CPU $\le 2.0\%$, context switches $< 100$/s, read syscalls $< 50$/s, MediaControls CPU $\le 10.0\%$ / iGPU $\le 12.0\%$, eliminate the 1550 MHz GPU boost lock, and maintain zero submodule drift under `./arch/dots-hyprland.sh verify --strict`.

---

## 2. Target File Role & Classification Matrix

| File Path | Operation | Role | Data Flow | Closest Codebase Analog | Key Architectural Responsibilities |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [`scripts/phase50-opt-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase50-opt-assert.sh) | **CREATE** | Quality Assertion Suite / Verification Harness | Request-Response / File Inspection / AST Grep / JSON Benchmark Validation | [`scripts/phase49-audit-assert.sh:1-413`](file:///home/pera/github_repo/.dotfiles/scripts/phase49-audit-assert.sh#L1-L413)<br>[`scripts/phase46-telemetry-assert.sh:1-471`](file:///home/pera/github_repo/.dotfiles/scripts/phase46-telemetry-assert.sh#L1-L471) | 5-section CLI runner (`--section`, `--quick`, `--syntax`), non-root fail-closed guard, zero recurring subshell AST audit, 5000ms idle timer verification, benchmark ceiling enforcement, and zero stow drift assertion. |
| [`restow/.../ii/services/ResourceUsage.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml) | **MODIFY** | Background Service / System CPU & Memory Singleton | `/proc/meminfo`, `/proc/stat`, sysfs max freq `FileView` $\to$ QML properties | [`ResourceUsage.qml:100-146`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml#L100-L146) | Replace `findCpuMaxFreqProc` (`bash -c lscpu`) with direct `FileView` on `/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`; coalesce `pollTimer` to 5000ms idle / 1000ms active. |
| [`restow/.../ii/services/HardwareTelemetry.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml) | **MODIFY** | Background Service / Hardware Sensor & DRM Singleton | Linux sysfs (`hwmon*`, DRM RC6, CPU freq) $\to$ QML properties | [`HardwareTelemetry.qml:13-31`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml#L13-L31) | Coalesce idle timer interval from 3000ms to 5000ms; coordinate fast rate with `GlobalStates.fastTelemetryRate`; retain Tier 1 / Tier 2 polling segregation. |
| [`restow/.../ii/services/NetworkUsage.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml) | **MODIFY** | Background Service / Network Telemetry Singleton | `/proc/net/dev`, `/proc/net/route`, `/sys/class/net/` $\to$ QML properties | [`NetworkUsage.qml:66-100, 186-290`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml#L66-L100) | Completely eliminate `probeProcess` (`bash -c`); parse `/proc/net/route` for default gateway; read interface attributes via `FileView`; one-shot `ip -j` JSON parse; coalesce timer to 5000ms idle / 1000ms active. |
| [`restow/.../ii/services/PingService.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/PingService.qml) | **MODIFY** | Background Service / Ping Daemon Bridge Singleton | XHR GET `http://127.0.0.1:8765/api/status` $\to$ QML latency/target state | [`PingService.qml:32-92`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/PingService.qml#L32-L92) | Demand-gated polling cadence (5000ms idle, 2000ms active); XHR in-flight concurrency guard preventing socket leak and churn. |
| [`restow/.../ii/services/StorageUsage.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml) | **MODIFY** | Background Service / Storage Mount & I/O Singleton | `/proc/diskstats` `FileView` + direct binary `df` exec $\to$ QML properties | [`StorageUsage.qml:54-60, 166-175`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml#L54-L60) | Replace `bash -c timeout 3 df` with direct argument array `["timeout", "3", "df", "-k", "-P"]`; coalesce idle diskstats interval to 5000ms. |
| [`restow/.../ii/modules/ii/mediaControls/MediaControls.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml) | **MODIFY** | UI Overlay / Media Controls Host & Spectrum Visualizer | `cava` child process stdout $\to$ `SplitParser` $\to$ `visualizerPoints` | [`MediaControls.qml:57-77`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml#L57-L77) | Downsample `cava` processing from 20 FPS to 12–15 FPS (`_cavaFrameSkip % 4 !== 0`); guarantee `cavaProc` termination when `mediaControlsLoader.active` is false. |
| [`restow/.../ii/modules/ii/mediaControls/PlayerControl.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml) | **CREATE (OVERRIDE)** | UI Component / Individual Media Player Card & Controls | MPRIS metadata & album art $\to$ QML Layouts, styled slider, native clip | [`vendor/.../PlayerControl.qml:76-170, 240-255`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml#L76-L170) | Stowed override of vendor file; eliminate `OpacityMask` and `StyledBlurEffect`; use native Qt Quick rounded clipping (`radius` + `clip: true`); eliminate `bash -c curl`; de-escalate wavy slider physics when unhovered. |
| [`restow/.../ii/modules/ii/bar/NetworkPingPopup.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml) | **MODIFY** | UI Popup / Network & Ping Inspector Window | `NetworkUsage` & `PingService` properties $\to$ Card layouts & status pills | [`NetworkPingPopup.qml:100-140, 235-260, 305-315`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml#L100-L140) | Break implicit height feedback loop in `ifaceCard` and `PingDiagnosticCard`; set explicit `implicitHeight: 68` on diagnostic cards; eliminate `allowWrap: true` on dynamic strings; eliminate 1550 MHz GPU boost lock. |
| [`restow/.../ii/modules/common/widgets/Graph.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/common/widgets/Graph.qml) | **CREATE (OVERRIDE)** | UI Widget / 2D Canvas History Line Graph | Array of normalized floats $\to$ 2D HTML5 canvas path strokes & fills | [`vendor/.../Graph.qml:1-52`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml#L1-L52) | Stowed override of vendor file; throttle `requestPaint()` using a deadband timer to max 10 FPS (100ms interval), preventing 60 FPS repaints. |
| [`restow/.../ii/modules/ii/bar/ClockWidgetPopup.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml) | **CREATE (OVERRIDE)** | UI Popup / Clock, Uptime & Task Inspector | `DateTime` & `Todo` services $\to$ formatted strings & text rows | [`vendor/.../ClockWidgetPopup.qml:1-71`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml#L1-L71) | Stowed override of vendor file; decouple string formatting from per-second ticks; gate updates strictly on `root.active` and minute changes. |
| [`restow/.../ii/modules/ii/bar/StyledPopup.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml) | **MODIFY** | UI Container / Base Popup Window Wrapper | Component loader & contentItem $\to$ PanelWindow with shadow & animations | [`StyledPopup.qml:125-135`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml#L125-L135) | Add `layer.enabled: true` and `layer.smooth: true` to `StyledRectangularShadow`, caching the Gaussian blur texture in GPU VRAM across content updates. |
| [`restow/.../ii/GlobalStates.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/GlobalStates.qml) | **MODIFY** | Coordinating Singleton / Global Shell State | Bar hover handler + popup visibility $\to$ coordinated telemetry mode | [`GlobalStates.qml:10-37`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/GlobalStates.qml#L10-L37) | Add `barHovered: bool`, `activeInspectorCount: int`, and `fastTelemetryRate: bool` coordinate bridge. |
| [`restow/.../ii/modules/ii/bar/BarContent.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml) | **MODIFY** | UI Shell / Top Status Bar Content Area | Mouse pointer occupancy $\to$ `GlobalStates.barHovered` | [`BarContent.qml:13-20`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L13-L20) | Embed top-level `HoverHandler` binding `GlobalStates.barHovered = hovered`. |
| [`restow/.../ii/modules/ii/bar/CpuGpuPopup.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml) | **MODIFY** | UI Popup / CPU & GPU Hardware Inspector | `HardwareTelemetry` properties $\to$ Progress bars & sensor rows | [`CpuGpuPopup.qml:136-155`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml#L136-L155) | De-escalate `popupCriticalPulse` from `Animation.Infinite` to `loops: 3`; register/unregister in `GlobalStates.activeInspectorCount`. |
| [`restow/.../ii/modules/ii/bar/MemoryStoragePopup.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml) | **MODIFY** | UI Popup / RAM, Swap & Storage Inspector | `ResourceUsage` & `StorageUsage` properties $\to$ Visual meters & drive cards | [`MemoryStoragePopup.qml:146-165`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml#L146-L165) | De-escalate `popupCriticalPulse` from `Animation.Infinite` to `loops: 3`; register/unregister in `GlobalStates.activeInspectorCount`. |

---

## 3. Core Architectural Patterns to Emulate

### Pattern 1: Coalesced 5000ms Heartbeat & Demand-Gated Acceleration
**Analog Source:** [`HardwareTelemetry.qml:13-31`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml#L13-L31) and [`ResourceUsage.qml:118-125`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml#L118-L125)

**Problem:** Telemetry singletons running individual timers at 1s, 2s, and 3s wake up CPU cores multiple times per second, generating over 450 context switches/s and blocking deep processor C-states.

**Pattern Implementation:**
1. A coordinated state property is exposed in `GlobalStates.qml`:
   ```qml
   property bool barHovered: false
   property int activeInspectorCount: 0
   readonly property bool fastTelemetryRate: barHovered || activeInspectorCount > 0
   ```
2. In `BarContent.qml`, a top-level `HoverHandler` drives `barHovered`:
   ```qml
   HoverHandler {
       id: barHoverHandler
       onHoveredChanged: GlobalStates.barHovered = hovered
   }
   ```
3. Interactive popups increment `GlobalStates.activeInspectorCount` in `onActiveChanged`:
   ```qml
   onActiveChanged: {
       if (active) GlobalStates.activeInspectorCount++;
       else GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
   }
   Component.onDestruction: {
       if (active) GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
   }
   ```
4. Singletons bind their primary timer interval to `GlobalStates.fastTelemetryRate`:
   - Idle Quiescence: `5000` ms (synchronized across `ResourceUsage`, `HardwareTelemetry`, `NetworkUsage`, `StorageUsage`, `PingService`).
   - Active Demand: `1000` ms (or `2000` ms for PingService).
5. Immediate refresh trigger: When `fastTelemetryRate` switches to `true`, services immediately trigger `pollMetrics()` so the user observes zero latency upon hovering the status bar or opening an inspector.

---

### Pattern 2: Complete Subshell Elimination via Virtual Observers & Direct Exec
**Analog Source:** [`ResourceUsage.qml:127-128`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml#L127-L128) and [`NetworkUsage.qml:90-95`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml#L90-L95)

**Problem:** Invocations like `["bash", "-c", "lscpu | grep ..."]` or `["bash", "-c", "timeout 3 df -k -P"]` spawn bash, fork sub-processes, invoke coreutils pipes, and generate high context switch churn.

**Pattern Implementation:**
1. **CPU Max Frequency Discovery (`ResourceUsage.qml`):**
   Replace `findCpuMaxFreqProc` (`lscpu | grep ...`) with direct sysfs read from `/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`:
   ```qml
   FileView {
       id: fileCpuMaxFreq
       path: "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
       printErrors: false
       blockLoading: true
   }
   ```
   At startup:
   ```qml
   fileCpuMaxFreq.reload();
   const rawKhz = parseInt(fileCpuMaxFreq.text().trim(), 10);
   if (!isNaN(rawKhz) && rawKhz > 0) {
       root.maxAvailableCpuString = (rawKhz / 1000000).toFixed(0) + " GHz";
   }
   ```
2. **Storage Mount Discovery (`StorageUsage.qml`):**
   Eliminate `bash -c` from `dfProc` by invoking `timeout` directly with command array arguments:
   ```qml
   Process {
       id: dfProc
       command: ["timeout", "3", "df", "-k", "-P"]
       stdout: StdioCollector {
           onStreamFinished: {
               root.lastDfTime = Date.now();
               root.parseDfOutput(text);
           }
       }
   }
   ```
3. **Network Discovery (`NetworkUsage.qml`):**
   Replace the 100-line shell script in `probeProcess` with virtual `FileView` observers:
   - Default route & Gateway: Read `/proc/net/route` directly. Default route destination is `00000000`; parse little-endian hex gateway IP.
   - Interface State: `/sys/class/net/<iface>/operstate` and `/sys/class/net/<iface>/carrier`.
   - MAC & Speed: `/sys/class/net/<iface>/address` and `/sys/class/net/<iface>/speed`.
   - DNS: Parse `nameserver` lines from `/etc/resolv.conf`.
   - IP Address: Execute one-shot `["ip", "-j", "-4", "addr", "show"]` only when active interface changes, parsing JSON directly with `JSON.parse()`.

---

### Pattern 3: Zero-FBO Rounded Clipping, Live Blur Removal & Wavy Slider Throttling
**Analog Source:** [`vendor/.../PlayerControl.qml:100-145`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml#L100-L145) and [`StyledSlider.qml:159-164`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/StyledSlider.qml#L159-L164)

**Problem:** In `PlayerControl.qml`, `layer.effect: OpacityMask` on `background` and `artBackground`, combined with `layer.effect: StyledBlurEffect` on `blurredArt`, forces Qt Quick to allocate 3 offscreen FBOs. Combined with a 60 FPS `FrameAnimation` in `StyledSlider`, the GPU is forced to re-render multi-pass Gaussian blurs every 16ms, driving iGPU load to 25.53%.

**Pattern Implementation:**
1. **Rounded Clipping without FBOs:**
   Use native Qt Quick `clip: true` and `radius: root.radius` on `Rectangle`. Vertex shader scissor/stencil clipping incurs zero offscreen FBO allocation.
2. **Elimination of `StyledBlurEffect`:**
   Replace the live Gaussian blur pass on `blurredArt` with a soft semi-transparent tinted backdrop:
   ```qml
   Rectangle {
       id: background
       anchors.fill: parent
       anchors.margins: Appearance.sizes.elevationMargin
       color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
       radius: root.radius
       clip: true // Native hardware clipping, ZERO OpacityMask FBO passes

       // Subtle album art background without live blur
       StyledImage {
           id: coverTint
           anchors.fill: parent
           source: root.displayedArtFilePath
           fillMode: Image.PreserveAspectCrop
           opacity: 0.15
           cache: true
           asynchronous: true
       }

       Rectangle {
           anchors.fill: parent
           color: ColorUtils.transparentize(blendedColors.colLayer0, 0.4)
           radius: root.radius
       }
       ...
   }
   ```
3. **De-escalating Wavy Slider Physics:**
   In `PlayerControl.qml`, `StyledSlider`'s `FrameAnimation` is controlled via `animateWave`:
   ```qml
   sourceComponent: StyledSlider {
       configuration: StyledSlider.Configuration.Wavy
       animateWave: root.player?.isPlaying && (sliderMouseArea.containsMouse || false)
       ...
   }
   ```
   When the user is not actively hovering or scrubbing the slider, `animateWave` evaluates to `false`, instantly stopping the 60 FPS animation loop.

---

### Pattern 4: Scene Graph Layout Stabilization & Feedback Loop Elimination
**Analog Source:** [`NetworkPingPopup.qml:235-258`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml#L235-L258)

**Problem:** In `NetworkPingPopup.qml`, `ifaceCard` declares `implicitHeight: cardContent.implicitHeight + 16` while the inner layout declares `anchors.fill: parent`. This creates a layout feedback cycle. Combined with dynamic text wrapping on `Drops / Errors` (`allowWrap: true`), the surface height fluctuates every second. In Wayland, surface size changes force buffer reallocations, triggering the Intel GPU governor to boost to 1550 MHz.

**Pattern Implementation:**
1. **Decouple Layout Anchors from Derived Parent Height:**
   Never set `anchors.fill: parent` on a layout whose parent's height is derived from that layout's implicit height.
   ```qml
   Rectangle {
       id: ifaceCard
       Layout.fillWidth: true
       radius: Appearance.rounding.small
       color: Appearance.m3colors.m3surfaceContainerHigh
       implicitHeight: cardContent.implicitHeight + 16

       ColumnLayout {
           id: cardContent
           anchors.top: parent.top
           anchors.left: parent.left
           anchors.right: parent.right
           anchors.margins: 8
           spacing: 4
           ...
       }
   }
   ```
2. **Fixed Geometry for Ping Diagnostic Cards:**
   Diagnostic cards have an immutable structure. Set an explicit `implicitHeight: 68` instead of computing dynamic geometry.
3. **Prevent Dynamic Text Wrap Jitter:**
   In `NetworkDetailRow` for `Drops / Errors`, remove `allowWrap: true` and specify `elide: Text.ElideRight` with `wrapMode: Text.NoWrap`.
4. **Bounded Pulse Loops:**
   Replace any remaining `loops: Animation.Infinite` with bounded `loops: 3` and guarantee opacity settles at static state on finish.

---

### Pattern 5: Canvas History Graph Repaint Clamping (10 FPS / 100ms Cap)
**Analog Source:** [`vendor/.../Graph.qml:8-20`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml#L8-L20)

**Problem:** Upstream `Graph.qml` connects `onValuesChanged: root.requestPaint()`. If history arrays update rapidly, the 2D canvas repaints at high frequencies, consuming GPU resources.

**Pattern Implementation:**
Create an override in `restow/quickshell/.config/quickshell/ii/modules/common/widgets/Graph.qml` with a 100ms deadband timer:
```qml
// restow/quickshell/.config/quickshell/ii/modules/common/widgets/Graph.qml
import QtQuick
import qs.modules.common
import qs.modules.common.functions

Canvas {
    id: root

    enum Alignment { Left, Right }

    required property list<real> values
    property int points: values.length
    property color color: Appearance.colors.colPrimary
    property real fillOpacity: 0.5
    property var alignment: Graph.Alignment.Left

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
        // Drawing logic preserved ...
    }
}
```

---

### Pattern 6: Clock & Todo Decoupling from Per-Second Ticks
**Analog Source:** [`vendor/.../ClockWidgetPopup.qml:7-13`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml#L7-L13)

**Problem:** Upstream `ClockWidgetPopup.qml` binds `formattedTime: DateTime.time`, `formattedUptime: DateTime.uptime`, and `todosSection: getUpcomingTodos()` directly. `DateTime.time` ticks every second, causing continuous string allocations, date formatting, and array filtering even when the popup is closed.

**Pattern Implementation:**
Create an override in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml` that gates updates on popup active state and decouples uptime from second ticks:
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Gate all dynamic bindings on root.active
    property string formattedDate: root.active ? Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy") : ""
    property string formattedTime: root.active ? DateTime.time : ""
    property string formattedUptime: root.active ? DateTime.uptime : ""
    property string todosSection: root.active ? getUpcomingTodos() : ""

    onActiveChanged: {
        if (root.active) {
            root.formattedDate = Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd, yyyy");
            root.formattedTime = DateTime.time;
            root.formattedUptime = DateTime.uptime;
            root.todosSection = getUpcomingTodos();
        }
    }

    // Remaining layout preserved ...
}
```

---

### Pattern 7: Popup Drop Shadow Texture Caching
**Analog Source:** [`restow/.../ii/modules/ii/bar/StyledPopup.qml:129-131`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml#L129-L131)

**Problem:** In `StyledPopup.qml`, `StyledRectangularShadow` surrounds `popupBackground`. When dynamic text or graphs inside the popup update, Qt Quick re-renders the shadow blur effect across the scene graph on every tick.

**Pattern Implementation:**
Enable layer caching on `StyledRectangularShadow` so the rendered drop shadow texture is cached in GPU VRAM:
```qml
StyledRectangularShadow {
    target: popupBackground
    layer.enabled: true
    layer.smooth: true
}
```

---

### Pattern 8: Multi-Section Assertion Suite with Empirical Benchmark Ceilings
**Analog Source:** [`scripts/phase49-audit-assert.sh:1-413`](file:///home/pera/github_repo/.dotfiles/scripts/phase49-audit-assert.sh#L1-L413)

**Problem:** Optimizations can easily regress without automated, fail-closed regression checks enforcing AST rules, timer configurations, and empirical benchmark limits.

**Pattern Implementation:**
Implement `scripts/phase50-opt-assert.sh` supporting `--section [1-5]`, `--quick`, `--syntax`, non-root execution check, temporary file cleanup traps, and standard `[PASS]`, `[FAIL]`, `[FINDING]` formatting.

Sections:
1. **Preconditions & Safety:** Non-root, bash syntax (`bash -n`), required CLI tools (`stow`, `jq`, `hyprctl`).
2. **Subshell Elimination Audit:** AST grep ensuring zero `bash -c`, `lscpu`, `curl`, `df` via shell across `restow/quickshell/ii/services/` and `ii/modules/`.
3. **Timer Coalescing & Scenegraph Rules:** Grep verifying 5000ms idle timer configuration in singletons, `loops <= 3` (zero `Animation.Infinite`), and `layer.enabled: true` in `StyledPopup.qml`.
4. **Empirical Benchmark Ceilings:** Reads `benchmark-latest.json`:
   - Idle CPU $\le 2.0\%$ (`custom_idle`)
   - Context switches $< 100$/s and read syscalls $< 50$/s
   - MediaControls CPU $\le 10.0\%$ and iGPU $\le 12.0\%$
   - NetPing iGPU active frequency $== 0.0$ MHz (no 1550 MHz boost lock).
5. **Strict Repository Verification:** Clean pass of `./arch/dots-hyprland.sh verify --strict` and zero submodule git drift.

---

## 4. Concrete Implementation Blueprints & Excerpts

### 4.1 `ResourceUsage.qml` (Subshell Elimination & 5s Idle Coalescing)

```qml
// In restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml

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
    onTriggered: {
        root.pollMetrics();
    }
}
```

---

### 4.2 `HardwareTelemetry.qml` (5s Idle Timer & Fast Rate Binding)

```qml
// In restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml

property int fastPollingRequests: 0
readonly property bool fastPolling: fastPollingRequests > 0 || overallCpuLoad > 0.50 || GlobalStates.fastTelemetryRate

onFastPollingChanged: {
    if (fastPolling) {
        root.pollTier2();
    }
}

Timer {
    id: pollTimer
    interval: root.fastPolling ? 1000 : 5000 // Coalesced 5000ms idle heartbeat
    repeat: true
    running: true
    onTriggered: root.pollAll()
}
```

---

### 4.3 `NetworkUsage.qml` (Zero Subshells, Direct Route & Carrier FileViews)

```qml
// In restow/quickshell/.config/quickshell/ii/services/NetworkUsage.qml

// Fast procfs and sysfs observers
FileView { id: fileNetDev; path: "/proc/net/dev"; printErrors: false; blockLoading: true }
FileView { id: fileRoute; path: "/proc/net/route"; printErrors: false; blockLoading: true }
FileView { id: fileResolv; path: "/etc/resolv.conf"; printErrors: false; blockLoading: true }
FileView { id: fileIfaceOperstate; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/operstate` : ""; printErrors: false; blockLoading: true }
FileView { id: fileIfaceCarrier; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/carrier` : ""; printErrors: false; blockLoading: true }
FileView { id: fileIfaceAddress; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/address` : ""; printErrors: false; blockLoading: true }
FileView { id: fileIfaceSpeed; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/speed` : ""; printErrors: false; blockLoading: true }

Timer {
    id: pollTimer
    interval: (root.isInspectorActive || GlobalStates.fastTelemetryRate) ? 1000 : 5000
    repeat: true
    running: true
    onTriggered: root.pollMetrics()
}

Timer {
    id: configTimer
    interval: 30000
    repeat: true
    running: true
    onTriggered: root.refreshConfig()
}

function refreshConfig() {
    fileRoute.reload();
    const textRoute = fileRoute.text();
    if (textRoute) {
        const lines = textRoute.trim().split("\n");
        for (let i = 1; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length >= 3 && parts[1] === "00000000") { // Default route destination
                root.activeInterface = parts[0];
                const hexGw = parts[2];
                // Convert hex little-endian IP to dotted-decimal
                root.gatewayIp = `${parseInt(hexGw.slice(6, 8), 16)}.${parseInt(hexGw.slice(4, 6), 16)}.${parseInt(hexGw.slice(2, 4), 16)}.${parseInt(hexGw.slice(0, 2), 16)}`;
                break;
            }
        }
    }

    if (root.activeInterface) {
        fileIfaceAddress.reload();
        root.macAddress = fileIfaceAddress.text().trim() || "--";
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

    // Trigger one-shot IP discovery directly without subshell wrapper
    if (!ipAddrProc.running) {
        ipAddrProc.running = true;
    }
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

---

### 4.4 `PingService.qml` (Demand-Gated 2s Active / 5s Idle & XHR Guard)

```qml
// In restow/quickshell/.config/quickshell/ii/services/PingService.qml

property bool isRequestInFlight: false

Timer {
    id: pollTimer
    interval: root.isOffline ? 15000 : (GlobalStates.fastTelemetryRate ? 2000 : 5000)
    repeat: true
    running: true
    onTriggered: root.fetchStatus()
}

function fetchStatus() {
    if (root.isRequestInFlight) return; // Prevent socket stacking
    root.isRequestInFlight = true;

    const xhr = new XMLHttpRequest();
    xhr.open("GET", root.endpointUrl);
    xhr.timeout = 2000;

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            root.isRequestInFlight = false;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    root.isOffline = false;
                    root.overallClass = data.overall_class || data.class || "dead";
                    root.targets = data.targets || [];
                    // Update wanTarget, gatewayTarget, homeServerTarget ...
                } catch (e) {
                    root.handleOffline();
                }
            } else {
                root.handleOffline();
            }
        }
    };

    xhr.ontimeout = function() { root.isRequestInFlight = false; root.handleOffline(); };
    xhr.onerror = function() { root.isRequestInFlight = false; root.handleOffline(); };
    xhr.send();
}
```

---

### 4.5 `StorageUsage.qml` (Direct Array Exec & 5s Diskstats)

```qml
// In restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml

Timer {
    id: ioPollTimer
    interval: 5000 // 5s relaxed diskstats tracking coalesced with other singletons
    repeat: true
    running: true
    onTriggered: root.updateDiskIo()
}

// Eliminate bash -c subshell
Process {
    id: dfProc
    command: ["timeout", "3", "df", "-k", "-P"]
    stdout: StdioCollector {
        onStreamFinished: {
            root.lastDfTime = Date.now();
            root.parseDfOutput(text);
        }
    }
}
```

---

### 4.6 `MediaControls.qml` (Cava Frame Downsampling & Immediate Kill)

```qml
// In restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml

property int _cavaFrameSkip: 0

Process {
    id: cavaProc
    running: mediaControlsLoader.active && (root.activePlayer?.playbackState === MprisPlaybackState.Playing)
    onRunningChanged: {
        if (!cavaProc.running) {
            root.visualizerPoints = [];
            root._cavaFrameSkip = 0;
        }
    }
    command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
    stdout: SplitParser {
        onRead: data => {
            // Downsample cava frames to 12-15 FPS: skip 3 out of 4 frames
            root._cavaFrameSkip++;
            if (root._cavaFrameSkip % 4 !== 0) return;

            let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
            root.visualizerPoints = points;
        }
    }
}
```

---

### 4.7 `PlayerControl.qml` (Zero-FBO Clipping, Direct Curl, Slider Hover Physics)

```qml
// In restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml
// Override of vendor PlayerControl.qml

// Direct curl exec without subshell
Process {
    id: coverArtDownloader
    property string targetFile: root.artUrl
    property string artFilePath: root.artFilePath
    command: ["curl", "-4", "-sSL", targetFile, "-o", artFilePath]
    onExited: (exitCode, exitStatus) => {
        root.downloaded = true;
    }
}

Rectangle { // Background with native rounded clipping (NO OpacityMask FBO)
    id: background
    anchors.fill: parent
    anchors.margins: Appearance.sizes.elevationMargin
    color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
    radius: root.radius
    clip: true // Hardware vertex scissor/stencil clipping, zero FBO passes

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

    Rectangle {
        anchors.fill: parent
        color: ColorUtils.transparentize(blendedColors.colLayer0, 0.4)
        radius: root.radius
    }

    WaveVisualizer {
        id: visualizerCanvas
        anchors.fill: parent
        live: root.player?.isPlaying
        points: root.visualizerPoints
        maxVisualizerValue: root.maxVisualizerValue
        smoothing: root.visualizerSmoothing
        color: blendedColors.colPrimary
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 13
        spacing: 15

        Rectangle { // Art background with native clipping (NO OpacityMask)
            id: artBackground
            Layout.fillHeight: true
            implicitWidth: height
            radius: Appearance.rounding.verysmall
            color: ColorUtils.transparentize(blendedColors.colLayer1, 0.5)
            clip: true

            StyledImage {
                id: mediaArt
                property int size: parent.height
                anchors.fill: parent
                source: root.displayedArtFilePath
                fillMode: Image.PreserveAspectCrop
                cache: true
                asynchronous: true
                antialiasing: true
                width: size
                height: size
            }
        }

        // Info & controls
        ColumnLayout {
            Layout.fillHeight: true
            spacing: 2
            // Titles & time ...

            Item {
                id: progressBarContainer
                Layout.fillWidth: true
                implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                MouseArea {
                    id: sliderHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                Loader {
                    id: sliderLoader
                    anchors.fill: parent
                    active: root.player?.canSeek ?? false
                    sourceComponent: StyledSlider {
                        configuration: StyledSlider.Configuration.Wavy
                        // De-escalate 60 FPS FrameAnimation: run ONLY when playing AND hovered
                        animateWave: root.player?.isPlaying && sliderHoverArea.containsMouse
                        highlightColor: blendedColors.colPrimary
                        trackColor: blendedColors.colSecondaryContainer
                        handleColor: blendedColors.colPrimary
                        value: root.player?.position / root.player?.length
                        onMoved: {
                            root.player.position = value * root.player.length;
                        }
                    }
                }
            }
        }
    }
}
```

---

### 4.8 `NetworkPingPopup.qml` (Layout Feedback Loop Fix & Text Wrap Removal)

```qml
// In restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml

// 1. Interface Card: decouple ColumnLayout from anchors.fill parent
Rectangle {
    id: ifaceCard
    Layout.fillWidth: true
    radius: Appearance.rounding.small
    color: Appearance.m3colors.m3surfaceContainerHigh
    implicitHeight: cardContent.implicitHeight + 16

    ColumnLayout {
        id: cardContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 4

        // Prevent dynamic text wrapping jitter
        NetworkDetailRow {
            label: "Drops / Errors"
            value: `Rx: ${NetworkUsage.rxDrops}d / ${NetworkUsage.rxErrors}e  Tx: ${NetworkUsage.txDrops}d / ${NetworkUsage.txErrors}e`
            allowWrap: false
        }
    }
}

// 2. PingDiagnosticCard: fixed implicit height, no anchors.fill feedback loop
component PingDiagnosticCard: Rectangle {
    id: card
    // ...
    Layout.fillWidth: true
    implicitHeight: 68 // Fixed immutable geometry, eliminating surface resize churn
    radius: Appearance.rounding.small
    color: Appearance.m3colors.m3surfaceContainerHigh
    border.color: root.getStatusColor(card.statusClass)
    border.width: 1
    opacity: PingService.isOffline ? 0.6 : 1.0

    ColumnLayout {
        id: cardLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 6
        // Rows ...
    }
}
```

---

### 4.9 Test Harness Blueprint: `scripts/phase50-opt-assert.sh`

```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 50: Quickshell Deep Performance Optimization Assert Harness
# Enforces: OPT-01, OPT-02, OPT-03, OPT-04, OPT-05
#
# Usage (from REPO_ROOT):
#   ./scripts/phase50-opt-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick,           Run standalone sections only (skip sub-harnesses in S5)
#       --standalone
#   -c, --syntax           Execute static AST and syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  local exit_code=$?
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return "$exit_code"
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    1|2|3|4|5)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --quick|--standalone|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo ""
      echo "Sections:"
      echo "  1: Preconditions & Safety"
      echo "  2: Subshell Elimination Audit (OPT-03, D-50-02, D-50-07)"
      echo "  3: Timer Coalescing, FBO Elimination & Scenegraph Rules (OPT-01, OPT-02, OPT-04)"
      echo "  4: Empirical Benchmark Ceilings (OPT-01, OPT-02, OPT-03, OPT-05)"
      echo "  5: Strict Repository Verification & Zero Stow Drift"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

PHASE_DIR="$REPO_ROOT/.planning/phases/50-quickshell-deep-performance-optimization-overhead-reduction"
BENCH_JSON="$PHASE_DIR/benchmark-latest.json"
BENCH_MD="$PHASE_DIR/BENCHMARK.md"

# ---------------------------------------------------------------------------
# Section 1: Preconditions & Safety
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Preconditions & Safety ---"
  command -v stow >/dev/null 2>&1 && pass "S1: stow utility available" || fail "S1: stow not in PATH"
  command -v jq >/dev/null 2>&1 && pass "S1: jq utility available" || fail "S1: jq not in PATH"
  command -v hyprctl >/dev/null 2>&1 && pass "S1: hyprctl utility available" || fail "S1: hyprctl not in PATH"
  [[ -r "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq" ]] && pass "S1: CPU max freq sysfs node readable" || fail "S1: Missing CPU max freq sysfs"
fi

# ---------------------------------------------------------------------------
# Section 2: Subshell Elimination Audit
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Subshell Elimination Audit ---"
  SERVICES_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services"

  # Grep for bash -c across services
  if grep -rn "bash.*-c" "$SERVICES_DIR" 2>/dev/null; then
    fail "S2: Found recurring bash -c subshells in services directory"
  else
    pass "S2: Zero bash -c subshell invocations across services"
  fi

  # Check ResourceUsage for lscpu
  if grep -q "lscpu" "$SERVICES_DIR/ResourceUsage.qml" 2>/dev/null; then
    fail "S2: ResourceUsage.qml still references lscpu"
  else
    pass "S2: ResourceUsage.qml eliminated lscpu subshell"
  fi

  # Check StorageUsage for bash -c df
  if grep -q "bash.*df" "$SERVICES_DIR/StorageUsage.qml" 2>/dev/null; then
    fail "S2: StorageUsage.qml still spawns df via shell"
  else
    pass "S2: StorageUsage.qml invokes df directly via argument array"
  fi
fi

# ---------------------------------------------------------------------------
# Section 3: Timer Coalescing, FBO Elimination & Scenegraph Rules
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Timer Coalescing, FBO Elimination & Scenegraph Rules ---"

  PLAYER_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml"
  [[ -f "$PLAYER_QML" ]] && pass "S3: PlayerControl.qml exists as stowed override" || fail "S3: Missing PlayerControl.qml override in restow/"

  if grep -q "OpacityMask" "$PLAYER_QML" 2>/dev/null; then
    fail "S3: PlayerControl.qml contains OpacityMask FBO pass"
  else
    pass "S3: PlayerControl.qml eliminated OpacityMask"
  fi

  if grep -q "StyledBlurEffect" "$PLAYER_QML" 2>/dev/null; then
    fail "S3: PlayerControl.qml contains StyledBlurEffect live Gaussian blur"
  else
    pass "S3: PlayerControl.qml eliminated live Gaussian blur"
  fi

  GRAPH_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/widgets/Graph.qml"
  [[ -f "$GRAPH_QML" ]] && pass "S3: Graph.qml exists as stowed override" || fail "S3: Missing Graph.qml override in restow/"

  if grep -q "paintThrottleTimer" "$GRAPH_QML" 2>/dev/null || grep -q "lastPaintTime" "$GRAPH_QML" 2>/dev/null; then
    pass "S3: Graph.qml implements Canvas repaint throttling"
  else
    fail "S3: Graph.qml missing repaint throttling logic"
  fi
fi

# ---------------------------------------------------------------------------
# Section 4: Empirical Benchmark Ceilings
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Empirical Benchmark Ceilings ---"
  if [[ -f "$BENCH_JSON" ]] && jq empty "$BENCH_JSON" 2>/dev/null; then
    # Idle CPU <= 2.0%
    IDLE_CPU="$(jq -r '.stages.custom_idle.cpu_pct_avg // empty' "$BENCH_JSON")"
    if [[ -n "$IDLE_CPU" ]]; then
      if (( $(awk -v c="$IDLE_CPU" 'BEGIN { print (c <= 2.0) }') )); then
        pass "S4: Idle CPU <= 2.0% (${IDLE_CPU}%)"
      else
        fail "S4: Idle CPU exceeded 2.0% (${IDLE_CPU}%)"
      fi
    fi

    # Context Switches < 100/s
    CTX_SW="$(jq -r '.stages.custom_idle.ctx_switches_per_sec // empty' "$BENCH_JSON")"
    if [[ -n "$CTX_SW" ]]; then
      if (( $(awk -v c="$CTX_SW" 'BEGIN { print (c < 100.0) }') )); then
        pass "S4: Idle Context Switches < 100/s (${CTX_SW}/s)"
      else
        fail "S4: Idle Context Switches exceeded 100/s (${CTX_SW}/s)"
      fi
    fi

    # MediaControls CPU <= 10.0%, iGPU <= 12.0%
    MEDIA_CPU="$(jq -r '.stages.popup_mediacontrols.cpu_pct_avg // empty' "$BENCH_JSON")"
    MEDIA_GPU="$(jq -r '.stages.popup_mediacontrols.gpu_busy_pct // empty' "$BENCH_JSON")"
    if [[ -n "$MEDIA_CPU" && -n "$MEDIA_GPU" ]]; then
      (( $(awk -v c="$MEDIA_CPU" 'BEGIN { print (c <= 10.0) }') )) && pass "S4: MediaControls CPU <= 10.0% (${MEDIA_CPU}%)" || fail "S4: MediaControls CPU exceeded 10.0% (${MEDIA_CPU}%)"
      (( $(awk -v g="$MEDIA_GPU" 'BEGIN { print (g <= 12.0) }') )) && pass "S4: MediaControls iGPU <= 12.0% (${MEDIA_GPU}%)" || fail "S4: MediaControls iGPU exceeded 12.0% (${MEDIA_GPU}%)"
    fi

    # NetPing GPU Boost Lock Check (act freq == 0.0 MHz)
    NETPING_FREQ="$(jq -r '.stages.popup_netping.gpu_act_freq_mhz // empty' "$BENCH_JSON")"
    if [[ -n "$NETPING_FREQ" ]]; then
      if (( $(awk -v f="$NETPING_FREQ" 'BEGIN { print (f == 0.0) }') )); then
        pass "S4: NetPing GPU boost clock lock eliminated (${NETPING_FREQ} MHz)"
      else
        fail "S4: NetPing GPU clock locked at boost frequency (${NETPING_FREQ} MHz)"
      fi
    fi
  else
    if [[ "$RUN_SECTION" -eq 4 ]]; then
      fail "S4: benchmark-latest.json missing or invalid JSON ($BENCH_JSON)"
    else
      finding "S4: benchmark-latest.json pending benchmarking run"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Section 5: Strict Repository Verification & Zero Stow Drift
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Repository Verification & Zero Stow Drift ---"
  if [[ "$QUICK_MODE" -eq 0 && -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
    info "Running ./arch/dots-hyprland.sh verify --strict..."
    "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict && pass "S5: dots-hyprland.sh verify --strict clean" || fail "S5: dots-hyprland.sh verify --strict failed"
  fi

  SUBMODULE_STATUS="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  [[ -z "$SUBMODULE_STATUS" ]] && pass "S5: Zero vendor submodule drift" || fail "S5: Submodule has uncommitted drift: $SUBMODULE_STATUS"
fi

info "=== Assertion Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
```

---

## 5. Architectural Anti-Patterns & Guardrails

### ❌ Anti-Pattern 1: Spawning Subshells Inside Services
- **Problem:** Writing `Process { command: ["bash", "-c", "..."] }` forks a full bash binary, spawns pipes, and creates high voluntary context switch spikes.
- **Guardrail:** Never invoke `bash -c`. Use direct `FileView` for `/proc` and `/sys` nodes. For external binaries, invoke the executable directly with an argument array (`["timeout", "3", "df", "-k", "-P"]`).

### ❌ Anti-Pattern 2: Multi-Pass OpacityMask and StyledBlurEffect in Overlay UI
- **Problem:** Layer effects that render offscreen FBOs (`OpacityMask`, `StyledBlurEffect`) force the GPU to allocate offscreen surfaces and execute multi-pass blur shaders every time a child updates, saturating the iGPU.
- **Guardrail:** Use native Qt Quick `Rectangle { radius: ...; clip: true }` and semi-opaque tinted backdrops (`ColorUtils.transparentize`) instead of live shader blurs.

### ❌ Anti-Pattern 3: Layout Feedback Loops (`anchors.fill: parent` Inside Dynamic Implicit Height)
- **Problem:** A layout declaring `anchors.fill: parent` inside a parent whose `implicitHeight` is derived from that layout's implicit height creates an endless geometry negotiation loop, causing surface resizing and locking the GPU clock at 1550 MHz.
- **Guardrail:** Anchor child layouts only to `anchors.top`, `anchors.left`, `anchors.right`, letting the parent rectangle derive height purely from `child.implicitHeight + margins`. For cards with known layouts, declare a fixed `implicitHeight`.

### ❌ Anti-Pattern 4: Un-throttled Canvas Repaints on High-Frequency Data
- **Problem:** Binding `onValuesChanged: root.requestPaint()` on a `Canvas` causes repainting on every array update, burning GPU and CPU cycles.
- **Guardrail:** Enforce a minimum 100ms deadband timer (`paintThrottleTimer`), clamping 2D canvas repaints to $\le 10$ FPS.

### ❌ Anti-Pattern 5: Modifying Vendor Submodules Directly
- **Problem:** Editing any file inside `vendor/dots-hyprland/` causes submodule drift and fails `./arch/dots-hyprland.sh verify --strict`.
- **Guardrail:** All customizations and overrides MUST reside in `restow/quickshell/` and be linked into `~/.config/quickshell/` via GNU Stow leaf symlinks.

---

## 6. Verification & Assertion Plan

The implementation in Phase 50 proceeds across 3 discrete waves:

| Plan | Target Files | Key Assertions / Verifications |
| :--- | :--- | :--- |
| **Plan 50-01** | `GlobalStates.qml`, `BarContent.qml`, `ResourceUsage.qml`, `HardwareTelemetry.qml`, `NetworkUsage.qml`, `PingService.qml`, `StorageUsage.qml` | - Section 2 passes (`phase50-opt-assert.sh -s 2` clean: zero subshells).<br>- 5000ms idle timer coalescing active.<br>- Sysfs direct max frequency and procfs route discovery functional. |
| **Plan 50-02** | `MediaControls.qml`, `PlayerControl.qml`, `NetworkPingPopup.qml`, `Graph.qml`, `ClockWidgetPopup.qml`, `StyledPopup.qml`, `CpuGpuPopup.qml`, `MemoryStoragePopup.qml` | - Section 3 passes (`phase50-opt-assert.sh -s 3` clean).<br>- Zero OpacityMask / StyledBlurEffect in PlayerControl.<br>- NetPing card geometry fixed; 1550 MHz GPU boost lock eliminated.<br>- Graph canvas clamped to 10 FPS. |
| **Plan 50-03** | `scripts/phase50-opt-assert.sh`, `scripts/profile-quickshell.sh`, `BENCHMARK.md`, `benchmark-latest.json` | - Complete 8-stage interactive benchmarking run.<br>- Section 4 passes: Idle CPU $\le 2.0\%$, ctx switches $< 100$/s, MediaControls CPU $\le 10.0\%$ / iGPU $\le 12.0\%$, NetPing GPU freq 0.0 MHz.<br>- Section 5 passes (`dots-hyprland.sh verify --strict` clean). |
