# Phase 42: Telemetry Services & Sensor Infrastructure - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement backend data acquisition singletons and telemetry services in Quickshell (`restow/quickshell/.config/quickshell/ii/services/`) and update the local ping daemon (`stow/system_monitor/.config/system_monitor/ping/server.py`):

1. **Hardware Telemetry Singleton (`HardwareTelemetry.qml`):** Non-blocking acquisition of CPU metrics (overall load, segregated P-core vs E-core load, clock frequencies, EPP energy preference, scaling governor), Intel iGPU UHD 770 metrics (active clock MHz, RC6 residency delta load %, thermal throttling status), and system thermals (CPU package, per-core, NVMe 1 & 2, Motherboard VRM/PCH). Exposes a unified single primary temperature (`packageTemp`) and peak temperature (`peakSystemTemperature`) for status bar pills.
2. **Storage Mount & I/O Engine (`StorageUsage.qml`):** Continuous `/proc/diskstats` tracking exposing live disk I/O % and throughput. Adaptive, pure I/O-driven `df` capacity polling (0 wakeups when idle; updates on active disk write/delete or instant on-demand popup open) discovering physical partitions (`/`, `/boot`, `/mnt/windows`, `/mnt/hdd`) and GoogleDrive FUSE cloud mounts (`gdrive-*`), highlighting the most active disk.
3. **Ping Daemon Server Update & Service Bridge (`PingService.qml` & `server.py`):** Update `stow/system_monitor/.../server.py` `/api/status` endpoint to emit clean structured JSON (eliminating legacy Waybar HTML spans/nerd fonts). `PingService.qml` polls this endpoint asynchronously at 5s intervals (with 15s offline backoff) exposing latencies for WAN (`8.8.8.8`), Gateway (`192.168.0.1`), and Home Server (`192.168.0.104`).
4. **Extended Memory Telemetry (`ResourceUsage.qml`):** Extend the existing `ResourceUsage.qml` singleton to parse and expose `memoryAvailable`, `memoryBuffers`, and `memoryCached` from `/proc/meminfo`.

**Out of scope:**
- Visual status bar pills (`CpuGpuPill.qml`, `MemoryStoragePill.qml`, `NetworkPingPill.qml`) — Phase 43, 44, and 45 own these.
- Visual popup inspector overlays (`CpuGpuPopup.qml`, `MemoryStoragePopup.qml`, `NetworkPingPopup.qml`) — Phase 43, 44, and 45 own these.
- Left zone bar rearrangement in `BarContent.qml` and automated assertion harness — Phase 46 owns this.
- CPU/GPU power wattage readouts — explicitly omitted to guarantee 100% unprivileged execution with zero root/udev dependencies.

</domain>

<decisions>
## Implementation Decisions

### Hardware & Thermal Telemetry (`HardwareTelemetry.qml`)
- **D-01 (Adaptive Polling Cadence):** Poll sysfs nodes at 1000ms when system is active or UI popups are visible, relaxing dynamically to 3000ms when system load is idle. — **Reversibility:** reversible.
- **D-02 (P-Core & E-Core Segregation):** On the host's 13th Gen Intel Core i5-13500 (14 cores, 20 threads), parse `/proc/stat` to expose `pCoreLoad` (average load of CPUs 0–11, up to 4.8 GHz) and `eCoreLoad` (average load of CPUs 12–19, up to 3.5 GHz) alongside `overallCpuLoad`. Expose separate `pCoreFrequencyMhz` and `eCoreFrequencyMhz`, plus a 20-element array for per-thread popup bars. — **Reversibility:** reversible.
- **D-03 (EPP & Frequency Governor):** Expose `energyPerformancePreference` (e.g. `balance_performance`) and `scalingGovernor` (e.g. `powersave`) via `FileView` from `/sys/devices/system/cpu/cpu0/cpufreq/`. — **Reversibility:** reversible.
- **D-04 (Intel iGPU UHD 770 Telemetry):** Expose active render clock (`gt_act_freq_mhz`), compute active `gpuLoad` % from `/sys/class/drm/card1/gt/gt0/rc6_residency_ms` sleep delta over sampling intervals, and expose `gpuThrottled` boolean from `throttle_reason_thermal`. — **Reversibility:** reversible.
- **D-05 (Zero Root / Wattage Omission):** CPU and GPU power wattage measurements are completely omitted from shell telemetry to ensure 100% unprivileged execution in user-space with zero system changes (no udev rules or root capabilities required). — **Reversibility:** reversible.
- **D-06 (Single Bar Pill Temperature vs Full System Thermals):** Expose `packageTemp` (CPU Package id 0 from `hwmon5/temp1_input`) as the primary default temperature for status bar pills; also expose `peakSystemTemperature` (`Math.max(cpu, nvme1, nvme2, vrm)`) and `peakDeviceLabel` for single-metric high-temp alerts without bloating the pill. — **Reversibility:** reversible.
- **D-07 (Extended Motherboard & Drive Thermals):** Expose NVMe 1 (`hwmon1` Samsung 980), NVMe 2 (`hwmon2` Samsung PM9A1), and Motherboard VRM & Chipset (`hwmon3` Gigabyte WMI) temperatures in `HardwareTelemetry.qml` for rich popup inspection cards. — **Reversibility:** reversible.

### Storage & Disks (`StorageUsage.qml`)
- **D-08 (Pure I/O-Driven & On-Demand Polling):** Zero polling of `df` when disk I/O is 0% (idle). Spawns asynchronous `df` process only when active disk writes/reads occur, plus immediate refresh on-demand when the user opens the storage popup inspector. — **Reversibility:** reversible.
- **D-09 (Top Bar Disk I/O Percentage):** Read `/proc/diskstats` via `FileView` to compute real-time `diskIoPercentage` (0–100%) and throughput (Read/Write MB/s), providing an active disk indicator for the top status bar. — **Reversibility:** reversible.
- **D-10 (Active Disk Dynamic Focus):** Expose `activeDisk` so the status bar pill can dynamically highlight whichever disk is actively writing/reading, falling back to Root `/` when idle. — **Reversibility:** reversible.
- **D-11 (Mount Classification & Filtering):** Classify mounts into physical drives (Root `/`, `/mnt/windows`, `/mnt/hdd`, `/boot`) and cloud FUSE mounts (`/home/pera/GoogleDrive/gdrive-*`), filtering out virtual pseudo-filesystems (`tmpfs`, `devtmpfs`, `efivarfs`, `none`). — **Reversibility:** reversible.

### Ping Daemon Bridge (`PingService.qml` & `server.py`)
- **D-12 (Server.py /api/status Payload Clean-up):** Update `stow/system_monitor/.config/system_monitor/ping/server.py` so `/api/status` returns clean structured JSON with `targets` (and named properties `host`, `ms`, `quality`, `text_value`, `class`), eliminating Waybar HTML spans/nerd fonts. Rebuild/restart local docker container so `PingService.qml` consumes clean JSON directly without client-side HTML regex stripping. — **Reversibility:** reversible.
- **D-13 (5s Polling with 15s Offline Backoff):** `PingService.qml` polls `http://127.0.0.1:8765/api/status` at 5s intervals. If the daemon is unreachable or offline, set latency to `"-- ms"`, mark state as `offline`, and back off polling interval to 15s to keep console error logs silent. — **Reversibility:** reversible.
- **D-14 (Three Target Exposure):** Expose distinct reactive properties for WAN (`8.8.8.8`), Gateway (`192.168.0.1`), and Home Server (`192.168.0.104`) with latency numbers and status classes (`good`, `medium`, `bad`, `dead`). — **Reversibility:** reversible.

### Extended Memory (`ResourceUsage.qml`)
- **D-15 (Extended Memory Fields):** Extend existing `ResourceUsage.qml` singleton to parse and expose `memoryAvailable`, `memoryBuffers`, and `memoryCached` from `/proc/meminfo` alongside `memoryUsed` and `memoryTotal`. — **Reversibility:** reversible.

### the agent's Discretion
- Exact smoothing factor for calculating instantaneous `diskIoPercentage` from `/proc/diskstats` ticks.
- Exact JSON key structure in `server.py` for backward compatibility while providing clean `targets` objects.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 42 — Telemetry Services & Sensor Infrastructure goals and success criteria.
- `.planning/REQUIREMENTS.md` lines 10–37 — Milestone v0.9 requirements (CPUGPU-01..04, MEMDSK-01..04, NETPING-01..05, INTG-01..03).
- `.planning/STATE.md` §Milestone v0.9 — Accumulated project state and key decisions.

### Sensor & Telemetry Data Sources
- `/proc/stat` — Aggregate and per-thread CPU utilization ticks (CPUs 0–19).
- `/proc/meminfo` — Memory allocation fields (`MemTotal`, `MemAvailable`, `Buffers`, `Cached`, `SwapTotal`, `SwapFree`).
- `/proc/diskstats` — Sector reads/writes and I/O ticks for `nvme1n1`, `nvme0n1`, and `sda`.
- `/sys/class/hwmon/hwmon5/` — Intel Coretemp package (`temp1_input`) and per-core thermal inputs.
- `/sys/class/hwmon/hwmon1/` & `hwmon2/` — Samsung 980 and PM9A1 NVMe composite temperatures.
- `/sys/class/hwmon/hwmon3/` — Gigabyte WMI motherboard thermal probes (VRM, Chipset, PCIe).
- `/sys/class/drm/card1/gt/gt0/rc6_residency_ms` — Intel UHD 770 RC6 sleep residency for load delta.
- `/sys/class/drm/card1/gt_act_freq_mhz` — Intel UHD 770 active render clock.
- `/sys/devices/system/cpu/cpu*/cpufreq/` — Frequency scaling, EPP, and governor nodes.

### Ping Monitor Daemon
- `stow/system_monitor/.config/system_monitor/ping/server.py` — Ping collector HTTP daemon and API routing.
- `stow/system_monitor/.config/system_monitor/ping/ping.config` — Target host definitions and thresholds.
- `stow/system_monitor/.config/system_monitor/ping/docker-compose.yml` — Container deployment spec.

### Quickshell Services Architecture & Patterns
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` — Existing CPU/RAM polling patterns via `FileView`.
- `restow/quickshell/.config/quickshell/ii/services/Voice.qml` — Singleton service architecture with adaptive polling.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` — Existing resource formatting and threshold alerts.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Quickshell.Io.FileView`: Native C++ element for asynchronous, non-blocking file reads on Linux virtual filesystems (`/proc/` and `/sys/`).
- `Quickshell.Io.Process`: Asynchronous process execution for running non-blocking background CLI commands like `df -h`.
- `QML Timer`: For adaptive 1000ms/3000ms polling intervals and 5s HTTP ping polling.

### Established Patterns
- Singleton Services: Services declare `pragma Singleton` and `pragma ComponentBehavior: Bound` for global accessibility across bar pills and popups.
- Restow Overlay Discipline: Custom services reside in `restow/quickshell/.config/quickshell/ii/services/` and are symlinked with GNU Stow `--no-folding`.
- Non-blocking I/O: UI thread must never stall waiting on child processes or synchronous HTTP requests.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` -> symlinked to `~/.config/quickshell/ii/services/HardwareTelemetry.qml`.
- `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` -> symlinked to `~/.config/quickshell/ii/services/StorageUsage.qml`.
- `restow/quickshell/.config/quickshell/ii/services/PingService.qml` -> symlinked to `~/.config/quickshell/ii/services/PingService.qml`.
- `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` -> overlays vendor `ResourceUsage.qml` with extended memory fields.
- Downstream consumers in Phase 43 (`CpuGpuPill.qml`, `CpuGpuPopup.qml`), Phase 44 (`MemoryStoragePill.qml`, `MemoryStoragePopup.qml`), and Phase 45 (`NetworkPingPill.qml`, `NetworkPingPopup.qml`) bind directly to these singletons.

</code_context>

<specifics>
## Specific Ideas

- **P-Core vs E-Core Visual Readiness:** P-cores (CPUs 0–11) run up to 4.8 GHz with Hyper-Threading; E-cores (CPUs 12–19) run up to 3.5 GHz single-threaded. Segregating them in the service allows the Phase 43 popup to clearly show how workloads are scheduled between heavy foreground apps (P-cores) and background tasks (E-cores).
- **Single Bar Temperature:** The status bar pill should not be cluttered with multiple temperatures. Expose `packageTemp` (CPU Package) as the default primary temperature, with `peakSystemTemperature` guarding against any thermal hotspots across CPU, NVMe, and Motherboard.
- **Dynamic Active Disk Focus:** In addition to standard Root `/` capacity, track live I/O activity so the status bar pill can dynamically switch focus to whichever disk is actively being written to or read from.
- **Server.py Native Clean JSON:** Rather than parsing legacy Waybar HTML spans on the client, update `server.py` directly to serve clean `targets` objects so Quickshell natively controls Material You theming and Material Symbols.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 43 (CPU & GPU Component):**
  - Dedicated `CpuGpuPill.qml` status bar pill with `planner_review` and `speed` icons, 250ms M3 width animation.
  - Interactive `CpuGpuPopup.qml` inspector overlay displaying P/E-core loads, package/core temperatures, and iGPU details.
  - Two-tier alert coloring (Amber at 70%, Red at 90%).
- **Phase 44 (Memory & Storage Component):**
  - Dedicated `MemoryStoragePill.qml` status bar pill displaying RAM (GB / %) and root or active disk capacity.
  - Interactive `MemoryStoragePopup.qml` with memory breakdown (Used, Available, Cached, Buffers, Free, Swap) and multi-mount storage bars.
- **Phase 45 (Network & Multi-Target Ping Component):**
  - Dedicated `NetworkPingPill.qml` status bar pill displaying live Rx/Tx rates and all 3 ping targets with status colors.
  - Interactive `NetworkPingPopup.qml` inspector with NIC diagnostic cards and 1-click web dashboard button (`http://127.0.0.1:8765/`).
- **Phase 46 (Left-Zone Integration & Automated Assertion Harness):**
  - Placing all 3 pills into `BarContent.qml` Left zone with responsive `useShortenedForm` defense.
  - Automated test harness `scripts/phase46-telemetry-assert.sh` verifying all services with zero working tree drift.

</deferred>

---

*Phase: 42-telemetry-services-sensor-infrastructure*
*Context gathered: 2026-09-25*
