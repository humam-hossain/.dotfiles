# Stack Research

**Domain:** Linux Desktop Shell Telemetry & Hardware Monitoring (Quickshell ii / Arch Linux)  
**Researched:** 2026-09-25  
**Confidence:** HIGH  

## Recommended Stack

### Core Technologies

| Technology | Version / Path | Purpose | Why Recommended |
|------------|----------------|---------|-----------------|
| Quickshell QML | 0.0.1+ / Qt 6.11 | UI presentation, animation, and reactive property binding | Native high-performance Wayland layer-shell runtime integrated into dots-hyprland. |
| Linux `procfs` | `/proc` | CPU metrics, memory details, network throughput | Kernel-direct virtual filesystem offering microsecond reads with zero process fork overhead. |
| Linux `sysfs` hwmon | `/sys/class/hwmon/hwmon5` (`coretemp`) | CPU package and per-core temperatures | Kernel driver reporting unprivileged millidegree Celsius telemetry (`temp1_input`). |
| Linux `sysfs` drm | `/sys/class/drm/card1/` | Intel iGPU frequency and RC6 residency | Native Intel Alder Lake-S GT1 telemetry (`rps_act_freq_mhz`, `rc6_residency_ms`) readable unprivileged. |
| Local Ping Monitor Daemon | `http://127.0.0.1:8765/` | Multi-target ping aggregation and history | Pre-existing SQLite-backed Python service providing sub-second status via `GET /api/status`. |

### Supporting Libraries & APIs

| Library / Tool | Path / API | Purpose | When to Use |
|----------------|------------|---------|-------------|
| `Quickshell.Io` `FileView` | QML Type | Non-blocking reactive file polling | For all continuous `procfs` and `sysfs` sensor polling (CPU load, temp, RAM, net dev). |
| `Quickshell.Io` `Process` | QML Type | Asynchronous sub-process execution | For periodic storage mount discovery (`df -k`) and HTTP ping status polling (`curl`). |
| Material 3 Motion Tokens | `Appearance.animation.elementMoveFast` | Width and opacity transitions | For pill resizing (250ms emphasized deceleration) matching the rest of the status bar. |
| Material You Color Scheme | `Appearance.colors.*` | Dynamic thematic coloring | Automatically adapts pill backgrounds, alert badges, and progress bars to active wallpaper. |

### Hardware Telemetry Sources (Machine Specific)

On this host (Intel Core i5-13500 + Intel UHD Graphics 770):
1. **CPU Temperature:** `/sys/class/hwmon/hwmon5/temp1_input` (Package temperature in m°C, unprivileged 0444).
2. **CPU Frequency:** `/proc/cpuinfo` (`cpu MHz` per logical core) or `/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq`.
3. **CPU Power Draw (Wattage):** `/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj` (root-restricted 0400). Requires graceful fallback to `-- W` or an optional udev helper rule.
4. **GPU Active Frequency:** `/sys/class/drm/card1/gt_act_freq_mhz` (readable unprivileged, e.g. 1550 MHz).
5. **GPU Load:** Computed from `/sys/class/drm/card1/gt/gt0/rc6_residency_ms` delta vs wall clock time (`1 - delta_rc6 / delta_time`).
6. **RAM Breakdown:** `/proc/meminfo` (`MemTotal`, `MemAvailable`, `MemFree`, `Buffers`, `Cached`, `SwapTotal`, `SwapFree`).
7. **Storage Disks:** `df -k -x tmpfs -x devtmpfs -x efivarfs --output=target,size,used,avail,pcent`.
8. **Network Throughput:** `/proc/net/dev` (`bytes received` / `bytes transmitted` on active default route interface).
9. **Ping Monitor:** `http://127.0.0.1:8765/api/status` (WAN `8.8.8.8`, Gateway `192.168.0.1`, Server `192.168.0.104`).

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `FileView` on `/proc/net/dev` | `ip` or `vnstat` CLI subprocesses | Only if long-term historical billing quotas are needed; `FileView` is zero-overhead for live rates. |
| RC6 residency delta for iGPU | `intel_gpu_top` via `perf` | `intel_gpu_top` requires `CAP_PERFMON` / root; RC6 residency is readable by standard users without privileges. |
| HTTP GET `/api/status` | Direct SQLite queries from QML | SQLite requires C++/QML plugin or python subshell; HTTP daemon is already running and lightweight. |

## What NOT to Use

- **`ddcutil` or I2C polling:** Proven to cause iGPU hangs and kernel display crashes (see `issues/2026-07-16_igpu-flickering-hang-no-display.md`).
- **Synchronous blocking commands in QML:** Running synchronous shell commands blocks the Qt event loop, freezing animations and cursor interactions.
- **Hardcoded interface names (e.g. assuming `eth0`):** Machine uses `wlp0s20f0u7`; interface must be dynamically resolved from `/proc/net/route` or config.
- **Hardcoded hex colors:** Violates dots-hyprland Material You theming contract.
