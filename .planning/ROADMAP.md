# Roadmap: Quickshell Desktop Shell

## Milestones

- ✅ **v0.8 Notification Experience & Shell Interaction Polish** — Phases 38–41 (shipped 2026-09-25) — [Archive](milestones/v0.8-ROADMAP.md)
- 📋 **v0.9 Top Status Bar Resource Components & Hardware Telemetry** — Phases 42–47 (in progress)

## Phases

<details>
<summary>✅ v0.8 Notification Experience & Shell Interaction Polish (Phases 38–41) — SHIPPED 2026-09-25</summary>

- [x] **Phase 38: Power Profiles Daemon System Integration** (1/1 plans) — completed 2026-09-23
- [x] **Phase 39: Dynamic Media Popup Anchoring** (1/1 plans) — completed 2026-09-23
- [x] **Phase 40: Notification Center Quick-Dismiss & Smart Interaction** (3/3 plans) — completed 2026-09-24
- [x] **Phase 40.1: Clock Pill Padding and Unified Volume Ceiling Ergonomics (INSERTED)** (2/2 plans) — completed 2026-09-24
- [x] **Phase 41: End-to-End Verification & Repository Integrity** (2/2 plans) — completed 2026-09-25

See full archived phase details in [milestones/v0.8-ROADMAP.md](milestones/v0.8-ROADMAP.md).

</details>

### 📋 v0.9 Top Status Bar Resource Components & Hardware Telemetry (Phases 42–47)

- [x] **Phase 42: Telemetry Services & Sensor Infrastructure** (4 plans) (completed 2026-09-25)
- [x] **Phase 43: CPU & GPU Component (Pill & Popup)** (4 plans) (completed 2026-09-26)
- [x] **Phase 43.1: Quickshell Performance Profiling and Resource Optimization (INSERTED)** (3 plans) (completed 2026-09-27)
- [x] **Phase 43.2: Quickshell Profiling Harness Calibration & Empirical Baseline Capture (INSERTED)** (2 plans) (completed 2026-09-27)
- [x] **Phase 43.3: Quickshell Benchmark Bottleneck Analysis & Optimization Strategy (INSERTED)** (1 plan) (completed 2026-09-27)
- [x] **Phase 43.4: Quickshell Targeted Optimization & Empirical Verification (INSERTED)** (3 plans) (completed 2026-09-27)
- [x] **Phase 43.5: CPU/GPU Dynamic Telemetry, Top Process Attribution Tree & Hover Delay Ergonomics (INSERTED)** (3 plans) (completed 2026-09-28)
- [x] **Phase 43.6: Remove Top Processes & Streamline CpuGpuPopup Layout (INSERTED)** (2 plans) (completed 2026-09-28)
- [x] **Phase 44: Memory & Storage Component (Pill & Popup)** (3 plans) (completed 2026-09-28)
- [x] **Phase 45: Network & Multi-Target Ping Component (Pill & Popup)** (3 plans) (completed 2026-09-29)
- [x] **Phase 46: Left-Zone Integration, Verification & Repository Integrity** (2 plans) (completed 2026-09-29)
- [ ] **Phase 47: Center-Zone Layout Reorganization** (0 plans)

## Phase Details

### Phase 42: Telemetry Services & Sensor Infrastructure

**Goal**: Implement backend telemetry services and data acquisition singletons for CPU/GPU hardware sensors, multi-mount storage discovery, and local ping daemon bridging.  
**Depends on**: Phase 41  
**Requirements**: Foundation for CPUGPU-01..04, MEMDSK-01..04, NETPING-01..05  
**Plans**: 4 plans (00, 01, 02, 03)

Success criteria:

1. `HardwareTelemetry.qml` reads CPU package temp (`coretemp`), RAPL power draw (with unprivileged fallback), frequencies, and Intel iGPU active load (RC6 residency delta) and clock MHz without blocking the event loop.
2. `StorageUsage.qml` asynchronously enumerates mount points (`df`) every 15–30s into a reactive model containing root `/`, physical partitions (`/boot`, `/mnt/windows`, `/mnt/hdd`), and FUSE cloud mounts (`GoogleDrive`).
3. `PingService.qml` polls `http://127.0.0.1:8765/api/status` at 5s intervals exposing latency for WAN (`8.8.8.8`), Gateway (`192.168.0.1`), and Home Server (`192.168.0.104`) with offline fallback.
4. `ResourceUsage.qml` exposes extended memory fields (`memoryAvailable`, `memoryBuffers`, `memoryCached`).

### Phase 43: CPU & GPU Component (Pill & Popup)

**Goal**: Build dedicated `CpuGpuPill.qml` status bar pill and interactive `CpuGpuPopup.qml` inspector overlay.  
**Depends on**: Phase 42  
**Requirements**: CPUGPU-01, CPUGPU-02, CPUGPU-03, CPUGPU-04  
**Plans**: 7/7 plans executed

- [x] 43-07-PLAN.md

- [x] 43-05-PLAN.md
- [x] 43-06-PLAN.md

- [x] 43-01-PLAN.md
- [x] 43-02-PLAN.md
- [x] 43-03-PLAN.md
- [x] 43-04-PLAN.md

Success criteria:

1. Status bar pill displays live CPU % and GPU % with distinct Material Symbols icons (`planner_review`, `speed`) and 250ms M3 emphasized deceleration width resizing.
2. Popup inspector displays CPU load %, package temperature (°C), wattage draw, clock speeds (MHz), and Intel iGPU load %, average load, frequency (MHz), and thermal status.
3. Synchronized two-tier alert coloring (Amber at 70%, Red at 90%) applied consistently across pill icons, text labels, and popup headers.

### Phase 43.1: Quickshell Performance Profiling and Resource Optimization (INSERTED)

**Goal:** Profile Quickshell CPU, GPU, memory, and timer/process usage across components and singletons (telemetry services, polling loops, animations). Isolate the root causes of elevated resource consumption, optimize hot routines, and streamline or remove unnecessary components to ensure the status bar remains lightweight and resource-efficient.  
**Requirements**: PERF-01, PERF-02, PERF-03  
**Depends on:** Phase 43  
**Plans:** 3/3 plans complete

Success criteria:

1. Benchmark baseline and per-component CPU, GPU, and memory footprints across Quickshell runtime (including `HardwareTelemetry`, `ResourceUsage`, `StorageUsage`, `PingService`, and active pills/popups).
2. Identify specific bottlenecks, runaway intervals, redundant polling loops, or expensive QML bindings/animations.
3. Apply targeted optimizations, throttles, or removals for high-cost components.
4. Validate reduced resource overhead without degrading core shell stability or UX.

Plans:
**Wave 1**

- [x] 43.1-01-PLAN.md — Baseline & Staged Resource Profiling Harness

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 43.1-02-PLAN.md — Staged Attribution Matrix, Dual-State Profiling & Comprehensive Reporting

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 43.1-03-PLAN.md — Performance Assertion Suite & Evidence-Based Optimization Framework

### Phase 43.2: Quickshell Profiling Harness Calibration & Empirical Baseline Capture (INSERTED)

**Goal:** Calibrate `scripts/profile-quickshell.sh` input coordinate scaling for Wayland, implement automated layer-shell pop-up verification (`quickshell:popup`), aggregate multi-threaded context switches, remove synthetic attribution calculations, and capture genuine empirical reference baselines for Quickshell under upstream baseline, full idle, and verified active pop-up states.  
**Depends on:** Phase 43.1  
**Plans:** 2 plans

Success criteria:

1. Mouse movement coordinates scaled correctly for Wayland uinput device; layer detection via `hyprctl layers` confirms `quickshell:popup` before measuring active UI state.
2. User notification protocol implemented in harness and chat (prominent warnings before mouse movement, notifications on completion).
3. Thread-wide context switch aggregation implemented across all worker threads in `/proc/$PID/task/*/status`.
4. Synthetic attribution weight map removed; reporting truthfully reflects measured vs unmeasured states.
5. Calibrated baseline capture executed, outputting verified `BENCHMARK.md` and `benchmark-latest.json`.

Plans:
**Wave 1**

- [x] 43.2-01-PLAN.md — Profiling Harness Calibration, Layer Verification & Multi-Thread Telemetry

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 43.2-02-PLAN.md — Calibrated Empirical Baseline Capture & Report Generation

### Phase 43.3: Quickshell Benchmark Bottleneck Analysis & Optimization Strategy (INSERTED)

**Goal:** Conduct in-depth diagnostic analysis of calibrated benchmark findings (3,120 reads/s idle churn, +8.14% CPU active pop-up overhead, +14.4% iGPU load), analyze source QML bottlenecks, evaluate optimization trade-offs, and establish a data-driven optimization decision matrix prior to code implementation.  
**Depends on:** Phase 43.2  
**Plans:** 1/1 plans complete

Success criteria:

1. Root-cause analysis of idle syscall churn (`ResourceUsage.qml` 1ms timer, `/proc/meminfo` & `/proc/stat` reloads).
2. Root-cause analysis of active pop-up overhead (`HardwareTelemetry.qml` fast-polling, 23 sensor FileViews, circular meter animations, StyledPopup blur/shadows).
3. Evaluation of secondary background pollers (`PingService.qml`, `Voice.qml`, `StorageUsage.qml`).
4. Architecture decision record (`43.3-DECISIONS.md`) formalizing consensus on optimization knobs, target thresholds, and rollout boundaries across upcoming phases.

Plans:
**Wave 1**

- [x] 43.3-01-PLAN.md — Bottleneck Root-Cause Dissection & Architectural Optimization Decision Matrix

### Phase 43.4: Quickshell Targeted Optimization & Empirical Verification (INSERTED)

**Goal:** Implement prioritized QML optimizations formulated in Phase 43.3 (ResourceUsage timer fix D-02, history array GC gating D-03, legacy Resources pill retirement D-04, HardwareTelemetry two-tier sensor sweeping D-05/D-06/D-07/D-08, and CpuGpuPopup/Pill scenegraph throttling D-09/D-10/D-11/D-12), then execute a complete re-benchmarking run via `scripts/profile-quickshell.sh` to capture both clean upstream baseline and optimized custom shell side-by-side in `BENCHMARK.md`.  
**Depends on:** Phase 43.3  
**Requirements**: PERF-01, PERF-02, PERF-03  
**Plans:** 3 plans

Plans:
**Wave 1**

- [x] 43.4-01-PLAN.md — Service Layer Optimizations & Bar Layout Cleanup

**Wave 2**

- [x] 43.4-02-PLAN.md — UI & Popup Scenegraph Optimization & Assertion Alignment

**Wave 3**

- [x] 43.4-03-PLAN.md — Empirical Benchmark Re-run & Performance Verification

Success criteria:

1. `ResourceUsage.qml` configured with declarative timer initialized to 3000ms idle interval (and `Component.onCompleted` initial fetch), eliminating the `interval: 1` bug and dropping idle read syscalls from ~3,120/s to <80/s.
2. `ResourceUsage.qml` history array updates gated on `isInspectorActive`, eliminating idle V8/QJSEngine garbage collection spread copying.
3. Legacy `Resources` pill retired and removed from `BarContent.qml` and `VerticalBarContent.qml`, leaving `ResourceUsage.qml` dormant and clearing the Left Zone for Phase 44.
4. `HardwareTelemetry.qml` implements Two-Tier Demand-Gated Sweeping (Tier 1: 3 files in idle every 3s; Tier 2: 28 files in active every 1s with frame-0 zero-latency synchronization on popup open).
5. Scenegraph throttling applied to `CpuGpuPopup.qml` and `CpuGpuPill.qml` (gated critical alert pulse animation, 1% integer deadband quantization, and `root.active` binding guards) retaining all 20 thread meters while reducing active iGPU rendering overhead.
6. Side-by-side re-benchmarking executed via `scripts/profile-quickshell.sh`, capturing upstream baseline, idle, and active UI performance metrics in `BENCHMARK.md`.

### Phase 43.5: CPU/GPU Dynamic Telemetry, Top Process Attribution Tree & Hover Delay Ergonomics (INSERTED)

**Goal:** Eliminate all hardcoded hardware strings (CPU, GPU, Platform/Motherboard names and core topology counts) with dynamic sysfs/procfs detection, reorder CpuGpuPopup layout (GPU below CPU, Platform on right), introduce top CPU and GPU process inspection with hierarchical tree/group attribution for multi-process applications (e.g. Chrome tabs), and implement a 1-second hover intent delay across all top status bar popups in `StyledPopup.qml`.  
**Depends on:** Phase 43.4  
**Requirements**: CPUGPU-05, CPUGPU-06, CPUGPU-07, POPUP-01  
**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 43.5-01-PLAN.md — Wave 0 Assert Harness, Universal Hover Intent Delay & Dynamic Telemetry Discovery

**Wave 2**

- [x] 43.5-02-PLAN.md — Single-Pass Process Attribution Tree & DRM GPU Accounting

**Wave 3**

- [x] 43.5-03-PLAN.md — Layout Restructuring, Demand-Gated Process Trees & Full Suite Verification

Success criteria:

1. CPU name, GPU name, and Platform/Motherboard name dynamically resolved from sysfs/procfs (`/proc/cpuinfo`, `/sys/class/drm/card*`, `/sys/class/dmi/id/board_name`) with graceful fallbacks when sensors or names are unavailable.
2. Core and thread topology dynamically discovered without hardcoding core counts or assuming fixed P/E hybrid topologies; non-hybrid CPUs render standard core views.
3. `CpuGpuPopup.qml` layout restructured: Left section contains CPU on top with GPU below it; Right section hosts Platform/Motherboard telemetry.
4. Top 5–10 process inspector implemented with dual views (Top CPU and Top GPU) featuring hierarchical child-process grouping (aggregating browser/child worker usage under root parent process) active only when popup is open.
5. `StyledPopup.qml` implements a ~1000ms hover delay timer before opening popups, preventing accidental triggers when cursor sweeps across top bar widgets while preserving smooth transit across open popups.

### Phase 43.6: Remove Top Processes & Streamline CpuGpuPopup Layout (INSERTED)

**Goal:** Simplify `CpuGpuPopup.qml` by removing top CPU and GPU process attribution trees (eliminating background process polling and script complexity) and restructuring the popup into a clean two-column layout: Left column hosting CPU (top) and GPU (bottom); Right column hosting Platform / Motherboard telemetry all in one column.  
**Depends on:** Phase 43.5  
**Requirements**: CPUGPU-05, CPUGPU-06  
**Plans:** 2/2 plans complete

Success criteria:

1. Top CPU and GPU process attribution trees, background process polling timers, and process aggregation scripts removed from `CpuGpuPopup.qml`.
2. `CpuGpuPopup.qml` left column restructured with CPU card on top and GPU card on the bottom.
3. `CpuGpuPopup.qml` right column restructured with Motherboard/Platform telemetry unified in a single column.
4. Clean visual presentation with zero layout overflow and verified popup open/close behavior.

Plans:

- [ ] TBD (run /gsd-plan-phase 43.6 to break down)

### Phase 44: Memory & Storage Component (Pill & Popup)

**Goal**: Build dedicated `MemoryStoragePill.qml` status bar pill and interactive `MemoryStoragePopup.qml` inspector overlay.  
**Depends on**: Phase 42  
**Requirements**: MEMDSK-01, MEMDSK-02, MEMDSK-03, MEMDSK-04  
**Plans**: 3/3 plans executed

- [x] 44-03-PLAN.md

- [x] 44-01-PLAN.md
- [x] 44-02-PLAN.md

Success criteria:

1. Status bar pill displays live RAM usage (`X.X/Y.Y GB` or `%`) and root filesystem `/` usage (`ZZ%`).
2. Popup inspector displays detailed memory allocation tiers: Used, Available, Cached, Buffers, Free, and Swap (with dynamic swap reveal when > 0%).
3. Storage popup inspector displays clean progress bars for root `/` and all mounted filesystems (physical and FUSE cloud mounts) with used and free space.
4. Storage discovery executes asynchronously via `Process` without causing UI stutter or dropped frames.

### Phase 45: Network & Multi-Target Ping Component (Pill & Popup)

**Goal**: Build dedicated `NetworkPingPill.qml` status bar pill and interactive `NetworkPingPopup.qml` inspector overlay.  
**Depends on**: Phase 42  
**Requirements**: NETPING-01, NETPING-02, NETPING-03, NETPING-04, NETPING-05  
**Plans**: 3/3 plans executed

- [x] 45-01-PLAN.md
- [x] 45-02-PLAN.md
- [x] 45-03-PLAN.md

Success criteria:

1. Status bar pill displays live network throughput rates (Rx/Tx KB/s or MB/s) derived from `/proc/net/dev`.
2. Status bar pill displays **all 3 ping targets** (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) with latency numbers and status colors.
3. Popup inspector displays active NIC interface name, IP address, link speed, and detailed 3-target ping diagnostic cards.
4. Left-clicking the pill or popup action button opens the web ping dashboard at `http://127.0.0.1:8765/` in the default browser.

### Phase 46: Left-Zone Integration, Verification & Repository Integrity

**Goal**: Integrate all 3 pills into `BarContent.qml` Left zone, verify responsive layouts, and create comprehensive automated test harness with strict zero git churn.  
**Depends on**: Phase 43, Phase 44, Phase 45  
**Requirements**: INTG-01, INTG-02, INTG-03  
**Plans**: 2/2 plans executed

- [x] 46-01-PLAN.md
- [x] 46-02-PLAN.md

Success criteria:

1. Three standalone pills replace legacy `Resources.qml` in `BarContent.qml` Left zone alongside `LeftSidebarButton` and `UtilButtons`.
2. Responsive layout adapts cleanly across standard and `useShortenedForm` screen widths without pushing Center Workspaces off-center.
3. All files deployed via GNU Stow leaf symlinks under `restow/quickshell/` without folding parent directories, maintaining `vendor/dots-hyprland` pristine.
4. Consolidated assertion harness (`scripts/phase46-telemetry-assert.sh`) verifies all sensor parsers, daemon bridge, multi-mount discovery, and `arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0`.

### Phase 47: Center-Zone Layout Reorganization

**Goal**: Reorganize the Center Zone in `BarContent.qml` to swap Clock/Date and Weather positions around Workspaces: placing Clock/Date to the left, keeping Workspaces dead-centered, and placing Weather to the right.  
**Depends on**: Phase 46  
**Requirements**: CNTR-01, CNTR-02, CNTR-03  
**Plans:** 0 plans

Success criteria:

1. Clock & Date widget (`ClockWidget` in left center group) is relocated from the right of the middle section to the left of Workspaces (`middleCenterGroup.left`), retaining its click behavior to toggle `GlobalStates.sidebarRightOpen` and responsive date hiding (`showDate` under shortened widths).
2. Workspaces widget (`middleCenterGroup`) remains dead-centered on the display bar (`anchors.horizontalCenter: parent.horizontalCenter`) with uniform 4px spacing on both sides.
3. Weather bar (`WeatherBar` in `weatherGroup`) is relocated from the left of Workspaces to the right of Workspaces (`anchors.left: middleCenterGroup.right`), honoring `Config.options.bar.weather.enable`.
4. `middleSection` wrapper boundary anchors (`middleSection.left` and `middleSection.right`) update cleanly to span between the leftmost center element and the rightmost center element without overlapping or clipping adjacent Left or Right bar zones.
5. Verification via `arch/dots-hyprland.sh verify --strict` passes with zero git churn in `vendor/dots-hyprland`.

Plans:

- [ ] TBD (run /gsd-plan-phase 47 to break down)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---|---|---|
| 38. Power Profiles Daemon System Integration | v0.8 | 1/1 | Complete | 2026-09-23 |
| 39. Dynamic Media Popup Anchoring | v0.8 | 1/1 | Complete | 2026-09-23 |
| 40. Notification Center Quick-Dismiss & Smart Interaction | v0.8 | 3/3 | Complete | 2026-09-24 |
| 40.1. Clock Pill Padding and Unified Volume Ceiling Ergonomics | v0.8 | 2/2 | Complete | 2026-09-24 |
| 41. End-to-End Verification & Repository Integrity | v0.8 | 2/2 | Complete | 2026-09-25 |
| 42. Telemetry Services & Sensor Infrastructure | v0.9 | 4/4 | Complete    | 2026-09-25 |
| 43. CPU & GPU Component (Pill & Popup) | v0.9 | 7/7 | Complete | 2026-09-26 |
| 43.1. Quickshell Performance Profiling and Resource Optimization | v0.9 | 3/3 | Complete    | 2026-09-27 |
| 43.2. Quickshell Profiling Harness Calibration & Empirical Baseline Capture | v0.9 | 2/2 | Complete | 2026-09-27 |
| 43.3. Quickshell Benchmark Bottleneck Analysis & Optimization Strategy | v0.9 | 1/1 | Complete    | 2026-09-27 |
| 43.4. Quickshell Targeted Optimization & Empirical Verification | v0.9 | 3/3 | Complete | 2026-09-27 |
| 43.5. CPU/GPU Dynamic Telemetry, Top Process Attribution Tree & Hover Delay Ergonomics | v0.9 | 3/3 | Complete    | 2026-09-28 |
| 43.6. Remove Top Processes & Streamline CpuGpuPopup Layout | v0.9 | 2/2 | Complete    | 2026-09-28 |
| 44. Memory & Storage Component (Pill & Popup) | v0.9 | 3/3 | Complete    | 2026-09-28 |
| 45. Network & Multi-Target Ping Component (Pill & Popup) | v0.9 | 3/3 | Complete    | 2026-09-29 |
| 46. Left-Zone Integration, Verification & Repository Integrity | v0.9 | 2/2 | Complete    | 2026-09-29 |
| 47. Center-Zone Layout Reorganization | v0.9 | 0/0 | Not Started | - |
