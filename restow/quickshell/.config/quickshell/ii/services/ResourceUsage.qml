pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Polled resource usage service with RAM, Swap, CPU usage, and extended D-15 memory telemetry.
 */
Singleton {
    id: root

    property bool isInspectorActive: false

    // Core Memory Properties (extended per D-15)
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryAvailable: 0
    property real memoryBuffers: 0
    property real memoryCached: 0
    property real memoryUsed: Math.max(0, memoryTotal - (memoryAvailable > 0 ? memoryAvailable : memoryFree))
    property real memoryUsedPercentage: memoryTotal > 0 ? (memoryUsed / memoryTotal) : 0

    // Swap Properties (preserved from upstream)
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: Math.max(0, swapTotal - swapFree)
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0

    // CPU Properties (preserved from upstream)
    property real cpuUsage: 0
    property var previousCpuStats

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options?.resources?.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage];
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift();
        }
    }

    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage];
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift();
        }
    }

    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage];
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift();
        }
    }

    function updateHistories() {
        updateMemoryUsageHistory();
        updateSwapUsageHistory();
        updateCpuUsageHistory();
    }

    function pollMetrics() {
        // Reload virtual files
        fileMeminfo.reload();
        fileStat.reload();

        // Parse memory and swap usage (D-15 extended fields)
        const textMeminfo = fileMeminfo.text();
        memoryTotal = Number(textMeminfo.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1);
        memoryAvailable = Number(textMeminfo.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0);
        memoryFree = Number(textMeminfo.match(/MemFree:\s*(\d+)/)?.[1] ?? 0);
        memoryBuffers = Number(textMeminfo.match(/Buffers:\s*(\d+)/)?.[1] ?? 0);
        memoryCached = Number(textMeminfo.match(/^Cached:\s*(\d+)/m)?.[1] ?? 0);
        swapTotal = Number(textMeminfo.match(/SwapTotal:\s*(\d+)/)?.[1] ?? 1);
        swapFree = Number(textMeminfo.match(/SwapFree:\s*(\d+)/)?.[1] ?? 0);

        // Parse CPU usage
        const textStat = fileStat.text();
        const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (cpuLine) {
            const stats = cpuLine.slice(1).map(Number);
            const total = stats.reduce((a, b) => a + b, 0);
            const idle = stats[3];

            if (previousCpuStats) {
                const totalDiff = total - previousCpuStats.total;
                const idleDiff = idle - previousCpuStats.idle;
                cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;
            }

            previousCpuStats = { total, idle };
        }

        if (root.isInspectorActive) {
            root.updateHistories();
        }
    }

    Component.onCompleted: {
        root.pollMetrics();
    }

    Timer {
        id: pollTimer
        interval: root.isInspectorActive ? 1000 : (Config?.options?.resources?.updateInterval ?? 3000)
        running: true 
        repeat: true
        onTriggered: {
            root.pollMetrics();
        }
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo"; printErrors: false; blockLoading: true }
    FileView { id: fileStat; path: "/proc/stat"; printErrors: false; blockLoading: true }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz";
            }
        }
    }
}
