pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Polled resource usage service with RAM, Swap, CPU, and root-/ disk usage.
 */
Singleton {
    id: root
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats

    // Disk metrics for root / (bytes); used/avail from df -B1
    property real diskTotal: 1
    property real diskAvail: 0
    property real diskUsed: 0
    property real diskUsedPercentage: diskTotal > 0 ? (diskUsed / diskTotal) : 0

    property string maxAvailableMemoryString: formatBytes(memoryTotal * 1024)
    property string maxAvailableSwapString: formatBytes(swapTotal * 1024)
    property string maxAvailableCpuString: "--"
    property string memoryUsedTotalString: formatPair(memoryUsed * 1024, memoryTotal * 1024)
    property string diskFreeTotalString: formatPair(diskAvail, diskTotal)

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    /**
     * Auto human capacity label: TB (≥ ~1 TiB) or GB with one decimal (D-15).
     * Input is bytes.
     */
    function formatBytes(bytes) {
        const n = Number(bytes) || 0
        const tib = 1024 * 1024 * 1024 * 1024
        if (n >= tib)
            return (n / tib).toFixed(1) + " TB"
        return (n / (1024 * 1024 * 1024)).toFixed(1) + " GB"
    }

    function kbToGbString(kb) {
        return formatBytes((Number(kb) || 0) * 1024)
    }

    /**
     * Format a used/total (or free/total) byte pair with a single shared unit suffix.
     * Unit is determined by the larger value (TB when ≥ 1 TiB, else GB).
     * Example output: "12.3/31.2 GB" or "1.2/2.0 TB"
     */
    function formatPair(bytesA, bytesB) {
        const a = Number(bytesA) || 0
        const b = Number(bytesB) || 0
        const tib = 1024 * 1024 * 1024 * 1024
        const larger = Math.max(a, b)
        if (larger >= tib) {
            return (a / tib).toFixed(1) + "/" + (b / tib).toFixed(1) + " TB"
        }
        const gib = 1024 * 1024 * 1024
        return (a / gib).toFixed(1) + "/" + (b / gib).toFixed(1) + " GB"
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function refreshDisk() {
        // Re-run df: toggle running so Process restarts if already finished
        diskProc.running = false
        diskProc.running = true
    }

    function parseCpu() {
        fileStat.reload()
        const textStat = fileStat.text()
        const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
        if (cpuLine) {
            const stats = cpuLine.slice(1).map(Number)
            const total = stats.reduce((a, b) => a + b, 0)
            const idle = stats[3]

            if (previousCpuStats) {
                const totalDiff = total - previousCpuStats.total
                const idleDiff = idle - previousCpuStats.idle
                cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
            }

            previousCpuStats = { total, idle }
        }
        updateCpuUsageHistory()
    }

    function parseMemory() {
        fileMeminfo.reload()
        const textMeminfo = fileMeminfo.text()
        memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
        memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
        swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
        swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
    }

    // Multi-rate poll (D-08, D-14): base ~1s CPU; RAM ~3s; disk ~10s (not every CPU tick)
    property int memoryElapsedMs: 0
    property int diskElapsedMs: 0

    Timer {
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            const cpuInterval = Config.options?.resources?.updateInterval ?? 1000
            const memInterval = Config.options?.resources?.memoryUpdateInterval ?? 3000
            const diskInterval = Config.options?.resources?.diskUpdateInterval ?? 10000

            // Always refresh CPU on base tick (D-08)
            root.parseCpu()

            // RAM/swap on memoryUpdateInterval (~3s)
            root.memoryElapsedMs += cpuInterval
            if (root.memoryElapsedMs >= memInterval) {
                root.memoryElapsedMs = 0
                root.parseMemory()
            }

            // Disk Process on diskUpdateInterval (~10s) — not every 1s tick (T-03-03)
            root.diskElapsedMs += cpuInterval
            if (root.diskElapsedMs >= diskInterval) {
                root.diskElapsedMs = 0
                root.refreshDisk()
            }

            interval = cpuInterval
        }
    }

    // Initial RAM parse so labels are not empty until first memory tick
    Component.onCompleted: {
        root.parseMemory()
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }

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
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }

    // Root / disk via df -B1 (bytes). argv form (Network.qml pattern); LANG=C for stable parse.
    Process {
        id: diskProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["df", "-B1", "--output=size,used,avail,pcent", "/"]
        running: true
        stdout: StdioCollector {
            id: diskOutput
            onStreamFinished: {
                // Skip header; first data line: size used avail pcent
                const lines = diskOutput.text.trim().split("\n")
                if (lines.length < 2)
                    return
                const parts = lines[1].trim().split(/\s+/)
                if (parts.length < 3)
                    return
                const size = Number(parts[0])
                const used = Number(parts[1])
                const avail = Number(parts[2])
                if (!isFinite(size) || size <= 0)
                    return
                root.diskTotal = size
                root.diskUsed = isFinite(used) && used >= 0 ? used : Math.max(0, size - (isFinite(avail) ? avail : 0))
                root.diskAvail = isFinite(avail) ? avail : Math.max(0, size - root.diskUsed)
                // diskUsedPercentage binds from diskUsed / diskTotal
            }
        }
    }
}
