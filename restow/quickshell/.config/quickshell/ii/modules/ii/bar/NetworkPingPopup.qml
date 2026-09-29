pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * NetworkPingPopup.qml
 * Two-column interactive inspector overlay for network telemetry and multi-target ping diagnostics.
 * Left Column (320px): Active interface details, Realtek r8169 NIC temp, dual throughput progress bars & totals.
 * Right Column (320px): Web dashboard launcher button, offline alert banner, and 3 dedicated ping diagnostic cards.
 * Enforces NETPING-04, NETPING-05, D-05..D-09, D-12, D-15..D-17.
 */
StyledPopup {
    id: root

    // =========================================================================
    // Lifecycle Demand-Gated Fast Polling (D-12)
    // =========================================================================
    onActiveChanged: {
        NetworkUsage.isInspectorActive = active;
        if (active) {
            NetworkUsage.pollMetrics();
            NetworkUsage.refreshConfig();
            PingService.fetchStatus();
        }
    }

    Component.onDestruction: {
        if (active) {
            NetworkUsage.isInspectorActive = false;
        }
    }

    // =========================================================================
    // Dynamic Health Status Colors (D-02, D-07)
    // =========================================================================
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

    function getStatusColor(statusClass) {
        if (statusClass === "good" || statusClass === "normal") return Appearance.colors.colPrimary;
        if (statusClass === "medium" || statusClass === "warning" || statusClass === "elevated") return root.warningColor;
        return Appearance.colors.colError;
    }

    // =========================================================================
    // Reusable Sub-Components
    // =========================================================================
    component NetworkDetailRow: RowLayout {
        id: rowItem
        property string label: ""
        property string value: ""
        property string iconName: ""
        property color valueColor: Appearance.colors.colOnSurface
        spacing: 4
        Layout.fillWidth: true

        StyledText {
            text: rowItem.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        MaterialSymbol {
            visible: rowItem.iconName !== ""
            text: rowItem.iconName
            iconSize: Appearance.font.pixelSize.smaller
            color: rowItem.valueColor
        }

        StyledText {
            text: rowItem.value
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: rowItem.valueColor
            elide: Text.ElideRight
            Layout.maximumWidth: 190
        }
    }

    component PingDiagnosticCard: Rectangle {
        id: card
        property string targetIcon: "public"
        property string targetTitle: ""
        property string hostIp: ""
        property var targetData: null
        property string latencyValue: "-- ms"
        property string statusClass: "dead"
        property string qualityText: "offline"

        Layout.fillWidth: true
        implicitHeight: 74
        radius: Appearance.rounding.small
        color: Appearance.m3colors.m3surfaceContainerHigh
        border.color: root.getStatusColor(card.statusClass)
        border.width: 1
        opacity: PingService.isOffline ? 0.6 : 1.0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            // Top Header Row: Target icon + title, spacer, quality badge pill
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: card.targetIcon
                    iconSize: Appearance.font.pixelSize.small
                    color: root.getStatusColor(card.statusClass)
                }

                StyledText {
                    text: card.targetTitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurface
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitHeight: 18
                    implicitWidth: qualityLabel.implicitWidth + 10
                    radius: 9
                    color: root.getStatusColor(card.statusClass)
                    opacity: 0.2

                    StyledText {
                        id: qualityLabel
                        anchors.centerIn: parent
                        text: card.qualityText
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        color: root.getStatusColor(card.statusClass)
                    }
                }
            }

            // Bottom Center Row: IP badge, spacer, prominent latency readout
            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    implicitHeight: 18
                    implicitWidth: ipText.implicitWidth + 8
                    radius: 4
                    color: Appearance.colors.colLayer1

                    StyledText {
                        id: ipText
                        anchors.centerIn: parent
                        text: card.hostIp
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: card.latencyValue
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: root.getStatusColor(card.statusClass)
                }
            }
        }
    }

    // =========================================================================
    // Balanced Two-Column Popup Architecture (D-05)
    // =========================================================================
    RowLayout {
        id: popupContent
        anchors.centerIn: parent
        spacing: 16

        // =====================================================================
        // Left Column (320px): Interface & Live Bandwidth Telemetry
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 8

            // Header
            StyledPopupHeaderRow {
                icon: NetworkUsage.materialSymbol
                label: "Network Interface"
            }

            // Comprehensive Interface Telemetry Card (D-06, D-11)
            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainerHigh
                implicitHeight: cardContent.implicitHeight + 16

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    NetworkDetailRow {
                        label: "Interface"
                        value: `${NetworkUsage.activeInterface} (${NetworkUsage.connectionType})`
                    }

                    NetworkDetailRow {
                        visible: NetworkUsage.isWireless
                        label: "Wi-Fi Details"
                        value: `${NetworkUsage.wifiSsid} (${NetworkUsage.wifiSignal}%)`
                    }

                    NetworkDetailRow {
                        label: "IP & Subnet"
                        value: NetworkUsage.ipAddress
                    }

                    NetworkDetailRow {
                        label: "Default Gateway"
                        value: NetworkUsage.gatewayIp
                    }

                    NetworkDetailRow {
                        label: "DNS Nameservers"
                        value: NetworkUsage.dnsServers
                    }

                    NetworkDetailRow {
                        label: "Link Speed"
                        value: NetworkUsage.linkSpeed
                    }

                    NetworkDetailRow {
                        label: "MAC Address"
                        value: NetworkUsage.macAddress
                    }

                    NetworkDetailRow {
                        label: "NIC Hardware Temp"
                        value: NetworkUsage.nicTempString
                        iconName: "device_thermostat"
                        valueColor: NetworkUsage.nicTemp !== null ? Appearance.colors.colOnSurface : Appearance.colors.colSubtext
                    }

                    NetworkDetailRow {
                        label: "Drops / Errors"
                        value: `Rx: ${NetworkUsage.rxDrops}d / ${NetworkUsage.rxErrors}e  Tx: ${NetworkUsage.txDrops}d / ${NetworkUsage.txErrors}e`
                    }
                }
            }

            // Horizontal Separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }

            // Live Bandwidth Activity Section (D-08)
            StyledText {
                text: "Live Bandwidth Activity"
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Rx Activity Meter
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    MaterialSymbol {
                        text: "arrow_downward"
                        iconSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Rx Rate: " + NetworkUsage.rxRateString
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurface
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: "Total: " + NetworkUsage.totalRxString
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                StyledProgressBar {
                    Layout.fillWidth: true
                    value: Math.min(1.0, NetworkUsage.rxBytesPerSec / (10 * 1024 * 1024))
                    highlightColor: Appearance.colors.colPrimary
                }
            }

            // Tx Activity Meter
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    MaterialSymbol {
                        text: "arrow_upward"
                        iconSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSecondary !== undefined ? Appearance.colors.colSecondary : Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Tx Rate: " + NetworkUsage.txRateString
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurface
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: "Total: " + NetworkUsage.totalTxString
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                StyledProgressBar {
                    Layout.fillWidth: true
                    value: Math.min(1.0, NetworkUsage.txBytesPerSec / (10 * 1024 * 1024))
                    highlightColor: Appearance.colors.colSecondary !== undefined ? Appearance.colors.colSecondary : Appearance.colors.colPrimary
                }
            }

            Item { Layout.fillHeight: true }
        }

        // =====================================================================
        // Center Vertical Separator Line (D-05)
        // =====================================================================
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Appearance.colors.colLayer0Border
        }

        // =====================================================================
        // Right Column (320px): Ping Telemetry & 3 Diagnostic Cards
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 8

            // Header Row with "Open Web Dashboard" Action Button (D-15, D-17)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledPopupHeaderRow {
                    icon: "speed"
                    label: "Ping Telemetry"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: btnDashboard
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Appearance.rounding.circle
                    color: btnMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "open_in_new"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colPrimary
                    }

                    PopupToolTip {
                        text: "Open Web Dashboard (http://127.0.0.1:8765/)"
                        extraVisibleCondition: btnMouse.containsMouse
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8765/"]);
                        }
                    }
                }
            }

            // Offline Warning Banner (D-09)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Appearance.rounding.small
                color: Appearance.colors.colError
                opacity: 0.15
                visible: PingService.isOffline

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        text: "cloud_off"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colError
                    }

                    StyledText {
                        text: "Ping Daemon Offline (http://127.0.0.1:8765)"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colError
                    }
                }
            }

            // 3 Dedicated Ping Diagnostic Cards (D-07)
            PingDiagnosticCard {
                targetIcon: "public"
                targetTitle: "WAN (Google DNS)"
                hostIp: PingService.wanTarget?.host || "8.8.8.8"
                targetData: PingService.wanTarget
                latencyValue: PingService.wanLatency
                statusClass: PingService.wanStatus
                qualityText: PingService.wanTarget?.quality || (PingService.isOffline ? "offline" : PingService.wanStatus)
            }

            PingDiagnosticCard {
                targetIcon: "router"
                targetTitle: "Local Gateway"
                hostIp: PingService.gatewayTarget?.host || "192.168.0.1"
                targetData: PingService.gatewayTarget
                latencyValue: PingService.gatewayLatency
                statusClass: PingService.gatewayStatus
                qualityText: PingService.gatewayTarget?.quality || (PingService.isOffline ? "offline" : PingService.gatewayStatus)
            }

            PingDiagnosticCard {
                targetIcon: "dns"
                targetTitle: "Home Server"
                hostIp: PingService.homeServerTarget?.host || "192.168.0.104"
                targetData: PingService.homeServerTarget
                latencyValue: PingService.homeServerLatency
                statusClass: PingService.homeServerStatus
                qualityText: PingService.homeServerTarget?.quality || (PingService.isOffline ? "offline" : PingService.homeServerStatus)
            }

            Item { Layout.fillHeight: true }
        }
    }
}
