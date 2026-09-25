# Project Research Summary

**Project:** Quickshell Desktop Shell  
**Domain:** Top Status Bar Telemetry & Hardware Inspector (Quickshell ii / Arch Linux)  
**Researched:** 2026-09-25  
**Confidence:** HIGH  

## Executive Summary

Milestone v0.9 addresses the evolution of the desktop shell's system monitoring infrastructure by transforming the single, monolithic `Resources.qml` status bar widget into three specialized, high-fidelity telemetry components in the Left zone of `BarContent.qml`: **CPU & GPU Telemetry**, **Memory & Storage Telemetry**, and **Network & Multi-Target Ping Telemetry**.

Each component features an always-visible status bar pill with dynamic Material 3 width resizing and a rich, interactive `StyledPopup` inspector providing deep hardware and network diagnostics. Telemetry is collected via high-performance, non-blocking Linux kernel virtual filesystems (`procfs` and `sysfs` hwmon/drm), lightweight asynchronous subprocesses for storage mounts, and seamless integration with the user's pre-existing SQLite-backed ping monitor daemon running on port 8765.

All modifications strictly adhere to the project's leaf-symlink overlay topology under `restow/quickshell/`, ensuring zero git churn on upstream `vendor/dots-hyprland`, dynamic Material You color token adaptation, and automated assertion test coverage.

## Key Findings

### Recommended Stack

- **Quickshell QML (Qt 6.11):** UI layer utilizing `BarGroup`, `RowLayout`, and `StyledPopup` with 250ms emphasized deceleration animations.
- **Kernel Direct Polling (`procfs` / `sysfs`):**
  - CPU load via `/proc/stat` and frequencies via `/proc/cpuinfo`.
  - CPU temperature via `/sys/class/hwmon/hwmon5/temp1_input` (`coretemp`).
  - Intel iGPU clock MHz via `/sys/class/drm/card1/gt_act_freq_mhz` and load via `rc6_residency_ms` delta.
  - Memory breakdown via `/proc/meminfo` (Used, Avail, Cached, Buffers, Free, Swap).
  - Network throughput via `/proc/net/dev`.
- **Asynchronous Mount Inspection:** Periodic `df` execution via `Quickshell.Io.Process` every 15–30s to discover root, physical, and cloud FUSE filesystems without blocking the UI thread.
- **System Monitor Ping Integration:** Consumes `http://127.0.0.1:8765/api/status` for 3-target latency (WAN `8.8.8.8`, Gateway `192.168.0.1`, Home Server `192.168.0.104`) with click-to-open web dashboard.

### Expected Features

**Table stakes (Must Have):**
- Three distinct `BarGroup` pills in `BarContent.qml` Left zone: `[CPU & GPU]`, `[Memory & Storage]`, `[Network & Ping]`.
- CPU & GPU pill with live load %; popup with temperature, wattage (with fallback), clock speeds, and GPU telemetry.
- Memory & Storage pill with live RAM GB/% and Root `/` usage; popup with detailed memory tiers and multi-mount storage bars (root, physical, and FUSE cloud mounts).
- Network & Ping pill with active transfer throughput and **all 3 ping targets visible on the bar** (WAN, Gateway, Home Server); popup with NIC details and click-through to web dashboard.

**Differentiators (Should Have):**
- Zero-churn leaf symlink overlay in `restow/quickshell/`.
- Dynamic two-tier warning (Amber) and critical (Red) alert tokens.
- Responsive width adaptation under `useShortenedForm`.
- Dynamic popup coordinate anchoring with screen boundary clamping.

### Architecture Approach

Create decoupled telemetry services in `restow/quickshell/.config/quickshell/ii/services/`:
1. `ResourceUsage.qml` (extended for deep memory stats).
2. `HardwareTelemetry.qml` (CPU temp/power/clocks, Intel GPU telemetry).
3. `StorageUsage.qml` (asynchronous mount point enumeration).
4. `PingService.qml` (daemon HTTP bridge and 3-target latency model).

Create 3 modular pills and popups in `modules/ii/bar/`:
- `CpuGpuPill.qml` & `CpuGpuPopup.qml`
- `MemoryStoragePill.qml` & `MemoryStoragePopup.qml`
- `NetworkPingPill.qml` & `NetworkPingPopup.qml`

Mount them in `BarContent.qml` Left zone alongside `LeftSidebarButton` and `UtilButtons`.

### Critical Pitfalls

1. **Platypus RAPL Permissions:** RAPL `energy_uj` is mode 0400 root-only; handle unprivileged access gracefully with fallback placeholder.
2. **Synchronous UI Freezes:** Never use blocking CLI calls in QML; use `FileView` for procfs/sysfs and async `Process` for `df`/`curl`.
3. **Popup Boundary Clipping:** Use `mapToItem(null, ...)` with horizontal clamping to avoid multi-monitor clipping.
4. **Left Zone Layout Overlap:** Maintain responsive `useShortenedForm` tiers to preserve the minimum 180px gap to Center Workspaces on 1080p.
5. **GNU Stow Directory Folding:** Maintain `--no-folding` and assert zero git churn with `arch/dots-hyprland.sh verify --strict`.

## Implications for Roadmap

Recommended phase structure:
1. **Phase 42: Telemetry Services & Sensor Infrastructure:** Implement backend services (`HardwareTelemetry.qml`, `StorageUsage.qml`, `PingService.qml`, and `ResourceUsage.qml` extensions) for CPU, GPU, memory, storage, and 3-target ping data collection.
2. **Phase 43: CPU & GPU Component (Pill & Popup):** Build `CpuGpuPill.qml` and `CpuGpuPopup.qml` with thermals, frequencies, load metrics, and M3 animations.
3. **Phase 44: Memory & Storage Component (Pill & Popup):** Build `MemoryStoragePill.qml` and `MemoryStoragePopup.qml` with RAM breakdown and multi-mount disk usage bars.
4. **Phase 45: Network & Multi-Target Ping Component (Pill & Popup):** Build `NetworkPingPill.qml` and `NetworkPingPopup.qml` with all 3 pings visible on the bar, NIC telemetry, and web dashboard integration.
5. **Phase 46: Top Bar Left-Zone Integration, Verification & Polish:** Mount all 3 pills into `BarContent.qml` Left zone, verify responsive layouts, build automated assertion test suite, and verify repository cleanliness.

## Sources

- Quickshell Architecture & Upstream dots-hyprland (`vendor/dots-hyprland`)
- Linux Kernel sysfs/procfs documentation (`coretemp`, `intel_rapl`, `i915/drm`)
- Waybar ping monitor configuration & SQLite database (`stow/system_monitor/`)
