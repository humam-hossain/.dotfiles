# Phase 42: Telemetry Services & Sensor Infrastructure - Pattern Map

**Mapped:** 2026-09-25  
**Files Analyzed:** 6  
**Analogs Found:** 6 / 6  

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` | service | sysfs / procfs file-I/O & pub-sub | `restow/quickshell/.config/quickshell/ii/services/Voice.qml` & `vendor/dots-hyprland/.../services/ResourceUsage.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml` | service | procfs file-I/O & process execution | `restow/quickshell/.config/quickshell/ii/services/Updates.qml` & `vendor/dots-hyprland/.../services/ResourceUsage.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/services/PingService.qml` | service | asynchronous HTTP polling / pub-sub | `vendor/dots-hyprland/.../services/Booru.qml` & `restow/quickshell/.../services/Voice.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml` | service (overlay) | procfs file-I/O / pub-sub | `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` | exact |
| `stow/system_monitor/.config/system_monitor/ping/server.py` | daemon / API | ICMP / SQLite / HTTP JSON | `stow/system_monitor/.config/system_monitor/ping/server.py` | exact |
| `scripts/phase42-telemetry-services-assert.sh` | test harness | batch verification / headless QML | `scripts/phase35-voice-telemetry-assert.sh` & `scripts/phase41-interactions-assert.sh` | exact |

---

## Pattern Assignments

### 1. `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml`

**Role:** Backend Hardware & Thermal Telemetry Singleton  
**Data Flow:** Non-blocking `/proc` and `/sys` virtual file polling -> reactive state properties (pub-sub)  
**Primary Analog:** `restow/quickshell/.config/quickshell/ii/services/Voice.qml` (singleton structure, `FileView` configuration with `blockLoading: true; printErrors: false`, adaptive polling cadence via dynamic `Timer.interval`)  
**Secondary Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` (reading `/proc/stat`, calculating CPU delta ticks, process collector pattern)  

#### Concrete Patterns to Copy:

**Singleton Declaration & Imports** (from `Voice.qml` lines 1–8):
```qml
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
```

**Non-Blocking Virtual File Reading via `FileView`** (from `Voice.qml` lines 55–67, 84–96):
```qml
    FileView {
        id: fileProcStat
        path: "/proc/stat"
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileCpuInfo
        path: "/proc/cpuinfo"
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileGpuRc6
        path: root.gpuRc6Path
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileGpuFreq
        path: root.gpuFreqPath
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileGpuThrottle
        path: root.gpuThrottlePath
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: filePackageTemp
        path: root.packageTempPath
        printErrors: false
        blockLoading: true
    }
```

**Adaptive Polling Timer Cadence** (adapted from `Voice.qml` lines 253–259 and Decision D-01):
```qml
    // Dynamic fast polling requested by open popups (Phase 43 CpuGpuPopup)
    property int fastPollingRequests: 0
    readonly property bool fastPolling: fastPollingRequests > 0 || overallCpuLoad > 0.15 || gpuLoad > 0.15

    Timer {
        id: pollTimer
        interval: root.fastPolling ? 1000 : 3000
        repeat: true
        running: true
        onTriggered: root.pollAll()
    }

    Component.onCompleted: {
        root.pollAll();
    }
```

**CPU P-Core vs E-Core Segregation Logic** (from `/proc/stat` delta ticks, Decision D-02):
```qml
    property real overallCpuLoad: 0.0
    property real pCoreLoad: 0.0
    property real eCoreLoad: 0.0
    property var threadLoads: [] // 20 threads (CPUs 0-19)
    property var prevCpuTicks: ({})

    function updateCpuLoad() {
        fileProcStat.reload();
        const text = fileProcStat.text();
        if (!text) return;

        const lines = text.split("\n");
        let newThreadLoads = [];
        let pCoreSum = 0;
        let eCoreSum = 0;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line.startsWith("cpu")) continue;
            const parts = line.split(/\s+/);
            const name = parts[0];

            // Sum user, nice, system, idle, iowait, irq, softirq, steal
            const total = parts.slice(1, 9).reduce((acc, val) => acc + parseFloat(val), 0);
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
                        pCoreSum += load; // CPUs 0-11 (6 P-cores, 12 threads)
                    } else {
                        eCoreSum += load; // CPUs 12-19 (8 E-cores, 8 threads)
                    }
                }
            }
        }
        threadLoads = newThreadLoads;
        pCoreLoad = pCoreSum / 12.0;
        eCoreLoad = eCoreSum / 8.0;
    }
```

**Single-Buffer Frequency Parsing from `/proc/cpuinfo`:**
```qml
    property real pCoreFrequencyMhz: 0.0
    property real eCoreFrequencyMhz: 0.0
    property var threadFrequencies: [] // 20 threads

    function updateFrequencies() {
        fileCpuInfo.reload();
        const text = fileCpuInfo.text();
        if (!text) return;

        const matches = [...text.matchAll(/cpu MHz\s*:\s*([0-9.]+)/g)];
        let freqs = [];
        let pSum = 0;
        let eSum = 0;

        for (let i = 0; i < matches.length && i < 20; i++) {
            const freq = parseFloat(matches[i][1]);
            freqs[i] = isNaN(freq) ? 0.0 : freq;
            if (i < 12) {
                pSum += freqs[i];
            } else {
                eSum += freqs[i];
            }
        }
        threadFrequencies = freqs;
        pCoreFrequencyMhz = freqs.length >= 12 ? (pSum / 12.0) : 0.0;
        eCoreFrequencyMhz = freqs.length >= 20 ? (eSum / 8.0) : 0.0;
    }
```

**Intel UHD 770 iGPU Telemetry via RC6 Sleep Delta** (Decision D-04):
```qml
    property real gpuLoad: 0.0
    property real gpuClockMhz: 0.0
    property bool gpuThrottled: false
    property real lastGpuSampleTime: 0
    property real lastRc6Ms: 0

    function updateGpuMetrics() {
        fileGpuRc6.reload();
        fileGpuFreq.reload();
        fileGpuThrottle.reload();

        const now = Date.now();
        const rc6 = parseFloat(fileGpuRc6.text().trim());
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

**System Thermals & Peak Alert Computation** (Decisions D-06, D-07):
```qml
    property int packageTemp: 0
    property int peakSystemTemperature: 0
    property string peakDeviceLabel: "CPU"
    property int nvme1Temp: 0
    property int nvme2Temp: 0
    property int motherboardTemp: 0

    function updateThermals() {
        filePackageTemp.reload();
        const pkgRaw = parseInt(filePackageTemp.text().trim());
        packageTemp = isNaN(pkgRaw) ? 0 : Math.round(pkgRaw / 1000.0);

        fileNvme1Temp.reload();
        const n1Raw = parseInt(fileNvme1Temp.text().trim());
        nvme1Temp = isNaN(n1Raw) ? 0 : Math.round(n1Raw / 1000.0);

        fileNvme2Temp.reload();
        const n2Raw = parseInt(fileNvme2Temp.text().trim());
        nvme2Temp = isNaN(n2Raw) ? 0 : Math.round(n2Raw / 1000.0);

        fileMoboTemp.reload();
        const moboRaw = parseInt(fileMoboTemp.text().trim());
        motherboardTemp = isNaN(moboRaw) ? 0 : Math.round(moboRaw / 1000.0);

        // Compute peakSystemTemperature and label (D-06)
        let peak = packageTemp;
        let label = "CPU";
        if (nvme1Temp > peak) { peak = nvme1Temp; label = "NVMe 1"; }
        if (nvme2Temp > peak) { peak = nvme2Temp; label = "NVMe 2"; }
        if (motherboardTemp > peak) { peak = motherboardTemp; label = "VRM"; }

        peakSystemTemperature = peak;
        peakDeviceLabel = label;
    }
```

**Startup Hardware Path Resolver Process** (dynamic verification of hwmon devices):
```qml
    Process {
        id: hwmonDiscoveryProc
        running: true
        command: ["bash", "-c", "for h in /sys/class/hwmon/hwmon*; do [ -f \"$h/name\" ] && echo \"$(cat $h/name):$h\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts.length === 2) {
                        const name = parts[0].trim();
                        const path = parts[1].trim();
                        if (name === "coretemp") root.hwmonCoretempPath = path;
                        else if (name === "gigabyte_wmi") root.hwmonMoboPath = path;
                    }
                }
            }
        }
    }
```

---

### 2. `restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml`

**Role:** Storage Mount & I/O Engine Singleton  
**Data Flow:** Continuous `/proc/diskstats` sampling via `FileView` + pure I/O-driven `df -k -P` execution via `Process` -> reactive state properties (pub-sub)  
**Primary Analog:** `restow/quickshell/.config/quickshell/ii/services/Updates.qml` (Process spawning with `StdioCollector`, `refresh()` pattern, conditional triggering)  
**Secondary Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` (data conversion helpers like `kbToGbString`, FileView polling)  

#### Concrete Patterns to Copy:

**Pure I/O-Driven `/proc/diskstats` Delta Accounting** (Decision D-08, D-09, D-10):
```qml
    property real diskIoPercentage: 0.0
    property real readSpeedBytes: 0.0
    property real writeSpeedBytes: 0.0
    property string activeDisk: "/"
    property real lastSampleTime: 0
    property var prevDiskTicks: ({})
    property real lastDfTime: 0
    readonly property real dfCooldownMs: 15000 // Minimum 15s between I/O-triggered df runs

    FileView {
        id: fileDiskstats
        path: "/proc/diskstats"
        printErrors: false
        blockLoading: true
    }

    function updateDiskIo() {
        fileDiskstats.reload();
        const text = fileDiskstats.text();
        if (!text) return;

        const now = Date.now();
        const dt = lastSampleTime > 0 ? (now - lastSampleTime) / 1000.0 : 1.0;
        const lines = text.split("\n");

        let totalIoTicksDelta = 0;
        let totalReadSectorsDelta = 0;
        let totalWriteSectorsDelta = 0;
        let maxDiskDelta = 0;
        let mostActiveDevice = "";

        // Track physical disk devices: nvme1n1, nvme0n1, sda
        const monitoredDevices = ["nvme1n1", "nvme0n1", "sda"];

        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length < 14) continue;
            const dev = parts[2];
            if (!monitoredDevices.includes(dev)) continue;

            const readSectors = parseFloat(parts[5]);  // Field 6: sectors read (512 bytes)
            const writeSectors = parseFloat(parts[9]); // Field 10: sectors written (512 bytes)
            const ioTicks = parseFloat(parts[12]);     // Field 13: ms spent doing I/O

            const prev = prevDiskTicks[dev];
            if (prev && dt > 0.1) {
                const dTicks = Math.max(0, ioTicks - prev.ioTicks);
                const dRead = Math.max(0, readSectors - prev.readSectors);
                const dWrite = Math.max(0, writeSectors - prev.writeSectors);

                totalIoTicksDelta += dTicks;
                totalReadSectorsDelta += dRead;
                totalWriteSectorsDelta += dWrite;

                if (dTicks > maxDiskDelta) {
                    maxDiskDelta = dTicks;
                    mostActiveDevice = dev;
                }
            }
            prevDiskTicks[dev] = { ioTicks: ioTicks, readSectors: readSectors, writeSectors: writeSectors };
        }

        lastSampleTime = now;

        if (dt > 0.1) {
            // ioTicks represents ms spent doing I/O; normalize to 0..100%
            const totalMs = dt * 1000.0;
            diskIoPercentage = Math.max(0.0, Math.min(100.0, (totalIoTicksDelta / totalMs) * 100.0));
            // 512 bytes per sector (Linux kernel standard)
            readSpeedBytes = (totalReadSectorsDelta * 512.0) / dt;
            writeSpeedBytes = (totalWriteSectorsDelta * 512.0) / dt;
        }

        // Active disk focus (D-10)
        if (maxDiskDelta > 0 && mostActiveDevice) {
            root.activeDisk = root.deviceToMount(mostActiveDevice);
        } else {
            root.activeDisk = "/";
        }

        // Pure I/O-driven trigger: only spawn df if I/O occurred and cooldown elapsed (D-08)
        if (totalIoTicksDelta > 0 && (now - lastDfTime) > dfCooldownMs) {
            root.refresh();
        }
    }
```

**Asynchronous `df` Execution & Filtering Pattern** (from `Updates.qml` lines 50–58, adapted with `-k -P` single-line formatting and 3s timeout):
```qml
    property var physicalDisks: []
    property var cloudDisks: []
    property var allDisks: []
    property var rootDisk: ({ mount: "/", totalKb: 0, usedKb: 0, availKb: 0, usePercent: 0, label: "Root" })

    function refresh() {
        if (!dfProc.running) {
            dfProc.running = true;
        }
    }

    Process {
        id: dfProc
        command: ["bash", "-c", "timeout 3 df -k -P"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.lastDfTime = Date.now();
                root.parseDfOutput(text);
            }
        }
    }

    function parseDfOutput(output) {
        if (!output) return;
        const lines = output.trim().split("\n");
        let phys = [];
        let cloud = [];

        // Ignored pseudo-filesystems (Decision D-11)
        const ignoredTypes = ["devtmpfs", "tmpfs", "efivarfs", "none"];

        for (let i = 1; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length < 6) continue;

            const fs = parts[0];
            const totalKb = parseInt(parts[1]);
            const usedKb = parseInt(parts[2]);
            const availKb = parseInt(parts[3]);
            const pctStr = parts[4];
            const mount = parts[5];

            if (ignoredTypes.some(t => fs === t || fs.startsWith(t))) continue;

            const usePercent = parseInt(pctStr.replace("%", "")) || 0;
            const entry = {
                fs: fs,
                mount: mount,
                totalKb: totalKb,
                usedKb: usedKb,
                availKb: availKb,
                usePercent: usePercent,
                label: root.labelForMount(mount)
            };

            if (mount.includes("GoogleDrive") || fs.startsWith("gdrive-")) {
                cloud.push(entry);
            } else if (["/", "/boot", "/mnt/windows", "/mnt/hdd"].includes(mount) || fs.startsWith("/dev/")) {
                phys.push(entry);
                if (mount === "/") {
                    root.rootDisk = entry;
                }
            }
        }

        physicalDisks = phys;
        cloudDisks = cloud;
        allDisks = [...phys, ...cloud];
    }
```

---

### 3. `restow/quickshell/.config/quickshell/ii/services/PingService.qml`

**Role:** Ping Daemon Client Singleton  
**Data Flow:** HTTP GET `http://127.0.0.1:8765/api/status` -> reactive properties (pub-sub)  
**Primary Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Booru.qml` (lines 372–405: `XMLHttpRequest` GET pattern, JSON parsing, error trapping)  
**Secondary Analog:** `restow/quickshell/.config/quickshell/ii/services/Voice.qml` (fail-soft state evaluation, timer backoff, fallback defaults)  

#### Concrete Patterns to Copy:

**`XMLHttpRequest` Client with 5s Interval & 15s Offline Backoff** (Decision D-13, D-14):
```qml
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    property var targets: []
    property var wanTarget: ({ host: "8.8.8.8", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
    property var gatewayTarget: ({ host: "192.168.0.1", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
    property var serverTarget: ({ host: "192.168.0.104", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
    property string overallClass: "dead"
    property bool isOffline: true

    readonly property string endpointUrl: "http://127.0.0.1:8765/api/status"

    Timer {
        id: pollTimer
        interval: root.isOffline ? 15000 : 5000
        repeat: true
        running: true
        onTriggered: root.fetchStatus()
    }

    Component.onCompleted: {
        root.fetchStatus();
    }

    function fetchStatus() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.endpointUrl);
        xhr.timeout = 2500;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const data = JSON.parse(xhr.responseText);
                        root.isOffline = false;
                        root.overallClass = data.overall_class || data.class || "dead";
                        root.targets = data.targets || [];

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
        root.isOffline = true;
        root.overallClass = "dead";
        root.wanTarget = { host: "8.8.8.8", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
        root.gatewayTarget = { host: "192.168.0.1", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
        root.serverTarget = { host: "192.168.0.104", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
    }
}
```

---

### 4. `restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml`

**Role:** Extended Memory & Swap Telemetry Singleton (Restow Overlay)  
**Data Flow:** Non-blocking `/proc/meminfo` parsing -> reactive memory properties (pub-sub)  
**Primary Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` (exact upstream vendor file being overlaid with extended fields)  

#### Concrete Patterns to Copy:

**Upstream Memory Properties & Extended Fields** (Decision D-15):
```qml
pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Core Memory Properties (extended per D-15)
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryAvailable: 0
    property real memoryBuffers: 0
    property real memoryCached: 0
    property real memoryUsed: Math.max(0, memoryTotal - memoryAvailable)
    property real memoryUsedPercentage: memoryTotal > 0 ? (memoryUsed / memoryTotal) : 0

    // Swap Properties (preserved from upstream)
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0

    // CPU Properties (preserved from upstream for backward compatibility)
    property real cpuUsage: 0
    property var previousCpuStats
    property string maxAvailableMemoryString: kbToGbString(root.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(root.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }
```

**Extended `/proc/meminfo` Regex Extraction** (in Timer `onTriggered`):
```qml
    Timer {
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            fileMeminfo.reload();
            fileStat.reload();

            const textMeminfo = fileMeminfo.text();
            root.memoryTotal = Number(textMeminfo.match(/^MemTotal:\s*(\d+)/m)?.[1] ?? 1);
            root.memoryAvailable = Number(textMeminfo.match(/^MemAvailable:\s*(\d+)/m)?.[1] ?? 0);
            root.memoryFree = Number(textMeminfo.match(/^MemFree:\s*(\d+)/m)?.[1] ?? 0);
            root.memoryBuffers = Number(textMeminfo.match(/^Buffers:\s*(\d+)/m)?.[1] ?? 0);
            root.memoryCached = Number(textMeminfo.match(/^Cached:\s*(\d+)/m)?.[1] ?? 0);

            root.swapTotal = Number(textMeminfo.match(/^SwapTotal:\s*(\d+)/m)?.[1] ?? 1);
            root.swapFree = Number(textMeminfo.match(/^SwapFree:\s*(\d+)/m)?.[1] ?? 0);

            // CPU usage handling preserved from upstream
            ...
            root.updateHistories();
            interval = Config.options?.resources?.updateInterval ?? 3000;
        }
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo"; blockLoading: true; printErrors: false }
    FileView { id: fileStat; path: "/proc/stat"; blockLoading: true; printErrors: false }
```

---

### 5. `stow/system_monitor/.config/system_monitor/ping/server.py`

**Role:** Ping Viz HTTP Server & Collector Daemon  
**Data Flow:** Multithreaded ICMP probing -> SQLite persistence -> JSON HTTP API  
**Primary Analog:** `stow/system_monitor/.config/system_monitor/ping/server.py` (lines 475–500, 571–584)  

#### Concrete Patterns to Modify:

**Structured Clean JSON Emission in `api_status`** (Decision D-12):
```python
def stale_status() -> dict[str, Any]:
    return {
        "text": "ping stale",
        "class": "dead",
        "generated_at": None,
        "overall_class": "dead",
        "targets": [],
    }

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
        "targets": cycle.get("targets", []),
    }
```
*Note on Docker rebuild (Pitfall 2):* Since `Dockerfile` copies `server.py` into `/app/server.py` during build time, modifying `server.py` requires restarting/rebuilding the container:
```bash
docker compose up -d --build
```

---

### 6. `scripts/phase42-telemetry-services-assert.sh`

**Role:** Automated Validation Test Harness  
**Data Flow:** Shell execution, QML static checks & headless execution -> exit code & pass/fail logging  
**Primary Analog:** `scripts/phase35-voice-telemetry-assert.sh` (service test harness with headless quickshell execution, FileView blockLoading/printErrors checks, adaptive timer checks, git porcelain invariance)  
**Secondary Analog:** `scripts/phase41-interactions-assert.sh` (overlay leaf symlink checks, directory folding guards, submodule cleanliness)  

#### Concrete Patterns to Copy:

**Script Boilerplate & Safe Invariance Checks** (from `phase35-voice-telemetry-assert.sh` lines 1–94):
```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 42: Telemetry Services & Sensor Infrastructure Assert Harness
# Enforces: CPUGPU-01..04, MEMDSK-01..04, NETPING-01..05, INTG-01..03,
#           D-01 through D-15
#
# Usage (from REPO_ROOT):
#   ./scripts/phase42-telemetry-services-assert.sh [--section <1-6>] [-s <1-6>]
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  return 0
}
trap cleanup EXIT

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p42-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p42-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

**Headless Quickshell Runner Helper** (from `phase35-voice-telemetry-assert.sh` lines 96–116):
```bash
run_qs_test() {
  local qml_content="$1"
  local timeout_sec="${2:-2.0}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME}/quickshell/ii/p42_runner_XXXXXX.qml")"
  TMP_FILES+=("$runner_file")

  printf '%s\n' "$qml_content" > "$runner_file"
  local out=""
  out="$(timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  rm -f "$runner_file" 2>/dev/null || true
  printf '%s\n' "$out"
}
```

**Section 1: Declarative Pragmas & FileView Options**:
```bash
for service in HardwareTelemetry.qml StorageUsage.qml PingService.qml ResourceUsage.qml; do
  svc_path="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/$service"
  if grep -q "^pragma Singleton" "$svc_path" && grep -q "^pragma ComponentBehavior: Bound" "$svc_path"; then
    pass "S1: $service declares required pragmas"
  else
    fail "S1: $service missing required pragmas"
  fi
done
```

**Section 6: Closing Git Porcelain Check**:
```bash
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "S6: git status --porcelain unchanged across assert run"
else
  fail "S6: git status --porcelain mutated across assert run"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

## Shared Patterns

### Pattern 1: Non-Blocking Procfs/Sysfs Observation via `FileView`
**Source:** `restow/quickshell/.config/quickshell/ii/services/Voice.qml`  
**Applied to:** `HardwareTelemetry.qml`, `StorageUsage.qml`, `ResourceUsage.qml`  
Virtual kernel files (`/proc/*` and `/sys/*`) lack inotify modification events. Always set `blockLoading: true` and `printErrors: false` on `FileView` nodes so calling `.reload()` immediately followed by `.text()` reads synchronously from the in-memory buffer without race conditions or error log spam.

### Pattern 2: Process Execution with `StdioCollector` & Timeout Defense
**Source:** `restow/quickshell/.config/quickshell/ii/services/Updates.qml`  
**Applied to:** `StorageUsage.qml` (`dfProc`), `HardwareTelemetry.qml` (`hwmonDiscoveryProc`)  
Always wrap external commands with `timeout` (e.g. `timeout 3 df -k -P`) to prevent network hangs on FUSE cloud mounts, and collect standard output asynchronously with `StdioCollector { onStreamFinished: { ... } }`.

### Pattern 3: Asynchronous HTTP Polling via `XMLHttpRequest` with Dynamic Timer Backoff
**Source:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Booru.qml`  
**Applied to:** `PingService.qml`  
To query the local daemon without freezing the Qt Quick render thread, use `XMLHttpRequest` with an explicit timeout (`xhr.timeout = 2500`). On failure or timeout, adjust the `Timer.interval` from 5000ms to 15000ms (fail-soft offline backoff) until connectivity is restored.

### Pattern 4: Hybrid Architecture & Multi-Core Workload Segregation
**Source:** Linux sysfs `/sys/devices/system/cpu/` & `/proc/stat`  
**Applied to:** `HardwareTelemetry.qml`  
Host CPU is 13th Gen Intel Core i5-13500 with 6 P-cores (12 threads, CPUs 0–11) and 8 E-cores (8 threads, CPUs 12–19). The telemetry singleton maps threads 0–11 to `pCoreLoad` / `pCoreFrequencyMhz` and threads 12–19 to `eCoreLoad` / `eCoreFrequencyMhz`, while maintaining `overallCpuLoad` and a 20-element `threadLoads` array.

### Pattern 5: Pure I/O-Driven Process Throttling & On-Demand Invalidation
**Source:** Decision D-08  
**Applied to:** `StorageUsage.qml`  
Never poll `df` periodically when disk I/O is idle ($\Delta \text{io\_ticks} == 0$). Trigger `dfProc` only when active sector reads/writes occur (with a 15-second cooldown), or immediately on-demand when the UI popup invokes `StorageUsage.refresh()`.

### Pattern 6: Automated Verification & Porcelain Invariance Harness
**Source:** `scripts/phase35-voice-telemetry-assert.sh` & `scripts/phase41-interactions-assert.sh`  
**Applied to:** `scripts/phase42-telemetry-services-assert.sh`  
Test harnesses must fail-closed on root execution (`EUID != 0`), support `--section <1-6>`, use `FAIL` and `FINDINGS` counters, clean up all temporary files via `trap cleanup EXIT`, verify leaf symlinks vs directory non-folding, and verify zero working tree drift via git porcelain diffing.

---

## Anti-Patterns & Pitfalls to Avoid

| Anti-Pattern | Correct Pattern | Reference |
|---|---|---|
| Hand-rolling ICMP ping sockets or spawning `ping` from QML | Poll local HTTP daemon `http://127.0.0.1:8765/api/status` | Avoids subprocess fork storms and unprivileged raw socket restrictions. |
| Scraping HTML spans or nerd font tokens in QML | Update `server.py` to return clean JSON with `targets` array | Enables native QML theming with Material You tokens without fragile regex. |
| Reading RAPL power counters (`/sys/class/powercap/intel-rapl/`) | Explicitly omit CPU/GPU wattage telemetry (D-05) | RAPL files are `0400` root-only (CVE-2020-8694). Omitting guarantees 100% unprivileged execution. |
| Periodic blind polling of `df` every 15s | Continuous `/proc/diskstats` + event-driven `df` on $\Delta \text{ticks} > 0$ | Eliminates unnecessary wakeups and Google Drive FUSE cloud API calls while idle. |
| Using `df -h` without `-P` | Always use `df -k -P` | Prevents line-wrapping on filesystem mount paths longer than 14 characters. |
| Assuming 4096-byte sectors in `/proc/diskstats` | Always multiply sector counts by 512 bytes | Linux kernel `iostats.rst` standard dictates 512 bytes per sector for all block devices. |
| Calling `.reload()` without `blockLoading: true` on virtual files | Set `blockLoading: true` on sysfs/procfs `FileView` | Ensures `.text()` reads the current kernel buffer immediately following `.reload()`. |
| Editing `server.py` without rebuilding Docker image | Run `docker compose up -d --build` after edits | `Dockerfile` copies `server.py` into image at build time; editing host file alone does not update running container. |

---

## No Analog Found

*None. All files planned for creation or modification in Phase 42 have exact analogs in the existing repository codebase or tracked submodules.*

---

## Metadata

**Analog Search Scope:**
- `restow/quickshell/.config/quickshell/ii/services/`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/`
- `stow/system_monitor/.config/system_monitor/ping/`
- `scripts/phase*.sh`

**Files Scanned:** 72  
**Pattern Extraction Date:** 2026-09-25  
