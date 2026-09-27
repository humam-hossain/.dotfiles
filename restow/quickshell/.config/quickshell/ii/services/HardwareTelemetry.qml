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
    readonly property bool fastPolling: fastPollingRequests > 0 || overallCpuLoad > 0.50

    onFastPollingRequestsChanged: {
        if (fastPollingRequests < 0) fastPollingRequests = 0;
        if (fastPollingRequests === 1) {
            root.pollTier2();
        }
    }

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
    property string gpuCurFreqPath: "/sys/class/drm/card1/gt_cur_freq_mhz"
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
    // Dynamic Model Strings & Topology Properties (D-01, D-02)
    // =========================================================================
    property string cpuModelName: "CPU"
    property string gpuModelName: "GPU"
    property string motherboardModelName: "Platform"
    property bool isHybridArchitecture: false
    property int pCoreThreadCount: 0
    property int eCoreThreadCount: 0
    property int totalThreadCount: 0

    // One-shot dynamic hardware resolver at startup
    Process {
        id: hardwareDiscoveryProc
        running: true
        command: ["bash", "-c", "cpu_name=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null | sed -E 's/.*(Core\\(TM\\) |AMD )//; s/\\((R|TM)\\)//g; s/CPU //g; s/Processor//g; s/@.*//; s/^[ ]+//; s/[ ]+$//'); [ -z \"$cpu_name\" ] && cpu_name=\"CPU\"; gpu_name=\"GPU\"; if command -v lspci >/dev/null 2>&1; then gpu_raw=$(lspci -d ::0300 2>/dev/null | head -n1 | sed -E 's/.*: (Intel Corporation |Advanced Micro Devices, Inc. \\[AMD\\/ATI\\] |NVIDIA Corporation )?//; s/.*\\[(.*)\\].*/\\1/; s/^[ ]+//; s/[ ]+$//'); [ -n \"$gpu_raw\" ] && gpu_name=\"$gpu_raw\"; fi; mobo_name=\"Platform\"; if [ -r /sys/class/dmi/id/board_name ]; then mobo_name=$(cat /sys/class/dmi/id/board_name 2>/dev/null | xargs); elif [ -r /sys/class/dmi/id/product_name ]; then mobo_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null | xargs); fi; [ -z \"$mobo_name\" ] && mobo_name=\"Platform\"; is_hybrid=false; p_threads=0; e_threads=0; if [ -d /sys/devices/cpu_atom ] && [ -f /sys/devices/cpu_atom/cpus ]; then is_hybrid=true; p_threads=$(cat /sys/devices/cpu_core/cpus 2>/dev/null | tr ',' '\\n' | awk -F- '{ if ($2 != \"\") sum += ($2 - $1 + 1); else sum += 1 } END { print sum }'); e_threads=$(cat /sys/devices/cpu_atom/cpus 2>/dev/null | tr ',' '\\n' | awk -F- '{ if ($2 != \"\") sum += ($2 - $1 + 1); else sum += 1 } END { print sum }'); else p_threads=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1); e_threads=0; fi; echo \"$cpu_name|$gpu_name|$mobo_name|$is_hybrid|$p_threads|$e_threads\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                if (parts.length >= 6) {
                    root.cpuModelName = parts[0] || "CPU";
                    root.gpuModelName = parts[1] || "GPU";
                    root.motherboardModelName = parts[2] || "Platform";
                    root.isHybridArchitecture = (parts[3] === "true");
                    root.pCoreThreadCount = parseInt(parts[4], 10) || 0;
                    root.eCoreThreadCount = parseInt(parts[5], 10) || 0;
                    root.totalThreadCount = root.pCoreThreadCount + root.eCoreThreadCount;
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
        id: fileGpuCurFreq
        path: root.gpuCurFreqPath
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

    // Coretemp Core inputs (6 P-cores: temp2, temp6, temp10, temp14, temp18, temp22)
    FileView { id: fileCoreTemp2; path: root.hwmonCoretempPath + "/temp2_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp6; path: root.hwmonCoretempPath + "/temp6_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp10; path: root.hwmonCoretempPath + "/temp10_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp14; path: root.hwmonCoretempPath + "/temp14_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp18; path: root.hwmonCoretempPath + "/temp18_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp22; path: root.hwmonCoretempPath + "/temp22_input"; printErrors: false; blockLoading: true }

    // Coretemp Core inputs (8 E-cores: temp26 through temp33)
    FileView { id: fileCoreTemp26; path: root.hwmonCoretempPath + "/temp26_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp27; path: root.hwmonCoretempPath + "/temp27_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp28; path: root.hwmonCoretempPath + "/temp28_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp29; path: root.hwmonCoretempPath + "/temp29_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp30; path: root.hwmonCoretempPath + "/temp30_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp31; path: root.hwmonCoretempPath + "/temp31_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp32; path: root.hwmonCoretempPath + "/temp32_input"; printErrors: false; blockLoading: true }
    FileView { id: fileCoreTemp33; path: root.hwmonCoretempPath + "/temp33_input"; printErrors: false; blockLoading: true }

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

    // Gigabyte WMI platform sensors (temp1_input through temp6_input)
    FileView { id: fileMoboTemp1; path: root.hwmonMoboPath + "/temp1_input"; printErrors: false; blockLoading: true }
    FileView { id: fileMoboTemp2; path: root.hwmonMoboPath + "/temp2_input"; printErrors: false; blockLoading: true }
    FileView { id: fileMoboTemp3; path: root.hwmonMoboPath + "/temp3_input"; printErrors: false; blockLoading: true }
    FileView { id: fileMoboTemp4; path: root.hwmonMoboPath + "/temp4_input"; printErrors: false; blockLoading: true }
    FileView { id: fileMoboTemp5; path: root.hwmonMoboPath + "/temp5_input"; printErrors: false; blockLoading: true }
    FileView { id: fileMoboTemp6; path: root.hwmonMoboPath + "/temp6_input"; printErrors: false; blockLoading: true }

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

    function updateCpuLoadTier1() {
        fileProcStat.reload();
        const text = fileProcStat.text();
        if (!text) return;

        const line = text.slice(0, text.indexOf("\n")).trim();
        if (!line.startsWith("cpu ")) return;
        const parts = line.split(/\s+/);
        const total = parts.slice(1, 9).reduce((acc, val) => acc + (parseFloat(val) || 0), 0);
        const idle = (parseFloat(parts[4]) || 0) + (parseFloat(parts[5]) || 0);
        const active = total - idle;

        const prev = prevCpuTicks["cpu"];
        if (prev) {
            const dTotal = total - prev.total;
            const dActive = active - prev.active;
            overallCpuLoad = dTotal > 0 ? Math.max(0.0, Math.min(1.0, dActive / dTotal)) : 0.0;
        }
        prevCpuTicks["cpu"] = { total: total, active: active };
    }

    function updateCpuLoadTier2() {
        if (!fileProcStat.text()) fileProcStat.reload();
        const text = fileProcStat.text();
        if (!text) return;

        const lines = text.split("\n");
        let newThreadLoads = [];
        let pCoreSum = 0;
        let eCoreSum = 0;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line.startsWith("cpu") || line.startsWith("cpu ")) continue;
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

            const cpuIdx = parseInt(name.replace("cpu", ""), 10);
            if (!isNaN(cpuIdx)) {
                newThreadLoads[cpuIdx] = load;
                if (root.isHybridArchitecture) {
                    if (cpuIdx < root.pCoreThreadCount) {
                        pCoreSum += load;
                    } else if (cpuIdx < root.totalThreadCount) {
                        eCoreSum += load;
                    }
                }
            }
        }
        perThreadLoads = newThreadLoads;
        if (root.isHybridArchitecture) {
            pCoreLoad = root.pCoreThreadCount > 0 ? (pCoreSum / root.pCoreThreadCount) : 0.0;
            eCoreLoad = root.eCoreThreadCount > 0 ? (eCoreSum / root.eCoreThreadCount) : 0.0;
        } else {
            pCoreLoad = overallCpuLoad;
            eCoreLoad = 0.0;
        }
    }

    function updateCpuLoad() {
        updateCpuLoadTier1();
        updateCpuLoadTier2();
    }

    function updateFrequencies() {
        fileCpuInfo.reload();
        const text = fileCpuInfo.text();
        if (!text) return;

        const regex = /cpu MHz\s*:\s*([0-9.]+)/g;
        let match;
        let freqs = [];
        let pSum = 0;
        let eSum = 0;
        let i = 0;

        while ((match = regex.exec(text)) !== null) {
            if (root.totalThreadCount > 0 && i >= root.totalThreadCount) break;
            const freq = parseFloat(match[1]);
            freqs[i] = isNaN(freq) ? 0.0 : freq;
            if (root.isHybridArchitecture) {
                if (i < root.pCoreThreadCount) {
                    pSum += freqs[i];
                } else if (i < root.totalThreadCount) {
                    eSum += freqs[i];
                }
            } else {
                pSum += freqs[i];
            }
            i++;
        }
        threadFrequencies = freqs;
        if (root.isHybridArchitecture) {
            pCoreFrequencyMhz = (root.pCoreThreadCount > 0 && freqs.length >= root.pCoreThreadCount) ? (pSum / root.pCoreThreadCount) : 0.0;
            eCoreFrequencyMhz = (root.eCoreThreadCount > 0 && freqs.length >= root.totalThreadCount) ? (eSum / root.eCoreThreadCount) : 0.0;
        } else {
            pCoreFrequencyMhz = i > 0 ? (pSum / i) : 0.0;
            eCoreFrequencyMhz = 0.0;
        }
    }

    // =========================================================================
    // D-03: EPP, Scaling Governor & Power Profiles
    // =========================================================================
    property string energyPerformancePreference: "balance_performance"
    property string scalingGovernor: "powersave"
    property string activePowerProfile: "power-saver"

    Process {
        id: powerProfileGetter
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const res = text.trim();
                if (res.length > 0) {
                    root.activePowerProfile = res;
                }
            }
        }
    }

    Process {
        id: powerProfileSetter
        command: ["powerprofilesctl", "set", "balanced"]
        onExited: {
            root.updateGovernors();
        }
    }

    function setPowerProfile(profileName) {
        if (!profileName) return;
        powerProfileSetter.command = ["powerprofilesctl", "set", profileName];
        powerProfileSetter.running = true;
    }

    function cyclePowerProfile() {
        const current = (activePowerProfile || energyPerformancePreference || "").toLowerCase();
        let next = "balanced";
        if (current.includes("save") || current === "power") {
            next = "balanced";
        } else if (current.includes("balance")) {
            next = "performance";
        } else {
            next = "power-saver";
        }
        setPowerProfile(next);
    }

    function updateGovernors() {
        fileEpp.reload();
        const epp = fileEpp.text().trim();
        if (epp.length > 0) energyPerformancePreference = epp;

        fileGov.reload();
        const gov = fileGov.text().trim();
        if (gov.length > 0) scalingGovernor = gov;

        if ((root.fastPollingRequests > 0 || root.activePowerProfile === "") && !powerProfileGetter.running) {
            powerProfileGetter.running = true;
        }
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

    function updateGpuRc6Tier1() {
        fileGpuRc6.reload();
        const now = Date.now();
        const rc6 = parseFloat(fileGpuRc6.text().trim());
        if (!isNaN(rc6) && lastGpuSampleTime > 0 && lastRc6Ms > 0) {
            const dt = now - lastGpuSampleTime;
            const dRc6 = rc6 - lastRc6Ms;
            if (dt > 100) {
                const idleRatio = Math.max(0.0, Math.min(1.0, dRc6 / dt));
                const instantLoad = Math.max(0.0, Math.min(1.0, 1.0 - idleRatio));
                gpuLoad = (gpuLoad === 0.0) ? instantLoad : (0.4 * instantLoad + 0.6 * gpuLoad);
            }
        }
        lastGpuSampleTime = now;
        lastRc6Ms = rc6;
    }

    function updateGpuMetricsTier2() {
        fileGpuFreq.reload();
        fileGpuCurFreq.reload();
        fileGpuThrottle.reload();

        const actFreq = parseFloat(fileGpuFreq.text().trim());
        const curFreq = parseFloat(fileGpuCurFreq.text().trim());
        if (!isNaN(actFreq) && actFreq > 0) {
            gpuFrequencyMhz = actFreq;
        } else if (!isNaN(curFreq) && curFreq > 0) {
            gpuFrequencyMhz = curFreq;
        } else {
            gpuFrequencyMhz = !isNaN(actFreq) ? actFreq : (!isNaN(curFreq) ? curFreq : 0.0);
        }

        const throttle = parseInt(fileGpuThrottle.text().trim(), 10);
        gpuThrottled = (!isNaN(throttle) && throttle !== 0);
    }

    function updateGpuMetrics() {
        updateGpuRc6Tier1();
        updateGpuMetricsTier2();
    }

    // =========================================================================
    // D-06 & D-07: System Thermals & Peak Alert Computation
    // =========================================================================
    property int packageTemp: 0
    property int pCoreTempAvg: 0
    property int eCoreTempAvg: 0
    property var pCoreTemps: []
    property var eCoreTemps: []
    property int peakSystemTemperature: 0
    property string peakDeviceLabel: "CPU"
    property int nvme1Temp: 0
    property int nvme2Temp: 0

    // Gigabyte WMI 6 Platform sensor temperatures & averages
    property int platformTemp1: 0
    property int platformTemp2: 0
    property int platformTemp3: 0
    property int platformTemp4: 0
    property int platformTemp5: 0
    property int platformTemp6: 0
    property var platformTemps: []
    property int platformTempAvg: 0
    property int vrmTemp: platformTemp1
    property int motherboardTemp: platformTempAvg

    function updatePackageTempTier1() {
        filePackageTemp.reload();
        const pkgRaw = parseInt(filePackageTemp.text().trim(), 10);
        packageTemp = isNaN(pkgRaw) ? 0 : Math.round(pkgRaw / 1000.0);
    }

    function updateThermalsTier2() {
        // Segregated core averages (6 P-cores: temp2,6,10,14,18,22; 8 E-cores: temp26..33)
        const pCoreFiles = [fileCoreTemp2, fileCoreTemp6, fileCoreTemp10, fileCoreTemp14, fileCoreTemp18, fileCoreTemp22];
        let pCoreTempsArr = [];
        let pSum = 0;
        let pCount = 0;
        for (let i = 0; i < pCoreFiles.length; i++) {
            pCoreFiles[i].reload();
            const raw = parseInt(pCoreFiles[i].text().trim(), 10);
            const val = isNaN(raw) ? 0 : Math.round(raw / 1000.0);
            pCoreTempsArr.push(val);
            if (val > 0) { pSum += val; pCount++; }
        }
        pCoreTemps = pCoreTempsArr;
        pCoreTempAvg = pCount > 0 ? Math.round(pSum / pCount) : packageTemp;

        const eCoreFiles = [fileCoreTemp26, fileCoreTemp27, fileCoreTemp28, fileCoreTemp29, fileCoreTemp30, fileCoreTemp31, fileCoreTemp32, fileCoreTemp33];
        let eCoreTempsArr = [];
        let eSum = 0;
        let eCount = 0;
        for (let i = 0; i < eCoreFiles.length; i++) {
            eCoreFiles[i].reload();
            const raw = parseInt(eCoreFiles[i].text().trim(), 10);
            const val = isNaN(raw) ? 0 : Math.round(raw / 1000.0);
            eCoreTempsArr.push(val);
            if (val > 0) { eSum += val; eCount++; }
        }
        eCoreTemps = eCoreTempsArr;
        eCoreTempAvg = eCount > 0 ? Math.round(eSum / eCount) : packageTemp;

        fileNvme1Temp.reload();
        const n1Raw = parseInt(fileNvme1Temp.text().trim(), 10);
        nvme1Temp = isNaN(n1Raw) ? 0 : Math.round(n1Raw / 1000.0);

        fileNvme2Temp.reload();
        const n2Raw = parseInt(fileNvme2Temp.text().trim(), 10);
        nvme2Temp = isNaN(n2Raw) ? 0 : Math.round(n2Raw / 1000.0);

        // Platform / Motherboard sensors (gigabyte_wmi temp1..temp6)
        fileMoboTemp1.reload();
        fileMoboTemp2.reload();
        fileMoboTemp3.reload();
        fileMoboTemp4.reload();
        fileMoboTemp5.reload();
        fileMoboTemp6.reload();

        const moboFiles = [fileMoboTemp1, fileMoboTemp2, fileMoboTemp3, fileMoboTemp4, fileMoboTemp5, fileMoboTemp6];
        let platformTempsArr = [];
        let moboSum = 0;
        let moboCount = 0;
        for (let i = 0; i < moboFiles.length; i++) {
            const raw = parseInt(moboFiles[i].text().trim(), 10);
            const val = isNaN(raw) ? 0 : Math.round(raw / 1000.0);
            platformTempsArr.push(val);
            if (val > 0) {
                moboSum += val;
                moboCount++;
            }
        }
        platformTemps = platformTempsArr;
        platformTemp1 = platformTempsArr[0] || 0;
        platformTemp2 = platformTempsArr[1] || 0;
        platformTemp3 = platformTempsArr[2] || 0;
        platformTemp4 = platformTempsArr[3] || 0;
        platformTemp5 = platformTempsArr[4] || 0;
        platformTemp6 = platformTempsArr[5] || 0;
        platformTempAvg = moboCount > 0 ? Math.round(moboSum / moboCount) : 0;
        vrmTemp = platformTemp1;
        motherboardTemp = platformTempAvg;

        let peak = packageTemp;
        let label = "CPU";
        if (nvme1Temp > peak) { peak = nvme1Temp; label = "NVMe 1"; }
        if (nvme2Temp > peak) { peak = nvme2Temp; label = "NVMe 2"; }
        if (vrmTemp > peak) { peak = vrmTemp; label = "VRM"; }

        peakSystemTemperature = peak;
        peakDeviceLabel = label;
    }

    function updateThermals() {
        updatePackageTempTier1();
        updateThermalsTier2();
    }

    // =========================================================================
    // Master Polling Dispatcher (Two-Tier Demand-Gated Sweeping)
    // =========================================================================
    function pollTier1() {
        try { updateCpuLoadTier1(); } catch (e) { console.warn("updateCpuLoadTier1 error:", e); }
        try { updatePackageTempTier1(); } catch (e) { console.warn("updatePackageTempTier1 error:", e); }
        try { updateGpuRc6Tier1(); } catch (e) { console.warn("updateGpuRc6Tier1 error:", e); }
    }

    function pollTier2() {
        try { updateCpuLoadTier2(); } catch (e) { console.warn("updateCpuLoadTier2 error:", e); }
        try { updateFrequencies(); } catch (e) { console.warn("updateFrequencies error:", e); }
        try { updateGovernors(); } catch (e) { console.warn("updateGovernors error:", e); }
        try { updateGpuMetricsTier2(); } catch (e) { console.warn("updateGpuMetricsTier2 error:", e); }
        try { updateThermalsTier2(); } catch (e) { console.warn("updateThermalsTier2 error:", e); }
    }

    function pollAll() {
        pollTier1();
        if (root.fastPollingRequests > 0) {
            pollTier2();
        }
    }

    Component.onCompleted: {
        root.pollAll();
    }
}
