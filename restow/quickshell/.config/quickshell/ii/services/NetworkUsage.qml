pragma Singleton
pragma ComponentBehavior: Bound

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
    property string rxShortRate: "0K"
    property string txShortRate: "0K"

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
    property string hwmonNicPath: ""
    property real lastSampleTime: 0
    property real prevRxBytes: -1
    property real prevTxBytes: -1

    // =========================================================================
    // Adaptive Polling Cadence (D-12)
    // =========================================================================
    Timer {
        id: pollTimer
        interval: root.isInspectorActive ? 1000 : 2000
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
        if (!probeProcess.running) {
            probeProcess.running = true;
        }
    }

    Process {
        id: probeProcess
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: [
            "bash", "-c",
            `IFACE=""
            CONN_TYPE="Disconnected"

            # 1. Ethernet check: prioritize physical Ethernet (en*/eth*) if carrier=1 and operstate=up
            for ifc in /sys/class/net/{en*,eth*}; do
              [ -d "$ifc" ] || continue
              carrier=$(cat "$ifc/carrier" 2>/dev/null || echo 0)
              state=$(cat "$ifc/operstate" 2>/dev/null || echo down)
              if [ "$carrier" = "1" ] && [ "$state" = "up" ]; then
                IFACE=$(basename "$ifc")
                CONN_TYPE="Ethernet"
                break
              fi
            done

            # 2. Wireless check: fallback to Wi-Fi (wl*) if carrier=1 or operstate=up
            if [ -z "$IFACE" ]; then
              for ifc in /sys/class/net/wl*; do
                [ -d "$ifc" ] || continue
                carrier=$(cat "$ifc/carrier" 2>/dev/null || echo 0)
                state=$(cat "$ifc/operstate" 2>/dev/null || echo down)
                if [ "$carrier" = "1" ] || [ "$state" = "up" ]; then
                  IFACE=$(basename "$ifc")
                  CONN_TYPE="Wi-Fi"
                  break
                fi
              done
            fi

            # 3. Default route fallback
            if [ -z "$IFACE" ]; then
              def_ifc=$(ip -4 route show default 2>/dev/null | awk '{print $5}' | head -1)
              if [ -n "$def_ifc" ] && [ -d "/sys/class/net/$def_ifc" ]; then
                IFACE="$def_ifc"
                if [[ "$IFACE" =~ ^(en|eth) ]]; then
                  CONN_TYPE="Ethernet"
                elif [[ "$IFACE" =~ ^wl ]]; then
                  CONN_TYPE="Wi-Fi"
                else
                  CONN_TYPE="Other"
                fi
              fi
            fi

            if [ -z "$IFACE" ]; then
              echo '{"connected":false,"interface":"","type":"Disconnected"}'
              exit 0
            fi

            IP_ADDR=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/inet / {print $2}' | head -1)
            [ -z "$IP_ADDR" ] && IP_ADDR="--"

            GATEWAY=$(ip -4 route show default 2>/dev/null | awk '/default via/ {print $3}' | head -1)
            [ -z "$GATEWAY" ] && GATEWAY="--"

            DNS=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null | paste -sd, -)
            [ -z "$DNS" ] && DNS="--"

            MAC=$(cat "/sys/class/net/$IFACE/address" 2>/dev/null || echo "--")

            SPEED="--"
            if [ "$CONN_TYPE" = "Ethernet" ]; then
              raw_speed=$(cat "/sys/class/net/$IFACE/speed" 2>/dev/null || echo "")
              duplex=$(cat "/sys/class/net/$IFACE/duplex" 2>/dev/null || echo "full")
              if [ -n "$raw_speed" ] && [ "$raw_speed" -gt 0 ] 2>/dev/null; then
                SPEED="\${raw_speed} Mbps (\${duplex})"
              fi
            elif [ "$CONN_TYPE" = "Wi-Fi" ]; then
              raw_speed=$(iw dev "$IFACE" link 2>/dev/null | awk -F': ' '/tx bitrate/ {print $2}' | head -1)
              if [ -n "$raw_speed" ]; then
                SPEED="$raw_speed"
              else
                SPEED="Wi-Fi Link"
              fi
            fi

            HWMON_NIC=""
            for d in /sys/class/hwmon/hwmon*; do
              if grep -q "r8169" "$d/name" 2>/dev/null; then
                HWMON_NIC="$d"
                break
              fi
            done

            jq -n \\
              --arg iface "$IFACE" \\
              --arg type "$CONN_TYPE" \\
              --arg ip "$IP_ADDR" \\
              --arg gw "$GATEWAY" \\
              --arg dns "$DNS" \\
              --arg mac "$MAC" \\
              --arg speed "$SPEED" \\
              --arg hwmon "$HWMON_NIC" \\
              '{connected: true, interface: $iface, type: $type, ip: $ip, gateway: $gw, dns: $dns, mac: $mac, speed: $speed, hwmonNic: $hwmon}'`
        ]
        stdout: StdioCollector {
            id: probeCollector
            onStreamFinished: {
                try {
                    const data = JSON.parse(probeCollector.text.trim());
                    root.isConnected = Boolean(data.connected);
                    root.activeInterface = data.interface || "";
                    root.connectionType = data.type || "Disconnected";
                    root.isEthernet = (data.type === "Ethernet");
                    root.isWireless = (data.type === "Wi-Fi");
                    root.ipAddress = data.ip || "--";
                    root.gatewayIp = data.gateway || "--";
                    root.dnsServers = data.dns || "--";
                    root.linkSpeed = data.speed || "--";
                    root.macAddress = data.mac || "--";
                    if (data.hwmonNic) {
                        root.hwmonNicPath = data.hwmonNic;
                    }
                    root.materialSymbol = root.isEthernet ? "lan" : (root.isWireless ? (Network.materialSymbol || "wifi") : "cloud_off");
                } catch (e) {
                    // Fallback on JSON parse error
                }
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
        if (!bytesPerSec || bytesPerSec < 1024) return "0K";
        if (bytesPerSec < 1024 * 1024) return Math.round(bytesPerSec / 1024) + "K";
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + "M";
        return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + "G";
    }

    function formatGigabytes(bytes) {
        if (!bytes || bytes <= 0) return "0.0 GB";
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }
}
