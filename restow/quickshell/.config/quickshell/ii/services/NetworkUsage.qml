pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * NetworkUsage.qml
 * Dedicated network telemetry acquisition singleton service for Quickshell.
 * Enforces NETPING-01, NETPING-03, D-06, D-10..D-13.
 */
Singleton {
    id: root

    // =========================================================================
    // Public Telemetry Properties (D-11)
    // =========================================================================
    property bool isInspectorActive: false
    property string activeInterface: ""
    property string connectionType: "Disconnected" // "Ethernet", "Wi-Fi", "Disconnected"
    property bool isEthernet: false
    property bool isWireless: false
    property bool isConnected: false
    property string materialSymbol: "wifi"

    property string ipAddress: "--"
    property string gatewayIp: "--"
    property string dnsServers: "--"
    property string linkSpeed: "--"
    property string macAddress: "--"
    property string wifiSsid: Network.networkName || ""
    property int wifiSignal: Network.networkStrength || 0

    property real rxBytesPerSec: 0.0
    property real txBytesPerSec: 0.0
    property string rxRateString: "0 B/s"
    property string txRateString: "0 B/s"
    property string rxShortRate: "0 B"
    property string txShortRate: "0 B"

    property real totalRxBytes: 0
    property real totalTxBytes: 0
    property string totalRxString: "0.0 GB"
    property string totalTxString: "0.0 GB"

    property var nicTemp: null
    property string nicTempString: "--"

    property int rxErrors: 0
    property int txErrors: 0
    property int rxDrops: 0
    property int txDrops: 0

    // Internal state
    property string hwmonNicPath: "/sys/class/hwmon/hwmon4"
    property real lastSampleTime: 0
    property real prevRxBytes: -1
    property real prevTxBytes: -1

    // =========================================================================
    // Adaptive Polling Cadence (D-12, D-50-01)
    // =========================================================================
    Timer {
        id: pollTimer
        interval: (root.isInspectorActive || GlobalStates.fastTelemetryRate) ? 1000 : 5000
        repeat: true
        running: true
        onTriggered: root.pollMetrics()
    }

    Timer {
        id: configTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refreshConfig()
    }

    Component.onCompleted: {
        root.refreshConfig();
        root.pollMetrics();
    }

    // =========================================================================
    // Virtual Procfs & Sysfs Files (Fast Path <1ms) (D-01, D-06, D-10)
    // =========================================================================
    FileView {
        id: fileNetDev
        path: "/proc/net/dev"
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: fileNicTemp
        path: root.hwmonNicPath ? (root.hwmonNicPath + "/temp1_input") : ""
        printErrors: false
        blockLoading: true
    }

    FileView { id: fileRoute; path: "/proc/net/route"; printErrors: false; blockLoading: true }
    FileView { id: fileResolv; path: "/etc/resolv.conf"; printErrors: false; blockLoading: true }
    FileView { id: fileIfaceOperstate; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/operstate` : ""; printErrors: false; blockLoading: true }
    FileView { id: fileIfaceCarrier; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/carrier` : ""; printErrors: false; blockLoading: true }
    FileView { id: fileIfaceAddress; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/address` : ""; printErrors: false; blockLoading: true }
    FileView { id: fileIfaceSpeed; path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/speed` : ""; printErrors: false; blockLoading: true }

    // =========================================================================
    // Telemetry Polling (Procfs Throughput Deltas & NIC Temp)
    // =========================================================================
    function pollMetrics() {
        fileNetDev.reload();
        const textNet = fileNetDev.text();
        if (!textNet) return;

        let iface = root.activeInterface;
        if (!iface) {
            const match = textNet.match(/^\s*(wlp\S+|enp\S+|eth\S+):/m);
            if (match) {
                iface = match[1];
                root.activeInterface = iface;
            }
        }
        if (!iface) return;

        const regex = new RegExp(`^\\s*${iface}:\\s*(.+)`, "m");
        const lineMatch = textNet.match(regex);
        if (!lineMatch) return;

        const parts = lineMatch[1].trim().split(/\s+/).map(Number);
        if (parts.length < 16) return;

        const rxBytes = parts[0];
        const rxErrs = parts[2];
        const rxDrops = parts[3];
        const txBytes = parts[8];
        const txErrs = parts[10];
        const txDrops = parts[11];

        root.rxErrors = rxErrs || 0;
        root.txErrors = txErrs || 0;
        root.rxDrops = rxDrops || 0;
        root.txDrops = txDrops || 0;

        const now = Date.now();
        if (root.lastSampleTime > 0 && root.prevRxBytes >= 0 && root.prevTxBytes >= 0) {
            const dt = Math.max(0.1, (now - root.lastSampleTime) / 1000.0);
            const dRx = Math.max(0, rxBytes - root.prevRxBytes);
            const dTx = Math.max(0, txBytes - root.prevTxBytes);

            root.rxBytesPerSec = dRx / dt;
            root.txBytesPerSec = dTx / dt;
            root.rxRateString = root.formatThroughput(root.rxBytesPerSec);
            root.txRateString = root.formatThroughput(root.txBytesPerSec);
            root.rxShortRate = root.formatShortRate(root.rxBytesPerSec);
            root.txShortRate = root.formatShortRate(root.txBytesPerSec);
        }

        root.lastSampleTime = now;
        root.prevRxBytes = rxBytes;
        root.prevTxBytes = txBytes;
        root.totalRxBytes = rxBytes;
        root.totalTxBytes = txBytes;
        root.totalRxString = root.formatGigabytes(rxBytes);
        root.totalTxString = root.formatGigabytes(txBytes);

        // Dynamic Realtek r8169 NIC Hardware Temperature (D-06)
        if (root.hwmonNicPath) {
            fileNicTemp.reload();
            const rawTemp = Number(fileNicTemp.text().trim());
            if (!isNaN(rawTemp) && rawTemp > 0) {
                root.nicTemp = rawTemp / 1000.0;
                root.nicTempString = (rawTemp / 1000.0).toFixed(1) + "°C";
            } else {
                root.nicTemp = null;
                root.nicTempString = "--";
            }
        }
    }

    // =========================================================================
    // Carrier Priority Interface Detection & System Info (D-13)
    // =========================================================================
    function refreshConfig() {
        fileRoute.reload();
        const textRoute = fileRoute.text();
        if (textRoute) {
            const lines = textRoute.trim().split("\n");
            for (let i = 1; i < lines.length; i++) {
                const parts = lines[i].trim().split(/\s+/);
                if (parts.length >= 3 && parts[1] === "00000000") { // Default route destination
                    root.activeInterface = parts[0];
                    const hexGw = parts[2];
                    // Convert hex little-endian IP to dotted-decimal
                    root.gatewayIp = `${parseInt(hexGw.slice(6, 8), 16)}.${parseInt(hexGw.slice(4, 6), 16)}.${parseInt(hexGw.slice(2, 4), 16)}.${parseInt(hexGw.slice(0, 2), 16)}`;
                    break;
                }
            }
        }

        if (root.activeInterface) {
            fileIfaceAddress.reload();
            root.macAddress = fileIfaceAddress.text().trim() || "--";
            fileIfaceSpeed.reload();
            const spd = fileIfaceSpeed.text().trim();
            root.linkSpeed = (spd && spd !== "-1") ? `${spd} Mbps` : "--";
            root.isEthernet = root.activeInterface.startsWith("en") || root.activeInterface.startsWith("eth");
            root.isWireless = root.activeInterface.startsWith("wl");
            root.connectionType = root.isEthernet ? "Ethernet" : (root.isWireless ? "Wi-Fi" : "Connected");
            root.materialSymbol = root.isEthernet ? "lan" : (root.isWireless ? (Network.materialSymbol || "wifi") : "cloud_off");
        }

        fileResolv.reload();
        const textResolv = fileResolv.text();
        if (textResolv) {
            const matches = [...textResolv.matchAll(/^nameserver\s+(\S+)/gm)].map(m => m[1]);
            root.dnsServers = matches.join(", ") || "--";
        }

        // Trigger one-shot IP discovery directly without subshell wrapper
        if (!ipAddrProc.running) {
            ipAddrProc.running = true;
        }
    }

    Process {
        id: ipAddrProc
        command: ["ip", "-j", "-4", "addr", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    for (const item of data) {
                        if (item.ifname === root.activeInterface && item.addr_info?.length > 0) {
                            root.ipAddress = item.addr_info[0].local || "--";
                            root.isConnected = true;
                            break;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // =========================================================================
    // Formatting Helper Functions (D-01, D-11)
    // =========================================================================
    function formatThroughput(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0) return "0 B/s";
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s";
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
    }

    function formatShortRate(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0) return "0 B";
        if (bytesPerSec < 1024) return Math.round(bytesPerSec) + " B";
        if (bytesPerSec < 1024 * 1024) return Math.round(bytesPerSec / 1024) + " KB";
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB";
        return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    function formatGigabytes(bytes) {
        if (!bytes || bytes <= 0) return "0.0 GB";
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }
}
