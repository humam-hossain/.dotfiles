# Architecture Research

**Domain:** Modular Top Status Bar Resource Telemetry & Hardware Inspector (Quickshell ii)  
**Researched:** 2026-09-25  
**Confidence:** HIGH  

## Architecture Overview

Milestone v0.9 replaces the single monolithic `Resources.qml` component with a decoupled three-pill architecture in the Left zone of `BarContent.qml`. Each component functions as an autonomous, self-contained `BarGroup` pill with a dedicated `StyledPopup` inspector.

```
+--------------------------------------------------------------------------------------------------+
| Top Status Bar (BarContent.qml Left Zone)                                                        |
|                                                                                                  |
| [SidebarBtn]  [CPU & GPU Pill]       [Memory & Disk Pill]     [Network & Ping Pill]     [Utils]  |
|                      |                        |                         |                        |
+----------------------|------------------------|-------------------------|------------------------+
                       v                        v                         v
              +------------------+     +------------------+      +------------------+
              |   CpuGpuPopup    |     | MemoryDiskPopup  |      | NetworkPingPopup |
              | - CPU Load/Temp  |     | - RAM: Used/Free |      | - IP & NIC stats |
              | - CPU Watts/Freq |     |   Cached/Buffers |      | - WAN: 27ms      |
              | - GPU Load/Freq  |     | - Mounts: /,     |      | - GW: 2ms        |
              |   and Temp       |     |   /mnt/windows,  |      | - Srv: 1.6ms     |
              |                  |     |   /mnt/hdd, FUSE |      | - Open Web UI    |
              +------------------+     +------------------+      +------------------+
```

## Component Breakdown

### 1. Telemetry Services Layer (`services/`)

Decouples data acquisition from UI rendering so that multiple consumers (top bar, vertical bar, popups, sidebar) access shared reactive properties without redundant polling.

- **`ResourceUsage.qml` (Extended):**
  - Manages RAM, Swap, and CPU load via `/proc/meminfo` and `/proc/stat`.
  - Extends memory metrics to expose `memoryAvailable`, `memoryBuffers`, `memoryCached`.
- **`HardwareTelemetry.qml` (New Singleton):**
  - CPU package & core temperatures via `/sys/class/hwmon/hwmon5/temp1_input`.
  - CPU frequency (MHz) via `/proc/cpuinfo` or `/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`.
  - CPU power (Watts) via `/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj` (with fallback).
  - Intel iGPU clock frequency via `/sys/class/drm/card1/gt_act_freq_mhz`.
  - Intel iGPU load via `/sys/class/drm/card1/gt/gt0/rc6_residency_ms` delta calculation.
- **`StorageUsage.qml` (New Singleton):**
  - Periodic asynchronous execution of `df -k -x tmpfs -x devtmpfs -x efivarfs` via `Quickshell.Io.Process`.
  - Parses storage partitions into a reactive model list of objects: `{ mount, totalBytes, usedBytes, availBytes, usePercent, isRoot, isPhysical, isFuse }`.
  - Polling interval: 15–30 seconds.
- **`PingService.qml` (New Singleton):**
  - Fetches status from `http://127.0.0.1:8765/api/status?format=%1|%2|%3` (or raw status) via `curl` / `Process`.
  - Exposes reactive properties: `wanLatency`, `gatewayLatency`, `serverLatency`, `overallClass` (`good`, `medium`, `bad`, `critical`, `dead`).
  - Polling interval: 5 seconds.

### 2. Bar Pill Components (`modules/ii/bar/`)

Each pill extends `BarGroup` or wraps a `MouseArea` to provide the standardized 12–16px rounded rectangle styling, hover states, and smooth 250ms M3 emphasized deceleration resizing.

- **`CpuGpuPill.qml`:**
  - Displays CPU usage badge and GPU usage badge with distinct Material Symbols icons.
  - Hover / click opens `CpuGpuPopup`.
- **`MemoryStoragePill.qml`:**
  - Displays RAM usage (`X.X/Y.Y GB` or `%`) and Root filesystem `/` usage (`ZZ%`).
  - Hover / click opens `MemoryStoragePopup`.
- **`NetworkPingPill.qml`:**
  - Displays network throughput rates (Rx/Tx) and **all 3 ping latency values** (`WAN`, `GW`, `SRV`) with colored quality indicators.
  - Hover opens `NetworkPingPopup`.
  - Left-click triggers `Qt.openUrlExternally("http://127.0.0.1:8765/")` to launch the full ping visualization dashboard.

### 3. Popups Layer (`modules/ii/bar/popups/` or inlined)

Extends `StyledPopup` with consistent coordinate mapping relative to each pill's parent screen:
- **`CpuGpuPopup.qml`:** Columnar layout displaying CPU section (load gauge, temperature, power draw in Watts, frequencies) and GPU section (load, frequency MHz, temperature).
- **`MemoryStoragePopup.qml`:** Section 1: Detailed RAM breakdown table (Used, Avail, Cached, Buffers, Free, Swap); Section 2: Clean horizontal progress bars for each mounted partition showing Mount point, Size, Used, Free, and % bar.
- **`NetworkPingPopup.qml`:** Section 1: Interface details (Active device name, IPv4 address, Rx/Tx totals); Section 2: Detailed 3-target ping diagnostic cards with latency thresholds; Section 3: "Open Web Dashboard" action button.

## Layout & Directory Architecture

All files live under `restow/quickshell/` to preserve `vendor/dots-hyprland` without modification:

```
restow/quickshell/.config/quickshell/ii/
├── services/
│   ├── ResourceUsage.qml          # Memory & CPU core metrics
│   ├── HardwareTelemetry.qml      # CPU/GPU temperatures, power, clocks
│   ├── StorageUsage.qml           # Multi-mount disk capacity
│   └── PingService.qml            # Local ping daemon bridge
└── modules/ii/bar/
    ├── BarContent.qml             # Left zone layout mounting the 3 pills
    ├── CpuGpuPill.qml             # CPU & GPU bar pill
    ├── CpuGpuPopup.qml            # CPU & GPU popup inspector
    ├── MemoryStoragePill.qml      # RAM & Root storage pill
    ├── MemoryStoragePopup.qml     # RAM & multi-mount storage popup
    ├── NetworkPingPill.qml        # Network throughput & 3-target ping pill
    └── NetworkPingPopup.qml       # Network details & ping inspector
```
