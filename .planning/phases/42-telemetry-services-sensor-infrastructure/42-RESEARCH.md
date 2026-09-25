# Phase 42: Telemetry Services & Sensor Infrastructure - Research

**Researched:** 2026-09-25  
**Domain:** Backend telemetry singletons, Linux kernel virtual filesystems (`/proc`, `/sys`), Intel iGPU DRM telemetry, storage mount tracking, and local loopback ping daemon bridging.  
**Confidence Level:** HIGH [VERIFIED: live sysfs/procfs probes, Docker inspection, codebase analysis, and Quickshell 0.2.1 runtime].

---

## User Constraints (verbatim from CONTEXT.md)

### Phase Boundary
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

### Implementation Decisions
- **D-01 (Adaptive Polling Cadence):** Poll sysfs nodes at 1000ms when system is active or UI popups are visible, relaxing dynamically to 3000ms when system load is idle. — **Reversibility:** reversible.
- **D-02 (P-Core & E-Core Segregation):** On the host's 13th Gen Intel Core i5-13500 (14 cores, 20 threads), parse `/proc/stat` to expose `pCoreLoad` (average load of CPUs 0–11, up to 4.8 GHz) and `eCoreLoad` (average load of CPUs 12–19, up to 3.5 GHz) alongside `overallCpuLoad`. Expose separate `pCoreFrequencyMhz` and `eCoreFrequencyMhz`, plus a 20-element array for per-thread popup bars. — **Reversibility:** reversible.
- **D-03 (EPP & Frequency Governor):** Expose `energyPerformancePreference` (e.g. `balance_performance`) and `scalingGovernor` (e.g. `powersave`) via `FileView` from `/sys/devices/system/cpu/cpu0/cpufreq/`. — **Reversibility:** reversible.
- **D-04 (Intel iGPU UHD 770 Telemetry):** Expose active render clock (`gt_act_freq_mhz`), compute active `gpuLoad` % from `/sys/class/drm/card1/gt/gt0/rc6_residency_ms` sleep delta over sampling intervals, and expose `gpuThrottled` boolean from `throttle_reason_thermal`. — **Reversibility:** reversible.
- **D-05 (Zero Root / Wattage Omission):** CPU and GPU power wattage measurements are completely omitted from shell telemetry to ensure 100% unprivileged execution in user-space with zero system changes (no udev rules or root capabilities required). — **Reversibility:** reversible.
- **D-06 (Single Bar Pill Temperature vs Full System Thermals):** Expose `packageTemp` (CPU Package id 0 from `hwmon5/temp1_input`) as the primary default temperature for status bar pills; also expose `peakSystemTemperature` (`Math.max(cpu, nvme1, nvme2, vrm)`) and `peakDeviceLabel` for single-metric high-temp alerts without bloating the pill. — **Reversibility:** reversible.
- **D-07 (Extended Motherboard & Drive Thermals):** Expose NVMe 1 (`hwmon1` Samsung 980), NVMe 2 (`hwmon2` Samsung PM9A1), and Motherboard VRM & Chipset (`hwmon3` Gigabyte WMI) temperatures in `HardwareTelemetry.qml` for rich popup inspection cards. — **Reversibility:** reversible.
- **D-08 (Pure I/O-Driven & On-Demand Polling):** Zero polling of `df` when disk I/O is 0% (idle). Spawns asynchronous `df` process only when active disk writes/reads occur, plus immediate refresh on-demand when the user opens the storage popup inspector. — **Reversibility:** reversible.
- **D-09 (Top Bar Disk I/O Percentage):** Read `/proc/diskstats` via `FileView` to compute real-time `diskIoPercentage` (0–100%) and throughput (Read/Write MB/s), providing an active disk indicator for the top status bar. — **Reversibility:** reversible.
- **D-10 (Active Disk Dynamic Focus):** Expose `activeDisk` so the status bar pill can dynamically highlight whichever disk is actively writing/reading, falling back to Root `/` when idle. — **Reversibility:** reversible.
- **D-11 (Mount Classification & Filtering):** Classify mounts into physical drives (Root `/`, `/mnt/windows`, `/mnt/hdd`, `/boot`) and cloud FUSE mounts (`/home/pera/GoogleDrive/gdrive-*`), filtering out virtual pseudo-filesystems (`tmpfs`, `devtmpfs`, `efivarfs`, `none`). — **Reversibility:** reversible.
- **D-12 (Server.py /api/status Payload Clean-up):** Update `stow/system_monitor/.config/system_monitor/ping/server.py` so `/api/status` returns clean structured JSON with `targets` (and named properties `host`, `ms`, `quality`, `text_value`, `class`), eliminating Waybar HTML spans/nerd fonts. Rebuild/restart local docker container so `PingService.qml` consumes clean JSON directly without client-side HTML regex stripping. — **Reversibility:** reversible.
- **D-13 (5s Polling with 15s Offline Backoff):** `PingService.qml` polls `http://127.0.0.1:8765/api/status` at 5s intervals. If the daemon is unreachable or offline, set latency to `"-- ms"`, mark state as `offline`, and back off polling interval to 15s to keep console error logs silent. — **Reversibility:** reversible.
- **D-14 (Three Target Exposure):** Expose distinct reactive properties for WAN (`8.8.8.8`), Gateway (`192.168.0.1`), and Home Server (`192.168.0.104`) with latency numbers and status classes (`good`, `medium`, `bad`, `dead`). — **Reversibility:** reversible.
- **D-15 (Extended Memory Fields):** Extend existing `ResourceUsage.qml` singleton to parse and expose `memoryAvailable`, `memoryBuffers`, and `memoryCached` from `/proc/meminfo` alongside `memoryUsed` and `memoryTotal`. — **Reversibility:** reversible.

---

## Architectural Responsibility Map

| Component | Repository Path | Target Symlink (`~/.config/...`) | Primary Responsibility |
|-----------|-----------------|-----------------------------------|------------------------|
| **`HardwareTelemetry.qml`** | `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` | `~/.config/quickshell/ii/services/HardwareTelemetry.qml` | Non-blocking CPU P/E-core metrics, Intel UHD 770 iGPU load (RC6 delta) and clock MHz, GPU throttling flag, and comprehensive system thermals (`packageTemp`, `peakSystemTemperature`, `peakDeviceLabel`). |
| **`StorageUsage.qml`** | `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` | `~/.config/quickshell/ii/services/StorageUsage.qml` | Pure I/O-driven `/proc/diskstats` tracking (`diskIoPercentage`, throughput MB/s, `activeDisk`), and on-demand/I/O-triggered `df -k -P` parsing for physical mounts (`/`, `/boot`, `/mnt/windows`, `/mnt/hdd`) and cloud FUSE mounts (`GoogleDrive`). |
| **`PingService.qml`** | `restow/quickshell/.config/quickshell/ii/services/PingService.qml` | `~/.config/quickshell/ii/services/PingService.qml` | Asynchronous 5s polling (`XMLHttpRequest`) of local daemon `http://127.0.0.1:8765/api/status` with 15s offline backoff, exposing reactive properties for WAN, Gateway, and Home Server. |
| **`server.py`** | `stow/system_monitor/.config/system_monitor/ping/server.py` | `~/.config/system_monitor/ping/server.py` | Ping viz server daemon: updates `/api/status` endpoint to emit clean structured JSON with `targets` array while preserving backward-compatible text/class fields. |
| **`ResourceUsage.qml`** | `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` | `~/.config/quickshell/ii/services/ResourceUsage.qml` | Overlays upstream `ResourceUsage.qml` to parse and expose `memoryAvailable`, `memoryBuffers`, and `memoryCached` from `/proc/meminfo` alongside existing memory properties. |

---

## Standard Stack

| Technology / Tool | Version / Spec | Purpose in Phase 42 |
|-------------------|----------------|---------------------|
| **Quickshell** | `0.2.1` (AUR `quickshell-git`) | C++/Qt 6 desktop shell framework executing the singletons. |
| **`Quickshell.Io.FileView`** | Native Quickshell C++ element | Asynchronous, non-blocking file reads on Linux virtual filesystems (`/proc/stat`, `/proc/meminfo`, `/proc/diskstats`, `/proc/cpuinfo`, `/sys/class/...`). |
| **`Quickshell.Io.Process`** | Native Quickshell C++ element | Asynchronous non-blocking process execution for `df -k -P` and startup hwmon probing with `StdioCollector`. |
| **`QtQuick.Timer`** | Qt 6.x | Adaptive polling timers (1000ms active / 3000ms idle, 5000ms ping poll / 15000ms offline backoff). |
| **`XMLHttpRequest`** | Qt Quick JS engine | Asynchronous HTTP client for querying the local ping daemon without stalling UI rendering. |
| **Python / Docker** | Python 3.12 / Docker 28.x | Ping collector daemon running `server.py` in container `system_monitor`. |
| **GNU Stow** | 2.4.x | Package symlinking with `--no-folding -t ~` across `stow/` and `restow/`. |

---

## Architecture Patterns

### 1. Quickshell Singleton Service Pattern
All backend services must be declared as global singletons:
```qml
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
    // Reactive state properties
}
```
*Rationale:* Downstream pills and popup overlays in Phases 43, 44, and 45 can directly access `HardwareTelemetry`, `StorageUsage`, `PingService`, and `ResourceUsage` globally without prop-drilling or instantiating multiple pollers.

### 2. Adaptive Polling Cadence (D-01)
To conserve CPU cycles and battery/power while maintaining high responsiveness:
- Poll cadence operates at **1000ms** during active system state (e.g. CPU load > 15%, active I/O, or when UI popups request fast polling via `fastPollingRequested` ref-count).
- Relaxes dynamically to **3000ms** when system load is idle and no UI inspector is open.

### 3. Pure I/O-Driven Storage Discovery (D-08)
Physical and cloud disk capacity physically cannot change if disk I/O ticks are 0.
- Sample `/proc/diskstats` continuously via `FileView`.
- If $\Delta \text{io\_ticks} == 0$, do **not** spawn `df` (0 wakeups, 0 cloud API / network calls).
- If $\Delta \text{io\_ticks} > 0$ and elapsed time since last `df` run $> 15\text{s}$, trigger background `dfProc.running = true`.
- Expose an explicit on-demand `refresh()` function that triggers `dfProc.running = true` immediately when a user opens the popup inspector in Phase 44.

### 4. Non-Blocking Virtual Filesystem Reads via `FileView`
Virtual kernel files (`/proc/` and `/sys/`) do not have inotify update events for continuous counters.
- To read updated counters, call `fileView.reload()`.
- Use `blockLoading: true` on virtual sysfs/procfs `FileView` nodes so calling `fileView.text()` immediately following `reload()` reads the in-memory kernel buffer synchronously without thread context-switching overhead or async callback nesting [VERIFIED: `Voice.qml`].

### 5. Resilient Hardware Path Discovery & Dynamic Fallback
Although sysfs paths on this host are verified (`hwmon5` = coretemp, `card1` = UHD 770), kernel updates or module reordering can occasionally alter hwmon indices.
- Default to verified paths (`/sys/class/hwmon/hwmon5`, `/sys/class/drm/card1`).
- Execute a fast one-shot startup `Process` (`for h in /sys/class/hwmon/hwmon*; do echo "$(cat $h/name 2>/dev/null):$h"; done`) with `StdioCollector` to dynamically resolve or verify paths at shell initialization.

### 6. Fail-Soft Offline Backoff (D-13)
When polling `http://127.0.0.1:8765/api/status`:
- On HTTP 200: parse JSON, set `isOffline = false`, keep interval at `5000ms`.
- On connection error, timeout, or non-200 status: retain last known status or set to `"-- ms"`, set `isOffline = true`, and back off timer interval to `15000ms` to prevent log spam and CPU churn.

---

## Don't Hand-Roll

| Anti-Pattern | Standard / Preferred Alternative | Why Avoid Hand-Rolling |
|--------------|----------------------------------|------------------------|
| **Spawning raw `ping` commands from QML** | Poll existing local daemon `http://127.0.0.1:8765/api/status` | Process fork overhead, network congestion, and ICMP socket permission requirements. The local daemon already collects ICMP packets into SQLite every 5s with zero shell overhead. |
| **Parsing Waybar HTML spans with regex in QML** | Update `server.py` `/api/status` to serve clean JSON | Fragile client-side regex matching, color token coupling, and inability to handle format changes. Native JSON allows QML to bind cleanly to Material You theme tokens. |
| **Periodic fixed 15s `df` polling** | Pure I/O-driven triggering via `/proc/diskstats` + on-demand `refresh()` | Running `df` periodically wakes up network connections and Google Drive FUSE mounts even when the system is completely idle. |
| **Reading RAPL power files (`energy_uj`)** | Exclude wattage entirely (D-05) | `/sys/class/powercap/intel-rapl` has `0400` permissions (root-only due to PLATYPUS CVE-2020-8694). Reading it requires root or setcap permissions, violating 100% unprivileged execution. |
| **Creating 20 separate `FileView` instances for CPU frequencies** | Parse `/proc/cpuinfo` in a single pass | 20 `FileView` instances create unnecessary QML object overhead; `/proc/cpuinfo` provides all 20 thread frequencies in a single text buffer. |

---

## Common Pitfalls

### Pitfall 1: FileView Async Race Condition
**Issue:** By default, `FileView` loads asynchronously. If `reload()` is called and `text()` is immediately read without `blockLoading: true`, `text()` may return stale content or empty string on the first cycle.  
**Fix:** Set `blockLoading: true` and `printErrors: false` on `FileView` nodes reading `/proc` and `/sys` virtual files [VERIFIED: `Voice.qml`].

### Pitfall 2: Docker Container Not Rebuilt After `server.py` Edits
**Issue:** `server.py` is copied into the Docker container image at build time (`COPY server.py ping_plot.html ./` in `Dockerfile`). Simply editing `stow/system_monitor/.../server.py` on disk does not update the running container.  
**Fix:** After modifying `server.py`, the plan must execute `docker compose up -d --build` (or `docker restart system_monitor`) in `stow/system_monitor/.config/system_monitor/ping/` and verify the `/api/status` endpoint via `curl` [VERIFIED: `docker-compose.yml`].

### Pitfall 3: POSIX Formatting Wrap in `df`
**Issue:** Standard `df -h` wraps filesystem paths longer than 14 characters onto a second line, breaking column-based string splitting.  
**Fix:** Always pass `-P` (POSIX standard format: `df -k -P`). This guarantees each filesystem is output on exactly one line regardless of length [VERIFIED: `df -k -P` tested live].

### Pitfall 4: `/proc/diskstats` Sector Size Assumption
**Issue:** Developers sometimes confuse physical drive sector size (4096 bytes) with kernel diskstats sector size.  
**Fix:** The Linux kernel `/proc/diskstats` documentation explicitly dictates that sectors read and written are always measured in units of **512 bytes**, regardless of the underlying physical storage geometry [VERIFIED: Linux kernel Documentation/admin-guide/iostats.rst].

### Pitfall 5: RC6 Sleep Delta Inversion & Clamping
**Issue:** `rc6_residency_ms` counts milliseconds the GPU is *asleep*. During active 3D rendering or video decoding, the counter increases slower than wall clock time. If system time slips or sampling interval is miscalculated, load calculation can become negative or exceed 100%.  
**Fix:** Calculate `idleRatio = (rc6DeltaMs / elapsedTimeMs)` and `gpuLoad = Math.max(0.0, Math.min(1.0, 1.0 - idleRatio))` [VERIFIED: tested live with python calculation].

### Pitfall 6: FUSE Cloud Mount Hangs During Network Dropouts
**Issue:** If Google Drive connection drops, running `df` without a timeout can block indefinitely in the kernel VFS layer.  
**Fix:** Wrap `df` execution with timeout in `Process`: `timeout 3 df -k -P`. If it times out, preserve previous cached mount data without freezing the shell.

---

## Code Examples

### 1. Intel iGPU Load Calculation from RC6 Residency
```qml
// HardwareTelemetry.qml (snippet)
property real gpuLoad: 0.0
property real gpuClockMhz: 0.0
property bool gpuThrottled: false

property real lastGpuSampleTime: 0
property real lastRc6Ms: 0

FileView { id: fileRc6; path: "/sys/class/drm/card1/gt/gt0/rc6_residency_ms"; blockLoading: true; printErrors: false }
FileView { id: fileGpuFreq; path: "/sys/class/drm/card1/gt_act_freq_mhz"; blockLoading: true; printErrors: false }
FileView { id: fileGpuThrottle; path: "/sys/class/drm/card1/gt/gt0/throttle_reason_thermal"; blockLoading: true; printErrors: false }

function updateGpuMetrics() {
    fileRc6.reload();
    fileGpuFreq.reload();
    fileGpuThrottle.reload();

    const now = Date.now();
    const rc6 = parseFloat(fileRc6.text().trim());
    if (!isNaN(rc6) && lastGpuSampleTime > 0 && lastRc6Ms > 0) {
        const dt = now - lastGpuSampleTime;
        const dRc6 = rc6 - lastRc6Ms;
        if (dt > 100) {
            const idleRatio = Math.max(0.0, Math.min(1.0, dRc6 / dt));
            gpuLoad = Math.max(0.0, Math.min(1.0, 1.0 - idleRatio));
        }
    }
    lastGpuSampleTime = now;
    lastRc6Ms = rc6;

    const freq = parseFloat(fileGpuFreq.text().trim());
    gpuClockMhz = isNaN(freq) ? 0.0 : freq;

    const throttle = parseInt(fileGpuThrottle.text().trim());
    gpuThrottled = (!isNaN(throttle) && throttle !== 0);
}
```

### 2. CPU P-Core and E-Core Segregation from `/proc/stat`
```qml
// HardwareTelemetry.qml (snippet)
property real overallCpuLoad: 0.0
property real pCoreLoad: 0.0
property real eCoreLoad: 0.0
property var threadLoads: [] // 20 elements
property var prevCpuTicks: ({})

FileView { id: fileProcStat; path: "/proc/stat"; blockLoading: true; printErrors: false }

function updateCpuMetrics() {
    fileProcStat.reload();
    const lines = fileProcStat.text().split("\n");
    let newThreadLoads = [];
    let pCoreSum = 0;
    let eCoreSum = 0;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line.startsWith("cpu")) continue;
        const parts = line.split(/\s+/);
        const name = parts[0];
        
        // Sum user, nice, system, idle, iowait, irq, softirq, steal
        const total = parts.slice(1, 9).reduce((a, b) => a + parseFloat(b), 0);
        const idle = parseFloat(parts[4]) + parseFloat(parts[5]); // idle + iowait
        const active = total - idle;

        const prev = prevCpuTicks[name];
        let load = 0.0;
        if (prev) {
            const dTotal = total - prev.total;
            const dActive = active - prev.active;
            load = dTotal > 0 ? Math.max(0.0, Math.min(1.0, dActive / dTotal)) : 0.0;
        }
        prevCpuTicks[name] = { total: total, active: active };

        if (name === "cpu") {
            overallCpuLoad = load;
        } else {
            const cpuIdx = parseInt(name.replace("cpu", ""));
            if (!isNaN(cpuIdx) && cpuIdx < 20) {
                newThreadLoads[cpuIdx] = load;
                if (cpuIdx < 12) {
                    pCoreSum += load; // CPUs 0-11 (P-cores)
                } else {
                    eCoreSum += load; // CPUs 12-19 (E-cores)
                }
            }
        }
    }
    threadLoads = newThreadLoads;
    pCoreLoad = pCoreSum / 12.0;
    eCoreLoad = eCoreSum / 8.0;
}
```

### 3. Server.py Clean JSON Endpoint
```python
# stow/system_monitor/.config/system_monitor/ping/server.py (snippet)
def api_status(params: dict[str, list[str]]) -> dict[str, Any]:
    fmt = params.get("format", [None])[0]
    cycle = get_latest_cycle()
    generated_at = cycle["generated_at"]
    if not generated_at:
        return stale_status()

    age = (datetime.now() - generated_at).total_seconds()
    if age > STALE_AFTER_SECONDS:
        return stale_status()

    rendered = render_status(cycle["targets"], fmt)
    return {
        "text": rendered["text"],
        "class": rendered["class"],
        "generated_at": generated_at.isoformat() if generated_at else None,
        "overall_class": cycle.get("overall_class", rendered["class"]),
        "targets": cycle.get("targets", [])
    }
```

### 4. PingService.qml Asynchronous Polling with Backoff
```qml
// PingService.qml (snippet)
property var targets: []
property var wanTarget: ({ host: "8.8.8.8", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
property var gatewayTarget: ({ host: "192.168.0.1", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
property var serverTarget: ({ host: "192.168.0.104", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
property bool isOffline: true

Timer {
    id: pollTimer
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.fetchStatus()
}

function fetchStatus() {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "http://127.0.0.1:8765/api/status");
    xhr.timeout = 2500;
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    root.targets = data.targets || [];
                    root.isOffline = false;
                    pollTimer.interval = 5000;
                    
                    for (let i = 0; i < root.targets.length; i++) {
                        const t = root.targets[i];
                        if (t.host === "8.8.8.8") root.wanTarget = t;
                        else if (t.host === "192.168.0.1") root.gatewayTarget = t;
                        else if (t.host === "192.168.0.104") root.serverTarget = t;
                    }
                } catch (e) {
                    root.handleOffline();
                }
            } else {
                root.handleOffline();
            }
        }
    };
    xhr.ontimeout = function() { root.handleOffline(); };
    xhr.onerror = function() { root.handleOffline(); };
    xhr.send();
}

function handleOffline() {
    isOffline = true;
    pollTimer.interval = 15000;
    wanTarget = { host: "8.8.8.8", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
    gatewayTarget = { host: "192.168.0.1", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
    serverTarget = { host: "192.168.0.104", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
}
```

### 5. Extended Memory Parsing in `ResourceUsage.qml`
```qml
// ResourceUsage.qml (snippet)
property real memoryTotal: 1
property real memoryFree: 0
property real memoryAvailable: 0
property real memoryBuffers: 0
property real memoryCached: 0
property real memoryUsed: Math.max(0, memoryTotal - memoryAvailable)
property real memoryUsedPercentage: memoryTotal > 0 ? (memoryUsed / memoryTotal) : 0

// Inside Timer onTriggered:
const textMeminfo = fileMeminfo.text();
memoryTotal = Number(textMeminfo.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1);
memoryAvailable = Number(textMeminfo.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0);
memoryFree = Number(textMeminfo.match(/MemFree:\s*(\d+)/)?.[1] ?? 0);
memoryBuffers = Number(textMeminfo.match(/Buffers:\s*(\d+)/)?.[1] ?? 0);
memoryCached = Number(textMeminfo.match(/^Cached:\s*(\d+)/m)?.[1] ?? 0);
```

---

## State of the Art

| Technology | Prior Standard | State of the Art (Phase 42) |
|------------|----------------|-----------------------------|
| **CPU Monitoring** | Monolithic aggregate CPU % across all cores | Segregated P-core (performance) vs E-core (efficiency) load and frequency tracking for Intel Raptor Lake hybrid CPUs. |
| **GPU Telemetry** | Vendor CLI scraping (`intel_gpu_top` requiring sudo or root) | Zero-root unprivileged sysfs reading (`rc6_residency_ms` sleep delta and `gt_act_freq_mhz`). |
| **Storage Monitoring** | Blind periodic `df` process polling every 15s (waking up cloud mounts) | Pure I/O-driven `/proc/diskstats` tracking with 0 `df` polling while disk I/O is idle, plus dynamic active disk detection. |
| **Ping Service** | Scraping Waybar HTML markup and regex parsing | Clean structured JSON endpoint in local daemon exposing typed targets, latencies, and status classes. |
| **Memory Monitoring** | Simple Used / Total RAM | Tiered memory telemetry exposing Available, Buffers, and Cached memory matching `htop` / `free -m`. |

---

## Assumptions Log

| # | Assumption | Status | Impact / Validation | Provenance |
|---|------------|--------|---------------------|------------|
| 1 | Host CPU is Intel Core i5-13500 with 14 cores (6P + 8E) and 20 threads. | VALIDATED | Verified via `lscpu` and `/sys/devices/system/cpu/`. CPUs 0–11 scale up to 4.8 GHz (P-cores); CPUs 12–19 scale up to 3.5 GHz (E-cores). | [VERIFIED: `lscpu`] |
| 2 | Intel UHD 770 iGPU exposes RC6 sleep residency at `/sys/class/drm/card1/gt/gt0/rc6_residency_ms`. | VALIDATED | Verified via sysfs file read; tested delta calculation over 1s interval. | [VERIFIED: sysfs probe] |
| 3 | CPU package temp is available at `hwmon5/temp1_input`. | VALIDATED | Verified `hwmon5/name` is `coretemp` and `temp1_label` is `Package id 0`. | [VERIFIED: sysfs probe] |
| 4 | NVMe drives and Gigabyte motherboard temps are available at `hwmon1`, `hwmon2`, and `hwmon3`. | VALIDATED | Verified `hwmon1` (Samsung 980), `hwmon2` (PM9A1), and `hwmon3` (`gigabyte_wmi`). | [VERIFIED: sysfs probe] |
| 5 | Ping daemon runs on Docker with host network mode on port 8765. | VALIDATED | Verified container `system_monitor` is running and `/api/status` is responsive on `127.0.0.1:8765`. | [VERIFIED: curl/docker] |
| 6 | RAPL CPU wattage is omitted to guarantee unprivileged execution. | VALIDATED | Confirmed by Decision D-05; RAPL node `/sys/class/powercap/intel-rapl` has 0400 root-only permissions. | [VERIFIED: CONTEXT.md D-05] |
| 7 | Storage mounts include physical (`/`, `/boot`, `/mnt/windows`, `/mnt/hdd`) and Google Drive FUSE (`gdrive-*`). | VALIDATED | Verified via `findmnt` and `df -k -P`. | [VERIFIED: `findmnt`] |

---

## Open Questions

None. All technical choices and constraints were resolved during the `/gsd-discuss-phase` session and captured in `42-CONTEXT.md`.

---

## Environment Availability

| Resource / Tool | Path / Identifier | State on Host |
|-----------------|-------------------|---------------|
| Quickshell | `/usr/bin/quickshell`, `/usr/bin/qs` | Available (v0.2.1) |
| Docker Ping Daemon | `container_name: system_monitor`, port 8765 | Running (healthy) |
| Intel iGPU Device | `/sys/class/drm/card1` | Present (`gt_act_freq_mhz`, `rc6_residency_ms`) |
| Intel Coretemp Hwmon | `/sys/class/hwmon/hwmon5` | Present (`name: coretemp`) |
| NVMe Hwmon Devices | `/sys/class/hwmon/hwmon1`, `hwmon2` | Present (`name: nvme`) |
| Gigabyte WMI Hwmon | `/sys/class/hwmon/hwmon3` | Present (`name: gigabyte_wmi`) |
| CPU Scaling Governor | `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` | Present (`powersave`) |
| CPU EPP | `/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference` | Present (`balance_performance`) |
| Physical Storage | `/dev/nvme1n1p2` (`/`), `nvme1n1p1` (`/boot`), `nvme0n1p3` (`/mnt/windows`), `sda1` (`/mnt/hdd`) | Mounted and active |
| Cloud FUSE Storage | `/home/pera/GoogleDrive/gdrive-*` | Mounted via rclone |

---

## Validation Architecture (Nyquist test mapping)

The phase plan will include creating an automated validation test harness:  
`scripts/phase42-telemetry-services-assert.sh`

### Assert Harness Sections & Requirements Mapping

1. **Section 1: QML Service Syntax & Declarative Integrity**
   - Asserts valid QML syntax for all four services (`HardwareTelemetry.qml`, `StorageUsage.qml`, `PingService.qml`, `ResourceUsage.qml`).
   - Asserts `pragma Singleton` and `pragma ComponentBehavior: Bound` are present on all singletons.
   - Verifies zero syntax errors via `quickshell --check` or headless parsing.

2. **Section 2: Hardware Telemetry Data Contracts (`HardwareTelemetry.qml`)**
   - Asserts CPU load properties exist (`overallCpuLoad`, `pCoreLoad`, `eCoreLoad`, `threadLoads`).
   - Asserts P/E-core segregation logic (CPUs 0–11 for P-cores, CPUs 12–19 for E-cores).
   - Asserts GPU properties exist (`gpuLoad`, `gpuClockMhz`, `gpuThrottled`).
   - Asserts thermal properties exist (`packageTemp`, `peakSystemTemperature`, `peakDeviceLabel`, `nvme1Temp`, `nvme2Temp`, `motherboardTemp`).
   - Asserts EPP and scaling governor properties exist.
   - Asserts zero RAPL wattage properties (enforcing D-05 unprivileged requirement).

3. **Section 3: Storage Engine & Dynamic Mount Discovery (`StorageUsage.qml`)**
   - Asserts `/proc/diskstats` parser calculates `diskIoPercentage` (0–100%) and throughput (MB/s).
   - Asserts `activeDisk` logic identifies active storage device and falls back to root when idle.
   - Asserts `df` mount filtering correctly identifies physical mounts (`/`, `/boot`, `/mnt/windows`, `/mnt/hdd`) and cloud mounts (`gdrive-*`) while filtering pseudo-filesystems.
   - Asserts pure I/O-driven trigger: 0 `df` spawns when I/O is 0, and immediate refresh on `refresh()` call.

4. **Section 4: Ping Daemon Clean JSON Bridge (`server.py` & `PingService.qml`)**
   - Asserts `server.py` `/api/status` returns structured JSON with `targets` array (with `host`, `ms`, `quality`, `text_value`, `class`).
   - Asserts live Docker container responds to `curl http://127.0.0.1:8765/api/status` with valid JSON containing targets for `8.8.8.8`, `192.168.0.1`, and `192.168.0.104`.
   - Asserts `PingService.qml` contains 5s polling interval and 15s offline backoff handler.

5. **Section 5: Extended Memory Telemetry (`ResourceUsage.qml`)**
   - Asserts `memoryAvailable`, `memoryBuffers`, and `memoryCached` are parsed from `/proc/meminfo` and exposed alongside `memoryTotal` and `memoryUsed`.
   - Verifies values match live kernel `/proc/meminfo` ranges.

6. **Section 6: Stow Symlink & Repository Integrity**
   - Asserts all files are located in `restow/quickshell/` and `stow/system_monitor/`.
   - Asserts GNU Stow links are established in `~/.config/quickshell/ii/services/` and `~/.config/system_monitor/ping/`.
   - Verifies `./arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0`.

---

## Security Domain (ASVS Categories & Threat Patterns)

| Category / Requirement | Threat Pattern | Mitigation Strategy |
|------------------------|----------------|---------------------|
| **ASVS V1 / Unprivileged Execution** | Unauthorized privilege escalation via RAPL energy counters (CVE-2020-8694 PLATYPUS attack). | Explicitly omit CPU/GPU power wattage readouts (D-05). Quickshell executes 100% in user-space with zero root/udev dependencies. |
| **ASVS V5 / Command Injection** | Arbitrary command execution via shell argument injection in `Process` or ping config. | In `server.py`, validate target expressions with `_LABEL_SAFE` regex and restrict host resolution. In QML `Process`, pass static argument arrays `["bash", "-c", "timeout 3 df -k -P"]` without string interpolation. |
| **ASVS V13 / Denial of Service (Thread Stalling)** | Qt Quick event loop freeze caused by synchronous I/O or hanging cloud mounts. | Use non-blocking `FileView` for sysfs/procfs, asynchronous `Quickshell.Io.Process` with timeout for `df`, and async `XMLHttpRequest` with 2500ms timeout for ping polling. |
| **ASVS V14 / Localhost Boundary** | Exposure of ping monitor metrics to untrusted external networks. | Ensure `server.py` continues binding strictly to loopback `127.0.0.1` (`BIND_HOST=127.0.0.1`). |

---

## Sources

### Authoritative Documentation
- Linux Kernel Documentation: `Documentation/admin-guide/iostats.rst` (Linux `/proc/diskstats` format and 512-byte sector definition)
- Linux Kernel Documentation: `Documentation/gpu/drm-uapi.rst` & `Documentation/gpu/i915.rst` (Intel iGPU RC6 residency and frequency sysfs nodes)
- Linux Kernel Documentation: `Documentation/hwmon/sysfs-interface.rst` (Hardware monitoring sysfs interface)
- Quickshell Documentation: `https://quickshell.outfoxxed.me/` (API reference for `FileView`, `Process`, `Singleton`, `StdioCollector`)

### In-Repo Verification Sources
- `stow/system_monitor/.config/system_monitor/ping/server.py` [VERIFIED: read file]
- `stow/system_monitor/.config/system_monitor/ping/docker-compose.yml` [VERIFIED: read file]
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` [VERIFIED: read file]
- `restow/quickshell/.config/quickshell/ii/services/Voice.qml` [VERIFIED: read file]
- `arch/dots-hyprland.sh` [VERIFIED: executed `verify --strict`]

---

## Metadata

- **Phase:** 42: Telemetry Services & Sensor Infrastructure
- **Date:** 2026-09-25
- **Status:** Complete — Ready for Planning
