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
    // Guarantees zero reference count leaks (Pitfall 5)
    onActiveChanged: {
        if (active) {
            HardwareTelemetry.fastPollingRequests++;
        } else {
            HardwareTelemetry.fastPollingRequests--;
        }
    }

    Component.onDestruction: {
        if (active) {
            HardwareTelemetry.fastPollingRequests--;
        }
    }




    // Alert threshold color mappings (D-10, D-11) with dots-hyprland amber warning color fallback
    readonly property color warningColor: Appearance.colors.colWarning !== undefined ? Appearance.colors.colWarning : "#FFA000"

    function getLoadColor(val) {
        if (val >= 0.90) return Appearance.colors.colError;
        if (val >= 0.70) return root.warningColor;
        return Appearance.colors.colPrimary;
    }

    function getTempColor(temp) {
        if (temp >= 80) return Appearance.colors.colError;
        if (temp >= 65) return root.warningColor;
        return Appearance.colors.colOnLayer1;
    }

    readonly property color cpuLoadColor: getLoadColor(HardwareTelemetry.overallCpuLoad || 0.0)
    readonly property color gpuLoadColor: getLoadColor(HardwareTelemetry.gpuLoad || 0.0)

    readonly property bool isCritical: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 || (HardwareTelemetry.packageTemp || 0) >= 80 || (HardwareTelemetry.gpuLoad || 0.0) >= 0.90
    property real criticalPulseOpacity: 1.0

    // Reusable progress meter row sub-component
    component MetricProgressRow: ColumnLayout {
        id: meterRow
        property string title: ""
        property string mhzText: ""
        property string subtitle: mhzText
        property real value: 0.0
        property string tempText: ""
        property color barColor: Appearance.colors.colPrimary
        property color tempColor: Appearance.colors.colOnLayer1
        property bool isCritical: false
        spacing: 2
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            StyledText {
                text: meterRow.title
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledText {
                visible: (meterRow.mhzText.length > 0 || meterRow.subtitle.length > 0)
                text: meterRow.mhzText.length > 0 ? meterRow.mhzText : meterRow.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: `${Math.round((meterRow.value || 0.0) * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: meterRow.barColor
                opacity: meterRow.isCritical ? root.criticalPulseOpacity : 1.0
            }
            StyledText {
                visible: meterRow.tempText.length > 0
                text: meterRow.tempText
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: meterRow.tempColor
                opacity: meterRow.isCritical ? root.criticalPulseOpacity : 1.0
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: Math.max(0.0, Math.min(1.0, Math.round((meterRow.value || 0.0) * 100) / 100))
            highlightColor: meterRow.barColor
            opacity: meterRow.isCritical ? root.criticalPulseOpacity : 1.0
        }
    }

    component PlatformSensorRow: RowLayout {
        id: psRow
        property string label: ""
        property int temp: 0
        spacing: 4
        Layout.fillWidth: true

        StyledText {
            text: psRow.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: root.active ? `${psRow.temp}°C` : ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: root.getTempColor(psRow.temp)
            opacity: psRow.temp >= 80 ? root.criticalPulseOpacity : 1.0
        }
    }

    ColumnLayout {
        id: popupContent
        anchors.centerIn: parent
        spacing: 12

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
        // Upper Dual Columns: Left (CPU + Process Tree) & Right (GPU + Process Tree)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // =================================================================
            // Left Column: CPU Telemetry & Top CPU Process Tree
            // =================================================================
            ColumnLayout {
                Layout.preferredWidth: 320
                spacing: 8

                StyledPopupHeaderRow {
                    icon: "planner_review"
                    label: `CPU (${HardwareTelemetry.cpuModelName})`
                }

                // Overall CPU Load
                MetricProgressRow {
                    title: "Overall CPU"
                    mhzText: root.active ? `${Math.round((HardwareTelemetry.pCoreFrequencyMhz || 0) * 0.6 + (HardwareTelemetry.eCoreFrequencyMhz || 0) * 0.4)} MHz` : ""
                    value: root.active ? (Math.round((HardwareTelemetry.overallCpuLoad || 0.0) * 100) / 100) : 0.0
                    tempText: root.active ? `${HardwareTelemetry.packageTemp || 0}°C` : ""
                    barColor: root.cpuLoadColor
                    tempColor: root.getTempColor(HardwareTelemetry.packageTemp || 0)
                    isCritical: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 || (HardwareTelemetry.packageTemp || 0) >= 80
                }

                // Segregated Hybrid P-Cores
                MetricProgressRow {
                    visible: HardwareTelemetry.isHybridArchitecture
                    title: `P-Cores (${HardwareTelemetry.pCoreThreadCount}T)`
                    mhzText: root.active ? `${Math.round(HardwareTelemetry.pCoreFrequencyMhz || 0)} MHz` : ""
                    value: root.active ? (Math.round((HardwareTelemetry.pCoreLoad || 0.0) * 100) / 100) : 0.0
                    tempText: root.active ? `${HardwareTelemetry.pCoreTempAvg || 0}°C` : ""
                    barColor: root.getLoadColor(HardwareTelemetry.pCoreLoad || 0.0)
                    tempColor: root.getTempColor(HardwareTelemetry.pCoreTempAvg || 0)
                    isCritical: (HardwareTelemetry.pCoreLoad || 0.0) >= 0.90 || (HardwareTelemetry.pCoreTempAvg || 0) >= 80
                }

                // Segregated Hybrid E-Cores
                MetricProgressRow {
                    visible: HardwareTelemetry.isHybridArchitecture
                    title: `E-Cores (${HardwareTelemetry.eCoreThreadCount}T)`
                    mhzText: root.active ? `${Math.round(HardwareTelemetry.eCoreFrequencyMhz || 0)} MHz` : ""
                    value: root.active ? (Math.round((HardwareTelemetry.eCoreLoad || 0.0) * 100) / 100) : 0.0
                    tempText: root.active ? `${HardwareTelemetry.eCoreTempAvg || 0}°C` : ""
                    barColor: root.getLoadColor(HardwareTelemetry.eCoreLoad || 0.0)
                    tempColor: root.getTempColor(HardwareTelemetry.eCoreTempAvg || 0)
                    isCritical: (HardwareTelemetry.eCoreLoad || 0.0) >= 0.90 || (HardwareTelemetry.eCoreTempAvg || 0) >= 80
                }

                // Telemetry Value Rows
                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "tune"
                    label: "Governor:"
                    value: root.active ? (HardwareTelemetry.scalingGovernor || "") : ""
                }

                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "bolt"
                    label: "Power Draw:"
                    value: root.active ? "N/A (unprivileged)" : ""
                }
            }

            // Vertical Separator
            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Appearance.colors.colLayer0Border
            }

            // =================================================================
            // Right Column: GPU Telemetry & Top GPU Process Tree
            // =================================================================
            ColumnLayout {
                Layout.preferredWidth: 320
                spacing: 8

                // --- GPU Section (Top) ---
                StyledPopupHeaderRow {
                    icon: "sports_esports"
                    label: `GPU (${HardwareTelemetry.gpuModelName})`
                }

                MetricProgressRow {
                    title: "iGPU Load"
                    value: root.active ? (Math.round((HardwareTelemetry.gpuLoad || 0.0) * 100) / 100) : 0.0
                    barColor: root.gpuLoadColor
                    isCritical: (HardwareTelemetry.gpuLoad || 0.0) >= 0.90
                }

                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "speed"
                    label: "Render Clock:"
                    value: root.active ? `${Math.round(HardwareTelemetry.gpuClockMhz || 0)} MHz` : ""
                }

                StyledPopupValueRow {
                    Layout.fillWidth: true
                    icon: "warning"
                    label: "Thermal Throttle:"
                    value: root.active ? (HardwareTelemetry.gpuThrottled ? "Throttling" : "Normal") : ""
                }
            }
        }

        // =====================================================================
        // Bottom Section: Platform & Motherboard Hardware Drawer (D-08)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colLayer0Border
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            StyledPopupHeaderRow {
                icon: "developer_board"
                label: `Platform (${HardwareTelemetry.motherboardModelName})`
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Summary Temps
                ColumnLayout {
                    Layout.preferredWidth: 320
                    spacing: 4

                    StyledPopupValueRow {
                        Layout.fillWidth: true
                        icon: "device_thermostat"
                        label: "VRM Temp:"
                        value: root.active ? `${HardwareTelemetry.vrmTemp || 0}°C` : ""
                    }

                    StyledPopupValueRow {
                        Layout.fillWidth: true
                        icon: "thermostat"
                        label: "Platform Avg Temp:"
                        value: root.active ? `${HardwareTelemetry.platformTempAvg || 0}°C` : ""
                    }
                }

                // 6 Gigabyte WMI platform sensors breakdown in 2 columns of 3
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        PlatformSensorRow {
                            label: "VRM / S1:"
                            temp: root.active ? (HardwareTelemetry.platformTemp1 || HardwareTelemetry.vrmTemp || 0) : 0
                        }
                        PlatformSensorRow {
                            label: "Sensor 2:"
                            temp: root.active ? (HardwareTelemetry.platformTemp2 || 0) : 0
                        }
                        PlatformSensorRow {
                            label: "Sensor 3:"
                            temp: root.active ? (HardwareTelemetry.platformTemp3 || 0) : 0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        PlatformSensorRow {
                            label: "Sensor 4:"
                            temp: root.active ? (HardwareTelemetry.platformTemp4 || 0) : 0
                        }
                        PlatformSensorRow {
                            label: "Sensor 5:"
                            temp: root.active ? (HardwareTelemetry.platformTemp5 || 0) : 0
                        }
                        PlatformSensorRow {
                            label: "Sensor 6:"
                            temp: root.active ? (HardwareTelemetry.platformTemp6 || 0) : 0
                        }
                    }
                }
            }
        }
    }
}
