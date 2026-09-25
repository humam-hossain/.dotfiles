# Feature Research

**Domain:** Top Status Bar Modular Resource Telemetry & Hardware Inspector (Quickshell ii)  
**Researched:** 2026-09-25  
**Confidence:** HIGH  

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 3 Standalone BarGroup Pills | User requested decoupling monolithic Resources into dedicated Left-zone components | MEDIUM | `[CPU & GPU]`, `[Memory & Storage]`, `[Network & Ping]` placed in `BarContent.qml` Left zone. |
| CPU & GPU Pill Metrics | Immediate visual feedback on compute load | LOW | Display CPU usage % and GPU usage % with Material Symbols icons (`planner_review`, `speed` / `developer_board`). |
| CPU Hardware Telemetry Popup | In-depth troubleshooting and thermals | MEDIUM | Shows CPU overall load %, Package temperature (°C via `coretemp`), power draw (Wattage via RAPL), and clock speeds (MHz). |
| GPU Hardware Telemetry Popup | In-depth graphics telemetry | MEDIUM | Shows Intel UHD 770 load %, average load, live clock frequency (MHz via `rps_act_freq_mhz`), and thermal state. |
| RAM & Root Storage Pill Metrics | Immediate awareness of memory and primary OS disk capacity | LOW | Display RAM used/total in GB (`X.X/Y.Y GB [ZZ%]`) and root `/` disk usage % / GB. |
| Detailed Memory Breakdown Popup | Transparency between active vs cached RAM | LOW | Breaks down RAM into Used, Available, Cached, Buffers, Free, and Swap with clean byte formatting. |
| Multi-Mount Storage Inspector Popup | Comprehensive visibility into all physical & virtual drives | MEDIUM | Clean progress bars showing Used vs Free space for `/`, `/boot`, `/mnt/windows`, `/mnt/hdd`, and FUSE cloud mounts (`GoogleDrive`). |
| Multi-Target Ping on Status Bar Pill | User requirement: all 3 system monitor pings visible on the bar | MEDIUM | Displays WAN (`8.8.8.8`), Gateway (`192.168.0.1`), and Home Server (`192.168.0.104`) with latency (ms) and quality colors. |
| Network Throughput & Interface Info | Real-time traffic awareness | LOW | Live Rx/Tx rates (KB/s or MB/s) derived from `/proc/net/dev`. |
| Network Inspector & Web Dashboard Click | Seamless integration with existing infrastructure | LOW | Popup displays NIC details (IP, interface, link) and 1-click opens `http://127.0.0.1:8765/` in the default browser. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Zero-Overhead Ping Daemon Re-use | Leverages pre-existing SQLite/Docker ping service without duplicate network ICMP traffic | LOW | Pulls from `http://127.0.0.1:8765/api/status` at a configurable interval (5s) without shell fork overhead. |
| Asynchronous Storage Mount Discovery | Does not freeze shell when querying network or cloud FUSE mounts | MEDIUM | Runs `df` asynchronously via `Quickshell.Io.Process` every 15–30s with cached state. |
| Dynamic Material You Two-Tier Alerts | Harmonious theme consistency across system state changes | LOW | Synchronized Amber (warning) and Red (critical) thresholds matching dots-hyprland palette tokens. |
| Material 3 Smooth Width Resizing | Prevents visual jarring as telemetry strings fluctuate | LOW | 250ms emphasized deceleration Behavior on `implicitWidth`. |

### Anti-Features (Avoid)

| Feature | Why Requested | Why Problematic | Better Approach |
|---------|---------------|-----------------|-----------------|
| Raw ICMP Ping from QML | Users might think QML needs to run ping commands | Spawning sub-processes every second introduces process churn and duplicate ICMP packets | Poll existing local Python daemon (`127.0.0.1:8765/api/status`) which already collects and logs to SQLite. |
| High-Frequency Disk Polling (1s) | Real-time disk tracking | Disk capacity changes slowly; polling every 1s prevents drives and FUSE mounts from sleeping | Poll storage every 15–30 seconds. |
| Blocking `statvfs` on FUSE mounts | Direct C-level filesystem queries | If a Google Drive FUSE mount lags or times out, the main UI thread freezes | Query via async `Process` with a strict timeout. |
| Hardcoded Screen Coordinate Popups | Simple absolute positioning | Misaligned on multi-monitor or secondary displays | Dynamic coordinate anchoring relative to each pill with screen boundary clamping (proven in Phase 39). |

## Feature Dependencies

```
[System Monitor Ping Daemon] (port 8765)
    └──consumed by──> [Network & Ping Service]
                          └──powers──> [Network & Ping Pill & Popup]

[Linux sysfs / procfs / hwmon]
    └──read by──> [Hardware Telemetry Service]
                      └──powers──> [CPU & GPU Pill & Popup]
                      └──powers──> [Memory & Storage Pill & Popup]

[BarContent.qml Left Zone]
    ├──mounts──> [CPU & GPU Pill]
    ├──mounts──> [Memory & Storage Pill]
    └──mounts──> [Network & Ping Pill]
```
