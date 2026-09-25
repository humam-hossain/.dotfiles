pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // =========================================================================
    // D-01: Adaptive Polling Cadence (1000ms active / 3000ms idle)
    // =========================================================================
    property int fastPollingRequests: 0
    readonly property bool fastPolling: fastPollingRequests > 0 || overallCpuLoad > 0.15 || gpuLoad > 0.15

    Timer {
        id: pollTimer
        interval: root.fastPolling ? 1000 : 3000
        repeat: true
        running: true
        onTriggered: root.pollAll()
    }

    // =========================================================================
    // Dynamic Path Configuration & Fallbacks
    // =========================================================================
    property string hwmonCoretempPath: "/sys/class/hwmon/hwmon5"
    property string hwmonNvme1Path: "/sys/class/hwmon/hwmon1"
    property string hwmonNvme2Path: "/sys/class/hwmon/hwmon2"
    property string hwmonMoboPath: "/sys/class/hwmon/hwmon3"

    property string gpuRc6Path: "/sys/class/drm/card1/gt/gt0/rc6_residency_ms"
    property string gpuFreqPath: "/sys/class/drm/card1/gt_act_freq_mhz"
    property string gpuThrottlePath: "/sys/class/drm/card1/gt/gt0/throttle_reason_thermal"

    property string eppPath: "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"
    property string govPath: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

    // One-shot hwmon device resolver at startup
    Process {
        id: hwmonDiscoveryProc
        running: true
        command: ["bash", "-c", "for h in /sys/class/hwmon/hwmon*; do [ -f \"$h/name\" ] && echo \"$(cat $h/name 2>/dev/null):$h\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let nvmeCount = 0;
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts.length === 2) {
                        const name = parts[0].trim();
                        const path = parts[1].trim();
                        if (name === "coretemp") {
                            root.hwmonCoretempPath = path;
                        } else if (name === "gigabyte_wmi") {
                            root.hwmonMoboPath = path;
                        } else if (name === "nvme") {
                            if (nvmeCount === 0) root.hwmonNvme1Path = path;
                            else if (nvmeCount === 1) root.hwmonNvme2Path = path;
                            nvmeCount++;
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // Virtual File Observers
    // =========================================================================
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
        id: fileEpp
        path: root.eppPath
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileGov
        path: root.govPath
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
        path: root.hwmonCoretempPath + "/temp1_input"
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileNvme1Temp
        path: root.hwmonNvme1Path + "/temp1_input"
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileNvme2Temp
        path: root.hwmonNvme2Path + "/temp1_input"
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileMoboTemp
        path: root.hwmonMoboPath + "/temp1_input"
        printErrors: false
        blockLoading: true
    }

    // =========================================================================
    // D-02: CPU P-Core & E-Core Segregated Metrics
    // =========================================================================
    property real overallCpuLoad: 0.0
    property real pCoreLoad: 0.0
    property real eCoreLoad: 0.0
    property real pCoreFrequencyMhz: 0.0
    property real eCoreFrequencyMhz: 0.0
    property var perThreadLoads: []
    property var threadLoads: perThreadLoads
    property var threadFrequencies: []
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

            // Fields: user, nice, system, idle, iowait, irq, softirq, steal
            const total = parts.slice(1, 9).reduce((acc, val) => acc + (parseFloat(val) || 0), 0);
            const idle = (parseFloat(parts[4]) || 0) + (parseFloat(parts[5]) || 0);
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
                const cpuIdx = parseInt(name.replace("cpu", ""), 10);
                if (!isNaN(cpuIdx) && cpuIdx < 20) {
                    newThreadLoads[cpuIdx] = load;
                    if (cpuIdx < 12) {
                        pCoreSum += load; // CPUs 0-11: 6 P-cores (12 threads)
                    } else {
                        eCoreSum += load; // CPUs 12-19: 8 E-cores (8 threads)
                    }
                }
            }
        }
        perThreadLoads = newThreadLoads;
        pCoreLoad = pCoreSum / 12.0;
        eCoreLoad = eCoreSum / 8.0;
    }

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

    // =========================================================================
    // D-03: EPP & Scaling Governor
    // =========================================================================
    property string energyPerformancePreference: "balance_performance"
    property string scalingGovernor: "powersave"

    function updateGovernors() {
        fileEpp.reload();
        const epp = fileEpp.text().trim();
        if (epp.length > 0) energyPerformancePreference = epp;

        fileGov.reload();
        const gov = fileGov.text().trim();
        if (gov.length > 0) scalingGovernor = gov;
    }

    // =========================================================================
    // D-04: Intel UHD 770 iGPU Telemetry via RC6 Sleep Delta
    // =========================================================================
    property real gpuLoad: 0.0
    property real gpuFrequencyMhz: 0.0
    property real gpuClockMhz: gpuFrequencyMhz
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
        gpuFrequencyMhz = isNaN(freq) ? 0.0 : freq;

        const throttle = parseInt(fileGpuThrottle.text().trim(), 10);
        gpuThrottled = (!isNaN(throttle) && throttle !== 0);
    }

    // =========================================================================
    // D-06 & D-07: System Thermals & Peak Alert Computation
    // =========================================================================
    property int packageTemp: 0
    property int peakSystemTemperature: 0
    property string peakDeviceLabel: "CPU"
    property int nvme1Temp: 0
    property int nvme2Temp: 0
    property int vrmTemp: 0
    property int motherboardTemp: vrmTemp

    function updateThermals() {
        filePackageTemp.reload();
        const pkgRaw = parseInt(filePackageTemp.text().trim(), 10);
        packageTemp = isNaN(pkgRaw) ? 0 : Math.round(pkgRaw / 1000.0);

        fileNvme1Temp.reload();
        const n1Raw = parseInt(fileNvme1Temp.text().trim(), 10);
        nvme1Temp = isNaN(n1Raw) ? 0 : Math.round(n1Raw / 1000.0);

        fileNvme2Temp.reload();
        const n2Raw = parseInt(fileNvme2Temp.text().trim(), 10);
        nvme2Temp = isNaN(n2Raw) ? 0 : Math.round(n2Raw / 1000.0);

        fileMoboTemp.reload();
        const moboRaw = parseInt(fileMoboTemp.text().trim(), 10);
        vrmTemp = isNaN(moboRaw) ? 0 : Math.round(moboRaw / 1000.0);

        let peak = packageTemp;
        let label = "CPU";
        if (nvme1Temp > peak) { peak = nvme1Temp; label = "NVMe 1"; }
        if (nvme2Temp > peak) { peak = nvme2Temp; label = "NVMe 2"; }
        if (vrmTemp > peak) { peak = vrmTemp; label = "VRM"; }

        peakSystemTemperature = peak;
        peakDeviceLabel = label;
    }

    // =========================================================================
    // Master Polling Dispatcher
    // =========================================================================
    function pollAll() {
        updateCpuLoad();
        updateFrequencies();
        updateGovernors();
        updateGpuMetrics();
        updateThermals();
    }

    Component.onCompleted: {
        root.pollAll();
    }
}
