pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

StyledPopup {
    id: root

    // Reactive fast-polling lifecycle boost (1000ms active / 3000ms idle)
    onActiveChanged: {
        ResourceUsage.isInspectorActive = active;
        if (active) {
            ResourceUsage.pollMetrics();
            StorageUsage.refresh();
        }
    }

    Component.onDestruction: {
        if (active) {
            ResourceUsage.isInspectorActive = false;
        }
    }

    // Formatting Helpers
    function formatKB(kb) {
        if (!kb || kb <= 0) return "0.0 GB";
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function formatThroughput(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0) return "0 B/s";
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s";
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
    }

    function formatDriveLabel(fs, mount) {
        if (!fs) return mount || "Drive";
        if (fs.startsWith("/dev/")) {
            const devName = fs.substring(5);
            return `${devName} (${mount})`;
        }
        const cleanFs = fs.replace(/:$/, "");
        if (cleanFs.includes("gdrive")) {
            return cleanFs;
        }
        return `${cleanFs} (${mount})`;
    }

    // Alert threshold color mappings with dots-hyprland amber warning color fallback
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

    function getLoadColor(val) {
        if (val >= 0.90) return Appearance.colors.colError;
        if (val >= 0.70) return root.warningColor;
        return Appearance.colors.colPrimary;
    }

    readonly property bool isCritical: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.90 || ((StorageUsage.rootDisk?.usePercent ?? 0) / 100.0) >= 0.90
    property real criticalPulseOpacity: 1.0




    // Sub-components
    component MemoryTierRow: RowLayout {
        id: tierRow
        property string label: ""
        property string value: ""
        property color valueColor: Appearance.colors.colOnSurfaceVariant
        property bool isAlert: false
        spacing: 4
        Layout.fillWidth: true

        StyledText {
            text: tierRow.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: tierRow.value
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: tierRow.isAlert ? Font.DemiBold : Font.Normal
            color: tierRow.valueColor
            opacity: tierRow.isAlert && root.isCritical ? root.criticalPulseOpacity : 1.0
        }
    }

    component StorageDriveRow: ColumnLayout {
        id: driveRow
        required property var modelData
        spacing: 3
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Subtle active drive indicator dot (D-15)
            Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: Appearance.colors.colPrimary
                visible: driveRow.modelData && StorageUsage.activeDisk === driveRow.modelData.mount && StorageUsage.diskIoPercentage > 0
            }

            StyledText {
                text: driveRow.modelData ? root.formatDriveLabel(driveRow.modelData.fs, driveRow.modelData.mount) : ""
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            StyledText {
                text: driveRow.modelData ? `${root.formatKB(driveRow.modelData.usedKb)} / ${root.formatKB(driveRow.modelData.totalKb)} (${driveRow.modelData.usePercent ?? 0}%)` : ""
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: root.getLoadColor(((driveRow.modelData?.usePercent ?? 0)) / 100.0)
                opacity: ((driveRow.modelData?.usePercent ?? 0) / 100.0) >= 0.90 ? root.criticalPulseOpacity : 1.0
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: Math.max(0.0, Math.min(1.0, ((driveRow.modelData?.usePercent ?? 0)) / 100.0))
            highlightColor: root.getLoadColor(((driveRow.modelData?.usePercent ?? 0)) / 100.0)
            opacity: ((driveRow.modelData?.usePercent ?? 0) / 100.0) >= 0.90 ? root.criticalPulseOpacity : 1.0
        }
    }

    RowLayout {
        id: popupContent
        anchors.centerIn: parent
        spacing: 16

        // Gated critical pulse animation (D-06)
        SequentialAnimation {
            id: popupCriticalPulse
            running: root.active && root.isCritical
            loops: Animation.Infinite
            onRunningChanged: {
                if (!running) root.criticalPulseOpacity = 1.0;
            }
            NumberAnimation {
                target: root
                property: "criticalPulseOpacity"
                to: 0.4
                duration: 600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "criticalPulseOpacity"
                to: 1.0
                duration: 600
                easing.type: Easing.InOutSine
            }
        }

        // =====================================================================
        // Left Column (320px): Memory Card (RAM Allocation + Tiers)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 8

            // Header
            StyledPopupHeaderRow {
                icon: "memory"
                label: "Memory"
            }

            // Multi-Segment Stacked Allocation Bar (D-05)
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "RAM Allocation"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: `${root.formatKB(ResourceUsage.memoryUsed)} / ${root.formatKB(ResourceUsage.memoryTotal)} (${Math.round((ResourceUsage.memoryUsedPercentage || 0.0) * 100)}%)`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                    opacity: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.90 ? root.criticalPulseOpacity : 1.0
                }
            }

            Rectangle {
                id: allocBarContainer
                Layout.fillWidth: true
                implicitHeight: 8
                radius: 4
                clip: true
                color: Appearance.m3colors.m3surfaceContainerHigh

                Rectangle {
                    id: subSegUsed
                    height: parent.height
                    width: parent.width * Math.max(0.0, Math.min(1.0, (ResourceUsage.memoryUsed || 0.0) / (ResourceUsage.memoryTotal || 1.0)))
                    color: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                    radius: 4
                }

                Rectangle {
                    id: subSegBuff
                    x: subSegUsed.width
                    height: parent.height
                    width: parent.width * Math.max(0.0, Math.min(1.0, Math.max(0, (ResourceUsage.memoryAvailable || 0.0) - (ResourceUsage.memoryFree || 0.0)) / (ResourceUsage.memoryTotal || 1.0)))
                    color: Appearance.colors.colSecondary !== undefined ? Appearance.colors.colSecondary : Appearance.colors.colPrimary
                    opacity: 0.6
                    radius: 4
                }
            }

            // Legend Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 4
                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                    }
                    StyledText {
                        text: "Used"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                RowLayout {
                    spacing: 4
                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Appearance.colors.colSecondary !== undefined ? Appearance.colors.colSecondary : Appearance.colors.colPrimary
                        opacity: 0.6
                    }
                    StyledText {
                        text: "Buffers/Cache"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 4
                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Appearance.m3colors.m3surfaceContainerHigh
                    }
                    StyledText {
                        text: "Free"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Horizontal Separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }

            // Detailed Numeric Memory Tier Rows (D-06)
            MemoryTierRow {
                label: "Used"
                value: `${root.formatKB(ResourceUsage.memoryUsed)} (${Math.round((ResourceUsage.memoryUsedPercentage || 0.0) * 100)}%)`
                valueColor: root.getLoadColor(ResourceUsage.memoryUsedPercentage || 0.0)
                isAlert: (ResourceUsage.memoryUsedPercentage || 0.0) >= 0.70
            }

            MemoryTierRow {
                label: "Available"
                value: `${root.formatKB(ResourceUsage.memoryAvailable)} (${Math.round(((ResourceUsage.memoryAvailable || 0.0) / (ResourceUsage.memoryTotal || 1.0)) * 100)}%)`
            }

            MemoryTierRow {
                label: "Buffers"
                value: root.formatKB(ResourceUsage.memoryBuffers)
            }

            MemoryTierRow {
                label: "Cached"
                value: root.formatKB(ResourceUsage.memoryCached)
            }

            MemoryTierRow {
                label: "Free (Unallocated)"
                value: root.formatKB(ResourceUsage.memoryFree)
            }

            MemoryTierRow {
                visible: ResourceUsage.swapTotal > 0
                label: "Swap"
                value: `${root.formatKB(ResourceUsage.swapUsed)} / ${root.formatKB(ResourceUsage.swapTotal)} (${Math.round((ResourceUsage.swapUsedPercentage || 0.0) * 100)}%)`
                valueColor: root.getLoadColor(ResourceUsage.swapUsedPercentage || 0.0)
                isAlert: (ResourceUsage.swapUsedPercentage || 0.0) >= 0.70
            }

            Item { Layout.fillHeight: true }
        }

        // =====================================================================
        // Center Vertical Separator
        // =====================================================================
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Appearance.colors.colLayer0Border
        }

        // =====================================================================
        // Right Column (320px): Storage Card (Throughput + Drives)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 320
            spacing: 8

            // Header Row with Live Throughput Badge (D-14, D-16)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledPopupHeaderRow {
                    icon: "storage"
                    label: "Storage"
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 4

                    MaterialSymbol {
                        text: "arrow_downward"
                        iconSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: root.formatThroughput(StorageUsage.readBytesPerSec)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    MaterialSymbol {
                        text: "arrow_upward"
                        iconSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: root.formatThroughput(StorageUsage.writeBytesPerSec)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Sub-section: Physical Drives (D-10)
            StyledText {
                text: "Physical Drives"
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }

            Repeater {
                model: StorageUsage.physicalDisks
                delegate: StorageDriveRow {}
            }

            // Sub-section: Cloud Mounts (Google Drive) (D-10, D-11)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: StorageUsage.cloudDisks && StorageUsage.cloudDisks.length > 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                }

                StyledText {
                    text: "Cloud Mounts (Google Drive)"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Repeater {
                    model: StorageUsage.cloudDisks
                    delegate: StorageDriveRow {}
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
