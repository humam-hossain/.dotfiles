# Phase 42: Telemetry Services & Sensor Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 42-telemetry-services-sensor-infrastructure
**Areas discussed:** Hardware Polling Cadence & RC6 Delta, CPU Topology & Thermals, RAPL Power & Unprivileged Strategy, Storage Mount Filtering & Polling, Ping Daemon Bridge & Server API

---

## Hardware Polling Cadence & CPU/GPU Telemetry

| Option | Description | Selected |
|--------|-------------|----------|
| 1000ms (1s) | Constant 1s polling interval | |
| 2000ms (2s) | Constant 2s polling interval | |
| Adaptive (1000ms active / 3000ms idle) | Fast when active or popup visible; throttles at idle | ✓ |

**User's choice:** Adaptive polling.
**Notes:** User requested a deep exploration of the CPU topology and available telemetry. Host revealed an Intel Core i5-13500 (6 P-cores @ up to 4.8 GHz, 8 E-cores @ up to 3.5 GHz). User confirmed segregating P-core vs E-core loads and clocks, and including Energy Performance Preference (`energy_performance_preference`) and scaling governor (`scaling_governor`). For the Intel UHD 770 iGPU, active render clock, RC6 sleep residency delta, and thermal throttling flag are included.

---

## System Thermals & Status Bar Temperature

| Option | Description | Selected |
|--------|-------------|----------|
| CPU & GPU thermals only | Minimal thermal footprint | |
| Include Motherboard & NVMe temps | Expose VRM, Chipset, and NVMe temperatures | ✓ |

**User's choice:** Include all system thermals.
**Notes:** User wanted comprehensive thermal data for popup inspector cards (NVMe 1 Samsung 980, NVMe 2 PM9A1, Motherboard VRM and Chipset on Gigabyte B660M AORUS ELITE). Crucially, for the status bar pill, the user specified that the bar must not be bloated with multiple temperatures: expose a single primary temperature (`packageTemp`) and a `peakSystemTemperature` property.

---

## RAPL CPU Power Measurement & Root Permissions

| Option | Description | Selected |
|--------|-------------|----------|
| Add udev rule for 0444 read | Grants unprivileged read to energy_uj | |
| Fallback with placeholder | Keeps 0400 root-only; outputs "-- W" | |
| Omit Wattage completely | Exclude power draw from telemetry entirely | ✓ |

**User's choice:** Omit CPU wattage completely ("i don't need cpu wattage").
**Notes:** Explored security rationale of RAPL (PLATYPUS attack CVE-2020-8694). Investigated how `btop` reads wattage without sudo: discovered `/usr/bin/btop cap_dac_read_search,cap_perfmon=ep`. Confirmed Quickshell will remain 100% unprivileged in user-space with zero root/udev requirements.

---

## Storage Mount Discovery & Polling Cadence

| Option | Description | Selected |
|--------|-------------|----------|
| 30s Background Poll | Spawns df twice a minute | |
| 5m Conservative Poll | Slow background timer | |
| Pure I/O-Driven & On-Demand | 0 df polling when I/O is 0%; polls on active I/O or on popup open | ✓ |

**User's choice:** Pure I/O-Driven & On-Demand.
**Notes:** User identified that if disk I/O is zero, disk capacity physically cannot change; slow-polling `df` wastes wakeups and triggers unwanted network checks on Google Drive FUSE cloud mounts. User requested:
1. Live disk I/O % from `/proc/diskstats` exposed in telemetry for the status bar.
2. Dynamic focus on whichever disk is currently experiencing active I/O, falling back to Root when idle.

---

## Ping Daemon Bridge & API Payload

| Option | Description | Selected |
|--------|-------------|----------|
| Poll /api/today | Structured JSON with full 24h history | |
| Poll /api/status with QML HTML stripping | 120-byte legacy Waybar string, strip in QML | |
| Update server.py to serve clean JSON natively | Modify stow/system_monitor server.py directly | ✓ |

**User's choice:** Update `server.py` natively.
**Notes:** Probed live endpoint payload sizes: `/api/today` was 733 KB (excessive overhead for 5s polling), whereas `/api/status` was 120 bytes. User instructed: instead of parsing/stripping Waybar HTML tags inside `PingService.qml`, modify `stow/system_monitor/.config/system_monitor/ping/server.py` so `/api/status` natively returns clean structured JSON with `targets` objects.

---

## the agent's Discretion

- Exact mathematical smoothing factor for converting `/proc/diskstats` ticks into instantaneous `diskIoPercentage`.
- Exact JSON key structure in `server.py` to maintain backward compatibility while providing clean target objects.

## Deferred Ideas

- **Phase 43:** Dedicated `CpuGpuPill.qml` and `CpuGpuPopup.qml` with M3 width resizing and Amber/Red alerts.
- **Phase 44:** Dedicated `MemoryStoragePill.qml` and `MemoryStoragePopup.qml` with memory breakdown and multi-mount storage bars.
- **Phase 45:** Dedicated `NetworkPingPill.qml` and `NetworkPingPopup.qml` with 3-target latency numbers and 1-click web dashboard launcher.
- **Phase 46:** Three-pill integration in `BarContent.qml` Left zone and automated test harness `scripts/phase46-telemetry-assert.sh`.
