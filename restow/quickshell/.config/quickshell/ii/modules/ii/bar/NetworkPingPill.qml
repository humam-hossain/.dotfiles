pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * NetworkPingPill.qml
 * Status bar telemetry pill displaying live network throughput (Rx/Tx)
 * partitioned by a vertical divider from 3 ping latency targets (WAN, Gateway, Home Server).
 * Left-click launches the local ping daemon dashboard in default browser.
 * Enforces NETPING-01, NETPING-02, NETPING-05, D-01..D-04, D-14, D-16, D-17.
 */
BarGroup {
    id: root

    property real useShortenedForm: 0

    // Public alias for popup anchoring (D-14, D-16)
    readonly property alias hoverArea: pillMouseArea

    // Dynamic health status color resolution (D-02)
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

    function getStatusColor(statusClass) {
        if (statusClass === "good" || statusClass === "normal") return Appearance.colors.colPrimary;
        if (statusClass === "medium" || statusClass === "warning" || statusClass === "elevated") return root.warningColor;
        return Appearance.colors.colError;
    }

    // Re-parented interactive MouseArea with left-click browser launch (D-14, D-16, D-17)
    MouseArea {
        id: pillMouseArea
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"]);
            }
        }

        NetworkPingPopup {
            hoverTarget: root.hoverArea
        }
    }

    // Interactive press feedback animation (D-17)
    scale: pillMouseArea.pressed ? 0.97 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutQuad
        }
    }

    // =========================================================================
    // Segment 1: Local Bandwidth Throughput (D-01)
    // =========================================================================
    MaterialSymbol {
        id: netIcon
        Layout.alignment: Qt.AlignVCenter
        text: NetworkUsage.isWireless ? (Network.materialSymbol || "wifi") : "lan"
        iconSize: Appearance.font.pixelSize.normal
        color: Appearance.colors.colOnLayer1
    }

    StyledText {
        id: throughputText
        Layout.alignment: Qt.AlignVCenter
        text: `↓ ${NetworkUsage.rxShortRate}  ↑ ${NetworkUsage.txShortRate}`
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colOnLayer1
    }

    // =========================================================================
    // Vertical Divider Line (D-03)
    // =========================================================================
    Rectangle {
        id: divider
        implicitWidth: 1
        Layout.fillHeight: true
        color: Appearance.colors.colLayer0Border
        opacity: 0.6
        Layout.leftMargin: 2
        Layout.rightMargin: 2
    }

    // =========================================================================
    // Segment 2: All 3 Ping Targets (D-02)
    // =========================================================================

    // Target 1: WAN (Google DNS 8.8.8.8)
    MaterialSymbol {
        id: wanIcon
        Layout.alignment: Qt.AlignVCenter
        text: "public"
        iconSize: Appearance.font.pixelSize.small
        color: root.getStatusColor(PingService.wanStatus)
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    StyledText {
        id: wanText
        Layout.alignment: Qt.AlignVCenter
        text: PingService.wanLatency
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.getStatusColor(PingService.wanStatus)
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // Target 2: Gateway (192.168.0.1)
    MaterialSymbol {
        id: gwIcon
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 3
        text: "router"
        iconSize: Appearance.font.pixelSize.small
        color: root.getStatusColor(PingService.gatewayStatus)
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    StyledText {
        id: gwText
        Layout.alignment: Qt.AlignVCenter
        text: PingService.gatewayLatency
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.getStatusColor(PingService.gatewayStatus)
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // Target 3: Home Server (192.168.0.104)
    MaterialSymbol {
        id: srvIcon
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 3
        text: "dns"
        iconSize: Appearance.font.pixelSize.small
        color: root.getStatusColor(PingService.homeServerStatus)
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    StyledText {
        id: srvText
        Layout.alignment: Qt.AlignVCenter
        text: PingService.homeServerLatency
        font.pixelSize: Appearance.font.pixelSize.small
        color: root.getStatusColor(PingService.homeServerStatus)
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
}
