pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // =========================================================================
    // D-09 & D-10: Reactive I/O Properties & Active Disk
    // =========================================================================
    property real diskIoPercentage: 0.0
    property real readBytesPerSec: 0.0
    property real writeBytesPerSec: 0.0
    property real readSpeedBytes: readBytesPerSec
    property real writeSpeedBytes: writeBytesPerSec

    property string activeDisk: "/"
    property string activeDiskLabel: labelForMount(activeDisk)

    // Mount lists
    property var physicalDisks: []
    property var cloudDisks: []
    property var mounts: []
    property var allDisks: mounts
    property var rootDisk: ({
        fs: "/dev/nvme1n1p2",
        mount: "/",
        totalKb: 0,
        usedKb: 0,
        availKb: 0,
        usePercent: 0,
        label: "Root"
    })

    // Polling state
    property real lastSampleTime: 0
    property var prevDiskTicks: ({})
    property real lastDfTime: 0
    readonly property real dfCooldownMs: 15000 // Minimum 15s between automatic I/O-triggered df runs

    // =========================================================================
    // File Observers & Timers
    // =========================================================================
    FileView {
        id: fileDiskstats
        path: "/proc/diskstats"
        printErrors: false
        blockLoading: true
    }

    Timer {
        id: ioPollTimer
        interval: 1000 // 1s continuous diskstats tracking
        repeat: true
        running: true
        onTriggered: root.updateDiskIo()
    }

    // =========================================================================
    // D-09 & D-10: Continuous /proc/diskstats I/O Sampling
    // =========================================================================
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

        // Track physical disk base devices
        const monitoredDevices = ["nvme1n1", "nvme0n1", "sda"];

        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length < 14) continue;
            const dev = parts[2];
            if (!monitoredDevices.includes(dev)) continue;

            const readSectors = parseFloat(parts[5]) || 0;  // Field 6: sectors read (512 bytes)
            const writeSectors = parseFloat(parts[9]) || 0; // Field 10: sectors written (512 bytes)
            const ioTicks = parseFloat(parts[12]) || 0;     // Field 13: ms spent doing I/O

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
            // ioTicks represents ms spent doing I/O; normalize across monitored drives
            const totalMs = dt * 1000.0;
            diskIoPercentage = Math.max(0.0, Math.min(100.0, (totalIoTicksDelta / totalMs) * 100.0));
            // 512 bytes per sector (Linux kernel standard)
            readBytesPerSec = (totalReadSectorsDelta * 512.0) / dt;
            writeBytesPerSec = (totalWriteSectorsDelta * 512.0) / dt;
        }

        // Active disk focus (D-10): highlight active disk, fallback to "/" when idle
        if (maxDiskDelta > 0 && mostActiveDevice.length > 0) {
            root.activeDisk = root.deviceToMount(mostActiveDevice);
        } else {
            root.activeDisk = "/";
        }
        root.activeDiskLabel = root.labelForMount(root.activeDisk);

        // D-08: Pure I/O-driven df trigger
        if (totalIoTicksDelta > 0 && (now - lastDfTime) > dfCooldownMs) {
            root.refresh();
        }
    }

    function deviceToMount(dev) {
        if (dev.startsWith("nvme1n1")) return "/";
        if (dev.startsWith("nvme0n1")) return "/mnt/windows";
        if (dev.startsWith("sda")) return "/mnt/hdd";
        return "/";
    }

    function labelForMount(mount) {
        if (mount === "/") return "Root";
        if (mount === "/boot") return "Boot";
        if (mount === "/mnt/windows") return "Windows";
        if (mount === "/mnt/hdd") return "Storage HDD";
        if (mount.includes("gdrive-ammu")) return "Drive: Ammu";
        if (mount.includes("gdrive-bapi")) return "Drive: Bapi";
        if (mount.includes("gdrive-humam")) return "Drive: Humam";
        if (mount.includes("GoogleDrive") || mount.includes("gdrive")) return "Google Drive";
        return mount;
    }

    // =========================================================================
    // D-08 & D-11: Asynchronous df Execution & Filtering Pattern
    // =========================================================================
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
        let all = [];

        // Ignored pseudo-filesystems (Decision D-11)
        const ignoredPrefixes = ["devtmpfs", "tmpfs", "efivarfs", "none", "/dev/loop"];
        const ignoredMounts = ["/dev", "/dev/shm", "/run", "/tmp", "/sys/firmware/efi/efivars"];

        for (let i = 1; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length < 6) continue;

            const fs = parts[0];
            const totalKb = parseInt(parts[1], 10) || 0;
            const usedKb = parseInt(parts[2], 10) || 0;
            const availKb = parseInt(parts[3], 10) || 0;
            const pctStr = parts[4];
            const mount = parts[5];

            // Filter virtual filesystems
            if (ignoredPrefixes.some(p => fs === p || fs.startsWith(p))) continue;
            if (ignoredMounts.some(m => mount === m || mount.startsWith("/run/"))) continue;

            const usePercent = parseInt(pctStr.replace("%", ""), 10) || 0;
            const isCloud = mount.includes("GoogleDrive") || mount.includes("gdrive") || fs.startsWith("gdrive");

            const entry = {
                fs: fs,
                mount: mount,
                totalKb: totalKb,
                usedKb: usedKb,
                availKb: availKb,
                usePercent: usePercent,
                isCloud: isCloud,
                label: root.labelForMount(mount)
            };

            if (isCloud) {
                cloud.push(entry);
            } else {
                phys.push(entry);
            }
            all.push(entry);

            if (mount === "/") {
                root.rootDisk = entry;
            }
        }

        physicalDisks = phys;
        cloudDisks = cloud;
        mounts = all;
    }

    Component.onCompleted: {
        root.updateDiskIo();
        root.refresh();
    }
}
