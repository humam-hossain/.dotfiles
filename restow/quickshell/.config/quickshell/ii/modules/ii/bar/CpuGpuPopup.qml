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

    // Alert threshold color mappings (D-10, D-11)
    readonly property color cpuLoadColor: (HardwareTelemetry.overallCpuLoad || 0.0) >= 0.90 ? Appearance.colors.colError : ((HardwareTelemetry.overallCpuLoad || 0.0) >= 0.70 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)
    readonly property color gpuLoadColor: (HardwareTelemetry.gpuLoad || 0.0) >= 0.90 ? Appearance.colors.colError : ((HardwareTelemetry.gpuLoad || 0.0) >= 0.70 ? Appearance.colors.colTertiary : Appearance.colors.colPrimary)

    // Reusable progress meter row sub-component
    component MetricProgressRow: ColumnLayout {
        id: meterRow
        property string title: ""
        property string subtitle: ""
        property real value: 0.0
        property color barColor: Appearance.colors.colPrimary
        spacing: 2
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: meterRow.title
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: meterRow.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: `${Math.round(meterRow.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: meterRow.barColor
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: Math.max(0.0, Math.min(1.0, meterRow.value))
            highlightColor: meterRow.barColor
        }
    }

    // Reusable per-thread mini meter row
    component ThreadMeter: RowLayout {
        id: tMeter
        property int threadIdx: 0
        property real load: (HardwareTelemetry.perThreadLoads && HardwareTelemetry.perThreadLoads[threadIdx]) || 0.0
        property real freq: (HardwareTelemetry.threadFrequencies && HardwareTelemetry.threadFrequencies[threadIdx]) || 0.0
        spacing: 4
        Layout.fillWidth: true

        StyledText {
            text: `C${tMeter.threadIdx}`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
            Layout.preferredWidth: 26
        }

        StyledProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            value: Math.max(0.0, Math.min(1.0, tMeter.load))
            highlightColor: root.cpuLoadColor
        }

        StyledText {
            text: `${Math.round(tMeter.load * 100)}%`
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: root.cpuLoadColor
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: `${Math.round(tMeter.freq)} MHz`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            Layout.preferredWidth: 54
            horizontalAlignment: Text.AlignRight
        }
    }

    RowLayout {
        id: popupContent
        anchors.centerIn: parent
        spacing: 16

        // =====================================================================
        // Left Column: CPU Section (CPUGPU-02, D-13, D-14)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU (i5-13500)"
            }

            // Overall CPU Load
            MetricProgressRow {
                title: "Overall Load"
                value: HardwareTelemetry.overallCpuLoad || 0.0
                barColor: root.cpuLoadColor
            }

            // Segregated P-Cores (12T) (CPUs 0-11)
            MetricProgressRow {
                title: "P-Cores (12T)"
                subtitle: `${Math.round(HardwareTelemetry.pCoreFrequencyMhz || 0)} MHz`
                value: HardwareTelemetry.pCoreLoad || 0.0
                barColor: root.cpuLoadColor
            }

            // Individual P-Core Threads (C0 - C11)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Repeater {
                    model: 12
                    delegate: ThreadMeter {
                        required property int index
                        threadIdx: index
                    }
                }
            }

            // Segregated E-Cores (8T) (CPUs 12-19)
            MetricProgressRow {
                title: "E-Cores (8T)"
                subtitle: `${Math.round(HardwareTelemetry.eCoreFrequencyMhz || 0)} MHz`
                value: HardwareTelemetry.eCoreLoad || 0.0
                barColor: root.cpuLoadColor
            }

            // Individual E-Core Threads (C12 - C19)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Repeater {
                    model: 8
                    delegate: ThreadMeter {
                        required property int index
                        threadIdx: index + 12
                    }
                }
            }

            // Telemetry Value Rows
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: "Package Temp:"
                value: `${HardwareTelemetry.packageTemp || 0}°C`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "thermostat"
                label: "P-Core / E-Core Avg:"
                value: `${HardwareTelemetry.pCoreTempAvg || 0}°C / ${HardwareTelemetry.eCoreTempAvg || 0}°C`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "tune"
                label: "Governor:"
                value: HardwareTelemetry.scalingGovernor || ""
            }

            // Unprivileged Power Fallback (D-05 Platypus mitigation)
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "bolt"
                label: "Power Draw:"
                value: "N/A (unprivileged)"
            }
        }

        // Vertical Separator
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Appearance.colors.colLayer0Border
        }

        // =====================================================================
        // Right Column: GPU Top + Motherboard Bottom (CPUGPU-03, D-13, D-15, D-16)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            spacing: 8

            // --- GPU Section (Top) ---
            StyledPopupHeaderRow {
                icon: "sports_esports"
                label: "GPU (Intel UHD 770)"
            }

            MetricProgressRow {
                title: "iGPU Load"
                value: HardwareTelemetry.gpuLoad || 0.0
                barColor: root.gpuLoadColor
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "speed"
                label: "Render Clock:"
                value: `${Math.round(HardwareTelemetry.gpuClockMhz || 0)} MHz`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "warning"
                label: "Thermal Throttle:"
                value: HardwareTelemetry.gpuThrottled ? "Throttling" : "Normal"
            }

            // Horizontal Separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }

            // --- Motherboard & Platform Telemetry (Bottom) ---
            StyledPopupHeaderRow {
                icon: "developer_board"
                label: "Platform (B760)"
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: "VRM Temp:"
                value: `${HardwareTelemetry.vrmTemp || 0}°C`
            }

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "thermostat"
                label: "Platform Avg Temp:"
                value: `${HardwareTelemetry.platformTempAvg || 0}°C`
            }

            // 6 Gigabyte WMI platform sensors breakdown
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: "Platform Sensors (1–6):"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 2
                    columnSpacing: 8

                    StyledText {
                        text: `VRM / S1: ${HardwareTelemetry.platformTemp1 || HardwareTelemetry.vrmTemp || 0}°C`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: `Sensor 2: ${HardwareTelemetry.platformTemp2 || 0}°C`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: `Sensor 3: ${HardwareTelemetry.platformTemp3 || 0}°C`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: `Sensor 4: ${HardwareTelemetry.platformTemp4 || 0}°C`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: `Sensor 5: ${HardwareTelemetry.platformTemp5 || 0}°C`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: `Sensor 6: ${HardwareTelemetry.platformTemp6 || 0}°C`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Interactive EPP / Power Profile Switcher
            Rectangle {
                id: eppButton
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Appearance.rounding.small
                color: eppMouseArea.containsMouse ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
                border.width: 1
                border.color: eppMouseArea.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    MaterialSymbol {
                        text: "energy_program_saving"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "EPP:"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: `${HardwareTelemetry.activePowerProfile || HardwareTelemetry.energyPerformancePreference || ""}`
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                    }

                    MaterialSymbol {
                        text: "swap_vert"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                MouseArea {
                    id: eppMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        HardwareTelemetry.cyclePowerProfile();
                    }
                }
            }
        }
    }
}
